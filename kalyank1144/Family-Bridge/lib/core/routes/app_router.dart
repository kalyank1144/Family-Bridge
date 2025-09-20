import 'package:flutter/material.dart';
import '../../features/onboarding/screens/welcome_screen.dart';
import '../../features/onboarding/screens/user_type_selection_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/elder/screens/elder_home_screen.dart';
import '../../features/caregiver/screens/caregiver_home_screen.dart';
import '../../features/youth/screens/youth_home_screen.dart';
import '../../features/chat/screens/chat_list_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/health/screens/health_dashboard_screen.dart';
import '../../features/health/screens/daily_checkin_screen.dart';
import '../../features/medication/screens/medication_list_screen.dart';
import '../../features/medication/screens/medication_detail_screen.dart';
import '../../features/emergency/screens/emergency_contacts_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/settings/screens/offline_settings_screen.dart';
import '../../features/settings/screens/sync_management_screen.dart';

class AppRouter {
  static const String initialRoute = welcome;
  
  // Onboarding Routes
  static const String welcome = '/';
  static const String userTypeSelection = '/user-type';
  
  // Auth Routes
  static const String login = '/login';
  static const String register = '/register';
  
  // Home Routes
  static const String elderHome = '/elder/home';
  static const String caregiverHome = '/caregiver/home';
  static const String youthHome = '/youth/home';
  
  // Feature Routes
  static const String chatList = '/chat/list';
  static const String chat = '/chat';
  static const String healthDashboard = '/health/dashboard';
  static const String dailyCheckin = '/health/checkin';
  static const String medicationList = '/medication/list';
  static const String medicationDetail = '/medication/detail';
  static const String emergencyContacts = '/emergency/contacts';
  
  // Settings Routes
  static const String settings = '/settings';
  static const String offlineSettings = '/settings/offline';
  static const String syncManagement = '/settings/sync';
  
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Onboarding
      case welcome:
        return _buildRoute(const WelcomeScreen());
        
      case userTypeSelection:
        return _buildRoute(const UserTypeSelectionScreen());
      
      // Auth
      case login:
        return _buildRoute(const LoginScreen());
        
      case register:
        return _buildRoute(const RegisterScreen());
      
      // Home Screens
      case elderHome:
        return _buildRoute(const ElderHomeScreen());
        
      case caregiverHome:
        return _buildRoute(const CaregiverHomeScreen());
        
      case youthHome:
        return _buildRoute(const YouthHomeScreen());
      
      // Chat
      case chatList:
        return _buildRoute(const ChatListScreen());
        
      case chat:
        final args = settings.arguments as Map<String, dynamic>?;
        return _buildRoute(ChatScreen(
          conversationId: args?['conversationId'] ?? '',
          recipientName: args?['recipientName'] ?? '',
        ));
      
      // Health
      case healthDashboard:
        return _buildRoute(const HealthDashboardScreen());
        
      case dailyCheckin:
        return _buildRoute(const DailyCheckinScreen());
      
      // Medication
      case medicationList:
        return _buildRoute(const MedicationListScreen());
        
      case medicationDetail:
        final medicationId = settings.arguments as String?;
        return _buildRoute(MedicationDetailScreen(
          medicationId: medicationId ?? '',
        ));
      
      // Emergency
      case emergencyContacts:
        return _buildRoute(const EmergencyContactsScreen());
      
      // Settings
      case settings:
        return _buildRoute(const SettingsScreen());
        
      case offlineSettings:
        return _buildRoute(const OfflineSettingsScreen());
        
      case syncManagement:
        return _buildRoute(const SyncManagementScreen());
      
      default:
        return _buildRoute(const _NotFoundScreen());
    }
  }
  
  static MaterialPageRoute _buildRoute(Widget screen) {
    return MaterialPageRoute(
      builder: (_) => screen,
    );
  }
  
  static Future<T?> navigateTo<T>(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.pushNamed<T>(context, routeName, arguments: arguments);
  }
  
  static Future<T?> navigateAndReplace<T>(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.pushReplacementNamed<T, T>(context, routeName, arguments: arguments);
  }
  
  static Future<T?> navigateAndRemoveAll<T>(BuildContext context, String routeName, {Object? arguments}) {
    return Navigator.pushNamedAndRemoveUntil<T>(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }
  
  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.pop(context, result);
  }
  
  static bool canPop(BuildContext context) {
    return Navigator.canPop(context);
  }
}

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Page Not Found',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'The page you are looking for does not exist.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => AppRouter.navigateAndRemoveAll(
                context,
                AppRouter.welcome,
              ),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}