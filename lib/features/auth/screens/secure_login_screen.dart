import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/models/user_model.dart';
import '../../../core/services/enhanced_auth_service.dart';
import '../../../core/services/voice_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/enhanced_ui_components.dart';
import '../../../core/widgets/loading_states.dart';
import '../../../core/widgets/success_animations.dart';
import '../providers/auth_provider.dart';

class SecureLoginScreen extends StatefulWidget {
  const SecureLoginScreen({super.key});

  @override
  State<SecureLoginScreen> createState() => _SecureLoginScreenState();
}

class _SecureLoginScreenState extends State<SecureLoginScreen>
    with TickerProviderStateMixin {
  final _authService = EnhancedAuthService.instance;
  final _voiceService = VoiceService.instance;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _mfaController = TextEditingController();

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // State variables
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _requiresMfa = false;
  bool _showBiometric = false;
  int _failedAttempts = 0;
  DeviceInfo? _currentDevice;
  UserRole? _detectedRole;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkBiometricAvailability();
    _loadSavedEmail();
    _initializeDevice();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _checkBiometricAvailability() async {
    final isSupported = await _authService.isBiometricSupported();
    final isEnabled = await _authService.getBiometricEnabled();
    
    setState(() {
      _showBiometric = isSupported && isEnabled;
    });

    if (_showBiometric) {
      // Auto-prompt for biometric if available
      Future.delayed(const Duration(seconds: 1), _authenticateWithBiometrics);
    }
  }

  Future<void> _loadSavedEmail() async {
    final savedEmail = await _authService.getLastEmail();
    if (savedEmail != null) {
      _emailController.text = savedEmail;
      setState(() => _rememberMe = true);
    }
  }

  Future<void> _initializeDevice() async {
    try {
      await _authService.initialize();
      final devices = await _authService.getUserDevices();
      if (devices.isNotEmpty) {
        _currentDevice = devices.first;
      }
    } catch (e) {
      debugPrint('Error initializing device: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _mfaController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    _voiceService.speak('Signing in');

    try {
      final response = await _authService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        mfaCode: _requiresMfa ? _mfaController.text : null,
      );

      if (response.user != null) {
        // Load user profile to get role
        final authProvider = context.read<AuthProvider>();
        await authProvider.loadCurrentUser();
        
        if (mounted) {
          await SuccessAnimations.show(
            context,
            message: 'Welcome back!',
          );

          // Check if device should be trusted
          if (_currentDevice?.isTrusted == false && _failedAttempts == 0) {
            _promptTrustDevice();
          } else {
            _navigateToDashboard();
          }
        }
      }
    } catch (e) {
      _handleSignInError(e);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleSignInError(dynamic error) {
    setState(() {
      _failedAttempts++;
    });

    String message = 'Sign in failed';
    
    if (error.toString().contains('MFA')) {
      setState(() => _requiresMfa = true);
      message = 'Please enter your MFA code';
    } else if (error.toString().contains('Invalid login credentials')) {
      message = 'Invalid email or password';
      
      if (_failedAttempts >= 3) {
        message += '. Too many failed attempts.';
        _showAccountRecoveryOptions();
      }
    } else if (error.toString().contains('User not confirmed')) {
      message = 'Please verify your email first';
    } else {
      message = error.toString();
    }

    _voiceService.speak(message);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: _failedAttempts >= 2
            ? SnackBarAction(
                label: 'Forgot Password?',
                textColor: Colors.white,
                onPressed: () => context.push('/forgot-password'),
              )
            : null,
      ),
    );
  }

  Future<void> _authenticateWithBiometrics() async {
    final authenticated = await _authService.authenticateWithBiometrics(
      reason: 'Authenticate to access FamilyBridge',
    );

    if (authenticated) {
      _voiceService.speak('Biometric authentication successful');
      
      // Auto-fill last email
      final lastEmail = await _authService.getLastEmail();
      if (lastEmail != null) {
        _emailController.text = lastEmail;
        // Attempt to sign in with cached credentials
        _navigateToDashboard();
      }
    }
  }

  void _promptTrustDevice() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trust This Device?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.security,
              size: 48,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            Text(
              'Would you like to trust this device for future logins?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Device: ${_currentDevice?.deviceName ?? 'Unknown'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToDashboard();
            },
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _authService.trustDevice(
                deviceName: _currentDevice?.deviceName,
              );
              if (mounted) {
                Navigator.of(context).pop();
                _navigateToDashboard();
              }
            },
            child: const Text('Trust Device'),
          ),
        ],
      ),
    );
  }

  void _showAccountRecoveryOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Account Recovery Options',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Reset via Email'),
              subtitle: const Text('Send reset link to your email'),
              onTap: () {
                Navigator.pop(context);
                context.push('/forgot-password');
              },
            ),
            ListTile(
              leading: const Icon(Icons.quiz),
              title: const Text('Security Question'),
              subtitle: const Text('Answer your security question'),
              onTap: () {
                Navigator.pop(context);
                context.push('/security-question-reset');
              },
            ),
            ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text('Contact Support'),
              subtitle: const Text('Get help from our support team'),
              onTap: () {
                Navigator.pop(context);
                // Open support contact
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDashboard() {
    final authProvider = context.read<AuthProvider>();
    final role = authProvider.currentUser?.role;

    String route = '/elder-home';
    switch (role) {
      case UserRole.elder:
        route = '/elder-home';
        break;
      case UserRole.caregiver:
        route = '/caregiver-dashboard';
        break;
      case UserRole.youth:
        route = '/youth-home';
        break;
      default:
        route = '/onboarding';
    }

    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isElder = _detectedRole == UserRole.elder;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.primaryColor.withOpacity(0.1),
              theme.primaryColor.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo and Title
                        _buildHeader(theme, isElder),
                        const SizedBox(height: 48),
                        
                        // Login Form
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: isElder ? 500 : 400,
                          ),
                          child: EnhancedCard(
                            isElder: isElder,
                            elevation: 8,
                            child: Padding(
                              padding: EdgeInsets.all(isElder ? 32 : 24),
                              child: Column(
                                children: [
                                  // Biometric login button
                                  if (_showBiometric && !_requiresMfa) ...[
                                    _buildBiometricButton(isElder),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      child: Row(
                                        children: [
                                          const Expanded(child: Divider()),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            child: Text(
                                              'OR',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: isElder ? 18 : 14,
                                              ),
                                            ),
                                          ),
                                          const Expanded(child: Divider()),
                                        ],
                                      ),
                                    ),
                                  ],
                                  
                                  // Email field
                                  if (!_requiresMfa)
                                    EnhancedTextField(
                                      controller: _emailController,
                                      label: 'Email Address',
                                      prefixIcon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
                                      isElder: isElder,
                                      validator: (value) {
                                        if (value?.isEmpty ?? true) {
                                          return 'Please enter your email';
                                        }
                                        if (!value!.contains('@')) {
                                          return 'Please enter a valid email';
                                        }
                                        return null;
                                      },
                                      onChanged: (value) {
                                        // Detect role based on email pattern
                                        if (value.contains('elder')) {
                                          _detectedRole = UserRole.elder;
                                        } else if (value.contains('care')) {
                                          _detectedRole = UserRole.caregiver;
                                        } else if (value.contains('youth')) {
                                          _detectedRole = UserRole.youth;
                                        }
                                      },
                                    ),
                                  
                                  if (!_requiresMfa)
                                    const SizedBox(height: 16),
                                  
                                  // Password field
                                  if (!_requiresMfa)
                                    EnhancedTextField(
                                      controller: _passwordController,
                                      label: 'Password',
                                      prefixIcon: Icons.lock_outline,
                                      obscureText: _obscurePassword,
                                      isElder: isElder,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          size: isElder ? 28 : 24,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                      ),
                                      validator: (value) {
                                        if (value?.isEmpty ?? true) {
                                          return 'Please enter your password';
                                        }
                                        if (value!.length < 6) {
                                          return 'Password must be at least 6 characters';
                                        }
                                        return null;
                                      },
                                    ),
                                  
                                  // MFA Code field
                                  if (_requiresMfa) ...[
                                    Icon(
                                      Icons.security,
                                      size: isElder ? 64 : 48,
                                      color: theme.primaryColor,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Enter Verification Code',
                                      style: TextStyle(
                                        fontSize: isElder ? 24 : 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Please enter the code from your authenticator app',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: isElder ? 18 : 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    EnhancedTextField(
                                      controller: _mfaController,
                                      label: 'Verification Code',
                                      prefixIcon: Icons.pin_outlined,
                                      keyboardType: TextInputType.number,
                                      isElder: isElder,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: isElder ? 28 : 20,
                                        letterSpacing: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(6),
                                      ],
                                      validator: (value) {
                                        if (value?.isEmpty ?? true) {
                                          return 'Please enter the code';
                                        }
                                        if (value!.length != 6) {
                                          return 'Code must be 6 digits';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Remember me & Forgot password
                                  if (!_requiresMfa)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Checkbox(
                                              value: _rememberMe,
                                              onChanged: (value) {
                                                setState(() {
                                                  _rememberMe = value ?? false;
                                                });
                                              },
                                            ),
                                            Text(
                                              'Remember me',
                                              style: TextStyle(
                                                fontSize: isElder ? 18 : 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            context.push('/forgot-password');
                                          },
                                          child: Text(
                                            'Forgot Password?',
                                            style: TextStyle(
                                              fontSize: isElder ? 18 : 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  // Sign in button
                                  EnhancedButton(
                                    onPressed: _isLoading ? null : _signIn,
                                    type: ButtonType.primary,
                                    size: isElder
                                        ? ButtonSize.large
                                        : ButtonSize.medium,
                                    text: _isLoading
                                        ? null
                                        : (_requiresMfa ? 'Verify' : 'Sign In'),
                                    fullWidth: true,
                                    child: _isLoading
                                        ? SizedBox(
                                            height: isElder ? 24 : 20,
                                            width: isElder ? 24 : 20,
                                            child: const CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : null,
                                  ),
                                  
                                  if (_requiresMfa) ...[
                                    const SizedBox(height: 16),
                                    TextButton(
                                      onPressed: () {
                                        setState(() {
                                          _requiresMfa = false;
                                          _mfaController.clear();
                                        });
                                      },
                                      child: Text(
                                        'Use different account',
                                        style: TextStyle(
                                          fontSize: isElder ? 18 : 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                  
                                  if (!_requiresMfa) ...[
                                    const SizedBox(height: 24),
                                    
                                    // Social login options
                                    _buildSocialLogins(isElder),
                                    
                                    const SizedBox(height: 24),
                                    
                                    // Sign up link
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Don't have an account? ",
                                          style: TextStyle(
                                            fontSize: isElder ? 18 : 14,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            context.push('/signup');
                                          },
                                          child: Text(
                                            'Sign Up',
                                            style: TextStyle(
                                              fontSize: isElder ? 18 : 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        // Security badges
                        const SizedBox(height: 32),
                        _buildSecurityBadges(isElder),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isElder) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.family_restroom,
            size: isElder ? 80 : 60,
            color: theme.primaryColor,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'FamilyBridge',
          style: TextStyle(
            fontSize: isElder ? 36 : 28,
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Secure Family Care Platform',
          style: TextStyle(
            fontSize: isElder ? 20 : 16,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildBiometricButton(bool isElder) {
    return EnhancedButton(
      onPressed: _authenticateWithBiometrics,
      type: ButtonType.secondary,
      size: isElder ? ButtonSize.large : ButtonSize.medium,
      icon: Icons.fingerprint,
      text: 'Sign in with Biometrics',
      fullWidth: true,
    );
  }

  Widget _buildSocialLogins(bool isElder) {
    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Or sign in with',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: isElder ? 18 : 14,
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialButton(
              icon: Icons.g_mobiledata,
              label: 'Google',
              color: Colors.red,
              onTap: () async {
                // Implement Google sign in
              },
              isElder: isElder,
            ),
            const SizedBox(width: 16),
            _buildSocialButton(
              icon: Icons.apple,
              label: 'Apple',
              color: Colors.black,
              onTap: () async {
                // Implement Apple sign in
              },
              isElder: isElder,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isElder,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isElder ? 24 : 20,
          vertical: isElder ? 16 : 12,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: isElder ? 28 : 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: isElder ? 18 : 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityBadges(bool isElder) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildBadge(
          icon: Icons.lock,
          label: 'HIPAA\nCompliant',
          isElder: isElder,
        ),
        const SizedBox(width: 16),
        _buildBadge(
          icon: Icons.security,
          label: 'End-to-End\nEncrypted',
          isElder: isElder,
        ),
        const SizedBox(width: 16),
        _buildBadge(
          icon: Icons.verified_user,
          label: 'Multi-Factor\nAuthentication',
          isElder: isElder,
        ),
      ],
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required bool isElder,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: isElder ? 32 : 24,
          color: Colors.green,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isElder ? 12 : 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}