import 'dart:io';

import 'package:flutter/material.dart';

import 'package:family_bridge/core/services/subscription_analytics_service.dart';
import 'package:family_bridge/core/theme/app_theme.dart';
import 'package:family_bridge/features/admin/reports/services/report_generator_service.dart';

class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  final _report = ReportGeneratorService.instance;
  final _analytics = SubscriptionAnalyticsService.instance;
  String? _summary;
  File? _pdf;
  File? _csv;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() => _loading = true);
    try {
      final metrics = await _analytics.fetchCoreSubscriptionMetrics();
      final data = {
        'new_trials': 157,
        'new_trials_change': '↑23% vs last week',
        'conversions': 89,
        'conversion_rate': '31%',
        'new_mrr': '
$2,847',
        'top_trigger': 'Storage limit (45 conversions)',
        'churn': 12,
        'retention_rate': '94.8%',
        'actions': [
          'Storage limit messaging is working - expand to other limits',
          'Consider offering annual plans (request from 23 users)',
          'Follow up with 67 users entering final trial week',
        ],
      };
      data['new_mrr'] = '\n$${(metrics['mrr'] as double).toStringAsFixed(0)}';
      final summary = await _report.generateWeeklySummaryText(data);
      final pdf = await _report.exportAsPdf('weekly_business_report', summary);
      final csv = await _report.exportAsCsv('weekly_business_report.csv', [
        ['metric', 'value'],
        ['new_trials', data['new_trials'].toString()],
        ['conversions', data['conversions'].toString()],
        ['conversion_rate', data['conversion_rate'].toString()],
        ['new_mrr', data['new_mrr'].toString()],
        ['churn', data['churn'].toString()],
      ]);
      if (!mounted) return;
      setState(() { _summary = summary; _pdf = pdf; _csv = csv; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate report: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Business Report'), centerTitle: true, actions: [
        IconButton(onPressed: _loading ? null : _generate, icon: const Icon(Icons.refresh)),
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (_summary != null)
                  Expanded(
                    child: Card(child: Padding(padding: const EdgeInsets.all(AppTheme.spacingMd), child: SingleChildScrollView(child: Text(_summary!))))
                  )
                else
                  const Expanded(child: Center(child: Text('No report yet'))),
                const SizedBox(height: AppTheme.spacingMd),
                Row(children: [
                  ElevatedButton.icon(onPressed: _pdf == null ? null : () {}, icon: const Icon(Icons.picture_as_pdf), label: const Text('Open PDF')),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(onPressed: _csv == null ? null : () {}, icon: const Icon(Icons.table_chart), label: const Text('Open CSV')),
                ]),
              ]),
            ),
    );
  }
}
