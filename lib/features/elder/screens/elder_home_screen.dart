import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/elder_provider.dart';
import '../widgets/action_card.dart';
import '../widgets/weather_widget.dart';
import '../widgets/voice_navigation_widget.dart';
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
  bool _isListening = false;
  bool _highContrastMode = false;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    _voiceService = context.read<VoiceService>();
    
    // Load elder data
    final elderProvider = context.read<ElderProvider>();
    await elderProvider.initializeElderData('user_id'); // Replace with actual user ID
    elderProvider.setupRealtimeSubscriptions();
    
    // Load weather data
    await elderProvider.fetchWeatherData();
    
    // Announce screen and welcome
    await _voiceService.announceScreen('Home');
    final userName = elderProvider.currentUser?.name ?? 'there';
    await _voiceService.speak(
      'Welcome back, $userName. You can say "check in" for daily wellness, '
      '"medications" for your medicine reminders, "emergency" for emergency contacts, '
      'or "family" for family messages. You can also tap the microphone to give voice commands.'
    );
  }

  void _navigateToEmergency() async {
    await _voiceService.speak('Opening emergency contacts');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EmergencyContactsScreen()),
    );
  }

  void _navigateToMedication() async {
    await _voiceService.speak('Opening your medications');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MedicationReminderScreen()),
    );
  }

  void _navigateToCheckin() async {
    await _voiceService.speak('Starting daily check-in');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DailyCheckinScreen()),
    );
  }

  void _navigateToFamily() async {
    await _voiceService.speak('Opening family messages');
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

  void _toggleHighContrast() {
    setState(() {
      _highContrastMode = !_highContrastMode;
    });
    _voiceService.speak(_highContrastMode ? 'High contrast mode enabled' : 'High contrast mode disabled');
  }
  
  Map<String, VoidCallback> get _homeScreenCommands => {
    'emergency': _navigateToEmergency,
    'help': _navigateToEmergency,
    'call for help': _navigateToEmergency,
    'medicine': _navigateToMedication,
    'medication': _navigateToMedication,
    'medications': _navigateToMedication,
    'my medicine': _navigateToMedication,
    'pills': _navigateToMedication,
    'family': _navigateToFamily,
    'family messages': _navigateToFamily,
    'chat': _navigateToFamily,
    'messages': _navigateToFamily,
    'check in': _navigateToCheckin,
    'daily check in': _navigateToCheckin,
    'wellness': _navigateToCheckin,
    'how am I feeling': _navigateToCheckin,
    'toggle contrast': _toggleHighContrast,
    'high contrast': _toggleHighContrast,
  };

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _highContrastMode ? Colors.black : Colors.white;
    final textColor = _highContrastMode ? Colors.white : AppTheme.darkText;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: FloatingActionButton(
        heroTag: 'contrast',
        onPressed: _toggleHighContrast,
        backgroundColor: AppTheme.primaryBlue,
        child: Icon(
          _highContrastMode ? Icons.contrast : Icons.contrast_rounded,
          color: Colors.white,
        ),
      ),
      body: Consumer<ElderProvider>(
        builder: (context, elderProvider, child) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  
                  // Large Greeting Header - matching design exactly
                  Text(
                    '${_getGreeting()},',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    elderProvider.currentUser?.name ?? 'Name',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  
                  // Weather Widget
                  if (elderProvider.weatherData != null)
                    WeatherWidget(
                      temperature: elderProvider.weatherData!.temperature,
                      description: elderProvider.weatherData!.description,
                      icon: elderProvider.weatherData!.icon,
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
                          highContrastMode: _highContrastMode,
                        ),
                        const SizedBox(height: 20),
                        
                        // 2. Call for Help Button (Red)
                        _LargeActionButton(
                          title: 'Call for Help',
                          icon: Icons.phone,
                          backgroundColor: AppTheme.emergencyRed,
                          onTap: _navigateToEmergency,
                          highContrastMode: _highContrastMode,
                        ),
                        const SizedBox(height: 20),
                        
                        // 3. My Medications Button (Blue)
                        _LargeActionButton(
                          title: 'My Medications',
                          icon: Icons.medication_outlined,
                          backgroundColor: AppTheme.primaryBlue,
                          onTap: _navigateToMedication,
                          highContrastMode: _highContrastMode,
                        ),
                        const SizedBox(height: 20),
                        
                        // 4. Family Messages Button (Purple)
                        _LargeActionButton(
                          title: 'Family Messages',
                          icon: Icons.chat_bubble_outline,
                          backgroundColor: AppTheme.familyPurple,
                          onTap: _navigateToFamily,
                          highContrastMode: _highContrastMode,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ).withVoiceNavigation(
          screenName: 'Home',
          screenCommands: _homeScreenCommands,
        );
      },
    );
  }
}

class _LargeActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onTap;
  final bool highContrastMode;

  const _LargeActionButton({
    required this.title,
    required this.icon,
    required this.backgroundColor,
    required this.onTap,
    this.highContrastMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final finalBackgroundColor = highContrastMode ? Colors.white : backgroundColor;
    final finalTextColor = highContrastMode ? Colors.black : Colors.white;
    final finalIconBackgroundColor = highContrastMode ? Colors.black : Colors.white;
    final finalIconColor = highContrastMode ? Colors.white : backgroundColor;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact(); // Tactile feedback
        onTap();
      },
      child: Container(
        width: double.infinity,
        height: 100,
        decoration: BoxDecoration(
          color: finalBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: highContrastMode ? Border.all(
            color: backgroundColor,
            width: 3,
          ) : null,
          boxShadow: !highContrastMode ? [
            BoxShadow(
              color: backgroundColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(width: 24),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: finalIconBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: finalIconColor,
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: finalTextColor,
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