import 'package:flutter/material.dart';
import '../../../core/services/gamification_service.dart';
import '../../caregiver/models/family_member.dart';

class YouthProvider extends ChangeNotifier {
  final GamificationService _gamification = GamificationService();

  int _points = 0;
  List<Achievement> _achievements = [];
  List<LeaderboardEntry> _leaderboard = [];
  List<FamilyMember> _family = [];

  int get points => _points;
  List<Achievement> get achievements => _achievements;
  List<LeaderboardEntry> get leaderboard => _leaderboard;
  List<FamilyMember> get family => _family;

  Future<void> initialize() async {
    _points = await _gamification.getPoints();
    _achievements = await _gamification.getAchievements();
    _leaderboard = await _gamification.getLeaderboard();
    _family = _mockFamily();
    notifyListeners();
  }

  Future<void> addPoints(int value) async {
    _points = await _gamification.addPoints(value);
    _leaderboard = await _gamification.getLeaderboard();
    notifyListeners();
  }

  Future<void> unlock(String id) async {
    await _gamification.unlockAchievement(id);
    _achievements = await _gamification.getAchievements();
    notifyListeners();
  }

  List<FamilyMember> _mockFamily() {
    final now = DateTime.now();
    return [
      FamilyMember(id: 'grandma', name: 'Grandma', type: MemberType.elder, isOnline: true, lastActivity: now.subtract(const Duration(minutes: 2)), healthStatus: HealthStatus.normal),
      FamilyMember(id: 'mom', name: 'Mom', type: MemberType.caregiver, isOnline: true, lastActivity: now.subtract(const Duration(minutes: 5)), healthStatus: HealthStatus.normal),
      FamilyMember(id: 'dad', name: 'Dad', type: MemberType.caregiver, isOnline: false, lastActivity: now.subtract(const Duration(hours: 1)), healthStatus: HealthStatus.normal),
      FamilyMember(id: 'sis', name: 'Sister', type: MemberType.youth, isOnline: true, lastActivity: now.subtract(const Duration(minutes: 10)), healthStatus: HealthStatus.normal),
    ];
  }
}