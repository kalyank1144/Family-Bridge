import 'dart:async';

import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';

import 'package:family_bridge/core/services/subscription_analytics_service.dart';
import 'package:family_bridge/core/theme/app_theme.dart';
import 'package:family_bridge/features/admin/subscription_dashboard/widgets/conversion_funnel_widget.dart';
import 'package:family_bridge/features/admin/subscription_dashboard/widgets/metric_card_widget.dart';

class SubscriptionMetricsScreen extends StatefulWidget {
  const SubscriptionMetricsScreen({super.key});

  @override
  State<SubscriptionMetricsScreen> createState() => _SubscriptionMetricsScreenState();
}

class _SubscriptionMetricsScreenState extends State<SubscriptionMetricsScreen> {
  final _analytics = SubscriptionAnalyticsService.instance;
  Map<String, dynamic>? _metrics;
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _load();
    _sub = _analytics.subscribeToTrialEvents(onChange: _load).listen((_) {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final m = await _analytics.fetchCoreSubscriptionMetrics();
    if (mounted) setState(() => _metrics = m);
  }

  @override
  Widget build(BuildContext context) {
    final m = _metrics ?? {
      'active_trials': 1247,
      'trial_conversion_rate': 0.34,
      'mrr': 4567.0,
      'churn_rate': 0.052,
      'arpu': 8.32,
      'avg_days_to_conversion': 18,
    };
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Subscription Metrics'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      title: 'Active Trials',
                      value: '${m['active_trials']}',
                      trend: 0.12,
                      icon: Icons.timelapse,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: MetricCard(
                      title: 'Trial Conversions',
                      value: '${((m['trial_conversion_rate'] as double) * 100).toStringAsFixed(1)}%',
                      subtitle: 'Industry 15–20%',
                      trend: 0.05,
                      icon: Icons.trending_up,
                      color: AppTheme.successColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      title: 'MRR',
                      value: '
$${(m['mrr'] as double).toStringAsFixed(0)}',
                      trend: 0.08,
                      icon: Icons.attach_money,
                      color: AppTheme.infoColor,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: MetricCard(
                      title: 'Churn Rate',
                      value: '${((m['churn_rate'] as double) * 100).toStringAsFixed(1)}%',
                      trend: -0.02,
                      icon: Icons.trending_down,
                      color: AppTheme.errorColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Row(
                children: [
                  Expanded(
                    child: MetricCard(
                      title: 'ARPU',
                      value: '
$${(m['arpu'] as double).toStringAsFixed(2)}',
                      trend: 0.03,
                      icon: Icons.person,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: MetricCard(
                      title: 'Days to Conversion',
                      value: '${m['avg_days_to_conversion']} days',
                      trend: -0.04,
                      icon: Icons.schedule,
                      color: AppTheme.warningColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingLg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('30/60/90-day Trends', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: AppTheme.spacingMd),
                      SizedBox(height: 220, child: LineChart(_buildLineChartData())),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              ConversionFunnel(trials: m['active_trials'] as int, engaged: (m['active_trials'] as int * 0.6).round(), prompted: (m['active_trials'] as int * 0.4).round(), converted: ((m['active_trials'] as int) * (m['trial_conversion_rate'] as double)).round()),
            ],
          ),
        ),
      ),
    );
  }

  LineChartData _buildLineChartData() {
    final spots1 = List.generate(12, (i) => FlSpot(i.toDouble(), (i * 2 + 10).toDouble()));
    final spots2 = List.generate(12, (i) => FlSpot(i.toDouble(), (i * 1.5 + 8).toDouble()));
    return LineChartData(
      lineBarsData: [
        LineChartBarData(spots: spots1, isCurved: true, color: AppTheme.primaryColor, barWidth: 3),
        LineChartBarData(spots: spots2, isCurved: true, color: AppTheme.successColor, barWidth: 3),
      ],
      gridData: FlGridData(show: true, drawVerticalLine: false),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 22, getTitlesWidget: (value, meta) => Text('${value.toInt()}d', style: const TextStyle(fontSize: 10)))), leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, getTitlesWidget: (value, meta) => Text(value.toInt().toString(), style: const TextStyle(fontSize: 10))))),
    );
  }
}
