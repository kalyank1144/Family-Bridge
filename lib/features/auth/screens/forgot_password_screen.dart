import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:family_bridge/core/services/auth_service.dart';
import 'package:family_bridge/core/services/voice_service.dart';
import 'package:family_bridge/core/theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _answerController = TextEditingController();

  bool _loading = false;
  bool _emailSent = false;
  bool _showSecurityOption = false;

  VoiceService? get _voice => context.read<VoiceService?>();

  @override
  void dispose() {
    _emailController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.instance.sendPasswordResetEmail(_emailController.text.trim());
      setState(() => _emailSent = true);
      _voice?.announceAction('Password reset email sent. Please check your inbox.');
      _showSnack('Password reset email sent! Please check your inbox.');
    } catch (e) {
      _voice?.announceError('Failed to send reset email');
      _showSnack('Failed to send reset email. Please try again.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _resetViaSecurityAnswer() async {
    if (!_formKey.currentState!.validate() || _answerController.text.trim().isEmpty) {
      _voice?.announceError('Please provide your security answer');
      _showSnack('Please provide your security answer');
      return;
    }
    setState(() => _loading = true);
    try {
      final success = await AuthService.instance.resetPasswordViaSecurityAnswer(
        email: _emailController.text.trim(),
        answer: _answerController.text.trim(),
      );
      if (success) {
        _voice?.announceAction('Password reset successful. Please check your email for the new password.');
        _showSnack('Password reset successful! Check your email.');
        if (mounted) context.pop();
      } else {
        _voice?.announceError('Security answer incorrect');
        _showSnack('Security answer is incorrect. Please try again.');
      }
    } catch (e) {
      _voice?.announceError('Failed to reset password via security answer');
      _showSnack('Failed to reset password. Please try the email option.');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset password'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_emailSent) ...[
                  Text(
                    'Forgot your password?',
                    style: textTheme.displaySmall,
                    semanticsLabel: 'Forgot your password? Reset it here',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your email address and we\'ll send you a link to reset your password.',
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      hintText: 'name@example.com',
                      prefixIcon: Icon(Icons.email),
                    ),
                    style: textTheme.bodyLarge?.copyWith(fontSize: 20),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Email is required';
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  if (_showSecurityOption) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Or answer your security question:',
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'What was the name of your first pet?',
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _answerController,
                      decoration: const InputDecoration(
                        labelText: 'Security answer',
                        hintText: 'Enter your answer',
                        prefixIcon: Icon(Icons.security),
                      ),
                      style: textTheme.bodyLarge?.copyWith(fontSize: 20),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : _sendResetEmail,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: _loading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Send reset email'),
                    ),
                  ),
                  if (_showSecurityOption) ...[
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _loading ? null : _resetViaSecurityAnswer,
                      child: const Text('Reset via security question'),
                    ),
                  ],
                  if (!_showSecurityOption) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() => _showSecurityOption = true),
                      child: const Text('Can\'t access email? Try security question'),
                    ),
                  ],
                ] else ...[
                  Icon(
                    Icons.mark_email_read,
                    size: 64,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Check your email',
                    style: textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We\'ve sent a password reset link to ${_emailController.text}',
                    style: textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () => setState(() {
                      _emailSent = false;
                      _showSecurityOption = false;
                    }),
                    child: const Text('Send again'),
                  ),
                ],
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Remember your password?'),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Sign in'),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}