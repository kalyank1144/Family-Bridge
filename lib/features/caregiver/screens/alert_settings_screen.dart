import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/alert_provider.dart';
import '../models/alert.dart';

class AlertSettingsScreen extends StatelessWidget {
  const AlertSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final alertProvider = context.watch<AlertProvider>();
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        title: const Text('Alert Settings'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildActiveAlerts(context, alertProvider),
            _buildAlertPreferences(context, alertProvider),
            _buildNotificationSettings(context),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveAlerts(BuildContext context, AlertProvider provider) {
    final alerts = provider.alerts.take(5).toList();
    
    return Card(
      margin: const EdgeInsets.all(AppTheme.spacingMd),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Alerts',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: provider.unreadCount > 0 
                        ? AppTheme.errorColor.withOpacity(0.1)
                        : AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${provider.unreadCount} unread',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: provider.unreadCount > 0 
                          ? AppTheme.errorColor
                          : AppTheme.successColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            if (alerts.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacingMd),
                  child: Text('No alerts'),
                ),
              )
            else
              ...alerts.map((alert) => ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: alert.priorityColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    alert.typeIcon,
                    color: alert.priorityColor,
                    size: 20,
                  ),
                ),
                title: Text(alert.title),
                subtitle: Text(alert.familyMemberName),
                trailing: Text(alert.timeAgo),
                onTap: () {
                  if (!alert.isRead) {
                    provider.markAlertAsRead(alert.id);
                  }
                },
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertPreferences(BuildContext context, AlertProvider provider) {
    return Card(
      margin: const EdgeInsets.all(AppTheme.spacingMd),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alert Preferences',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            ...AlertType.values.map((type) {
              final enabled = provider.alertPreferences[type] ?? true;
              return SwitchListTile(
                title: Text(_getAlertTypeLabel(type)),
                subtitle: Text(_getAlertTypeDescription(type)),
                value: enabled,
                onChanged: (value) {
                  provider.updateAlertPreference(type, value);
                },
                secondary: Icon(
                  _getAlertTypeIcon(type),
                  color: enabled ? AppTheme.primaryColor : AppTheme.textTertiary,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettings(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(AppTheme.spacingMd),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            ListTile(
              leading: const Icon(FeatherIcons.bell),
              title: const Text('Push Notifications'),
              subtitle: const Text('Receive alerts on your device'),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
              ),
            ),
            ListTile(
              leading: const Icon(FeatherIcons.mail),
              title: const Text('Email Notifications'),
              subtitle: const Text('Get daily summaries via email'),
              trailing: Switch(
                value: false,
                onChanged: (value) {},
              ),
            ),
            ListTile(
              leading: const Icon(FeatherIcons.messageSquare),
              title: const Text('SMS Alerts'),
              subtitle: const Text('Critical alerts via text message'),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getAlertTypeLabel(AlertType type) {
    switch (type) {
      case AlertType.missedMedication:
        return 'Missed Medication';
      case AlertType.abnormalVitals:
        return 'Abnormal Vitals';
      case AlertType.missedCheckIn:
        return 'Missed Check-in';
      case AlertType.appointmentReminder:
        return 'Appointment Reminders';
      case AlertType.emergencyContact:
        return 'Emergency Contact';
      case AlertType.fallDetection:
        return 'Fall Detection';
      case AlertType.locationAlert:
        return 'Location Alerts';
      case AlertType.batteryLow:
        return 'Low Battery';
      case AlertType.systemUpdate:
        return 'System Updates';
    }
  }

  String _getAlertTypeDescription(AlertType type) {
    switch (type) {
      case AlertType.missedMedication:
        return 'When medications are not taken on time';
      case AlertType.abnormalVitals:
        return 'When vital signs are outside normal range';
      case AlertType.missedCheckIn:
        return 'When daily check-ins are missed';
      case AlertType.appointmentReminder:
        return 'Upcoming appointment notifications';
      case AlertType.emergencyContact:
        return 'Emergency button pressed';
      case AlertType.fallDetection:
        return 'Automatic fall detection alerts';
      case AlertType.locationAlert:
        return 'When member leaves designated area';
      case AlertType.batteryLow:
        return 'Device battery running low';
      case AlertType.systemUpdate:
        return 'App and system updates';
    }
  }

  IconData _getAlertTypeIcon(AlertType type) {
    switch (type) {
      case AlertType.missedMedication:
        return Icons.medication;
      case AlertType.abnormalVitals:
        return Icons.monitor_heart;
      case AlertType.missedCheckIn:
        return Icons.schedule;
      case AlertType.appointmentReminder:
        return Icons.event;
      case AlertType.emergencyContact:
        return Icons.emergency;
      case AlertType.fallDetection:
        return Icons.elderly;
      case AlertType.locationAlert:
        return Icons.location_on;
      case AlertType.batteryLow:
        return Icons.battery_alert;
      case AlertType.systemUpdate:
        return Icons.system_update;
    }
  }
}
