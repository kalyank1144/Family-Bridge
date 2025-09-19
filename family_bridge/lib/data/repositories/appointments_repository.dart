import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/offline_cache.dart';

class AppointmentsRepository {
  final SupabaseClient client;
  final OfflineCache cache = OfflineCache('appts');
  AppointmentsRepository(this.client);

  Stream<List<Map<String, dynamic>>> watchMyAppointments(String userId) {
    final key = userId;
    final ctrl = StreamController<List<Map<String, dynamic>>>.broadcast();
    () async {
      final cached = await cache.readList(key);
      if (!ctrl.isClosed) ctrl.add(cached);
      final data = await client
          .from('appointments')
          .select()
          .eq('user_id', userId)
          .order('time') as List;
      final list = data.cast<Map<String, dynamic>>();
      await cache.writeList(key, list);
      if (!ctrl.isClosed) ctrl.add(list);
    }();

    final channel = client.channel('public:appointments')
      ..on(RealtimeListenTypes.postgresChanges, ChannelFilter(event: 'INSERT', schema: 'public', table: 'appointments'), (payload, [ref]) async {
        final row = payload['new'] as Map<String, dynamic>;
        if (row['user_id'] == userId) {
          final current = await cache.readList(key);
          final next = [...current, row];
          await cache.writeList(key, next);
          if (!ctrl.isClosed) ctrl.add(next);
        }
      })
      ..on(RealtimeListenTypes.postgresChanges, ChannelFilter(event: 'UPDATE', schema: 'public', table: 'appointments'), (payload, [ref]) async {
        final row = payload['new'] as Map<String, dynamic>;
        if (row['user_id'] == userId) {
          final current = await cache.readList(key);
          final next = current.map((e) => e['id'] == row['id'] ? row : e).toList();
          await cache.writeList(key, next);
          if (!ctrl.isClosed) ctrl.add(next);
        }
      })
      ..on(RealtimeListenTypes.postgresChanges, ChannelFilter(event: 'DELETE', schema: 'public', table: 'appointments'), (payload, [ref]) async {
        final row = payload['old'] as Map<String, dynamic>;
        final current = await cache.readList(key);
        final next = current.where((e) => e['id'] != row['id']).toList();
        await cache.writeList(key, next);
        if (!ctrl.isClosed) ctrl.add(next);
      })
      ..subscribe();

    ctrl.onCancel = () {
      try { client.removeChannel(channel); } catch (_) {}
    };

    return ctrl.stream;
  }
}