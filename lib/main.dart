import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/chat/screens/family_chat_screen.dart';
import 'features/chat/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  
  runApp(
    const ProviderScope(
      child: FamilyBridgeApp(),
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
    await NotificationService().initialize(userType: _selectedUserType);
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