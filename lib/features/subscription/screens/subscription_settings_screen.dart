import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:family_bridge/core/theme/app_theme.dart';
import 'package:family_bridge/features/subscription/providers/subscription_provider.dart';

/// Screen for managing subscription settings and preferences
class SubscriptionSettingsScreen extends StatefulWidget {
  const SubscriptionSettingsScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionSettingsScreen> createState() => _SubscriptionSettingsScreenState();
}

class _SubscriptionSettingsScreenState extends State<SubscriptionSettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  bool _autoRenew = true;
  bool _emailNotifications = true;
  bool _billingReminders = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Subscription Settings',
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Current subscription card
                      _buildCurrentSubscriptionCard(provider),
                      
                      const SizedBox(height: 24),

                      // Subscription preferences
                      _buildPreferencesSection(),
                      
                      const SizedBox(height: 24),

                      // Billing settings
                      _buildBillingSection(provider),
                      
                      const SizedBox(height: 24),

                      // Notifications settings
                      _buildNotificationsSection(),
                      
                      const SizedBox(height: 24),

                      // Danger zone
                      _buildDangerZoneSection(provider),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCurrentSubscriptionCard(SubscriptionProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.star,
                  color: Colors.blue[600],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Plan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      provider.isPremiumActive ? 'Family Bridge Premium' : 'Trial',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                provider.isPremiumActive ? '\$9.99/month' : 'Free',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          
          if (provider.nextBillingDate != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: Colors.grey[600],
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Next billing: ${_formatDate(provider.nextBillingDate!)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
          
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showPlanOptions(provider),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('View Plan Options'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return _buildSettingsCard(
      title: 'Subscription Preferences',
      icon: Icons.settings,
      iconColor: Colors.blue,
      children: [
        _buildSwitchTile(
          title: 'Auto-renewal',
          subtitle: 'Automatically renew your subscription each month',
          value: _autoRenew,
          onChanged: (value) {
            setState(() {
              _autoRenew = value;
            });
            _updateAutoRenewal(value);
          },
        ),
      ],
    );
  }

  Widget _buildBillingSection(SubscriptionProvider provider) {
    return _buildSettingsCard(
      title: 'Billing',
      icon: Icons.payment,
      iconColor: Colors.green,
      children: [
        _buildListTile(
          title: 'Payment Methods',
          subtitle: provider.paymentMethods.isEmpty
              ? 'No payment methods'
              : '${provider.paymentMethods.length} method${provider.paymentMethods.length != 1 ? 's' : ''} on file',
          icon: Icons.credit_card,
          onTap: () => Navigator.of(context).pop(), // Navigate back to payment methods
        ),
        _buildListTile(
          title: 'Billing History',
          subtitle: 'View past payments and receipts',
          icon: Icons.receipt,
          onTap: () => Navigator.of(context).pop(), // Navigate back to billing history
        ),
        _buildListTile(
          title: 'Tax Information',
          subtitle: 'Manage tax settings and exemptions',
          icon: Icons.assessment,
          onTap: () => _showTaxSettings(),
        ),
      ],
    );
  }

  Widget _buildNotificationsSection() {
    return _buildSettingsCard(
      title: 'Notifications',
      icon: Icons.notifications,
      iconColor: Colors.orange,
      children: [
        _buildSwitchTile(
          title: 'Email notifications',
          subtitle: 'Receive subscription updates via email',
          value: _emailNotifications,
          onChanged: (value) {
            setState(() {
              _emailNotifications = value;
            });
            _updateEmailNotifications(value);
          },
        ),
        _buildSwitchTile(
          title: 'Billing reminders',
          subtitle: 'Get notified before your next payment',
          value: _billingReminders,
          onChanged: (value) {
            setState(() {
              _billingReminders = value;
            });
            _updateBillingReminders(value);
          },
        ),
      ],
    );
  }

  Widget _buildDangerZoneSection(SubscriptionProvider provider) {
    return _buildSettingsCard(
      title: 'Danger Zone',
      icon: Icons.warning,
      iconColor: Colors.red,
      children: [
        _buildListTile(
          title: 'Pause Subscription',
          subtitle: 'Temporarily pause your subscription',
          icon: Icons.pause_circle_outline,
          onTap: () => _showPauseSubscriptionDialog(),
          textColor: Colors.orange,
        ),
        _buildListTile(
          title: 'Cancel Subscription',
          subtitle: 'Cancel your subscription and downgrade',
          icon: Icons.cancel_outlined,
          onTap: () => _showCancelSubscriptionDialog(provider),
          textColor: Colors.red,
        ),
      ],
    );
  }

  Widget _buildSettingsCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blue,
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(
        icon,
        color: textColor ?? Colors.grey[600],
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: Colors.grey[400],
        size: 16,
      ),
      onTap: onTap,
    );
  }

  void _showPlanOptions(SubscriptionProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _PlanOptionsSheet(provider: provider),
    );
  }

  void _showTaxSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tax Information'),
        content: const Text(
          'Tax settings are managed automatically based on your billing address. For tax exemptions or questions, please contact support.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Contact support
            },
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }

  void _showPauseSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.pause_circle_outline, color: Colors.orange),
            SizedBox(width: 8),
            Text('Pause Subscription'),
          ],
        ),
        content: const Text(
          'Pausing your subscription will stop billing but maintain your account. You can resume anytime within 90 days. After 90 days, your account will be cancelled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _pauseSubscription();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Pause'),
          ),
        ],
      ),
    );
  }

  void _showCancelSubscriptionDialog(SubscriptionProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Cancel Subscription'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel your subscription?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text('You will lose access to:'),
            SizedBox(height: 8),
            Text('• Unlimited family members'),
            Text('• Advanced health monitoring'),
            Text('• Caregiver dashboard'),
            Text('• Priority support'),
            SizedBox(height: 12),
            Text(
              'Your subscription will remain active until the end of the current billing period.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Keep Subscription'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cancelSubscription(provider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateAutoRenewal(bool enabled) async {
    // Update auto-renewal setting
    _showSuccessSnackbar(
      enabled ? 'Auto-renewal enabled' : 'Auto-renewal disabled'
    );
  }

  Future<void> _updateEmailNotifications(bool enabled) async {
    // Update email notification setting
    _showSuccessSnackbar(
      enabled ? 'Email notifications enabled' : 'Email notifications disabled'
    );
  }

  Future<void> _updateBillingReminders(bool enabled) async {
    // Update billing reminder setting
    _showSuccessSnackbar(
      enabled ? 'Billing reminders enabled' : 'Billing reminders disabled'
    );
  }

  Future<void> _pauseSubscription() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Implement pause subscription logic
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      
      _showSuccessDialog(
        'Subscription Paused',
        'Your subscription has been paused. You can resume it anytime from your settings.',
      );
    } catch (error) {
      _showErrorDialog('Failed to pause subscription', error.toString());
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _cancelSubscription(SubscriptionProvider provider) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final success = await provider.cancelSubscription(
        reason: 'User requested cancellation from settings',
      );
      
      if (success) {
        _showSuccessDialog(
          'Subscription Cancelled',
          'Your subscription has been cancelled. You\'ll continue to have access until ${_formatDate(provider.nextBillingDate!)}.',
        );
      } else {
        _showErrorDialog('Cancellation Failed', 'Unable to cancel subscription. Please try again or contact support.');
      }
    } catch (error) {
      _showErrorDialog('Cancellation Failed', error.toString());
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to main screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
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
            Icon(Icons.error, color: Colors.red[400]),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _PlanOptionsSheet extends StatelessWidget {
  final SubscriptionProvider provider;

  const _PlanOptionsSheet({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Choose Your Plan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Plan options
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildPlanOption(
                    title: 'Family Bridge Premium',
                    price: '\$9.99/month',
                    features: [
                      'Unlimited family members',
                      'Advanced health monitoring',
                      'Caregiver dashboard',
                      'Priority support',
                      'Data backup & sync',
                    ],
                    isSelected: provider.isPremiumActive,
                    onSelect: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildPlanOption(
                    title: 'Family Bridge Basic',
                    price: 'Free',
                    features: [
                      'Up to 5 family members',
                      'Basic health tracking',
                      'Emergency contacts',
                      'Community support',
                    ],
                    isSelected: !provider.isPremiumActive,
                    onSelect: () {
                      // Show downgrade confirmation
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanOption({
    required String title,
    required String price,
    required List<String> features,
    required bool isSelected,
    required VoidCallback onSelect,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isSelected ? Colors.blue[50] : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                price,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(
                  Icons.check,
                  size: 16,
                  color: Colors.green[600],
                ),
                const SizedBox(width: 8),
                Text(
                  feature,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          )),
          
          if (isSelected) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Current Plan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSelect,
                child: const Text('Select Plan'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}