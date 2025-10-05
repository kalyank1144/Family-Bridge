import 'package:flutter/material.dart';
import 'package:family_bridge/config/app_config.dart';
import 'package:family_bridge/routes/app_routes.dart';
import 'package:family_bridge/widgets/caregiver/family_member_card.dart';
import 'package:family_bridge/widgets/caregiver/quick_action_button.dart';

class CaregiverHomeScreen extends StatelessWidget {
  const CaregiverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.caregiverBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppConfig.caregiverPrimaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Care Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Family Members',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              const FamilyMemberCard(
                name: 'Robert Johnson',
                relationship: 'Father',
                status: 'Good',
                lastCheckin: '2 hours ago',
                imageUrl: null,
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.monitor_heart,
                      label: 'Health',
                      color: AppConfig.primaryColor,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.caregiverHealthMonitoring,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.calendar_today,
                      label: 'Appointments',
                      color: AppConfig.secondaryColor,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.caregiverAppointments,
                        );
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.task,
                      label: 'Tasks',
                      color: AppConfig.warningColor,
                      onTap: () {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuickActionButton(
                      icon: Icons.message,
                      label: 'Messages',
                      color: AppConfig.youthPrimaryColor,
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.familyChat);
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              _buildActivityItem(
                context,
                Icons.check_circle,
                'Daily check-in completed',
                '2 hours ago',
                AppConfig.elderPrimaryColor,
              ),
              
              _buildActivityItem(
                context,
                Icons.medication,
                'Medication taken: Aspirin',
                '3 hours ago',
                AppConfig.primaryColor,
              ),
              
              _buildActivityItem(
                context,
                Icons.phone,
                'Emergency contact called',
                '5 hours ago',
                AppConfig.errorColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    IconData icon,
    String title,
    String time,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
