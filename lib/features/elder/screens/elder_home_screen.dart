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
      backgroundColor: AppTheme.lightBackground,
      body: SafeArea(
        child: Consumer<ElderProvider>(
          builder: (context, elderProvider, child) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting Section
                    Text(
                      '${_getGreeting()},',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    Text(
                      elderProvider.userName,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Date and Weather
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('EEEE').format(DateTime.now()),
                                style: Theme.of(context).textTheme.headlineMedium,
                              ),
                              Text(
                                DateFormat('MMMM d, yyyy').format(DateTime.now()),
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppTheme.neutralGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                        WeatherWidget(
                          temperature: elderProvider.temperature,
                          description: elderProvider.weatherDescription,
                          icon: elderProvider.weatherIcon,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Quick Status Button
                    if (!elderProvider.hasCheckedInToday)
                      GestureDetector(
                        onTap: () {
                          _voiceService.speak('You haven\'t checked in today. Tap to complete your daily check-in.');
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.successGreen,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                size: 36,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'I\'m OK Today',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    
                    // Action Cards Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.1,
                      children: [
                        ActionCard(
                          title: 'Emergency\nContacts',
                          icon: Icons.phone,
                          color: AppTheme.emergencyRed,
                          subtitle: 'Call for Help',
                          onTap: _navigateToEmergency,
                          isUrgent: true,
                        ),
                        ActionCard(
                          title: 'My\nMedications',
                          icon: Icons.medication,
                          color: AppTheme.primaryBlue,
                          subtitle: elderProvider.nextMedication != null
                              ? elderProvider.nextMedication!.getTimeUntilNext()
                              : 'View Schedule',
                          onTap: _navigateToMedication,
                          badge: elderProvider.nextMedication?.isDue() == true ? '!' : null,
                        ),
                        ActionCard(
                          title: 'Daily\nCheck-in',
                          icon: Icons.favorite,
                          color: elderProvider.hasCheckedInToday
                              ? AppTheme.successGreen
                              : AppTheme.warningYellow,
                          subtitle: elderProvider.hasCheckedInToday
                              ? 'Completed ✓'
                              : 'Not Done',
                          onTap: _navigateToCheckin,
                        ),
                        ActionCard(
                          title: 'Family\nMessages',
                          icon: Icons.chat_bubble,
                          color: Colors.purple,
                          subtitle: elderProvider.unreadMessages > 0
                              ? '${elderProvider.unreadMessages} New'
                              : 'Stay Connected',
                          onTap: _navigateToFamily,
                          badge: elderProvider.unreadMessages > 0
                              ? elderProvider.unreadMessages.toString()
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Recent Activities
                    if (elderProvider.todayCheckin != null) ...[
                      Text(
                        'Today\'s Wellness',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Text(
                              elderProvider.todayCheckin!.getMoodEmoji(),
                              style: const TextStyle(fontSize: 48),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Feeling ${elderProvider.todayCheckin!.mood}',
                                    style: Theme.of(context).textTheme.headlineSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Wellness Score: ${elderProvider.todayCheckin!.getWellnessScore()}/100',
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: AppTheme.neutralGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          switch (index) {
            case 0:
              _voiceService.announceScreen('Home');
              break;
            case 1:
              _navigateToMedication();
              break;
            case 2:
              _navigateToFamily();
              break;
            case 3:
              _voiceService.speak('Opening settings');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medication),
            label: 'Medicine',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Family',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_voiceService.isListening) {
            await _voiceService.stopListening();
          } else {
            await _voiceService.startListening(
              onResult: (words) {
                print('Voice input: $words');
              },
            );
          }
          setState(() {});
        },
        backgroundColor: _voiceService.isListening
            ? AppTheme.emergencyRed
            : AppTheme.primaryBlue,
        child: Icon(
          _voiceService.isListening ? Icons.mic : Icons.mic_none,
          size: 32,
        ),
      ),
    );
  }
}