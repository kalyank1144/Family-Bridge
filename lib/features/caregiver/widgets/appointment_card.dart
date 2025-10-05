import 'package:flutter/material.dart';

import 'package:flutter_feather_icons/flutter_feather_icons.dart';

import 'package:family_bridge/core/theme/app_theme.dart';
import 'package:family_bridge/features/caregiver/models/appointment.dart';
import 'package:family_bridge/features/caregiver/models/family_member.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final FamilyMember? member;
  final VoidCallback? onEdit;
  final VoidCallback? onCall;
  final VoidCallback? onNavigate;

  const AppointmentCard({
    super.key,
    required this.appointment,
    this.member,
    this.onEdit,
    this.onCall,
    this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border(
            left: BorderSide(
              color: appointment.memberColor,
              width: 4,
            ),
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
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: appointment.memberColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Icon(
                      appointment.typeIcon,
                      color: appointment.memberColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.timeFormatted,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          appointment.familyMemberName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: appointment.memberColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      if (onEdit != null)
                        IconButton(
                          icon: const Icon(FeatherIcons.edit2, size: 18),
                          onPressed: onEdit,
                        ),
                      if (onCall != null)
                        IconButton(
                          icon: const Icon(FeatherIcons.phone, size: 18),
                          onPressed: onCall,
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingMd),
              _buildInfoRow(
                context,
                FeatherIcons.user,
                appointment.doctorName,
                appointment.typeLabel,
              ),
              const SizedBox(height: AppTheme.spacingSm),
              _buildInfoRow(
                context,
                FeatherIcons.mapPin,
                appointment.location,
                null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String text,
    String? subtitle,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.textSecondary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
