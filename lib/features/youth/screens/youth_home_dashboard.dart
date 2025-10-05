import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'achievements_screen.dart';
import 'package:family_bridge/features/chat/screens/family_chat_screen.dart';
import 'package:family_bridge/features/youth/providers/youth_provider.dart';
import 'package:family_bridge/features/youth/widgets/achievement_badge.dart';
import 'package:family_bridge/features/youth/widgets/care_points_display.dart';
import 'package:family_bridge/features/youth/widgets/family_avatar_row.dart';
import 'package:family_bridge/features/youth/widgets/leaderboard_widget.dart';
import 'package:family_bridge/features/youth/widgets/youth_action_card.dart';
import 'photo_sharing_screen.dart';
import 'story_recording_screen.dart';
import 'tech_help_screen.dart';
import 'youth_games_screen.dart';

class YouthHomeDashboard extends StatelessWidget {
  const YouthHomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => YouthProvider()..initialize(),
      child: const _Content(),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<YouthProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with app title and care points
              _buildHeader(p),
              const SizedBox(height: 24),
              
              // Family members status cards
              _buildFamilySection(p),
              const SizedBox(height: 24),
              
              // Main action buttons grid
              _buildActionGrid(context),
              const SizedBox(height: 32),
              
              // Recent achievements and leaderboard row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildAchievementsSection(p)),
                  const SizedBox(width: 20),
                  Expanded(child: _buildLeaderboardSection(p)),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(YouthProvider p) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Youth Engagement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2D3748),
                ),
              ),
              Text(
                'FamilyBridge',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AchievementsScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text('Badges', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFB74D), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF9800),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          '✦',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Care points',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${p.points}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFamilySection(YouthProvider p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: p.family.map((member) => _buildFamilyMemberCard(member)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFamilyMemberCard(dynamic member) {
    final isOnline = member.isOnline ?? false;
    final statusColor = isOnline ? const Color(0xFF10B981) : Colors.grey[400];
    final avatarColor = _getAvatarColor(member.name);
    
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: avatarColor,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: avatarColor[0].withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    member.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: isOnline 
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            member.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getAvatarColor(String name) {
    final colors = [
      [const Color(0xFF81E6D9), const Color(0xFF4FD1C7)],
      [const Color(0xFF90CDF4), const Color(0xFF63B3ED)],
      [const Color(0xFF9F7AEA), const Color(0xFF805AD5)],
      [const Color(0xFFFBB6CE), const Color(0xFFF687B3)],
    ];
    return colors[name.hashCode % colors.length];
  }

  Widget _buildActionGrid(BuildContext context) {
    final actions = [
      {
        'title': 'Record\nStory',
        'icon': Icons.mic,
        'colors': [const Color(0xFFFF8A00), const Color(0xFFFF5E62)],
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoryRecordingScreen())),
      },
      {
        'title': 'Share\nPhotos',
        'icon': Icons.camera_alt,
        'colors': [const Color(0xFF4F46E5), const Color(0xFF7C3AED)],
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PhotoSharingScreen())),
      },
      {
        'title': 'Play\nGames',
        'icon': Icons.sports_esports,
        'colors': [const Color(0xFF10B981), const Color(0xFF059669)],
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const YouthGamesScreen())),
      },
      {
        'title': 'Tech\nHelp',
        'icon': Icons.build,
        'colors': [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TechHelpScreen())),
      },
    ];

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: actions.map((action) => _buildActionCard(
        title: action['title'] as String,
        icon: action['icon'] as IconData,
        colors: action['colors'] as List<Color>,
        onTap: action['onTap'] as VoidCallback,
      )).toList(),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colors[0].withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsSection(YouthProvider p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Achievements',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: p.achievements.take(2).map((achievement) => 
            _buildAchievementItem(achievement)
          ).toList(),
        ),
      ],
    );
  }

  Widget _buildAchievementItem(dynamic achievement) {
    final isUnlocked = achievement.unlockedAt != null;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked ? const Color(0xFFFFF3E0) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked ? const Color(0xFFFFB74D) : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isUnlocked ? const Color(0xFFFF9800) : Colors.grey[400],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                achievement.icon,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isUnlocked ? const Color(0xFF2D3748) : Colors.grey[600],
                  ),
                ),
                Text(
                  '${achievement.points} pts',
                  style: TextStyle(
                    fontSize: 12,
                    color: isUnlocked ? const Color(0xFF8B4513) : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardSection(YouthProvider p) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Leaderboard',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: p.leaderboard.take(3).map((entry) => 
              _buildLeaderboardItem(entry, p.leaderboard.indexOf(entry) + 1)
            ).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(dynamic entry, int position) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: position == 1 ? const Color(0xFFFFD700) : 
                     position == 2 ? const Color(0xFFC0C0C0) : 
                     position == 3 ? const Color(0xFFCD7F32) : 
                     Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$position',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            entry.avatar,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
          ),
          Text(
            '${entry.points}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}