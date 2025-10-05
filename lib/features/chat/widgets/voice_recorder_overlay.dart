import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceRecorderOverlay extends StatefulWidget {
  final String userType;
  final VoidCallback onCancel;
  final Function(String audioPath, int duration, String? transcription) onSend;

  const VoiceRecorderOverlay({
    super.key,
    required this.userType,
    required this.onCancel,
    required this.onSend,
  });

  @override
  State<VoiceRecorderOverlay> createState() => _VoiceRecorderOverlayState();
}

class _VoiceRecorderOverlayState extends State<VoiceRecorderOverlay> {
  final AudioRecorder _recorder = AudioRecorder();
  final SpeechToText _speechToText = SpeechToText();
  
  Timer? _timer;
  int _recordDuration = 0;
  String? _audioPath;
  String _transcription = '';
  bool _isRecording = false;
  bool _isTranscribing = false;
  double _amplitude = 0.0;

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        _audioPath = '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _recorder.start(
          const RecordConfig(),
          path: _audioPath!,
        );
        
        setState(() => _isRecording = true);
        
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() => _recordDuration++);
          _updateAmplitude();
        });
        
        if (widget.userType == 'elder') {
          _startTranscription();
        }
        
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
      widget.onCancel();
    }
  }

  Future<void> _updateAmplitude() async {
    final amplitude = await _recorder.getAmplitude();
    setState(() {
      _amplitude = (amplitude.current + 40) / 40;
      _amplitude = _amplitude.clamp(0.0, 1.0);
    });
  }

  Future<void> _startTranscription() async {
    if (await _speechToText.initialize()) {
      setState(() => _isTranscribing = true);
      
      _speechToText.listen(
        onResult: (result) {
          setState(() {
            _transcription = result.recognizedWords;
          });
        },
        listenFor: const Duration(minutes: 2),
        pauseFor: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    
    final path = await _recorder.stop();
    _timer?.cancel();
    _speechToText.stop();
    
    setState(() {
      _isRecording = false;
      _isTranscribing = false;
    });
    
    if (path != null) {
      widget.onSend(path, _recordDuration, _transcription.isNotEmpty ? _transcription : null);
    }
    
    HapticFeedback.mediumImpact();
  }

  void _cancelRecording() {
    _recorder.stop();
    _timer?.cancel();
    _speechToText.stop();
    widget.onCancel();
    HapticFeedback.lightImpact();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isElder = widget.userType == 'elder';
    
    return Container(
      color: Colors.black87,
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            _buildWaveform(),
            const SizedBox(height: 32),
            Text(
              _formatDuration(_recordDuration),
              style: TextStyle(
                color: Colors.white,
                fontSize: isElder ? 48 : 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (_transcription.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.mic,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Live Transcription',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: isElder ? 14 : 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _transcription,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isElder ? 18 : 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ] else
              const SizedBox(height: 100),
            Text(
              _isRecording ? 'Recording...' : 'Ready to send',
              style: TextStyle(
                color: Colors.white70,
                fontSize: isElder ? 20 : 16,
              ),
            ).animate(
              onPlay: (controller) => controller.repeat(),
            ).fadeIn(duration: 500.ms).then().fadeOut(duration: 500.ms),
            const Spacer(),
            _buildControls(isElder),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveform() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(20, (index) {
          final height = 20 + (_amplitude * 60 * (index % 3 == 1 ? 1 : 0.7));
          return Container(
            width: 4,
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(2),
            ),
          ).animate(
            onPlay: (controller) => controller.repeat(),
          ).scaleY(
            begin: 0.5,
            end: 1,
            duration: 300.ms,
            delay: (index * 50).ms,
          );
        }),
      ),
    );
  }

  Widget _buildControls(bool isElder) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Container(
          width: isElder ? 80 : 64,
          height: isElder ? 80 : 64,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.close),
            iconSize: isElder ? 36 : 28,
            color: Colors.white,
            onPressed: _cancelRecording,
          ),
        ),
        GestureDetector(
          onTap: _stopRecording,
          child: Container(
            width: isElder ? 100 : 80,
            height: isElder ? 100 : 80,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              _isRecording ? Icons.stop : Icons.send,
              color: Colors.white,
              size: isElder ? 48 : 36,
            ),
          ).animate(
            onPlay: (controller) => controller.repeat(),
          ).scale(
            begin: const Offset(0.95, 0.95),
            end: const Offset(1.05, 1.05),
            duration: 1.seconds,
          ),
        ),
        Container(
          width: isElder ? 80 : 64,
          height: isElder ? 80 : 64,
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    _speechToText.stop();
    super.dispose();
  }
}