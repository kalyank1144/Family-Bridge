import 'package:flutter/material.dart';
import 'package:family_bridge/config/app_config.dart';
import 'package:family_bridge/routes/app_routes.dart';
import 'package:family_bridge/widgets/youth/care_points_card.dart';
import 'package:family_bridge/widgets/youth/youth_action_card.dart';

class YouthHomeScreen extends StatelessWidget {
  const YouthHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConfig.youthBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppConfig.youthPrimaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'FamilyBridge',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CarePointsCard(
                points: 1250,
                level: 5,
                nextLevelPoints: 1500,
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'Family Members',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              _buildFamilyMemberCard(
                'Grandpa Robert',
                'Last active: 2 hours ago',
                '😊',
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              YouthActionCard(
                icon: Icons.mic,
                title: 'Record a Story',
                subtitle: 'Share your day with family',
                color: AppConfig.youthPrimaryColor,
                points: 50,
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.youthStoryTime);
                },
              ),
              
              const SizedBox(height: 12),
              
              YouthActionCard(
                icon: Icons.photo_camera,
                title: 'Share Photos',
                subtitle: 'Send pictures to your family',
                color: AppConfig.primaryColor,
                points: 30,
                onTap: () {},
              ),
              
              const SizedBox(height: 12),
              
              YouthActionCard(
                icon: Icons.games,
                title: 'Play Games',
                subtitle: 'Fun cognitive games together',
                color: AppConfig.elderPrimaryColor,
                points: 40,
                onTap: () {},
              ),
              
              const SizedBox(height: 12),
              
              YouthActionCard(
                icon: Icons.message,
                title: 'Family Chat',
                subtitle: 'Connect with everyone',
                color: AppConfig.warningColor,
                points: 20,
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.familyChat);
                },
              ),
              
              const SizedBox(height: 12),
              
              YouthActionCard(
                icon: Icons.support_agent,
                title: 'Tech Help',
                subtitle: 'Help family with technology',
                color: AppConfig.secondaryColor,
                points: 60,
                onTap: () {},
              ),
              
              const SizedBox(height: 24),
              
              Text(
                'Recent Achievements',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildAchievementCard(
                      '🌟',
                      'Story Teller',
                      '10 stories shared',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAchievementCard(
                      '📸',
                      'Memory Maker',
                      '25 photos shared',
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

  Widget _buildFamilyMemberCard(String name, String status, String emoji) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppConfig.elderPrimaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () {},
            color: AppConfig.elderPrimaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(String emoji, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConfig.youthPrimaryColor.withOpacity(0.2),
            AppConfig.primaryColor.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppConfig.youthPrimaryColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
