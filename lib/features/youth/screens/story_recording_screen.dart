import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/story_recording_provider.dart';
import '../widgets/audio_recording_widget.dart';
import '../../chat/screens/family_chat_screen.dart';

class StoryRecordingScreen extends StatelessWidget {
  const StoryRecordingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StoryRecordingProvider(),
      child: const _Content(),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<StoryRecordingProvider>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: const Text('Story Time with Grandma', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFFFF3E0), Color(0xFFFFFBF5)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _prompt('Tell about your day', () async {}),
                  const SizedBox(width: 10),
                  _prompt('Share a memory', () async {}),
                  const SizedBox(width: 10),
                  _prompt('Ask a question', () async {}),
                ],
              ),
              const SizedBox(height: 24),
              ChangeNotifierProvider.value(
                value: p,
                child: AudioRecordingWidget(
                  onSend: (path, seconds) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FamilyChatScreen(
                          familyId: 'demo-family-123',
                          userId: 'youth-demo',
                          userType: 'youth',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _prompt(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE0B2),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFFFB74D)),
        ),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF8D6E63))),
      ),
    );
  }
}