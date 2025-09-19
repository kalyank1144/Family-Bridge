import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/offline_cache.dart';

class MedicationsRepository {
  final SupabaseClient client;
  final OfflineCache cache = OfflineCache('meds');
  final _controllers = <String, StreamController<List<Map<String, dynamic>>>>{};

  MedicationsRepository(this.client);

  Stream<List<Map<String, dynamic>>> watchMyMedications(String userId) {
    _controllers.putIfAbsent(userId, () => StreamController.broadcast());
    final ctrl = _controllers[userId]!;
    () async {
      final cached = await cache.readList(userId);
      if (!ctrl.isClosed) ctrl.add(cached);
      final data = await client
          .from('medications')
          .select()
          .eq('user_id', userId)
          .order('created_at') as List;
      final list = data.cast<Map<String, dynamic>>();
      await cache.writeList(userId, list);
      if (!ctrl.isClosed) ctrl.add(list);
    }();

    final channel = client.channel('public:medications')
      ..on(RealtimeListenTypes.postgresChanges, ChannelFilter(event: 'INSERT', schema: 'public', table: 'medications'), (payload, [ref]) async {
        final current = await cache.readList(userId);
        final row = payload['new'] as Map<String, dynamic>;
        if (row['user_id'] == userId) {
          final next = [...current, row];
          await cache.writeList(userId, next);
          if (!ctrl.isClosed) ctrl.add(next);
        }
      })
      ..on(RealtimeListenTypes.postgresChanges, ChannelFilter(event: 'UPDATE', schema: 'public', table: 'medications'), (payload, [ref]) async {
        final current = await cache.readList(userId);
        final row = payload['new'] as Map<String, dynamic>;
        if (row['user_id'] == userId) {
          final next = current.map((e) => e['id'] == row['id'] ? row : e).toList();
          await cache.writeList(userId, next);
          if (!ctrl.isClosed) ctrl.add(next);
        }
      })
      ..on(RealtimeListenTypes.postgresChanges, ChannelFilter(event: 'DELETE', schema: 'public', table: 'medications'), (payload, [ref]) async {
        final current = await cache.readList(userId);
        final row = payload['old'] as Map<String, dynamic>;
        final next = current.where((e) => e['id'] != row['id']).toList();
        await cache.writeList(userId, next);
        if (!ctrl.isClosed) ctrl.add(next);
      })
      ..subscribe();

    ctrl.onCancel = () {
      try { client.removeChannel(channel); } catch (_) {}
    };

    return ctrl.stream;
  }

  Future<void> toggleTaken(String id, bool taken) async {
    await client.from('medications').update({'taken': taken}).eq('id', id);
  }
}