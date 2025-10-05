import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  final StreamController<double> _amplitudeController = StreamController.broadcast();
  Timer? _ampTimer;
  Timer? _durationTimer;
  int _seconds = 0;
  String? _path;
  bool _isRecording = false;

  Stream<double> get amplitudeStream => _amplitudeController.stream;
  int get seconds => _seconds;
  String? get path => _path;
  bool get isRecording => _isRecording;

  Future<bool> requestPermissions() async {
    final statuses = await [Permission.microphone, Permission.storage].request();
    return statuses.values.every((s) => s.isGranted || s.isLimited);
  }

  Future<void> start() async {
    if (_isRecording) return;
    if (!await _recorder.hasPermission()) {
      final ok = await requestPermissions();
      if (!ok) throw Exception('Microphone permission denied');
    }
    final dir = await getTemporaryDirectory();
    _path = '${dir.path}/story_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(), path: _path!);
    _isRecording = true;
    _seconds = 0;
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) => _seconds++);
    _ampTimer?.cancel();
    _ampTimer = Timer.periodic(const Duration(milliseconds: 120), (_) async {
      final amp = await _recorder.getAmplitude();
      final v = ((amp.current + 45) / 45).clamp(0.0, 1.0);
      if (!_amplitudeController.isClosed) _amplitudeController.add(v);
    });
  }

  Future<String?> stop() async {
    if (!_isRecording) return _path;
    final p = await _recorder.stop();
    _isRecording = false;
    _ampTimer?.cancel();
    _durationTimer?.cancel();
    return p ?? _path;
  }

  Future<void> cancel() async {
    if (_isRecording) {
      await _recorder.stop();
    }
    _isRecording = false;
    _ampTimer?.cancel();
    _durationTimer?.cancel();
    _seconds = 0;
    if (_path != null) {
      try {
        final f = File(_path!);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    _path = null;
  }

  void dispose() {
    _ampTimer?.cancel();
    _durationTimer?.cancel();
    _amplitudeController.close();
  }
}