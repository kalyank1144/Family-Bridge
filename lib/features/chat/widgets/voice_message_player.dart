import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class VoiceMessagePlayer extends StatefulWidget {
  final String audioUrl;
  final int duration;
  final String? transcription;
  final bool isMe;
  final String userType;

  const VoiceMessagePlayer({
    super.key,
    required this.audioUrl,
    required this.duration,
    this.transcription,
    required this.isMe,
    required this.userType,
  });

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  Duration _currentPosition = Duration.zero;
  bool _showTranscription = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() => _playerState = state);
    });
    
    _audioPlayer.onPositionChanged.listen((position) {
      setState(() => _currentPosition = position);
    });
    
    if (widget.userType == 'elder' && !widget.isMe) {
      _autoPlay();
    }
  }

  Future<void> _autoPlay() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _togglePlayPause();
  }

  Future<void> _togglePlayPause() async {
    HapticFeedback.lightImpact();
    
    if (_playerState == PlayerState.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource(widget.audioUrl));
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isElder = widget.userType == 'elder';
    final isPlaying = _playerState == PlayerState.playing;
    
    return Container(
      padding: EdgeInsets.all(isElder ? 12 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isElder ? 48 : 40,
                height: isElder ? 48 : 40,
                decoration: BoxDecoration(
                  color: widget.isMe 
                      ? Colors.white.withOpacity(0.3)
                      : _getAccentColor().withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: widget.isMe ? Colors.white : _getAccentColor(),
                  ),
                  iconSize: isElder ? 28 : 24,
                  onPressed: _togglePlayPause,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWaveform(isPlaying),
                    const SizedBox(height: 4),
                    Text(
                      isPlaying
                          ? _formatDuration(_currentPosition)
                          : _formatDuration(Duration(seconds: widget.duration)),
                      style: TextStyle(
                        fontSize: isElder ? 14 : 12,
                        color: widget.isMe ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.transcription != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                setState(() => _showTranscription = !_showTranscription);
                HapticFeedback.selectionClick();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _showTranscription 
                        ? Icons.expand_less 
                        : Icons.expand_more,
                    size: isElder ? 20 : 16,
                    color: widget.isMe ? Colors.white70 : Colors.black54,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _showTranscription ? 'Hide' : 'Show transcription',
                    style: TextStyle(
                      fontSize: isElder ? 14 : 12,
                      color: widget.isMe ? Colors.white70 : Colors.black54,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'AI',
                      style: TextStyle(
                        fontSize: isElder ? 11 : 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_showTranscription) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.isMe 
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.transcription!,
                  style: TextStyle(
                    fontSize: isElder ? 16 : 14,
                    color: widget.isMe ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildWaveform(bool isPlaying) {
    return SizedBox(
      height: 30,
      width: 150,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(20, (index) {
          final progress = _currentPosition.inMilliseconds / 
                          (widget.duration * 1000);
          final isPassed = index / 20 <= progress;
          
          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 3,
            height: isPassed
                ? 10 + (index % 3) * 10
                : 5 + (index % 3) * 5,
            decoration: BoxDecoration(
              color: widget.isMe
                  ? (isPassed ? Colors.white : Colors.white54)
                  : (isPassed ? _getAccentColor() : Colors.grey),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }

  Color _getAccentColor() {
    switch (widget.userType) {
      case 'elder':
        return Colors.blue;
      case 'caregiver':
        return Colors.teal;
      case 'youth':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}