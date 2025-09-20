import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'dart:async';
import '../providers/elder_provider.dart';
import '../models/daily_checkin_model.dart';
import '../../../core/services/voice_service.dart';
import '../../../core/theme/app_theme.dart';

class DailyCheckinScreen extends StatefulWidget {
  const DailyCheckinScreen({super.key});

  @override
  State<DailyCheckinScreen> createState() => _DailyCheckinScreenState();
}

class _DailyCheckinScreenState extends State<DailyCheckinScreen> {
  late VoiceService _voiceService;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final TextEditingController _notesController = TextEditingController();
  
  // Check-in data - simplified
  String _selectedMood = '';
  String _notes = '';
  String? _voiceNoteUrl;
  
  bool _isRecording = false;
  Timer? _recordingTimer;
  int _recordingDuration = 0;
  
  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    _voiceService = context.read<VoiceService>();
    await _voiceService.announceScreen('Daily Check-in');
    
    // Check if already completed today
    final elderProvider = context.read<ElderProvider>();
    if (elderProvider.hasCheckedInToday) {
      await _voiceService.speak('You have already completed today\'s check-in');
    } else {
      await _voiceService.speak('Let\'s check how you\'re feeling today');
    }
    
    // Register voice commands
    _voiceService.registerCommand('i feel good', () => _setMood('good'));
    _voiceService.registerCommand('i feel great', () => _setMood('great'));
    _voiceService.registerCommand('i feel okay', () => _setMood('okay'));
    _voiceService.registerCommand('i feel sad', () => _setMood('sad'));
    _voiceService.registerCommand('record note', () => _toggleRecording());
    _voiceService.registerCommand('submit', () => _submitCheckin());
    _voiceService.registerCommand('im okay', () => _quickCheckin());
  }

  void _setMood(String mood) {
    setState(() {
      _selectedMood = mood;
    });
    _voiceService.confirmAction('Mood set to $mood');
  }

  Future<void> _quickCheckin() async {
    setState(() {
      _selectedMood = 'good';
    });
    await _submitCheckin();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        await _audioRecorder.start(
          const RecordConfig(),
          path: '/tmp/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a',
        );
        
        setState(() {
          _isRecording = true;
          _recordingDuration = 0;
        });
        
        _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordingDuration++;
            if (_recordingDuration >= 30) {
              _stopRecording();
            }
          });
        });
        
        await _voiceService.speak('Recording started. Speak your message.');
      }
    } catch (e) {
      await _voiceService.announceError('Could not start recording');
    }
  }

  Future<void> _stopRecording() async {
    try {
      _voiceNoteUrl = await _audioRecorder.stop();
      _recordingTimer?.cancel();
      
      setState(() {
        _isRecording = false;
      });
      
      await _voiceService.confirmAction('Voice note recorded');
    } catch (e) {
      await _voiceService.announceError('Could not stop recording');
    }
  }

  Future<void> _submitCheckin() async {
    if (_selectedMood.isEmpty) {
      await _voiceService.announceError('Please select how you\'re feeling');
      return;
    }
    
    final elderProvider = context.read<ElderProvider>();
    
    final checkin = DailyCheckin(
      elderId: elderProvider.userId,
      mood: _selectedMood,
      sleepQuality: 'good', // Default for simplified version
      mealEaten: true, // Default for simplified version
      medicationTaken: true, // Default for simplified version
      physicalActivity: true, // Default for simplified version
      painLevel: 0, // Default for simplified version
      notes: _notes,
      voiceNoteUrl: _voiceNoteUrl,
    );
    
    await elderProvider.submitDailyCheckin(checkin);
    await _voiceService.confirmAction('Check-in sent to family');
    
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Small header text - matching sample
              const Text(
                'Elder interface',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.neutralGray,
                ),
              ),
              const SizedBox(height: 40),
              
              // Main question - large and prominent
              const Text(
                'How are you\nfeeling today?',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkText,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              
              // Three emoji mood options - matching sample exactly
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _MoodEmoji(
                    emoji: '😊',
                    isSelected: _selectedMood == 'happy',
                    onTap: () => _setMood('happy'),
                  ),
                  _MoodEmoji(
                    emoji: '😐',
                    isSelected: _selectedMood == 'okay',
                    onTap: () => _setMood('okay'),
                  ),
                  _MoodEmoji(
                    emoji: '😔',
                    isSelected: _selectedMood == 'sad',
                    onTap: () => _setMood('sad'),
                  ),
                ],
              ),
              const SizedBox(height: 60),
              
              // I'M OK Button - Green, prominent
              Container(
                width: double.infinity,
                height: 80,
                margin: const EdgeInsets.only(bottom: 40),
                child: ElevatedButton(
                  onPressed: _quickCheckin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'I\'M OK',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              
              // Add a note text input - matching sample
              Container(\n                height: 80,\n                decoration: BoxDecoration(\n                  border: Border.all(color: Colors.grey.shade300, width: 2),\n                  borderRadius: BorderRadius.circular(16),\n                ),\n                child: Row(\n                  children: [\n                    Expanded(\n                      child: TextField(\n                        controller: _notesController,\n                        onChanged: (value) => _notes = value,\n                        decoration: const InputDecoration(\n                          hintText: 'Add a note...',\n                          hintStyle: TextStyle(\n                            fontSize: 20,\n                            color: Colors.grey,\n                          ),\n                          border: InputBorder.none,\n                          contentPadding: EdgeInsets.all(24),\n                        ),\n                        style: const TextStyle(\n                          fontSize: 20,\n                          color: AppTheme.darkText,\n                        ),\n                      ),\n                    ),\n                    // Microphone button\n                    Container(\n                      width: 60,\n                      height: 60,\n                      margin: const EdgeInsets.only(right: 10),\n                      decoration: BoxDecoration(\n                        color: _isRecording ? AppTheme.emergencyRed : AppTheme.darkText,\n                        borderRadius: BorderRadius.circular(30),\n                      ),\n                      child: IconButton(\n                        onPressed: _toggleRecording,\n                        icon: Icon(\n                          _isRecording ? Icons.stop : Icons.mic,\n                          color: Colors.white,\n                          size: 28,\n                        ),\n                      ),\n                    ),\n                  ],\n                ),\n              ),
              const SizedBox(height: 40),
              
              const Spacer(),
              
              // Send to Family button - matching sample
              Container(
                width: double.infinity,
                height: 80,
                child: ElevatedButton(
                  onPressed: _submitCheckin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.darkText,
                    side: const BorderSide(color: AppTheme.darkText, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Send to Family',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodEmoji extends StatelessWidget {
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodEmoji({
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade200 : Colors.transparent,
          borderRadius: BorderRadius.circular(40),
          border: isSelected 
              ? Border.all(color: AppTheme.darkText, width: 3)
              : null,
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 48),
          ),
        ),
      ),
    );
  }
}