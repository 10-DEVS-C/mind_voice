import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/pdf_export_service.dart';
import '../../../../features/audio_recorder/presentation/providers/audio_recorder_provider.dart';

Future<void> openSharedMindmapFromLinkDialog(BuildContext context) async {
  final controller = TextEditingController();
  final rawLink = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Abrir mapa desde link'),
      content: TextField(
        controller: controller,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Pega aquí el link mindvoice://mindmap?...',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
          child: const Text('Abrir'),
        ),
      ],
    ),
  );

  if (rawLink == null || rawLink.isEmpty || !context.mounted) {
    return;
  }

  try {
    final sharedId = _extractMindmapIdFromAnyLinkValue(rawLink);
    if (sharedId == null || sharedId.isEmpty) {
      throw const FormatException('Link sin id');
    }

    final loaded = await context.read<AudioRecorderProvider>().fetchMindmapById(
          sharedId,
        );
    if (loaded == null) {
      throw const FormatException('No se pudo cargar el mapa remoto.');
    }

    final dynamic nodesPayload = loaded['nodes'];
    final rawNodes = _extractRawNodesFromMindmapPayload(nodesPayload);
    final title = _extractMindmapTitleFromPayload(nodesPayload);
    final updatedAt = loaded['updatedAt']?.toString();
    final loadedMindmapId = loaded['_id']?.toString() ?? sharedId;

    if (!context.mounted) {
      return;
    }

    final loadedCount = _parseMindMapNodes(rawNodes).length;
    final loadedText = loadedCount > 0
        ? 'Mapa mental cargado correctamente ($loadedCount nodos).'
        : 'Mapa mental cargado, pero no tiene nodos.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(loadedText)),
    );

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _AiMindMapPage(
          title: title,
          rawNodes: rawNodes,
          initialSharedMindmapId: loadedMindmapId,
          initialRemoteUpdatedAt: updatedAt,
        ),
      ),
    );
  } catch (e) {
    if (!context.mounted) {
      return;
    }
    final providerError = context.read<AudioRecorderProvider>().errorMessage;
    final fallback = e.toString().replaceFirst('Exception: ', '');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'No se pudo cargar el mapa mental. ${providerError ?? fallback}',
        ),
      ),
    );
  }
}

List<dynamic> _extractRawNodesFromMindmapPayload(dynamic nodesPayload) {
  if (nodesPayload is List) {
    return nodesPayload;
  }

  if (nodesPayload is Map<String, dynamic>) {
    final candidate = nodesPayload['flatNodes'];
    if (candidate is List) {
      return candidate;
    }

    // Compatibilidad con formato de diccionario por id.
    final fallback = <Map<String, dynamic>>[];
    nodesPayload.forEach((key, value) {
      if (key == 'title' || key == 'flatNodes') {
        return;
      }
      if (value is Map) {
        final map = value.cast<dynamic, dynamic>();
        fallback.add(<String, dynamic>{
          'id': map['id']?.toString() ?? key,
          'label': map['label']?.toString() ??
              map['text']?.toString() ??
              map['title']?.toString() ??
              key,
          'parentId': map['parentId']?.toString(),
        });
      }
    });

    return fallback;
  }

  return const <dynamic>[];
}

String _extractMindmapTitleFromPayload(dynamic nodesPayload) {
  if (nodesPayload is Map<String, dynamic>) {
    final title = nodesPayload['title']?.toString();
    if (title != null && title.trim().isNotEmpty) {
      return title;
    }
  }
  return 'Mapa compartido';
}

