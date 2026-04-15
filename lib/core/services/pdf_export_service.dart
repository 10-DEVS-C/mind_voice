import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class PdfExportService {
  static Future<void> exportAnalysis(Map<String, dynamic> result) async {
    final pdf = pw.Document();

    final title = result['title']?.toString() ?? 'Análisis de MindVoice AI';
    final List<dynamic> execSummary = result['executive_summary'] is List ? result['executive_summary'] : [];
    final List<dynamic> keyInsights = result['key_insights'] is List ? result['key_insights'] : [];
    final List<dynamic> taskList = result['task_list'] is List ? result['task_list'] : [];
    final List<dynamic> tags = result['tags'] is List ? result['tags'] : [];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('MINDVOICE AI', 
                      style: pw.TextStyle(
                        fontSize: 26, 
                        fontWeight: pw.FontWeight.bold, 
                        color: PdfColor.fromInt(0xFF6D28D9)
                      )
                    ),
                    pw.Text('Reporte de Inteligencia Artificial', 
                      style: pw.TextStyle(
                        fontSize: 12, 
                        color: PdfColors.grey600,
                        letterSpacing: 1.2
                      )
                    ),
                  ],
                ),
                pw.Text(DateTime.now().toString().split(' ')[0], 
                  style: const pw.TextStyle(color: PdfColors.grey700)
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 1.5, color: PdfColor.fromInt(0xFF6D28D9)),
            pw.SizedBox(height: 30),

            // Main Title
            pw.Center(
              child: pw.Text(title.toUpperCase(), 
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 22, 
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                )
              )
            ),
            pw.SizedBox(height: 40),

            // Executive Summary
            if (execSummary.isNotEmpty) ...[
              _buildSectionHeader(pdf, 'RESUMEN EJECUTIVO'),
              ...execSummary.map((p) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 12),
                child: pw.Text(p.toString(), 
                  textAlign: pw.TextAlign.justify, 
                  style: const pw.TextStyle(
                    fontSize: 12,
                    lineSpacing: 3,
                  )
                )
              )),
              pw.SizedBox(height: 25),
            ],

            // Task List
            if (taskList.isNotEmpty) ...[
              _buildSectionHeader(pdf, 'ACCIONES Y TAREAS'),
              ...taskList.map((taskItem) {
                final taskStr = taskItem is Map ? taskItem['task']?.toString() ?? '' : taskItem.toString();
                final priority = taskItem is Map ? taskItem['priority']?.toString().toUpperCase() ?? 'MEDIA' : 'MEDIA';
                
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('• ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      pw.Expanded(
                        child: pw.RichText(
                          text: pw.TextSpan(
                            children: [
                              pw.TextSpan(text: taskStr, style: const pw.TextStyle(fontSize: 12)),
                              pw.TextSpan(text: ' [$priority]', 
                                style: pw.TextStyle(
                                  fontSize: 10, 
                                  fontWeight: pw.FontWeight.bold,
                                  color: priority.contains('ALTA') ? PdfColors.red900 : PdfColors.blueGrey800
                                )
                              ),
                            ]
                          )
                        ),
                      ),
                    ],
                  )
                );
              }),
              pw.SizedBox(height: 25),
            ],

            // Key Insights
            if (keyInsights.isNotEmpty) ...[
              _buildSectionHeader(pdf, 'HALLAZGOS CLAVE (INSIGHTS)'),
              ...keyInsights.map((insight) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 8),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('- ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Expanded(
                      child: pw.Text(insight.toString(), style: const pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic)),
                    ),
                  ],
                )
              )),
              pw.SizedBox(height: 25),
            ],

            // Footer
            pw.Spacer(),
            pw.Divider(thickness: 0.5, color: PdfColors.grey400),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Generado por MindVoice AI Assistant', 
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)
                ),
                pw.Text('Página 1 de 1', 
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)
                ),
              ],
            ),
          ];
        },
      ),
    );

    // Save and Share
    try {
      final output = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File("${output.path}/MindVoice_Report_$timestamp.pdf");
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles(
        [XFile(file.path)], 
        subject: 'Reporte MindVoice AI - $title',
        text: 'Te comparto el análisis estructurado de mi última grabación en MindVoice AI.'
      );
    } catch (e) {
      rethrow;
    }
  }

  static pw.Widget _buildSectionHeader(pw.Document pdf, String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, 
          style: pw.TextStyle(
            fontSize: 14, 
            fontWeight: pw.FontWeight.bold, 
            color: PdfColor.fromInt(0xFF4F46E5),
            letterSpacing: 1.1
          )
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          height: 1,
          width: 80,
          color: PdfColor.fromInt(0xFF4F46E5),
        ),
        pw.SizedBox(height: 15),
      ],
    );
  }
}
