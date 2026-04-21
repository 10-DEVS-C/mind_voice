import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/recording.dart';
import '../providers/audio_recorder_provider.dart';
import '../widgets/recording_player_widget.dart';

class RecordingDetailPage extends StatefulWidget {
  final Recording recording;

  const RecordingDetailPage({super.key, required this.recording});

  @override
  State<RecordingDetailPage> createState() => _RecordingDetailPageState();
}

class _RecordingDetailPageState extends State<RecordingDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Recording _recording;

  @override
  void initState() {
    super.initState();
    _recording = widget.recording;
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AudioRecorderProvider>();
      final userId = context.read<AuthProvider>().user?.id;

      // Load AI analysis if transcription exists
      if (_recording.apiTranscriptionId != null &&
          _recording.apiTranscriptionId!.isNotEmpty &&
          userId != null) {
        provider.analyzeRecordingWithIa(_recording.id, userId);
      }

      // Load mindmaps
      provider.loadMindmaps();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool _isProPlan(String plan) {
    final p = plan.toLowerCase();
    return p == 'professional' || p == 'business';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _recording.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.text_snippet_outlined), text: 'Transcripción'),
            Tab(icon: Icon(Icons.auto_awesome_outlined), text: 'Análisis IA'),
            Tab(icon: Icon(Icons.account_tree_outlined), text: 'Mapa Mental'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Audio player at the top
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: RecordingPlayerWidget(
              audioPath: _recording.path,
              totalDuration: _recording.duration,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TranscriptionTab(recording: _recording),
                _AiAnalysisTab(recording: _recording),
                const _MindmapsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TRANSCRIPTION TAB
// ─────────────────────────────────────────────────────────────────────────────

class _TranscriptionTab extends StatefulWidget {
  final Recording recording;
  const _TranscriptionTab({required this.recording});

  @override
  State<_TranscriptionTab> createState() => _TranscriptionTabState();
}

class _TranscriptionTabState extends State<_TranscriptionTab> {
  bool _editing = false;
  late TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.recording.transcription ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;

    setState(() => _saving = true);

    final ok = await context.read<AudioRecorderProvider>().updateTranscriptionText(
          widget.recording.id,
          _controller.text.trim(),
          userId,
        );

    setState(() {
      _saving = false;
      if (ok) _editing = false;
    });

    if (!ok && mounted) {
      final err = context.read<AudioRecorderProvider>().errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Error al guardar'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AudioRecorderProvider>();
    final isTranscribing = provider.isTranscribing(widget.recording.id);
    final transcription = widget.recording.transcription;
    final hasTranscription = transcription != null && transcription.trim().isNotEmpty;
    final canEdit = widget.recording.apiTranscriptionId != null &&
        widget.recording.apiTranscriptionId!.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Transcripción',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (canEdit && !isTranscribing)
                _editing
                    ? Row(
                        children: [
                          TextButton(
                            onPressed: () => setState(() {
                              _editing = false;
                              _controller.text =
                                  widget.recording.transcription ?? '';
                            }),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 4),
                          FilledButton.icon(
                            onPressed: _saving ? null : _save,
                            icon: _saving
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.save_outlined, size: 16),
                            label: const Text('Guardar'),
                          ),
                        ],
                      )
                    : IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Editar transcripción',
                        onPressed: () => setState(() => _editing = true),
                      ),
            ],
          ),
          const SizedBox(height: 12),
          if (isTranscribing)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text('Transcribiendo audio...'),
                ],
              ),
            )
          else if (_editing)
            TextField(
              controller: _controller,
              maxLines: null,
              minLines: 8,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: 'Escribe la transcripción aquí...',
              ),
            )
          else if (!hasTranscription)
            _EmptyState(
              icon: Icons.text_snippet_outlined,
              message: 'Aún no hay transcripción para este audio.',
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Text(
                transcription,
                style: const TextStyle(height: 1.6),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AI ANALYSIS TAB
// ─────────────────────────────────────────────────────────────────────────────

class _AiAnalysisTab extends StatefulWidget {
  final Recording recording;
  const _AiAnalysisTab({required this.recording});

  @override
  State<_AiAnalysisTab> createState() => _AiAnalysisTabState();
}

class _AiAnalysisTabState extends State<_AiAnalysisTab> {
  bool _editing = false;
  late TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isProPlan(String plan) {
    final p = plan.toLowerCase();
    return p == 'professional' || p == 'business';
  }

  Future<void> _save(String analysisId) async {
    setState(() => _saving = true);

    Map<String, dynamic> result;
    try {
      result = jsonDecode(_controller.text) as Map<String, dynamic>;
    } catch (_) {
      result = {'text': _controller.text.trim()};
    }

    final ok = await context
        .read<AudioRecorderProvider>()
        .updateAiAnalysis(analysisId, result);

    setState(() {
      _saving = false;
      if (ok) _editing = false;
    });

    if (!ok && mounted) {
      final err = context.read<AudioRecorderProvider>().errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Error al guardar'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AudioRecorderProvider>();
    final user = context.watch<AuthProvider>().user;
    final plan = user?.plan ?? 'basic';
    final isPro = _isProPlan(plan);
    final isAnalyzing = provider.isAnalyzing;
    final aiResult = provider.lastAiResult;
    final analysisId = provider.lastAiAnalysisId;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Análisis de IA',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              if (!isPro)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Pro',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              const Spacer(),
              if (isPro && analysisId != null && !isAnalyzing)
                _editing
                    ? Row(
                        children: [
                          TextButton(
                            onPressed: () => setState(() => _editing = false),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 4),
                          FilledButton.icon(
                            onPressed: _saving ? null : () => _save(analysisId),
                            icon: _saving
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.save_outlined, size: 16),
                            label: const Text('Guardar'),
                          ),
                        ],
                      )
                    : IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Editar análisis',
                        onPressed: () {
                          _controller.text =
                              const JsonEncoder.withIndent('  ')
                                  .convert(aiResult ?? {});
                          setState(() => _editing = true);
                        },
                      ),
            ],
          ),
          const SizedBox(height: 12),
          if (isAnalyzing)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text('Generando análisis con IA...'),
                ],
              ),
            )
          else if (_editing && isPro)
            TextField(
              controller: _controller,
              maxLines: null,
              minLines: 10,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: '{"key": "value"}',
              ),
            )
          else if (aiResult == null)
            _EmptyState(
              icon: Icons.auto_awesome_outlined,
              message: 'No hay análisis de IA aún.\nGenera uno desde la lista de grabaciones.',
            )
          else
            _AiResultWidget(result: aiResult),
          if (!isPro && aiResult != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline, color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Editar el análisis de IA requiere plan Professional o Business.',
                      style: TextStyle(
                          color: AppColors.primary, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AiResultWidget extends StatelessWidget {
  final Map<String, dynamic> result;
  const _AiResultWidget({required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: result.entries.map((e) {
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                e.key,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                e.value is String
                    ? e.value as String
                    : const JsonEncoder.withIndent('  ').convert(e.value),
                style: const TextStyle(height: 1.5, fontSize: 13),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MINDMAPS TAB
// ─────────────────────────────────────────────────────────────────────────────

class _MindmapsTab extends StatelessWidget {
  const _MindmapsTab();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AudioRecorderProvider>();

    if (provider.isLoadingMindmaps) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.mindmaps.isEmpty) {
      return _EmptyState(
        icon: Icons.account_tree_outlined,
        message: 'No hay mapas mentales asociados.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: provider.mindmaps.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final mindmap = provider.mindmaps[index];
        return _MindmapCard(mindmap: mindmap);
      },
    );
  }
}

class _MindmapCard extends StatelessWidget {
  final Map<String, dynamic> mindmap;
  const _MindmapCard({required this.mindmap});

  @override
  Widget build(BuildContext context) {
    final nodes = mindmap['nodes'] as Map<String, dynamic>? ?? {};
    final updatedAt = mindmap['updatedAt']?.toString();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ExpansionTile(
        leading: const Icon(Icons.account_tree_outlined, color: AppColors.primary),
        title: Text(
          'Documento: ${mindmap['documentId'] ?? 'Sin ID'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: updatedAt != null
            ? Text(
                'Actualizado: ${updatedAt.substring(0, 10)}',
                style: const TextStyle(fontSize: 12),
              )
            : null,
        children: nodes.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Sin nodos', style: TextStyle(color: Colors.grey)),
                ),
              ]
            : nodes.entries.map((e) => _NodeTile(nodeId: e.key, node: e.value)).toList(),
      ),
    );
  }
}

class _NodeTile extends StatelessWidget {
  final String nodeId;
  final dynamic node;
  const _NodeTile({required this.nodeId, required this.node});

  @override
  Widget build(BuildContext context) {
    final nodeMap = node is Map<String, dynamic> ? node as Map<String, dynamic> : <String, dynamic>{};
    final label = nodeMap['label']?.toString() ??
        nodeMap['text']?.toString() ??
        nodeMap['title']?.toString() ??
        nodeId;
    final children = nodeMap['children'];
    final hasChildren = children is List && (children as List).isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            dense: true,
            leading: Icon(
              hasChildren ? Icons.chevron_right : Icons.circle,
              size: hasChildren ? 20 : 8,
              color: AppColors.primary.withOpacity(0.7),
            ),
            title: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          if (hasChildren)
            ...((children as List).map(
              (c) => _NodeTile(nodeId: '', node: c),
            )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared empty state widget
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: Colors.grey[400]),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
