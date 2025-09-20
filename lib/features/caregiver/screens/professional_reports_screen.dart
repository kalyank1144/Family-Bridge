import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/health_analytics_service.dart';
import '../providers/family_data_provider.dart';
import '../providers/health_monitoring_provider.dart';

class ProfessionalReportsScreen extends StatefulWidget {
  const ProfessionalReportsScreen({super.key});

  @override
  State<ProfessionalReportsScreen> createState() => _ProfessionalReportsScreenState();
}

class _ProfessionalReportsScreenState extends State<ProfessionalReportsScreen> {
  String? _selectedMemberId;
  DateTimeRange? _selectedRange;

  @override
  void initState() {
    super.initState();
    final familyProvider = context.read<FamilyDataProvider>();
    if (familyProvider.familyMembers.isNotEmpty) {
      _selectedMemberId = familyProvider.familyMembers.first.id;
    }
    _selectedRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final familyProvider = context.watch<FamilyDataProvider>();
    final healthProvider = context.watch<HealthMonitoringProvider>();
    final members = familyProvider.familyMembers;
    final analytics = HealthAnalyticsService();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Professional Reports'),
        centerTitle: true,
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(FeatherIcons.download),
            onPressed: () => _exportReport(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _controlsCard(context, members),
            const SizedBox(height: AppTheme.spacingLg),
            if (_selectedMemberId != null) ...[
              _summaryCard(context, members, analytics),
              const SizedBox(height: AppTheme.spacingLg),
              _medicationComplianceCard(context, healthProvider),
              const SizedBox(height: AppTheme.spacingLg),
              _vitalTrendsCard(context, healthProvider),
              const SizedBox(height: AppTheme.spacingLg),
              _alertHistoryCard(context),
              const SizedBox(height: AppTheme.spacingLg),
              _recommendationsCard(context, analytics, members),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _shareReport(context),
        icon: const Icon(FeatherIcons.share2),
        label: const Text('Share Report'),
      ),
    );
  }

