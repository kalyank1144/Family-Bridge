import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/utils/env.dart';
import 'features/caregiver/providers/family_data_provider.dart';
import 'features/caregiver/providers/health_monitoring_provider.dart';
import 'features/caregiver/providers/appointments_provider.dart';
import 'features/caregiver/providers/alert_provider.dart';
import 'features/caregiver/services/notification_service.dart';
import 'features/elder/providers/elder_provider.dart';
import 'core/services/voice_service.dart';
import 'features/chat/screens/family_chat_screen.dart';

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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        fontFamily: 'SF Pro Display',
      ),
      home: const ChatDemoScreen(),
    );
  }
}

class ChatDemoScreen extends StatefulWidget {
  const ChatDemoScreen({super.key});

  @override
  State<ChatDemoScreen> createState() => _ChatDemoScreenState();
}

class _ChatDemoScreenState extends State<ChatDemoScreen> {
  String _selectedUserType = 'elder';
  final _familyId = 'demo-family-123';
  final _userId = 'demo-user-456';

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await NotificationService.instance.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FamilyBridge Chat Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select User Type:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'elder',
                      label: Text('Elder'),
                      icon: Icon(Icons.elderly),
                    ),
                    ButtonSegment(
                      value: 'caregiver',
                      label: Text('Caregiver'),
                      icon: Icon(Icons.medical_services),
                    ),
                    ButtonSegment(
                      value: 'youth',
                      label: Text('Youth'),
                      icon: Icon(Icons.school),
                    ),
                  ],
                  selected: {_selectedUserType},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _selectedUserType = newSelection.first;
                    });
                    _initializeNotifications();
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
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
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('Open Family Chat'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Features for $_selectedUserType:',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._getFeaturesList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _getFeaturesList() {
    final features = _getFeaturesForUserType();
    return features.map((feature) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: _getColorForUserType(),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    )).toList();
  }

  List<String> _getFeaturesForUserType() {
    switch (_selectedUserType) {
      case 'elder':
        return [
          'Large text display (24px+)',
          'Voice message auto-playback',
          'Preset quick responses',
          'Simplified emoji picker',
          'Voice announcements for urgent messages',
          'Auto-transcription of voice messages',
          'Large record button for easy access',
        ];
      case 'caregiver':
        return [
          'Professional layout design',
          'Message search functionality',
          'Care notes with timestamps',
          'Priority message flagging',
          'Export chat history',
          'Multi-select for task creation',
          '@mentions for family members',
          'Grouped notifications',
        ];
      case 'youth':
        return [
          'Modern chat interface',
          'Message reactions and effects',
          'GIF picker integration',
          'Sticker packs support',
          'Voice filters for recordings',
          'Achievement sharing',
          'Silent during school hours',
        ];
      default:
        return [];
    }
  }

  Color _getColorForUserType() {
    switch (_selectedUserType) {
      case 'elder':
        return Colors.blue;
      case 'caregiver':
        return Colors.teal;
      case 'youth':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}