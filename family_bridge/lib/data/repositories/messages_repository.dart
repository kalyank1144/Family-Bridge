import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/offline_cache.dart';

class MessagesRepository {
  final SupabaseClient client;
  final OfflineCache cache = OfflineCache('msgs');
  MessagesRepository(this.client);

  Stream<List<Map<String, dynamic>>> watchChannel(String channelId, String userId) {
    final key = '$channelId:$userId';
    final ctrl = StreamController<List<Map<String, dynamic>>>.broadcast();
    () async {
      final cached = await cache.readList(key);
      if (!ctrl.isClosed) ctrl.add(cached);
      final data = await client
          .from('messages')
          .select()
          .eq('channel_id', channelId)
          .order('created_at', ascending: false)
          .limit(100) as List;
      final list = data.cast<Map<String, dynamic>>();
      await cache.writeList(key, list);
      if (!ctrl.isClosed) ctrl.add(list);
    }();

    final channel = client.channel('public:messages:$channelId')
      ..on(RealtimeListenTypes.postgresChanges, ChannelFilter(event: 'INSERT', schema: 'public', table: 'messages'), (payload, [ref]) async {
        final row = payload['new'] as Map<String, dynamic>;
        if (row['channel_id'] == channelId) {
          final current = await cache.readList(key);
          final next = [row, ...current];
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

  Future<void> send(String channelId, String userId, String text) async {
    await client.from('messages').insert({
      'channel_id': channelId,
      'sender_id': userId,
      'content': text,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}