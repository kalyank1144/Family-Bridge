import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/utils/env.dart';

// Caregiver state
import 'features/caregiver/providers/family_data_provider.dart';
import 'features/caregiver/providers/health_monitoring_provider.dart';
import 'features/caregiver/providers/appointments_provider.dart';
import 'features/caregiver/providers/alert_provider.dart';
import 'features/caregiver/services/notification_service.dart' as caregiver_notifications;

// Elder + Voice
import 'features/elder/providers/elder_provider.dart';
import 'core/services/voice_service.dart';

// Onboarding state
import 'features/onboarding/providers/user_type_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env', isOptional: true);

  if (Env.supabaseUrl.isNotEmpty && Env.supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
  }

  await caregiver_notifications.NotificationService.instance.initialize();

  final voiceService = VoiceService();
  await voiceService.initialize();

  final userTypeProvider = UserTypeProvider();
  await userTypeProvider.load();

  runApp(
    ProviderScope(
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider<FamilyDataProvider>(create: (_) => FamilyDataProvider()),
          ChangeNotifierProvider<HealthMonitoringProvider>(create: (_) => HealthMonitoringProvider()),
          ChangeNotifierProvider<AppointmentsProvider>(create: (_) => AppointmentsProvider()),
          ChangeNotifierProvider<AlertProvider>(create: (_) => AlertProvider()),
          ChangeNotifierProvider<ElderProvider>(create: (_) => ElderProvider()),
          ChangeNotifierProvider<UserTypeProvider>.value(value: userTypeProvider),
          Provider<VoiceService>.value(value: voiceService),
        ],
        child: FamilyBridgeApp(userTypeProvider: userTypeProvider),
      ),
    ),
  );
}

class FamilyBridgeApp extends StatelessWidget {
  final UserTypeProvider userTypeProvider;
  const FamilyBridgeApp({super.key, required this.userTypeProvider});

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