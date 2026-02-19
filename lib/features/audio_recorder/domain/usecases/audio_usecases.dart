import 'package:mind_voice/core/utils/result.dart';
import 'package:mind_voice/features/audio_recorder/domain/entities/recording.dart';
import 'package:mind_voice/features/audio_recorder/domain/repositories/audio_recorder_repository.dart';

class GetRecordingsUseCase {
  final AudioRecorderRepository repository;

  GetRecordingsUseCase(this.repository);

  Future<Result<List<Recording>>> call() {
    return repository.getRecordings();
  }
}

class SaveRecordingUseCase {
  final AudioRecorderRepository repository;

  SaveRecordingUseCase(this.repository);

  Future<Result<Recording>> call(Recording recording) {
    return repository.saveRecording(recording);
  }
}

class DeleteRecordingUseCase {
  final AudioRecorderRepository repository;

  DeleteRecordingUseCase(this.repository);

  Future<Result<void>> call(String id) {
    return repository.deleteRecording(id);
  }
}

class UpdateRecordingUseCase {
  final AudioRecorderRepository repository;

  UpdateRecordingUseCase(this.repository);

  Future<Result<void>> call(Recording recording) {
    return repository.updateRecording(recording);
  }
}
