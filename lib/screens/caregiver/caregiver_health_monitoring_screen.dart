import 'package:flutter/material.dart';
import 'package:family_bridge/config/app_config.dart';
import 'package:family_bridge/widgets/caregiver/health_metric_card.dart';

class CaregiverHealthMonitoringScreen extends StatelessWidget {
  const CaregiverHealthMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.caregiverBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppConfig.caregiverPrimaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Health Monitoring',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConfig.elderPrimaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppConfig.elderPrimaryColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: AppConfig.elderPrimaryColor,
                      child: Text(
                        'RJ',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Robert Johnson',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Last check-in: 2 hours ago',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppConfig.elderPrimaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Good',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'Vital Signs',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: HealthMetricCard(
                      icon: Icons.favorite,
                      label: 'Heart Rate',
                      value: '72',
                      unit: 'bpm',
                      color: AppConfig.errorColor,
                      trend: 'stable',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: HealthMetricCard(
                      icon: Icons.thermostat,
                      label: 'Blood Pressure',
                      value: '120/80',
                      unit: 'mmHg',
                      color: AppConfig.primaryColor,
                      trend: 'stable',
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: HealthMetricCard(
                      icon: Icons.directions_walk,
                      label: 'Steps',
                      value: '3,245',
                      unit: 'steps',
                      color: AppConfig.elderPrimaryColor,
                      trend: 'up',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: HealthMetricCard(
                      icon: Icons.bedtime,
                      label: 'Sleep',
                      value: '7.5',
                      unit: 'hours',
                      color: AppConfig.youthPrimaryColor,
                      trend: 'stable',
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'Medication Compliance',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildMedicationItem(
                      'Aspirin',
                      '8:00 AM',
                      true,
                      AppConfig.elderPrimaryColor,
                    ),
                    const Divider(),
                    _buildMedicationItem(
                      'Lisinopril',
                      '12:00 PM',
                      false,
                      AppConfig.warningColor,
                    ),
                    const Divider(),
                    _buildMedicationItem(
                      'Metformin',
                      '6:00 PM',
                      false,
                      Colors.grey,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'Mood Tracking',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildMoodIndicator('😊', 'Happy', 15),
                    _buildMoodIndicator('😐', 'Okay', 10),
                    _buildMoodIndicator('😢', 'Sad', 2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicationItem(
    String name,
    String time,
    bool taken,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            taken ? Icons.check_circle : Icons.schedule,
            color: color,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            taken ? 'Taken' : 'Pending',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodIndicator(String emoji, String label, int days) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 48),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$days days',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
