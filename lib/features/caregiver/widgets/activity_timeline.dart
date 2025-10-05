import 'package:flutter/material.dart';

import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:intl/intl.dart';

import 'package:family_bridge/core/theme/app_theme.dart';
import 'package:family_bridge/features/caregiver/models/appointment.dart';
import 'package:family_bridge/features/caregiver/models/family_member.dart';

class ActivityTimeline extends StatelessWidget {
  final List<FamilyMember> familyMembers;
  final List<Appointment> appointments;

  const ActivityTimeline({
    super.key,
    required this.familyMembers,
    required this.appointments,
  });

  @override
  Widget build(BuildContext context) {
    final activities = _generateActivities();
    
    if (activities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Column(
            children: [
              Icon(
                FeatherIcons.clock,
                size: 48,
                color: AppTheme.textTertiary,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              Text(
                'No recent activity',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textTertiary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: activities.take(5).map((activity) => 
        _buildActivityItem(context, activity)
      ).toList(),
    );
  }

  List<_ActivityItem> _generateActivities() {
    final activities = <_ActivityItem>[];
    final now = DateTime.now();
    
    // Add family member activities
    for (final member in familyMembers) {
      if (member.lastActivity.difference(now).inHours.abs() < 24) {
        activities.add(_ActivityItem(
          timestamp: member.lastActivity,
          title: '${member.name} ${member.isOnline ? "came online" : "went offline"}',
          subtitle: member.lastActivityFormatted,
          icon: FeatherIcons.user,
          color: member.isOnline ? AppTheme.successColor : AppTheme.textTertiary,
        ));
      }
      
      if (!member.hasCompletedDailyCheckIn && member.type == MemberType.elder) {
        activities.add(_ActivityItem(
          timestamp: DateTime(now.year, now.month, now.day, 9, 0),
          title: '${member.name} missed daily check-in',
          subtitle: 'Requires attention',
          icon: FeatherIcons.alertCircle,
          color: AppTheme.warningColor,
        ));
      }
      
      if (member.medicationCompliance < 0.8) {
        activities.add(_ActivityItem(
          timestamp: now.subtract(const Duration(hours: 2)),
          title: '${member.name} medication compliance low',
          subtitle: '${(member.medicationCompliance * 100).toInt()}% this week',
          icon: Icons.medication,
          color: AppTheme.warningColor,
        ));
      }
    }
    
    // Add appointment activities
    for (final appointment in appointments) {
      activities.add(_ActivityItem(
        timestamp: appointment.dateTime,
        title: '${appointment.familyMemberName} - ${appointment.doctorName}',
        subtitle: '${appointment.typeLabel} at ${appointment.timeFormatted}',
        icon: FeatherIcons.calendar,
        color: appointment.memberColor,
      ));
    }
    
    // Sort by timestamp
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return activities;
  }

  Widget _buildActivityItem(BuildContext context, _ActivityItem activity) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: activity.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Icon(
                  activity.icon,
                  color: activity.color,
                  size: 20,
                ),
              ),
              Container(
                width: 2,
                height: 40,
                color: AppTheme.backgroundColor,
              ),
            ],
          ),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        activity.title,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      _formatTime(activity.timestamp),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  activity.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      if (time.hour > 0) {
        return DateFormat('h:mm a').format(time);
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d').format(time);
    }
  }
}

class _ActivityItem {
  final DateTime timestamp;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  _ActivityItem({
    required this.timestamp,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}