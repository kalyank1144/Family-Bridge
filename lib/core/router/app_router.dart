import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Core imports
import '../models/user_model.dart';

// Auth imports
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/profile_setup_screen.dart';
import '../../features/auth/screens/profile_screen.dart';
import '../../features/auth/screens/family_setup_screen.dart';
import '../../features/auth/screens/family_members_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';

// Onboarding imports
import '../../features/onboarding/screens/welcome_screen.dart';
import '../../features/onboarding/screens/user_type_selection_screen.dart';
import '../../features/onboarding/providers/user_type_provider.dart';

// Caregiver imports
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

// Admin imports
import '../../features/admin/screens/compliance_dashboard_screen.dart';
import '../../features/admin/screens/audit_logs_screen.dart';

// Elder imports
import '../../features/elder/screens/elder_home_screen.dart';
import '../../features/elder/screens/emergency_contacts_screen.dart';
import '../../features/elder/screens/medication_reminder_screen.dart';
import '../../features/elder/screens/daily_checkin_screen.dart';
import '../../features/elder/screens/family_chat_screen.dart' as elder_chat;

// Youth imports
import '../../features/youth/screens/youth_home_dashboard.dart';
import '../../features/youth/screens/story_recording_screen.dart';
import '../../features/youth/screens/youth_games_screen.dart';
import '../../features/youth/screens/photo_sharing_screen.dart';

// Chat imports
import '../../features/chat/screens/family_chat_screen.dart';
import '../../features/chat/screens/chat_settings_screen.dart';

// Additional admin imports
import '../../features/admin/screens/secure_authentication_screen.dart';

/// Centralized application router with authentication and role-based routing
class AppRouter {
  /// Create router instance with context for auth checking
  static GoRouter createRouter(BuildContext context) {
    return GoRouter(
      initialLocation: '/welcome',
      debugLogDiagnostics: false,
      redirect: (context, state) => _handleRedirect(context, state),
      routes: [
        // === ONBOARDING & AUTH ROUTES ===
        GoRoute(
          path: '/welcome',
          name: 'welcome',
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/user-type',
          name: 'user_type',
          builder: (context, state) => const UserTypeSelectionScreen(),
        ),
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

        // === CAREGIVER ROUTES ===
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

        // === ELDER ROUTES ===
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
              name: 'elder_family_chat',
              builder: (context, state) => const elder_chat.FamilyChatScreen(),
            ),
          ],
        ),

