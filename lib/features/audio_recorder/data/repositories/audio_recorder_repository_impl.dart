import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:mind_voice/core/utils/result.dart';
import 'package:mind_voice/features/audio_recorder/data/models/recording_model.dart';
import 'package:mind_voice/features/audio_recorder/domain/entities/recording.dart';
import 'package:mind_voice/features/audio_recorder/domain/repositories/audio_recorder_repository.dart';

class AudioRecorderRepositoryImpl implements AudioRecorderRepository {
  final List<RecordingModel> _dummyData = [
    RecordingModel(
      id: '1',
      path: 'path/to/recording1.aac',
      name: 'Meeting notes',
      date: DateTime.now().subtract(const Duration(days: 1)),
      duration: const Duration(minutes: 2, seconds: 30),
    ),
    RecordingModel(
      id: '2',
      path: 'path/to/recording2.aac',
      name: 'Idea for app',
      date: DateTime.now().subtract(const Duration(hours: 5)),
      duration: const Duration(seconds: 45),
    ),
    RecordingModel(
      id: '3',
      path: 'path/to/recording3.aac',
      name: 'Grocery list',
      date: DateTime.now().subtract(const Duration(minutes: 30)),
      duration: const Duration(minutes: 1, seconds: 15),
    ),
  ];

  @override
  Future<Result<List<Recording>>> getRecordings() async {
    // Simulate network/db delay
    await Future.delayed(const Duration(milliseconds: 500));
    return Result.success(_dummyData);
  }

  @override
  Future<Result<Recording>> saveRecording(Recording recording) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final model = RecordingModel(
      id: const Uuid().v4(), // Generate new ID
      path: recording.path,
      name: recording.name,
      date: recording.date,
      duration: recording.duration,
    );
    _dummyData.add(model);
    return Result.success(model);
  }

  @override
  Future<Result<void>> deleteRecording(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _dummyData.removeWhere((rec) => rec.id == id);
    return Result.success(null);
  }
}
