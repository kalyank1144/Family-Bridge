import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:family_bridge/core/services/notification_service.dart';
import 'package:family_bridge/core/theme/app_theme.dart';
import 'package:family_bridge/features/caregiver/models/alert.dart';
import 'package:family_bridge/features/caregiver/providers/alert_provider.dart';

/// Enhanced Alert Management Screen showcasing comprehensive AlertProvider integration
/// Features: alert creation, management, filtering, real-time updates, and escalation
class EnhancedAlertManagementScreen extends StatefulWidget {
  final String familyId;
  final String caregiverId;

  const EnhancedAlertManagementScreen({
    super.key,
    required this.familyId,
    required this.caregiverId,
  });

  @override
  State<EnhancedAlertManagementScreen> createState() => _EnhancedAlertManagementScreenState();
}

class _EnhancedAlertManagementScreenState extends State<EnhancedAlertManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  AlertType? _filterType;
  AlertSeverity? _filterSeverity;
  bool _showOnlyActive = true;

  // Alert creation controllers
  final _alertTitleController = TextEditingController();
  final _alertMessageController = TextEditingController();
  final _healthConcernController = TextEditingController();
  final _emergencyLocationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeAlertProvider();
  }

  Future<void> _initializeAlertProvider() async {
    final alertProvider = Provider.of<AlertProvider>(context, listen: false);
    await alertProvider.initialize(widget.familyId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _alertTitleController.dispose();
    _alertMessageController.dispose();
    _healthConcernController.dispose();
    _emergencyLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<AlertProvider>(
          builder: (context, alertProvider, child) {
            return Column(
              children: [
                _buildHeader(alertProvider),
                _buildQuickStats(alertProvider),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAllAlertsTab(alertProvider),
                      _buildActiveAlertsTab(alertProvider),
                      _buildCriticalAlertsTab(alertProvider),
                      _buildCreateAlertTab(alertProvider),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _tabController.animateTo(3),
        label: const Text('New Alert'),
        icon: const Icon(Icons.add_alert),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildHeader(AlertProvider alertProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alert Management',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Monitor and manage family alerts',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _showFilterDialog,
                    icon: const Icon(Icons.filter_list, color: Colors.white, size: 28),
                  ),
                  IconButton(
                    onPressed: alertProvider.refresh,
                    icon: const Icon(Icons.refresh, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ],
          ),
          if (alertProvider.error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      alertProvider.error!,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickStats(AlertProvider alertProvider) {
    final totalAlerts = alertProvider.alerts.length;
    final activeAlerts = alertProvider.activeAlerts.length;
    final criticalAlerts = alertProvider.criticalAlerts.length;
    final stats = alertProvider.alertStats;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Alerts',
              totalAlerts.toString(),
              Icons.notifications,
              AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Active',
              activeAlerts.toString(),
              Icons.notification_important,
              activeAlerts > 0 ? Colors.orange : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Critical',
              criticalAlerts.toString(),
              Icons.priority_high,
              criticalAlerts > 0 ? Colors.red : Colors.grey,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Today',
              (stats['today'] ?? 0).toString(),
              Icons.today,
              Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppTheme.primaryColor,
        tabs: const [
          Tab(text: 'All Alerts'),
          Tab(text: 'Active'),
          Tab(text: 'Critical'),
          Tab(text: 'Create'),
        ],
      ),
    );
  }

  Widget _buildAllAlertsTab(AlertProvider alertProvider) {
    final alerts = _getFilteredAlerts(alertProvider.alerts);
    
    if (alertProvider.isLoading && alerts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (alerts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.notifications_none,
        title: 'No Alerts Found',
        message: 'No alerts match your current filters',
      );
    }

    return RefreshIndicator(
      onRefresh: () => alertProvider.refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: alerts.length,
        itemBuilder: (context, index) => _buildAlertCard(alerts[index], alertProvider),
      ),
    );
  }

  Widget _buildActiveAlertsTab(AlertProvider alertProvider) {
    final alerts = alertProvider.activeAlerts;
    
    if (alerts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.check_circle,
        title: 'No Active Alerts',
        message: 'All alerts have been resolved',
        color: Colors.green,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alerts.length,
      itemBuilder: (context, index) => _buildAlertCard(alerts[index], alertProvider),
    );
  }

  Widget _buildCriticalAlertsTab(AlertProvider alertProvider) {
    final alerts = alertProvider.criticalAlerts;
    
    if (alerts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.shield_outlined,
        title: 'No Critical Alerts',
        message: 'No critical alerts require immediate attention',
        color: Colors.green,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alerts.length,
      itemBuilder: (context, index) => _buildAlertCard(alerts[index], alertProvider),
    );
  }

  Widget _buildCreateAlertTab(AlertProvider alertProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create New Alert',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose the type of alert you want to create',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          _buildAlertTypeCard(
            'General Alert',
            'Create a custom alert for any situation',
            Icons.notification_important,
            Colors.blue,
            () => _showGeneralAlertDialog(alertProvider),
          ),
          const SizedBox(height: 16),
          _buildAlertTypeCard(
            'Medication Alert',
            'Alert about medication issues',
            Icons.medication,
            Colors.orange,
            () => _showMedicationAlertDialog(alertProvider),
          ),
          const SizedBox(height: 16),
          _buildAlertTypeCard(
            'Health Concern',
            'Report a health-related concern',
            Icons.health_and_safety,
            Colors.red,
            () => _showHealthConcernDialog(alertProvider),
          ),
          const SizedBox(height: 16),
          _buildAlertTypeCard(
            'Emergency Alert',
            'Create an urgent emergency alert',
            Icons.emergency,
            Colors.red.shade700,
            () => _showEmergencyAlertDialog(alertProvider),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertTypeCard(String title, String description, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(Alert alert, AlertProvider alertProvider) {
    final severityColor = _getSeverityColor(alert.severity);
    final typeIcon = _getTypeIcon(alert.type);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: severityColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(typeIcon, color: severityColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            alert.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildSeverityBadge(alert.severity),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, h:mm a').format(alert.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            alert.message,
            style: const TextStyle(fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (alert.actionRequired != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Text(
                'Action Required: ${alert.actionRequired}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.amber.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (alert.isActive) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _acknowledgeAlert(alert, alertProvider),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Acknowledge'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _resolveAlert(alert, alertProvider),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Resolve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        alert.isResolved ? 'Resolved' : 'Acknowledged',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              IconButton(
                onPressed: () => _showAlertDetails(alert),
                icon: const Icon(Icons.more_vert),
                color: Colors.grey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityBadge(AlertSeverity severity) {
    final color = _getSeverityColor(severity);
    final text = _getSeverityText(severity);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    Color color = Colors.grey,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<Alert> _getFilteredAlerts(List<Alert> alerts) {
    var filtered = alerts;
    
    if (_showOnlyActive) {
      filtered = filtered.where((alert) => alert.isActive).toList();
    }
    
    if (_filterType != null) {
      filtered = filtered.where((alert) => alert.type == _filterType).toList();
    }
    
    if (_filterSeverity != null) {
      filtered = filtered.where((alert) => alert.severity == _filterSeverity).toList();
    }
    
    return filtered;
  }

  Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return Colors.green;
      case AlertSeverity.medium:
        return Colors.orange;
      case AlertSeverity.high:
        return Colors.red;
      case AlertSeverity.critical:
        return Colors.red.shade700;
    }
  }

  String _getSeverityText(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return 'Low';
      case AlertSeverity.medium:
        return 'Medium';
      case AlertSeverity.high:
        return 'High';
      case AlertSeverity.critical:
        return 'Critical';
    }
  }

  IconData _getTypeIcon(AlertType type) {
    switch (type) {
      case AlertType.medicationMissed:
      case AlertType.medicationDelayed:
        return Icons.medication;
      case AlertType.healthConcern:
      case AlertType.vitalsAbnormal:
        return Icons.health_and_safety;
      case AlertType.emergencyActivated:
        return Icons.emergency;
      case AlertType.appointmentReminder:
        return Icons.calendar_today;
      case AlertType.familyNotification:
        return Icons.family_restroom;
      case AlertType.systemAlert:
        return Icons.settings;
    }
  }

  Future<void> _acknowledgeAlert(Alert alert, AlertProvider alertProvider) async {
    final success = await alertProvider.acknowledgeAlert(
      alert.id,
      widget.caregiverId,
    );
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alert acknowledged: ${alert.title}'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  Future<void> _resolveAlert(Alert alert, AlertProvider alertProvider) async {
    final success = await alertProvider.resolveAlert(
      alert.id,
      widget.caregiverId,
      'Resolved by caregiver',
    );
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alert resolved: ${alert.title}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showAlertDetails(Alert alert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Alert Details',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Title: ${alert.title}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text('Message: ${alert.message}', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 12),
                      Text('Type: ${alert.type.toString().split('.').last}', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 12),
                      Text('Severity: ${_getSeverityText(alert.severity)}', style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 12),
                      Text('Created: ${DateFormat('MMM d, yyyy h:mm a').format(alert.createdAt)}', style: const TextStyle(fontSize: 16)),
                      if (alert.acknowledgedAt != null) ...[
                        const SizedBox(height: 12),
                        Text('Acknowledged: ${DateFormat('MMM d, yyyy h:mm a').format(alert.acknowledgedAt!)}', style: const TextStyle(fontSize: 16)),
                      ],
                      if (alert.resolvedAt != null) ...[
                        const SizedBox(height: 12),
                        Text('Resolved: ${DateFormat('MMM d, yyyy h:mm a').format(alert.resolvedAt!)}', style: const TextStyle(fontSize: 16)),
                      ],
                      if (alert.actionRequired != null) ...[
                        const SizedBox(height: 12),
                        Text('Action Required: ${alert.actionRequired}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      ],
                      if (alert.data != null && alert.data!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text('Additional Data:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ...alert.data!.entries.map((entry) => Text('${entry.key}: ${entry.value}')),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Alerts'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                title: const Text('Show only active alerts'),
                value: _showOnlyActive,
                onChanged: (value) {
                  setState(() => _showOnlyActive = value ?? true);
                },
              ),
              DropdownButtonFormField<AlertType?>(
                decoration: const InputDecoration(labelText: 'Alert Type'),
                value: _filterType,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Types')),
                  ...AlertType.values.map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type.toString().split('.').last),
                  )),
                ],
                onChanged: (value) => setState(() => _filterType = value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<AlertSeverity?>(
                decoration: const InputDecoration(labelText: 'Severity'),
                value: _filterSeverity,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Severities')),
                  ...AlertSeverity.values.map((severity) => DropdownMenuItem(
                    value: severity,
                    child: Text(_getSeverityText(severity)),
                  )),
                ],
                onChanged: (value) => setState(() => _filterSeverity = value),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filterType = null;
                _filterSeverity = null;
                _showOnlyActive = true;
              });
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () {
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showGeneralAlertDialog(AlertProvider alertProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create General Alert'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _alertTitleController,
              decoration: const InputDecoration(labelText: 'Alert Title'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _alertMessageController,
              decoration: const InputDecoration(labelText: 'Message'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _createGeneralAlert(alertProvider),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showMedicationAlertDialog(AlertProvider alertProvider) {
    // Implementation for medication alert creation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Medication alert creation - implementation needed')),
    );
  }

  void _showHealthConcernDialog(AlertProvider alertProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Health Concern'),
        content: TextField(
          controller: _healthConcernController,
          decoration: const InputDecoration(
            labelText: 'Describe the health concern',
            hintText: 'e.g., Patient reported dizziness',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _createHealthConcernAlert(alertProvider),
            child: const Text('Create Alert'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyAlertDialog(AlertProvider alertProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Emergency Alert'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This will create a critical emergency alert that will notify all family members immediately.',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emergencyLocationController,
              decoration: const InputDecoration(
                labelText: 'Location (optional)',
                hintText: 'Current location or address',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _createEmergencyAlert(alertProvider),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Create Emergency Alert'),
          ),
        ],
      ),
    );
  }

  Future<void> _createGeneralAlert(AlertProvider alertProvider) async {
    if (_alertTitleController.text.trim().isEmpty) return;

    final success = await alertProvider.createAlert(
      type: AlertType.familyNotification,
      severity: AlertSeverity.medium,
      title: _alertTitleController.text.trim(),
      message: _alertMessageController.text.trim(),
      userId: widget.caregiverId,
    );

    if (success && mounted) {
      Navigator.pop(context);
      _alertTitleController.clear();
      _alertMessageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ General alert created successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _createHealthConcernAlert(AlertProvider alertProvider) async {
    if (_healthConcernController.text.trim().isEmpty) return;

    final success = await alertProvider.createHealthConcernAlert(
      userId: widget.caregiverId,
      concern: _healthConcernController.text.trim(),
      severity: AlertSeverity.high,
    );

    if (success && mounted) {
      Navigator.pop(context);
      _healthConcernController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Health concern alert created'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _createEmergencyAlert(AlertProvider alertProvider) async {
    final success = await alertProvider.createEmergencyAlert(
      userId: widget.caregiverId,
      emergencyType: 'Medical Emergency',
      location: _emergencyLocationController.text.trim(),
      emergencyData: {
        'created_by': 'caregiver',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    if (success && mounted) {
      Navigator.pop(context);
      _emergencyLocationController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚨 Emergency alert created and sent to all family members'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }
}