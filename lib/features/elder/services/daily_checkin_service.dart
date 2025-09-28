import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:uuid/uuid.dart';

import 'package:family_bridge/core/services/notification_service.dart';
import 'package:family_bridge/features/elder/models/daily_checkin_model.dart';
import 'package:family_bridge/models/hive/daily_checkin_model.dart';
import 'package:family_bridge/repositories/offline_first/daily_checkin_repository.dart';
import 'package:family_bridge/services/sync/data_sync_service.dart';

class DailyCheckinService {
  final _uuid = const Uuid();
  
  late DailyCheckinRepository _repo;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await DataSyncService.instance.initialize();
    _repo = DailyCheckinRepository(box: DataSyncService.instance.dailyCheckinsBox);
    _initialized = true;
  }

  Future<List<DailyCheckin>> getUserCheckins(String userId, {int days = 7}) async {
    await initialize();
    
    try {
      final hiveCheckins = _repo.getUserCheckins(userId, days: days);
      return hiveCheckins.map(_fromHiveCheckin).toList();
    } catch (e) {
      debugPrint('Error loading daily check-ins: $e');
      return [];
    }
  }

  Stream<List<DailyCheckin>> watchUserCheckins(String userId, {int days = 7}) async* {
    await initialize();
    
    await for (final hiveCheckins in _repo.watchUserCheckins(userId, days: days)) {
      yield hiveCheckins.map(_fromHiveCheckin).toList();
    }
  }

  Future<DailyCheckin?> getTodayCheckin(String userId) async {
    await initialize();
    
    try {
      final hiveCheckin = _repo.getTodayCheckin(userId);
      return hiveCheckin != null ? _fromHiveCheckin(hiveCheckin) : null;
    } catch (e) {
      debugPrint('Error loading today check-in: $e');
      return null;
    }
  }

  Future<bool> hasTodayCheckin(String userId) async {
    await initialize();
    
    return _repo.hasTodayCheckin(userId);
  }

  Future<DailyCheckin> submitCheckin(DailyCheckin checkin, String userId) async {
    await initialize();
    
    final id = checkin.id ?? _uuid.v4();
    final hiveCheckin = _toHiveCheckin(checkin, id, userId);
    
    await _repo.create(hiveCheckin);
    
    return checkin.copyWith(id: id);
  }

  Future<void> updateCheckin(DailyCheckin checkin, String userId) async {
    await initialize();
    
    if (checkin.id == null) return;
    
    final hiveCheckin = _toHiveCheckin(checkin, checkin.id!, userId);
    await _repo.upsert(hiveCheckin);
  }

  Future<void> deleteCheckin(String checkinId) async {
    await initialize();
    
    await _repo.delete(checkinId);
  }

  Future<Map<String, dynamic>> getCheckinStats(String userId, {int days = 30}) async {
    await initialize();
    
    final checkins = await getUserCheckins(userId, days: days);
    
    if (checkins.isEmpty) {
      return {
        'averageWellnessScore': 0,
        'checkinStreak': 0,
        'totalCheckins': 0,
        'medicationCompliance': 0.0,
        'mealCompliance': 0.0,
        'activityCompliance': 0.0,
      };
    }

    final wellnessScores = checkins.map((c) => c.getWellnessScore()).toList();
    final averageWellness = wellnessScores.reduce((a, b) => a + b) / wellnessScores.length;
    
    final medicationTaken = checkins.where((c) => c.medicationTaken).length;
    final mealsEaten = checkins.where((c) => c.mealEaten).length;
    final activitiesDone = checkins.where((c) => c.physicalActivity).length;
    
    final totalCheckins = checkins.length;
    
    return {
      'averageWellnessScore': averageWellness.round(),
      'checkinStreak': _calculateStreak(checkins),
      'totalCheckins': totalCheckins,
      'medicationCompliance': totalCheckins > 0 ? medicationTaken / totalCheckins : 0.0,
      'mealCompliance': totalCheckins > 0 ? mealsEaten / totalCheckins : 0.0,
      'activityCompliance': totalCheckins > 0 ? activitiesDone / totalCheckins : 0.0,
    };
  }

  int _calculateStreak(List<DailyCheckin> checkins) {
    if (checkins.isEmpty) return 0;
    
    // Sort by date, most recent first
    checkins.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    int streak = 0;
    DateTime? lastCheckinDate;
    
    for (final checkin in checkins) {
      final checkinDate = DateTime(
        checkin.createdAt.year,
        checkin.createdAt.month,
        checkin.createdAt.day,
      );
      
      if (lastCheckinDate == null) {
        // First check-in, start the streak
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);
        
        if (checkinDate.isAtSameMomentAs(todayDate) || 
            checkinDate.isAtSameMomentAs(todayDate.subtract(const Duration(days: 1)))) {
          streak = 1;
          lastCheckinDate = checkinDate;
        } else {
          break; // Gap found, streak is 0
        }
      } else {
        // Check if this check-in is consecutive
        final expectedDate = lastCheckinDate.subtract(const Duration(days: 1));
        if (checkinDate.isAtSameMomentAs(expectedDate)) {
          streak++;
          lastCheckinDate = checkinDate;
        } else {
          break; // Gap found, end streak
        }
      }
    }
    
    return streak;
  }

  void dispose() {
    
  }

  Future<void> scheduleDailyReminder({required TimeOfDay time}) async {
    await NotificationService.instance.scheduleDailyCheckinReminder(
      title: 'Daily Check-in',
      message: 'Please complete your daily check-in',
      time: time,
    );
  }

  // Conversion helpers
  HiveDailyCheckin _toHiveCheckin(DailyCheckin checkin, String id, String userId) {
    return HiveDailyCheckin(
      id: id,
      userId: userId,
      familyId: 'default', // Should come from context
      mood: checkin.mood,
      sleepQuality: checkin.sleepQuality,
      mealEaten: checkin.mealEaten,
      medicationTaken: checkin.medicationTaken,
      physicalActivity: checkin.physicalActivity,
      painLevel: checkin.painLevel,
      notes: checkin.notes,
      voiceNoteUrl: checkin.voiceNoteUrl,
      createdAt: checkin.createdAt,
    );
  }

  DailyCheckin _fromHiveCheckin(HiveDailyCheckin hiveCheckin) {
    return DailyCheckin(
      id: hiveCheckin.id,
      elderId: hiveCheckin.userId,
      mood: hiveCheckin.mood,
      sleepQuality: hiveCheckin.sleepQuality,
      mealEaten: hiveCheckin.mealEaten,
      medicationTaken: hiveCheckin.medicationTaken,
      physicalActivity: hiveCheckin.physicalActivity,
      painLevel: hiveCheckin.painLevel,
      notes: hiveCheckin.notes,
      voiceNoteUrl: hiveCheckin.voiceNoteUrl,
      createdAt: hiveCheckin.createdAt,
    );
  }
}

extension DailyCheckinCopyWith on DailyCheckin {
  DailyCheckin copyWith({String? id}) {
    return DailyCheckin(
      id: id ?? this.id,
      elderId: elderId,
      mood: mood,
      sleepQuality: sleepQuality,
      mealEaten: mealEaten,
      medicationTaken: medicationTaken,
      physicalActivity: physicalActivity,
      painLevel: painLevel,
      notes: notes,
      voiceNoteUrl: voiceNoteUrl,
      createdAt: createdAt,
    );
  }
}