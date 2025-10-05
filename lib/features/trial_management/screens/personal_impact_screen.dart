import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:family_bridge/features/trial_management/models/subscription_model.dart';
import 'package:family_bridge/features/trial_management/providers/subscription_provider.dart';
import 'upgrade_options_screen.dart';

class PersonalImpactScreen extends ConsumerWidget {
  const PersonalImpactScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);

    return subscription.when(
      data: (sub) => _buildImpactScreen(context, sub),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const Scaffold(
        body: Center(child: Text('Error loading data')),
      ),
    );
  }

  Widget _buildImpactScreen(BuildContext context, SubscriptionModel subscription) {
    final theme = Theme.of(context);
    final isElder = subscription.userType == UserType.elder;
    final stats = subscription.usageStats;
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          isElder ? 'Your Family Memories' : 'Your FamilyBridge Impact',
          style: TextStyle(fontSize: isElder ? 24 : 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.onBackground,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero section with emotional appeal
            _buildHeroSection(context, subscription),
            
            // Personal usage statistics
            _buildDetailedStats(context, subscription),
            
            // Family dependency visualization
            _buildFamilyDependency(context, subscription),
            
            // What you'll lose section
            _buildWhatYouLoseSection(context, subscription),
            
            // Upgrade CTA
            _buildUpgradeCTA(context, subscription),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, SubscriptionModel subscription) {
    final isElder = subscription.userType == UserType.elder;
    final daysUsed = 30 - subscription.daysRemaining;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isElder ? 32 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade600,
            Colors.purple.shade600,
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            isElder ? 'You\'ve Been Amazing!' : 'Your Impact Journey',
            style: TextStyle(
              color: Colors.white,
              fontSize: isElder ? 32 : 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isElder ? 20 : 16),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isElder ? 20 : 16,
              vertical: isElder ? 10 : 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              '$daysUsed Days of Family Connection',
              style: TextStyle(
                color: Colors.white,
                fontSize: isElder ? 20 : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: isElder ? 16 : 12),
          Text(
            'Here\'s what you and your family have built together',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: isElder ? 18 : 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats(BuildContext context, SubscriptionModel subscription) {
    final isElder = subscription.userType == UserType.elder;
    final stats = subscription.usageStats;
    
    final statItems = [
      {
        'icon': Icons.photo_camera,
        'label': 'Photos Shared',
        'value': stats['photosUploaded'] ?? 0,
        'unit': 'memories',
        'color': Colors.purple,
        'impact': 'Each photo brings smiles to ${subscription.connectedFamilyMembers.length} family members',
      },
      {
        'icon': Icons.mic,
        'label': 'Voice Messages',
        'value': stats['voiceMessages'] ?? 0,
        'unit': 'messages',
        'color': Colors.blue,
        'impact': 'Your voice means everything to your family',
      },
      {
        'icon': Icons.auto_stories,
        'label': 'Stories Recorded',
        'value': stats['storiesRecorded'] ?? 0,
        'unit': 'stories',
        'color': Colors.orange,
        'impact': 'Precious family history preserved forever',
      },
      {
        'icon': Icons.favorite,
        'label': 'Health Check-ins',
        'value': stats['dailyCheckIns'] ?? 0,
        'unit': 'check-ins',
        'color': Colors.red,
        'impact': 'Your family knows you\'re safe and healthy',
      },
      {
        'icon': Icons.storage,
        'label': 'Storage Used',
        'value': stats['storageUsedGB'] ?? 0,
        'unit': 'GB',
        'color': Colors.green,
        'impact': 'Lifetime of memories safely stored',
      },
      {
        'icon': Icons.emergency,
        'label': 'Emergency Contacts',
        'value': stats['emergencyContacts'] ?? 3,
        'unit': 'contacts',
        'color': Colors.teal,
        'impact': 'Your safety net is in place',
      },
    ];
    
    return Padding(
      padding: EdgeInsets.all(isElder ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Personal Dashboard',
            style: TextStyle(
              fontSize: isElder ? 24 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isElder ? 20 : 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isElder ? 1 : 2,
              childAspectRatio: isElder ? 2.5 : 1.2,
              crossAxisSpacing: isElder ? 0 : 12,
              mainAxisSpacing: isElder ? 16 : 12,
            ),
            itemCount: statItems.length,
            itemBuilder: (context, index) {
              final stat = statItems[index];
              return _buildStatCard(
                icon: stat['icon'] as IconData,
                label: stat['label'] as String,
                value: stat['value'],
                unit: stat['unit'] as String,
                color: stat['color'] as Color,
                impact: stat['impact'] as String,
                isElder: isElder,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required dynamic value,
    required String unit,
    required Color color,
    required String impact,
    required bool isElder,
  }) {
    return Container(
      padding: EdgeInsets.all(isElder ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isElder ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(isElder ? 12 : 10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(isElder ? 12 : 10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: isElder ? 28 : 24,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value.toString(),
                    style: TextStyle(
                      fontSize: isElder ? 32 : 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: isElder ? 14 : 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: isElder ? 12 : 8),
          Text(
            label,
            style: TextStyle(
              fontSize: isElder ? 16 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: isElder ? 8 : 4),
          Text(
            impact,
            style: TextStyle(
              fontSize: isElder ? 14 : 11,
              color: Colors.grey.shade600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyDependency(BuildContext context, SubscriptionModel subscription) {
    final isElder = subscription.userType == UserType.elder;
    final familyMembers = subscription.connectedFamilyMembers;
    
    if (familyMembers.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isElder ? 24 : 16),
      padding: EdgeInsets.all(isElder ? 24 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade50,
            Colors.pink.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isElder ? 20 : 16),
        border: Border.all(
          color: Colors.orange.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.family_restroom,
            size: isElder ? 56 : 48,
            color: Colors.orange.shade600,
          ),
          SizedBox(height: isElder ? 16 : 12),
          Text(
            '${familyMembers.length} Family Members Depend on You',
            style: TextStyle(
              fontSize: isElder ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isElder ? 12 : 8),
          Wrap(
            spacing: isElder ? 12 : 8,
            runSpacing: isElder ? 12 : 8,
            alignment: WrapAlignment.center,
            children: familyMembers.take(5).map((member) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isElder ? 16 : 12,
                  vertical: isElder ? 8 : 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.orange.shade300,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: isElder ? 16 : 12,
                      backgroundColor: Colors.orange.shade100,
                      child: Icon(
                        Icons.person,
                        size: isElder ? 20 : 16,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    SizedBox(width: isElder ? 8 : 6),
                    Text(
                      member,
                      style: TextStyle(
                        fontSize: isElder ? 16 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          if (familyMembers.length > 5) ...[
            SizedBox(height: isElder ? 8 : 6),
            Text(
              'and ${familyMembers.length - 5} more...',
              style: TextStyle(
                fontSize: isElder ? 14 : 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWhatYouLoseSection(BuildContext context, SubscriptionModel subscription) {
    final isElder = subscription.userType == UserType.elder;
    
    final losses = [
      {
        'icon': Icons.photo_library,
        'title': 'All Your Photos',
        'description': 'Only last 10 photos will be kept',
        'color': Colors.red,
      },
      {
        'icon': Icons.mic_off,
        'title': 'Voice Messages',
        'description': 'Can\'t send new voice notes',
        'color': Colors.red,
      },
      {
        'icon': Icons.analytics,
        'title': 'Health Insights',
        'description': 'No trend analysis or alerts',
        'color': Colors.red,
      },
      {
        'icon': Icons.group_off,
        'title': 'Family Features',
        'description': 'Limited to 3 family members',
        'color': Colors.red,
      },
    ];
    
    return Container(
      margin: EdgeInsets.all(isElder ? 24 : 16),
      padding: EdgeInsets.all(isElder ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(isElder ? 20 : 16),
        border: Border.all(
          color: Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: isElder ? 48 : 40,
            color: Colors.red.shade600,
          ),
          SizedBox(height: isElder ? 16 : 12),
          Text(
            subscription.daysRemaining > 0
                ? 'In ${subscription.daysRemaining} days, you\'ll lose:'
                : 'Without Premium, you\'re losing:',
            style: TextStyle(
              fontSize: isElder ? 22 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isElder ? 20 : 16),
          ...losses.map((loss) => Padding(
            padding: EdgeInsets.only(bottom: isElder ? 16 : 12),
            child: Row(
              children: [
                Icon(
                  loss['icon'] as IconData,
                  color: loss['color'] as Color,
                  size: isElder ? 32 : 28,
                ),
                SizedBox(width: isElder ? 16 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loss['title'] as String,
                        style: TextStyle(
                          fontSize: isElder ? 18 : 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        loss['description'] as String,
                        style: TextStyle(
                          fontSize: isElder ? 16 : 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildUpgradeCTA(BuildContext context, SubscriptionModel subscription) {
    final isElder = subscription.userType == UserType.elder;
    
    return Container(
      padding: EdgeInsets.all(isElder ? 32 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.blue.shade50,
          ],
        ),
      ),
      child: Column(
        children: [
          Text(
            'Don\'t Lose What You\'ve Built',
            style: TextStyle(
              fontSize: isElder ? 28 : 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isElder ? 16 : 12),
          Text(
            'Keep all your family memories and connections safe',
            style: TextStyle(
              fontSize: isElder ? 18 : 14,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isElder ? 32 : 24),
          SizedBox(
            width: double.infinity,
            height: isElder ? 80 : 64,
            child: ElevatedButton(
              onPressed: () => _navigateToUpgrade(context, subscription),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isElder ? 20 : 16),
                ),
                elevation: 8,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Keep Everything - Upgrade Now',
                    style: TextStyle(
                      fontSize: isElder ? 24 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: isElder ? 4 : 2),
                  Text(
                    'Starting at \$9.99/month',
                    style: TextStyle(
                      fontSize: isElder ? 16 : 14,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: isElder ? 20 : 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Maybe Later',
              style: TextStyle(
                fontSize: isElder ? 18 : 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToUpgrade(BuildContext context, SubscriptionModel subscription) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const UpgradeOptionsScreen(),
      ),
    );
  }
}