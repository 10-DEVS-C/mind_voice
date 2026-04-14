import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:mind_voice/core/services/shared_prefs_service.dart';
import 'package:mind_voice/features/audio_recorder/domain/entities/recording.dart';
import 'package:mind_voice/features/audio_recorder/domain/usecases/audio_usecases.dart';

class AudioRecorderProvider extends ChangeNotifier {
  final GetRecordingsUseCase _getRecordingsUseCase;
  final SaveRecordingUseCase _saveRecordingUseCase;
  final DeleteRecordingUseCase _deleteRecordingUseCase;
  final UpdateRecordingUseCase _updateRecordingUseCase;
  final SharedPrefsService _sharedPrefsService;
  final http.Client _httpClient;

  List<Recording> _recordings = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isRecording = false;
  final Set<String> _transcribingIds = <String>{};
  final AudioRecorder _audioRecorder = AudioRecorder();
  DateTime? _startTime;
  static const String _baseUrl = 'http://18.223.30.63:5000';
  static const List<String> _dummyMarkers = <String>[
    'transcripcion dummy',
    'transcripción dummy',
    'dummy para demostracion',
    'dummy para demostración',
  ];

  List<Recording> get recordings => _recordings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isRecording => _isRecording;

  bool isTranscribing(String recordingId) => _transcribingIds.contains(recordingId);

  AudioRecorderProvider({
    required GetRecordingsUseCase getRecordingsUseCase,
    required SaveRecordingUseCase saveRecordingUseCase,
    required DeleteRecordingUseCase deleteRecordingUseCase,
    required UpdateRecordingUseCase updateRecordingUseCase,
    required SharedPrefsService sharedPrefsService,
    required http.Client httpClient,
  }) : _getRecordingsUseCase = getRecordingsUseCase,
       _saveRecordingUseCase = saveRecordingUseCase,
       _deleteRecordingUseCase = deleteRecordingUseCase,
       _updateRecordingUseCase = updateRecordingUseCase,
       _sharedPrefsService = sharedPrefsService,
       _httpClient = httpClient;