String? _extractMindmapIdFromAnyLinkValue(String rawLink) {
  final uri = Uri.tryParse(rawLink);
  if (uri == null) {
    return null;
  }

  final directId = uri.queryParameters['id'];
  if (directId != null && directId.isNotEmpty) {
    return directId;
  }

  if (uri.pathSegments.length >= 2 && uri.pathSegments.first == 'mindmap') {
    final pathId = uri.pathSegments[1];
    if (pathId.isNotEmpty) {
      return pathId;
    }
  }

  final wrapped =
      uri.queryParameters['q'] ?? uri.queryParameters['url'] ?? uri.queryParameters['link'];
  if (wrapped != null && wrapped.isNotEmpty) {
    final wrappedUri = Uri.tryParse(Uri.decodeComponent(wrapped));
    final wrappedId = wrappedUri?.queryParameters['id'];
    if (wrappedId != null && wrappedId.isNotEmpty) {
      return wrappedId;
    }
  }

  return null;
}

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Obtenemos el provider para leer lastAiResult
    final provider = context.watch<AudioRecorderProvider>();
    final result = provider.lastAiResult;

    if (result == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 60,
                color: Colors.blueGrey.withOpacity(0.5),
              ),
              const SizedBox(height: 20),
              const Text(
                'Sin datos de IA',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Ve a la biblioteca, selecciona un audio y pulsa en "VER DOC" para analizarlo y obtener un reporte estructurado aquí.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blueGrey, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    final title = result['title']?.toString() ?? 'Análisis de IA';
    final List<dynamic> execSummary = result['executive_summary'] is List
        ? result['executive_summary']
        : [];
    final List<dynamic> keyInsights = result['key_insights'] is List
        ? result['key_insights']
        : [];
    final List<dynamic> taskList = result['task_list'] is List
        ? result['task_list']
        : [];
    final List<dynamic> mindMapNodes = result['mind_map_nodes'] is List
        ? result['mind_map_nodes']
        : [];
    final List<dynamic> tags = result['tags'] is List ? result['tags'] : [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: Color(0xFF6D28D9),
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                        letterSpacing: -0.8,
                      ),
                ),
              ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf_outlined,
                            color: Color(0xFF6D28D9)),
                        onPressed: () async {
                          try {
                            await PdfExportService.exportAnalysis(result);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error al exportar PDF: $e')),
                              );
                            }
                          }
                        },
                        tooltip: 'Exportar PDF',
                      ),
                      const SizedBox(height: 6),
                      FilledButton.tonalIcon(
                        onPressed: () {
                          if (mindMapNodes.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No hay nodos para construir el mapa mental.'),
                              ),
                            );
                            return;
                          }

                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => _AiMindMapPage(
                                title: title,
                                rawNodes: mindMapNodes,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.account_tree_outlined, size: 18),
                        label: const Text('Mapa mental'),
                      ),
                    ],
                  ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Reporte estructurado por IA',
            style: TextStyle(
              color: isDarkMode
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),

          if (execSummary.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6D28D9), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6D28D9).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resumen Ejecutivo',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...execSummary
                      .map(
                        (para) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            para.toString(),
                            style: const TextStyle(
                              color: Colors.white70,
                              height: 1.6,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          if (taskList.isNotEmpty) ...[
            const Text(
              'Tareas Identificadas',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 12),
            ...taskList.map((taskItem) {
              final taskStr = taskItem is Map
                  ? taskItem['task']?.toString() ?? ''
                  : taskItem.toString();
              final priorityStr = taskItem is Map
                  ? taskItem['priority']?.toString().toLowerCase() ?? 'media'
                  : 'media';

              Color pColor = Colors.orange;
              if (priorityStr.contains('alta')) pColor = Colors.redAccent;
              if (priorityStr.contains('baja')) pColor = Colors.green;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: pColor, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        taskStr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: pColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        priorityStr.toUpperCase(),
                        style: TextStyle(
                          color: pColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 24),
          ],

          if (keyInsights.isNotEmpty) ...[
            const Text(
              'Key Insights',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 12),
            ...keyInsights.map(
              (insight) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: Icon(
                        Icons.lightbulb,
                        size: 18,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        insight.toString(),
                        style: const TextStyle(
                          fontSize: 14.5,
                          height: 1.5,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          Row(
            children: [
              Expanded(
                child: _infoCard(
                  context,
                  Icons.account_tree_outlined,
                  'Mapa Mental',
                  '${mindMapNodes.length} nodos extraídos',
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _infoCard(
                  context,
                  Icons.label_outline,
                  'Etiquetas',
                  '${tags.length} sugeridas',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: () => openSharedMindmapFromLinkDialog(context),
              icon: const Icon(Icons.link_outlined),
              label: const Text('Abrir mapa por link'),
            ),
          ),

          if (tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags
                  .map(
                    (t) => Chip(
                      label: Text(
                        t.toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: const Color(0xFF6D28D9).withOpacity(0.1),
                      side: BorderSide.none,
                      labelStyle: const TextStyle(
                        color: Color(0xFF6D28D9),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _infoCard(
    BuildContext context,
    IconData icon,
    String title,
    String sub,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
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
            color: Colors.black.withOpacity(isDarkMode ? 0.16 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF6D28D9), size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _AiMindMapPage extends StatefulWidget {
  final String title;
  final List<dynamic> rawNodes;
  final String? initialSharedMindmapId;
  final String? initialRemoteUpdatedAt;

  const _AiMindMapPage({
    required this.title,
    required this.rawNodes,
    this.initialSharedMindmapId,
    this.initialRemoteUpdatedAt,
  });

  @override
  State<_AiMindMapPage> createState() => _AiMindMapPageState();
}

class _AiMindMapPageState extends State<_AiMindMapPage> {
  late List<_EditableMindMapNode> _nodes;
  String? _sharedMindmapId;
  String? _lastRemoteUpdatedAt;
  Timer? _pollTimer;
  bool _isPushing = false;

  @override
  void initState() {
    super.initState();
    _sharedMindmapId = widget.initialSharedMindmapId;
    _lastRemoteUpdatedAt = widget.initialRemoteUpdatedAt;
    final parsed = _parseMindMapNodes(widget.rawNodes);
    _nodes = parsed
        .map(
          (n) => _EditableMindMapNode(
            id: n.id,
            label: n.label,
            parentId: n.parentId,
          ),
        )
        .toList();

    _restoreLocalDraftIfAny();

    if (_sharedMindmapId != null && _sharedMindmapId!.isNotEmpty) {
      _startPolling();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tree = _buildEditableMindMapTree(_nodes);
    final roots = tree.$1;
    final childrenByParent = tree.$2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa Mental IA'),
        actions: [
          IconButton(
            tooltip: 'Copiar link',
            onPressed: _copyLink,
            icon: const Icon(Icons.link_outlined),
          ),
          IconButton(
            tooltip: 'Compartir',
            onPressed: _shareMindMap,
            icon: const Icon(Icons.share_outlined),
          ),
          IconButton(
            tooltip: 'Abrir desde link',
            onPressed: _importFromLink,
            icon: const Icon(Icons.input_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRootNode,
        icon: const Icon(Icons.add),
        label: const Text('Nodo raíz'),
      ),
      body: roots.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No se pudieron interpretar nodos del análisis.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final safeWidth = constraints.maxWidth.isFinite
                    ? constraints.maxWidth
                    : MediaQuery.of(context).size.width;
                final canvasWidth = (safeWidth * 1.25).clamp(320.0, 1400.0);

                return InteractiveViewer(
                  minScale: 0.7,
                  maxScale: 2.2,
                  boundaryMargin: const EdgeInsets.all(80),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: canvasWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_nodes.length} nodos',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.blueGrey,
                                ),
                          ),
                          const SizedBox(height: 16),
                          ...roots.map(
                            (root) => _EditableMindMapTreeNode(
                              node: root,
                              depth: 0,
                              childrenByParent: childrenByParent,
                              onEdit: _editNode,
                              onAddChild: _addChildNode,
                              onDelete: _deleteNode,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _buildDeepLink(String mindmapId) {
    return Uri(
      scheme: 'mindvoice',
      host: 'mindmap',
      queryParameters: {
        'id': mindmapId,
      },
    ).toString();
  }

  String _buildGoogleRedirectLink(String mindmapId) {
    final deepLink = _buildDeepLink(mindmapId);
    return Uri.https(
      'www.google.com',
      '/url',
      <String, String>{
        'q': deepLink,
      },
    ).toString();
  }

  List<Map<String, dynamic>> _serializeNodes() {
    return _nodes
        .map(
          (n) => {
            'id': n.id,
            'label': n.label,
            'parentId': n.parentId,
          },
        )
        .toList();
  }

  String _titleDraftIdentifier() => 'title:${widget.title}';

  String _idDraftIdentifier(String id) => 'id:$id';

  void _restoreLocalDraftIfAny() {
    final provider = context.read<AudioRecorderProvider>();

    Map<String, dynamic>? draft;
    if (_sharedMindmapId != null && _sharedMindmapId!.isNotEmpty) {
      draft = provider.loadLocalMindmapDraft(_idDraftIdentifier(_sharedMindmapId!));
    }
    draft ??= provider.loadLocalMindmapDraft(_titleDraftIdentifier());

    if (draft == null) {
      return;
    }

    final flatNodesRaw = draft['flatNodes'];
    if (flatNodesRaw is! List) {
      return;
    }

    final restored = _parseMindMapNodes(flatNodesRaw)
        .map(
          (n) => _EditableMindMapNode(
            id: n.id,
            label: n.label,
            parentId: n.parentId,
          ),
        )
        .toList();

    if (restored.isNotEmpty) {
      _nodes = restored;
    }

    final draftSharedId = draft['sharedMindmapId']?.toString();
    if ((_sharedMindmapId == null || _sharedMindmapId!.isEmpty) &&
        draftSharedId != null &&
        draftSharedId.isNotEmpty) {
      _sharedMindmapId = draftSharedId;
      _startPolling();
    }
  }

  Future<void> _persistLocalDraft() async {
    final provider = context.read<AudioRecorderProvider>();
    final payload = _serializeNodes();

    await provider.saveLocalMindmapDraft(
      identifier: _titleDraftIdentifier(),
      title: widget.title,
      flatNodes: payload,
      sharedMindmapId: _sharedMindmapId,
    );

    final id = _sharedMindmapId;
    if (id != null && id.isNotEmpty) {
      await provider.saveLocalMindmapDraft(
        identifier: _idDraftIdentifier(id),
        title: widget.title,
        flatNodes: payload,
        sharedMindmapId: id,
      );
    }
  }

  Future<String?> _ensureSharedMindmapId() async {
    final provider = context.read<AudioRecorderProvider>();
    final id = await provider.upsertSharedMindmap(
      mindmapId: _sharedMindmapId,
      title: widget.title,
      flatNodes: _serializeNodes(),
    );
    if (id != null && id.isNotEmpty) {
      _sharedMindmapId = id;
      _startPolling();
      return id;
    }
    return null;
  }

  Future<void> _copyLink() async {
    final id = await _ensureSharedMindmapId();
    if (id == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo generar el link compartido.')),
      );
      return;
    }

    final webLink = _buildGoogleRedirectLink(id);
    final deepLink = _buildDeepLink(id);
    final payload = 'Web: $webLink\nApp: $deepLink';
    await Clipboard.setData(ClipboardData(text: payload));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Links web y app copiados al portapapeles.'),
      ),
    );
  }

  Future<void> _shareMindMap() async {
    final id = await _ensureSharedMindmapId();
    if (id == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo compartir el mapa.')),
      );
      return;
    }

    final webLink = _buildGoogleRedirectLink(id);
    final deepLink = _buildDeepLink(id);
    final text =
      'Mapa mental: ${widget.title}\nWeb: $webLink\nApp: $deepLink';
    await Share.share(text);
  }

  Future<void> _importFromLink() async {
    final controller = TextEditingController();
    final rawLink = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abrir mapa desde link'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Pega aquí el link mindvoice://mindmap?...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Abrir'),
          ),
        ],
      ),
    );

    if (rawLink == null || rawLink.isEmpty) {
      return;
    }

    try {
      final uri = Uri.tryParse(rawLink);
      final sharedId = _extractMindmapIdFromAnyLink(rawLink);

      if (sharedId != null && sharedId.isNotEmpty) {
        final loaded = await context.read<AudioRecorderProvider>().fetchMindmapById(
              sharedId,
            );
        if (loaded == null) {
          throw const FormatException('No se pudo cargar el mapa remoto.');
        }

        final loadedNodes = _extractNodesFromMindmapResponse(loaded);
        _lastRemoteUpdatedAt = loaded['updatedAt']?.toString();
        _sharedMindmapId = loaded['_id']?.toString() ?? sharedId;
        _startPolling();

        if (!mounted) {
          return;
        }

        setState(() {
          _nodes = loadedNodes;
        });
        final loadedCount = loadedNodes.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loadedCount > 0
                  ? 'Mapa mental cargado correctamente ($loadedCount nodos).'
                  : 'Mapa mental cargado, pero no tiene nodos.',
            ),
          ),
        );
        return;
      }

      // Compatibilidad con links antiguos largos.
      final encoded = uri?.queryParameters['data'];
      if (encoded == null || encoded.isEmpty) {
        throw const FormatException('Link sin id o data.');
      }

      final decoded = utf8.decode(base64Url.decode(encoded));
      final dynamic parsed = jsonDecode(decoded);
      if (parsed is! List) {
        throw const FormatException('Formato inválido.');
      }

      final loaded = _parseMindMapNodes(parsed)
          .map(
            (n) => _EditableMindMapNode(
              id: n.id,
              label: n.label,
              parentId: n.parentId,
            ),
          )
          .toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _nodes = loaded;
      });
      final loadedCount = loaded.length;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loadedCount > 0
                ? 'Mapa mental cargado correctamente ($loadedCount nodos).'
                : 'Mapa mental cargado, pero no tiene nodos.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      final providerError = context.read<AudioRecorderProvider>().errorMessage;
      final fallback = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo cargar el mapa mental. ${providerError ?? fallback}',
          ),
        ),
      );
    }
  }

  String? _extractMindmapIdFromAnyLink(String rawLink) {
    final uri = Uri.tryParse(rawLink);
    if (uri == null) {
      return null;
    }

    final directId = uri.queryParameters['id'];
    if (directId != null && directId.isNotEmpty) {
      return directId;
    }

    if (uri.pathSegments.length >= 2 && uri.pathSegments.first == 'mindmap') {
      final pathId = uri.pathSegments[1];
      if (pathId.isNotEmpty) {
        return pathId;
      }
    }

    final wrapped =
        uri.queryParameters['q'] ?? uri.queryParameters['url'] ?? uri.queryParameters['link'];
    if (wrapped != null && wrapped.isNotEmpty) {
      final wrappedUri = Uri.tryParse(Uri.decodeComponent(wrapped));
      final wrappedId = wrappedUri?.queryParameters['id'];
      if (wrappedId != null && wrappedId.isNotEmpty) {
        return wrappedId;
      }
    }

    return null;
  }

  List<_EditableMindMapNode> _extractNodesFromMindmapResponse(
    Map<String, dynamic> response,
  ) {
    final dynamic nodesPayload = response['nodes'];
    final raw = _extractRawNodesFromMindmapPayload(nodesPayload);

    return _parseMindMapNodes(raw)
        .map(
          (n) => _EditableMindMapNode(
            id: n.id,
            label: n.label,
            parentId: n.parentId,
          ),
        )
        .toList();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      unawaited(_pullRemoteChanges());
    });
  }

  Future<void> _pullRemoteChanges() async {
    if (_isPushing) {
      return;
    }
    final id = _sharedMindmapId;
    if (id == null || id.isEmpty) {
      return;
    }

    final loaded = await context.read<AudioRecorderProvider>().fetchMindmapById(id);
    if (loaded == null) {
      return;
    }

    final updatedAt = loaded['updatedAt']?.toString();
    if (updatedAt != null && updatedAt == _lastRemoteUpdatedAt) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _nodes = _extractNodesFromMindmapResponse(loaded);
      _lastRemoteUpdatedAt = updatedAt;
    });
  }

  Future<void> _pushSharedChanges() async {
    if (_isPushing) {
      return;
    }

    _isPushing = true;
    final hadId = _sharedMindmapId != null && _sharedMindmapId!.isNotEmpty;
    final newId = await context.read<AudioRecorderProvider>().upsertSharedMindmap(
          mindmapId: _sharedMindmapId,
          title: widget.title,
          flatNodes: _serializeNodes(),
        );
    _isPushing = false;

    if (newId != null && newId.isNotEmpty) {
      _sharedMindmapId = newId;
      _startPolling();
      await _persistLocalDraft();
      unawaited(_pullRemoteChanges());
      if (!hadId && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cambios guardados. Ya puedes compartir el link.'),
          ),
        );
      }
      return;
    }

    if (mounted) {
      final err = context.read<AudioRecorderProvider>().errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            err ?? 'No se pudieron guardar los cambios del mapa mental.',
          ),
        ),
      );
    }
  }

  Future<void> _editNode(_EditableMindMapNode node) async {
    final controller = TextEditingController(text: node.label);
    final updatedText = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar nodo'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Texto del nodo',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (updatedText == null || updatedText.isEmpty) {
      return;
    }

    setState(() {
      node.label = updatedText;
    });
    unawaited(_persistLocalDraft());
    unawaited(_pushSharedChanges());
  }

  Future<void> _addChildNode(_EditableMindMapNode parent) async {
    final controller = TextEditingController();
    final label = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo nodo hijo'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Texto del nodo',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );

    if (label == null || label.isEmpty) {
      return;
    }

    final id = 'node_${DateTime.now().microsecondsSinceEpoch}';
    setState(() {
      _nodes.add(
        _EditableMindMapNode(
          id: id,
          label: label,
          parentId: parent.id,
        ),
      );
    });
    unawaited(_persistLocalDraft());
    unawaited(_pushSharedChanges());
  }

  void _addRootNode() {
    final id = 'node_${DateTime.now().microsecondsSinceEpoch}';
    setState(() {
      _nodes.add(
        _EditableMindMapNode(
          id: id,
          label: 'Nuevo nodo',
          parentId: null,
        ),
      );
    });
    unawaited(_persistLocalDraft());
    unawaited(_pushSharedChanges());
  }

  void _deleteNode(_EditableMindMapNode node) {
    final idsToDelete = <String>{node.id};
    var changed = true;
    while (changed) {
      changed = false;
      for (final n in _nodes) {
        if (n.parentId != null && idsToDelete.contains(n.parentId)) {
          if (idsToDelete.add(n.id)) {
            changed = true;
          }
        }
      }
    }

    setState(() {
      _nodes.removeWhere((n) => idsToDelete.contains(n.id));
    });
    unawaited(_persistLocalDraft());
    unawaited(_pushSharedChanges());
  }
}

