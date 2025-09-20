import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/utils/env.dart';
import 'core/router/app_router.dart';
import 'core/services/auth_service.dart';
import 'core/services/voice_service.dart';

import 'features/auth/providers/auth_provider.dart';
import 'features/onboarding/providers/user_type_provider.dart';
import 'features/caregiver/providers/family_data_provider.dart';
import 'features/caregiver/providers/health_monitoring_provider.dart';
import 'features/caregiver/providers/appointments_provider.dart';
import 'features/caregiver/providers/alert_provider.dart';
import 'features/elder/providers/elder_provider.dart';
import 'features/youth/providers/youth_provider.dart';
import 'features/youth/providers/games_provider.dart';
import 'features/youth/providers/photo_sharing_provider.dart';
import 'features/youth/providers/story_recording_provider.dart';
import 'features/chat/providers/chat_provider.dart';
import 'features/admin/providers/hipaa_compliance_provider.dart';

import 'features/chat/services/notification_service.dart' as chat_notifications;
import 'features/caregiver/services/notification_service.dart' as caregiver_notifications;

import 'services/sync/data_sync_service.dart';
import 'services/offline/offline_manager.dart';
import 'services/network/network_manager.dart';
import 'shared/services/analytics_service.dart';
import 'shared/services/crash_reporting_service.dart';
import 'shared/services/performance_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await _initializeApp();
  } catch (e) {
    debugPrint('Error initializing app: $e');
    runApp(ErrorApp(error: e.toString()));
    return;
  }
}

Future<void> _initializeApp() async {
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await dotenv.load(fileName: '.env', isOptional: true);

  await Hive.initFlutter();

  if (Env.supabaseUrl.isNotEmpty && Env.supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
  }

  await AuthService.instance.initialize();

  await caregiver_notifications.NotificationService.instance.initialize();
  await chat_notifications.NotificationService().initialize(userType: 'general');

  final voiceService = VoiceService();
  await voiceService.initialize();

  final prefs = await SharedPreferences.getInstance();

  final userTypeProvider = UserTypeProvider();
  await userTypeProvider.load();

  PerformanceService.instance.initialize();
  AnalyticsService.instance.initialize();
  CrashReportingService.instance.initialize();

  runApp(FamilyBridgeApp(
    prefs: prefs,
    voiceService: voiceService,
    userTypeProvider: userTypeProvider,
  ));
}

class FamilyBridgeApp extends StatelessWidget {
  final SharedPreferences prefs;
  final VoiceService voiceService;
  final UserTypeProvider userTypeProvider;

  const FamilyBridgeApp({
    super.key,
    required this.prefs,
    required this.voiceService,
    required this.userTypeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: voiceService),
        Provider.value(value: prefs),
        
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider.value(value: userTypeProvider),
        
        ChangeNotifierProvider(create: (_) => FamilyDataProvider()),
        ChangeNotifierProvider(create: (_) => HealthMonitoringProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentsProvider()),
        ChangeNotifierProvider(create: (_) => AlertProvider()),
        ChangeNotifierProvider(create: (_) => ElderProvider()),
        ChangeNotifierProvider(create: (_) => YouthProvider()),
        ChangeNotifierProvider(create: (_) => GamesProvider()),
        ChangeNotifierProvider(create: (_) => PhotoSharingProvider()),
        ChangeNotifierProvider(create: (_) => StoryRecordingProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => HipaaComplianceProvider()),
        
        Provider(create: (_) => DataSyncService()),
        Provider(create: (_) => OfflineManager()),
        Provider(create: (_) => NetworkManager()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final router = AppRouter(userTypeProvider).router;
          
          return MaterialApp.router(
            title: 'FamilyBridge',
            debugShowCheckedModeBanner: false,
            theme: _getTheme(authProvider),
            darkTheme: AppTheme.darkTheme,
            routerConfig: router,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(_getTextScaleFactor(authProvider)),
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
    
    if (profile?.role == UserRole.elder || 
        profile?.accessibility.largeText == true ||
        profile?.accessibility.highContrast == true) {
      return AppTheme.elderTheme;
    }
    
    if (profile?.role == UserRole.youth) {
      return AppTheme.youthTheme;
    }
    
    return AppTheme.lightTheme;
  }

  double _getTextScaleFactor(AuthProvider authProvider) {
    final profile = authProvider.profile;
    
    if (profile?.accessibility.largeText == true) {
      return 1.3;
    } else if (profile?.accessibility.extraLargeText == true) {
      return 1.5;
    }
    
    return 1.0;
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FamilyBridge - Error',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
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
                  'Failed to Start',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => SystemNavigator.pop(),
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Restart App'),
                  style: ElevatedButton.styleFrom(
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
}