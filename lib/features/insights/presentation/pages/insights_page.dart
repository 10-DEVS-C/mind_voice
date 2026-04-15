import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/pdf_export_service.dart';
import '../../../../features/audio_recorder/presentation/providers/audio_recorder_provider.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
