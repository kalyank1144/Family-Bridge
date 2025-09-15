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
  
  // Check-in data
  String _selectedMood = '';
  String _sleepQuality = '';
  bool _mealEaten = false;
  bool _medicationTaken = false;
  bool _physicalActivity = false;
  int _painLevel = 0;
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
      _sleepQuality = 'good';
      _mealEaten = true;
      _medicationTaken = true;
      _physicalActivity = true;
      _painLevel = 0;
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
      sleepQuality: _sleepQuality.isEmpty ? 'fair' : _sleepQuality,
      mealEaten: _mealEaten,
      medicationTaken: _medicationTaken,
      physicalActivity: _physicalActivity,
      painLevel: _painLevel,
      notes: _notes,
      voiceNoteUrl: _voiceNoteUrl,
    );
    
    await elderProvider.submitDailyCheckin(checkin);
    await _voiceService.confirmAction('Check-in submitted');
    
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Daily Check-in'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quick OK Button
              GestureDetector(
                onTap: _quickCheckin,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.successGreen,
                        AppTheme.successGreen.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'I\'M OK',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap for quick check-in',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Or Divider
              Row(
                children: [
                  Expanded(child: Divider(color: AppTheme.neutralGray)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR COMPLETE FULL CHECK-IN',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.neutralGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: AppTheme.neutralGray)),
                ],
              ),
              const SizedBox(height: 32),
              
              // Mood Selection
              Text(
                'How are you feeling today?',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _MoodOption(
                    emoji: '😊',
                    label: 'Great',
                    isSelected: _selectedMood == 'great',
                    onTap: () => setState(() => _selectedMood = 'great'),
                  ),
                  _MoodOption(
                    emoji: '🙂',
                    label: 'Good',
                    isSelected: _selectedMood == 'good',
                    onTap: () => setState(() => _selectedMood = 'good'),
                  ),
                  _MoodOption(
                    emoji: '😐',
                    label: 'Okay',
                    isSelected: _selectedMood == 'okay',
                    onTap: () => setState(() => _selectedMood = 'okay'),
                  ),
                  _MoodOption(
                    emoji: '😔',
                    label: 'Not Good',
                    isSelected: _selectedMood == 'not good',
                    onTap: () => setState(() => _selectedMood = 'not good'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Sleep Quality
              Text(
                'How did you sleep?',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: [
                  _QualityChip(
                    label: 'Great',
                    isSelected: _sleepQuality == 'great',
                    onTap: () => setState(() => _sleepQuality = 'great'),
                  ),
                  _QualityChip(
                    label: 'Good',
                    isSelected: _sleepQuality == 'good',
                    onTap: () => setState(() => _sleepQuality = 'good'),
                  ),
                  _QualityChip(
                    label: 'Fair',
                    isSelected: _sleepQuality == 'fair',
                    onTap: () => setState(() => _sleepQuality = 'fair'),
                  ),
                  _QualityChip(
                    label: 'Poor',
                    isSelected: _sleepQuality == 'poor',
                    onTap: () => setState(() => _sleepQuality = 'poor'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Yes/No Questions
              _YesNoQuestion(
                question: 'Did you eat your meals?',
                value: _mealEaten,
                onChanged: (value) => setState(() => _mealEaten = value),
                icon: Icons.restaurant,
              ),
              _YesNoQuestion(
                question: 'Did you take your medications?',
                value: _medicationTaken,
                onChanged: (value) => setState(() => _medicationTaken = value),
                icon: Icons.medication,
              ),
              _YesNoQuestion(
                question: 'Did you do any physical activity?',
                value: _physicalActivity,
                onChanged: (value) => setState(() => _physicalActivity = value),
                icon: Icons.directions_walk,
              ),
              const SizedBox(height: 32),
              
              // Pain Level
              Text(
                'Any pain today?',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return GestureDetector(
                    onTap: () => setState(() => _painLevel = index),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _painLevel == index
                            ? (index == 0 ? AppTheme.successGreen : 
                               index < 3 ? AppTheme.warningYellow :
                               AppTheme.emergencyRed)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _painLevel == index
                              ? Colors.black
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          index.toString(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _painLevel == index
                                ? Colors.white
                                : AppTheme.darkText,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _painLevel == 0 ? 'No Pain' :
                  _painLevel < 3 ? 'Mild Pain' :
                  _painLevel < 5 ? 'Moderate Pain' : 'Severe Pain',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppTheme.neutralGray,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Notes Section
              Text(
                'Add a note (optional)',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => _notes = value,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'How are you feeling? Any concerns?',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.mic, size: 28),
                    onPressed: () {
                      _voiceService.startListening(
                        onResult: (words) {
                          setState(() {
                            _notes = words;
                          });
                        },
                      );
                    },
                  ),
                ),
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 20),
              
              // Voice Note
              GestureDetector(
                onTap: _toggleRecording,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _isRecording
                        ? AppTheme.emergencyRed.withOpacity(0.1)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isRecording
                          ? AppTheme.emergencyRed
                          : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        size: 32,
                        color: _isRecording
                            ? AppTheme.emergencyRed
                            : AppTheme.darkText,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        _isRecording
                            ? 'Recording... $_recordingDuration/30s'
                            : _voiceNoteUrl != null
                                ? 'Voice note recorded ✓'
                                : 'Record voice note',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: _isRecording
                              ? AppTheme.emergencyRed
                              : AppTheme.darkText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              // Submit Button
              ElevatedButton(
                onPressed: _submitCheckin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                ),
                child: const Text(
                  'Send to Family',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodOption extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodOption({
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryBlue.withOpacity(0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: isSelected
                    ? AppTheme.primaryBlue
                    : Colors.transparent,
                width: 3,
              ),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 36),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? AppTheme.primaryBlue
                  : AppTheme.neutralGray,
            ),
          ),
        ],
      ),
    );
  }
}

class _QualityChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _QualityChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryBlue
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppTheme.darkText,
          ),
        ),
      ),
    );
  }
}

class _YesNoQuestion extends StatelessWidget {
  final String question;
  final bool value;
  final Function(bool) onChanged;
  final IconData icon;

  const _YesNoQuestion({
    required this.question,
    required this.value,
    required this.onChanged,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? AppTheme.successGreen : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: AppTheme.primaryBlue),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              question,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => onChanged(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: value
                        ? AppTheme.successGreen
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Yes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: value ? Colors.white : AppTheme.darkText,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => onChanged(false),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: !value
                        ? AppTheme.emergencyRed
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'No',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: !value ? Colors.white : AppTheme.darkText,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}