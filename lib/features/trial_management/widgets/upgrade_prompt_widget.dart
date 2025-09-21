import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subscription_model.dart';
import '../providers/subscription_provider.dart';
import '../screens/upgrade_options_screen.dart';

class UpgradePromptWidget extends ConsumerWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback? onDismiss;
  final bool showDismiss;
  final bool isFloating;

  const UpgradePromptWidget({
    Key? key,
    required this.title,
    required this.message,
    required this.icon,
    this.color = Colors.orange,
    this.onDismiss,
    this.showDismiss = true,
    this.isFloating = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);
    
    return subscription.when(
      data: (sub) => _buildPrompt(context, sub),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildPrompt(BuildContext context, SubscriptionModel subscription) {
    if (subscription.status == SubscriptionStatus.active) {
      return const SizedBox.shrink();
    }

    final isElder = subscription.userType == UserType.elder;
    
    if (isFloating) {
      return _buildFloatingPrompt(context, subscription, isElder);
    } else {
      return _buildInlinePrompt(context, subscription, isElder);
    }
  }

  Widget _buildFloatingPrompt(
    BuildContext context, 
    SubscriptionModel subscription, 
    bool isElder,
  ) {
    return Positioned(
      bottom: isElder ? 24 : 16,
      left: isElder ? 24 : 16,
      right: isElder ? 24 : 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(isElder ? 20 : 16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.shade400, color.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(isElder ? 20 : 16),
          ),
          child: Padding(
            padding: EdgeInsets.all(isElder ? 20 : 16),
            child: _buildContent(context, subscription, isElder, true),
          ),
        ),
      ),
    );
  }

  Widget _buildInlinePrompt(
    BuildContext context, 
    SubscriptionModel subscription, 
    bool isElder,
  ) {
    return Container(
      margin: EdgeInsets.all(isElder ? 20 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.shade50, color.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isElder ? 20 : 16),
        border: Border.all(
          color: color.shade300,
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isElder ? 20 : 16),
        child: _buildContent(context, subscription, isElder, false),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, 
    SubscriptionModel subscription, 
    bool isElder,
    bool isFloating,
  ) {
    final textColor = isFloating ? Colors.white : color.shade900;
    final iconColor = isFloating ? Colors.white : color.shade700;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDismiss && onDismiss != null)
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: onDismiss,
              icon: Icon(
                Icons.close_rounded,
                color: textColor.withOpacity(0.7),
                size: isElder ? 24 : 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(isElder ? 14 : 12),
              decoration: BoxDecoration(
                color: isFloating 
                    ? Colors.white.withOpacity(0.2)
                    : iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: isElder ? 32 : 28,
              ),
            ),
            SizedBox(width: isElder ? 16 : 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isElder ? 20 : 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: isElder ? 8 : 4),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: isElder ? 16 : 14,
                      color: textColor.withOpacity(0.9),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: isElder ? 20 : 16),
        SizedBox(
          width: double.infinity,
          height: isElder ? 56 : 48,
          child: ElevatedButton(
            onPressed: () => _navigateToUpgrade(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: isFloating ? Colors.white : color,
              foregroundColor: isFloating ? color : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isElder ? 14 : 12),
              ),
              elevation: isFloating ? 0 : 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star_rounded,
                  size: isElder ? 24 : 20,
                ),
                SizedBox(width: isElder ? 8 : 6),
                Text(
                  subscription.upgradeButtonText,
                  style: TextStyle(
                    fontSize: isElder ? 18 : 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToUpgrade(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UpgradeOptionsScreen(),
      ),
    );
=======
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
>>>>>>> origin/main
  }
}