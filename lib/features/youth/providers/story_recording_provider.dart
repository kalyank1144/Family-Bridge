import 'dart:async';

import 'package:flutter/material.dart';

import 'package:family_bridge/core/services/audio_service.dart';

class StoryRecordingProvider extends ChangeNotifier {
  final AudioService _audio = AudioService();
  StreamSubscription<double>? _ampSub;

  double _amplitude = 0;
  int _seconds = 0;
  String? _path;
  bool _isRecording = false;

  double get amplitude => _amplitude;
  int get seconds => _seconds;
  String? get path => _path;
  bool get isRecording => _isRecording;

  List<String> get prompts => [
        'Tell about your day',
        'Share a memory',
        'Ask a question',
      ];

  Future<void> start() async {
    await _audio.start();
    _isRecording = true;
    _seconds = 0;
    _ampSub?.cancel();
    _ampSub = _audio.amplitudeStream.listen((v) {
      _amplitude = v;
      _seconds = _audio.seconds;
      notifyListeners();
    });
    notifyListeners();
  }

  Future<void> stop() async {
    _path = await _audio.stop();
    _isRecording = false;
    notifyListeners();
  }

  Future<void> cancel() async {
    await _audio.cancel();
    _isRecording = false;
    _path = null;
    _seconds = 0;
    notifyListeners();
  }

  String formattedTime() {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString()}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _ampSub?.cancel();
    super.dispose();
  }
}