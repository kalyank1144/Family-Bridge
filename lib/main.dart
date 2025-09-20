import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:go_router/go_router.dart';


import 'core/theme/app_theme.dart';
import 'core/utils/env.dart';

import 'features/chat/screens/family_chat_screen.dart';
import 'features/chat/services/notification_service.dart';

import 'core/services/auth_service.dart';
import 'core/models/user_model.dart';


import 'features/auth/providers/auth_provider.dart';


// Caregiver providers
import 'features/caregiver/providers/family_data_provider.dart';
import 'features/caregiver/providers/health_monitoring_provider.dart';
import 'features/caregiver/providers/appointments_provider.dart';
import 'features/caregiver/providers/alert_provider.dart';


// Elder imports

import 'features/caregiver/services/notification_service.dart';

import 'features/elder/providers/elder_provider.dart';
import 'features/elder/screens/elder_home_screen.dart';
import 'core/services/voice_service.dart';
import 'features/chat/screens/family_chat_screen.dart';

// Chat
import 'features/chat/providers/chat_providers.dart';
import 'features/chat/services/notification_service.dart' as chat_notifications;

// HIPAA Compliance
import 'features/admin/providers/hipaa_compliance_provider.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);


  // Load environment variables
  await dotenv.load(fileName: ".env", isOptional: true);



  // Initialize Supabase




  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );




  // Initialize auth service
  await AuthService.instance.initialize();

  // Initialize notifications




  await NotificationService.instance.initialize();
  await chat_notifications.NotificationService().initialize(userType: 'elder');

  // Initialize shared preferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize voice service
  final voiceService = VoiceService();
  await voiceService.initialize();

  runApp(FamilyBridgeApp(
    prefs: prefs,
    voiceService: voiceService,
  ));
}

class FamilyBridgeApp extends StatelessWidget {
  final SharedPreferences prefs;
  final VoiceService voiceService;

  const FamilyBridgeApp({
    super.key,
    required this.prefs,
    required this.voiceService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core providers
        Provider.value(value: voiceService),
        Provider.value(value: prefs),
        
        // Auth provider (must be first for other providers to access)
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        
        // Feature providers
        ChangeNotifierProvider(create: (_) => FamilyDataProvider()),
        ChangeNotifierProvider(create: (_) => HealthMonitoringProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentsProvider()),
        ChangeNotifierProvider(create: (_) => AlertProvider()),
        ChangeNotifierProvider(create: (_) => ElderProvider()),

        ChangeNotifierProvider(create: (_) => HipaaComplianceProvider()),
        Provider.value(value: voiceService),
      ],
      child: const FamilyBridgeApp(),
    ),
  );
}

class FamilyBridgeApp extends StatelessWidget {
  const FamilyBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FamilyBridge',
      debugShowCheckedModeBanner: false,

      theme: AppTheme.elderTheme, // Use elder theme for better accessibility
      home: const UserSelectionScreen(),
    );
  }
}

class UserSelectionScreen extends StatefulWidget {
  const UserSelectionScreen({super.key});

  @override
  State<UserSelectionScreen> createState() => _UserSelectionScreenState();
}

class _UserSelectionScreenState extends State<UserSelectionScreen> {
  String _selectedUserType = 'elder';
  final _familyId = 'demo-family-123';
  final _userId = 'demo-user-456';

      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
        
        // Chat providers (using Riverpod pattern)
        Provider(create: (_) => chatServiceProvider),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp.router(
            title: 'FamilyBridge',
            debugShowCheckedModeBanner: false,
            
            // Use appropriate theme based on user role/preferences
            theme: _getTheme(authProvider),
            
            routerConfig: AppRouter.createRouter(context),
            
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaleFactor: _getTextScaleFactor(authProvider),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),

    );
  }

  ThemeData _getTheme(AuthProvider authProvider) {
    final profile = authProvider.profile;
    
    // Use elder theme if user is elder or has accessibility preferences
    if (profile?.role == UserRole.elder || 
        profile?.accessibility.largeText == true ||
        profile?.accessibility.highContrast == true) {
      return AppTheme.elderTheme;
    }
    
    return AppTheme.lightTheme;
  }



  double _getTextScaleFactor(AuthProvider authProvider) {
    final profile = authProvider.profile;
    
    if (profile?.accessibility.largeText == true) {
      return 1.3;
    }
    
    return 1.0;

  Future<void> _initializeNotifications() async {
    await NotificationService.instance.initialize();
  }
}

// Loading screen for app initialization
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  void _navigateToInterface() {
    switch (_selectedUserType) {
      case 'elder':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ElderHomeScreen(),
          ),
        );
        break;
      case 'caregiver':
        // Navigate to caregiver interface
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Caregiver interface - use existing navigation')),
        );
        break;
      case 'youth':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FamilyChatScreen(
              familyId: _familyId,
              userId: _userId,
              userType: _selectedUserType,
            ),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'FamilyBridge',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to FamilyBridge',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              'Select your role to continue',
              style: TextStyle(
                fontSize: 20,
                color: AppTheme.neutralGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 60),
            
            // User Type Selection - Large buttons for accessibility
            _UserTypeButton(
              title: 'Elder',
              subtitle: 'Large buttons, voice control, simplified interface',
              icon: Icons.elderly,
              isSelected: _selectedUserType == 'elder',
              onTap: () => setState(() => _selectedUserType = 'elder'),
              color: AppTheme.primaryBlue,
            ),
            const SizedBox(height: 20),
            _UserTypeButton(
              title: 'Caregiver',
              subtitle: 'Health monitoring, appointments, family management',
              icon: Icons.medical_services,
              isSelected: _selectedUserType == 'caregiver',
              onTap: () => setState(() => _selectedUserType = 'caregiver'),
              color: AppTheme.successGreen,
            ),
            const SizedBox(height: 20),
            _UserTypeButton(
              title: 'Youth/Family',
              subtitle: 'Modern chat, reactions, family communication',
              icon: Icons.school,
              isSelected: _selectedUserType == 'youth',
              onTap: () => setState(() => _selectedUserType = 'youth'),
              color: AppTheme.familyPurple,
            ),
            
            const SizedBox(height: 60),
            
            // Continue Button
            Container(
              width: double.infinity,
              height: 80,
              child: ElevatedButton(
                onPressed: _navigateToInterface,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.darkText,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserTypeButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _UserTypeButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 3 : 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 32,
                color: isSelected ? Colors.white : Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.neutralGray,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                size: 32,
                color: color,
              ),
          ],
        ),
      ),
    );
  }

      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.family_restroom,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            Text(
              'FamilyBridge',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}

// Error screen for app-level errors
class ErrorScreen extends StatelessWidget {
  final String error;
  
  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 24),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // Restart the app
                SystemNavigator.pop();
              },
              child: const Text('Restart app'),
            ),
          ],
        ),
      ),
    );
  }
}