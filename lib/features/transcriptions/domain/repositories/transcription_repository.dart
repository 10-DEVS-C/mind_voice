import '../entities/transcription.dart';
import '../../../../core/utils/result.dart';

abstract class TranscriptionRepository {
  Future<Result<Transcription>> getTranscription(String id);
  Future<Result<Transcription>> updateTranscription(String id, String text);
  Future<Result<List<Transcription>>> getTranscriptionsByAudio(String audioId);
}
