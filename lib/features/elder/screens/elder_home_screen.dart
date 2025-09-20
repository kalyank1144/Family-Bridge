import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/elder_provider.dart';
import '../widgets/action_card.dart';
import '../widgets/weather_widget.dart';
import 'emergency_contacts_screen.dart';
import 'medication_reminder_screen.dart';
import 'daily_checkin_screen.dart';
import 'family_chat_screen.dart';
import '../../../core/services/voice_service.dart';
import '../../../core/theme/app_theme.dart';

class ElderHomeScreen extends StatefulWidget {
  const ElderHomeScreen({super.key});

  @override
  State<ElderHomeScreen> createState() => _ElderHomeScreenState();
}

class _ElderHomeScreenState extends State<ElderHomeScreen> {
  late VoiceService _voiceService;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    _voiceService = context.read<VoiceService>();
    
    // Announce screen
    await _voiceService.announceScreen('Home');
    
    // Register voice commands
    _voiceService.registerCommand('emergency', () => _navigateToEmergency());
    _voiceService.registerCommand('help', () => _navigateToEmergency());
    _voiceService.registerCommand('medicine', () => _navigateToMedication());
    _voiceService.registerCommand('medication', () => _navigateToMedication());
    _voiceService.registerCommand('family', () => _navigateToFamily());
    _voiceService.registerCommand('chat', () => _navigateToFamily());
    _voiceService.registerCommand('check in', () => _navigateToCheckin());
    _voiceService.registerCommand('wellness', () => _navigateToCheckin());
    
    // Load elder data
    final elderProvider = context.read<ElderProvider>();
    await elderProvider.initializeElderData('user_id'); // Replace with actual user ID
    elderProvider.setupRealtimeSubscriptions();
  }

  void _navigateToEmergency() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()),
    );
  }

  void _navigateToMedication() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MedicationReminderScreen()),
    );
  }

  void _navigateToCheckin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DailyCheckinScreen()),
    );
  }

  void _navigateToFamily() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FamilyChatScreen()),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<ElderProvider>(
          builder: (context, elderProvider, child) {
            return Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  
                  // Large Greeting Header - matching design exactly
                  Text(
                    '${_getGreeting()},',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkText,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Name', // Will be dynamic
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkText,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 60),
                  
                  // Four Main Action Buttons - vertical layout matching design
                  Expanded(
                    child: Column(
                      children: [
                        // 1. I'm OK Today Button (Green)
                        _LargeActionButton(
                          title: "I'm OK Today",
                          icon: Icons.check_circle_outline,
                          backgroundColor: AppTheme.successGreen,
                          onTap: _navigateToCheckin,
                        ),
                        const SizedBox(height: 20),
                        
                        // 2. Call for Help Button (Red)
                        _LargeActionButton(
                          title: 'Call for Help',
                          icon: Icons.phone,
                          backgroundColor: AppTheme.emergencyRed,
                          onTap: _navigateToEmergency,
                        ),
                        const SizedBox(height: 20),
                        
                        // 3. My Medications Button (Blue)
                        _LargeActionButton(
                          title: 'My Medications',
                          icon: Icons.medication_outlined,
                          backgroundColor: AppTheme.primaryBlue,
                          onTap: _navigateToMedication,
                        ),
                        const SizedBox(height: 20),
                        
                        // 4. Family Messages Button (Purple)
                        _LargeActionButton(
                          title: 'Family Messages',
                          icon: Icons.chat_bubble_outline,
                          backgroundColor: AppTheme.familyPurple,
                          onTap: _navigateToFamily,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LargeActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _LargeActionButton({
    required this.title,
    required this.icon,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 100,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(width: 24),
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: backgroundColor,
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}