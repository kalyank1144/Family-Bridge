import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Caregiver screens
import '../../features/caregiver/screens/caregiver_dashboard_screen.dart';
import '../../features/caregiver/screens/health_monitoring_screen.dart';
import '../../features/caregiver/screens/appointments_calendar_screen.dart';
import '../../features/caregiver/screens/family_member_detail_screen.dart';
import '../../features/caregiver/screens/add_appointment_screen.dart';
import '../../features/caregiver/screens/alert_settings_screen.dart';
import '../../features/caregiver/screens/reports_screen.dart';
import '../../features/caregiver/screens/advanced_health_monitoring_screen.dart';
import '../../features/caregiver/screens/care_plan_screen.dart';
import '../../features/caregiver/screens/professional_reports_screen.dart';

// Elder screens
import '../../features/elder/screens/elder_home_screen.dart';
import '../../features/elder/screens/emergency_contacts_screen.dart';
import '../../features/elder/screens/medication_reminder_screen.dart';
import '../../features/elder/screens/daily_checkin_screen.dart';
import '../../features/elder/screens/family_chat_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    // Keep caregiver dashboard as initial to avoid breaking existing flows
    initialLocation: '/caregiver',
    routes: [
      // Caregiver routes
      GoRoute(
        path: '/caregiver',
        name: 'caregiver_dashboard',
        builder: (context, state) => const CaregiverDashboardScreen(),
        routes: [
          GoRoute(
            path: 'health-monitoring/:memberId',
            name: 'health_monitoring',
            builder: (context, state) {
              final memberId = state.pathParameters['memberId']!;
              return HealthMonitoringScreen(memberId: memberId);
            },
          ),
          GoRoute(
            path: 'appointments',
            name: 'appointments_calendar',
            builder: (context, state) => const AppointmentsCalendarScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: 'add_appointment',
                builder: (context, state) => const AddAppointmentScreen(),
              ),
            ],
          ),
          GoRoute(
            path: 'member/:memberId',
            name: 'family_member_detail',
            builder: (context, state) {
              final memberId = state.pathParameters['memberId']!;
              return FamilyMemberDetailScreen(memberId: memberId);
            },
          ),
          GoRoute(
            path: 'alerts',
            name: 'alert_settings',
            builder: (context, state) => const AlertSettingsScreen(),
          ),
          GoRoute(
            path: 'reports',
            name: 'reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: 'advanced-monitoring',
            name: 'advanced_monitoring',
            builder: (context, state) => const AdvancedHealthMonitoringScreen(),
          ),
          GoRoute(
            path: 'care-plan',
            name: 'care_plan',
            builder: (context, state) => const CarePlanScreen(),
          ),
          GoRoute(
            path: 'professional-reports',
            name: 'professional_reports',
            builder: (context, state) => const ProfessionalReportsScreen(),
          ),
        ],
      ),

      // Elder routes
      GoRoute(
        path: '/elder',
        name: 'elder_home',
        builder: (context, state) => const ElderHomeScreen(),
        routes: [
          GoRoute(
            path: 'contacts',
            name: 'elder_contacts',
            builder: (context, state) => const EmergencyContactsScreen(),
          ),
          GoRoute(
            path: 'medications',
            name: 'elder_medications',
            builder: (context, state) => const MedicationReminderScreen(),
          ),
          GoRoute(
            path: 'checkin',
            name: 'elder_checkin',
            builder: (context, state) => const DailyCheckinScreen(),
          ),
          GoRoute(
            path: 'family',
            name: 'elder_family',
            builder: (context, state) => const FamilyChatScreen(),
          ),
        ],
      ),
    ],
  );
}