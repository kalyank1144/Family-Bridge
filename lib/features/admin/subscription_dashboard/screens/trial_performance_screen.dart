import 'package:flutter/material.dart';

import 'package:family_bridge/core/services/subscription_analytics_service.dart';
import 'package:family_bridge/core/theme/app_theme.dart';

class TrialPerformanceScreen extends StatefulWidget {
  const TrialPerformanceScreen({super.key});

  @override
  State<TrialPerformanceScreen> createState() => _TrialPerformanceScreenState();
}

class _TrialPerformanceScreenState extends State<TrialPerformanceScreen> {
  final _analytics = SubscriptionAnalyticsService.instance;
  Map<String, double>? _triggers;
  Map<String, double>? _correlations;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final t = await _analytics.fetchConversionTriggers();
    final c = await _analytics.fetchFeatureUsageCorrelations();
    if (mounted) setState(() { _triggers = t; _correlations = c; });
  }

  @override
  Widget build(BuildContext context) {
    final t = _triggers ?? {
      'storage_limit': 0.67,
      'emergency_contact_limit': 0.45,
      'story_limit': 0.38,
      'health_analytics': 0.52,
    };
    final c = _correlations ?? {
      'photos_over_1gb': 0.78,
      'stories_over_3': 0.71,
      'families_over_3': 0.65,
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Trial Performance'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Conversion Triggers', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppTheme.spacingMd),
                  _row(context, 'Storage limit reached', t['storage_limit']!),
                  _row(context, 'Emergency contact limit', t['emergency_contact_limit']!),
                  _row(context, 'Story recording limit', t['story_limit']!),
                  _row(context, 'Health analytics access', t['health_analytics']!),
                ]),
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Feature Usage Correlation', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppTheme.spacingMd),
                  _row(context, 'Users who upload >1GB of photos', c['photos_over_1gb']!),
                  _row(context, 'Users who record >3 stories', c['stories_over_3']!),
                  _row(context, 'Families with >3 members active', c['families_over_3']!),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String label, double pct) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Container(
            width: 160,
            alignment: Alignment.centerRight,
            child: Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(minHeight: 10, value: pct.clamp(0, 1), backgroundColor: AppTheme.primaryColor.withOpacity(0.1), valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor)),
                ),
              ),
              const SizedBox(width: 8),
              Text('${(pct * 100).toStringAsFixed(0)}%'),
            ]),
          ),
        ],
      ),
    );
  }
}
