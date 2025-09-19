import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import '../providers/story_recording_provider.dart';
import 'waveform_visualizer.dart';

class AudioRecordingWidget extends StatefulWidget {
  final void Function(String path, int seconds) onSend;
  const AudioRecordingWidget({super.key, required this.onSend});

  @override
  State<AudioRecordingWidget> createState() => _AudioRecordingWidgetState();
}

class _AudioRecordingWidgetState extends State<AudioRecordingWidget> {
  final AudioPlayer _player = AudioPlayer();
  bool _hasRecording = false;
  PlayerState _state = PlayerState.stopped;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((s) => setState(() => _state = s));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<StoryRecordingProvider>();
    return Column(
      children: [
        GestureDetector(
          onTap: () async {
            if (!p.isRecording && !_hasRecording) await p.start();
          },
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const SweepGradient(colors: [Color(0xFFFF8A00), Color(0xFF7C3AED), Color(0xFFFF8A00)]),
              boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 24, spreadRadius: 2)],
            ),
            child: Center(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Center(
                  child: Icon(
                    p.isRecording ? Icons.mic : (_hasRecording ? Icons.play_arrow : Icons.mic),
                    color: p.isRecording ? Colors.red : Colors.orange,
                    size: 56,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(p.formattedTime(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        WaveformVisualizer(amplitude: p.isRecording ? p.amplitude : 0.0),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _circleBtn(Icons.replay_10, () async {
              if (_hasRecording && p.path != null) {
                await _player.seek(const Duration(seconds: 0));
              }
            }),
            const SizedBox(width: 16),
            _circleBtn(p.isRecording ? Icons.stop : (_state == PlayerState.playing ? Icons.pause : Icons.play_arrow), () async {
              if (p.isRecording) {
                await p.stop();
                setState(() => _hasRecording = true);
              } else if (_hasRecording && p.path != null) {
                if (_state == PlayerState.playing) {
                  await _player.pause();
                } else {
                  await _player.play(DeviceFileSource(p.path!));
                }
              }
            }, primary: true),
            const SizedBox(width: 16),
            _circleBtn(Icons.forward_10, () async {}),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _hasRecording && p.path != null ? () => widget.onSend(p.path!, p.seconds) : null,
          icon: const Icon(Icons.send),
          label: const Text('Send to Family'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4DA3FF), foregroundColor: Colors.white, minimumSize: const Size(220, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        ),
      ],
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap, {bool primary = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: primary ? const Color(0xFFFF8A00) : Colors.grey.shade200,
          shape: BoxShape.circle,
          boxShadow: [if (primary) BoxShadow(color: const Color(0xFFFF8A00).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        child: Icon(icon, color: primary ? Colors.white : Colors.black87, size: 28),
      ),
    );
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}