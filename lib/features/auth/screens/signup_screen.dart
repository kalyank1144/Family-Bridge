import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:family_bridge/core/models/user_model.dart';
import 'package:family_bridge/core/services/voice_service.dart';
import 'package:family_bridge/core/theme/app_theme.dart';
import 'package:family_bridge/core/widgets/enhanced_ui_components.dart';
import 'package:family_bridge/core/widgets/form_validation.dart';
import 'package:family_bridge/core/widgets/loading_states.dart';
import 'package:family_bridge/core/widgets/success_animations.dart';
import 'package:family_bridge/features/auth/providers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  UserRole _selectedRole = UserRole.elder;
  bool _loading = false;
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;
  bool _showSuccess = false;
  double _formProgress = 0.0;

  VoiceService? get _voice => context.read<VoiceService?>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updateFormProgress() {
    double progress = 0.0;
    
    if (_nameController.text.trim().isNotEmpty) progress += 0.15;
    if (_emailController.text.trim().isNotEmpty && 
        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailController.text)) {
      progress += 0.15;
    }
    if (_passwordController.text.length >= 8) progress += 0.2;
    if (_confirmPasswordController.text == _passwordController.text && 
        _confirmPasswordController.text.isNotEmpty) {
      progress += 0.15;
    }
    if (_acceptedTerms) progress += 0.15;
    if (_acceptedPrivacy) progress += 0.2;

    setState(() => _formProgress = progress);
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms || !_acceptedPrivacy) {
      _announceError('Please accept the terms and privacy policy');
      _showSnack('Please accept the terms and privacy policy', isError: true);
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
        setState(() => _showSuccess = true);
        
        _voice?.announceAction('Account created successfully. Please check your email to verify your account.');
        
        SuccessToast.show(
          context,
          message: 'Account created! Please check your email.',
          icon: Icons.mark_email_read,
          duration: const Duration(seconds: 4),
        );
        
        await Future.delayed(const Duration(milliseconds: 1500));
        
        if (mounted) {
          context.push('/profile-setup');
        }
      }
    } catch (e) {
      _announceError('Signup failed: ${e.toString()}');
      _showSnack('Failed to create account. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _announceError(String msg) {
    _voice?.announceError(msg);
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create account'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SuccessCelebration(
        showCelebration: _showSuccess,
        child: LoadingStates.pageOverlay(
          isLoading: _loading,
          loadingText: 'Creating your account...',
          child: SafeArea(
            child: Column(
              children: [
                // Progress indicator
                if (_formProgress > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: ProgressCelebration(
                      progress: _formProgress,
                      showCelebration: _formProgress >= 1.0,
                      label: 'Account setup progress',
                    ),
                  ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      onChanged: _updateFormProgress,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header with animation
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOut,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, (1 - value) * 50),
                                child: Opacity(
                                  opacity: value,
                                  child: child,
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Join FamilyBridge',
                                  style: textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  semanticsLabel: 'Join Family Bridge, create new account',
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Create your account to connect with family',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Name field
                          ValidatedFormField(
                            controller: _nameController,
                            labelText: 'Full name',
                            hintText: 'Enter your full name',
                            prefixIcon: Icons.person,
                            validationRules: [
                              ValidationRule('Name is required', (value) {
                                if (value.trim().isEmpty) return 'Please enter your name';
                                if (value.trim().length < 2) return 'Name must be at least 2 characters';
                                return null;
                              }),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Email field with suggestions
                          EmailFormField(
                            controller: _emailController,
                            labelText: 'Email',
                            hintText: 'name@example.com',
                          ),
                          const SizedBox(height: 16),

                          // Password field with strength indicator
                          PasswordStrengthField(
                            controller: _passwordController,
                            labelText: 'Password',
                            hintText: 'Create a strong password',
                            showStrengthIndicator: true,
                          ),
                          const SizedBox(height: 16),

                          // Confirm password field
                          ValidatedFormField(
                            controller: _confirmPasswordController,
                            labelText: 'Confirm password',
                            hintText: 'Re-enter your password',
                            prefixIcon: Icons.lock_outline,
                            obscureText: true,
                            validationRules: [
                              ValidationRule('Passwords must match', (value) {
                                if (value.isEmpty) return 'Please confirm your password';
                                if (value != _passwordController.text) return 'Passwords do not match';
                                return null;
                              }),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Role selection
                          InteractiveCard(
                            borderRadius: 12,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'I am a...',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...UserRole.values.map((role) => Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: InkWell(
                                        onTap: () {
                                          setState(() => _selectedRole = role);
                                          _updateFormProgress();
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: _selectedRole == role 
                                                  ? Theme.of(context).primaryColor 
                                                  : Colors.grey.shade300,
                                              width: _selectedRole == role ? 2 : 1,
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                            color: _selectedRole == role 
                                                ? Theme.of(context).primaryColor.withOpacity(0.1) 
                                                : null,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                _getRoleIcon(role),
                                                color: _selectedRole == role 
                                                    ? Theme.of(context).primaryColor 
                                                    : Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      _getRoleLabel(role),
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        color: _selectedRole == role 
                                                            ? Theme.of(context).primaryColor 
                                                            : null,
                                                      ),
                                                    ),
                                                    Text(
                                                      _getRoleDescription(role),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey.shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (_selectedRole == role)
                                                Icon(
                                                  Icons.check_circle,
                                                  color: Theme.of(context).primaryColor,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Terms and privacy checkboxes
                          InteractiveCard(
                            borderRadius: 12,
                            child: Column(
                              children: [
                                CheckboxListTile(
                                  title: Row(
                                    children: [
                                      const Text('I accept the '),
                                      GestureDetector(
                                        onTap: () => context.push('/terms'),
                                        child: Text(
                                          'Terms of Service',
                                          style: TextStyle(
                                            decoration: TextDecoration.underline,
                                            color: Theme.of(context).primaryColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  value: _acceptedTerms,
                                  onChanged: (v) {
                                    setState(() => _acceptedTerms = v ?? false);
                                    _updateFormProgress();
                                  },
                                  controlAffinity: ListTileControlAffinity.leading,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                CheckboxListTile(
                                  title: Row(
                                    children: [
                                      const Text('I accept the '),
                                      GestureDetector(
                                        onTap: () => context.push('/privacy'),
                                        child: Text(
                                          'Privacy Policy',
                                          style: TextStyle(
                                            decoration: TextDecoration.underline,
                                            color: Theme.of(context).primaryColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  value: _acceptedPrivacy,
                                  onChanged: (v) {
                                    setState(() => _acceptedPrivacy = v ?? false);
                                    _updateFormProgress();
                                  },
                                  controlAffinity: ListTileControlAffinity.leading,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Create account button
                          EnhancedButton(
                            onPressed: _signup,
                            isLoading: _loading,
                            type: ButtonType.primary,
                            size: ButtonSize.large,
                            child: const Text(
                              'Create account',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Sign in link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: textTheme.bodyMedium,
                              ),
                              GestureDetector(
                                onTap: () => context.pop(),
                                child: Text(
                                  'Sign in',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.elder:
        return 'Senior Family Member';
      case UserRole.caregiver:
        return 'Family Caregiver';
      case UserRole.youth:
        return 'Young Family Member';
    }
  }

  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.elder:
        return 'I need care coordination and family support';
      case UserRole.caregiver:
        return 'I provide care and coordinate family health';
      case UserRole.youth:
        return 'I want to stay connected with my family';
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.elder:
        return Icons.elderly;
      case UserRole.caregiver:
        return Icons.medical_services;
      case UserRole.youth:
        return Icons.school;
    }
  }
}