import 'package:flutter/material.dart';

import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:provider/provider.dart';

import 'package:family_bridge/core/theme/app_theme.dart';
import 'package:family_bridge/features/caregiver/providers/family_data_provider.dart';
import 'package:family_bridge/features/caregiver/providers/health_monitoring_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = 'Weekly';
  String? _selectedMemberId;

  @override
  Widget build(BuildContext context) {
    final familyProvider = context.watch<FamilyDataProvider>();
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        title: const Text('Health Reports'),
        actions: [
          IconButton(
            icon: const Icon(FeatherIcons.share2),
            onPressed: _shareReport,
          ),
          IconButton(
            icon: const Icon(FeatherIcons.download),
            onPressed: _downloadReport,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          children: [
            _buildReportControls(familyProvider),
            const SizedBox(height: AppTheme.spacingMd),
            _buildReportSummary(context),
            const SizedBox(height: AppTheme.spacingMd),
            _buildHealthMetrics(context),
            const SizedBox(height: AppTheme.spacingMd),
            _buildComplianceReport(context),
            const SizedBox(height: AppTheme.spacingMd),
            _buildActivityReport(context),
          ],
        ),
      ),
    );
  }

  Widget _buildReportControls(FamilyDataProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedMemberId,
                    decoration: const InputDecoration(
                      labelText: 'Family Member',
                      prefixIcon: Icon(FeatherIcons.user),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Members'),
                      ),
                      ...provider.familyMembers.map((member) {
                        return DropdownMenuItem(
                          value: member.id,
                          child: Text(member.name),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedMemberId = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedPeriod,
                    decoration: const InputDecoration(
                      labelText: 'Period',
                      prefixIcon: Icon(FeatherIcons.calendar),
                    ),
                    items: ['Daily', 'Weekly', 'Monthly', 'Yearly'].map((period) {
                      return DropdownMenuItem(
                        value: period,
                        child: Text(period),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPeriod = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportSummary(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'Period: $_selectedPeriod Report',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Generated: ${DateTime.now().toString().split(' ')[0]}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSummaryCard(
                  context,
                  'Overall Health',
                  '92%',
                  AppTheme.successColor,
                  Icons.favorite,
                ),
                _buildSummaryCard(
                  context,
                  'Compliance',
                  '87%',
                  AppTheme.warningColor,
                  Icons.medication,
                ),
                _buildSummaryCard(
                  context,
                  'Activity',
                  '78%',
                  AppTheme.infoColor,
                  Icons.directions_walk,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMetrics(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Health Metrics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            _buildMetricRow('Blood Pressure', '120/80 mmHg', 'Normal'),
            _buildMetricRow('Heart Rate', '72 bpm', 'Normal'),
            _buildMetricRow('Oxygen Level', '98%', 'Normal'),
            _buildMetricRow('Temperature', '98.6°F', 'Normal'),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, String status) {
    final color = status == 'Normal' ? AppTheme.successColor : AppTheme.warningColor;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceReport(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medication Compliance',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            LinearProgressIndicator(
              value: 0.87,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.successColor),
            ),
            const SizedBox(height: 8),
            Text(
              '87% compliance rate',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              'Missed Medications: 3',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'On-time Rate: 92%',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityReport(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            _buildActivityRow('Average Steps', '5,234 steps/day'),
            _buildActivityRow('Active Days', '5 out of 7'),
            _buildActivityRow('Goal Achievement', '78%'),
            _buildActivityRow('Most Active Time', '10:00 AM - 11:00 AM'),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _shareReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report shared successfully')),
    );
  }

  void _downloadReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report downloaded successfully')),
    );
  }
}
