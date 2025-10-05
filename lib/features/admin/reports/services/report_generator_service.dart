import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReportGeneratorService {
  static final ReportGeneratorService instance = ReportGeneratorService._internal();
  ReportGeneratorService._internal();

  Future<String> generateWeeklySummaryText(Map<String, dynamic> data) async {
    final b = StringBuffer();
    b.writeln("This Week's Highlights:");
    b.writeln('- ${data['new_trials']} new trial users started (${data['new_trials_change']})');
    b.writeln('- ${data['conversions']} users converted to premium (conversion rate: ${data['conversion_rate']})');
    b.writeln('- ${data['new_mrr']} new MRR added');
    b.writeln('- Top conversion trigger: ${data['top_trigger']}');
    b.writeln('- Churn: ${data['churn']} cancellations (retention rate: ${data['retention_rate']})');
    b.writeln('');
    b.writeln('Action Items:');
    for (final item in (data['actions'] as List<String>)) {
      b.writeln('- $item');
    }
    return b.toString();
  }

  Future<File> exportAsPdf(String title, String body) async {
    final pdf = pw.Document();
    final now = DateFormat('yMMMd').format(DateTime.now());
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      build: (ctx) => [
        pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 12),
        pw.Text('Generated $now'),
        pw.SizedBox(height: 24),
        pw.Text(body),
      ],
    ));
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${title.replaceAll(' ', '_').toLowerCase()}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<File> exportAsCsv(String filename, List<List<String>> rows) async {
    final csv = rows.map((r) => r.map(_escapeCsv).join(',')).join('\n');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(csv);
    return file;
  }

  String _escapeCsv(String v) {
    final needsQuotes = v.contains(',') || v.contains('"') || v.contains('\n');
    final escaped = v.replaceAll('"', '""');
    return needsQuotes ? '"$escaped"' : escaped;
  }
}
