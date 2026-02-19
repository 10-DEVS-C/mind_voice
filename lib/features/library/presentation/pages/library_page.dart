import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../features/audio_recorder/presentation/providers/audio_recorder_provider.dart';
import '../../../../features/audio_recorder/domain/entities/recording.dart';
import '../../../../features/audio_recorder/presentation/widgets/recording_player_widget.dart';

class LibraryPage extends StatefulWidget {
  final VoidCallback onNavigateToInsights;
  const LibraryPage({super.key, required this.onNavigateToInsights});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  @override
  void initState() {
    super.initState();
    // Load recordings if empty or refresh needed.
    // For now, we assume provider keeps state, but good to refresh on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AudioRecorderProvider>().loadRecordings();
    });
  }

  void _showTranscriptionModal(BuildContext context, Recording recording) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Transcripción",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    recording.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () {
                    _showEditTitleDialog(context, recording);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('dd MMM yyyy - HH:mm').format(recording.date),
              style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
            ),
            const SizedBox(height: 24),
            RecordingPlayerWidget(
              audioPath: recording.path,
              totalDuration: recording.duration,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  recording.transcription ??
                      "Analizando audio... La transcripción aparecerá aquí una vez procesada por la IA.",
                  style: const TextStyle(fontSize: 15, height: 1.6),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onNavigateToInsights();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "VER DOC",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tus Audios",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Consumer<AudioRecorderProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.recordings.isEmpty) {
                  return const Center(
                    child: Text(
                      "No tienes grabaciones aún.",
                      style: TextStyle(color: Colors.blueGrey),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: provider.recordings.length,
                  itemBuilder: (context, index) {
                    final recording = provider.recordings[index];
                    final duration =
                        "${recording.duration.inMinutes.toString().padLeft(2, '0')}:${(recording.duration.inSeconds % 60).toString().padLeft(2, '0')}";
                    final date = DateFormat(
                      'dd MMM yyyy',
                    ).format(recording.date);

                    return GestureDetector(
                      onTap: () => _showTranscriptionModal(context, recording),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C3AED).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                color: Color(0xFF8B5CF6),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    recording.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "$duration • $date",
                                    style: const TextStyle(
                                      color: Colors.blueGrey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.blueGrey,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showEditTitleDialog(BuildContext context, Recording recording) {
    final titleController = TextEditingController(text: recording.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Editar Título"),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(hintText: "Nuevo título"),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                // Update in Provider
                context.read<AudioRecorderProvider>().updateRecordingTitle(
                  recording.id,
                  titleController.text,
                );

                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close modal
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
            ),
            child: const Text("Guardar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
