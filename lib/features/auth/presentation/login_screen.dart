import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final emailC = TextEditingController();
  final passC = TextEditingController();
  final phoneC = TextEditingController();
  final otpC = TextEditingController();
  bool viaPhone = false;
  bool sending = false;

  @override
  Widget build(BuildContext context) {
    final authRepo = ref.watch(authRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(label: const Text('Email'), selected: !viaPhone, onSelected: (_) => setState(() => viaPhone = false)),
                const SizedBox(width: 8),
                ChoiceChip(label: const Text('Phone'), selected: viaPhone, onSelected: (_) => setState(() => viaPhone = true)),
              ],
            ),
            const SizedBox(height: 16),
            if (!viaPhone) ...[
              AppTextField(controller: emailC, label: 'Email', keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              AppTextField(controller: passC, label: 'Password', obscure: true),
              const SizedBox(height: 16),
              AppButton(
                label: 'Sign in',
                loading: sending,
                onPressed: () async {
                  setState(() => sending = true);
                  try {
                    await authRepo.signInWithEmail(email: emailC.text.trim(), password: passC.text);
                  } finally {
                    setState(() => sending = false);
                  }
                },
              ),
            ] else ...[
              AppTextField(controller: phoneC, label: 'Phone (+1...)', keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              AppButton(
                label: 'Send code',
                loading: sending,
                onPressed: () async {
                  setState(() => sending = true);
                  try {
                    await authRepo.signInWithPhoneOtp(phone: phoneC.text.trim());
                  } finally {
                    setState(() => sending = false);
                  }
                },
              ),
              const SizedBox(height: 12),
              AppTextField(controller: otpC, label: 'OTP Code'),
              const SizedBox(height: 12),
              AppButton(
                label: 'Verify',
                onPressed: () async {
                  await authRepo.verifyPhoneOtp(phone: phoneC.text.trim(), token: otpC.text.trim());
                },
              ),
            ],
            const Spacer(),
            TextButton(
              onPressed: () => context.push('/register'),
              child: const Text('Create account'),
            )
          ],
        ),
      ),
    );
  }
}
