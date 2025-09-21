import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/subscription_analytics_service.dart';

class RevenueForecastScreen extends StatefulWidget {
  const RevenueForecastScreen({super.key});

  @override
  State<RevenueForecastScreen> createState() => _RevenueForecastScreenState();
}

class _RevenueForecastScreenState extends State<RevenueForecastScreen> {
  final _analytics = SubscriptionAnalyticsService.instance;
  Map<String, dynamic>? _metrics;
  final _targetMrPctCtrl = TextEditingController(text: '0.34');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _targetMrPctCtrl.dispose();
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
      'arpu': 8.32,
    };
    final activeTrials = m['active_trials'] as int;
    final convRate = m['trial_conversion_rate'] as double;
    final arpu = m['arpu'] as double;
    final currentMRR = m['mrr'] as double;
    final projIfSame = (activeTrials * convRate * arpu).toDouble();
    final normalConv = 0.20;
    final projNormal = (activeTrials * normalConv * arpu).toDouble();
    final breakEven = ((10000 - currentMRR) / arpu).ceil();

    return Scaffold(
      appBar: AppBar(title: const Text('Revenue Forecast'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Simple Projections', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppTheme.spacingMd),
                  _row('If conversion stays at ${(convRate * 100).toStringAsFixed(0)}%', '
$${projIfSame.toStringAsFixed(0)} MRR next month'),
                  _row('If trials convert at 20%', '
$${projNormal.toStringAsFixed(0)} revenue this quarter'),
                  _row('Break-even analysis', 'Need $breakEven subscribers to cover costs'),
                  const SizedBox(height: AppTheme.spacingMd),
                  Text('Growth Targets', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  TextField(controller: _targetMrPctCtrl, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Target conversion rate (0-1)', border: OutlineInputBorder())),
                  const SizedBox(height: 8),
                  Builder(builder: (_) {
                    final target = double.tryParse(_targetMrPctCtrl.text) ?? convRate;
                    final needed = ((target - convRate) <= 0) ? 0 : (((target - convRate) * activeTrials)).round();
                    return Text('Need ${(target * 100).toStringAsFixed(0)}% conversion to hit goals. Extra conversions needed: $needed');
                  }),
                ]),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Seasonal Trends', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppTheme.spacingMd),
                  _bullet('Family event seasons (holidays) often show higher conversion'),
                  _bullet('Back-to-school season increases family engagement'),
                  _bullet('Summer months may see usage dips'),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String a, String b) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [Expanded(child: Text(a)), Text(b, style: const TextStyle(fontWeight: FontWeight.bold))]),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [const Icon(Icons.circle, size: 8), const SizedBox(width: 8), Expanded(child: Text(text))]),
    );
  }
}
