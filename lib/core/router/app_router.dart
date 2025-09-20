import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// Auth
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/profile_setup_screen.dart';
import '../../features/auth/screens/profile_screen.dart';
import '../../features/auth/screens/family_setup_screen.dart';
import '../../features/auth/screens/family_members_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';

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

// Admin screens
import '../../features/admin/screens/compliance_dashboard_screen.dart';
import '../../features/admin/screens/audit_logs_screen.dart';

import '../../features/elder/screens/elder_home_screen.dart';
import '../../features/elder/screens/emergency_contacts_screen.dart';
import '../../features/elder/screens/medication_reminder_screen.dart';
import '../../features/elder/screens/daily_checkin_screen.dart';
import '../../features/elder/screens/family_chat_screen.dart';

import '../../features/youth/screens/youth_home_dashboard.dart';
import '../../features/youth/screens/story_recording_screen.dart';
import '../../features/youth/screens/youth_games_screen.dart';
import '../../features/youth/screens/photo_sharing_screen.dart';

class AppRouter {

  static final GoRouter router = GoRouter(
    initialLocation: '/caregiver',
    routes: [

  static GoRouter createRouter(BuildContext context) {
    return GoRouter(
      initialLocation: '/onboarding',
      redirect: (context, state) {
        final authProvider = context.read<AuthProvider>();
        final isAuthenticated = authProvider.status == AuthStatus.authenticated;
        final isOnboardingRoute = state.matchedLocation.startsWith('/onboarding');
        final isOnAuthRoute = state.matchedLocation.startsWith('/login') ||
            state.matchedLocation.startsWith('/signup') ||
            state.matchedLocation.startsWith('/forgot-password');
        
        // If user has selected a role but isn't authenticated, skip onboarding
        final hasSelectedRole = authProvider.selectedRole != null;
        if (!isAuthenticated && hasSelectedRole && isOnboardingRoute) {
          return '/login';
        }
        
        // If not authenticated and not on auth/onboarding route, redirect to onboarding
        if (!isAuthenticated && !isOnAuthRoute && !isOnboardingRoute &&
            !state.matchedLocation.startsWith('/profile-setup') &&
            !state.matchedLocation.startsWith('/family-setup')) {
          return '/onboarding';
        }
        
        // If authenticated and on auth/onboarding route, redirect to appropriate home
        if (isAuthenticated && (isOnAuthRoute || isOnboardingRoute)) {
          return authProvider.roleBasedHomePath();
        }
        
        return null;
      },
      routes: [
        // Onboarding route
        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        
        // Auth routes
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          name: 'signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          name: 'forgot_password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: '/profile-setup',
          name: 'profile_setup',
          builder: (context, state) => const ProfileSetupScreen(),
        ),
        GoRoute(
          path: '/family-setup',
          name: 'family_setup',
          builder: (context, state) => const FamilySetupScreen(),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/family-members',
          name: 'family_members',
          builder: (context, state) => const FamilyMembersScreen(),
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

      GoRoute(
        path: '/youth',
        name: 'youth_home',
        builder: (context, state) => const YouthHomeDashboard(),
        routes: [
          GoRoute(
            path: 'story',
            name: 'youth_story',
            builder: (context, state) => const StoryRecordingScreen(),
          ),
          GoRoute(
            path: 'games',
            name: 'youth_games',
            builder: (context, state) => const YouthGamesScreen(),
          ),
          GoRoute(
            path: 'photos',
            name: 'youth_photos',
            builder: (context, state) => const PhotoSharingScreen(),


      // Admin routes (HIPAA Compliance)
      GoRoute(
        path: '/admin',
        name: 'admin_dashboard',
        builder: (context, state) => const ComplianceDashboardScreen(),
        routes: [
          GoRoute(
            path: 'audit-logs',
            name: 'audit_logs',
            builder: (context, state) => const AuditLogsScreen(),

          ),
        ],
      ),
    ],
  );
        ),
      ],
    );
  }

}