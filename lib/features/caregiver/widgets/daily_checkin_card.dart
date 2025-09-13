import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import '../../../core/theme/app_theme.dart';

class DailyCheckInCard extends StatelessWidget {
  final bool hasCompletedCheckIn;
  final DateTime lastCheckIn;
  final VoidCallback? onRemind;

  const DailyCheckInCard({
    super.key,
    required this.hasCompletedCheckIn,
    required this.lastCheckIn,
    this.onRemind,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = lastCheckIn.year == now.year &&
        lastCheckIn.month == now.month &&
        lastCheckIn.day == now.day;

    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          gradient: LinearGradient(
            colors: hasCompletedCheckIn
                ? [
                    AppTheme.successColor.withOpacity(0.1),
                    AppTheme.successColor.withOpacity(0.05),
                  ]
                : [
                    AppTheme.warningColor.withOpacity(0.1),
                    AppTheme.warningColor.withOpacity(0.05),
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: hasCompletedCheckIn
                          ? AppTheme.successColor.withOpacity(0.2)
                          : AppTheme.warningColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasCompletedCheckIn
                          ? FeatherIcons.checkCircle
                          : FeatherIcons.alertCircle,
                      color: hasCompletedCheckIn
                          ? AppTheme.successColor
                          : AppTheme.warningColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Check-in',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasCompletedCheckIn
                              ? 'Completed today'
                              : isToday
                                  ? 'Not completed yet'
                                  : 'Missed',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: hasCompletedCheckIn
                                ? AppTheme.successColor
                                : AppTheme.warningColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hasCompletedCheckIn)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.done,
                            size: 16,
                            color: AppTheme.successColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Done',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.successColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingLg),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Column(
                  children: [
                    _buildCheckInDetail(
                      context,
                      'Last Check-in',
                      _formatLastCheckIn(),
                      FeatherIcons.clock,
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    _buildCheckInDetail(
                      context,
                      'Status',
                      hasCompletedCheckIn ? 'All Good' : 'Needs Attention',
                      hasCompletedCheckIn
                          ? FeatherIcons.smile
                          : FeatherIcons.frown,
                    ),
                    if (hasCompletedCheckIn) ...[
                      const SizedBox(height: AppTheme.spacingSm),
                      _buildCheckInDetail(
                        context,
                        'Voice Note',
                        'Available',
                        FeatherIcons.mic,
                      ),
                    ],
                  ],
                ),
              ),
              if (!hasCompletedCheckIn && onRemind != null) ...[
                const SizedBox(height: AppTheme.spacingMd),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onRemind,
                    icon: const Icon(FeatherIcons.bell),
                    label: const Text('Send Reminder'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warningColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
              if (hasCompletedCheckIn) ...[
                const SizedBox(height: AppTheme.spacingMd),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Play voice note
                        },
                        icon: const Icon(FeatherIcons.play, size: 16),
                        label: const Text('Play Voice Note'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // View details
                        },
                        icon: const Icon(FeatherIcons.fileText, size: 16),
                        label: const Text('View Details'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckInDetail(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.textSecondary,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatLastCheckIn() {
    final now = DateTime.now();
    final difference = now.difference(lastCheckIn);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}