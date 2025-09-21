import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/subscription_provider.dart';
import '../models/payment_method.dart';

/// Screen for upgrading from trial to premium subscription
class TrialUpgradeScreen extends StatefulWidget {
  const TrialUpgradeScreen({Key? key}) : super(key: key);

  @override
  State<TrialUpgradeScreen> createState() => _TrialUpgradeScreenState();
}

class _TrialUpgradeScreenState extends State<TrialUpgradeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  PaymentMethodInfo? _selectedPaymentMethod;
  bool _isUpgrading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Upgrade to Premium',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[200],
          ),
        ),
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, provider, child) {
          return AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Header with trial info
                        _buildTrialInfoCard(provider),
                        
                        const SizedBox(height: 24),

                        // Premium benefits
                        _buildBenefitsSection(),
                        
                        const SizedBox(height: 24),

                        // Pricing card
                        _buildPricingCard(),
                        
                        const SizedBox(height: 24),

                        // Payment method selection
                        _buildPaymentMethodSection(provider),
                        
                        const SizedBox(height: 32),

                        // Upgrade button
                        _buildUpgradeButton(provider),
                        
                        const SizedBox(height: 16),

                        // Terms and conditions
                        _buildTermsText(),
                        
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTrialInfoCard(SubscriptionProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.timer,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            '${provider.trialDaysRemaining} Days Left',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'in your free trial',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Upgrade now to continue enjoying all features',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection() {
    final benefits = [
      _Benefit(
        icon: Icons.group_add,
        title: 'Unlimited Family Members',
        description: 'Add as many family members as you need',
        color: Colors.green,
      ),
      _Benefit(
        icon: Icons.dashboard,
        title: 'Advanced Dashboard',
        description: 'Comprehensive caregiver insights and analytics',
        color: Colors.blue,
      ),
      _Benefit(
        icon: Icons.health_and_safety,
        title: 'Health Monitoring',
        description: 'Track vitals, medications, and health trends',
        color: Colors.red,
      ),
      _Benefit(
        icon: Icons.support_agent,
        title: 'Priority Support',
        description: '24/7 customer support with priority response',
        color: Colors.purple,
      ),
      _Benefit(
        icon: Icons.backup,
        title: 'Data Backup',
        description: 'Secure cloud backup of all family data',
        color: Colors.orange,
      ),
      _Benefit(
        icon: Icons.security,
        title: 'Enhanced Security',
        description: 'Advanced encryption and privacy controls',
        color: Colors.teal,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Premium Features',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Everything you need to care for your family',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          ...benefits.asMap().entries.map((entry) {
            final index = entry.key;
            final benefit = entry.value;
            return Padding(
              padding: EdgeInsets.only(bottom: index == benefits.length - 1 ? 0 : 16),
              child: _buildBenefitItem(benefit),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(_Benefit benefit) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: benefit.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            benefit.icon,
            color: benefit.color,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                benefit.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                benefit.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPricingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4CAF50), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'BEST VALUE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\$',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                '9',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1,
                ),
              ),
              Text(
                '99',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const Text(
            'per month',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Cancel anytime • 30-day money back guarantee',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF4CAF50),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection(SubscriptionProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          if (provider.paymentMethods.isNotEmpty) ...[
            ...provider.paymentMethods.map((method) => 
              _buildPaymentMethodTile(method)),
            const SizedBox(height: 12),
          ],
          
          _buildAddPaymentMethodTile(),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(PaymentMethodInfo method) {
    final isSelected = _selectedPaymentMethod?.id == method.id;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = method;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.05) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Icon(
                _getPaymentMethodIcon(method.card?.brand ?? ''),
                size: 24,
                color: _getPaymentMethodColor(method.card?.brand ?? ''),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•••• •••• •••• ${method.card?.last4 ?? ''}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${method.card?.brand?.toUpperCase()} expires ${method.card?.expMonth}/${method.card?.expYear}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Colors.blue,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPaymentMethodTile() {
    return GestureDetector(
      onTap: () => _addPaymentMethod(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, style: BorderStyle.solid),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add,
                size: 24,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Add new payment method',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeButton(SubscriptionProvider provider) {
    final canUpgrade = _selectedPaymentMethod != null && !_isUpgrading;
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: canUpgrade ? () => _performUpgrade(provider) : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: _isUpgrading ? 0 : 4,
          shadowColor: const Color(0xFF4CAF50).withOpacity(0.3),
        ),
        child: _isUpgrading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Upgrading...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upgrade, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Upgrade to Premium',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTermsText() {
    return Text(
      'By upgrading, you agree to our Terms of Service and Privacy Policy. '
      'Your subscription will automatically renew monthly unless cancelled. '
      'You can cancel anytime in your subscription settings.',
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[600],
        height: 1.4,
      ),
      textAlign: TextAlign.center,
    );
  }

  IconData _getPaymentMethodIcon(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return Icons.credit_card;
      case 'mastercard':
        return Icons.credit_card;
      case 'amex':
      case 'american express':
        return Icons.credit_card;
      case 'discover':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  Color _getPaymentMethodColor(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return const Color(0xFF1A1F71);
      case 'mastercard':
        return const Color(0xFFEB001B);
      case 'amex':
      case 'american express':
        return const Color(0xFF006FCF);
      case 'discover':
        return const Color(0xFFFF6000);
      default:
        return Colors.grey;
    }
  }

  Future<void> _addPaymentMethod() async {
    try {
      final provider = context.read<SubscriptionProvider>();
      final success = await provider.addPaymentMethod(context);
      
      if (success && provider.paymentMethods.isNotEmpty) {
        setState(() {
          _selectedPaymentMethod = provider.paymentMethods.first;
        });
      }
    } catch (error) {
      _showErrorDialog('Failed to add payment method', error.toString());
    }
  }

  Future<void> _performUpgrade(SubscriptionProvider provider) async {
    if (_selectedPaymentMethod == null) return;
    
    setState(() {
      _isUpgrading = true;
    });

    try {
      final result = await provider.upgradeTrialToPremium(_selectedPaymentMethod!);
      
      if (result.isSuccess) {
        _showSuccessDialog();
      } else {
        _showErrorDialog('Upgrade Failed', result.message);
      }
    } catch (error) {
      _showErrorDialog('Upgrade Failed', error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isUpgrading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Welcome to Premium!'),
          ],
        ),
        content: const Text(
          'Your upgrade was successful! You now have access to all premium features and unlimited family members.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close upgrade screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
            child: const Text('Start Exploring'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 28),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Optionally trigger retry
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

class _Benefit {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _Benefit({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}