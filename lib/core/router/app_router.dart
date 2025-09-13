import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/caregiver/screens/caregiver_dashboard_screen.dart';
import '../../features/caregiver/screens/health_monitoring_screen.dart';
import '../../features/caregiver/screens/appointments_calendar_screen.dart';
import '../../features/caregiver/screens/family_member_detail_screen.dart';
import '../../features/caregiver/screens/add_appointment_screen.dart';
import '../../features/caregiver/screens/alert_settings_screen.dart';
import '../../features/caregiver/screens/reports_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/caregiver',
    routes: [
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
        ],
      ),
    ],
  );
}