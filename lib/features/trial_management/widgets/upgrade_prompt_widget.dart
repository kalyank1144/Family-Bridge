import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trial_status_provider.dart';

class UpgradePromptWidget extends StatelessWidget {
  final String featureKey;
  final VoidCallback? onUpgrade;
  const UpgradePromptWidget({super.key, required this.featureKey, this.onUpgrade});
  @override
  Widget build(BuildContext context) {
    return Consumer<TrialStatusProvider>(builder: (context, p, _) {
      final message = p.upgradeMessage(featureKey);
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Go Premium', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(message.isEmpty ? 'Upgrade to continue with this feature.' : message),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onUpgrade ?? p.upgradeToPremium,
                      child: const Text('Upgrade for \$9.99/month'),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      );
    });
  }
}