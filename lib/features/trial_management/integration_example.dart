import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:family_bridge/features/trial_management/widgets/trial_countdown_widget.dart';
import 'package:family_bridge/features/trial_management/widgets/usage_statistics_widget.dart';
import 'package:family_bridge/features/trial_management/widgets/upgrade_prompt_widget.dart';
import 'package:family_bridge/features/trial_management/triggers/storage_upgrade_trigger.dart';
import 'package:family_bridge/features/trial_management/triggers/health_upgrade_trigger.dart';
import 'package:family_bridge/features/trial_management/models/subscription_model.dart';
import 'package:family_bridge/features/trial_management/providers/subscription_provider.dart';

/// Example integration for Elder Dashboard
class ElderDashboardWithTrial extends ConsumerWidget {
  const ElderDashboardWithTrial({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Family',
          style: TextStyle(fontSize: 28),
        ),
      ),
      body: subscription.when(
        data: (sub) => SingleChildScrollView(
          child: Column(
            children: [
              // Trial countdown at the top
              if (sub.status == SubscriptionStatus.trial)
                const TrialCountdownWidget(),
              
              // Main dashboard content
              _buildDashboardContent(context, ref, sub),
              
              // Usage statistics
              if (sub.status == SubscriptionStatus.trial &&
                  sub.daysRemaining <= 14)
                const UsageStatisticsWidget(showFullStats: false),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    WidgetRef ref,
    SubscriptionModel subscription,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Photo sharing with trigger
          _buildPhotoSharingCard(context, ref, subscription),
          const SizedBox(height: 20),
          
          // Health monitoring with trigger
          _buildHealthCard(context, ref, subscription),
          const SizedBox(height: 20),
          
          // Emergency contacts with trigger
          _buildEmergencyContactsCard(context, ref, subscription),
        ],
      ),
    );
  }