  Future<void> loadRecordings(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _getRecordingsUseCase(userId);

    if (result.isSuccess) {
      _recordings = List.from(result.data!);
      final hadDummyData = _cleanupDummyTranscriptions(userId);
      // Sort by date descending
      _recordings.sort((a, b) => b.date.compareTo(a.date));

      if (hadDummyData) {
        _recordings.sort((a, b) => b.date.compareTo(a.date));
      }
    } else {
      _errorMessage = result.error;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Recording?> addRecording(Recording recording, String userId) async {
    final result = await _saveRecordingUseCase(recording, userId);
    if (result.isSuccess) {
      _recordings.insert(0, result.data!);
      notifyListeners();
      return result.data;
    }
    return null;
  }

  Future<bool> deleteRecording(String id, String userId) async {
    final recordingIndex = _recordings.indexWhere((rec) => rec.id == id);
    final recording = recordingIndex != -1 ? _recordings[recordingIndex] : null;

    if (recording?.apiAudioId != null) {
      final deletedRemote = await _deleteAudioFromApi(recording!.apiAudioId!);
      if (!deletedRemote) {
        _errorMessage = 'No se pudo borrar el audio en el servidor.';
        notifyListeners();
        return false;
      }
    }

    final result = await _deleteRecordingUseCase(id, userId);
    if (result.isSuccess) {
      _recordings.removeWhere((rec) => rec.id == id);
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateRecordingTitle(
    String id,
    String newName,
    String userId,
  ) async {
    final index = _recordings.indexWhere((rec) => rec.id == id);
    if (index != -1) {
      final recording = _recordings[index];
      final updatedRecording = Recording(
        id: recording.id,
        path: recording.path,
        name: newName,
        date: recording.date,
        duration: recording.duration,
        apiAudioId: recording.apiAudioId,
        transcription: recording.transcription,
      );

      final result = await _updateRecordingUseCase(updatedRecording, userId);
      if (result.isSuccess) {
        _recordings[index] = updatedRecording;
        notifyListeners();
      } else {
        _errorMessage = result.error;
        notifyListeners();
      }
    }
  }

  Future<void> startRecording() async {
    if (_isRecording) return;
    try {
      if (await _audioRecorder.hasPermission()) {
        // Permission granted
      } else {
        final status = await Permission.microphone.request();
        if (status != PermissionStatus.granted) {
          _errorMessage = "Permissions not granted";
          notifyListeners();
          return;
        }
      }

      final directory = await getApplicationDocumentsDirectory();
      final String path =
          '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(const RecordConfig(), path: path);
      _isRecording = true;
      _startTime = DateTime.now();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> stopRecording(String userId) async {
    if (!_isRecording) return;
    try {
      final path = await _audioRecorder.stop();
      _isRecording = false;
      final endTime = DateTime.now();
      final duration = endTime.difference(_startTime ?? endTime);

      if (path != null) {
        final newRecording = Recording(
          id: '', // Repo generates ID
          path: path,
          name: 'Recording ${DateTime.now().toIso8601String()}',
          date: DateTime.now(),
          duration: duration,
        );
        final savedRecording = await addRecording(newRecording, userId);
        if (savedRecording != null) {
          unawaited(_syncRecordingWithApiAndTranscription(savedRecording, userId));
        }
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> _transcribeAndUpdateRecording(
    Recording recording,
    String userId,
  ) async {
    final transcription = await _transcribeAudio(recording.path);
    if (transcription == null || transcription.trim().isEmpty) {
      return;
    }

    final updatedRecording = Recording(
      id: recording.id,
      path: recording.path,
      name: recording.name,
      date: recording.date,
      duration: recording.duration,
      apiAudioId: recording.apiAudioId,
      transcription: transcription,
    );

    final result = await _updateRecordingUseCase(updatedRecording, userId);
    if (!result.isSuccess) {
      return;
    }

    final index = _recordings.indexWhere((rec) => rec.id == recording.id);
    if (index == -1) {
      return;
    }

    _recordings[index] = updatedRecording;
    notifyListeners();

    if (updatedRecording.apiAudioId != null) {
      await _updateAudioRemoteTranscription(
        updatedRecording.apiAudioId!,
        updatedRecording.transcription!,
      );
      await _createTranscriptionRecord(
        updatedRecording.apiAudioId!,
        updatedRecording.transcription!,
      );
    }
  }

  Future<void> _syncRecordingWithApiAndTranscription(
    Recording recording,
    String userId,
  ) async {
    var current = recording;
    final remoteId = await _uploadAudioToApi(recording);

    if (remoteId != null && remoteId.isNotEmpty) {
      final withRemoteId = Recording(
        id: recording.id,
        path: recording.path,
        name: recording.name,
        date: recording.date,
        duration: recording.duration,
        apiAudioId: remoteId,
        transcription: recording.transcription,
      );

      final updateResult = await _updateRecordingUseCase(withRemoteId, userId);
      if (updateResult.isSuccess) {
        final index = _recordings.indexWhere((rec) => rec.id == recording.id);
        if (index != -1) {
          _recordings[index] = withRemoteId;
          notifyListeners();
          current = withRemoteId;
        }
      }
    }

    await transcribeRecordingIfNeeded(current.id, userId);
  }

  Future<void> transcribeRecordingIfNeeded(
    String recordingId,
    String userId,
  ) async {
    final index = _recordings.indexWhere((rec) => rec.id == recordingId);
    if (index == -1) {
      return;
    }

    final recording = _recordings[index];
    if (_hasRealTranscription(recording.transcription)) {
      return;
    }

    if (_transcribingIds.contains(recordingId)) {
      return;
    }

    _transcribingIds.add(recordingId);
    notifyListeners();

    try {
      await _transcribeAndUpdateRecording(recording, userId);
    } finally {
      _transcribingIds.remove(recordingId);
      notifyListeners();
    }
  }

  Future<String?> _transcribeAudio(String path) async {
    try {
      final token = _sharedPrefsService.getToken();
      if (token == null || token.isEmpty) {
        return null;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/mindvoice-api/analyze/audio'),
      )
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(await http.MultipartFile.fromPath('audio', path));

      final streamedResponse = await _httpClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode != 200) {
        debugPrint('Transcription failed: ${response.statusCode} - ${response.body}');
        return null;
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      final transcription = data['transcription']?.toString();
      if (transcription != null && transcription.trim().isNotEmpty) {
        return transcription;
      }

      final editedText = data['edited_text']?.toString();
      if (editedText != null && editedText.trim().isNotEmpty) {
        return editedText;
      }

      return null;
    } catch (e) {
      debugPrint('Transcription error: $e');
      return null;
    }
  }

  Future<String?> _uploadAudioToApi(Recording recording) async {
    try {
      final token = _sharedPrefsService.getToken();
      if (token == null || token.isEmpty) {
        return null;
      }

      final file = File(recording.path);
      if (!await file.exists()) {
        return null;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/audios/upload'),
      )
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['duration'] = recording.duration.inSeconds.toString()
        ..fields['title'] = recording.name
        ..files.add(await http.MultipartFile.fromPath('file', recording.path));

      final streamedResponse = await _httpClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode != 201 && response.statusCode != 200) {
        debugPrint('Audio upload failed: ${response.statusCode} - ${response.body}');
        return null;
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      return data['_id']?.toString();
    } catch (e) {
      debugPrint('Audio upload error: $e');
      return null;
    }
  }

  Future<bool> _deleteAudioFromApi(String apiAudioId) async {
    try {
      final token = _sharedPrefsService.getToken();
      if (token == null || token.isEmpty) {
        return false;
      }

      final response = await _httpClient.delete(
        Uri.parse('$_baseUrl/audios/$apiAudioId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      debugPrint('Audio delete error: $e');
      return false;
    }
  }

  Future<void> _updateAudioRemoteTranscription(
    String apiAudioId,
    String transcription,
  ) async {
    try {
      final token = _sharedPrefsService.getToken();
      if (token == null || token.isEmpty) {
        return;
      }

      await _httpClient.put(
        Uri.parse('$_baseUrl/audios/$apiAudioId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'transcription': transcription}),
      );
    } catch (e) {
      debugPrint('Audio transcription update error: $e');
    }
  }

  Future<void> _createTranscriptionRecord(
    String apiAudioId,
    String transcription,
  ) async {
    try {
      final token = _sharedPrefsService.getToken();
      if (token == null || token.isEmpty) {
        return;
      }

      await _httpClient.post(
        Uri.parse('$_baseUrl/transcriptions/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'audioId': apiAudioId,
          'text': transcription,
          'timestamps': <Map<String, dynamic>>[],
        }),
      );
    } catch (e) {
      debugPrint('Create transcription record error: $e');
    }
  }

  bool _hasRealTranscription(String? transcription) {
    final value = transcription?.trim();
    if (value == null || value.isEmpty) {
      return false;
    }
    return !_isDummyTranscription(value);
  }

  bool _isDummyTranscription(String transcription) {
    final normalized = transcription.toLowerCase();
    for (final marker in _dummyMarkers) {
      if (normalized.contains(marker)) {
        return true;
      }
    }
    return false;
  }

  bool _cleanupDummyTranscriptions(String userId) {
    var changed = false;

    for (var i = 0; i < _recordings.length; i++) {
      final recording = _recordings[i];
      final transcription = recording.transcription;

      if (transcription == null || !_isDummyTranscription(transcription)) {
        continue;
      }

      final cleanedRecording = Recording(
        id: recording.id,
        path: recording.path,
        name: recording.name,
        date: recording.date,
        duration: recording.duration,
        apiAudioId: recording.apiAudioId,
        transcription: null,
      );

      _recordings[i] = cleanedRecording;
      changed = true;
      unawaited(_updateRecordingUseCase(cleanedRecording, userId));
    }

    return changed;
  }

  void clear() {
    _recordings = [];
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }
}
