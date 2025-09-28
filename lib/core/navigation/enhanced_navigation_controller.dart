import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:family_bridge/features/auth/providers/auth_provider.dart';
import 'package:family_bridge/features/caregiver/providers/alert_provider.dart';
import 'package:family_bridge/features/caregiver/providers/family_data_provider.dart';
import 'package:family_bridge/features/elder/providers/elder_provider.dart';
import 'package:family_bridge/features/youth/providers/photo_sharing_provider.dart';

// Enhanced Screens
import 'package:family_bridge/features/elder/screens/enhanced_elder_dashboard.dart';
import 'package:family_bridge/features/auth/screens/enhanced_family_setup_screen.dart';
import 'package:family_bridge/features/caregiver/screens/enhanced_alert_management_screen.dart';
import 'package:family_bridge/features/youth/screens/enhanced_youth_dashboard.dart';

// Existing Screens
import 'package:family_bridge/features/caregiver/screens/caregiver_dashboard_screen.dart';
import 'package:family_bridge/features/onboarding/screens/welcome_screen.dart';
import 'package:family_bridge/features/onboarding/screens/user_type_selection_screen.dart';
import 'package:family_bridge/features/auth/screens/login_screen.dart';

/// Enhanced Navigation Controller that showcases comprehensive provider integration
/// Manages routing between enhanced screens with proper provider initialization
class EnhancedNavigationController {
  static final EnhancedNavigationController _instance = EnhancedNavigationController._internal();
  factory EnhancedNavigationController() => _instance;
  EnhancedNavigationController._internal();

  static const String welcomeRoute = '/welcome';
  static const String userTypeSelectionRoute = '/user-type';
  static const String loginRoute = '/login';
  static const String familySetupRoute = '/family-setup';
  static const String elderDashboardRoute = '/elder-dashboard';
  static const String caregiverDashboardRoute = '/caregiver-dashboard';
  static const String youthDashboardRoute = '/youth-dashboard';
  static const String alertManagementRoute = '/alert-management';

  /// Create enhanced router with provider-based navigation
  GoRouter createRouter() {
    return GoRouter(
      initialLocation: welcomeRoute,
      routes: [
        // Onboarding Flow
        GoRoute(
          path: welcomeRoute,
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(
          path: userTypeSelectionRoute,
          builder: (context, state) => const UserTypeSelectionScreen(),
        ),
        GoRoute(
          path: loginRoute,
          builder: (context, state) => const LoginScreen(),
        ),

        // Family Setup Flow
        GoRoute(
          path: familySetupRoute,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final userId = extra?['userId'] as String? ?? 'demo-user';
            final isCreating = extra?['isCreating'] as bool? ?? true;
            
            return EnhancedFamilySetupScreen(
              userId: userId,
              isCreatingFamily: isCreating,
            );
          },
        ),

        // Enhanced Dashboards with Provider Integration
        GoRoute(
          path: elderDashboardRoute,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final userId = extra?['userId'] as String? ?? 'demo-elder-user';
            
            return _withProviderInitialization(
              context: context,
              userId: userId,
              userType: 'elder',
              child: EnhancedElderDashboard(userId: userId),
            );
          },
        ),

        GoRoute(
          path: caregiverDashboardRoute,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final userId = extra?['userId'] as String? ?? 'demo-caregiver-user';
            
            return _withProviderInitialization(
              context: context,
              userId: userId,
              userType: 'caregiver',
              child: const CaregiverDashboardScreen(),
            );
          },
        ),

        GoRoute(
          path: youthDashboardRoute,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final userId = extra?['userId'] as String? ?? 'demo-youth-user';
            final familyId = extra?['familyId'] as String? ?? 'demo-family';
            
            return _withProviderInitialization(
              context: context,
              userId: userId,
              userType: 'youth',
              child: EnhancedYouthDashboard(
                userId: userId,
                familyId: familyId,
              ),
            );
          },
        ),

