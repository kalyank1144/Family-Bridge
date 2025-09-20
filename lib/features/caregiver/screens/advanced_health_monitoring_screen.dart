import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/health_analytics_service.dart';
import '../../../core/mixins/hipaa_compliance_mixin.dart';
import '../../../core/services/access_control_service.dart';
import '../providers/family_data_provider.dart';

class AdvancedHealthMonitoringScreen extends StatefulWidget {
  const AdvancedHealthMonitoringScreen({super.key});

  @override
  State<AdvancedHealthMonitoringScreen> createState() => _AdvancedHealthMonitoringScreenState();
}

class _AdvancedHealthMonitoringScreenState extends State<AdvancedHealthMonitoringScreen> 
    with HipaaComplianceMixin<AdvancedHealthMonitoringScreen> {

  @override
  Widget build(BuildContext context) {
    return buildPermissionGate(
      requiredPermission: Permission.readPhi,
      child: _buildMonitoringContent(context),
    );
  }

  Widget _buildMonitoringContent(BuildContext context) {
    final familyProvider = context.watch<FamilyDataProvider>();
    final members = familyProvider.familyMembers;
    
    // Log PHI access when viewing health monitoring data
    for (final member in members) {
      logPhiAccess(member.id, 'health_monitoring', metadata: {
        'screen': 'AdvancedHealthMonitoring',
        'memberName': member.name,
      });
    }
    
    final analytics = HealthAnalyticsService();
    final summary = analytics.summarizeCurrent(members);
    final anomalies = analytics.detectAnomalies(members);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Advanced Monitoring'),
        centerTitle: true,
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(FeatherIcons.refreshCw),
            onPressed: () => _refresh(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _kpiCard(context, 'Avg Heart Rate', '${summary.avgHeartRate}', 'bpm', Icons.monitor_heart, AppTheme.healthGreen)),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(child: _kpiCard(context, 'Max BP', summary.maxBloodPressure ?? '--/--', 'mmHg', Icons.favorite, AppTheme.errorColor)),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              children: [
                Expanded(child: _kpiCard(context, 'Total Steps', '${summary.totalSteps}', '', FeatherIcons.trendingUp, AppTheme.infoColor)),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(child: _kpiCard(context, 'Avg Compliance', '${(summary.avgMedicationCompliance * 100).toStringAsFixed(0)}%', '', Icons.medication, AppTheme.warningColor)),
              ],
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text('Medication Adherence', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTheme.spacingSm),
            _complianceChart(context, members),
            const SizedBox(height: AppTheme.spacingLg),
            Text('Activity Overview', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTheme.spacingSm),
            _stepsChart(context, members),
            const SizedBox(height: AppTheme.spacingLg),
            Text('Detected Anomalies', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTheme.spacingSm),
            if (anomalies.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  child: Row(
                    children: [
                      Icon(FeatherIcons.checkCircle, color: AppTheme.successColor),
                      const SizedBox(width: 8),
                      const Text('No anomalies detected'),
                    ],
                  ),
                ),
              )
            else
              ...anomalies.map((a) => _anomalyTile(context, a)).toList(),
          ],
        ),
      ),
    );
  }

  Future<void> _refresh(BuildContext context) async {
    await context.read<FamilyDataProvider>().refresh();
  }

  Widget _kpiCard(BuildContext context, String title, String value, String unit, IconData icon, Color color) {
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
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: Theme.of(context).textTheme.bodySmall)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.w700)),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(unit, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _complianceChart(BuildContext context, List members) {
    if (members.isEmpty) {
      return const SizedBox.shrink();
    }
    final bars = members.map((m) => (m.medicationCompliance as double).clamp(0, 1) * 100).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: bars.asMap().entries.map((e) {
                return BarChartGroupData(x: e.key, barRods: [
                  BarChartRodData(
                    toY: e.value,
                    color: e.value >= 90 ? AppTheme.successColor : e.value >= 75 ? AppTheme.warningColor : AppTheme.errorColor,
                    width: 20,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
                  )
                ]);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepsChart(BuildContext context, List members) {
    if (members.isEmpty) return const SizedBox.shrink();
    final steps = members.map((m) => (m.vitals['steps'] as int?)?.toDouble() ?? 0.0).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: steps.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                  isCurved: true,
                  color: AppTheme.infoColor,
                  barWidth: 3,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, color: AppTheme.infoColor.withOpacity(0.12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _anomalyTile(BuildContext context, HealthAnomaly a) {
    final color = a.severity >= 0.9 ? AppTheme.healthRed : AppTheme.warningColor;
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
          child: Icon(FeatherIcons.alertTriangle, color: color),
        ),
        title: Text(a.title),
        subtitle: Text(a.description),
        trailing: const Icon(FeatherIcons.chevronRight),
        onTap: () {
          Navigator.of(context).pushNamed('/caregiver/health-monitoring/${a.memberId}');
        },
      ),
    );
  }
}