import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/user_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/services/voice_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  UserRole _selectedRole = UserRole.elder;
  bool _loading = false;
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;

  VoiceService? get _voice => context.read<VoiceService?>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms || !_acceptedPrivacy) {
      _announceError('Please accept the terms and privacy policy');
      _showSnack('Please accept the terms and privacy policy');
      return;
    }

    setState(() => _loading = true);
    try {
      final res = await context.read<AuthProvider>().signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            name: _nameController.text.trim(),
            role: _selectedRole,
          );

      if (res.user != null) {
        if (mounted) {
          _voice?.announceAction('Account created successfully. Please check your email to verify your account.');
          _showSnack('Account created! Please check your email to verify.');
          context.push('/profile-setup');
        }
      }
    } catch (e) {
      _announceError('Signup failed: ${e.toString()}');
      _showSnack('Signup failed.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
      appBar: AppBar(
        title: const Text('Create account'),
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
                Text(
                  'Join FamilyBridge',
                  style: textTheme.displaySmall,
                  semanticsLabel: 'Join Family Bridge, create new account',
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    hintText: 'Enter your full name',
                  ),
                  style: textTheme.bodyLarge?.copyWith(fontSize: 20),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Name is required';
                    if (v.trim().length < 2) return 'Name must be at least 2 characters';
                    return null;
                  },
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
                    if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    hintText: 'At least 8 characters',
                  ),
                  style: textTheme.bodyLarge?.copyWith(fontSize: 20),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 8) return 'Password must be at least 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm password',
                    hintText: 'Re-enter your password',
                  ),
                  style: textTheme.bodyLarge?.copyWith(fontSize: 20),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm your password';
                    if (v != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'I am a...',
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...UserRole.values.map((role) => RadioListTile<UserRole>(
                      title: Text(_roleLabel(role)),
                      subtitle: Text(_roleDescription(role)),
                      value: role,
                      groupValue: _selectedRole,
                      onChanged: (v) => setState(() => _selectedRole = v!),
                      contentPadding: EdgeInsets.zero,
                    )),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: Row(
                    children: [
                      const Text('I accept the '),
                      GestureDetector(
                        onTap: () => context.push('/terms'),
                        child: const Text(
                          'Terms of Service',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  value: _acceptedTerms,
                  onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: Row(
                    children: [
                      const Text('I accept the '),
                      GestureDetector(
                        onTap: () => context.push('/privacy'),
                        child: const Text(
                          'Privacy Policy',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  value: _acceptedPrivacy,
                  onChanged: (v) => setState(() => _acceptedPrivacy = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading ? null : _signup,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _loading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create account'),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
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

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.elder:
        return 'Senior family member';
      case UserRole.caregiver:
        return 'Family caregiver';
      case UserRole.youth:
        return 'Young family member';
    }
  }

  String _roleDescription(UserRole role) {
    switch (role) {
      case UserRole.elder:
        return 'I need care coordination and support';
      case UserRole.caregiver:
        return 'I provide care and coordination';
      case UserRole.youth:
        return 'I want to stay connected with family';
    }
  }
}