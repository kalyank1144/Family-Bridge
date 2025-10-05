import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:family_bridge/features/trial_management/models/subscription_model.dart';
import 'package:family_bridge/features/trial_management/providers/subscription_provider.dart';

class UsageStatisticsWidget extends ConsumerWidget {
  final bool showFullStats;
  final VoidCallback? onUpgradeTap;

  const UsageStatisticsWidget({
    Key? key,
    this.showFullStats = false,
    this.onUpgradeTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);

    return subscription.when(
      data: (sub) => _buildStatistics(context, sub),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildStatistics(BuildContext context, SubscriptionModel subscription) {
    final theme = Theme.of(context);
    final stats = subscription.personalizedStats;
    final isElder = subscription.userType == UserType.elder;
    
    // Define icons and colors for each stat type
    final statConfig = {
      'photos': {
        'icon': Icons.photo_library_rounded,
        'color': Colors.purple,
        'title': 'Family Photos',
        'elderTitle': 'Your Photos',
      },
      'voiceMessages': {
        'icon': Icons.mic_rounded,
        'color': Colors.blue,
        'title': 'Voice Messages',
        'elderTitle': 'Voice Notes',
      },
      'stories': {
        'icon': Icons.auto_stories_rounded,
        'color': Colors.orange,
        'title': 'Family Stories',
        'elderTitle': 'Your Stories',
      },
      'checkIns': {
        'icon': Icons.calendar_today_rounded,
        'color': Colors.green,
        'title': 'Daily Check-ins',
        'elderTitle': 'Check-ins',
      },
      'healthAlerts': {
        'icon': Icons.favorite_rounded,
        'color': Colors.red,
        'title': 'Health Insights',
        'elderTitle': 'Health Updates',
      },
      'familyMembers': {
        'icon': Icons.people_rounded,
        'color': Colors.teal,
        'title': 'Family Members',
        'elderTitle': 'Your Family',
      },
    };

    final displayStats = showFullStats 
        ? stats.entries.toList()
        : stats.entries.take(3).toList();

    return Container(
      padding: EdgeInsets.all(isElder ? 20 : 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(isElder ? 20 : 16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isElder ? 'Your FamilyBridge Activity' : 'Your Impact on FamilyBridge',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: isElder ? 24 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subscription.status == SubscriptionStatus.trial)
                _buildValueBadge(context, subscription),
            ],
          ),
          SizedBox(height: isElder ? 24 : 16),
          ...displayStats.map((entry) {
            final config = statConfig[entry.key]!;
            return _buildStatItem(
              context,
              icon: config['icon'] as IconData,
              color: config['color'] as Color,
              title: isElder 
                  ? config['elderTitle'] as String 
                  : config['title'] as String,
              value: entry.value,
              isElder: isElder,
              isLocked: subscription.status != SubscriptionStatus.active &&
                        subscription.status != SubscriptionStatus.trial,
            );
          }).toList(),
          if (!showFullStats && stats.length > 3) ...[
            SizedBox(height: isElder ? 20 : 16),
            Center(
              child: TextButton.icon(
                onPressed: onUpgradeTap ?? () => _showAllStats(context, subscription),
                icon: Icon(
                  Icons.arrow_forward_rounded,
                  size: isElder ? 24 : 20,
                ),
                label: Text(
                  'See What You\'ll Lose',
                  style: TextStyle(
                    fontSize: isElder ? 18 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
          if (subscription.status == SubscriptionStatus.trial) ...[
            SizedBox(height: isElder ? 24 : 20),
            _buildImpactMessage(context, subscription),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required bool isElder,
    required bool isLocked,
  }) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isElder ? 12 : 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isElder ? 14 : 10),
            decoration: BoxDecoration(
              color: isLocked 
                  ? Colors.grey.shade200 
                  : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(isElder ? 16 : 12),
            ),
            child: Icon(
              isLocked ? Icons.lock_rounded : icon,
              color: isLocked ? Colors.grey : color,
              size: isElder ? 32 : 24,
            ),
          ),
          SizedBox(width: isElder ? 20 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isElder ? 18 : 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isLocked ? 'Upgrade to access' : value,
                  style: TextStyle(
                    fontSize: isElder ? 20 : 16,
                    fontWeight: FontWeight.w600,
                    color: isLocked 
                        ? Colors.grey 
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueBadge(BuildContext context, SubscriptionModel subscription) {
    final totalValue = _calculateTotalValue(subscription);
    final isElder = subscription.userType == UserType.elder;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isElder ? 16 : 12,
        vertical: isElder ? 8 : 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange, Colors.deepOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '\$$totalValue Value',
        style: TextStyle(
          color: Colors.white,
          fontSize: isElder ? 16 : 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildImpactMessage(BuildContext context, SubscriptionModel subscription) {
    final theme = Theme.of(context);
    final isElder = subscription.userType == UserType.elder;
    final familyCount = subscription.connectedFamilyMembers.length;
    
    String message;
    IconData icon;
    Color color;
    
    if (familyCount > 3) {
      message = '$familyCount family members depend on your FamilyBridge account';
      icon = Icons.group_rounded;
      color = Colors.blue;
    } else if (subscription.usageStats['photosUploaded'] > 50) {
      message = 'Your family treasures the memories you\'ve shared';
      icon = Icons.photo_album_rounded;
      color = Colors.purple;
    } else {
      message = 'Your family stays connected through FamilyBridge';
      icon = Icons.favorite_rounded;
      color = Colors.red;
    }
    
    return Container(
      padding: EdgeInsets.all(isElder ? 20 : 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(isElder ? 16 : 12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: isElder ? 36 : 28,
          ),
          SizedBox(width: isElder ? 16 : 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: isElder ? 18 : 14,
                fontWeight: FontWeight.w500,
                color: color.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTotalValue(SubscriptionModel subscription) {
    // Calculate approximate value based on usage
    final photos = (subscription.usageStats['photosUploaded'] ?? 0) as int;
    final storage = (subscription.usageStats['storageUsedGB'] ?? 0) as double;
    final messages = (subscription.usageStats['voiceMessages'] ?? 0) as int;
    
    // Simple value calculation
    final photoValue = photos * 0.10; // $0.10 per photo
    final storageValue = storage * 5.00; // $5 per GB
    final messageValue = messages * 0.25; // $0.25 per voice message
    
    return (photoValue + storageValue + messageValue).clamp(19.99, 99.99);
  }

  void _showAllStats(BuildContext context, SubscriptionModel subscription) {
    Navigator.pushNamed(
      context,
      '/personal-impact',
      arguments: subscription,
    );
  }
}