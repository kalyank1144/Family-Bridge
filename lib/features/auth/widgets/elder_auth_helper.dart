import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_tts/flutter_tts.dart';

import 'package:family_bridge/core/services/voice_service.dart';
import 'package:family_bridge/core/theme/app_theme.dart';

/// Elder-friendly authentication helper widget
class ElderAuthHelper extends StatefulWidget {
  final Function(String email, String password) onSignIn;
  final VoidCallback onForgotPassword;
  final VoidCallback onNeedHelp;

  const ElderAuthHelper({
    super.key,
    required this.onSignIn,
    required this.onForgotPassword,
    required this.onNeedHelp,
  });

  @override
  State<ElderAuthHelper> createState() => _ElderAuthHelperState();
}

class _ElderAuthHelperState extends State<ElderAuthHelper>
    with SingleTickerProviderStateMixin {
  final _voiceService = VoiceService.instance;
  final _tts = FlutterTts();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  int _currentStep = 0;
  bool _isListening = false;
  bool _showPassword = false;
  bool _needsAssistance = false;

  @override
  void initState() {
    super.initState();
    _initializeVoice();
    _initializePulseAnimation();
    _startGuidedFlow();
  }

  void _initializeVoice() {
    _tts.setLanguage('en-US');
    _tts.setSpeechRate(0.4); // Slower for elder users
    _tts.setVolume(1.0);
    _tts.setPitch(1.0);
  }

  void _initializePulseAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _tts.stop();
    super.dispose();
  }

  void _startGuidedFlow() {
    _speak('Welcome to FamilyBridge. Let me help you sign in. '
        'First, please enter your email address.');
  }

  Future<void> _speak(String text) async {
    await _tts.speak(text);
  }

  void _nextStep() {
    setState(() {
      _currentStep++;
    });

    switch (_currentStep) {
      case 1:
        _speak('Good! Now please enter your password. '
            'Tap the eye icon if you want to see what you are typing.');
        break;
      case 2:
        _speak('Perfect! Now tap the big green Sign In button to continue.');
        _handleSignIn();
        break;
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      
      if (_currentStep == 0) {
        _speak('Let\'s go back. Please enter your email address.');
      }
    }
  }

  void _handleSignIn() {
    if (_emailController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
      widget.onSignIn(_emailController.text, _passwordController.text);
    } else {
      _speak('Please make sure you have entered both email and password.');
    }
  }

  void _requestAssistance() {
    setState(() {
      _needsAssistance = true;
    });
    
    HapticFeedback.heavyImpact();
    _speak('Don\'t worry! Let me connect you with a family member who can help.');
    
    // Show assistance options
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildAssistanceOptions(),
    );
  }

  Widget _buildAssistanceOptions() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.help_outline,
            size: 64,
            color: Colors.blue,
          ),
          const SizedBox(height: 24),
          const Text(
            'Need Help Signing In?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          _buildAssistanceButton(
            icon: Icons.phone,
            label: 'Call Family Member',
            color: Colors.green,
            onTap: () {
              _speak('Calling your primary caregiver');
              // Implement call functionality
            },
          ),
          const SizedBox(height: 16),
          _buildAssistanceButton(
            icon: Icons.message,
            label: 'Send Help Request',
            color: Colors.blue,
            onTap: () {
              _speak('Sending help request to your family');
              // Implement help request
            },
          ),
          const SizedBox(height: 16),
          _buildAssistanceButton(
            icon: Icons.quiz,
            label: 'Answer Security Question',
            color: Colors.orange,
            onTap: () {
              Navigator.pop(context);
              widget.onForgotPassword();
            },
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Try Again',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistanceButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Sign In Help',
          style: TextStyle(fontSize: 28),
        ),
        backgroundColor: theme.primaryColor.withOpacity(0.1),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up, size: 32),
            onPressed: () {
              _speak('This is the sign in help screen. '
                  'I will guide you through signing in step by step.');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Progress indicator
              _buildProgressIndicator(),
              const SizedBox(height: 32),
              
              // Current step content
              Expanded(
                child: _buildStepContent(),
              ),
              
              // Navigation buttons
              _buildNavigationButtons(),
              
              const SizedBox(height: 24),
              
              // Help button
              _buildHelpButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isActive = index <= _currentStep;
        final isComplete = index < _currentStep;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isActive ? 60 : 50,
                height: isActive ? 60 : 50,
                decoration: BoxDecoration(
                  color: isActive
                      ? Theme.of(context).primaryColor
                      : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isComplete
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 32,
                        )
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isActive ? Colors.white : Colors.grey,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getStepTitle(index),
                style: TextStyle(
                  fontSize: 16,
                  color: isActive ? Colors.black : Colors.grey,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Email';
      case 1:
        return 'Password';
      case 2:
        return 'Sign In';
      default:
        return '';
    }
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildEmailStep();
      case 1:
        return _buildPasswordStep();
      case 2:
        return _buildConfirmStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEmailStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: const Icon(
            Icons.email_outlined,
            size: 80,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Enter Your Email',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Type the email address you use for FamilyBridge',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 40),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(fontSize: 24),
          decoration: InputDecoration(
            hintText: 'your.email@example.com',
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 20,
            ),
            prefixIcon: const Icon(Icons.email, size: 32),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(24),
          ),
          onSubmitted: (_) => _nextStep(),
        ),
        const SizedBox(height: 24),
        TextButton.icon(
          onPressed: () {
            _speak(_emailController.text.isEmpty
                ? 'Email field is empty'
                : 'You entered: ${_emailController.text}');
          },
          icon: const Icon(Icons.volume_up, size: 28),
          label: const Text(
            'Read Back to Me',
            style: TextStyle(fontSize: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: const Icon(
            Icons.lock_outline,
            size: 80,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Enter Your Password',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Type your password carefully',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 40),
        TextField(
          controller: _passwordController,
          obscureText: !_showPassword,
          style: const TextStyle(fontSize: 24),
          decoration: InputDecoration(
            hintText: 'Your password',
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 20,
            ),
            prefixIcon: const Icon(Icons.lock, size: 32),
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword ? Icons.visibility : Icons.visibility_off,
                size: 32,
              ),
              onPressed: () {
                setState(() {
                  _showPassword = !_showPassword;
                });
                _speak(_showPassword
                    ? 'Password is now visible'
                    : 'Password is now hidden');
              },
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(24),
          ),
          onSubmitted: (_) => _nextStep(),
        ),
        const SizedBox(height: 24),
        TextButton.icon(
          onPressed: widget.onForgotPassword,
          icon: const Icon(Icons.help_outline, size: 28),
          label: const Text(
            'I Forgot My Password',
            style: TextStyle(fontSize: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.check_circle,
          size: 100,
          color: Colors.green,
        ),
        const SizedBox(height: 32),
        const Text(
          'Ready to Sign In!',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Information:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.email, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _emailController.text,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.lock, color: Colors.green),
                  const SizedBox(width: 12),
                  Text(
                    '••••••••',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        ElevatedButton(
          onPressed: _handleSignIn,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 60,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Colors.green,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.login, size: 32, color: Colors.white),
              SizedBox(width: 16),
              Text(
                'Sign In Now',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentStep > 0)
          ElevatedButton.icon(
            onPressed: _previousStep,
            icon: const Icon(Icons.arrow_back, size: 28),
            label: const Text(
              'Back',
              style: TextStyle(fontSize: 20),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )
        else
          const SizedBox(width: 120),
        
        if (_currentStep < 2)
          ElevatedButton.icon(
            onPressed: () {
              if (_currentStep == 0 && _emailController.text.isEmpty) {
                _speak('Please enter your email address first');
                return;
              }
              if (_currentStep == 1 && _passwordController.text.isEmpty) {
                _speak('Please enter your password first');
                return;
              }
              _nextStep();
            },
            label: const Text(
              'Next',
              style: TextStyle(fontSize: 20),
            ),
            icon: const Icon(Icons.arrow_forward, size: 28),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHelpButton() {
    return Container(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _requestAssistance,
        icon: const Icon(Icons.help, size: 32),
        label: const Text(
          'I Need Help',
          style: TextStyle(fontSize: 22),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: Colors.orange, width: 2),
          foregroundColor: Colors.orange,
        ),
      ),
    );
  }
}