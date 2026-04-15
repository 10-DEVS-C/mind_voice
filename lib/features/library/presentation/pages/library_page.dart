import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/errors/request_error_mapper.dart';
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
      unawaited(context.read<AudioRecorderProvider>().loadTaxonomyOptions());
    });
  }

  void _showTranscriptionModal(BuildContext context, Recording recording) {
    final l10n = AppLocalizations.of(context)!;
    final userId = context.read<AuthProvider>().user?.id;

    if (userId != null &&
        (recording.transcription?.trim().isNotEmpty != true)) {
      unawaited(
        context.read<AudioRecorderProvider>().transcribeRecordingIfNeeded(
          recording.id,
          userId,
        ),
      );
    }

    final audioProvider = context.read<AudioRecorderProvider>();
    if (audioProvider.availableFolders.isEmpty ||
        audioProvider.availableTags.isEmpty) {
      unawaited(audioProvider.loadTaxonomyOptions());
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.78,
        minChildSize: 0.55,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                controller: scrollController,
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.translate('transcription'),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                await _confirmDeleteRecording(
                                  context,
                                  recording,
                                );
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
                      style: const TextStyle(
                        color: Colors.blueGrey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 24),
                    RecordingPlayerWidget(
                      audioPath: recording.path,
                      totalDuration: recording.duration,
                    ),
                    const SizedBox(height: 12),
                    Consumer<AudioRecorderProvider>(
                      builder: (context, provider, child) {
                        final currentRecording = provider.recordings.firstWhere(
                          (rec) => rec.id == recording.id,
                          orElse: () => recording,
                        );
                        final isLoadingTaxonomy = provider.isLoadingTaxonomy;

                        final folderName = provider.availableFolders.firstWhere(
                          (f) => f['id'] == currentRecording.folderId,
                          orElse: () => const {'name': 'Sin carpeta'},
                        )['name'];

                        final selectedTags = provider.availableTags
                            .where(
                              (t) => currentRecording.tagIds.contains(t['id']),
                            )
                            .map((e) => e['name']!)
                            .toList();

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isLoadingTaxonomy) ...[
                                Row(
                                  children: const [
                                    SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Cargando carpetas y tags...',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                              ],
                              Row(
                                children: [
                                  const Icon(
                                    Icons.folder_open_outlined,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Carpeta: ${folderName ?? 'Sin carpeta'}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => _showAssignMetadataSheet(
                                      context,
                                      currentRecording,
                                    ),
                                    child: const Text('Editar'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: selectedTags.isEmpty
                                    ? const [
                                        Text(
                                          'Sin tags asignados',
                                          style: TextStyle(
                                            color: Colors.blueGrey,
                                          ),
                                        ),
                                      ]
                                    : selectedTags
                                          .map(
                                            (name) => Chip(
                                              label: Text(name),
                                              visualDensity:
                                                  VisualDensity.compact,
                                            ),
                                          )
                                          .toList(),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Consumer<AudioRecorderProvider>(
                      builder: (context, provider, child) {
                        final currentRecording = provider.recordings.firstWhere(
                          (rec) => rec.id == recording.id,
                          orElse: () => recording,
                        );

                        final hasError =
                            provider.errorMessage != null &&
                            !provider.isTranscribing(currentRecording.id) &&
                            currentRecording.transcription?.trim().isNotEmpty !=
                                true;
                        final transcriptionText =
                            currentRecording.transcription?.trim().isNotEmpty ==
                                true
                            ? currentRecording.transcription!
                            : provider.isTranscribing(currentRecording.id)
                            ? "Analizando audio... La transcripción aparecerá aquí una vez procesada por la IA."
                            : hasError
                            ? "Error del servidor:\n${provider.errorMessage}\n\nVuelve a abrir este modal para reintentar."
                            : "No se pudo transcribir este audio todavía. Vuelve a abrir este modal para reintentar.";

                        return Text(
                          transcriptionText,
                          style: const TextStyle(fontSize: 15, height: 1.6),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        final userId = context.read<AuthProvider>().user?.id;
                        Map<String, dynamic>? result;
                        if (userId != null) {
                          result = await context
                              .read<AudioRecorderProvider>()
                              .analyzeRecordingWithIa(recording.id, userId);
                        }

                        if (!context.mounted) {
                          return;
                        }

                        if (result == null) {
                          final error = context
                              .read<AudioRecorderProvider>()
                              .errorMessage;
                          if (error != null && error.trim().isNotEmpty) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(error)));
                          }
                          return;
                        }

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
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAssignMetadataSheet(
    BuildContext context,
    Recording recording,
  ) async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) {
      return;
    }

    final provider = context.read<AudioRecorderProvider>();
    await provider.loadTaxonomyOptions();
    if (!context.mounted) {
      return;
    }

    String? selectedFolderId = recording.folderId;
    final selectedTagIds = Set<String>.from(recording.tagIds);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            final folders = provider.availableFolders;
            final tags = provider.availableTags;
            final folderExists = selectedFolderId == null
                ? true
                : folders.any((f) => f['id'] == selectedFolderId);
            final dropdownFolderValue = folderExists ? selectedFolderId : null;

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Asignar carpeta y tags',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      value: dropdownFolderValue,
                      decoration: const InputDecoration(labelText: 'Carpeta'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Sin carpeta'),
                        ),
                        ...folders.map(
                          (f) => DropdownMenuItem<String?>(
                            value: f['id'],
                            child: Text(f['name'] ?? ''),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setModalState(() => selectedFolderId = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Tags',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: tags
                          .map(
                            (t) => FilterChip(
                              label: Text(t['name'] ?? ''),
                              selected: selectedTagIds.contains(t['id']),
                              onSelected: (selected) {
                                setModalState(() {
                                  if (selected) {
                                    selectedTagIds.add(t['id']!);
                                  } else {
                                    selectedTagIds.remove(t['id']);
                                  }
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final ok = await context
                            .read<AudioRecorderProvider>()
                            .assignRecordingMetadata(
                              recording.id,
                              userId,
                              folderId: selectedFolderId,
                              tagIds: selectedTagIds.toList(),
                            );

                        if (!sheetContext.mounted) {
                          return;
                        }

                        if (ok) {
                          Navigator.pop(sheetContext);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No se pudo guardar carpeta/tags.'),
                            ),
                          );
                        }
                      },
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
          content: Text(
            'Se eliminará "${recording.name}". Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true || !context.mounted) {
      return;
    }

    final deleted = await context.read<AudioRecorderProvider>().deleteRecording(
      recording.id,
      userId,
    );
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
                if (provider.errorMessage != null &&
                    RequestErrorMapper.isNetworkMessage(
                      provider.errorMessage!,
                    )) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        provider.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.blueGrey),
                      ),
                    ),
                  );
                }
                if (provider.recordings.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.translate('libraryEmpty'),
                      style: const TextStyle(color: Colors.blueGrey),
                    ),
                  );
                }
                final foldersById = <String, String>{
                  for (final f in provider.availableFolders)
                    if ((f['id'] ?? '').isNotEmpty)
                      f['id']!: f['name'] ?? 'Carpeta',
                };

                final groupedByFolder = <String, List<Recording>>{};
                final ungroupedRecordings = <Recording>[];

                for (final recording in provider.recordings) {
                  final folderId = recording.folderId;
                  if (folderId != null && foldersById.containsKey(folderId)) {
                    groupedByFolder
                        .putIfAbsent(folderId, () => <Recording>[])
                        .add(recording);
                  } else {
                    ungroupedRecordings.add(recording);
                  }
                }

                final folderIds = groupedByFolder.keys.toList()
                  ..sort(
                    (a, b) => (foldersById[a] ?? '').toLowerCase().compareTo(
                      (foldersById[b] ?? '').toLowerCase(),
                    ),
                  );

                return ListView(
                  children: [
                    if (ungroupedRecordings.isNotEmpty) ...[
                      _buildGroupTitle('Sin carpeta'),
                      const SizedBox(height: 8),
                      ...ungroupedRecordings.map(
                        (recording) =>
                            _buildRecordingCard(context, recording, isDarkMode),
                      ),
                      const SizedBox(height: 8),
                    ],
                    ...folderIds.map((folderId) {
                      final recordingsInFolder =
                          groupedByFolder[folderId] ?? <Recording>[];
                      final folderName = foldersById[folderId] ?? 'Carpeta';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
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
                              color: Colors.black.withOpacity(
                                isDarkMode ? 0.18 : 0.05,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ExpansionTile(
                          key: PageStorageKey<String>('folder_$folderId'),
                          leading: const Icon(Icons.folder_open_outlined),
                          title: Text(
                            folderName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('${recordingsInFolder.length} audios'),
                          childrenPadding: const EdgeInsets.fromLTRB(
                            12,
                            0,
                            12,
                            8,
                          ),
                          children: recordingsInFolder
                              .map(
                                (recording) => _buildRecordingCard(
                                  context,
                                  recording,
                                  isDarkMode,
                                  margin: const EdgeInsets.only(bottom: 10),
                                ),
                              )
                              .toList(),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.blueGrey,
        fontSize: 13,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildRecordingCard(
    BuildContext context,
    Recording recording,
    bool isDarkMode, {
    EdgeInsetsGeometry margin = const EdgeInsets.only(bottom: 12),
  }) {
    final duration =
        "${recording.duration.inMinutes.toString().padLeft(2, '0')}:${(recording.duration.inSeconds % 60).toString().padLeft(2, '0')}";
    final date = DateFormat('dd MMM yyyy').format(recording.date);

    return GestureDetector(
      onTap: () => _showTranscriptionModal(context, recording),
      child: Container(
        margin: margin,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode
              ? AppColors.darkSurface.withOpacity(0.92)
              : Colors.white.withOpacity(0.96),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDarkMode ? AppColors.darkBorder : AppColors.lightBorder,
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
              child: const Icon(Icons.play_arrow, color: Color(0xFF6D28D9)),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recording.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
            const Icon(Icons.chevron_right, color: Colors.blueGrey),
          ],
        ),
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
