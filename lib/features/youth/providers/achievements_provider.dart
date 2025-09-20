import 'package:flutter/material.dart';
import '../../../core/services/gamification_service.dart';

class AchievementsProvider extends ChangeNotifier {
  final GamificationService _gamification = GamificationService();

  int _points = 0;
  int _streak = 0;
  int _level = 1;
  int _pointsToNextLevel = 100;
  double _levelProgress = 0.0;
  List<Achievement> _achievements = [];
  List<LeaderboardEntry> _leaderboard = [];
  List<String> _recentActivities = [];
  Map<String, int> _weeklyStats = {};

  // Getters
  int get points => _points;
  int get streak => _streak;
  int get level => _level;
  int get pointsToNextLevel => _pointsToNextLevel;
  double get levelProgress => _levelProgress;
  List<Achievement> get achievements => _achievements;
  List<LeaderboardEntry> get leaderboard => _leaderboard;
  List<String> get recentActivities => _recentActivities;
  Map<String, int> get weeklyStats => _weeklyStats;

  int get unlockedCount => _achievements.where((a) => a.unlockedAt != null).length;
  int get totalCount => _achievements.length;

  Map<String, List<Achievement>> get achievementsByCategory {
    final categories = <String, List<Achievement>>{};
    
    for (final achievement in _achievements) {
      String category;
      
      // Categorize achievements based on their ID
      if (achievement.id.contains('story') || achievement.id.contains('memory_keeper')) {
        category = '🎙️ Storytelling';
      } else if (achievement.id.contains('photo') || achievement.id.contains('memory_maker')) {
        category = '📸 Photography';
      } else if (achievement.id.contains('memory_master') || achievement.id.contains('trivia') || achievement.id.contains('game')) {
        category = '🎮 Gaming';
      } else if (achievement.id.contains('tech') || achievement.id.contains('help') || achievement.id.contains('guide')) {
        category = '🛠️ Tech Support';
      } else if (achievement.id.contains('chat') || achievement.id.contains('voice') || achievement.id.contains('daily')) {
        category = '💬 Communication';
      } else if (achievement.id.contains('caring') || achievement.id.contains('guardian') || achievement.id.contains('elder')) {
        category = '❤️ Care & Support';
      } else if (achievement.id.contains('social') || achievement.id.contains('milestone') || achievement.id.contains('tradition')) {
        category = '🦋 Social';
      } else {
        category = '⭐ Special';
      }
      
      categories.putIfAbsent(category, () => []);
      categories[category]!.add(achievement);
    }
    
    return categories;
  }

  Future<void> loadData() async {
    try {
      await _gamification.init();
      
      // Load basic stats
      _points = await _gamification.getPoints();
      _streak = await _gamification.getStreak();
      _level = await _gamification.getLevel();
      _pointsToNextLevel = _gamification.getPointsToNextLevel(_points);
      _levelProgress = _gamification.getLevelProgress(_points);
      
      // Load achievements and leaderboard
      _achievements = await _gamification.getAchievements();
      _leaderboard = await _gamification.getLeaderboard();
      
      // Load activity data
      _recentActivities = await _gamification.getRecentActivities();
      _weeklyStats = await _gamification.getWeeklyStats();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading achievements data: $e');
    }
  }

  Future<void> unlockAchievement(String achievementId) async {
    try {
      await _gamification.unlockAchievement(achievementId);
      await loadData(); // Refresh data
    } catch (e) {
      debugPrint('Error unlocking achievement: $e');
    }
  }

  Future<void> addPoints(int points) async {
    try {
      await _gamification.addPoints(points);
      await loadData(); // Refresh data
    } catch (e) {
      debugPrint('Error adding points: $e');
    }
  }

  Future<void> updateStreak() async {
    try {
      await _gamification.updateStreak();
      await loadData(); // Refresh data
    } catch (e) {
      debugPrint('Error updating streak: $e');
    }
  }

  String getAchievementProgressText() {
    return '$unlockedCount of $totalCount achievements unlocked';
  }

  String getLevelProgressText() {
    return '$_pointsToNextLevel points to level ${_level + 1}';
  }

  List<Achievement> getRecentlyUnlocked() {
    final now = DateTime.now();
    return _achievements.where((achievement) {
      if (achievement.unlockedAt == null) return false;
      final daysSinceUnlock = now.difference(achievement.unlockedAt!).inDays;
      return daysSinceUnlock <= 7; // Recent = within last week
    }).toList()
      ..sort((a, b) => b.unlockedAt!.compareTo(a.unlockedAt!));
  }

  List<Achievement> getLockedAchievements() {
    return _achievements.where((achievement) => achievement.unlockedAt == null).toList();
  }

  List<Achievement> getUnlockedAchievements() {
    return _achievements.where((achievement) => achievement.unlockedAt != null).toList()
      ..sort((a, b) => b.unlockedAt!.compareTo(a.unlockedAt!));
  }

  double getCompletionPercentage() {
    if (_achievements.isEmpty) return 0.0;
    return unlockedCount / totalCount;
  }

  String getNextLevelReward() {
    // Mock rewards for different levels
    final rewards = {
      2: 'Custom Avatar Frame',
      3: 'Family Story Badge',
      4: 'Photo Filter Pack',
      5: 'Special Achievement Theme',
      6: 'Voice Message Effects',
      7: 'Family Trivia Master',
      8: 'Tech Helper Pro Badge',
      9: 'Memory Keeper Crown',
      10: 'Family MVP Status',
    };
    
    return rewards[_level + 1] ?? 'Surprise Reward!';
  }

  List<String> getUpcomingMilestones() {
    final milestones = <String>[];
    
    // Points milestones
    final nextPointMilestone = ((_points ~/ 100) + 1) * 100;
    milestones.add('Reach $nextPointMilestone points');
    
    // Streak milestones
    if (_streak < 7) {
      milestones.add('Maintain ${7 - _streak} more days streak');
    } else if (_streak < 30) {
      milestones.add('Reach 30-day streak');
    }
    
    // Achievement milestones
    final nextAchievementCount = ((unlockedCount ~/ 5) + 1) * 5;
    if (nextAchievementCount <= totalCount) {
      milestones.add('Unlock $nextAchievementCount achievements');
    }
    
    return milestones;
  }
}