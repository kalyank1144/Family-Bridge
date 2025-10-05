import 'package:flutter/material.dart';

import 'package:audioplayers/audioplayers.dart';

import 'package:family_bridge/core/theme/app_theme.dart';

class VoiceNotePlayer extends StatefulWidget {
  final String urlOrPath;
  final bool isLocal;
  final int? durationSeconds;

  const VoiceNotePlayer({
    super.key,
    required this.urlOrPath,
    this.isLocal = false,
    this.durationSeconds,
  });

  @override
  State<VoiceNotePlayer> createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<VoiceNotePlayer> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((s) {
      setState(() => _isPlaying = s == PlayerState.playing);
    });
    _player.onDurationChanged.listen((d) => setState(() => _duration = d));
    _player.onPositionChanged.listen((p) => setState(() => _position = p));
  }

  Future<void> _toggle() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      if (widget.isLocal) {
        await _player.play(DeviceFileSource(widget.urlOrPath));
      } else {
        await _player.play(UrlSource(widget.urlOrPath));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.durationSeconds != null ? Duration(seconds: widget.durationSeconds!) : _duration;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _toggle,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: total.inMilliseconds == 0 ? 0 : _position.inMilliseconds / total.inMilliseconds,
                  backgroundColor: Colors.grey.shade200,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_format(_position), style: const TextStyle(fontSize: 14, color: Colors.grey)),
                    Text(_format(total), style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  String _format(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
