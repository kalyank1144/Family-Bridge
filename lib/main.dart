import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/theme/app_theme.dart';
import 'core/utils/env.dart';
import 'core/router/app_router.dart';

// Services
import 'core/services/auth_service.dart';
import 'core/services/voice_service.dart';

// Providers (Provider package)
import 'features/auth/providers/auth_provider.dart';
import 'features/caregiver/providers/family_data_provider.dart';
import 'features/caregiver/providers/health_monitoring_provider.dart';
import 'features/caregiver/providers/appointments_provider.dart';
import 'features/caregiver/providers/alert_provider.dart';
import 'features/elder/providers/elder_provider.dart';
import 'features/admin/providers/hipaa_compliance_provider.dart';
import 'features/onboarding/providers/user_type_provider.dart';

// Notifications
import 'features/caregiver/services/notification_service.dart' as caregiver_notifications;
import 'features/chat/services/notification_service.dart' as chat_notifications;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env', isOptional: true);

  if (Env.supabaseUrl.isNotEmpty && Env.supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
  }

  await AuthService.instance.initialize();

  await caregiver_notifications.NotificationService.instance.initialize();
  await chat_notifications.ChatNotificationService().initialize(userType: 'elder');

  final voiceService = VoiceService();
  await voiceService.initialize();

  final userTypeProvider = UserTypeProvider();
  await userTypeProvider.load();

  runApp(
    MultiProvider(
      providers: [
        // Core
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        Provider.value(value: voiceService),

        // Feature providers
        ChangeNotifierProvider(create: (_) => FamilyDataProvider()),
        ChangeNotifierProvider(create: (_) => HealthMonitoringProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentsProvider()),
        ChangeNotifierProvider(create: (_) => AlertProvider()),
        ChangeNotifierProvider(create: (_) => ElderProvider()),
        ChangeNotifierProvider(create: (_) => HipaaComplianceProvider()),

        // Onboarding
        ChangeNotifierProvider<UserTypeProvider>.value(value: userTypeProvider),
      ],
      child: FamilyBridgeApp(userTypeProvider: userTypeProvider, voiceService: voiceService),
    ),
  );
}

class FamilyBridgeApp extends StatelessWidget {
  final UserTypeProvider userTypeProvider;
  final VoiceService voiceService;

  const FamilyBridgeApp({super.key, required this.userTypeProvider, required this.voiceService});

  @override
  Widget build(BuildContext context) {
    final router = AppRouter(userTypeProvider).router;

    return MaterialApp.router(
      title: 'FamilyBridge',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