        // === YOUTH ROUTES ===
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
            ),
          ],
        ),

        // === SHARED CHAT ROUTES ===
        GoRoute(
          path: '/chat/:familyId',
          name: 'family_chat',
          builder: (context, state) {
            final familyId = state.pathParameters['familyId']!;
            final userId = state.uri.queryParameters['userId'];
            final userType = state.uri.queryParameters['userType'];
            
            return FamilyChatScreen(
              familyId: familyId,
              userId: userId ?? '',
              userType: userType ?? 'elder',
            );
          },
          routes: [
            GoRoute(
              path: 'settings',
              name: 'chat_settings',
              builder: (context, state) {
                final familyId = state.pathParameters['familyId']!;
                return ChatSettingsScreen(familyId: familyId);
              },
            ),
          ],
        ),

        // === ADMIN ROUTES ===
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
            GoRoute(
              path: 'secure-auth',
              name: 'secure_auth',
              builder: (context, state) => const SecureAuthenticationScreen(),
            ),
          ],
        ),
      ],
    );
  }

  /// Handle authentication and role-based redirects
  static String? _handleRedirect(BuildContext context, GoRouterState state) {
    final authProvider = context.read<AuthProvider>();
    final currentPath = state.matchedLocation;
    
    // Public routes that don't require authentication
    final publicRoutes = [
      '/welcome',
      '/onboarding', 
      '/user-type',
      '/login',
      '/signup',
      '/forgot-password',
    ];

    // Check if current route is public
    final isPublicRoute = publicRoutes.any((route) => currentPath.startsWith(route));
    
    // Check authentication status
    final isAuthenticated = authProvider.isAuthenticated;
    final isLoading = authProvider.status == AuthStatus.unknown;

    // Don't redirect while authentication is loading
    if (isLoading) return null;

    // If not authenticated and not on public route, redirect to welcome
    if (!isAuthenticated && !isPublicRoute) {
      return '/welcome';
    }

    // If authenticated and on public route, redirect to appropriate home
    if (isAuthenticated && isPublicRoute) {
      return _getHomePathForRole(authProvider.profile?.role);
    }

    // Check role-based access
    if (isAuthenticated) {
      final userRole = authProvider.profile?.role;
      if (userRole != null && !_hasAccessToRoute(currentPath, userRole)) {
        // Redirect to user's home if they don't have access
        return _getHomePathForRole(userRole);
      }
    }

    return null; // No redirect needed
  }

  /// Get home path for user role
  static String _getHomePathForRole(UserRole? role) {
    switch (role) {
      case UserRole.elder:
        return '/elder';
      case UserRole.caregiver:
        return '/caregiver';
      case UserRole.youth:
        return '/youth';
      case UserRole.professional:
      case UserRole.admin:
      case UserRole.superAdmin:
        return '/admin';
      case null:
        return '/welcome';
    }
  }

  /// Check if user role has access to route
  static bool _hasAccessToRoute(String route, UserRole role) {
    // Elder access
    if (route.startsWith('/elder')) {
      return role == UserRole.elder;
    }
    
    // Caregiver access
    if (route.startsWith('/caregiver')) {
      return role == UserRole.caregiver;
    }
    
    // Youth access
    if (route.startsWith('/youth')) {
      return role == UserRole.youth;
    }
    
    // Admin access
    if (route.startsWith('/admin')) {
      return [UserRole.professional, UserRole.admin, UserRole.superAdmin].contains(role);
    }
    
    // Chat access - all authenticated users can access family chat
    if (route.startsWith('/chat')) {
      return UserType.isFamilyMember(role);
    }
    
    // Shared routes like profile, family-members - all authenticated users
    if (route.startsWith('/profile') || route.startsWith('/family')) {
      return true;
    }
    
    // Default deny
    return false;
  }

  /// Navigation helpers
  static void goToLogin(BuildContext context) {
    context.go('/login');
  }

  static void goToHome(BuildContext context, UserRole role) {
    context.go(_getHomePathForRole(role));
  }

  static void goToChat(BuildContext context, String familyId, {String? userId, String? userType}) {
    final uri = Uri(
      path: '/chat/$familyId',
      queryParameters: {
        if (userId != null) 'userId': userId,
        if (userType != null) 'userType': userType,
      },
    );
    context.go(uri.toString());
  }

  static void goToProfile(BuildContext context) {
    context.go('/profile');
  }

  static void goToFamilyMembers(BuildContext context) {
    context.go('/family-members');
  }

  /// Deep link handling
  static String? handleDeepLink(String? link) {
    if (link == null || link.isEmpty) return null;

    final uri = Uri.tryParse(link);
    if (uri == null) return null;

    // Handle family bridge deep links
    if (uri.scheme == 'familybridge' || uri.scheme == 'https' && uri.host == 'familybridge.app') {
      return uri.path;
    }

    return null;
  }

  /// Route information for navigation UI
  static const Map<String, RouteInfo> routeInfo = {
    '/elder': RouteInfo(
      title: 'Home',
      icon: Icons.home,
      requiresAuth: true,
      allowedRoles: [UserRole.elder],
    ),
    '/caregiver': RouteInfo(
      title: 'Dashboard',
      icon: Icons.dashboard,
      requiresAuth: true,
      allowedRoles: [UserRole.caregiver],
    ),
    '/youth': RouteInfo(
      title: 'Home',
      icon: Icons.home,
      requiresAuth: true,
      allowedRoles: [UserRole.youth],
    ),
    '/admin': RouteInfo(
      title: 'Admin',
      icon: Icons.admin_panel_settings,
      requiresAuth: true,
      allowedRoles: [UserRole.professional, UserRole.admin, UserRole.superAdmin],
    ),
  };
}

/// Route information for navigation
class RouteInfo {
  final String title;
  final IconData icon;
  final bool requiresAuth;
  final List<UserRole> allowedRoles;

  const RouteInfo({
    required this.title,
    required this.icon,
    this.requiresAuth = false,
    this.allowedRoles = const [],
  });
}
