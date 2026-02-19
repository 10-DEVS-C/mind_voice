import 'package:mind_voice/core/utils/result.dart';
import 'package:mind_voice/features/audio_recorder/domain/entities/recording.dart';

abstract class AudioRecorderRepository {
  Future<Result<List<Recording>>> getRecordings(String userId);
  Future<Result<Recording>> saveRecording(Recording recording, String userId);
  Future<Result<void>> deleteRecording(String id, String userId);
  Future<Result<void>> updateRecording(Recording recording, String userId);
}