class _EditableMindMapTreeNode extends StatelessWidget {
  final _EditableMindMapNode node;
  final int depth;
  final Map<String, List<_EditableMindMapNode>> childrenByParent;
  final Future<void> Function(_EditableMindMapNode node) onEdit;
  final Future<void> Function(_EditableMindMapNode node) onAddChild;
  final void Function(_EditableMindMapNode node) onDelete;

  const _EditableMindMapTreeNode({
    required this.node,
    required this.depth,
    required this.childrenByParent,
    required this.onEdit,
    required this.onAddChild,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final children =
        childrenByParent[node.id] ?? const <_EditableMindMapNode>[];
    final isRoot = depth == 0;
    final branchColor = const Color(0xFF4F46E5).withOpacity(0.30);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: depth == 0 ? 12 : (depth * 22.0) + 12,
                height: 44,
                child: _MindMapConnectorGuide(
                  depth: depth,
                  color: branchColor,
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isRoot
                        ? const Color(0xFF6D28D9).withOpacity(0.12)
                        : const Color(0xFF4F46E5).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isRoot
                          ? const Color(0xFF6D28D9).withOpacity(0.30)
                          : const Color(0xFF4F46E5).withOpacity(0.24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isRoot ? Icons.hub_outlined : Icons.circle,
                        size: isRoot ? 18 : 9,
                        color: const Color(0xFF4F46E5),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          node.label,
                          style: TextStyle(
                            fontWeight: isRoot ? FontWeight.w700 : FontWeight.w500,
                            fontSize: isRoot ? 14.5 : 13.5,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Acciones',
                        onSelected: (value) {
                          if (value == 'edit') {
                            onEdit(node);
                          } else if (value == 'add') {
                            onAddChild(node);
                          } else if (value == 'delete') {
                            onDelete(node);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Editar')),
                          PopupMenuItem(value: 'add', child: Text('Agregar hijo')),
                          PopupMenuItem(value: 'delete', child: Text('Eliminar rama')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ...children.map(
            (child) => _EditableMindMapTreeNode(
              node: child,
              depth: depth + 1,
              childrenByParent: childrenByParent,
              onEdit: onEdit,
              onAddChild: onAddChild,
              onDelete: onDelete,
            ),
          ),
        ],
      ),
    );
  }
}

class _MindMapConnectorGuide extends StatelessWidget {
  final int depth;
  final Color color;

  const _MindMapConnectorGuide({
    required this.depth,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (depth == 0) {
      return const SizedBox.shrink();
    }

    return CustomPaint(
      painter: _MindMapConnectorPainter(
        depth: depth,
        color: color,
      ),
    );
  }
}

class _MindMapConnectorPainter extends CustomPainter {
  final int depth;
  final Color color;

  _MindMapConnectorPainter({
    required this.depth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    const levelGap = 22.0;

    for (var i = 0; i < depth; i++) {
      final x = 10 + (i * levelGap);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    final elbowX = 10 + ((depth - 1) * levelGap);
    final centerY = size.height / 2;
    canvas.drawLine(Offset(elbowX, centerY), Offset(size.width, centerY), paint);
  }

  @override
  bool shouldRepaint(covariant _MindMapConnectorPainter oldDelegate) {
    return oldDelegate.depth != depth || oldDelegate.color != color;
  }
}

class _MindMapNode {
  final String id;
  final String label;
  final String? parentId;

  const _MindMapNode({
    required this.id,
    required this.label,
    required this.parentId,
  });
}

class _EditableMindMapNode {
  final String id;
  String label;
  String? parentId;

  _EditableMindMapNode({
    required this.id,
    required this.label,
    required this.parentId,
  });
}

List<_MindMapNode> _parseMindMapNodes(List<dynamic> rawNodes) {
  final List<_MindMapNode> nodes = <_MindMapNode>[];
  final Set<String> usedIds = <String>{};

  for (var i = 0; i < rawNodes.length; i++) {
    final item = rawNodes[i];
    String id = 'node_$i';
    String label = 'Nodo ${i + 1}';
    String? parentId;

    if (item is Map) {
      final map = item.cast<dynamic, dynamic>();
      final dynamic rawId = map['id'] ?? map['_id'] ?? map['nodeId'] ?? map['key'];
      final dynamic rawLabel =
          map['label'] ?? map['text'] ?? map['title'] ?? map['name'] ?? map['task'];
      final dynamic rawParent =
          map['parentId'] ?? map['parent_id'] ?? map['parent'] ?? map['parentNodeId'];

      if (rawId != null && rawId.toString().trim().isNotEmpty) {
        id = rawId.toString();
      }
      if (rawLabel != null && rawLabel.toString().trim().isNotEmpty) {
        label = rawLabel.toString();
      }

      if (rawParent != null) {
        final parent = rawParent.toString().trim();
        if (parent.isNotEmpty && parent.toLowerCase() != 'null') {
          parentId = parent;
        }
      }
    } else if (item != null) {
      final text = item.toString().trim();
      if (text.isNotEmpty) {
        label = text;
      }
    }

    if (usedIds.contains(id)) {
      id = '${id}_$i';
    }
    usedIds.add(id);

    nodes.add(
      _MindMapNode(
        id: id,
        label: label,
        parentId: parentId,
      ),
    );
  }

  return nodes;
}

(List<_MindMapNode>, Map<String, List<_MindMapNode>>) _buildMindMapTree(
  List<_MindMapNode> nodes,
) {
  final Map<String, _MindMapNode> byId = <String, _MindMapNode>{
    for (final node in nodes) node.id: node,
  };

  final Map<String, List<_MindMapNode>> childrenByParent =
      <String, List<_MindMapNode>>{};
  final List<_MindMapNode> roots = <_MindMapNode>[];

  for (final node in nodes) {
    final parentId = node.parentId;
    if (parentId == null || !byId.containsKey(parentId)) {
      roots.add(node);
      continue;
    }

    final children = childrenByParent.putIfAbsent(
      parentId,
      () => <_MindMapNode>[],
    );
    children.add(node);
  }

  if (roots.isEmpty && nodes.isNotEmpty) {
    roots.addAll(nodes);
  }

  roots.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
  for (final entry in childrenByParent.entries) {
    entry.value.sort(
      (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );
  }

  return (roots, childrenByParent);
}

(List<_EditableMindMapNode>, Map<String, List<_EditableMindMapNode>>)
    _buildEditableMindMapTree(
  List<_EditableMindMapNode> nodes,
) {
  final Map<String, _EditableMindMapNode> byId =
      <String, _EditableMindMapNode>{
    for (final node in nodes) node.id: node,
  };

  final Map<String, List<_EditableMindMapNode>> childrenByParent =
      <String, List<_EditableMindMapNode>>{};
  final List<_EditableMindMapNode> roots = <_EditableMindMapNode>[];

  for (final node in nodes) {
    final parentId = node.parentId;
    if (parentId == null || !byId.containsKey(parentId)) {
      roots.add(node);
      continue;
    }

    final children = childrenByParent.putIfAbsent(
      parentId,
      () => <_EditableMindMapNode>[],
    );
    children.add(node);
  }

  if (roots.isEmpty && nodes.isNotEmpty) {
    roots.addAll(nodes);
  }

  roots.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
  for (final entry in childrenByParent.entries) {
    entry.value.sort(
      (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );
  }

  return (roots, childrenByParent);
}
