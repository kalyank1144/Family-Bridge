import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import 'package:family_bridge/core/services/storage_service.dart';
import 'package:family_bridge/core/services/voice_service.dart';
import 'package:family_bridge/core/theme/app_theme.dart';
import 'package:family_bridge/features/elder/models/daily_checkin_model.dart';
import 'package:family_bridge/features/elder/providers/elder_provider.dart';
import 'package:family_bridge/features/elder/widgets/elder_image_picker.dart';
import 'package:family_bridge/features/elder/widgets/voice_checkin_widget.dart';
import 'package:family_bridge/services/storage/media_storage_service.dart';

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
  String? _environmentPhotoUrl;
  String? _voiceNoteUrl;
  
  bool _isRecording = false;
  bool _hasRecordedVoiceNote = false;
  bool _isUploadingVoice = false;
  Timer? _recordingTimer;
  int _recordingDuration = 0;
  final ImagePicker _imagePicker = ImagePicker();
  bool _highContrastMode = false;
  
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
      await _voiceService.speak('Let\'s check how you\'re feeling today. You can tap a mood or say how you feel.');
    }
    
    // Register voice commands with better recognition
    _voiceService.registerCommand('happy', () => _setMood('happy'));
    _voiceService.registerCommand('good', () => _setMood('happy'));
    _voiceService.registerCommand('great', () => _setMood('happy'));
    _voiceService.registerCommand('fine', () => _setMood('happy'));
    _voiceService.registerCommand('okay', () => _setMood('okay'));
    _voiceService.registerCommand('alright', () => _setMood('okay'));
    _voiceService.registerCommand('sad', () => _setMood('sad'));
    _voiceService.registerCommand('down', () => _setMood('sad'));
    _voiceService.registerCommand('not good', () => _setMood('sad'));
    _voiceService.registerCommand('record', () => _toggleRecording());
    _voiceService.registerCommand('voice note', () => _toggleRecording());
    _voiceService.registerCommand('take photo', () => _takePhoto());
    _voiceService.registerCommand('camera', () => _takePhoto());
    _voiceService.registerCommand('submit', () => _submitCheckin());
    _voiceService.registerCommand('send', () => _submitCheckin());
    _voiceService.registerCommand('im okay', () => _quickCheckin());
    _voiceService.registerCommand('toggle contrast', () => _toggleHighContrast());
  }

  void _setMood(String mood) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedMood = mood;
    });
    String moodMessage;
    switch (mood) {
      case 'happy':
        moodMessage = 'Great! I\'m glad you\'re feeling good today.';
        break;
      case 'okay':
        moodMessage = 'That\'s alright. Some days are just okay.';
        break;
      case 'sad':
        moodMessage = 'I\'m sorry you\'re feeling down. Would you like to add a note about how you\'re feeling?';
        break;
      default:
        moodMessage = 'Mood recorded.';
    }
    _voiceService.speak(moodMessage);
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
      final path = await _audioRecorder.stop();
      _recordingTimer?.cancel();

      setState(() {
        _isRecording = false;
        _isUploadingVoice = true;
      });

      if (path != null) {
        final elderProvider = context.read<ElderProvider>();
        await _voiceService.speak('Voice note recorded. Uploading now.');
        
        try {
          final uploadedUrl = await StorageService.uploadVoiceNote(
            file: File(path),
            elderId: elderProvider.userId,
          );
          setState(() {
            _voiceNoteUrl = uploadedUrl;
            _hasRecordedVoiceNote = true;
            _isUploadingVoice = false;
          });
          await _voiceService.speak('Voice note saved successfully!');
        } catch (uploadError) {
          // Save locally if upload fails
          setState(() {
            _voiceNoteUrl = path;
            _hasRecordedVoiceNote = true;
            _isUploadingVoice = false;
          });
          await _voiceService.speak('Voice note saved. Will upload when connected.');
        }
      } else {
        setState(() => _isUploadingVoice = false);
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _isUploadingVoice = false;
      });
      await _voiceService.announceError('Could not save voice note. Please try again.');
    }
  }

  Future<void> _submitCheckin() async {
    if (_selectedMood.isEmpty) {
      await _voiceService.announceError('Please select how you\'re feeling');
      return;
    }
    
    final elderProvider = context.read<ElderProvider>();

    // If we have a local voice note path, upload it to Supabase first
    if (_voiceNoteUrl != null && _voiceNoteUrl!.startsWith('/')) {
      try {
        await _voiceService.speak('Uploading voice note');
        final uploaded = await StorageService.uploadVoiceNote(
          file: File(_voiceNoteUrl!),
          elderId: elderProvider.userId,
        );
        if (uploaded != null) {
          _voiceNoteUrl = uploaded;
        }
      } catch (_) {}
    }
    
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

  Future<void> _takePhoto() async {
    try {
      await _voiceService.speak('Opening camera');
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );
      
      if (photo != null) {
        await _voiceService.speak('Photo taken! Uploading now.');
        try {
          final elderProvider = context.read<ElderProvider>();
          final uploadedUrl = await StorageService.uploadVoiceNote(
            file: File(photo.path),
            elderId: elderProvider.userId,
          );
          setState(() {
            _environmentPhotoUrl = uploadedUrl;
          });
          await _voiceService.speak('Photo uploaded successfully!');
        } catch (e) {
          setState(() {
            _environmentPhotoUrl = photo.path;
          });
          await _voiceService.speak('Photo saved. Will upload when connected.');
        }
      }
    } catch (e) {
      await _voiceService.announceError('Could not access camera');
    }
  }
  
  void _toggleHighContrast() {
    setState(() {
      _highContrastMode = !_highContrastMode;
    });
    _voiceService.speak(_highContrastMode ? 'High contrast mode enabled' : 'High contrast mode disabled');
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
    final backgroundColor = _highContrastMode ? Colors.black : Colors.white;
    final textColor = _highContrastMode ? Colors.white : AppTheme.darkText;
    final cardColor = _highContrastMode ? Colors.grey.shade800 : Colors.white;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // High Contrast Toggle
          FloatingActionButton(
            heroTag: 'contrast',
            onPressed: _toggleHighContrast,
            backgroundColor: AppTheme.primaryBlue,
            child: Icon(
              _highContrastMode ? Icons.contrast : Icons.contrast_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          // Camera Button
          if (_environmentPhotoUrl == null)
            FloatingActionButton(
              heroTag: 'camera',
              onPressed: _takePhoto,
              backgroundColor: AppTheme.successGreen,
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Small header text - matching sample
              Text(
                'Elder interface',
                style: TextStyle(
                  fontSize: 16,
                  color: _highContrastMode ? Colors.white60 : AppTheme.neutralGray,
                ),
              ),
              const SizedBox(height: 40),
              
              // Main question - large and prominent
              Text(
                'How are you\nfeeling today?',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: textColor,
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
                    highContrastMode: _highContrastMode,
                  ),
                  _MoodEmoji(
                    emoji: '😐',
                    isSelected: _selectedMood == 'okay',
                    onTap: () => _setMood('okay'),
                    highContrastMode: _highContrastMode,
                  ),
                  _MoodEmoji(
                    emoji: '😔',
                    isSelected: _selectedMood == 'sad',
                    onTap: () => _setMood('sad'),
                    highContrastMode: _highContrastMode,
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
              Container(
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _notesController,
                        onChanged: (value) => _notes = value,
                        decoration: const InputDecoration(
                          hintText: 'Add a note...',
                          hintStyle: TextStyle(
                            fontSize: 20,
                            color: Colors.grey,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(24),
                        ),
                        style: const TextStyle(
                          fontSize: 20,
                          color: AppTheme.darkText,
                        ),
                      ),
                    ),
                    // Microphone button
                    Container(
                      width: 60,
                      height: 60,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: _isRecording ? AppTheme.emergencyRed : 
                               _isUploadingVoice ? AppTheme.warningYellow : 
                               _hasRecordedVoiceNote ? AppTheme.successGreen : AppTheme.darkText,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: IconButton(
                        onPressed: _isUploadingVoice ? null : _toggleRecording,
                        icon: Icon(
                          _isRecording ? Icons.stop : 
                          _isUploadingVoice ? Icons.cloud_upload : 
                          _hasRecordedVoiceNote ? Icons.check : Icons.mic,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
  final bool highContrastMode;

  const _MoodEmoji({
    required this.emoji,
    required this.isSelected,
    required this.onTap,
    this.highContrastMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = isSelected 
        ? (highContrastMode ? Colors.white : Colors.grey.shade200)
        : Colors.transparent;
    final borderColor = isSelected 
        ? (highContrastMode ? Colors.white : AppTheme.darkText)
        : Colors.transparent;
        
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: selectedColor,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 4 : 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(
              fontSize: 48,
              shadows: [
                Shadow(
                  offset: Offset(0.5, 0.5),
                  blurRadius: 1,
                  color: Colors.black12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}