  Widget _buildPhotoSharingCard(
    BuildContext context,
    WidgetRef ref,
    SubscriptionModel subscription,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () async {
          // Check storage limit before allowing upload
          final currentStorage = subscription.usageStats['storageUsedGB'] ?? 0.0;
          
          if (StorageUpgradeTrigger.shouldTrigger(
            currentStorageGB: currentStorage,
            status: subscription.status,
          )) {
            StorageUpgradeTrigger.showStorageLimitDialog(
              context: context,
              subscription: subscription,
              fileName: 'family_photo.jpg',
              fileSize: 2.5,
              onUpgrade: () {
                // Track conversion event
                ref.read(conversionEventsProvider.notifier)
                    .trackUpgradeTrigger('storage_limit');
                Navigator.pushNamed(context, '/upgrade');
              },
            );
          } else {
            // Proceed with photo upload
            Navigator.pushNamed(context, '/photo-upload');
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.photo_camera,
                size: 48,
                color: Colors.purple.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'Share Photos',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${subscription.usageStats['photosUploaded'] ?? 0} photos shared',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthCard(
    BuildContext context,
    WidgetRef ref,
    SubscriptionModel subscription,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () {
          // Check if trying to access premium feature
          if (subscription.status != SubscriptionStatus.active) {
            HealthUpgradeTrigger.showHealthFeatureDialog(
              context: context,
              subscription: subscription,
              featureName: 'Health Trends',
              onUpgrade: () {
                ref.read(conversionEventsProvider.notifier)
                    .trackUpgradeTrigger('health_analytics');
                Navigator.pushNamed(context, '/upgrade');
              },
            );
          } else {
            Navigator.pushNamed(context, '/health-monitoring');
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.favorite,
                size: 48,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'Health Check',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (subscription.status != SubscriptionStatus.active)
                    Icon(
                      Icons.lock_outline,
                      size: 16,
                      color: Colors.orange.shade600,
                    ),
                  const SizedBox(width: 4),
                  Text(
                    subscription.status == SubscriptionStatus.active
                        ? 'View trends & insights'
                        : 'Upgrade for insights',
                    style: TextStyle(
                      fontSize: 16,
                      color: subscription.status == SubscriptionStatus.active
                          ? Colors.grey.shade600
                          : Colors.orange.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyContactsCard(
    BuildContext context,
    WidgetRef ref,
    SubscriptionModel subscription,
  ) {
    final contactCount = subscription.usageStats['emergencyContacts'] ?? 3;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/emergency-contacts'),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.emergency,
                size: 48,
                color: Colors.green.shade400,
              ),
              const SizedBox(height: 16),
              const Text(
                'Emergency Contacts',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$contactCount contacts added',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Example integration for Caregiver Dashboard
class CaregiverDashboardWithTrial extends ConsumerWidget {
  const CaregiverDashboardWithTrial({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);

    return Scaffold(
      body: subscription.when(
        data: (sub) => Stack(
          children: [
            // Main content
            _buildDashboard(context, ref, sub),
            
            // Floating upgrade prompt for trial users
            if (sub.status == SubscriptionStatus.trial &&
                sub.daysRemaining <= 7)
              const UpgradePromptWidget(
                title: 'Upgrade for Advanced Monitoring',
                message: 'Get AI-powered health insights and save 2+ hours per week',
                icon: Icons.analytics,
                color: Colors.deepPurple,
                isFloating: true,
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    WidgetRef ref,
    SubscriptionModel subscription,
  ) {
    return CustomScrollView(
      slivers: [
        // App bar with trial badge
        SliverAppBar(
          expandedHeight: 120,
          floating: false,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Row(
              children: [
                const Text('Care Dashboard'),
                if (subscription.status == SubscriptionStatus.trial)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'TRIAL',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple.shade400,
                    Colors.deepPurple.shade600,
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // Trial countdown
        if (subscription.status == SubscriptionStatus.trial)
          const SliverToBoxAdapter(
            child: TrialCountdownWidget(),
          ),
        
        // Professional metrics
        SliverToBoxAdapter(
          child: _buildProfessionalMetrics(context, ref, subscription),
        ),
      ],
    );
  }

  Widget _buildProfessionalMetrics(
    BuildContext context,
    WidgetRef ref,
    SubscriptionModel subscription,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ROI Calculator
          Card(
            child: ListTile(
              leading: const Icon(Icons.calculate),
              title: const Text('ROI Calculator'),
              subtitle: const Text('See how premium saves you time'),
              trailing: subscription.status == SubscriptionStatus.active
                  ? const Text(
                      '2.5 hrs/week saved',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : const Icon(Icons.lock_outline),
              onTap: () {
                if (subscription.status != SubscriptionStatus.active) {
                  ref.read(conversionEventsProvider.notifier)
                      .trackUpgradeView('roi_calculator');
                  Navigator.pushNamed(context, '/upgrade');
                }
              },
            ),
          ),
          
          // Advanced reports
          Card(
            child: ListTile(
              leading: const Icon(Icons.assessment),
              title: const Text('Professional Reports'),
              subtitle: const Text('Export PDF reports for consultations'),
              trailing: subscription.status == SubscriptionStatus.active
                  ? const Icon(Icons.arrow_forward)
                  : const Icon(Icons.lock_outline),
              onTap: () {
                if (subscription.status != SubscriptionStatus.active) {
                  HealthUpgradeTrigger.showHealthFeatureDialog(
                    context: context,
                    subscription: subscription,
                    featureName: 'Professional Reports',
                    onUpgrade: () {
                      Navigator.pushNamed(context, '/upgrade');
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Example integration for Youth Dashboard
class YouthDashboardWithTrial extends ConsumerWidget {
  const YouthDashboardWithTrial({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);

    return Scaffold(
      body: subscription.when(
        data: (sub) => _buildYouthDashboard(context, ref, sub),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildYouthDashboard(
    BuildContext context,
    WidgetRef ref,
    SubscriptionModel subscription,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.purple.shade300,
            Colors.blue.shade400,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Gamified header with points
            _buildGamifiedHeader(subscription),
            
            // Trial status with modern design
            if (subscription.status == SubscriptionStatus.trial)
              _buildModernTrialStatus(subscription),
            
            // Main content
            Expanded(
              child: _buildYouthContent(context, ref, subscription),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGamifiedHeader(SubscriptionModel subscription) {
    final points = (subscription.usageStats['carePoints'] ?? 0) as int;
    final level = (points / 100).floor() + 1;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Family Hero',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Level $level',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  '$points pts',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTrialStatus(SubscriptionModel subscription) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.orange, Colors.deepOrange],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.rocket_launch,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${subscription.daysRemaining} days of premium left',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Keep being the family tech hero!',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/upgrade'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  Widget _buildYouthContent(
    BuildContext context,
    WidgetRef ref,
    SubscriptionModel subscription,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: const Center(
        child: Text('Youth Dashboard Content'),
      ),
    );
  }
}