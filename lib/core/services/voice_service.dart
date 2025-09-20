import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService {
  final FlutterTts _flutterTts = FlutterTts();
  final SpeechToText _speechToText = SpeechToText();
  
  bool _isListening = false;
  String _lastWords = '';
  Function(String)? _onResult;
  String _currentScreen = '';
  bool _isAnnouncing = false;
  
  // Voice command callbacks with priority levels
  final Map<String, VoidCallback> _globalCommands = {};
  final Map<String, VoidCallback> _screenCommands = {};
  
  // Navigation context for better voice assistance
  String? _previousScreen;
  List<String> _navigationHistory = [];
  
  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  String get currentScreen => _currentScreen;
  bool get isAnnouncing => _isAnnouncing;
  
  Future<void> initialize() async {
    // Request microphone permission
    await Permission.microphone.request();
    
    // Initialize TTS with elder-optimized settings
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.7); // Even slower for better comprehension
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(0.9); // Slightly lower pitch for clarity
    
    // Configure for clear speech
    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.setQueueMode(1);
    
    // Initialize Speech to Text with elder-optimized settings
    bool available = await _speechToText.initialize(
      onError: (error) => debugPrint('Speech recognition error: $error'),
      onStatus: (status) => debugPrint('Speech recognition status: $status'),
    );
    
    if (!available) {
      debugPrint('Speech recognition not available');
    }
    
    // Register global voice commands
    _registerGlobalCommands();
  }
  
  void _registerGlobalCommands() {
    // Global navigation commands that work from any screen
    _globalCommands['go home'] = () => _navigateToHome();
    _globalCommands['home'] = () => _navigateToHome();
    _globalCommands['main menu'] = () => _navigateToHome();
    _globalCommands['back'] = () => _navigateBack();
    _globalCommands['go back'] = () => _navigateBack();
    _globalCommands['previous'] = () => _navigateBack();
    
    // Global help commands
    _globalCommands['help'] = () => _provideContextualHelp();
    _globalCommands['what can I say'] = () => _listAvailableCommands();
    _globalCommands['voice commands'] = () => _listAvailableCommands();
    
    // Global accessibility commands
    _globalCommands['repeat'] = () => _repeatLastAnnouncement();
    _globalCommands['say that again'] = () => _repeatLastAnnouncement();
    _globalCommands['speak slower'] = () => _adjustSpeechRate(slower: true);
    _globalCommands['speak faster'] = () => _adjustSpeechRate(slower: false);
    _globalCommands['louder'] = () => _adjustVolume(louder: true);
    _globalCommands['quieter'] = () => _adjustVolume(louder: false);
    
    // Emergency commands (highest priority)
    _globalCommands['emergency'] = () => _handleEmergency();
    _globalCommands['call for help'] = () => _handleEmergency();
    _globalCommands['I need help'] = () => _handleEmergency();
  }
  
  void registerCommand(String command, VoidCallback callback, {bool isGlobal = false}) {
    if (isGlobal) {
      _globalCommands[command.toLowerCase()] = callback;
    } else {
      _screenCommands[command.toLowerCase()] = callback;
    }
  }
  
  void clearScreenCommands() {
    _screenCommands.clear();
  }
  
  void setCurrentScreen(String screenName) {
    if (_currentScreen.isNotEmpty && _currentScreen != screenName) {
      _previousScreen = _currentScreen;
      _navigationHistory.add(_currentScreen);
    }
    _currentScreen = screenName;
    clearScreenCommands(); // Clear previous screen's commands
  }
  
  String _lastSpokenText = '';
  
  Future<void> speak(String text, {bool interrupt = true}) async {
    if (interrupt) {
      await _flutterTts.stop();
    }
    _lastSpokenText = text;
    _isAnnouncing = true;
    await _flutterTts.speak(text);
    _isAnnouncing = false;
  }
  
  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }
  
  Future<void> startListening({
    Function(String)? onResult,
    Duration? listenFor,
  }) async {
    if (!_isListening) {
      bool available = await _speechToText.initialize();
      if (available) {
        _isListening = true;
        _onResult = onResult;
        
        await _speechToText.listen(
          onResult: (result) {
            _lastWords = result.recognizedWords;
            _checkForCommands(_lastWords);
            _onResult?.call(_lastWords);
          },
          listenFor: listenFor ?? const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          partialResults: true,
          localeId: "en_US",
        );
      }
    }
  }
  
  Future<void> stopListening() async {
    if (_isListening) {
      _isListening = false;
      await _speechToText.stop();
    }
  }
  
  void _checkForCommands(String words) {
    final lowercaseWords = words.toLowerCase();
    bool commandFound = false;
    
    // Check global commands first (highest priority)
    for (final command in _globalCommands.keys) {
      if (_matchesCommand(lowercaseWords, command)) {
        _globalCommands[command]!();
        commandFound = true;
        break; // Execute only the first matching command
      }
    }
    
    // If no global command matched, check screen-specific commands
    if (!commandFound) {
      for (final command in _screenCommands.keys) {
        if (_matchesCommand(lowercaseWords, command)) {
          _screenCommands[command]!();
          commandFound = true;
          break;
        }
      }
    }
    
    // If no commands matched, provide helpful feedback
    if (!commandFound && words.isNotEmpty) {
      _handleUnrecognizedCommand(words);
    }
  }
  
  bool _matchesCommand(String spokenText, String command) {
    // Exact match
    if (spokenText.contains(command)) return true;
    
    // Handle partial matches and common variations
    final spokenWords = spokenText.split(' ');
    final commandWords = command.split(' ');
    
    // Check if all command words are present (in any order)
    return commandWords.every((word) => spokenWords.contains(word));
  }
  
  // Announce screen changes for accessibility
  Future<void> announceScreen(String screenName) async {
    await speak('$screenName screen opened', interrupt: true);
  }
  
  // Announce button or action availability
  Future<void> announceAction(String action) async {
    await speak(action, interrupt: false);
  }
  
  // Read out notifications
  Future<void> announceNotification(String notification) async {
    await speak(notification, interrupt: true);
  }
  
  // Confirm actions with voice
  Future<void> confirmAction(String action) async {
    await speak('$action completed', interrupt: false);
  }
  
  // Error announcements
  Future<void> announceError(String error) async {
    await speak('Error: $error', interrupt: true);
  }
  
  // Navigation helper methods
  void _navigateToHome() {
    // This would need to be implemented with a navigation service
    speak('Going to home screen');
    // TODO: Implement actual navigation
  }
  
  void _navigateBack() {
    if (_previousScreen != null) {
      speak('Going back to ${_previousScreen}');
      // TODO: Implement actual navigation back
    } else {
      speak('Already at the main screen');
    }
  }
  
  // Help and assistance methods
  void _provideContextualHelp() {
    String helpMessage = 'You are on the $_currentScreen screen. ';
    
    switch (_currentScreen.toLowerCase()) {
      case 'home':
        helpMessage += 'You can say "check in" for daily wellness, "medications" for your medicine reminders, "emergency" for emergency contacts, or "family" for family messages.';
        break;
      case 'daily check-in':
      case 'daily wellness':
        helpMessage += 'You can say "happy", "okay", or "sad" to set your mood. Say "take photo" to capture a photo, "record" to add a voice note, or "send" to submit your check-in.';
        break;
      case 'medication reminders':
      case 'medications':
        helpMessage += 'You can say "take now" to mark medication as taken, "take photo" for photo confirmation, or "back" to return home.';
        break;
      case 'emergency contacts':
        helpMessage += 'You can say "call" followed by a contact name, "emergency" for 911, "location" to share your location, or "photo" to take an emergency photo.';
        break;
      default:
        helpMessage += 'You can say "home" to go to the main screen, "help" for assistance, or "back" to go to the previous screen.';
    }
    
    speak(helpMessage);
  }
  
  void _listAvailableCommands() {
    List<String> commands = [];
    
    // Add global commands
    commands.addAll(['home', 'back', 'help', 'repeat', 'emergency']);
    
    // Add screen-specific commands
    commands.addAll(_screenCommands.keys);
    
    if (commands.isNotEmpty) {
      speak('Available voice commands: ${commands.take(8).join(', ')}. Say "help" for more specific guidance.');
    } else {
      speak('Say "home" to go to the main screen, "help" for guidance, or "emergency" if you need immediate assistance.');
    }
  }
  
  void _handleUnrecognizedCommand(String spokenText) {
    // Provide helpful suggestions based on what was said
    final suggestions = <String>[];
    
    if (spokenText.contains('medicine') || spokenText.contains('medication') || spokenText.contains('pill')) {
      suggestions.add('medications');
    }
    if (spokenText.contains('family') || spokenText.contains('chat') || spokenText.contains('message')) {
      suggestions.add('family');
    }
    if (spokenText.contains('check') || spokenText.contains('wellness') || spokenText.contains('feeling')) {
      suggestions.add('check in');
    }
    if (spokenText.contains('help') || spokenText.contains('emergency')) {
      suggestions.add('emergency');
    }
    
    if (suggestions.isNotEmpty) {
      speak('I think you meant to say: ${suggestions.first}. Try saying that.');
    } else {
      speak('I didn\'t understand that. Say "help" to hear what you can say, or "home" to go to the main screen.');
    }
  }
  
  // Accessibility adjustment methods
  void _repeatLastAnnouncement() {
    if (_lastSpokenText.isNotEmpty) {
      speak(_lastSpokenText);
    } else {
      speak('Nothing to repeat.');
    }
  }
  
  Future<void> _adjustSpeechRate({required bool slower}) async {
    double currentRate = await _flutterTts.getSpeechRate ?? 0.7;
    double newRate = slower ? (currentRate - 0.1) : (currentRate + 0.1);
    newRate = newRate.clamp(0.3, 1.5);
    
    await _flutterTts.setSpeechRate(newRate);
    speak(slower ? 'Speech slowed down' : 'Speech speeded up');
  }
  
  Future<void> _adjustVolume({required bool louder}) async {
    double currentVolume = await _flutterTts.getVolume ?? 1.0;
    double newVolume = louder ? (currentVolume + 0.2) : (currentVolume - 0.2);
    newVolume = newVolume.clamp(0.1, 1.0);
    
    await _flutterTts.setVolume(newVolume);
    speak(louder ? 'Volume increased' : 'Volume decreased');
  }
  
  void _handleEmergency() {
    speak('Opening emergency contacts. Say "call 911" for immediate emergency assistance.');
    // TODO: Navigate to emergency screen or call emergency services
  }
  
  void dispose() {
    stopListening();
    stopSpeaking();
  }
}