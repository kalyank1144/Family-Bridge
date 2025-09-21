import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trial_status_provider.dart';

class TrialCountdownWidget extends StatelessWidget {
  final VoidCallback? onUpgrade;
  const TrialCountdownWidget({super.key, this.onUpgrade});
  @override
  Widget build(BuildContext context) {
    return Consumer<TrialStatusProvider>(builder: (context, p, _) {
      final inTrial = p.isInTrial;
      final days = p.remainingDays;
      if (!inTrial && days == 0 && p.user != null && p.user!.subscriptionStatus != 'premium') {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your trial has ended', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Upgrade to keep using premium features for your family.'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: onUpgrade ?? p.upgradeToPremium,
                  child: const Text('Upgrade to Premium'),
                )
              ],
            ),
          ),
        );
      }
      final total = 30.0;
      final remaining = days.toDouble();
      final elapsed = (total - remaining).clamp(0, total);
      String subtitle = 'Enjoy full access to all features.';
      if (days <= 15 && days > 7) subtitle = 'Your trial is halfway through.';
      if (days <= 7 && days > 0) subtitle = 'Your trial is ending soon.';
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(inTrial ? 'Trial: $days days left' : 'Trial status', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(subtitle),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: elapsed / total),
            ],
          ),
        ),
      );
    });
  }
}