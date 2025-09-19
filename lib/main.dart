import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/utils/env.dart';
import 'core/services/auth_service.dart';
import 'core/models/user_model.dart';

// Auth
import 'features/auth/providers/auth_provider.dart';

// Caregiver providers
import 'features/caregiver/providers/family_data_provider.dart';
import 'features/caregiver/providers/health_monitoring_provider.dart';
import 'features/caregiver/providers/appointments_provider.dart';
import 'features/caregiver/providers/alert_provider.dart';
import 'features/caregiver/services/notification_service.dart';

// Elder + Voice
import 'features/elder/providers/elder_provider.dart';
import 'core/services/voice_service.dart';

// Chat
import 'features/chat/providers/chat_providers.dart';
import 'features/chat/services/notification_service.dart' as chat_notifications;

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
  }
}

// Loading screen for app initialization
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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