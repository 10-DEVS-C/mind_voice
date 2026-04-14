import 'package:mind_voice/features/audio_recorder/domain/entities/recording.dart';

class RecordingModel extends Recording {
  RecordingModel({
    required String id,
    required String path,
    required String name,
    required DateTime date,
    required Duration duration,
    String? apiAudioId,
    String? apiTranscriptionId,
    String? transcription,
  }) : super(
         id: id,
         path: path,
         name: name,
         date: date,
         duration: duration,
         apiAudioId: apiAudioId,
         apiTranscriptionId: apiTranscriptionId,
         transcription: transcription,
       );

  factory RecordingModel.fromJson(Map<String, dynamic> json) {
    return RecordingModel(
      id: json['id'],
      path: json['path'],
      name: json['name'],
      date: DateTime.parse(json['date']),
      duration: Duration(milliseconds: json['durationMs']),
      apiAudioId: json['apiAudioId'],
      apiTranscriptionId: json['apiTranscriptionId'],
      transcription: json['transcription'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'name': name,
      'date': date.toIso8601String(),
      'durationMs': duration.inMilliseconds,
      'apiAudioId': apiAudioId,
      'apiTranscriptionId': apiTranscriptionId,
      'transcription': transcription,
    };
  }
}
