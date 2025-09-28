import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:family_bridge/features/trial_management/providers/trial_status_provider.dart';

class UsageStatsWidget extends StatelessWidget {
  const UsageStatsWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<TrialStatusProvider>(builder: (context, p, _) {
      final usage = p.usage;
      final items = usage.entries.map((e) {
        final v = e.value is Map ? e.value as Map : {};
        final c = v['count'] ?? 0;
        return MapEntry(e.key.toString(), c);
      }).toList()
        ..sort((a, b) => (b.value as int).compareTo(a.value as int));
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your usage', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (items.isEmpty) const Text('Start exploring premium features during your trial.'),
              for (final it in items.take(5))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(it.key.replaceAll('_', ' ')),
                      Text(it.value.toString()),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }
}