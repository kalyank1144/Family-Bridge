import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/subscription_provider.dart';
import '../models/subscription_status.dart';
import 'trial_upgrade_screen.dart';
import 'payment_methods_screen.dart';
import 'billing_history_screen.dart';
import 'subscription_settings_screen.dart';

/// Main subscription management screen with overview and navigation
class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionManagementScreen> createState() => _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState extends State<SubscriptionManagementScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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

    // Initialize subscription data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().refresh();
    });
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
          'Subscription',
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
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(context),
            tooltip: 'Help & Support',
          ),
        ],
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && !provider.isInitialized) {
            return const _LoadingView();
          }

          if (provider.error != null && !provider.isInitialized) {
            return _ErrorView(
              error: provider.error!,
              onRetry: () => provider.refresh(),
            );
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: RefreshIndicator(
              onRefresh: () => provider.refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Subscription Status Card
                    _buildSubscriptionStatusCard(context, provider),
                    
                    const SizedBox(height: 24),

                    // Action Cards
                    _buildActionCards(context, provider),

                    const SizedBox(height: 24),

                    // Quick Stats
                    if (provider.hasActiveSubscription)
                      _buildQuickStats(context, provider),

                    const SizedBox(height: 100), // Bottom padding for FAB
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: Consumer<SubscriptionProvider>(
        builder: (context, provider, child) {
          if (provider.isTrialActive && provider.isTrialEnding) {
            return FloatingActionButton.extended(
              onPressed: () => _navigateToTrialUpgrade(context),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.upgrade),
              label: const Text('Upgrade Now'),
              elevation: 4,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSubscriptionStatusCard(BuildContext context, SubscriptionProvider provider) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: _getStatusGradient(provider),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(provider),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.subscriptionStatusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusDescription(provider),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (provider.isTrialActive) ...[
              const SizedBox(height: 20),
              _buildTrialProgress(provider),
            ],

            if (provider.nextBillingDate != null && provider.isPremiumActive) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: Colors.white.withOpacity(0.8),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Next billing: ${_formatDate(provider.nextBillingDate!)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrialProgress(SubscriptionProvider provider) {
    final progress = (30 - provider.trialDaysRemaining) / 30;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Trial Progress',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${provider.trialDaysRemaining} days left',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          minHeight: 4,
        ),
      ],
    );
  }

  Widget _buildActionCards(BuildContext context, SubscriptionProvider provider) {
    final actions = <_ActionCard>[];

    // Trial upgrade action
    if (provider.isTrialActive) {
      actions.add(_ActionCard(
        title: 'Upgrade to Premium',
        subtitle: 'Unlock all features and unlimited family members',
        icon: Icons.upgrade,
        color: Colors.green,
        onTap: () => _navigateToTrialUpgrade(context),
        highlighted: provider.isTrialEnding,
      ));
    }

    // Payment methods
    actions.add(_ActionCard(
      title: 'Payment Methods',
      subtitle: provider.paymentMethods.isEmpty
          ? 'Add a payment method'
          : '${provider.paymentMethods.length} method${provider.paymentMethods.length != 1 ? 's' : ''} on file',
      icon: Icons.payment,
      color: Colors.blue,
      onTap: () => _navigateToPaymentMethods(context),
    ));

    // Billing history
    if (provider.hasActiveSubscription || provider.subscription != null) {
      actions.add(_ActionCard(
        title: 'Billing History',
        subtitle: 'View your past transactions and receipts',
        icon: Icons.receipt_long,
        color: Colors.orange,
        onTap: () => _navigateToBillingHistory(context),
      ));
    }

    // Subscription settings
    if (provider.hasActiveSubscription) {
      actions.add(_ActionCard(
        title: 'Subscription Settings',
        subtitle: 'Manage your subscription and preferences',
        icon: Icons.settings,
        color: Colors.purple,
        onTap: () => _navigateToSubscriptionSettings(context),
      ));
    }

    return Column(
      children: actions.map((action) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildActionCardWidget(action),
      )).toList(),
    );
  }

  Widget _buildActionCardWidget(_ActionCard action) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: action.highlighted ? 4 : 2,
      shadowColor: action.highlighted ? action.color.withOpacity(0.3) : Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: action.highlighted
                ? Border.all(color: action.color.withOpacity(0.3), width: 2)
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  action.icon,
                  color: action.color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      action.subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, SubscriptionProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Premium Features',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            icon: Icons.dashboard,
            title: 'Caregiver Dashboard',
            enabled: provider.canAccessCaregiverDashboard,
          ),
          _buildFeatureItem(
            icon: Icons.health_and_safety,
            title: 'Advanced Health Monitoring',
            enabled: provider.canUseAdvancedHealthMonitoring,
          ),
          _buildFeatureItem(
            icon: Icons.group,
            title: provider.hasUnlimitedMembers 
                ? 'Unlimited Family Members' 
                : 'Up to ${provider.maxFamilyMembers} Family Members',
            enabled: provider.canCreateFamilyGroups,
          ),
          _buildFeatureItem(
            icon: Icons.support_agent,
            title: 'Priority Support',
            enabled: provider.isPremiumActive,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required bool enabled,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle : Icons.cancel,
            color: enabled ? Colors.green : Colors.grey[400],
            size: 20,
          ),
          const SizedBox(width: 12),
          Icon(
            icon,
            color: enabled ? Colors.black87 : Colors.grey[400],
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: enabled ? Colors.black87 : Colors.grey[500],
                fontWeight: enabled ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _getStatusGradient(SubscriptionProvider provider) {
    if (provider.isPremiumActive) {
      return const LinearGradient(
        colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (provider.isTrialActive) {
      if (provider.isTrialEnding) {
        return const LinearGradient(
          colors: [Color(0xFFFF9800), Color(0xFFFF8F00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }
      return const LinearGradient(
        colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (provider.isPaymentPastDue) {
      return const LinearGradient(
        colors: [Color(0xFFF44336), Color(0xFFD32F2F)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      return LinearGradient(
        colors: [Colors.grey[600]!, Colors.grey[700]!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
  }

  IconData _getStatusIcon(SubscriptionProvider provider) {
    if (provider.isPremiumActive) return Icons.star;
    if (provider.isTrialActive) return Icons.timer;
    if (provider.isPaymentPastDue) return Icons.warning;
    if (provider.isCancelled) return Icons.cancel;
    return Icons.info;
  }

  String _getStatusDescription(SubscriptionProvider provider) {
    if (provider.isPremiumActive) {
      return 'Enjoy unlimited access to all premium features';
    } else if (provider.isTrialActive) {
      if (provider.isTrialEnding) {
        return 'Your trial ends soon. Upgrade to keep premium features.';
      }
      return 'Exploring premium features during your trial period';
    } else if (provider.isPaymentPastDue) {
      return 'Please update your payment method to continue service';
    } else if (provider.isCancelled) {
      return 'Your subscription has been cancelled';
    } else {
      return 'Start your free trial to unlock premium features';
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  void _navigateToTrialUpgrade(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TrialUpgradeScreen(),
      ),
    );
  }

  void _navigateToPaymentMethods(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PaymentMethodsScreen(),
      ),
    );
  }

  void _navigateToBillingHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const BillingHistoryScreen(),
      ),
    );
  }

  void _navigateToSubscriptionSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SubscriptionSettingsScreen(),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subscription Help'),
        content: const Text(
          'Need help with your subscription? Contact our support team at support@familybridge.com or visit our help center for detailed guides.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Open support contact
            },
            child: const Text('Contact Support'),
          ),
        ],
      ),
    );
  }
}

class _ActionCard {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool highlighted;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.highlighted = false,
  });
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading subscription information...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load subscription information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}