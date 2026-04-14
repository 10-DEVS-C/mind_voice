import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/audio_recorder/presentation/providers/audio_recorder_provider.dart';
import '../../../../features/audio_recorder/domain/entities/recording.dart';
import '../../../../features/audio_recorder/presentation/widgets/recording_player_widget.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId != null) {
        context.read<AudioRecorderProvider>().loadRecordings(userId);
      }
    });
  }

  void _showTranscriptionModal(BuildContext context, Recording recording) {
    final l10n = AppLocalizations.of(context)!;
    final userId = context.read<AuthProvider>().user?.id;

    if (userId != null && (recording.transcription?.trim().isNotEmpty != true)) {
      unawaited(
        context.read<AudioRecorderProvider>().transcribeRecordingIfNeeded(
          recording.id,
          userId,
        ),
      );
    }

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
                  l10n.translate('transcription'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await _confirmDeleteRecording(context, recording);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
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
              child: Consumer<AudioRecorderProvider>(
                builder: (context, provider, child) {
                  final currentRecording = provider.recordings.firstWhere(
                    (rec) => rec.id == recording.id,
                    orElse: () => recording,
                  );

                  final transcriptionText =
                      currentRecording.transcription?.trim().isNotEmpty == true
                      ? currentRecording.transcription!
                      : provider.isTranscribing(currentRecording.id)
                      ? "Analizando audio... La transcripción aparecerá aquí una vez procesada por la IA."
                      : "No se pudo transcribir este audio todavía. Vuelve a abrir este modal para reintentar.";

                  return SingleChildScrollView(
                    child: Text(
                      transcriptionText,
                      style: const TextStyle(fontSize: 15, height: 1.6),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onNavigateToInsights();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6D28D9),
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

  Future<void> _confirmDeleteRecording(
    BuildContext context,
    Recording recording,
  ) async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar audio'),
          content: Text('Se eliminará "${recording.name}". Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirm != true || !context.mounted) {
      return;
    }

    final deleted = await context.read<AudioRecorderProvider>().deleteRecording(recording.id, userId);
    if (!context.mounted) {
      return;
    }

    if (deleted) {
      Navigator.pop(context);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No se pudo eliminar el audio. Intenta de nuevo.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.translate('audios'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 28,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tu biblioteca de ideas y grabaciones',
            style: TextStyle(
              color: isDarkMode
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Consumer<AudioRecorderProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.recordings.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.translate('libraryEmpty'),
                      style: const TextStyle(color: Colors.blueGrey),
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
                          color: isDarkMode
                              ? AppColors.darkSurface.withOpacity(0.92)
                              : Colors.white.withOpacity(0.96),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDarkMode
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDarkMode ? 0.18 : 0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6D28D9).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                color: Color(0xFF6D28D9),
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
    final l10n = AppLocalizations.of(context)!;
    final titleController = TextEditingController(text: recording.name);
    final userId = context.read<AuthProvider>().user?.id;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.translate('editTitle')),
        content: TextField(
          controller: titleController,
          decoration: InputDecoration(hintText: l10n.translate('newTitle')),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty && userId != null) {
                // Update in Provider
                context.read<AudioRecorderProvider>().updateRecordingTitle(
                  recording.id,
                  titleController.text,
                  userId,
                );
                Navigator.pop(context); // Close modal
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6D28D9),
            ),
            child: Text(
              l10n.translate('save'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
