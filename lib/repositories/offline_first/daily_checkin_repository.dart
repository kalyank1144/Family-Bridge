import 'package:hive/hive.dart';

import 'base_offline_repository.dart';
import 'package:family_bridge/models/hive/daily_checkin_model.dart';

class DailyCheckinRepository extends BaseOfflineRepository<HiveDailyCheckin> {
  DailyCheckinRepository({required Box<HiveDailyCheckin> box})
      : super(
          table: 'daily_checkins',
          box: box,
          fromMap: (m) => HiveDailyCheckin.fromMap(m),
          toMap: (m) => m.toMap(),
        );

  List<HiveDailyCheckin> getUserCheckins(String userId, {int days = 7}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return box.values
        .where((checkin) => 
            checkin.userId == userId && 
            checkin.createdAt.isAfter(cutoff))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Most recent first
  }

  Stream<List<HiveDailyCheckin>> watchUserCheckins(String userId, {int days = 7}) {
    return box.watch().map((_) => getUserCheckins(userId, days: days));
  }

  HiveDailyCheckin? getTodayCheckin(String userId) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return box.values
        .where((checkin) => 
            checkin.userId == userId &&
            checkin.createdAt.isAfter(todayStart) &&
            checkin.createdAt.isBefore(todayEnd))
        .firstOrNull;
  }

  bool hasTodayCheckin(String userId) => getTodayCheckin(userId) != null;
}