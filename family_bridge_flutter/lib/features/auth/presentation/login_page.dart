import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final otpCtrl = TextEditingController();
  bool otpSent = false;
  bool loading = false;

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    phoneCtrl.dispose();
    otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _emailSignIn() async {
    setState(() => loading = true);
    try {
      await ref.read(authRepositoryProvider).signInWithEmail(
            email: emailCtrl.text.trim(),
            password: passCtrl.text,
          );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _phoneSignIn() async {
    setState(() => loading = true);
    try {
      await ref.read(authRepositoryProvider).signInWithPhone(phone: phoneCtrl.text.trim());
      setState(() => otpSent = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    setState(() => loading = true);
    try {
      await ref.read(authRepositoryProvider).verifyPhoneOtp(
            phone: phoneCtrl.text.trim(),
            token: otpCtrl.text.trim(),
          );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FamilyBridge Login')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Email Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 8),
            TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: loading ? null : _emailSignIn, child: const Text('Sign in')),
            const Divider(height: 32),
            const Text('Phone (OTP) for Elder Users', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone (+1...)')),
            if (otpSent) ...[
              const SizedBox(height: 8),
              TextField(controller: otpCtrl, decoration: const InputDecoration(labelText: 'OTP Code')),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: loading ? null : _verifyOtp, child: const Text('Verify')),
            ] else ...[
              const SizedBox(height: 8),
              ElevatedButton(onPressed: loading ? null : _phoneSignIn, child: const Text('Send OTP')),
            ],
          ],
        ),
      ),
    );
  }
}
