import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:family_bridge/features/trial_management/models/subscription_model.dart';
import 'package:family_bridge/features/trial_management/providers/subscription_provider.dart';

class FamilyImpactWidget extends ConsumerWidget {
  const FamilyImpactWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(subscriptionProvider);
    
    return subscription.when(
      data: (sub) => _buildFamilyImpact(context, sub),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildFamilyImpact(BuildContext context, SubscriptionModel subscription) {
    final theme = Theme.of(context);
    final isElder = subscription.userType == UserType.elder;
    final familyMembers = subscription.connectedFamilyMembers;
    
    if (familyMembers.isEmpty) {
      return _buildEmptyState(context, isElder);
    }
    
    final impactMetrics = _calculateFamilyImpact(subscription);
    
    return Container(
      margin: EdgeInsets.all(isElder ? 20 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade50,
            Colors.blue.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isElder ? 24 : 20),
        border: Border.all(
          color: Colors.purple.shade200.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(isElder ? 24 : 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.shade400,
                  Colors.blue.shade400,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isElder ? 24 : 20),
                topRight: Radius.circular(isElder ? 24 : 20),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.family_restroom,
                  color: Colors.white,
                  size: isElder ? 48 : 40,
                ),
                SizedBox(height: isElder ? 12 : 8),
                Text(
                  'Family Impact Score',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isElder ? 22 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isElder ? 8 : 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ...List.generate(5, (index) {
                      return Icon(
                        index < impactMetrics['score']
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: isElder ? 32 : 28,
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          
          // Family members
          Padding(
            padding: EdgeInsets.all(isElder ? 24 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connected Family Members',
                  style: TextStyle(
                    fontSize: isElder ? 20 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isElder ? 16 : 12),
                _buildFamilyMembersGrid(familyMembers, isElder),
                SizedBox(height: isElder ? 24 : 20),
                
                // Impact metrics
                Text(
                  'Your Family Benefits',
                  style: TextStyle(
                    fontSize: isElder ? 20 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: isElder ? 16 : 12),
                _buildImpactMetrics(impactMetrics, isElder),
                
                // Emotional message
                if (subscription.status == SubscriptionStatus.trial)
                  _buildEmotionalAppeal(subscription, isElder),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyMembersGrid(List<String> members, bool isElder) {
    return Wrap(
      spacing: isElder ? 12 : 8,
      runSpacing: isElder ? 12 : 8,
      children: members.map((member) {
        final parts = member.split(' ');
        final name = parts[0];
        final relation = parts.length > 1 
            ? parts.sublist(1).join(' ').replaceAll('(', '').replaceAll(')', '')
            : '';
        
        return Container(
          padding: EdgeInsets.all(isElder ? 12 : 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isElder ? 16 : 12),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: isElder ? 28 : 24,
                backgroundColor: _getColorForRelation(relation),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isElder ? 20 : 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: isElder ? 8 : 4),
              Text(
                name,
                style: TextStyle(
                  fontSize: isElder ? 16 : 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (relation.isNotEmpty)
                Text(
                  relation,
                  style: TextStyle(
                    fontSize: isElder ? 14 : 10,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildImpactMetrics(Map<String, dynamic> metrics, bool isElder) {
    final items = [
      {
        'icon': Icons.message,
        'label': 'Messages Shared',
        'value': '${metrics['totalInteractions']}+',
        'color': Colors.blue,
      },
      {
        'icon': Icons.photo,
        'label': 'Memories Saved',
        'value': '${metrics['memoriesSaved']}',
        'color': Colors.purple,
      },
      {
        'icon': Icons.favorite,
        'label': 'Care Moments',
        'value': '${metrics['careMoments']}',
        'color': Colors.red,
      },
      {
        'icon': Icons.security,
        'label': 'Safety Checks',
        'value': '${metrics['safetyChecks']}',
        'color': Colors.green,
      },
    ];
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: isElder ? 1.8 : 2.0,
        crossAxisSpacing: isElder ? 16 : 12,
        mainAxisSpacing: isElder ? 16 : 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: EdgeInsets.all(isElder ? 16 : 12),
          decoration: BoxDecoration(
            color: (item['color'] as Color).withOpacity(0.05),
            borderRadius: BorderRadius.circular(isElder ? 16 : 12),
            border: Border.all(
              color: (item['color'] as Color).withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item['icon'] as IconData,
                color: item['color'] as Color,
                size: isElder ? 32 : 28,
              ),
              SizedBox(height: isElder ? 8 : 4),
              Text(
                item['value'] as String,
                style: TextStyle(
                  fontSize: isElder ? 24 : 20,
                  fontWeight: FontWeight.bold,
                  color: item['color'] as Color,
                ),
              ),
              Text(
                item['label'] as String,
                style: TextStyle(
                  fontSize: isElder ? 14 : 11,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmotionalAppeal(SubscriptionModel subscription, bool isElder) {
    final messages = {
      UserType.elder: [
        'Your family checks on you ${subscription.usageStats['dailyViews'] ?? 12} times a day',
        'They\'ve saved every photo and voice message you\'ve shared',
        'Your stories are becoming family treasures',
      ],
      UserType.caregiver: [
        'You\'ve prevented ${subscription.usageStats['alertsPrevented'] ?? 3} potential emergencies',
        'Your care has saved the family countless hours of worry',
        'Everyone feels more connected and secure',
      ],
      UserType.youth: [
        'You\'re the tech hero keeping everyone connected',
        'Grandparents smile every time they see your updates',
        'You\'re preserving family history for generations',
      ],
    };
    
    final userMessages = messages[subscription.userType] ?? [];
    
    return Container(
      margin: EdgeInsets.only(top: isElder ? 24 : 20),
      padding: EdgeInsets.all(isElder ? 20 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade50,
            Colors.orange.shade50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isElder ? 16 : 12),
        border: Border.all(
          color: Colors.orange.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.favorite,
            color: Colors.orange.shade600,
            size: isElder ? 36 : 32,
          ),
          SizedBox(height: isElder ? 12 : 8),
          Text(
            'Your Impact Matters',
            style: TextStyle(
              fontSize: isElder ? 20 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade800,
            ),
          ),
          SizedBox(height: isElder ? 12 : 8),
          ...userMessages.map((message) => Padding(
            padding: EdgeInsets.only(bottom: isElder ? 8 : 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.orange.shade600,
                  size: isElder ? 20 : 16,
                ),
                SizedBox(width: isElder ? 8 : 6),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: isElder ? 16 : 13,
                      color: Colors.orange.shade800,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isElder) {
    return Container(
      padding: EdgeInsets.all(isElder ? 32 : 24),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: isElder ? 64 : 56,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: isElder ? 16 : 12),
          Text(
            'Connect Your Family',
            style: TextStyle(
              fontSize: isElder ? 22 : 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: isElder ? 8 : 4),
          Text(
            'Invite family members to start sharing moments together',
            style: TextStyle(
              fontSize: isElder ? 16 : 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _calculateFamilyImpact(SubscriptionModel subscription) {
    final stats = subscription.usageStats;
    final familySize = subscription.connectedFamilyMembers.length;
    
    // Calculate impact score (1-5)
    int score = 1;
    if (familySize >= 3) score++;
    if ((stats['photosUploaded'] ?? 0) > 50) score++;
    if ((stats['voiceMessages'] ?? 0) > 20) score++;
    if ((stats['dailyCheckIns'] ?? 0) > 20) score++;
    
    return {
      'score': score.clamp(1, 5),
      'totalInteractions': (stats['voiceMessages'] ?? 0) + 
                          (stats['photosUploaded'] ?? 0) * 2 +
                          (stats['dailyCheckIns'] ?? 0),
      'memoriesSaved': stats['photosUploaded'] ?? 0,
      'careMoments': stats['dailyCheckIns'] ?? 0,
      'safetyChecks': (stats['emergencyContacts'] ?? 0) * familySize,
    };
  }

  Color _getColorForRelation(String relation) {
    final relationLower = relation.toLowerCase();
    if (relationLower.contains('daughter') || relationLower.contains('son')) {
      return Colors.blue.shade400;
    } else if (relationLower.contains('grand')) {
      return Colors.purple.shade400;
    } else if (relationLower.contains('caregiver')) {
      return Colors.green.shade400;
    } else if (relationLower.contains('spouse') || relationLower.contains('partner')) {
      return Colors.red.shade400;
    } else {
      return Colors.orange.shade400;
    }
  }
}