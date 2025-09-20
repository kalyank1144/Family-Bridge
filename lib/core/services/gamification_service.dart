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
  }

  List<Achievement> _defaultAchievements() {
    return [
      Achievement(id: 'first_story', title: 'First Story', description: 'Recorded your first story', icon: '🏆', points: 50),
      Achievement(id: 'photo_sharer', title: 'Photo Sharer', description: 'Shared 5 photos', icon: '📸', points: 25),
      Achievement(id: 'memory_master', title: 'Memory Master', description: 'Won a memory game', icon: '🧠', points: 40),
      Achievement(id: 'family_trivia', title: 'Family Historian', description: 'Completed a trivia round', icon: '❓', points: 30),
    ];
  }

  List<LeaderboardEntry> _defaultLeaderboard() {
    return [
      LeaderboardEntry(id: 'mom', name: 'Mom', avatar: '👩‍🦰', points: 320),
      LeaderboardEntry(id: 'grandma', name: 'Grandma', avatar: '👵', points: 280),
      LeaderboardEntry(id: 'me', name: 'You', avatar: '👦', points: 200),
      LeaderboardEntry(id: 'dad', name: 'Dad', avatar: '👨', points: 180),
      LeaderboardEntry(id: 'sis', name: 'Sister', avatar: '👧', points: 150),
    ];
  }
}