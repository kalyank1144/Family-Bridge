import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/storage/media_storage_service.dart';
import 'voice_note_player.dart';

class VoiceCheckinWidget extends StatefulWidget {
  final void Function(String url)? onUploaded;

  const VoiceCheckinWidget({super.key, this.onUploaded});

  @override
  State<VoiceCheckinWidget> createState() => _VoiceCheckinWidgetState();
}

class _VoiceCheckinWidgetState extends State<VoiceCheckinWidget> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  int _seconds = 0;
  Timer? _timer;
  String? _localPath;
  String? _uploadedUrl;
  double _amplitude = 0;
  bool _isUploading = false;

  Future<void> _start() async {
    if (!await Permission.microphone.request().isGranted) return;
    if (!await _recorder.hasPermission()) return;

    final dir = await getTemporaryDirectory();
    _localPath = '${dir.path}/checkin_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(const RecordConfig(), path: _localPath!);
    setState(() {
      _isRecording = true;
      _seconds = 0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      setState(() => _seconds++);
      final amp = await _recorder.getAmplitude();
      setState(() => _amplitude = (amp.current + 45).clamp(0, 60) / 60);
      if (_seconds >= 60) _stop();
    });
  }

  Future<void> _stop() async {
    final path = await _recorder.stop();
    _timer?.cancel();
    setState(() => _isRecording = false);
    if (path != null) setState(() => _localPath = path);
  }

  Future<void> _upload() async {
    if (_localPath == null) return;
    setState(() => _isUploading = true);
    try {
      final url = await MediaStorageService().uploadFile(
        file: File(_localPath!),
        bucket: MediaStorageService.bucketVoiceNotes,
        contentType: 'audio/m4a',
      );
      setState(() => _uploadedUrl = url);
      widget.onUploaded?.call(url);
    } catch (_) {
      // queued offline
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 100,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(18, (i) {
              final h = 16.0 + (_amplitude * 64) * (i % 3 == 0 ? 1 : 0.7);
              return Container(
                width: 6,
                height: h,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: _isRecording ? AppTheme.emergencyRed : AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            _isRecording ? 'Recording... ${_seconds}s' : (_localPath != null ? 'Recorded ${_seconds}s' : 'Tap to record'),
            style: const TextStyle(fontSize: 18),
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _isRecording ? _stop : _start,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: _isRecording ? AppTheme.emergencyRed : AppTheme.primaryBlue,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_isRecording ? Icons.stop : Icons.mic, color: Colors.white, size: 32),
                const SizedBox(width: 12),
                Text(
                  _isRecording ? 'Stop Recording' : 'Record Voice Note',
                  style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                )
              ],
            ),
          ),
        ),
        if (_localPath != null) ...[
          const SizedBox(height: 12),
          VoiceNotePlayer(urlOrPath: _localPath!, isLocal: true, durationSeconds: _seconds),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isUploading ? null : _upload,
            icon: const Icon(Icons.cloud_upload, color: Colors.white),
            label: Text(
              _uploadedUrl != null ? 'Uploaded ✓' : 'Upload Voice Note',
              style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successGreen,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }
}
