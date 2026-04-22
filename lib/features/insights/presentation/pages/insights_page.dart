import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/pdf_export_service.dart';
import '../../../../features/audio_recorder/presentation/providers/audio_recorder_provider.dart';

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

  const _AiMindMapPage({
    required this.title,
    required this.rawNodes,
  });

  @override
  State<_AiMindMapPage> createState() => _AiMindMapPageState();
}

class _AiMindMapPageState extends State<_AiMindMapPage> {
  late List<_EditableMindMapNode> _nodes;

  @override
  void initState() {
    super.initState();
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

  String _buildShareLink() {
    final payload = jsonEncode(
      _nodes
          .map(
            (n) => {
              'id': n.id,
              'label': n.label,
              'parentId': n.parentId,
            },
          )
          .toList(),
    );
    final encoded = base64UrlEncode(utf8.encode(payload));
    return Uri(
      scheme: 'mindvoice',
      host: 'mindmap',
      queryParameters: {
        'title': widget.title,
        'data': encoded,
      },
    ).toString();
  }

  Future<void> _copyLink() async {
    final link = _buildShareLink();
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copiado al portapapeles.')),
    );
  }

  Future<void> _shareMindMap() async {
    final link = _buildShareLink();
    final text = 'Mapa mental: ${widget.title}\n$link';
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
      final uri = Uri.parse(rawLink);
      final encoded = uri.queryParameters['data'];
      if (encoded == null || encoded.isEmpty) {
        throw const FormatException('Link sin data.');
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mapa importado desde el link.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el link del mapa.')),
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
