import 'package:mind_voice/features/audio_recorder/domain/entities/recording.dart';

class RecordingModel extends Recording {
  RecordingModel({
    required String id,
    required String path,
    required String name,
    required DateTime date,
    required Duration duration,
  }) : super(id: id, path: path, name: name, date: date, duration: duration);

  factory RecordingModel.fromJson(Map<String, dynamic> json) {
    return RecordingModel(
      id: json['id'],
      path: json['path'],
      name: json['name'],
      date: DateTime.parse(json['date']),
      duration: Duration(milliseconds: json['durationMs']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'name': name,
      'date': date.toIso8601String(),
      'durationMs': duration.inMilliseconds,
    };
  }
}
