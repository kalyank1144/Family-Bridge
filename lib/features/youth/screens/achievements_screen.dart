import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/achievements_provider.dart';
import '../../../core/services/gamification_service.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AchievementsProvider()..loadData(),
      child: const _Content(),
    );
  }
}

class _Content extends StatefulWidget {
  const _Content();

  @override
  State<_Content> createState() => _ContentState();
}

class _ContentState extends State<_Content> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _celebrationController;
  late Animation<double> _celebrationAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _celebrationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _celebrationAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.elasticOut),
    );
    _celebrationController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AchievementsProvider>();
    
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(provider),
            _buildStatsCard(provider),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAchievementsTab(provider),
                  _buildStatsTab(provider),
                  _buildLeaderboardTab(provider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AchievementsProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1B3A), Color(0xFF2D1B69)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'My Achievements',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('👑', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      'Level ${provider.level}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
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

  Widget _buildStatsCard(AchievementsProvider provider) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Points',
                '${provider.points}',
                Icons.star,
                const Color(0xFFFFD700),
              ),
              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
              _buildStatItem(
                'Streak',
                '${provider.streak}',
                Icons.local_fire_department,
                const Color(0xFFFF4444),
              ),
              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
              _buildStatItem(
                'Badges',
                '${provider.unlockedCount}/${provider.totalCount}',
                Icons.emoji_events,
                const Color(0xFF10B981),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildLevelProgress(provider),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildLevelProgress(AchievementsProvider provider) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Level ${provider.level}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              '${provider.pointsToNextLevel} pts to next level',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: provider.levelProgress,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)]),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.7),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        tabs: const [
          Tab(icon: Icon(Icons.emoji_events, size: 18), text: 'Badges'),
          Tab(icon: Icon(Icons.analytics, size: 18), text: 'Stats'),
          Tab(icon: Icon(Icons.leaderboard, size: 18), text: 'Ranking'),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab(AchievementsProvider provider) {
    final categories = provider.achievementsByCategory;
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: ListView.builder(
        itemCount: categories.keys.length,
        itemBuilder: (context, index) {
          final category = categories.keys.elementAt(index);
          final achievements = categories[category]!;
          return _buildCategorySection(category, achievements);
        },
      ),
    );
  }

  Widget _buildCategorySection(String category, List<Achievement> achievements) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 16),
            child: Text(
              category,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: achievements.length,
            itemBuilder: (context, index) => _buildAchievementCard(achievements[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final isUnlocked = achievement.unlockedAt != null;
    
    return AnimatedBuilder(
      animation: _celebrationAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isUnlocked ? _celebrationAnimation.value : 1.0,
          child: Container(
            decoration: BoxDecoration(
              gradient: isUnlocked
                  ? const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)])
                  : LinearGradient(
                      colors: [
                        Colors.grey[800]!,
                        Colors.grey[700]!,
                      ],
                    ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    achievement.icon,
                    style: TextStyle(
                      fontSize: 32,
                      color: isUnlocked ? Colors.white : Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    achievement.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isUnlocked ? Colors.white : Colors.grey[400],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${achievement.points} pts',
                    style: TextStyle(
                      fontSize: 12,
                      color: isUnlocked ? Colors.white70 : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsTab(AchievementsProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildWeeklyStats(provider),
          const SizedBox(height: 24),
          _buildRecentActivities(provider),
        ],
      ),
    );
  }

  Widget _buildWeeklyStats(AchievementsProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This Week',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          ...provider.weeklyStats.entries.map((entry) => _buildStatRow(
            _getStatIcon(entry.key),
            _getStatLabel(entry.key),
            entry.value.toString(),
            _getStatColor(entry.key),
          )),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities(AchievementsProvider provider) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: provider.recentActivities.length,
                itemBuilder: (context, index) {
                  final activity = provider.recentActivities[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            activity,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardTab(AchievementsProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: ListView.builder(
        itemCount: provider.leaderboard.length,
        itemBuilder: (context, index) {
          final entry = provider.leaderboard[index];
          final position = index + 1;
          final isCurrentUser = entry.id == 'me';
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isCurrentUser
                  ? const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)])
                  : const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF334155)]),
              borderRadius: BorderRadius.circular(16),
              border: isCurrentUser ? Border.all(color: const Color(0xFF7C3AED), width: 2) : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getPositionColor(position),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$position',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  entry.avatar,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${entry.points}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'points',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getPositionColor(int position) {
    switch (position) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.grey[600]!;
    }
  }

  IconData _getStatIcon(String key) {
    switch (key) {
      case 'storiesRecorded':
        return Icons.mic;
      case 'photosShared':
        return Icons.photo_camera;
      case 'gamesPlayed':
        return Icons.sports_esports;
      case 'helpSessions':
        return Icons.help;
      case 'messagesExchanged':
        return Icons.message;
      default:
        return Icons.star;
    }
  }

  String _getStatLabel(String key) {
    switch (key) {
      case 'storiesRecorded':
        return 'Stories Recorded';
      case 'photosShared':
        return 'Photos Shared';
      case 'gamesPlayed':
        return 'Games Played';
      case 'helpSessions':
        return 'Help Sessions';
      case 'messagesExchanged':
        return 'Messages Sent';
      default:
        return key;
    }
  }

  Color _getStatColor(String key) {
    switch (key) {
      case 'storiesRecorded':
        return const Color(0xFFFF8A00);
      case 'photosShared':
        return const Color(0xFF4F46E5);
      case 'gamesPlayed':
        return const Color(0xFF10B981);
      case 'helpSessions':
        return const Color(0xFF3B82F6);
      case 'messagesExchanged':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFFFFD700);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }
}