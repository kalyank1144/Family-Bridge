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

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer>
    with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  PlayerState _playerState = PlayerState.stopped;
  Duration _currentPosition = Duration.zero;
  bool _showTranscription = false;
  late AnimationController _waveformController;

  @override
  void initState() {
    super.initState();
    _waveformController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() => _playerState = state);
      if (state == PlayerState.playing) {
        _waveformController.repeat();
      } else {
        _waveformController.stop();
      }
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
    if (mounted) _togglePlayPause();
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
  void dispose() {
    _audioPlayer.dispose();
    _waveformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isElder = widget.userType == 'elder';
    final isPlaying = _playerState == PlayerState.playing;

    return Container(
      padding: EdgeInsets.all(isElder ? 16 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Voice message header with AI translation badge
          if (widget.transcription != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.isMe ? Colors.white.withOpacity(0.2) : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.isMe ? Colors.white.withOpacity(0.3) : Colors.blue.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: widget.isMe ? Colors.white.withOpacity(0.3) : Colors.blue.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              'AI',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: widget.isMe ? Colors.white : Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Translated',
                          style: TextStyle(
                            fontSize: isElder ? 12 : 11,
                            fontWeight: FontWeight.w600,
                            color: widget.isMe ? Colors.white.withOpacity(0.9) : Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Voice player controls
          Row(
            children: [
              // Play/Pause button
              Container(
                width: isElder ? 48 : 44,
                height: isElder ? 48 : 44,
                decoration: BoxDecoration(
                  color: widget.isMe
                      ? Colors.white.withOpacity(0.2)
                      : _getAccentColor().withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.isMe
                        ? Colors.white.withOpacity(0.3)
                        : _getAccentColor().withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: widget.isMe ? Colors.white : _getAccentColor(),
                  ),
                  iconSize: isElder ? 28 : 24,
                  onPressed: _togglePlayPause,
                ),
              ),
              const SizedBox(width: 12),

              // Waveform and duration
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAdvancedWaveform(isPlaying),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_currentPosition),
                          style: TextStyle(
                            fontSize: isElder ? 13 : 11,
                            fontWeight: FontWeight.w500,
                            color: widget.isMe ? Colors.white.withOpacity(0.8) : Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          _formatDuration(Duration(seconds: widget.duration)),
                          style: TextStyle(
                            fontSize: isElder ? 13 : 11,
                            color: widget.isMe ? Colors.white.withOpacity(0.7) : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Transcription section
          if (widget.transcription != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.isMe
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: widget.isMe
                      ? Colors.white.withOpacity(0.2)
                      : Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: widget.userType == 'elder' ? 22 : 18,
                          color: widget.isMe ? Colors.white.withOpacity(0.8) : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _showTranscription ? 'Hide transcript' : 'Show transcript',
                          style: TextStyle(
                            fontSize: widget.userType == 'elder' ? 14 : 12,
                            fontWeight: FontWeight.w500,
                            color: widget.isMe ? Colors.white.withOpacity(0.8) : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_showTranscription) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.transcription!,
                      style: TextStyle(
                        fontSize: widget.userType == 'elder' ? 16 : 14,
                        height: 1.4,
                        color: widget.isMe ? Colors.white.withOpacity(0.9) : Colors.black87,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdvancedWaveform(bool isPlaying) {
    final waveformBars = _generateWaveformBars();
    final progress = widget.duration > 0
        ? _currentPosition.inMilliseconds / (widget.duration * 1000)
        : 0.0;

    return AnimatedBuilder(
      animation: _waveformController,
      builder: (context, child) {
        return Container(
          height: 32,
          child: Row(
            children: List.generate(waveformBars.length, (index) {
              final isActive = index < (waveformBars.length * progress);
              final animatedHeight = isPlaying && isActive
                  ? waveformBars[index] * 32 * (0.7 + 0.3 * _waveformController.value)
                  : waveformBars[index] * 32;

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: isPlaying ? 100 : 300),
                    height: animatedHeight,
                    decoration: BoxDecoration(
                      color: isActive
                          ? (widget.isMe ? Colors.white : _getAccentColor())
                          : (widget.isMe
                              ? Colors.white.withOpacity(0.4)
                              : _getAccentColor().withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  List<double> _generateWaveformBars() {
    // Generate realistic waveform data based on voice message
    // This would typically come from audio analysis in a real app
    return [
      0.1, 0.3, 0.2, 0.6, 0.4, 0.8, 0.5, 0.9, 0.7, 0.4,
      0.6, 0.3, 0.7, 0.5, 0.8, 0.4, 0.6, 0.2, 0.5, 0.3,
      0.7, 0.6, 0.4, 0.8, 0.5, 0.9, 0.3, 0.6, 0.4, 0.7,
      0.2, 0.5, 0.8, 0.4, 0.6, 0.3, 0.7, 0.5, 0.4, 0.2,
      0.6, 0.8, 0.3, 0.5, 0.7, 0.2, 0.9, 0.4, 0.6, 0.1,
    ];
  }

  Color _getAccentColor() {
    switch (widget.userType) {
      case 'elder':
        return Colors.blue.shade600;
      case 'caregiver':
        return Colors.teal.shade600;
      case 'youth':
        return Colors.purple.shade600;
      default:
        return Colors.blue;
    }
  }
}