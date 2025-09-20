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
  
  // Voice command callbacks
  final Map<String, VoidCallback> _commandCallbacks = {};
  
  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  
  Future<void> initialize() async {
    // Request microphone permission
    await Permission.microphone.request();
    
    // Initialize TTS
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.8); // Slower for elderly users
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    // Configure for clear speech
    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.setQueueMode(1);
    
    // Initialize Speech to Text
    bool available = await _speechToText.initialize(
      onError: (error) => debugPrint('Speech recognition error: $error'),
      onStatus: (status) => debugPrint('Speech recognition status: $status'),
    );
    
    if (!available) {
      debugPrint('Speech recognition not available');
    }
    
    // Register default voice commands
    _registerDefaultCommands();
  }
  
  void _registerDefaultCommands() {
    // These will be overridden by specific screens
    registerCommand('help', () => speak('Say help to call for emergency assistance'));
    registerCommand('medicine', () => speak('Say medicine to open medication reminders'));
    registerCommand('family', () => speak('Say family to open family chat'));
    registerCommand('check in', () => speak('Say check in to complete daily wellness check'));
    registerCommand('emergency', () => speak('Calling emergency contact'));
  }
  
  void registerCommand(String command, VoidCallback callback) {
    _commandCallbacks[command.toLowerCase()] = callback;
  }
  
  Future<void> speak(String text, {bool interrupt = true}) async {
    if (interrupt) {
      await _flutterTts.stop();
    }
    await _flutterTts.speak(text);
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
    
    // Check for each registered command
    _commandCallbacks.forEach((command, callback) {
      if (lowercaseWords.contains(command)) {
        callback();
      }
    });
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
  
  void dispose() {
    stopListening();
    stopSpeaking();
  }
}