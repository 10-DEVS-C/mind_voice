import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:mind_voice/core/utils/result.dart';
import 'package:mind_voice/features/audio_recorder/data/models/recording_model.dart';
import 'package:mind_voice/features/audio_recorder/domain/entities/recording.dart';
import 'dart:convert';
import 'package:mind_voice/core/services/shared_prefs_service.dart';
import 'package:mind_voice/features/audio_recorder/domain/repositories/audio_recorder_repository.dart';

class AudioRecorderRepositoryImpl implements AudioRecorderRepository {
  final SharedPrefsService _sharedPrefsService;
  List<RecordingModel> _recordings = [];
  bool _initialized = false;

  AudioRecorderRepositoryImpl(this._sharedPrefsService);

  Future<void> _init() async {
    if (_initialized) return;
    final jsonString = _sharedPrefsService.prefs.getString('recordings');
    if (jsonString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        _recordings = decoded.map((e) => RecordingModel.fromJson(e)).toList();
      } catch (e) {
        print("Error loading recordings: $e");
      }
    }
    _initialized = true;
  }

  Future<void> _saveToPrefs() async {
    final jsonString = jsonEncode(_recordings.map((e) => e.toJson()).toList());
    await _sharedPrefsService.prefs.setString('recordings', jsonString);
  }

  @override
  Future<Result<List<Recording>>> getRecordings() async {
    await _init();
    return Result.success(List.from(_recordings));
  }

  @override
  Future<Result<Recording>> saveRecording(Recording recording) async {
    await _init();
    final model = RecordingModel(
      id: const Uuid().v4(), // Generate new ID
      path: recording.path,
      name: recording.name,
      date: recording.date,
      duration: recording.duration,
      transcription: recording.transcription,
    );
    _recordings.add(model);
    await _saveToPrefs();
    return Result.success(model);
  }

  @override
  Future<Result<void>> deleteRecording(String id) async {
    await _init();
    _recordings.removeWhere((rec) => rec.id == id);
    await _saveToPrefs();
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateRecording(Recording recording) async {
    await _init();
    final index = _recordings.indexWhere((rec) => rec.id == recording.id);
    if (index != -1) {
      _recordings[index] = RecordingModel(
        id: recording.id,
        path: recording.path,
        name: recording.name,
        date: recording.date,
        duration: recording.duration,
        transcription: recording.transcription,
      );
      await _saveToPrefs();
      return Result.success(null);
    }
    return Result.failure("Recording not found");
  }
}
