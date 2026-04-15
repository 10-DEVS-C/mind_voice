class Recording {
  final String id;
  final String path;
  final String name;
  final DateTime date;
  final Duration duration;

  Recording({
    required this.id,
    required this.path,
    required this.name,
    required this.date,
    required this.duration,
    this.apiAudioId,
    this.apiTranscriptionId,
    this.folderId,
    this.tagIds = const <String>[],
    this.transcription,
  });

  final String? apiAudioId;
  final String? apiTranscriptionId;
  final String? folderId;
  final List<String> tagIds;
  final String? transcription;
}
