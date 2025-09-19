import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/services/voice_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _biometricSupported = false;

  VoiceService? get _voice => context.read<VoiceService?>();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final auth = AuthService.instance;
    _biometricSupported = await auth.isBiometricSupported();
    final lastEmail = await auth.getLastEmail();
    if (lastEmail != null) _emailController.text = lastEmail;
    setState(() {});
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final res = await context
          .read<AuthProvider>()
          .signIn(_emailController.text.trim(), _passwordController.text);
      if (res.session != null) {
        if (mounted) context.go(context.read<AuthProvider>().roleBasedHomePath());
      } else {
        _announceError('Please verify your email to continue.');
        _showSnack('Please verify your email to continue.');
      }
    } catch (e) {
      _announceError('Login failed: ${e.toString()}');
      _showSnack('Login failed.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _oauthGoogle() async {
    try {
      await context.read<AuthProvider>().signInWithGoogle();
    } catch (e) {
      _announceError('Google sign-in failed.');
      _showSnack('Google sign-in failed');
    }
  }

  Future<void> _oauthApple() async {
    try {
      await context.read<AuthProvider>().signInWithApple();
    } catch (e) {
      _announceError('Apple sign-in failed.');
      _showSnack('Apple sign-in failed');
    }
  }

  Future<void> _unlockOffline() async {
    final ok = await AuthService.instance.unlockOfflineWithBiometrics();
    if (!ok) {
      _announceError('Biometric authentication failed.');
      _showSnack('Biometric authentication failed');
      return;
    }
    if (mounted) context.go(context.read<AuthProvider>().roleBasedHomePath());
  }

  void _announceError(String msg) {
    _voice?.announceError(msg);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Welcome back',
                  style: textTheme.displaySmall,
                  semanticsLabel: 'Welcome back, sign in',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'name@example.com',
                  ),
                  style: textTheme.bodyLarge?.copyWith(fontSize: 20),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                  ),
                  style: textTheme.bodyLarge?.copyWith(fontSize: 20),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 8) return 'Minimum 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: const Text('Forgot password?'),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _loading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign in'),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('or'),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _oauthGoogle,
                        icon: const Icon(Icons.login),
                        label: const Text('Google'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (Platform.isIOS)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _oauthApple,
                          icon: const Icon(Icons.apple),
                          label: const Text('Apple'),
                        ),
                      ),
                  ],
                ),
                if (_biometricSupported) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _unlockOffline,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Unlock with biometrics'),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () => context.push('/signup'),
                      child: const Text('Sign up'),
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