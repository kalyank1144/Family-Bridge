import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/loading_states.dart';
import '../../../core/widgets/success_animations.dart';
import '../../../core/widgets/form_validation.dart';
import '../../../core/widgets/enhanced_ui_components.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/services/voice_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _biometricSupported = false;
  bool _showSuccess = false;

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
        setState(() => _showSuccess = true);
        
        _voice?.announceAction('Login successful! Redirecting to dashboard.');
        SuccessToast.show(
          context,
          message: 'Welcome back! Login successful.',
          icon: Icons.check_circle,
        );
        
        await Future.delayed(const Duration(milliseconds: 800));
        
        if (mounted) {
          context.go(context.read<AuthProvider>().roleBasedHomePath());
        }
      } else {
        _announceError('Please verify your email to continue.');
        _showSnack('Please verify your email to continue.');
      }
    } catch (e) {
      _announceError('Login failed: ${e.toString()}');
      _showSnack('Login failed. Please check your credentials.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _oauthGoogle() async {
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().signInWithGoogle();
      SuccessToast.show(
        context,
        message: 'Google sign-in successful!',
        icon: Icons.check_circle,
      );
    } catch (e) {
      _announceError('Google sign-in failed.');
      _showSnack('Google sign-in failed');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _oauthApple() async {
    setState(() => _loading = true);
    try {
      await context.read<AuthProvider>().signInWithApple();
      SuccessToast.show(
        context,
        message: 'Apple sign-in successful!',
        icon: Icons.check_circle,
      );
    } catch (e) {
      _announceError('Apple sign-in failed.');
      _showSnack('Apple sign-in failed');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _unlockOffline() async {
    final ok = await AuthService.instance.unlockOfflineWithBiometrics();
    if (!ok) {
      _announceError('Biometric authentication failed.');
      _showSnack('Biometric authentication failed');
      return;
    }
    
    SuccessToast.show(
      context,
      message: 'Biometric unlock successful!',
      icon: Icons.fingerprint,
    );
    
    if (mounted) {
      context.go(context.read<AuthProvider>().roleBasedHomePath());
    }
  }

  void _announceError(String msg) {
    _voice?.announceError(msg);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade600,
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
        title: const Text('Sign in'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SuccessCelebration(
        showCelebration: _showSuccess,
        child: LoadingStates.pageOverlay(
          isLoading: _loading,
          loadingText: 'Signing you in...',
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Welcome header with animation
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
                            'Welcome back',
                            style: textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                            semanticsLabel: 'Welcome back, sign in to continue',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in to continue to FamilyBridge',
                            style: textTheme.bodyLarge?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Email field with enhanced validation
                    EmailFormField(
                      controller: _emailController,
                      labelText: 'Email',
                      hintText: 'name@example.com',
                      additionalRules: [
                        ValidationRule('Email is required', (value) {
                          return value.isEmpty ? 'Please enter your email' : null;
                        }),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    ValidatedFormField(
                      controller: _passwordController,
                      labelText: 'Password',
                      prefixIcon: Icons.lock,
                      obscureText: true,
                      validationRules: [
                        ValidationRule('Password is required', (value) {
                          return value.isEmpty ? 'Please enter your password' : null;
                        }),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Forgot password link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        child: Text(
                          'Forgot password?',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sign in button
                    EnhancedButton(
                      onPressed: _login,
                      isLoading: _loading,
                      type: ButtonType.primary,
                      size: ButtonSize.large,
                      child: const Text(
                        'Sign in',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: Colors.grey.shade300,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'or continue with',
                            style: textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Social login buttons
                    Row(
                      children: [
                        Expanded(
                          child: EnhancedButton(
                            onPressed: _oauthGoogle,
                            type: ButtonType.secondary,
                            size: ButtonSize.large,
                            icon: Icons.login,
                            child: const Text('Google'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        if (Platform.isIOS)
                          Expanded(
                            child: EnhancedButton(
                              onPressed: _oauthApple,
                              type: ButtonType.secondary,
                              size: ButtonSize.large,
                              icon: Icons.apple,
                              child: const Text('Apple'),
                            ),
                          ),
                      ],
                    ),
                    
                    // Biometric authentication
                    if (_biometricSupported) ...[
                      const SizedBox(height: 24),
                      InteractiveCard(
                        onTap: _unlockOffline,
                        borderRadius: 16,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.fingerprint,
                                  color: Theme.of(context).primaryColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Use biometric unlock',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Sign in with your fingerprint or face',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.grey.shade400,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),

                    // Sign up link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: textTheme.bodyMedium,
                        ),
                        GestureDetector(
                          onTap: () => context.push('/signup'),
                          child: Text(
                            'Sign up',
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
        ),
      ),
    );
  }
}