import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription_model.dart';
import '../providers/subscription_provider.dart';

class TrialCountdownWidget extends ConsumerWidget {
  const TrialCountdownWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);

    return subscription.when(
      data: (sub) => _buildCountdown(context, sub),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCountdown(BuildContext context, SubscriptionModel subscription) {
    if (subscription.status != SubscriptionStatus.trial && 
        !subscription.isInGracePeriod) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final days = subscription.daysRemaining;
    final isUrgent = days <= 7;
    final isCritical = days <= 3;

    Color backgroundColor;
    Color textColor;
    IconData icon;
    
    if (isCritical) {
      backgroundColor = Colors.red.shade50;
      textColor = Colors.red.shade900;
      icon = Icons.warning_amber_rounded;
    } else if (isUrgent) {
      backgroundColor = Colors.orange.shade50;
      textColor = Colors.orange.shade900;
      icon = Icons.access_time_rounded;
    } else {
      backgroundColor = Colors.blue.shade50;
      textColor = Colors.blue.shade900;
      icon = Icons.celebration_rounded;
    }

    // Age-appropriate styling
    final isElder = subscription.userType == UserType.elder;
    final textSize = isElder ? 18.0 : 14.0;
    final padding = isElder ? 20.0 : 16.0;
    final iconSize = isElder ? 32.0 : 24.0;

    return Container(
      margin: EdgeInsets.all(isElder ? 20 : 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(isElder ? 20 : 16),
        border: Border.all(
          color: textColor.withOpacity(0.3),
          width: isElder ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: textColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showUpgradeDialog(context, subscription),
          borderRadius: BorderRadius.circular(isElder ? 20 : 16),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      color: textColor,
                      size: iconSize,
                    ),
                    SizedBox(width: isElder ? 16 : 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            days > 0 ? '$days Days Remaining' : 'Trial Ended',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: textColor,
                              fontSize: isElder ? 24 : 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subscription.trialMessage,
                            style: TextStyle(
                              color: textColor.withOpacity(0.8),
                              fontSize: textSize,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isUrgent) ...[
                  SizedBox(height: isElder ? 20 : 16),
                  _buildUpgradeButton(context, subscription, isElder),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpgradeButton(BuildContext context, SubscriptionModel subscription, bool isElder) {
    return SizedBox(
      width: double.infinity,
      height: isElder ? 70 : 56,
      child: ElevatedButton(
        onPressed: () => _navigateToUpgrade(context, subscription),
        style: ElevatedButton.styleFrom(
          backgroundColor: subscription.daysRemaining <= 3 
              ? Colors.red 
              : Colors.orange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isElder ? 16 : 12),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_rounded,
              size: isElder ? 32 : 24,
            ),
            SizedBox(width: isElder ? 12 : 8),
            Flexible(
              child: Text(
                subscription.upgradeButtonText,
                style: TextStyle(
                  fontSize: isElder ? 20 : 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context, SubscriptionModel subscription) {
    if (subscription.userType == UserType.elder) {
      // Simple dialog for elders
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Keep Your Family Connected',
            style: TextStyle(fontSize: 24),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.family_restroom,
                size: 64,
                color: Colors.blue,
              ),
              const SizedBox(height: 16),
              Text(
                'Your family loves staying connected with you through FamilyBridge.',
                style: TextStyle(fontSize: 18, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Continue sharing photos, voice messages, and daily check-ins.',
                style: TextStyle(fontSize: 16, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Maybe Later',
                style: TextStyle(fontSize: 18),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToUpgrade(context, subscription);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Upgrade Now',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      );
    } else {
      _navigateToUpgrade(context, subscription);
    }
  }

  void _navigateToUpgrade(BuildContext context, SubscriptionModel subscription) {
    Navigator.pushNamed(
      context,
      '/upgrade',
      arguments: subscription,
    );
  }
}