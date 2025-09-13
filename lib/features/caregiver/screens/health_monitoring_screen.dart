import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/family_data_provider.dart';
import '../providers/health_monitoring_provider.dart';
import '../widgets/vitals_card.dart';
import '../widgets/medication_compliance_card.dart';
import '../widgets/mood_chart.dart';
import '../widgets/daily_checkin_card.dart';

class HealthMonitoringScreen extends StatefulWidget {
  final String memberId;

  const HealthMonitoringScreen({
    super.key,
    required this.memberId,
  });

  @override
  State<HealthMonitoringScreen> createState() => _HealthMonitoringScreenState();
}

class _HealthMonitoringScreenState extends State<HealthMonitoringScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadHealthData();
  }

  Future<void> _loadHealthData() async {
    final healthProvider = context.read<HealthMonitoringProvider>();
    await healthProvider.loadHealthData(widget.memberId);
    healthProvider.subscribeToHealthUpdates(widget.memberId);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final familyProvider = context.watch<FamilyDataProvider>();
    final healthProvider = context.watch<HealthMonitoringProvider>();
    final member = familyProvider.getMemberById(widget.memberId);
    
    if (member == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Health Monitoring'),
        ),
        body: const Center(
          child: Text('Member not found'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(FeatherIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'Health Monitoring',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              member.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(FeatherIcons.download),
            onPressed: _exportHealthReport,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Vitals'),
            Tab(text: 'Medications'),
            Tab(text: 'Activity'),
            Tab(text: 'Mood'),
          ],
        ),
      ),
      body: healthProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildVitalsTab(context, member),
                _buildMedicationsTab(context, member),
                _buildActivityTab(context, member),
                _buildMoodTab(context, member),
              ],
            ),
    );
  }

  Widget _buildVitalsTab(BuildContext context, FamilyMember member) {
    final healthProvider = context.watch<HealthMonitoringProvider>();
    final latestData = healthProvider.getLatestHealthData(member.id);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: VitalsCard(
                  title: 'Blood Pressure',
                  value: latestData?.bloodPressureFormatted ?? '--/--',
                  unit: 'mmHg',
                  icon: Icons.favorite,
                  color: latestData?.isBloodPressureNormal ?? true
                      ? AppTheme.healthGreen
                      : AppTheme.healthRed,
                  chartData: healthProvider.getBloodPressureHistory(member.id),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: VitalsCard(
                  title: 'Heart Rate',
                  value: latestData?.heartRate?.toStringAsFixed(0) ?? '--',
                  unit: 'bpm',
                  icon: Icons.monitor_heart,
                  color: latestData?.isHeartRateNormal ?? true
                      ? AppTheme.healthGreen
                      : AppTheme.healthYellow,
                  chartData: healthProvider.getHeartRateHistory(member.id),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          Row(
            children: [
              Expanded(
                child: VitalsCard(
                  title: 'Oxygen Level',
                  value: latestData?.oxygenLevel?.toStringAsFixed(0) ?? '--',
                  unit: '%',
                  icon: Icons.air,
                  color: latestData?.isOxygenLevelNormal ?? true
                      ? AppTheme.healthGreen
                      : AppTheme.healthRed,
                  chartData: [],
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: VitalsCard(
                  title: 'Temperature',
                  value: latestData?.temperature?.toStringAsFixed(1) ?? '--',
                  unit: '°F',
                  icon: Icons.thermostat,
                  color: latestData?.isTemperatureNormal ?? true
                      ? AppTheme.healthGreen
                      : AppTheme.healthYellow,
                  chartData: [],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _buildBloodPressureChart(context, member),
          const SizedBox(height: AppTheme.spacingMd),
          _buildHeartRateChart(context, member),
        ],
      ),
    );
  }

  Widget _buildMedicationsTab(BuildContext context, FamilyMember member) {
    final healthProvider = context.watch<HealthMonitoringProvider>();
    final compliance = healthProvider.getMedicationCompliance(member.id);
    final medications = healthProvider.getMedicationsForMember(member.id);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MedicationComplianceCard(
            compliance: compliance,
            medications: medications,
            onMedicationTaken: (medId) {
              healthProvider.markMedicationTaken(member.id, medId);
            },
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            'Weekly Compliance',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _buildWeeklyComplianceChart(context, member),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            'Medication Schedule',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          ...medications.map((med) => _buildMedicationItem(context, med)),
        ],
      ),
    );
  }

  Widget _buildActivityTab(BuildContext context, FamilyMember member) {
    final healthProvider = context.watch<HealthMonitoringProvider>();
    final stepsHistory = healthProvider.getStepsHistory(member.id);
    final latestData = healthProvider.getLatestHealthData(member.id);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMd),
              child: Row(
                children: [
                  CircularPercentIndicator(
                    radius: 60.0,
                    lineWidth: 8.0,
                    percent: (latestData?.steps ?? 0) / 10000,
                    center: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${latestData?.steps ?? 0}',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(
                          'steps',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    progressColor: AppTheme.primaryColor,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  ),
                  const SizedBox(width: AppTheme.spacingLg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Goal: 10,000 steps',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: (latestData?.steps ?? 0) / 10000,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${((latestData?.steps ?? 0) / 10000 * 100).toInt()}% completed',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            'Weekly Activity',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          _buildActivityChart(context, stepsHistory),
        ],
      ),
    );
  }

  Widget _buildMoodTab(BuildContext context, FamilyMember member) {
    final healthProvider = context.watch<HealthMonitoringProvider>();
    final moodHistory = healthProvider.getMoodHistory(member.id);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DailyCheckInCard(
            hasCompletedCheckIn: member.hasCompletedDailyCheckIn,
            lastCheckIn: member.lastActivity,
            onRemind: () {
              // Send reminder notification
            },
          ),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            'Mood Trends',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppTheme.spacingMd),
          MoodChart(moodData: moodHistory),
          const SizedBox(height: AppTheme.spacingLg),
          _buildMoodInsights(context, moodHistory),
        ],
      ),
    );
  }

  Widget _buildBloodPressureChart(BuildContext context, FamilyMember member) {
    final healthProvider = context.watch<HealthMonitoringProvider>();
    final bpHistory = healthProvider.getBloodPressureHistory(member.id);
    
    if (bpHistory.isEmpty) {
      return Card(
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: const Center(
            child: Text('No blood pressure data available'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Blood Pressure Trend',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: bpHistory.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value['systolic']!,
                        );
                      }).toList(),
                      isCurved: true,
                      color: AppTheme.errorColor,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                    ),
                    LineChartBarData(
                      spots: bpHistory.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value['diastolic']!,
                        );
                      }).toList(),
                      isCurved: true,
                      color: AppTheme.primaryColor,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeartRateChart(BuildContext context, FamilyMember member) {
    final healthProvider = context.watch<HealthMonitoringProvider>();
    final hrHistory = healthProvider.getHeartRateHistory(member.id);
    
    if (hrHistory.isEmpty) {
      return Card(
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: const Center(
            child: Text('No heart rate data available'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Heart Rate Trend',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: hrHistory.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), entry.value);
                      }).toList(),
                      isCurved: true,
                      color: AppTheme.healthGreen,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.healthGreen.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyComplianceChart(BuildContext context, FamilyMember member) {
    return Card(
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (index) {
            final day = DateTime.now().subtract(Duration(days: 6 - index));
            final dayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day.weekday - 1];
            final isCompliant = index != 2; // Mock data: missed on Wednesday
            
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isCompliant ? Icons.check_circle : Icons.cancel,
                  color: isCompliant ? AppTheme.successColor : AppTheme.errorColor,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  dayName,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildActivityChart(BuildContext context, List<int> stepsHistory) {
    if (stepsHistory.isEmpty) {
      return Card(
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: const Center(
            child: Text('No activity data available'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: stepsHistory.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.toDouble(),
                      color: AppTheme.primaryColor,
                      width: 20,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedicationItem(BuildContext context, MedicationRecord med) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: med.isTaken
                ? AppTheme.successColor.withOpacity(0.1)
                : AppTheme.warningColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Icon(
            Icons.medication,
            color: med.isTaken ? AppTheme.successColor : AppTheme.warningColor,
          ),
        ),
        title: Text(med.name),
        subtitle: Text('${med.dosage} - ${_formatTime(med.scheduledTime)}'),
        trailing: med.isTaken
            ? Icon(Icons.check_circle, color: AppTheme.successColor)
            : TextButton(
                onPressed: () {
                  final provider = context.read<HealthMonitoringProvider>();
                  provider.markMedicationTaken(widget.memberId, med.id);
                },
                child: const Text('Mark Taken'),
              ),
      ),
    );
  }

  Widget _buildMoodInsights(BuildContext context, List<int> moodHistory) {
    if (moodHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    final averageMood = moodHistory.reduce((a, b) => a + b) / moodHistory.length;
    final trend = moodHistory.last > moodHistory.first ? 'improving' : 'declining';
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mood Insights',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              children: [
                Icon(
                  trend == 'improving' ? Icons.trending_up : Icons.trending_down,
                  color: trend == 'improving' ? AppTheme.successColor : AppTheme.warningColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Mood is $trend',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Average mood score: ${averageMood.toStringAsFixed(1)}/5',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  void _exportHealthReport() {
    // Export health report functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Health report exported successfully'),
      ),
    );
  }
}