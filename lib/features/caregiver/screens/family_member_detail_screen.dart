import 'package:flutter/material.dart';

import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:family_bridge/core/theme/app_theme.dart';
import 'package:family_bridge/features/caregiver/providers/appointments_provider.dart';
import 'package:family_bridge/features/caregiver/providers/family_data_provider.dart';
import 'package:family_bridge/features/caregiver/providers/health_monitoring_provider.dart';

class FamilyMemberDetailScreen extends StatelessWidget {
  final String memberId;

  const FamilyMemberDetailScreen({
    super.key,
    required this.memberId,
  });

  @override
  Widget build(BuildContext context) {
    final familyProvider = context.watch<FamilyDataProvider>();
    final member = familyProvider.getMemberById(memberId);

    if (member == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Member Details')),
        body: const Center(child: Text('Member not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        title: Text(member.name),
        actions: [
          IconButton(
            icon: const Icon(FeatherIcons.edit),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          children: [
            _buildProfileCard(context, member),
            const SizedBox(height: AppTheme.spacingMd),
            _buildQuickActions(context, member),
            const SizedBox(height: AppTheme.spacingMd),
            _buildHealthSummary(context, member),
            const SizedBox(height: AppTheme.spacingMd),
            _buildUpcomingAppointments(context, member),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, dynamic member) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Text(
                member.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    member.type.toString().split('.').last.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        member.isOnline ? Icons.circle : Icons.circle_outlined,
                        size: 12,
                        color: member.isOnline ? AppTheme.successColor : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        member.isOnline ? 'Online' : 'Offline',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, dynamic member) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => context.push('/caregiver/health-monitoring/$memberId'),
            icon: const Icon(FeatherIcons.heart),
            label: const Text('Health'),
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(FeatherIcons.messageSquare),
            label: const Text('Message'),
          ),
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(FeatherIcons.phone),
            label: const Text('Call'),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthSummary(BuildContext context, dynamic member) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Health Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            ListTile(
              leading: Icon(Icons.medication, color: member.medicationCompliance > 0.8 ? AppTheme.successColor : AppTheme.warningColor),
              title: const Text('Medication Compliance'),
              trailing: Text('${(member.medicationCompliance * 100).toInt()}%'),
            ),
            ListTile(
              leading: Icon(Icons.check_circle, color: member.hasCompletedDailyCheckIn ? AppTheme.successColor : AppTheme.warningColor),
              title: const Text('Daily Check-in'),
              trailing: Text(member.hasCompletedDailyCheckIn ? 'Completed' : 'Pending'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingAppointments(BuildContext context, dynamic member) {
    final appointmentsProvider = context.watch<AppointmentsProvider>();
    final appointments = appointmentsProvider.getAppointmentsForMember(memberId);
    final upcoming = appointments.where((a) => a.dateTime.isAfter(DateTime.now())).take(3).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming Appointments',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: () => context.push('/caregiver/appointments'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            if (upcoming.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacingMd),
                  child: Text('No upcoming appointments'),
                ),
              )
            else
              ...upcoming.map((appointment) => ListTile(
                leading: Icon(appointment.typeIcon, color: appointment.memberColor),
                title: Text(appointment.doctorName),
                subtitle: Text('${appointment.typeLabel} - ${appointment.timeFormatted}'),
                trailing: Text(
                  '${appointment.dateTime.day}/${appointment.dateTime.month}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )),
          ],
        ),
      ),
    );
  }
}
