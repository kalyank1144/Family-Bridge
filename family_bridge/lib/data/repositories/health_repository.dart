import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/offline_cache.dart';

class HealthRepository {
  final SupabaseClient client;
  final OfflineCache cache = OfflineCache('health');

  HealthRepository(this.client);

  Future<void> addCheckIn(String userId, Map<String, dynamic> fields) async {
    final data = {
      'user_id': userId,
      'mood': fields['mood'],
      'pain': fields['pain'],
      'medication_taken': fields['medication_taken'],
      'created_at': DateTime.now().toIso8601String(),
    };
    await client.from('health_data').insert(data);
  }

  Stream<List<Map<String, dynamic>>> watchRecent(String userId, {int days = 7}) {
    final key = 'recent_$userId';
    final ctrl = StreamController<List<Map<String, dynamic>>>.broadcast();
    () async {
      final cached = await cache.readList(key);
      if (!ctrl.isClosed) ctrl.add(cached);
      final since = DateTime.now().subtract(Duration(days: days)).toIso8601String();
      final data = await client
          .from('health_data')
          .select()
          .eq('user_id', userId)
          .gte('created_at', since)
          .order('created_at') as List;
      final list = data.cast<Map<String, dynamic>>();
      await cache.writeList(key, list);
      if (!ctrl.isClosed) ctrl.add(list);
    }();

    final channel = client.channel('public:health_data')
      ..on(RealtimeListenTypes.postgresChanges, ChannelFilter(event: 'INSERT', schema: 'public', table: 'health_data'), (payload, [ref]) async {
        final row = payload['new'] as Map<String, dynamic>;
        if (row['user_id'] == userId) {
          final current = await cache.readList(key);
          final next = [...current, row];
          await cache.writeList(key, next);
          if (!ctrl.isClosed) ctrl.add(next);
        }
      })
      ..subscribe();

    ctrl.onCancel = () {
      try { client.removeChannel(channel); } catch (_) {}
    };

    return ctrl.stream;
  }

  List<double> toDailyAverages(List<Map<String, dynamic>> rows, String field) {
    final now = DateTime.now();
    final days = List.generate(7, (i) => DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i)));
    final values = <double>[];
    for (final d in days) {
      final sameDay = rows.where((r) => DateTime.parse(r['created_at']).day == d.day && DateTime.parse(r['created_at']).month == d.month);
      if (sameDay.isEmpty) {
        values.add(0);
      } else {
        final nums = sameDay.map((r) => (r[field] ?? 0).toDouble()).toList();
        final avg = nums.reduce((a, b) => a + b) / nums.length;
        values.add(double.parse(avg.toStringAsFixed(1)));
      }
    }
    return values;
  }
}