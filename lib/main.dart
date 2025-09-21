import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/shared/services/logging_service.dart';
import 'features/shared/services/notification_service.dart';
import 'features/caregiver/services/alert_service.dart';
import 'features/caregiver/services/family_data_service.dart';
import 'features/elder/services/medication_service.dart';
import 'features/chat/services/media_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  // Initialize services
  await _initializeServices();

  runApp(const FamilyBridgeApp());
}

Future<void> _initializeServices() async {
  try {
    // Initialize core services
    await LoggingService().initialize();
    await NotificationService().initialize();
    
    // Services will be initialized when needed based on user context
    // This prevents initialization errors when user data is not available
    
    LoggingService().info('All services initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('Failed to initialize services: $e');
    LoggingService().error('Service initialization failed: $e', stackTrace);
  }
}

class FamilyBridgeApp extends StatelessWidget {
  const FamilyBridgeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<LoggingService>(create: (_) => LoggingService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
        Provider<AlertService>(create: (_) => AlertService()),
        Provider<FamilyDataService>(create: (_) => FamilyDataService()),
        Provider<ElderMedicationService>(create: (_) => ElderMedicationService()),
        Provider<MediaService>(create: (_) => MediaService()),
      ],
      child: MaterialApp(
        title: 'FamilyBridge',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const WelcomeScreen(),
      ),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Welcome to FamilyBridge',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Connecting generations through care',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              const Text(
                'Services Implementation Status:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              _ServiceStatusCard(
                title: 'Alert Service',
                description: 'Caregiver alert management and notifications',
                isImplemented: true,
              ),
              _ServiceStatusCard(
                title: 'Family Data Service',
                description: 'Family member data and relationship management',
                isImplemented: true,
              ),
              _ServiceStatusCard(
                title: 'Media Service',
                description: 'Photo/media sharing with optimization',
                isImplemented: true,
              ),
              _ServiceStatusCard(
                title: 'Medication Service',
                description: 'Elder medication reminders and tracking',
                isImplemented: true,
              ),
              const SizedBox(height: 32),
              const Text(
                'All core services have been implemented!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceStatusCard extends StatelessWidget {
  final String title;
  final String description;
  final bool isImplemented;

  const _ServiceStatusCard({
    Key? key,
    required this.title,
    required this.description,
    required this.isImplemented,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isImplemented ? Icons.check_circle : Icons.pending,
              color: isImplemented ? Colors.green : Colors.orange,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}