        // Enhanced Feature Screens
        GoRoute(
          path: alertManagementRoute,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final familyId = extra?['familyId'] as String? ?? 'demo-family';
            final caregiverId = extra?['caregiverId'] as String? ?? 'demo-caregiver';
            
            return _withProviderInitialization(
              context: context,
              userId: caregiverId,
              userType: 'caregiver',
              child: EnhancedAlertManagementScreen(
                familyId: familyId,
                caregiverId: caregiverId,
              ),
            );
          },
        ),
      ],
      redirect: (context, state) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final isAuthenticated = authProvider.isAuthenticated;
        final currentLocation = state.matchedLocation;

        // Public routes that don't require authentication
        final publicRoutes = [welcomeRoute, userTypeSelectionRoute, loginRoute];
        
        if (!isAuthenticated && !publicRoutes.contains(currentLocation)) {
          return loginRoute;
        }

        return null; // No redirect needed
      },
    );
  }

  /// Wrapper that ensures proper provider initialization before showing screens
  Widget _withProviderInitialization({
    required BuildContext context,
    required String userId,
    required String userType,
    required Widget child,
  }) {
    return FutureBuilder<void>(
      future: _initializeProvidersForUser(context, userId, userType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen(userType);
        }

        if (snapshot.hasError) {
          return _buildErrorScreen(snapshot.error.toString(), () {
            // Retry initialization
            _initializeProvidersForUser(context, userId, userType);
          });
        }

        return child;
      },
    );
  }

  /// Initialize providers based on user type and context
  Future<void> _initializeProvidersForUser(
    BuildContext context,
    String userId,
    String userType,
  ) async {
    try {
      switch (userType.toLowerCase()) {
        case 'elder':
          final elderProvider = Provider.of<ElderProvider>(context, listen: false);
          await elderProvider.initialize(userId);
          break;

        case 'caregiver':
          final familyProvider = Provider.of<FamilyDataProvider>(context, listen: false);
          final alertProvider = Provider.of<AlertProvider>(context, listen: false);
          
          await familyProvider.initialize(userId);
          
          if (familyProvider.currentFamily != null) {
            await alertProvider.initialize(familyProvider.currentFamily!.id);
          }
          break;

        case 'youth':
          // Youth providers are initialized in the dashboard itself
          // due to specific requirements for familyId parameter
          break;

        default:
          throw Exception('Unknown user type: $userType');
      }
    } catch (e) {
      throw Exception('Failed to initialize providers for $userType: $e');
    }
  }

  Widget _buildLoadingScreen(String userType) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(strokeWidth: 3),
              const SizedBox(height: 24),
              Text(
                'Loading ${_getUserTypeDisplayName(userType)} Dashboard...',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Initializing your personalized experience',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String error, VoidCallback onRetry) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Failed to Load Dashboard',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getUserTypeDisplayName(String userType) {
    switch (userType.toLowerCase()) {
      case 'elder':
        return 'Elder';
      case 'caregiver':
        return 'Caregiver';
      case 'youth':
        return 'Youth';
      default:
        return 'User';
    }
  }

  /// Navigation helper methods for easy screen transitions
  static void navigateToElderDashboard(BuildContext context, String userId) {
    context.go(elderDashboardRoute, extra: {'userId': userId});
  }

  static void navigateToCaregiverDashboard(BuildContext context, String userId) {
    context.go(caregiverDashboardRoute, extra: {'userId': userId});
  }

  static void navigateToYouthDashboard(BuildContext context, String userId, String familyId) {
    context.go(youthDashboardRoute, extra: {
      'userId': userId,
      'familyId': familyId,
    });
  }

  static void navigateToAlertManagement(BuildContext context, String familyId, String caregiverId) {
    context.go(alertManagementRoute, extra: {
      'familyId': familyId,
      'caregiverId': caregiverId,
    });
  }

  static void navigateToFamilySetup(BuildContext context, String userId, {bool isCreating = true}) {
    context.go(familySetupRoute, extra: {
      'userId': userId,
      'isCreating': isCreating,
    });
  }

  /// Navigation based on user type and role
  static void navigateToUserDashboard(BuildContext context, String userType, String userId, [String? familyId]) {
    switch (userType.toLowerCase()) {
      case 'elder':
        navigateToElderDashboard(context, userId);
        break;
      case 'primarycaregiver':
      case 'secondarycaregiver':
      case 'caregiver':
        navigateToCaregiverDashboard(context, userId);
        break;
      case 'youth':
        navigateToYouthDashboard(context, userId, familyId ?? 'demo-family');
        break;
      default:
        context.go(welcomeRoute);
    }
  }

  /// Show provider-specific action sheets
  static void showQuickActions(BuildContext context, String userType) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _QuickActionsSheet(userType: userType),
    );
  }
}

