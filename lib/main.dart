import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/theme/app_theme.dart';
import 'core/utils/env.dart';
import 'features/chat/screens/family_chat_screen.dart';
import 'features/chat/services/notification_service.dart';

// Caregiver providers
import 'features/caregiver/providers/family_data_provider.dart';
import 'features/caregiver/providers/health_monitoring_provider.dart';
import 'features/caregiver/providers/appointments_provider.dart';
import 'features/caregiver/providers/alert_provider.dart';

// Elder imports
import 'features/elder/providers/elder_provider.dart';
import 'features/elder/screens/elder_home_screen.dart';
import 'core/services/voice_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment (optional, supports --dart-define and .env)
  await dotenv.load(fileName: ".env", isOptional: true);

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  await NotificationService.instance.initialize();

  final prefs = await SharedPreferences.getInstance();

  final voiceService = VoiceService();
  await voiceService.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FamilyDataProvider()),
        ChangeNotifierProvider(create: (_) => HealthMonitoringProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentsProvider()),
        ChangeNotifierProvider(create: (_) => AlertProvider()),
        ChangeNotifierProvider(create: (_) => ElderProvider()),
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
    return MaterialApp(
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

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await NotificationService().initialize(userType: _selectedUserType);
  }

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
}