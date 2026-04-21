import '../../domain/entities/transcription.dart';

class TranscriptionModel extends Transcription {
  const TranscriptionModel({
    required String id,
    required String userId,
    required String audioId,
    required String text,
    List<Map<String, dynamic>> timestamps = const [],
    DateTime? createdAt,
  }) : super(
          id: id,
          userId: userId,
          audioId: audioId,
          text: text,
          timestamps: timestamps,
          createdAt: createdAt,
        );

  factory TranscriptionModel.fromJson(Map<String, dynamic> json) {
    return TranscriptionModel(
      id: json['_id'] as String,
      userId: (json['userId'] ?? '') as String,
      audioId: (json['audioId'] ?? '') as String,
      text: (json['text'] ?? '') as String,
      timestamps: (json['timestamps'] as List<dynamic>? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'userId': userId,
        'audioId': audioId,
        'text': text,
        'timestamps': timestamps,
        'createdAt': createdAt?.toIso8601String(),
      };
}
