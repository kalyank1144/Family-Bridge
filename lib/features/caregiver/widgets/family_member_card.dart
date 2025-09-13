import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../models/family_member.dart';

class FamilyMemberCard extends StatelessWidget {
  final FamilyMember member;
  final VoidCallback? onTap;

  const FamilyMemberCard({
    super.key,
    required this.member,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(AppTheme.spacingSm),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: member.healthStatus == HealthStatus.critical
                ? AppTheme.healthRed.withOpacity(0.5)
                : member.healthStatus == HealthStatus.warning
                    ? AppTheme.healthYellow.withOpacity(0.5)
                    : Colors.grey.shade200,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  backgroundImage: member.profileImageUrl != null
                      ? NetworkImage(member.profileImageUrl!)
                      : null,
                  child: member.profileImageUrl == null
                      ? Text(
                          member.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: member.isOnline ? AppTheme.successColor : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.surfaceColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: member.statusColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      member.statusIcon,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              member.name,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (member.activeAlerts.isNotEmpty)
                  const Icon(
                    FeatherIcons.alertCircle,
                    size: 14,
                    color: AppTheme.warningColor,
                  ),
                if (member.hasCompletedDailyCheckIn)
                  const Icon(
                    FeatherIcons.checkCircle,
                    size: 14,
                    color: AppTheme.successColor,
                  ),
                if (member.medicationCompliance < 0.8)
                  const Icon(
                    Icons.medication,
                    size: 14,
                    color: AppTheme.warningColor,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}