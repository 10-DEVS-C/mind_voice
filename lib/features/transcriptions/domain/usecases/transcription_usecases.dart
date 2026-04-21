import '../../../../core/utils/result.dart';
import '../entities/transcription.dart';
import '../repositories/transcription_repository.dart';

class GetTranscriptionUseCase {
  final TranscriptionRepository repository;
  GetTranscriptionUseCase(this.repository);
  Future<Result<Transcription>> call(String id) => repository.getTranscription(id);
}

class UpdateTranscriptionUseCase {
  final TranscriptionRepository repository;
  UpdateTranscriptionUseCase(this.repository);
  Future<Result<Transcription>> call(String id, String text) =>
      repository.updateTranscription(id, text);
}

class GetTranscriptionsByAudioUseCase {
  final TranscriptionRepository repository;
  GetTranscriptionsByAudioUseCase(this.repository);
  Future<Result<List<Transcription>>> call(String audioId) =>
      repository.getTranscriptionsByAudio(audioId);
}
