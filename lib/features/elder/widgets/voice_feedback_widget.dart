import 'package:flutter/material.dart';
import '../../../core/services/voice_service.dart';

class VoiceFeedbackWidget extends StatefulWidget {
  final String message;
  final bool speak;
  final Duration? delay;

  const VoiceFeedbackWidget({
    super.key,
    required this.message,
    this.speak = true,
    this.delay,
  });

  @override
  State<VoiceFeedbackWidget> createState() => _VoiceFeedbackWidgetState();
}

class _VoiceFeedbackWidgetState extends State<VoiceFeedbackWidget> {
  VoiceService? _voice;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _voice ??= VoiceService();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      if (widget.speak) {
        if (widget.delay != null) await Future.delayed(widget.delay!);
        try {
          await VoiceService().speak(widget.message);
        } catch (_) {}
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.message,
      child: const SizedBox.shrink(),
    );
  }
}
