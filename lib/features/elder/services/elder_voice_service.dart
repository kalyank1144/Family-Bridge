import 'package:flutter/material.dart';
import '../../../core/services/voice_service.dart';

class ElderVoiceService {
  final VoiceService _core = VoiceService();

  Future<void> initialize() async {
    await _core.initialize();
    _registerElderDefaults();
  }

  void _registerElderDefaults() {
    _core.registerCommand('home', () => _core.speak('Returning to home'));
    _core.registerCommand('help', () => _core.speak('Help requested. Use emergency button to call.'));
    _core.registerCommand('back', () => _core.speak('Going back'));
  }

  Future<void> announceScreen(String name) async => _core.announceScreen(name);
  Future<void> speak(String text) async => _core.speak(text);
  Future<void> announceError(String error) async => _core.announceError(error);
  void registerCommand(String cmd, VoidCallback cb) => _core.registerCommand(cmd, cb);
  Future<void> startListening({Function(String)? onResult}) async => _core.startListening(onResult: onResult);
  Future<void> stopListening() async => _core.stopListening();
}
