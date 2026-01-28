import 'package:flutter/foundation.dart';

import 'package:mind_voice/features/audio_recorder/domain/entities/recording.dart';
import 'package:mind_voice/features/audio_recorder/domain/usecases/audio_usecases.dart';

class AudioRecorderProvider extends ChangeNotifier {
  final GetRecordingsUseCase _getRecordingsUseCase;
  final SaveRecordingUseCase _saveRecordingUseCase;
  final DeleteRecordingUseCase _deleteRecordingUseCase;

  List<Recording> _recordings = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isRecording = false; // Simulated recording state

  List<Recording> get recordings => _recordings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isRecording => _isRecording;

  AudioRecorderProvider({
    required GetRecordingsUseCase getRecordingsUseCase,
    required SaveRecordingUseCase saveRecordingUseCase,
    required DeleteRecordingUseCase deleteRecordingUseCase,
  }) : _getRecordingsUseCase = getRecordingsUseCase,
       _saveRecordingUseCase = saveRecordingUseCase,
       _deleteRecordingUseCase = deleteRecordingUseCase;

  Future<void> loadRecordings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _getRecordingsUseCase();

    if (result.isSuccess) {
      _recordings = result.data!;
    } else {
      _errorMessage = result.error;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addRecording(Recording recording) async {
    final result = await _saveRecordingUseCase(recording);
    if (result.isSuccess) {
      _recordings.add(result.data!);
      notifyListeners();
    }
  }

  Future<void> deleteRecording(String id) async {
    final result = await _deleteRecordingUseCase(id);
    if (result.isSuccess) {
      _recordings.removeWhere((rec) => rec.id == id);
      notifyListeners();
    }
  }

  void startRecording() {
    _isRecording = true;
    notifyListeners();
  }

  void stopRecording() async {
    _isRecording = false;
    // Simulate saving a recording after stopping
    final newRecording = Recording(
      id: '', // Repo will assign ID
      path: 'dummy/path.aac',
      name: 'New Recording ${DateTime.now().second}',
      date: DateTime.now(),
      duration: const Duration(seconds: 10), // Dummy duration
    );
    await addRecording(newRecording);
    notifyListeners();
  }
}
