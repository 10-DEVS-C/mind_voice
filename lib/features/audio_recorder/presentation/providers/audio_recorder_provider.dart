import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:mind_voice/core/errors/request_error_mapper.dart';
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
  List<Map<String, String>> _availableTags = [];
  List<Map<String, String>> _availableFolders = [];
  bool _isLoading = false;
  bool _isLoadingTaxonomy = false;
  String? _errorMessage;
  bool _forceLogoutRequired = false;
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

  Map<String, dynamic>? _lastAiResult;
  bool _isAnalyzing = false;

  List<Recording> get recordings => _recordings;
  List<Map<String, String>> get availableTags => _availableTags;
  Map<String, dynamic>? get lastAiResult => _lastAiResult;
  List<Map<String, String>> get availableFolders => _availableFolders;
  bool get isLoading => _isLoading;
  bool get isAnalyzing => _isAnalyzing;
  bool get isLoadingTaxonomy => _isLoadingTaxonomy;
  String? get errorMessage => _errorMessage;
  bool get forceLogoutRequired => _forceLogoutRequired;
  bool get isRecording => _isRecording;

  bool isTranscribing(String recordingId) =>
      _transcribingIds.contains(recordingId);

  bool consumeForceLogoutFlag() {
    final value = _forceLogoutRequired;
    _forceLogoutRequired = false;
    return value;
  }

  void _markHttpError(int statusCode, String fallbackMessage) {
    if (RequestErrorMapper.isSessionInvalidStatus(statusCode)) {
      _errorMessage = RequestErrorMapper.sessionInvalidMessage;
      _forceLogoutRequired = true;
      return;
    }

    _errorMessage = RequestErrorMapper.fromHttpStatus(
      statusCode,
      fallbackMessage,
    );
  }

  void _markNetworkException(Object error) {
    if (RequestErrorMapper.isNetworkException(error)) {
      _errorMessage = RequestErrorMapper.networkRetryMessage;
      debugPrint('Network error: $error');
      return;
    }

    _errorMessage = RequestErrorMapper.fromException(error);
    debugPrint('Unexpected error: $error');
  }

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
      
      // Fetch remote records to merge
      final token = _sharedPrefsService.getToken();
      if (token != null && token.isNotEmpty) {
        try {
          final resp = await _httpClient.get(
            Uri.parse('$_baseUrl/audios/'),
            headers: {'Authorization': 'Bearer $token'},
          );
          if (resp.statusCode == 200) {
            final List<dynamic> remoteData = jsonDecode(resp.body);
            for (final remote in remoteData) {
              final apiId = remote['_id']?.toString();
              if (apiId == null) continue;

              final existsLocally = _recordings.any((r) => r.apiAudioId == apiId);
              if (!existsLocally) {
                // Add a virtual recording (it exists on server but not on this device)
                _recordings.add(Recording(
                  id: 'remote_$apiId',
                  path: '', // Empty path means it exists on server but not locally
                  name: remote['title'] ?? 'Audio remoto',
                  date: remote['createdAt'] != null 
                      ? DateTime.parse(remote['createdAt']) 
                      : DateTime.now(),
                  duration: Duration(seconds: (remote['duration'] ?? 0).toInt()),
                  apiAudioId: apiId,
                  apiTranscriptionId: remote['transcriptionId']?.toString(),
                  folderId: remote['folderId']?.toString(),
                  tagIds: (remote['tagIds'] as List?)?.map((e) => e.toString()).toList() ?? [],
                  transcription: remote['transcription']?.toString(),
                ));
              }
            }
          }
        } catch (e) {
          debugPrint("Error fetching remote audios: $e");
        }
      }

      _cleanupDummyTranscriptions(userId);
      // Sort by date descending
      _recordings.sort((a, b) => b.date.compareTo(a.date));
    } else {
      _errorMessage = result.error;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadTaxonomyOptions() async {
    _isLoadingTaxonomy = true;
    _errorMessage = null;
    notifyListeners();

    final token = _sharedPrefsService.getToken();
    if (token == null || token.isEmpty) {
      _isLoadingTaxonomy = false;
      notifyListeners();
      return;
    }

    try {
      final headers = {'Authorization': 'Bearer $token'};
      final responses = await Future.wait([
        _httpClient.get(Uri.parse('$_baseUrl/tags/'), headers: headers),
        _httpClient.get(Uri.parse('$_baseUrl/folders/'), headers: headers),
      ]);

      if (responses[0].statusCode == 200) {
        final List<dynamic> tagsData = jsonDecode(responses[0].body);
        _availableTags = tagsData
            .whereType<Map<String, dynamic>>()
            .map(
              (e) => {
                'id': (e['_id'] ?? '').toString(),
                'name': (e['name'] ?? '').toString(),
              },
            )
            .where((e) => e['id']!.isNotEmpty && e['name']!.isNotEmpty)
            .toList();
      } else {
        _markHttpError(
          responses[0].statusCode,
          'No se pudieron cargar los tags.',
        );
      }

      if (responses[1].statusCode == 200) {
        final List<dynamic> foldersData = jsonDecode(responses[1].body);
        _availableFolders = foldersData
            .whereType<Map<String, dynamic>>()
            .map(
              (e) => {
                'id': (e['_id'] ?? '').toString(),
                'name': (e['name'] ?? '').toString(),
              },
            )
            .where((e) => e['id']!.isNotEmpty && e['name']!.isNotEmpty)
            .toList();
      } else {
        _markHttpError(
          responses[1].statusCode,
          'No se pudieron cargar las carpetas.',
        );
      }
    } catch (e) {
      _markNetworkException(e);
    } finally {
      _isLoadingTaxonomy = false;
      notifyListeners();
    }
  }

  Future<bool> assignRecordingMetadata(
    String recordingId,
    String userId, {
    String? folderId,
    List<String>? tagIds,
  }) async {
    final index = _recordings.indexWhere((rec) => rec.id == recordingId);
    if (index == -1) {
      return false;
    }

    final recording = _recordings[index];
    final normalizedTagIds = (tagIds ?? recording.tagIds)
        .where((e) => e.trim().isNotEmpty)
        .toSet()
        .toList();

    final updatedRecording = Recording(
      id: recording.id,
      path: recording.path,
      name: recording.name,
      date: recording.date,
      duration: recording.duration,
      apiAudioId: recording.apiAudioId,
      apiTranscriptionId: recording.apiTranscriptionId,
      folderId: folderId,
      tagIds: normalizedTagIds,
      transcription: recording.transcription,
    );

    if (recording.apiAudioId != null) {
      final ok = await _updateAudioRemoteMetadata(
        recording.apiAudioId!,
        folderId: folderId,
        tagIds: normalizedTagIds,
      );
      if (!ok) {
        _errorMessage = 'No se pudo actualizar el audio en el servidor.';
        notifyListeners();
        return false;
      }
    }

    final result = await _updateRecordingUseCase(updatedRecording, userId);
    if (!result.isSuccess) {
      _errorMessage = result.error;
      notifyListeners();
      return false;
    }

    _recordings[index] = updatedRecording;
    _errorMessage = null;
    notifyListeners();
    return true;
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

      if (recording.apiAudioId != null) {
        final ok = await _updateAudioRemoteTitle(
          recording.apiAudioId!,
          newName,
        );
        if (!ok) {
          _errorMessage = 'No se pudo actualizar el nombre en el servidor.';
          notifyListeners();
          return;
        }
      }

      final updatedRecording = Recording(
        id: recording.id,
        path: recording.path,
        name: newName,
        date: recording.date,
        duration: recording.duration,
        apiAudioId: recording.apiAudioId,
        apiTranscriptionId: recording.apiTranscriptionId,
        folderId: recording.folderId,
        tagIds: recording.tagIds,
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

  int getTodayRecordingsCount() {
    final now = DateTime.now();
    return _recordings.where((r) {
      // Solo contar grabaciones locales ó grabaciones del servidor con fecha de hoy
      // (asumimos que la fecha del Recording ya está en hora local o sincronizada)
      return r.date.year == now.year &&
          r.date.month == now.month &&
          r.date.day == now.day;
    }).length;
  }

  bool canStartRecording(String plan) {
    final p = plan.toLowerCase();
    if (p == 'business' || p == 'admin') return true;

    final limit = p == 'professional' ? 20 : 3;
    final count = getTodayRecordingsCount();

    return count < limit;
  }

  Future<void> startRecording(String plan) async {
    if (_isRecording) return;
    
    if (!canStartRecording(plan)) {
      final p = plan.toLowerCase();
      final limit = p == 'professional' ? 20 : 3;
      _errorMessage = "Límite alcanzado: Tu plan ${plan.capitalize()} permite $limit notas por día.";
      notifyListeners();
      return;
    }

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
          '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.mp4';

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
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
          folderId: null,
          tagIds: const <String>[],
        );
        final savedRecording = await addRecording(newRecording, userId);
        if (savedRecording != null) {
          unawaited(
            _syncRecordingWithApiAndTranscription(savedRecording, userId),
          );
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
    String? finalTranscription;
    String? apiTranscriptionId = recording.apiTranscriptionId;

    if (recording.apiAudioId != null) {
      final existingData = await _checkExistingTranscription(
        recording.apiAudioId!,
      );
      if (existingData != null) {
        finalTranscription = existingData['text'];
        apiTranscriptionId = existingData['id'];

        if (finalTranscription != null &&
            finalTranscription.trim().isNotEmpty) {
          final updatedRecording = Recording(
            id: recording.id,
            path: recording.path,
            name: recording.name,
            date: recording.date,
            duration: recording.duration,
            apiAudioId: recording.apiAudioId,
            apiTranscriptionId: apiTranscriptionId,
            folderId: recording.folderId,
            tagIds: recording.tagIds,
            transcription: finalTranscription,
          );

          await _updateRecordingUseCase(updatedRecording, userId);
          final index = _recordings.indexWhere((rec) => rec.id == recording.id);
          if (index != -1) {
            _recordings[index] = updatedRecording;
            notifyListeners();
          }
          return;
        }
      }
    }

    if (recording.path.isEmpty) {
      // No podemos transcribir localmente si no hay archivo, 
      // y ya verificamos que no hay transcripción en el servidor arriba.
      return;
    }

    final transcription = await _transcribeAudio(recording.path);
    if (transcription == null || transcription.trim().isEmpty) {
      return;
    }

    finalTranscription = transcription;

    if (recording.apiAudioId != null) {
      await _updateAudioRemoteTranscription(
        recording.apiAudioId!,
        transcription,
      );

      final createdTranscriptionId = await _createTranscriptionRecord(
        recording.apiAudioId!,
        transcription,
      );

      if (createdTranscriptionId != null && createdTranscriptionId.isNotEmpty) {
        apiTranscriptionId = createdTranscriptionId;
      }
    }

    final updatedRecording = Recording(
      id: recording.id,
      path: recording.path,
      name: recording.name,
      date: recording.date,
      duration: recording.duration,
      apiAudioId: recording.apiAudioId,
      apiTranscriptionId: apiTranscriptionId,
      folderId: recording.folderId,
      tagIds: recording.tagIds,
      transcription: finalTranscription,
    );

    final result = await _updateRecordingUseCase(updatedRecording, userId);
    if (!result.isSuccess) return;

    final index = _recordings.indexWhere((rec) => rec.id == recording.id);
    if (index == -1) return;

    _recordings[index] = updatedRecording;
    notifyListeners();
  }

  Future<Map<String, String>?> _checkExistingTranscription(
    String apiAudioId,
  ) async {
    try {
      final token = _sharedPrefsService.getToken();
      if (token == null || token.isEmpty) return null;

      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/transcriptions/?audioId=$apiAudioId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final first = data.first as Map<String, dynamic>;
          return {
            'id': first['_id']?.toString() ?? '',
            'text': first['text']?.toString() ?? '',
          };
        }
      }
    } catch (_) {}
    return null;
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
        apiTranscriptionId: recording.apiTranscriptionId,
        folderId: recording.folderId,
        tagIds: recording.tagIds,
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

      final request =
          http.MultipartRequest(
              'POST',
              Uri.parse('$_baseUrl/mindvoice-api/analyze/audio'),
            )
            ..headers['Authorization'] = 'Bearer $token'
            ..files.add(
              await http.MultipartFile.fromPath(
                'audio',
                path,
                contentType: MediaType('audio', 'mp4'),
                filename: path.split('/').last.split('\\').last,
              ),
            );

      final streamedResponse = await _httpClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode != 200) {
        String errorMsg = 'No se pudo transcribir el audio en este momento.';
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMsg = errorData['message'].toString();
          }
        } catch (_) {}

        _markHttpError(response.statusCode, errorMsg);
        notifyListeners();
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
      _markNetworkException(e);
      notifyListeners();
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

      final request =
          http.MultipartRequest('POST', Uri.parse('$_baseUrl/audios/upload'))
            ..headers['Authorization'] = 'Bearer $token'
            ..fields['duration'] = recording.duration.inSeconds.toString()
            ..fields['title'] = recording.name
            ..fields['folderId'] = recording.folderId ?? ''
            ..fields['tagIds'] = recording.tagIds.join(',')
            ..files.add(
              await http.MultipartFile.fromPath(
                'file',
                recording.path,
                contentType: MediaType('audio', 'mp4'),
                filename: recording.path.split('/').last.split('\\').last,
              ),
            );

      final streamedResponse = await _httpClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode != 201 && response.statusCode != 200) {
        _markHttpError(
          response.statusCode,
          'No se pudo subir el audio al servidor.',
        );
        notifyListeners();
        return null;
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      return data['_id']?.toString();
    } catch (e) {
      _markNetworkException(e);
      notifyListeners();
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

      final ok = response.statusCode == 204 || response.statusCode == 200;
      if (!ok) {
        _markHttpError(
          response.statusCode,
          'No se pudo eliminar el audio en el servidor.',
        );
        notifyListeners();
      }

      return ok;
    } catch (e) {
      _markNetworkException(e);
      notifyListeners();
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

      final response = await _httpClient.put(
        Uri.parse('$_baseUrl/audios/$apiAudioId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'transcription': transcription}),
      );

      if (response.statusCode != 200) {
        _markHttpError(
          response.statusCode,
          'No se pudo guardar la transcripción en el servidor.',
        );
        notifyListeners();
      }
    } catch (e) {
      _markNetworkException(e);
      notifyListeners();
    }
  }

  Future<bool> _updateAudioRemoteMetadata(
    String apiAudioId, {
    String? folderId,
    List<String> tagIds = const <String>[],
  }) async {
    try {
      final token = _sharedPrefsService.getToken();
      if (token == null || token.isEmpty) {
        return false;
      }

      final response = await _httpClient.put(
        Uri.parse('$_baseUrl/audios/$apiAudioId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'folderId': folderId, 'tagIds': tagIds}),
      );

      final ok = response.statusCode == 200;
      if (!ok) {
        _markHttpError(
          response.statusCode,
          'No se pudieron actualizar carpeta y tags del audio.',
        );
        notifyListeners();
      }

      return ok;
    } catch (e) {
      _markNetworkException(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> _updateAudioRemoteTitle(String apiAudioId, String title) async {
    try {
      final token = _sharedPrefsService.getToken();
      if (token == null || token.isEmpty) {
        return false;
      }

      final response = await _httpClient.put(
        Uri.parse('$_baseUrl/audios/$apiAudioId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'title': title}),
      );

      final ok = response.statusCode == 200;
      if (!ok) {
        _markHttpError(
          response.statusCode,
          'No se pudo actualizar el nombre del audio en el servidor.',
        );
        notifyListeners();
      }

      return ok;
    } catch (e) {
      _markNetworkException(e);
      notifyListeners();
      return false;
    }
  }

  Future<String?> _createTranscriptionRecord(
    String apiAudioId,
    String transcription,
  ) async {
    try {
      final token = _sharedPrefsService.getToken();
      if (token == null || token.isEmpty) {
        return null;
      }

      final response = await _httpClient.post(
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

      if (response.statusCode != 200 && response.statusCode != 201) {
        _markHttpError(
          response.statusCode,
          'No se pudo crear el registro de transcripción.',
        );
        notifyListeners();
        return null;
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      return data['_id']?.toString();
    } catch (e) {
      _markNetworkException(e);
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> analyzeRecordingWithIa(
    String recordingId,
    String userId,
  ) async {
    _isAnalyzing = true;
    notifyListeners();

    try {
      final index = _recordings.indexWhere((rec) => rec.id == recordingId);
      if (index == -1) {
        _errorMessage = 'No se encontró la grabación a analizar.';
        return null;
      }

      var recording = _recordings[index];

      final token = _sharedPrefsService.getToken();
      if (token == null || token.isEmpty) {
        _errorMessage = 'Sesión expirada. Inicia sesión de nuevo.';
        return null;
      }

      // 1) REVISIÓN DE BASE DE DATOS PARA ANÁLISIS EXISTENTE
      if (recording.apiTranscriptionId != null &&
          recording.apiTranscriptionId!.isNotEmpty) {
        final existingRes = await _httpClient.get(
          Uri.parse(
            '$_baseUrl/ai-analyses/?transcriptionId=${recording.apiTranscriptionId}',
          ),
          headers: {'Authorization': 'Bearer $token'},
        );
        if (existingRes.statusCode == 200) {
          final List<dynamic> data = jsonDecode(existingRes.body);
          if (data.isNotEmpty) {
            final firstAnalysis = data.first as Map<String, dynamic>;
            if (firstAnalysis.containsKey('result')) {
              _lastAiResult = firstAnalysis['result'] as Map<String, dynamic>;
              _errorMessage = null;
              return _lastAiResult;
            }
          }
        }
      }

      if (!_hasRealTranscription(recording.transcription)) {
        await transcribeRecordingIfNeeded(recordingId, userId);
        final refreshIndex = _recordings.indexWhere(
          (rec) => rec.id == recordingId,
        );
        if (refreshIndex == -1) {
          _errorMessage = 'No se encontró la grabación a analizar.';
          return null;
        }
        recording = _recordings[refreshIndex];
      }

      final Map<String, dynamic> payload =
          recording.apiTranscriptionId != null &&
              recording.apiTranscriptionId!.isNotEmpty
          ? {'transcriptionId': recording.apiTranscriptionId}
          : {'text': recording.transcription ?? ''};

      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/mindvoice-api/analyze/text'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode != 200) {
        _markHttpError(
          response.statusCode,
          'No se pudo analizar el audio con IA.',
        );
        return null;
      }

      _lastAiResult = jsonDecode(response.body) as Map<String, dynamic>;
      _errorMessage = null;
      return _lastAiResult;
    } catch (e) {
      _markNetworkException(e);
      return null;
    } finally {
      _isAnalyzing = false;
      notifyListeners();
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
        apiTranscriptionId: recording.apiTranscriptionId,
        folderId: recording.folderId,
        tagIds: recording.tagIds,
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
