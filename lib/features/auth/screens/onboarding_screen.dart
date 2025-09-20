import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/user_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/services/voice_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  int _currentPage = 0;
  UserRole? _selectedRole;
  
  VoiceService? get _voice => context.read<VoiceService?>();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeOnboarding() {
    if (_selectedRole != null) {
      context.read<AuthProvider>().setSelectedRole(_selectedRole!);
      _voice?.announceAction('Onboarding completed. You can now sign up or sign in.');
      context.go('/signup');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  for (int i = 0; i < 3; i++)
                    Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                        decoration: BoxDecoration(
                          color: i <= _currentPage 
                              ? Theme.of(context).primaryColor 
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                  _animationController.reset();
                  _animationController.forward();
                  
                  // Announce page changes for accessibility
                  switch (page) {
                    case 0:
                      _voice?.announceScreen('Welcome to FamilyBridge');
                      break;
                    case 1:
                      _voice?.announceScreen('Choose your role');
                      break;
                    case 2:
                      _voice?.announceScreen('Get started');
                      break;
                  }
                },
                children: [
                  // Page 1: Welcome
                  _buildWelcomePage(textTheme),
                  
                  // Page 2: Role selection
                  _buildRoleSelectionPage(textTheme),
                  
                  // Page 3: Get started
                  _buildGetStartedPage(textTheme),
                ],
              ),
            ),
            
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    OutlinedButton(
                      onPressed: _previousPage,
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox.shrink(),
                  
                  ElevatedButton(
                    onPressed: _currentPage == 1 && _selectedRole == null 
                        ? null 
                        : _nextPage,
                    child: Text(_currentPage == 2 ? 'Get Started' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage(TextTheme textTheme) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.family_restroom,
              size: 120,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 32),
            Text(
              'Welcome to\nFamilyBridge',
              style: textTheme.displayMedium?.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Connecting families across generations with care coordination, health monitoring, and communication.',
              style: textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildFeatureItem(
                      Icons.health_and_safety,
                      'Health Monitoring',
                      'Track medications, vitals, and daily check-ins',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      Icons.chat,
                      'Family Communication',
                      'Stay connected with voice messages and chat',
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      Icons.calendar_today,
                      'Care Coordination',
                      'Manage appointments and care schedules',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelectionPage(TextTheme textTheme) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'I am a...',
              style: textTheme.displaySmall?.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose your role to personalize your experience',
              style: textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            ...UserRole.values.map((role) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildRoleCard(role, textTheme),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildGetStartedPage(TextTheme textTheme) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getRoleIcon(_selectedRole!),
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Perfect!',
              style: textTheme.displaySmall?.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'re set up as a ${_getRoleLabel(_selectedRole!)}',
              style: textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'What\'s next:',
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ..._getRoleNextSteps(_selectedRole!).map(
                      (step) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 20,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(step)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(description, style: const TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard(UserRole role, TextTheme textTheme) {
    final isSelected = _selectedRole == role;
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      child: InkWell(
        onTap: () {
          setState(() => _selectedRole = role);
          _voice?.announceAction('Selected ${_getRoleLabel(role)}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getRoleColor(role).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getRoleIcon(role),
                  color: _getRoleColor(role),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getRoleLabel(role),
                      style: textTheme.titleMedium?.copyWith(
                        color: isSelected ? Theme.of(context).primaryColor : null,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getRoleDescription(role),
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
            ],
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

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.elder:
        return Colors.blue;
      case UserRole.caregiver:
        return Colors.teal;
      case UserRole.youth:
        return Colors.purple;
    }
  }

  List<String> _getRoleNextSteps(UserRole role) {
    switch (role) {
      case UserRole.elder:
        return [
          'Create your account with large text support',
          'Set up your health profile and medications',
          'Connect with family caregivers',
          'Learn voice commands for easy navigation',
        ];
      case UserRole.caregiver:
        return [
          'Create your caregiver account',
          'Set up family group or join existing one',
          'Configure health monitoring for family members',
          'Set up alerts and notifications',
        ];
      case UserRole.youth:
        return [
          'Create your account',
          'Join your family group',
          'Set up communication preferences',
          'Learn how to stay connected with family',
        ];
    }
  }
}