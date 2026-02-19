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

  AudioRecorderRepositoryImpl(this._sharedPrefsService);

  String _getKey(String userId) => 'recordings_$userId';

  Future<List<RecordingModel>> _loadFromPrefs(String userId) async {
    final jsonString = _sharedPrefsService.prefs.getString(_getKey(userId));
    if (jsonString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.map((e) => RecordingModel.fromJson(e)).toList();
      } catch (e) {
        print("Error loading recordings: $e");
      }
    }
    return [];
  }

  Future<void> _saveToPrefs(
    String userId,
    List<RecordingModel> recordings,
  ) async {
    final jsonString = jsonEncode(recordings.map((e) => e.toJson()).toList());
    await _sharedPrefsService.prefs.setString(_getKey(userId), jsonString);
  }

  @override
  Future<Result<List<Recording>>> getRecordings(String userId) async {
    final recordings = await _loadFromPrefs(userId);
    return Result.success(List.from(recordings));
  }

  @override
  Future<Result<Recording>> saveRecording(
    Recording recording,
    String userId,
  ) async {
    final recordings = await _loadFromPrefs(userId);
    final model = RecordingModel(
      id: const Uuid().v4(), // Generate new ID
      path: recording.path,
      name: recording.name,
      date: recording.date,
      duration: recording.duration,
      transcription: recording.transcription,
    );
    recordings.add(model);
    await _saveToPrefs(userId, recordings);
    return Result.success(model);
  }

  @override
  Future<Result<void>> deleteRecording(String id, String userId) async {
    final recordings = await _loadFromPrefs(userId);
    recordings.removeWhere((rec) => rec.id == id);
    await _saveToPrefs(userId, recordings);
    return Result.success(null);
  }

  @override
  Future<Result<void>> updateRecording(
    Recording recording,
    String userId,
  ) async {
    final recordings = await _loadFromPrefs(userId);
    final index = recordings.indexWhere((rec) => rec.id == recording.id);
    if (index != -1) {
      recordings[index] = RecordingModel(
        id: recording.id,
        path: recording.path,
        name: recording.name,
        date: recording.date,
        duration: recording.duration,
        transcription: recording.transcription,
      );
      await _saveToPrefs(userId, recordings);
      return Result.success(null);
    }
    return Result.failure("Recording not found");
  }
}
