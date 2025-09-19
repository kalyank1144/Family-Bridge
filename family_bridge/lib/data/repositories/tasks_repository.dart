import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/offline_cache.dart';

class TasksRepository {
  final SupabaseClient client;
  final OfflineCache cache = OfflineCache('tasks');
  TasksRepository(this.client);

  Stream<List<Map<String, dynamic>>> watchMyTasks(String userId) {
    final key = userId;
    final ctrl = StreamController<List<Map<String, dynamic>>>.broadcast();
    () async {
      final cached = await cache.readList(key);
      if (!ctrl.isClosed) ctrl.add(cached);
      final data = await client
          .from('tasks')
          .select()
          .eq('user_id', userId)
          .order('created_at') as List;
      final list = data.cast<Map<String, dynamic>>();
      await cache.writeList(key, list);
      if (!ctrl.isClosed) ctrl.add(list);
    }();

    final channel = client.channel('public:tasks')
      ..on(RealtimeListenTypes.postgresChanges, ChannelFilter(event: 'INSERT', schema: 'public', table: 'tasks'), (payload, [ref]) async {
        final row = payload['new'] as Map<String, dynamic>;
        if (row['user_id'] == userId) {
          final current = await cache.readList(key);
          final next = [...current, row];
          await cache.writeList(key, next);
          if (!ctrl.isClosed) ctrl.add(next);
        }
      })
      ..on(RealtimeListenTypes.postgresChanges, ChannelFilter(event: 'UPDATE', schema: 'public', table: 'tasks'), (payload, [ref]) async {
        final row = payload['new'] as Map<String, dynamic>;
        if (row['user_id'] == userId) {
          final current = await cache.readList(key);
          final next = current.map((e) => e['id'] == row['id'] ? row : e).toList();
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

  Future<void> toggle(String id, bool done) async {
    await client.from('tasks').update({'done': done}).eq('id', id);
  }

  Future<void> add(String userId, String title) async {
    await client.from('tasks').insert({
      'user_id': userId,
      'title': title,
      'done': false,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}