  Widget _controlsCard(BuildContext context, List members) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Report Parameters', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppTheme.spacingMd),
            Text('Family Member', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: AppTheme.spacingSm),
            Wrap(
              spacing: 8,
              children: members.map<Widget>((member) {
                final selected = member.id == _selectedMemberId;
                return ChoiceChip(
                  label: Text(member.name),
                  selected: selected,
                  onSelected: (sel) {
                    if (sel) {
                      setState(() {
                        _selectedMemberId = member.id;
                      });
                    }
                  },
                  selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                  labelStyle: TextStyle(color: selected ? AppTheme.primaryColor : AppTheme.textPrimary),
                );
              }).toList(),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date Range', style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: AppTheme.spacingSm),
                      OutlinedButton.icon(
                        onPressed: () => _selectDateRange(context),
                        icon: const Icon(FeatherIcons.calendar),
                        label: Text(_selectedRange != null 
                            ? '${_formatDate(_selectedRange!.start)} - ${_formatDate(_selectedRange!.end)}'
                            : 'Select dates'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(BuildContext context, List members, HealthAnalyticsService analytics) {
    final member = members.firstWhere((m) => m.id == _selectedMemberId);
    final riskScore = analytics.riskScore(member);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Health Summary', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              children: [
                _summaryItem(context, 'Risk Score', '${(riskScore * 100).toInt()}/100', 
                    riskScore > 0.7 ? AppTheme.errorColor : riskScore > 0.4 ? AppTheme.warningColor : AppTheme.successColor),
                const SizedBox(width: AppTheme.spacingLg),
                _summaryItem(context, 'Status', _getStatusText(member.healthStatus), member.statusColor),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              children: [
                _summaryItem(context, 'Compliance', '${(member.medicationCompliance * 100).toInt()}%', 
                    member.medicationCompliance >= 0.9 ? AppTheme.successColor : AppTheme.warningColor),
                const SizedBox(width: AppTheme.spacingLg),
                _summaryItem(context, 'Active Alerts', '${member.activeAlerts.length}', 
                    member.activeAlerts.isEmpty ? AppTheme.successColor : AppTheme.errorColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _medicationComplianceCard(BuildContext context, HealthMonitoringProvider healthProvider) {
    final compliance = healthProvider.getMedicationCompliance(_selectedMemberId ?? '', days: 30);
    final medications = healthProvider.getMedicationsForMember(_selectedMemberId ?? '');
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Medication Compliance (30 days)', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Text('${(compliance * 100).toInt()}%', 
                           style: Theme.of(context).textTheme.displayMedium?.copyWith(
                             color: compliance >= 0.9 ? AppTheme.successColor : AppTheme.warningColor,
                             fontWeight: FontWeight.bold,
                           )),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: compliance,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          compliance >= 0.9 ? AppTheme.successColor : AppTheme.warningColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppTheme.spacingLg),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Medications: ${medications.length}', style: Theme.of(context).textTheme.bodyMedium),
                      Text('Missed: ${medications.where((m) => !m.isTaken).length}', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      if (compliance < 0.8)
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.warningColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child: const Row(
                            children: [
                              Icon(FeatherIcons.alertTriangle, size: 16, color: AppTheme.warningColor),
                              SizedBox(width: 8),
                              Expanded(child: Text('Below target compliance', style: TextStyle(color: AppTheme.warningColor, fontSize: 12))),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _vitalTrendsCard(BuildContext context, HealthMonitoringProvider healthProvider) {
    final hrHistory = healthProvider.getHeartRateHistory(_selectedMemberId ?? '', days: 30);
    final bpHistory = healthProvider.getBloodPressureHistory(_selectedMemberId ?? '', days: 30);
    final analytics = HealthAnalyticsService();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vital Signs Trends (30 days)', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              children: [
                _trendItem(context, 'Heart Rate', hrHistory.isNotEmpty ? '${hrHistory.last.toInt()} bpm' : '--', 
                           hrHistory.isNotEmpty ? analytics.trendOf(hrHistory) : 'stable'),
                const SizedBox(width: AppTheme.spacingLg),
                _trendItem(context, 'Blood Pressure', bpHistory.isNotEmpty ? '${bpHistory.last['systolic']?.toInt()}/${bpHistory.last['diastolic']?.toInt()}' : '--/--', 
                           bpHistory.isNotEmpty ? analytics.trendOf(bpHistory.map((bp) => bp['systolic']!).toList()) : 'stable'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _trendItem(BuildContext context, String label, String value, String trend) {
    final trendColor = trend == 'up' ? AppTheme.warningColor : trend == 'down' ? AppTheme.successColor : AppTheme.textSecondary;
    final trendIcon = trend == 'up' ? FeatherIcons.trendingUp : trend == 'down' ? FeatherIcons.trendingDown : FeatherIcons.minus;
    
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(trendIcon, size: 16, color: trendColor),
              const SizedBox(width: 4),
              Text(trend, style: TextStyle(color: trendColor, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _alertHistoryCard(BuildContext context) {
    // Mock alert history data
    final alertCount = 3;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alert History (30 days)', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              children: [
                Icon(FeatherIcons.bell, color: alertCount > 5 ? AppTheme.errorColor : AppTheme.infoColor),
                const SizedBox(width: 8),
                Text('$alertCount alerts generated', style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text('Most recent: Missed medication alert 2 hours ago', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _recommendationsCard(BuildContext context, HealthAnalyticsService analytics, List members) {
    final member = members.firstWhere((m) => m.id == _selectedMemberId);
    final recommendations = _generateRecommendations(member, analytics);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Clinical Recommendations', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTheme.spacingMd),
            ...recommendations.map((rec) => Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(rec, style: Theme.of(context).textTheme.bodyMedium)),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  List<String> _generateRecommendations(dynamic member, HealthAnalyticsService analytics) {
    final recommendations = <String>[];
    
    if (member.medicationCompliance < 0.8) {
      recommendations.add('Consider medication adherence counseling or pill organizer system');
    }
    
    final riskScore = analytics.riskScore(member);
    if (riskScore > 0.7) {
      recommendations.add('Schedule follow-up appointment within 1-2 weeks for high-risk assessment');
    }
    
    if (member.activeAlerts.isNotEmpty) {
      recommendations.add('Address active alerts: ${member.activeAlerts.join(', ')}');
    }
    
    recommendations.add('Continue current monitoring protocol with weekly check-ins');
    
    return recommendations;
  }

  void _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedRange,
    );
    
    if (picked != null) {
      setState(() {
        _selectedRange = picked;
      });
    }
  }

  void _exportReport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report exported as PDF')),
    );
  }

  void _shareReport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report shared with healthcare provider')),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getStatusText(dynamic status) {
    return status.toString().split('.').last;
  }
}