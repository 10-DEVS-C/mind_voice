import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:mind_voice/features/audio_recorder/domain/entities/recording.dart';
import 'package:mind_voice/features/audio_recorder/domain/usecases/audio_usecases.dart';

class AudioRecorderProvider extends ChangeNotifier {
  final GetRecordingsUseCase _getRecordingsUseCase;
  final SaveRecordingUseCase _saveRecordingUseCase;
  final DeleteRecordingUseCase _deleteRecordingUseCase;
  final UpdateRecordingUseCase _updateRecordingUseCase;

  List<Recording> _recordings = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isRecording = false;
  final AudioRecorder _audioRecorder = AudioRecorder();
  DateTime? _startTime;

  List<Recording> get recordings => _recordings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isRecording => _isRecording;

  AudioRecorderProvider({
    required GetRecordingsUseCase getRecordingsUseCase,
    required SaveRecordingUseCase saveRecordingUseCase,
    required DeleteRecordingUseCase deleteRecordingUseCase,
    required UpdateRecordingUseCase updateRecordingUseCase,
  }) : _getRecordingsUseCase = getRecordingsUseCase,
       _saveRecordingUseCase = saveRecordingUseCase,
       _deleteRecordingUseCase = deleteRecordingUseCase,
       _updateRecordingUseCase = updateRecordingUseCase;

  Future<void> loadRecordings(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _getRecordingsUseCase(userId);

    if (result.isSuccess) {
      _recordings = List.from(result.data!);
      // Sort by date descending
      _recordings.sort((a, b) => b.date.compareTo(a.date));
    } else {
      _errorMessage = result.error;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addRecording(Recording recording, String userId) async {
    final result = await _saveRecordingUseCase(recording, userId);
    if (result.isSuccess) {
      _recordings.insert(0, result.data!);
      notifyListeners();
    }
  }

  Future<void> deleteRecording(String id, String userId) async {
    final result = await _deleteRecordingUseCase(id, userId);
    if (result.isSuccess) {
      _recordings.removeWhere((rec) => rec.id == id);
      notifyListeners();
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
          transcription:
              "Transcripción dummy para demostración. El audio se ha grabado correctamente en: $path. Aquí iría el texto procesado por la IA.",
        );
        await addRecording(newRecording, userId);
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
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
