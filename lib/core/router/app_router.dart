import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Onboarding
import '../../features/onboarding/screens/welcome_screen.dart';
import '../../features/onboarding/screens/user_type_selection_screen.dart';
import '../../features/onboarding/providers/user_type_provider.dart';

// Caregiver screens
import '../../features/caregiver/screens/caregiver_dashboard_screen.dart';
import '../../features/caregiver/screens/health_monitoring_screen.dart';
import '../../features/caregiver/screens/appointments_calendar_screen.dart';
import '../../features/caregiver/screens/family_member_detail_screen.dart';
import '../../features/caregiver/screens/add_appointment_screen.dart';
import '../../features/caregiver/screens/alert_settings_screen.dart';
import '../../features/caregiver/screens/reports_screen.dart';

// Elder screens
import '../../features/elder/screens/elder_home_screen.dart';
import '../../features/elder/screens/emergency_contacts_screen.dart';
import '../../features/elder/screens/medication_reminder_screen.dart';
import '../../features/elder/screens/daily_checkin_screen.dart';
import '../../features/elder/screens/family_chat_screen.dart' as elder_chat;

// Youth
import '../../features/youth/screens/youth_home_screen.dart';

class AppRouter {
  final UserTypeProvider userTypeProvider;
  AppRouter(this.userTypeProvider);

  late final GoRouter router = GoRouter(
    initialLocation: '/welcome',
    debugLogDiagnostics: false,
    refreshListenable: userTypeProvider,
    routes: [
      // Onboarding
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/user-type',
        name: 'user_type',
        builder: (context, state) => const UserTypeSelectionScreen(),
      ),

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
            builder: (context, state) => const elder_chat.FamilyChatScreen(),
          ),
        ],
      ),

      // Youth
      GoRoute(
        path: '/youth',
        name: 'youth_home',
        builder: (context, state) => const YouthHomeScreen(),
      ),
    ],
    redirect: (context, state) {
      final path = state.uri.path;
      final selected = userTypeProvider.userType;

      final isOnboarding = path == '/welcome' || path == '/user-type';
      final isRolePath =
          path.startsWith('/elder') || path.startsWith('/caregiver') || path.startsWith('/youth');

      // If userType selected and trying to visit onboarding, send to home
      if (selected != null && isOnboarding) {
        return switch (selected) {
          UserType.elder => '/elder',
          UserType.caregiver => '/caregiver',
          UserType.youth => '/youth',
        };
      }

      // If no user type yet and not onboarding or role deep link, go to welcome
      if (selected == null && !(isOnboarding || isRolePath)) {
        return '/welcome';
      }

      // Allow deep links to role paths even if not selected
      return null;
    },
  );
}