import 'package:flutter/material.dart';

import 'package:flutter_feather_icons/flutter_feather_icons.dart';

import 'package:family_bridge/core/theme/app_theme.dart';
import 'package:family_bridge/features/caregiver/models/family_member.dart';

class FamilyMemberOverviewCard extends StatelessWidget {
  final FamilyMember member;
  final VoidCallback? onViewDetails;
  final VoidCallback? onMonitor;

  const FamilyMemberOverviewCard({
    super.key,
    required this.member,
    this.onViewDetails,
    this.onMonitor,
  });

  @override
  Widget build(BuildContext context) {
    final compliance = (member.medicationCompliance.clamp(0, 1) * 100).toInt();
    final bp = member.vitals['bloodPressure']?.toString() ?? '--/--';
    final hr = member.vitals['heartRate']?.toString() ?? '--';
    final steps = member.vitals['steps']?.toString() ?? '--';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
                      backgroundImage: member.profileImageUrl != null
                          ? NetworkImage(member.profileImageUrl!)
                          : null,
                      child: member.profileImageUrl == null
                          ? Text(
                              member.name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryColor,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: member.isOnline ? AppTheme.successColor : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
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
                              member.name,
                              style: Theme.of(context).textTheme.headlineSmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: member.statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              children: [
                                Icon(member.statusIcon, size: 14, color: member.statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  _statusText(member.healthStatus),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: member.statusColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (member.activeAlerts.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            _badge(context, '${member.activeAlerts.length}', AppTheme.errorColor, FeatherIcons.alertTriangle),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(FeatherIcons.clock, size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            'Last check-in ${member.lastActivityFormatted}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      if (member.currentLocation != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(FeatherIcons.mapPin, size: 14, color: AppTheme.textSecondary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                member.currentLocation!,
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              children: [
                Icon(Icons.medication, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: member.medicationCompliance.clamp(0, 1),
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        member.medicationCompliance >= 0.9
                            ? AppTheme.successColor
                            : member.medicationCompliance >= 0.75
                                ? AppTheme.warningColor
                                : AppTheme.errorColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('$compliance%', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _metricChip(context, label: 'BP', value: bp, icon: FeatherIcons.activity),
                _metricChip(context, label: 'HR', value: hr == '--' ? '--' : '$hr bpm', icon: Icons.monitor_heart, color: AppTheme.healthGreen),
                _metricChip(context, label: 'Steps', value: steps, icon: FeatherIcons.trendingUp, color: AppTheme.infoColor),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewDetails,
                    icon: const Icon(FeatherIcons.user),
                    label: const Text('Details'),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onMonitor,
                    icon: const Icon(FeatherIcons.heart),
                    label: const Text('Monitor'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricChip(BuildContext context, {required String label, required String value, required IconData icon, Color? color}) {
    final c = color ?? AppTheme.primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: c.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: c),
          const SizedBox(width: 6),
          Text('$label: ', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c)),
          Text(value, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }

  Widget _badge(BuildContext context, String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  String _statusText(HealthStatus status) {
    switch (status) {
      case HealthStatus.normal:
        return 'Normal';
      case HealthStatus.warning:
        return 'Warning';
      case HealthStatus.critical:
        return 'Critical';
    }
  }
}
