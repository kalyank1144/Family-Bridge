import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../models/subscription_model.dart';

class SubscriptionSuccessScreen extends StatefulWidget {
  final SubscriptionModel subscription;
  final SubscriptionPlan plan;

  const SubscriptionSuccessScreen({
    Key? key,
    required this.subscription,
    required this.plan,
  }) : super(key: key);

  @override
  State<SubscriptionSuccessScreen> createState() => _SubscriptionSuccessScreenState();
}

class _SubscriptionSuccessScreenState extends State<SubscriptionSuccessScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _checkAnimationController;
  late AnimationController _textAnimationController;
  late Animation<double> _checkAnimation;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _checkAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _textAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _checkAnimation = CurvedAnimation(
      parent: _checkAnimationController,
      curve: Curves.elasticOut,
    );
    _textAnimation = CurvedAnimation(
      parent: _textAnimationController,
      curve: Curves.easeInOut,
    );
    
    _playSuccessAnimation();
  }

  void _playSuccessAnimation() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _confettiController.play();
    _checkAnimationController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _textAnimationController.forward();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _checkAnimationController.dispose();
    _textAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isElder = widget.subscription.userType == UserType.elder;
    final isYouth = widget.subscription.userType == UserType.youth;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.shade50,
                  Colors.white,
                  Colors.purple.shade50,
                ],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isElder ? 32 : 24),
              child: Column(
                children: [
                  SizedBox(height: isElder ? 40 : 20),
                  // Success checkmark
                  ScaleTransition(
                    scale: _checkAnimation,
                    child: Container(
                      width: isElder ? 120 : 100,
                      height: isElder ? 120 : 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.green, Colors.lightGreen],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: isElder ? 80 : 60,
                      ),
                    ),
                  ),
                  SizedBox(height: isElder ? 32 : 24),
                  // Success message
                  FadeTransition(
                    opacity: _textAnimation,
                    child: Column(
                      children: [
                        Text(
                          _getSuccessTitle(),
                          style: TextStyle(
                            fontSize: isElder ? 32 : 28,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: isElder ? 16 : 12),
                        Text(
                          _getSuccessMessage(),
                          style: TextStyle(
                            fontSize: isElder ? 20 : 16,
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isElder ? 40 : 32),
                  // Features unlocked
                  FadeTransition(
                    opacity: _textAnimation,
                    child: _buildFeaturesUnlocked(isElder),
                  ),
                  SizedBox(height: isElder ? 40 : 32),
                  // Next steps
                  FadeTransition(
                    opacity: _textAnimation,
                    child: _buildNextSteps(context, isElder),
                  ),
                  SizedBox(height: isElder ? 32 : 24),
                  // Family notification
                  if (widget.subscription.connectedFamilyMembers.isNotEmpty)
                    FadeTransition(
                      opacity: _textAnimation,
                      child: _buildFamilyNotification(isElder),
                    ),
                ],
              ),
            ),
          ),
          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.purple,
                Colors.orange,
                Colors.pink,
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getSuccessTitle() {
    switch (widget.subscription.userType) {
      case UserType.elder:
        return 'Welcome to Premium!';
      case UserType.caregiver:
        return 'Professional Care Activated';
      case UserType.youth:
        return 'You\'re the Family Hero!';
    }
  }

  String _getSuccessMessage() {
    final familyCount = widget.subscription.connectedFamilyMembers.length;
    switch (widget.subscription.userType) {
      case UserType.elder:
        return 'Your family can now stay connected with all premium features';
      case UserType.caregiver:
        return 'Advanced monitoring and care coordination tools are now active';
      case UserType.youth:
        return 'You\'ve unlocked everything to help your $familyCount family members!';
    }
  }

  Widget _buildFeaturesUnlocked(bool isElder) {
    final features = [
      {
        'icon': Icons.cloud_outlined,
        'title': 'Unlimited Storage',
        'description': 'Save all family memories forever',
      },
      {
        'icon': Icons.people_outline,
        'title': 'Unlimited Contacts',
        'description': 'Add everyone important',
      },
      {
        'icon': Icons.analytics_outlined,
        'title': 'Advanced Analytics',
        'description': 'Deep health insights',
      },
      {
        'icon': Icons.support_agent,
        'title': 'Priority Support',
        'description': '24/7 family assistance',
      },
    ];

    return Container(
      padding: EdgeInsets.all(isElder ? 24 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade50,
            Colors.blue.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isElder ? 20 : 16),
        border: Border.all(
          color: Colors.purple.shade200.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            '✨ Everything Unlocked ✨',
            style: TextStyle(
              fontSize: isElder ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade700,
            ),
          ),
          SizedBox(height: isElder ? 20 : 16),
          ...features.map((feature) => Padding(
            padding: EdgeInsets.only(bottom: isElder ? 16 : 12),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isElder ? 12 : 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    feature['icon'] as IconData,
                    color: Colors.purple.shade600,
                    size: isElder ? 28 : 24,
                  ),
                ),
                SizedBox(width: isElder ? 16 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature['title'] as String,
                        style: TextStyle(
                          fontSize: isElder ? 18 : 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        feature['description'] as String,
                        style: TextStyle(
                          fontSize: isElder ? 16 : 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: isElder ? 28 : 24,
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildNextSteps(BuildContext context, bool isElder) {
    return Column(
      children: [
        Text(
          'What would you like to do first?',
          style: TextStyle(
            fontSize: isElder ? 22 : 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: isElder ? 20 : 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.photo_library,
                title: 'Upload Photos',
                color: Colors.purple,
                onTap: () => _navigateToPhotos(context),
                isElder: isElder,
              ),
            ),
            SizedBox(width: isElder ? 16 : 12),
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.mic,
                title: 'Record Story',
                color: Colors.orange,
                onTap: () => _navigateToStories(context),
                isElder: isElder,
              ),
            ),
          ],
        ),
        SizedBox(height: isElder ? 16 : 12),
        SizedBox(
          width: double.infinity,
          height: isElder ? 70 : 56,
          child: OutlinedButton.icon(
            onPressed: () => _navigateToDashboard(context),
            icon: Icon(
              Icons.dashboard,
              size: isElder ? 28 : 24,
            ),
            label: Text(
              'Go to Dashboard',
              style: TextStyle(
                fontSize: isElder ? 20 : 16,
              ),
            ),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isElder ? 16 : 12),
              ),
              side: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    required bool isElder,
  }) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(isElder ? 16 : 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isElder ? 16 : 12),
        child: Container(
          padding: EdgeInsets.all(isElder ? 20 : 16),
          child: Column(
            children: [
              Icon(
                icon,
                color: color,
                size: isElder ? 40 : 32,
              ),
              SizedBox(height: isElder ? 12 : 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: isElder ? 18 : 14,
                  fontWeight: FontWeight.w600,
                  color: color.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFamilyNotification(bool isElder) {
    final familyCount = widget.subscription.connectedFamilyMembers.length;
    
    return Container(
      padding: EdgeInsets.all(isElder ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(isElder ? 16 : 12),
        border: Border.all(
          color: Colors.green.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_active,
            color: Colors.green.shade700,
            size: isElder ? 32 : 28,
          ),
          SizedBox(width: isElder ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Family Notified!',
                  style: TextStyle(
                    fontSize: isElder ? 18 : 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                Text(
                  'All $familyCount family members have been notified about the upgrade',
                  style: TextStyle(
                    fontSize: isElder ? 16 : 12,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPhotos(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/photo-sharing',
      (route) => false,
    );
  }

  void _navigateToStories(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/story-recording',
      (route) => false,
    );
  }

  void _navigateToDashboard(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/dashboard',
      (route) => false,
    );
  }
}