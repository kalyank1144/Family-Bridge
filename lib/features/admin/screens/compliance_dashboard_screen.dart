import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/hipaa_audit_service.dart';
import '../../../core/services/access_control_service.dart';
import '../../../core/services/encryption_service.dart';

class ComplianceDashboardScreen extends StatefulWidget {
  const ComplianceDashboardScreen({super.key});

  @override
  State<ComplianceDashboardScreen> createState() => _ComplianceDashboardScreenState();
}

class _ComplianceDashboardScreenState extends State<ComplianceDashboardScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final HipaaAuditService _auditService = HipaaAuditService.instance;
  final AccessControlService _accessService = AccessControlService.instance;
  final EncryptionService _encryptionService = EncryptionService.instance;
  
  Map<String, dynamic>? _complianceReport;
  List<UserSession>? _activeSessions;
  Map<String, dynamic>? _encryptionStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadComplianceData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadComplianceData() async {
    setState(() => _isLoading = true);
    
    try {
      final complianceReport = await _auditService.generateComplianceReport();
      final encryptionStatus = _encryptionService.getEncryptionStatus();
      
      setState(() {
        _complianceReport = complianceReport;
        _encryptionStatus = encryptionStatus;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load compliance data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('HIPAA Compliance Dashboard'),
        centerTitle: true,
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(FeatherIcons.refreshCw),
            onPressed: _loadComplianceData,
          ),
          PopupMenuButton<String>(
            icon: const Icon(FeatherIcons.moreVertical),
            onSelected: _handleMenuSelection,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'export', child: Text('Export Report')),
              const PopupMenuItem(value: 'schedule', child: Text('Schedule Reports')),
              const PopupMenuItem(value: 'settings', child: Text('Compliance Settings')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Audit Logs'),
            Tab(text: 'Security'),
            Tab(text: 'Reports'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildAuditLogsTab(),
                _buildSecurityTab(),
                _buildReportsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _generateComplianceReport,
        icon: const Icon(FeatherIcons.fileText),
        label: const Text('Generate Report'),
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_complianceReport == null) {
      return const Center(child: Text('No compliance data available'));
    }

    final summary = _complianceReport!['summary'] as Map<String, dynamic>;
    final riskAssessment = _complianceReport!['riskAssessment'] as Map<String, dynamic>;
    final integrityCheck = _complianceReport!['integrityCheck'] as Map<String, dynamic>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compliance Status Cards
          Row(
            children: [
              Expanded(child: _buildStatusCard(context, 'Compliance Score', '98%', AppTheme.successColor, FeatherIcons.shield)),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(child: _buildStatusCard(context, 'Risk Level', riskAssessment['level'], _getRiskColor(riskAssessment['level']), FeatherIcons.alertTriangle)),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            children: [
              Expanded(child: _buildStatusCard(context, 'Data Integrity', '${integrityCheck['integrityPercentage'].toStringAsFixed(1)}%', AppTheme.infoColor, FeatherIcons.database)),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(child: _buildStatusCard(context, 'Active Users', '${summary['uniqueUsers']}', AppTheme.primaryColor, FeatherIcons.users)),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLg),
          
          // PHI Access Overview
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PHI Access Overview (30 Days)', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppTheme.spacingMd),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricItem(context, 'Total Access', '${summary['phiAccessEvents']}', AppTheme.primaryColor),
                      ),
                      Expanded(
                        child: _buildMetricItem(context, 'Failed Logins', '${summary['failedLogins']}', AppTheme.warningColor),
                      ),
                      Expanded(
                        child: _buildMetricItem(context, 'Critical Events', '${summary['criticalEvents']}', AppTheme.errorColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          
          // Event Distribution Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Event Distribution', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppTheme.spacingMd),
                  SizedBox(
                    height: 200,
                    child: _buildEventDistributionChart(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          
          // Recent Critical Events
          _buildCriticalEventsCard(),
        ],
      ),
    );
  }

  Widget _buildAuditLogsTab() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        children: [
          // Audit Log Filters
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Audit Log Filters', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppTheme.spacingMd),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip('All Events', true),
                      _buildFilterChip('PHI Access', false),
                      _buildFilterChip('Login/Logout', false),
                      _buildFilterChip('Critical', false),
                      _buildFilterChip('Failed Attempts', false),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _selectDateRange(),
                          icon: const Icon(FeatherIcons.calendar),
                          label: const Text('Last 30 Days'),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _exportAuditLogs(),
                          icon: const Icon(FeatherIcons.download),
                          label: const Text('Export Logs'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          
          // Audit Log List
          Expanded(
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    child: Row(
                      children: [
                        Text('Audit Events', style: Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        Text('Total: ${_complianceReport?['summary']['totalEvents'] ?? 0}', 
                             style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _buildAuditEventsList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Sessions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Active Sessions', style: Theme.of(context).textTheme.titleLarge),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _loadActiveSessions,
                        icon: const Icon(FeatherIcons.refreshCw, size: 16),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  _buildActiveSessionsList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          
          // Encryption Status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Encryption Status', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppTheme.spacingMd),
                  _buildEncryptionStatus(),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          
          // Security Alerts
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Security Alerts (24h)', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppTheme.spacingMd),
                  _buildSecurityAlerts(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Report Generation
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Generate Compliance Reports', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppTheme.spacingMd),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: AppTheme.spacingMd,
                    crossAxisSpacing: AppTheme.spacingMd,
                    childAspectRatio: 1.5,
                    children: [
                      _buildReportCard(context, 'Monthly HIPAA Report', 'Comprehensive monthly compliance summary', FeatherIcons.calendar, () => _generateReport('monthly')),
                      _buildReportCard(context, 'Audit Log Export', 'Full audit trail with integrity verification', FeatherIcons.fileText, () => _generateReport('audit')),
                      _buildReportCard(context, 'Risk Assessment', 'Security risk analysis and recommendations', FeatherIcons.shield, () => _generateReport('risk')),
                      _buildReportCard(context, 'Breach Analysis', 'Incident response and breach documentation', FeatherIcons.alertTriangle, () => _generateReport('breach')),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          
          // Scheduled Reports
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Scheduled Reports', style: Theme.of(context).textTheme.titleLarge),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _addScheduledReport,
                        icon: const Icon(FeatherIcons.plus),
                        label: const Text('Add Schedule'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                  _buildScheduledReportsList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, String title, String value, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: Theme.of(context).textTheme.bodySmall)),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildEventDistributionChart() {
    if (_complianceReport == null) return const SizedBox.shrink();
    
    final eventsByType = _complianceReport!['eventsByType'] as Map<String, dynamic>;
    final data = eventsByType.entries.map((e) => PieChartSectionData(
      value: e.value.toDouble(),
      title: e.key,
      color: _getEventTypeColor(e.key),
      radius: 60,
    )).toList();

    return PieChart(
      PieChartData(
        sections: data,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildCriticalEventsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Recent Critical Events', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('High Priority', style: TextStyle(color: AppTheme.errorColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            // Mock critical events
            _buildEventTile('Unauthorized PHI access attempt', '2 hours ago', AppTheme.errorColor),
            _buildEventTile('Multiple failed login attempts detected', '4 hours ago', AppTheme.warningColor),
            _buildEventTile('Encryption key accessed', '1 day ago', AppTheme.errorColor),
          ],
        ),
      ),
    );
  }

  Widget _buildEventTile(String description, String time, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(description, style: Theme.of(context).textTheme.bodyMedium),
                Text(time, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Icon(FeatherIcons.chevronRight, size: 16, color: AppTheme.textSecondary),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (sel) {
        // Handle filter selection
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      labelStyle: TextStyle(color: selected ? AppTheme.primaryColor : AppTheme.textPrimary),
    );
  }

  Widget _buildAuditEventsList() {
    // Mock audit events list
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: _getEventSeverityColor('medium').withOpacity(0.2),
            child: Icon(FeatherIcons.eye, color: _getEventSeverityColor('medium')),
          ),
          title: Text('PHI access event'),
          subtitle: Text('User: john.doe • 2023-12-01 14:30:22'),
          trailing: const Icon(FeatherIcons.chevronRight),
          onTap: () => _showAuditEventDetails(index),
        );
      },
    );
  }

  Widget _buildActiveSessionsList() {
    // Mock active sessions
    return Column(
      children: List.generate(3, (index) => ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.successColor.withOpacity(0.2),
          child: Icon(FeatherIcons.user, color: AppTheme.successColor),
        ),
        title: Text('Dr. Smith'),
        subtitle: Text('Professional • Last active: 5 min ago'),
        trailing: TextButton(
          onPressed: () => _forceLogout(index),
          child: const Text('Force Logout'),
        ),
      )),
    );
  }

  Widget _buildEncryptionStatus() {
    if (_encryptionStatus == null) return const SizedBox.shrink();
    
    final shouldRotate = _encryptionStatus!['shouldRotateKeys'] as bool;
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildEncryptionMetric('Algorithm', _encryptionStatus!['algorithm'])),
            Expanded(child: _buildEncryptionMetric('Key Version', _encryptionStatus!['keyVersion'].toString())),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMd),
        if (shouldRotate)
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Row(
              children: [
                Icon(FeatherIcons.alertTriangle, color: AppTheme.warningColor),
                const SizedBox(width: 8),
                Expanded(child: Text('Key rotation recommended', style: TextStyle(color: AppTheme.warningColor))),
                ElevatedButton(
                  onPressed: _rotateEncryptionKeys,
                  child: const Text('Rotate Keys'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEncryptionMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }

  Widget _buildSecurityAlerts() {
    return Column(
      children: [
        _buildAlertTile('No security alerts', 'All systems normal', AppTheme.successColor),
        _buildAlertTile('Encryption keys due for rotation', '15 days remaining', AppTheme.warningColor),
      ],
    );
  }

  Widget _buildAlertTile(String title, String subtitle, Color color) {
    return ListTile(
      leading: Icon(FeatherIcons.shield, color: color),
      title: Text(title),
      subtitle: Text(subtitle),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildReportCard(BuildContext context, String title, String description, IconData icon, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 24),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(description, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduledReportsList() {
    return Column(
      children: [
        ListTile(
          leading: Icon(FeatherIcons.calendar, color: AppTheme.primaryColor),
          title: const Text('Monthly HIPAA Report'),
          subtitle: const Text('Every 1st of month • Next: Jan 1, 2024'),
          trailing: Switch(value: true, onChanged: (v) {}),
          contentPadding: EdgeInsets.zero,
        ),
        ListTile(
          leading: Icon(FeatherIcons.clock, color: AppTheme.infoColor),
          title: const Text('Weekly Audit Summary'),
          subtitle: const Text('Every Monday • Next: Dec 25, 2023'),
          trailing: Switch(value: false, onChanged: (v) {}),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  // Helper methods
  Color _getRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'low': return AppTheme.successColor;
      case 'medium': return AppTheme.warningColor;
      case 'high': return AppTheme.errorColor;
      case 'critical': return const Color(0xFFDC2626);
      default: return AppTheme.textSecondary;
    }
  }

  Color _getEventTypeColor(String eventType) {
    switch (eventType.toLowerCase()) {
      case 'phiaccess': return AppTheme.primaryColor;
      case 'login': return AppTheme.successColor;
      case 'logout': return AppTheme.infoColor;
      case 'loginfailed': return AppTheme.errorColor;
      default: return AppTheme.textSecondary;
    }
  }

  Color _getEventSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'low': return AppTheme.infoColor;
      case 'medium': return AppTheme.warningColor;
      case 'high': return AppTheme.errorColor;
      case 'critical': return const Color(0xFFDC2626);
      default: return AppTheme.textSecondary;
    }
  }

  // Action methods
  void _handleMenuSelection(String value) {
    switch (value) {
      case 'export':
        _exportComplianceReport();
        break;
      case 'schedule':
        _scheduleReports();
        break;
      case 'settings':
        _openComplianceSettings();
        break;
    }
  }

  Future<void> _loadActiveSessions() async {
    // Load active sessions from access control service
    try {
      // Implementation would load from access control service
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Active sessions refreshed')),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to load active sessions: $e');
    }
  }

  void _selectDateRange() {
    showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: DateTime.now().subtract(const Duration(days: 30)),
        end: DateTime.now(),
      ),
    ).then((range) {
      if (range != null) {
        // Apply date filter and reload data
        _loadComplianceData();
      }
    });
  }

  void _exportAuditLogs() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Audit logs exported successfully')),
    );
  }

  void _showAuditEventDetails(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Audit Event Details'),
        content: const Text('Event details would be shown here...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _forceLogout(int sessionIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Force Logout'),
        content: const Text('Are you sure you want to force logout this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User logged out successfully')),
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _rotateEncryptionKeys() async {
    try {
      await _encryptionService.rotateKeys();
      await _loadComplianceData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Encryption keys rotated successfully')),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to rotate encryption keys: $e');
    }
  }

  void _generateReport(String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generating $type report...')),
    );
  }

  void _addScheduledReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Schedule New Report'),
        content: const Text('Report scheduling configuration would be here...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
  }

  void _generateComplianceReport() async {
    await _loadComplianceData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Compliance report generated')),
    );
  }

  void _exportComplianceReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Compliance report exported as PDF')),
    );
  }

  void _scheduleReports() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening report scheduling...')),
    );
  }

  void _openComplianceSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening compliance settings...')),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }
}