import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_providers.dart';
import '../widgets/voice_feedback.dart';

class ElderRegistrationScreen extends ConsumerStatefulWidget {
  const ElderRegistrationScreen({super.key});
  @override
  ConsumerState<ElderRegistrationScreen> createState() => _ElderRegistrationScreenState();
}

class _ElderRegistrationScreenState extends ConsumerState<ElderRegistrationScreen> {
  final phoneC = TextEditingController();
  final codeC = TextEditingController();
  bool step2 = false;
  bool sending = false;

  @override
  void initState() {
    super.initState();
    VoiceFeedback.speak('Welcome. Enter your phone number to receive a code.');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authServiceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Elder registration')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step2 ? 'Enter the code sent to your phone' : 'Enter your phone number', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              if (!step2)
                TextField(
                  controller: phoneC,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone (+1...)'),
                )
              else
                TextField(
                  controller: codeC,
                  decoration: const InputDecoration(labelText: 'Verification code'),
                ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 60),
                child: FilledButton(
                  onPressed: sending
                      ? null
                      : () async {
                          setState(() => sending = true);
                          try {
                            if (!step2) {
                              await auth.signInWithPhoneOtp(phone: phoneC.text.trim());
                              setState(() => step2 = true);
                              VoiceFeedback.speak('Code sent. Enter the code now.');
                            } else {
                              await auth.verifyPhoneOtp(phone: phoneC.text.trim(), token: codeC.text.trim());
                              VoiceFeedback.speak('You are signed in.');
                            }
                          } finally {
                            setState(() => sending = false);
                          }
                        },
                  child: Text(step2 ? 'Verify' : 'Send code'),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Large buttons and high contrast are enabled for accessibility.'),
            ],
          ),
        ),
      ),
    );
  }
}