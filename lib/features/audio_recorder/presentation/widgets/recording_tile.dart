import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mind_voice/features/audio_recorder/domain/entities/recording.dart';
import 'package:mind_voice/features/audio_recorder/presentation/pages/recording_detail_page.dart';

class RecordingTile extends StatelessWidget {
  final Recording recording;
  final VoidCallback onDelete;

  const RecordingTile({
    super.key,
    required this.recording,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d, yyyy - HH:mm').format(recording.date);
    final durationStr =
        '${recording.duration.inMinutes}:${(recording.duration.inSeconds % 60).toString().padLeft(2, '0')}';

    return Dismissible(
      key: Key(recording.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.audiotrack)),
        title: Text(recording.name),
        subtitle: Text(dateStr),
        trailing: Text(durationStr),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RecordingDetailPage(recording: recording),
            ),
          );
        },
      ),
    );
  }
}