/// Quick actions sheet that provides user-type specific actions
class _QuickActionsSheet extends StatelessWidget {
  final String userType;

  const _QuickActionsSheet({required this.userType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          ...switch (userType.toLowerCase()) {
            'elder' => _buildElderActions(context),
            'caregiver' => _buildCaregiverActions(context),
            'youth' => _buildYouthActions(context),
            _ => [const Text('No actions available')],
          },
        ],
      ),
    );
  }

  List<Widget> _buildElderActions(BuildContext context) {
    return [
      ListTile(
        leading: const Icon(Icons.medication, color: Colors.blue),
        title: const Text('Take Medication'),
        subtitle: const Text('Record medication intake'),
        onTap: () {
          Navigator.pop(context);
          // Navigate to medication screen or trigger medication action
        },
      ),
      ListTile(
        leading: const Icon(Icons.favorite, color: Colors.red),
        title: const Text('Daily Check-in'),
        subtitle: const Text('Share how you\'re feeling'),
        onTap: () {
          Navigator.pop(context);
          // Navigate to check-in screen
        },
      ),
      ListTile(
        leading: const Icon(Icons.emergency, color: Colors.red),
        title: const Text('Emergency Contact'),
        subtitle: const Text('Call for immediate help'),
        onTap: () {
          Navigator.pop(context);
          // Trigger emergency contact
        },
      ),
    ];
  }

  List<Widget> _buildCaregiverActions(BuildContext context) {
    return [
      ListTile(
        leading: const Icon(Icons.add_alert, color: Colors.orange),
        title: const Text('Create Alert'),
        subtitle: const Text('Add new family alert'),
        onTap: () {
          Navigator.pop(context);
          // Navigate to alert creation
        },
      ),
      ListTile(
        leading: const Icon(Icons.family_restroom, color: Colors.blue),
        title: const Text('Family Status'),
        subtitle: const Text('Check family member updates'),
        onTap: () {
          Navigator.pop(context);
          // Navigate to family status
        },
      ),
      ListTile(
        leading: const Icon(Icons.calendar_today, color: Colors.green),
        title: const Text('Schedule Appointment'),
        subtitle: const Text('Add medical appointment'),
        onTap: () {
          Navigator.pop(context);
          // Navigate to appointment scheduling
        },
      ),
    ];
  }

  List<Widget> _buildYouthActions(BuildContext context) {
    return [
      ListTile(
        leading: const Icon(Icons.camera_alt, color: Colors.purple),
        title: const Text('Share Photo'),
        subtitle: const Text('Take and share with family'),
        onTap: () {
          Navigator.pop(context);
          // Trigger photo sharing
        },
      ),
      ListTile(
        leading: const Icon(Icons.mic, color: Colors.blue),
        title: const Text('Record Story'),
        subtitle: const Text('Share a voice message'),
        onTap: () {
          Navigator.pop(context);
          // Navigate to story recording
        },
      ),
      ListTile(
        leading: const Icon(Icons.games, color: Colors.green),
        title: const Text('Play Games'),
        subtitle: const Text('Interactive family activities'),
        onTap: () {
          Navigator.pop(context);
          // Navigate to games
        },
      ),
    ];
  }
}