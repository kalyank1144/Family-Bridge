import 'package:flutter/material.dart';
import 'package:family_bridge/config/app_config.dart';
import 'package:family_bridge/utils/helpers.dart';

class CaregiverAppointmentsScreen extends StatelessWidget {
  const CaregiverAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.caregiverBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppConfig.caregiverPrimaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Appointments',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConfig.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppConfig.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: AppConfig.primaryColor,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Today',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            Helpers.formatDate(
                              DateTime.now(),
                              format: 'EEEE, MMMM dd, yyyy',
                            ),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'Upcoming Appointments',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              _buildAppointmentCard(
                context,
                'Dr. Williams',
                'Cardiology Check-up',
                DateTime.now().add(const Duration(days: 2)),
                const TimeOfDay(hour: 10, minute: 30),
                'Main Hospital, Room 301',
                AppConfig.primaryColor,
              ),
              
              const SizedBox(height: 12),
              
              _buildAppointmentCard(
                context,
                'Dr. Smith',
                'General Health Review',
                DateTime.now().add(const Duration(days: 7)),
                const TimeOfDay(hour: 14, minute: 0),
                'Family Clinic, 2nd Floor',
                AppConfig.elderPrimaryColor,
              ),
              
              const SizedBox(height: 12),
              
              _buildAppointmentCard(
                context,
                'Lab Tests',
                'Blood Work & Analysis',
                DateTime.now().add(const Duration(days: 10)),
                const TimeOfDay(hour: 9, minute: 0),
                'Medical Center Lab',
                AppConfig.warningColor,
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'Past Appointments',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              _buildPastAppointmentCard(
                context,
                'Dr. Johnson',
                'Routine Check-up',
                DateTime.now().subtract(const Duration(days: 14)),
                'Completed',
              ),
              
              const SizedBox(height: 12),
              
              _buildPastAppointmentCard(
                context,
                'Physical Therapy',
                'Knee Rehabilitation',
                DateTime.now().subtract(const Duration(days: 21)),
                'Completed',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(
    BuildContext context,
    String doctor,
    String type,
    DateTime date,
    TimeOfDay time,
    String location,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.medical_services,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                Helpers.formatDate(date, format: 'MMM dd, yyyy'),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.access_time,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                time.format(context),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  location,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPastAppointmentCard(
    BuildContext context,
    String doctor,
    String type,
    DateTime date,
    String status,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.grey,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  type,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Helpers.formatDate(date, format: 'MMM dd'),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                status,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
