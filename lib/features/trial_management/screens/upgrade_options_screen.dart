import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:family_bridge/features/trial_management/models/subscription_model.dart';
import 'package:family_bridge/features/trial_management/providers/subscription_provider.dart';
import 'package:family_bridge/features/trial_management/services/payment_service.dart';
import 'payment_flow_screen.dart';

class UpgradeOptionsScreen extends ConsumerStatefulWidget {
  const UpgradeOptionsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<UpgradeOptionsScreen> createState() => _UpgradeOptionsScreenState();
}

class _UpgradeOptionsScreenState extends ConsumerState<UpgradeOptionsScreen> 
    with TickerProviderStateMixin {
  SubscriptionPlan? selectedPlan = SubscriptionPlan.monthly;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subscription = ref.watch(subscriptionProvider);
    
    return subscription.when(
      data: (sub) => _buildUpgradeOptions(context, sub),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const Scaffold(
        body: Center(child: Text('Error loading subscription data')),
      ),
    );
  }

  Widget _buildUpgradeOptions(BuildContext context, SubscriptionModel subscription) {
    final theme = Theme.of(context);
    final isElder = subscription.userType == UserType.elder;
    final isYouth = subscription.userType == UserType.youth;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          isElder ? 'Choose Your Plan' : 'Upgrade to Premium',
          style: TextStyle(fontSize: isElder ? 24 : 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.onBackground,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isElder ? 24 : 16),
          child: Column(
            children: [
              // Header message
              _buildHeaderMessage(subscription),
              SizedBox(height: isElder ? 32 : 24),
              
              // Plan options
              _buildPlanOption(
                context,
                plan: SubscriptionPlan.monthly,
                title: 'Monthly',
                price: '\$9.99',
                period: 'per month',
                description: 'Perfect for trying out premium features',
                features: [
                  'Unlimited storage',
                  'All premium features',
                  'Priority support',
                  'Cancel anytime',
                ],
                isPopular: false,
                isElder: isElder,
                isYouth: isYouth,
              ),
              SizedBox(height: isElder ? 20 : 16),
              
              _buildPlanOption(
                context,
                plan: SubscriptionPlan.annual,
                title: 'Annual',
                price: '\$99.99',
                period: 'per year',
                description: 'Best value - Save \$20!',
                features: [
                  'Everything in Monthly',
                  'Save 17% (2 months free!)',
                  'Priority family support',
                  'Advanced health analytics',
                ],
                isPopular: true,
                isElder: isElder,
                isYouth: isYouth,
              ),
              
              SizedBox(height: isElder ? 32 : 24),
              
              // Trust badges
              _buildTrustBadges(isElder),
              
              SizedBox(height: isElder ? 32 : 24),
              
              // Continue button
              _buildContinueButton(context, subscription),
              
              SizedBox(height: isElder ? 20 : 16),
              
              // Money-back guarantee
              _buildGuarantee(isElder),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderMessage(SubscriptionModel subscription) {
    final isElder = subscription.userType == UserType.elder;
    final familyCount = subscription.connectedFamilyMembers.length;
    
    return Container(
      padding: EdgeInsets.all(isElder ? 20 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.purple.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isElder ? 20 : 16),
        border: Border.all(
          color: Colors.blue.shade200.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.family_restroom,
            size: isElder ? 56 : 48,
            color: Colors.blue.shade600,
          ),
          SizedBox(height: isElder ? 16 : 12),
          Text(
            'One Subscription, Whole Family Protected',
            style: TextStyle(
              fontSize: isElder ? 22 : 18,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isElder ? 12 : 8),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isElder ? 16 : 12,
              vertical: isElder ? 8 : 6,
            ),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '✓ Covers all $familyCount family members',
              style: TextStyle(
                fontSize: isElder ? 16 : 14,
                color: Colors.green.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanOption(
    BuildContext context, {
    required SubscriptionPlan plan,
    required String title,
    required String price,
    required String period,
    required String description,
    required List<String> features,
    required bool isPopular,
    required bool isElder,
    required bool isYouth,
  }) {
    final isSelected = selectedPlan == plan;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPlan = plan;
        });
        if (isSelected) {
          _animationController.forward().then((_) {
            _animationController.reverse();
          });
        }
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: isSelected ? _scaleAnimation.value : 1.0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(isElder ? 24 : 16),
                border: Border.all(
                  color: isSelected
                      ? Colors.blue
                      : Colors.grey.shade200,
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                ],
              ),
              child: Stack(
                children: [
                  if (isPopular)
                    Positioned(
                      top: 0,
                      right: isElder ? 20 : 16,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isElder ? 16 : 12,
                          vertical: isElder ? 8 : 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.orange, Colors.deepOrange],
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Text(
                          'BEST VALUE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isElder ? 14 : 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.all(isElder ? 24 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (isSelected)
                              Container(
                                width: isElder ? 32 : 28,
                                height: isElder ? 32 : 28,
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: isElder ? 20 : 18,
                                ),
                              )
                            else
                              Container(
                                width: isElder ? 32 : 28,
                                height: isElder ? 32 : 28,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 2,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            SizedBox(width: isElder ? 16 : 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: isElder ? 22 : 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  description,
                                  style: TextStyle(
                                    fontSize: isElder ? 16 : 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  price,
                                  style: TextStyle(
                                    fontSize: isElder ? 28 : 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                Text(
                                  period,
                                  style: TextStyle(
                                    fontSize: isElder ? 14 : 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: isElder ? 20 : 16),
                        ...features.map((feature) => Padding(
                          padding: EdgeInsets.only(bottom: isElder ? 12 : 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                color: Colors.green,
                                size: isElder ? 24 : 20,
                              ),
                              SizedBox(width: isElder ? 12 : 8),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: TextStyle(
                                    fontSize: isElder ? 18 : 14,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrustBadges(bool isElder) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildTrustBadge(
          Icons.lock_rounded,
          'Secure',
          'Bank-level encryption',
          isElder,
        ),
        _buildTrustBadge(
          Icons.verified_user_rounded,
          'HIPAA',
          'Compliant',
          isElder,
        ),
        _buildTrustBadge(
          Icons.support_agent_rounded,
          '24/7',
          'Support',
          isElder,
        ),
      ],
    );
  }

  Widget _buildTrustBadge(IconData icon, String title, String subtitle, bool isElder) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isElder ? 12 : 10),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.blue.shade600,
            size: isElder ? 28 : 24,
          ),
        ),
        SizedBox(height: isElder ? 8 : 6),
        Text(
          title,
          style: TextStyle(
            fontSize: isElder ? 16 : 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: isElder ? 14 : 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton(BuildContext context, SubscriptionModel subscription) {
    final isElder = subscription.userType == UserType.elder;
    
    return SizedBox(
      width: double.infinity,
      height: isElder ? 70 : 56,
      child: ElevatedButton(
        onPressed: selectedPlan == null
            ? null
            : () => _navigateToPayment(context, subscription),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isElder ? 16 : 12),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_rounded,
              size: isElder ? 28 : 24,
            ),
            SizedBox(width: isElder ? 12 : 8),
            Text(
              'Continue Securely',
              style: TextStyle(
                fontSize: isElder ? 22 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuarantee(bool isElder) {
    return Container(
      padding: EdgeInsets.all(isElder ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(isElder ? 12 : 8),
        border: Border.all(
          color: Colors.green.shade200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified_rounded,
            color: Colors.green.shade700,
            size: isElder ? 28 : 24,
          ),
          SizedBox(width: isElder ? 12 : 8),
          Text(
            '30-Day Money-Back Guarantee',
            style: TextStyle(
              fontSize: isElder ? 18 : 14,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade800,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToPayment(BuildContext context, SubscriptionModel subscription) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentFlowScreen(
          subscription: subscription,
          selectedPlan: selectedPlan!,
        ),
      ),
    );
  }
}