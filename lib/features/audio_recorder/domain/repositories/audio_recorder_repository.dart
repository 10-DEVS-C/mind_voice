import 'package:mind_voice/core/utils/result.dart';
import 'package:mind_voice/features/audio_recorder/domain/entities/recording.dart';

abstract class AudioRecorderRepository {
  Future<Result<List<Recording>>> getRecordings();
  Future<Result<Recording>> saveRecording(Recording recording);
  Future<Result<void>> deleteRecording(String id);
}
