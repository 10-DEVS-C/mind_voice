class Transcription {
  final String id;
  final String userId;
  final String audioId;
  final String text;
  final List<Map<String, dynamic>> timestamps;
  final DateTime? createdAt;

  const Transcription({
    required this.id,
    required this.userId,
    required this.audioId,
    required this.text,
    this.timestamps = const [],
    this.createdAt,
  });
}
