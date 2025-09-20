import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int points;
  final DateTime? unlockedAt;

  Achievement({required this.id, required this.title, required this.description, required this.icon, required this.points, this.unlockedAt});

  Achievement copyWith({DateTime? unlockedAt}) {
    return Achievement(id: id, title: title, description: description, icon: icon, points: points, unlockedAt: unlockedAt ?? this.unlockedAt);
  }

  Map<String, dynamic> toJson() => {"id": id, "title": title, "description": description, "icon": icon, "points": points, "unlockedAt": unlockedAt?.toIso8601String()};
  factory Achievement.fromJson(Map<String, dynamic> j) => Achievement(id: j['id'], title: j['title'], description: j['description'], icon: j['icon'], points: j['points'], unlockedAt: j['unlockedAt'] != null ? DateTime.parse(j['unlockedAt']) : null);
}

class LeaderboardEntry {
  final String id;
  final String name;
  final String avatar;
  final int points;

  LeaderboardEntry({required this.id, required this.name, required this.avatar, required this.points});

  Map<String, dynamic> toJson() => {"id": id, "name": name, "avatar": avatar, "points": points};
  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(id: j['id'], name: j['name'], avatar: j['avatar'], points: j['points']);
}

class GamificationService {
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  static const _kPointsKey = 'youth_points';
  static const _kAchievementsKey = 'youth_achievements';
  static const _kLeaderboardKey = 'youth_leaderboard';
  static const _kStreakKey = 'youth_streak';
  static const _kLevelKey = 'youth_level';
  static const _kLastActivityKey = 'youth_last_activity';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    _ensureDefaults();
  }

  Future<int> getPoints() async {
    await init();
    return _prefs!.getInt(_kPointsKey) ?? 0;
  }

  Future<int> addPoints(int delta) async {
    await init();
    final current = await getPoints();
    final next = current + delta;
    await _prefs!.setInt(_kPointsKey, next);
    await _updateSelfOnLeaderboard(next);
    return next;
  }

  Future<List<Achievement>> getAchievements() async {
    await init();
    final raw = _prefs!.getString(_kAchievementsKey);
    if (raw == null || raw.isEmpty) return _defaultAchievements();
    final list = (jsonDecode(raw) as List).map((e) => Achievement.fromJson(e)).toList();
    return list;
  }

  Future<void> unlockAchievement(String id) async {
    await init();
    final list = await getAchievements();
    final updated = list.map((a) => a.id == id && a.unlockedAt == null ? a.copyWith(unlockedAt: DateTime.now()) : a).toList();
    await _prefs!.setString(_kAchievementsKey, jsonEncode(updated.map((e) => e.toJson()).toList()));
  }

  Future<List<LeaderboardEntry>> getLeaderboard() async {
    await init();
    final raw = _prefs!.getString(_kLeaderboardKey);
    if (raw == null || raw.isEmpty) return _defaultLeaderboard();
    final list = (jsonDecode(raw) as List).map((e) => LeaderboardEntry.fromJson(e)).toList();
    list.sort((a, b) => b.points.compareTo(a.points));
    return list;
  }

  Future<void> _updateSelfOnLeaderboard(int points) async {
    final list = await getLeaderboard();
    final idx = list.indexWhere((e) => e.id == 'me');
    if (idx >= 0) {
      list[idx] = LeaderboardEntry(id: 'me', name: 'You', avatar: '👦', points: points);
    } else {
      list.add(LeaderboardEntry(id: 'me', name: 'You', avatar: '👦', points: points));
    }
    list.sort((a, b) => b.points.compareTo(a.points));
    await _prefs!.setString(_kLeaderboardKey, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  void _ensureDefaults() {
    _prefs!.getInt(_kPointsKey) ?? _prefs!.setInt(_kPointsKey, 0);
    _prefs!.getString(_kAchievementsKey) ?? _prefs!.setString(_kAchievementsKey, jsonEncode(_defaultAchievements().map((e) => e.toJson()).toList()));
    _prefs!.getString(_kLeaderboardKey) ?? _prefs!.setString(_kLeaderboardKey, jsonEncode(_defaultLeaderboard().map((e) => e.toJson()).toList()));
    _prefs!.getInt(_kStreakKey) ?? _prefs!.setInt(_kStreakKey, 0);
    _prefs!.getInt(_kLevelKey) ?? _prefs!.setInt(_kLevelKey, 1);
    _prefs!.getString(_kLastActivityKey) ?? _prefs!.setString(_kLastActivityKey, DateTime.now().toIso8601String());
  }

  Future<int> getStreak() async {
    await init();
    final lastActivity = DateTime.parse(_prefs!.getString(_kLastActivityKey) ?? DateTime.now().toIso8601String());
    final now = DateTime.now();
    final daysSinceLastActivity = now.difference(lastActivity).inDays;
    
    if (daysSinceLastActivity > 1) {
      // Streak broken - reset to 0
      await _prefs!.setInt(_kStreakKey, 0);
      return 0;
    }
    
    return _prefs!.getInt(_kStreakKey) ?? 0;
  }

  Future<int> updateStreak() async {
    await init();
    final lastActivity = DateTime.parse(_prefs!.getString(_kLastActivityKey) ?? DateTime.now().toIso8601String());
    final now = DateTime.now();
    final daysSinceLastActivity = now.difference(lastActivity).inDays;
    
    int currentStreak = _prefs!.getInt(_kStreakKey) ?? 0;
    
    if (daysSinceLastActivity == 1) {
      // Continue streak
      currentStreak++;
      await _prefs!.setInt(_kStreakKey, currentStreak);
    } else if (daysSinceLastActivity > 1) {
      // Reset streak
      currentStreak = 1;
      await _prefs!.setInt(_kStreakKey, currentStreak);
    }
    // If daysSinceLastActivity == 0, streak stays the same (already active today)
    
    await _prefs!.setString(_kLastActivityKey, now.toIso8601String());
    return currentStreak;
  }

  Future<int> getLevel() async {
    await init();
    final points = await getPoints();
    final level = (points / 100).floor() + 1; // Level up every 100 points
    await _prefs!.setInt(_kLevelKey, level);
    return level;
  }

  int getPointsToNextLevel(int currentPoints) {
    final currentLevel = (currentPoints / 100).floor() + 1;
    final nextLevelPoints = currentLevel * 100;
    return nextLevelPoints - currentPoints;
  }

  double getLevelProgress(int currentPoints) {
    final currentLevel = (currentPoints / 100).floor() + 1;
    final levelStartPoints = (currentLevel - 1) * 100;
    final pointsInLevel = currentPoints - levelStartPoints;
    return pointsInLevel / 100.0;
  }

  Future<List<String>> getRecentActivities() async {
    // This would normally come from a database
    return [
      'Helped Grandma with video call',
      'Shared family photo',
      'Won memory game',
      'Recorded bedtime story',
      'Earned care points',
    ];
  }

  Future<Map<String, int>> getWeeklyStats() async {
    // Mock weekly stats - in real app this would track actual activities
    return {
      'storiesRecorded': 3,
      'photosShared': 7,
      'gamesPlayed': 5,
      'helpSessions': 2,
      'messagesExchanged': 24,
    };
  }

  List<Achievement> _defaultAchievements() {
    return [
      // Story Recording Achievements
      Achievement(id: 'first_story', title: 'Storyteller', description: 'Recorded your first story for the family', icon: '🎙️', points: 50),
      Achievement(id: 'story_streaker', title: 'Story Streaker', description: 'Recorded stories for 7 days straight', icon: '🔥', points: 100),
      Achievement(id: 'memory_keeper', title: 'Memory Keeper', description: 'Recorded 10 family memories', icon: '📚', points: 150),
      
      // Photo Sharing Achievements
      Achievement(id: 'photo_sharer', title: 'Snapshot Hero', description: 'Shared 5 photos with family', icon: '📸', points: 25),
      Achievement(id: 'family_photographer', title: 'Family Photographer', description: 'Shared 25 photos', icon: '📷', points: 75),
      Achievement(id: 'memory_maker', title: 'Memory Maker', description: 'Created a family photo album', icon: '🖼️', points: 100),
      
      // Gaming Achievements
      Achievement(id: 'memory_master', title: 'Memory Master', description: 'Won your first memory game', icon: '🧠', points: 40),
      Achievement(id: 'trivia_champion', title: 'Trivia Champion', description: 'Perfect score on family trivia', icon: '🏆', points: 75),
      Achievement(id: 'game_night_hero', title: 'Game Night Hero', description: 'Played 10 games with family', icon: '🎮', points: 120),
      
      // Tech Help Achievements
      Achievement(id: 'tech_helper', title: 'Tech Helper', description: 'Helped a family member with technology', icon: '🛠️', points: 60),
      Achievement(id: 'remote_hero', title: 'Remote Hero', description: 'Completed 5 remote assistance sessions', icon: '💻', points: 150),
      Achievement(id: 'guide_master', title: 'Guide Master', description: 'Shared 10 helpful guides', icon: '📋', points: 100),
      
      // Communication Achievements
      Achievement(id: 'daily_connector', title: 'Daily Connector', description: 'Checked in with family daily for a week', icon: '💬', points: 80),
      Achievement(id: 'voice_bridge', title: 'Voice Bridge', description: 'Sent 20 voice messages to family', icon: '🎤', points: 50),
      Achievement(id: 'chat_champion', title: 'Chat Champion', description: 'Sent 100 messages in family chat', icon: '💭', points: 75),
      
      // Care & Support Achievements
      Achievement(id: 'caring_heart', title: 'Caring Heart', description: 'Earned 500 care points', icon: '❤️', points: 200),
      Achievement(id: 'family_guardian', title: 'Family Guardian', description: 'Helped with 5 emergency situations', icon: '🛡️', points: 300),
      Achievement(id: 'elder_champion', title: 'Elder Champion', description: 'Dedicated helper for elderly family members', icon: '👵', points: 250),
      
      // Social & Engagement Achievements
      Achievement(id: 'social_butterfly', title: 'Social Butterfly', description: 'Engaged with all family members in one day', icon: '🦋', points: 90),
      Achievement(id: 'milestone_celebrator', title: 'Milestone Celebrator', description: 'Celebrated 5 family milestones', icon: '🎉', points: 120),
      Achievement(id: 'tradition_keeper', title: 'Tradition Keeper', description: 'Participated in 10 family activities', icon: '🏮', points: 180),
      
      // Special Achievements
      Achievement(id: 'early_bird', title: 'Early Bird', description: 'First to try a new feature', icon: '🐦', points: 100),
      Achievement(id: 'feedback_hero', title: 'Feedback Hero', description: 'Provided valuable app feedback', icon: '⭐', points: 150),
      Achievement(id: 'family_mvp', title: 'Family MVP', description: 'Top contributor for the month', icon: '👑', points: 500),
    ];
  }

  List<LeaderboardEntry> _defaultLeaderboard() {
    return [
      LeaderboardEntry(id: 'emily', name: 'Emily', avatar: '👩‍🦰', points: 485),
      LeaderboardEntry(id: 'brian', name: 'Brian', avatar: '👨', points: 432),
      LeaderboardEntry(id: 'sophia', name: 'Sophia', avatar: '👧', points: 378),
      LeaderboardEntry(id: 'me', name: 'You', avatar: '👦', points: 315),
      LeaderboardEntry(id: 'grandma_rose', name: 'Grandma Rose', avatar: '👵', points: 298),
      LeaderboardEntry(id: 'grandpa_joe', name: 'Grandpa Joe', avatar: '👴', points: 267),
      LeaderboardEntry(id: 'uncle_mark', name: 'Uncle Mark', avatar: '👨‍🦲', points: 234),
      LeaderboardEntry(id: 'cousin_lisa', name: 'Cousin Lisa', avatar: '👱‍♀️', points: 189),
    ];
  }
}