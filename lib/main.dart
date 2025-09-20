import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Core imports
import 'core/theme/app_theme.dart';
import 'core/utils/env.dart';
import 'core/router/app_router.dart';
import 'core/services/auth_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/voice_service.dart';
import 'core/models/user_model.dart';
import 'core/models/message_model.dart';

// Provider imports
import 'features/auth/providers/auth_provider.dart';
import 'features/caregiver/providers/family_data_provider.dart';
import 'features/caregiver/providers/health_monitoring_provider.dart';
import 'features/caregiver/providers/appointments_provider.dart';
import 'features/caregiver/providers/alert_provider.dart';
import 'features/elder/providers/elder_provider.dart';
import 'features/onboarding/providers/user_type_provider.dart';
import 'features/admin/providers/hipaa_compliance_provider.dart';
import 'features/chat/providers/chat_providers.dart';

/// Application entry point
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await _initializeApp();
    runApp(const FamilyBridgeApp());
  } catch (error, stackTrace) {
    debugPrint('Failed to initialize app: $error');
    debugPrint('Stack trace: $stackTrace');
    runApp(ErrorApp(error: error.toString()));
  }
}

/// Initialize all app dependencies and services
Future<void> _initializeApp() async {
  // Load environment variables
  await dotenv.load(fileName: '.env', isOptional: true);

  // Set device orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Hive for local storage
  await Hive.initFlutter();
  await _registerHiveAdapters();

  // Initialize Supabase if configured
  if (Env.supabaseUrl.isNotEmpty && Env.supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
  }

  // Initialize core services
  await AuthService.instance.initialize();
  await NotificationService.instance.initialize();
}

/// Register Hive adapters for local storage
Future<void> _registerHiveAdapters() async {
  Hive.registerAdapter(MessageAdapter());
  Hive.registerAdapter(MessageTypeAdapter());
  Hive.registerAdapter(MessageStatusAdapter());
  Hive.registerAdapter(MessagePriorityAdapter());
  Hive.registerAdapter(MessageReactionAdapter());
}

/// Main application widget with providers and routing
class FamilyBridgeApp extends StatelessWidget {
  const FamilyBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MultiProvider(
        providers: [
          // Core providers
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => UserTypeProvider()),

          // Feature providers
          ChangeNotifierProvider(create: (_) => FamilyDataProvider()),
          ChangeNotifierProvider(create: (_) => HealthMonitoringProvider()),
          ChangeNotifierProvider(create: (_) => AppointmentsProvider()),
          ChangeNotifierProvider(create: (_) => AlertProvider()),
          ChangeNotifierProvider(create: (_) => ElderProvider()),
          ChangeNotifierProvider(create: (_) => HipaaComplianceProvider()),

          // Services as providers
          Provider<VoiceService>(create: (_) => VoiceService()),
          Provider<NotificationService>.value(value: NotificationService.instance),
        ],
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            return MaterialApp.router(
              title: 'FamilyBridge',
              debugShowCheckedModeBanner: false,
              theme: _getThemeForUser(authProvider),
              routerConfig: AppRouter.createRouter(context),
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaleFactor: _getTextScaleForUser(authProvider),
                  ),
                  child: child ?? const SizedBox.shrink(),
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Get appropriate theme based on user profile and accessibility needs
  ThemeData _getThemeForUser(AuthProvider authProvider) {
    final profile = authProvider.profile;
    
    // Use elder theme for elders or users with accessibility preferences
    if (profile?.role == UserRole.elder || 
        profile?.accessibility.largeText == true ||
        profile?.accessibility.highContrast == true) {
      return AppTheme.elderTheme;
    }
    
    // Use onboarding theme for unauthenticated users
    if (!authProvider.isAuthenticated) {
      return AppTheme.onboardingTheme;
    }
    
    return AppTheme.lightTheme;
  }

  /// Get text scale factor based on user accessibility preferences
  double _getTextScaleForUser(AuthProvider authProvider) {
    final profile = authProvider.profile;
    
    if (profile?.accessibility.largeText == true) {
      return 1.3;
    }
    
    return 1.0;
  }
}

/// Error application for initialization failures
class ErrorApp extends StatelessWidget {
  final String error;
  
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FamilyBridge - Error',
      theme: AppTheme.lightTheme,
      home: ErrorScreen(error: error),
    );
  }
}

/// Error screen widget
class ErrorScreen extends StatelessWidget {
  final String error;
  
  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Application Error'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
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
              'Failed to start FamilyBridge',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Please try restarting the application. If the problem persists, contact support.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                error,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: Colors.red[800],
                ),
                textAlign: TextAlign.left,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                SystemNavigator.pop();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Restart App'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}