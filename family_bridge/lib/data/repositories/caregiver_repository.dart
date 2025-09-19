import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/offline_cache.dart';

class CaregiverRepository {
  final SupabaseClient client;
  final OfflineCache cache = OfflineCache('caregiver');
  CaregiverRepository(this.client);

  Stream<List<Map<String, dynamic>>> streamAssignedPatients(String caregiverId) {
    final key = 'patients_$caregiverId';
    final ctrl = StreamController<List<Map<String, dynamic>>>.broadcast();

    () async {
      final cached = await cache.readList(key);
      if (!ctrl.isClosed) ctrl.add(cached);

      final data = await client
          .from('caregiver_patients')
          .select('elder_id, profiles!fk_caregiver_patients_elder_profile ( id, email, full_name, user_type, role )')
          .eq('caregiver_id', caregiverId) as List;

      final list = (data as List)
          .map((row) {
            final p = (row['profiles'] as Map<String, dynamic>?) ?? {};
            return {
              'elder_id': row['elder_id'],
              'full_name': p['full_name'] ?? p['email'] ?? row['elder_id'],
              'email': p['email'],
              'user_type': p['user_type'],
            };
          })
          .toList();

      await cache.writeList(key, list);
      if (!ctrl.isClosed) ctrl.add(list);
    }();

    final ch1 = client.channel('public:caregiver_patients')
      ..on(RealtimeListenTypes.postgresChanges, const ChannelFilter(event: 'INSERT', schema: 'public', table: 'caregiver_patients'), (_) async {
        final fresh = await cache.readList(key);
        // Keep it simple: refetch on membership changes
        await _refetch(caregiverId, key, ctrl);
      })
      ..on(RealtimeListenTypes.postgresChanges, const ChannelFilter(event: 'DELETE', schema: 'public', table: 'caregiver_patients'), (_) async {
        await _refetch(caregiverId, key, ctrl);
      })
      ..subscribe();

    // profiles updates
    final ch2 = client.channel('public:profiles')
      ..on(RealtimeListenTypes.postgresChanges, const ChannelFilter(event: 'UPDATE', schema: 'public', table: 'profiles'), (_) async {
        await _refetch(caregiverId, key, ctrl);
      })
      ..subscribe();

    ctrl.onCancel = () {
      try { client.removeChannel(ch1); } catch (_) {}
      try { client.removeChannel(ch2); } catch (_) {}
    };

    return ctrl.stream;
  }

  Future<void> _refetch(String caregiverId, String key, StreamController<List<Map<String, dynamic>>> ctrl) async {
    final data = await client
        .from('caregiver_patients')
        .select('elder_id, profiles!fk_caregiver_patients_elder_profile ( id, email, full_name, user_type, role )')
        .eq('caregiver_id', caregiverId) as List;

    final list = (data as List)
        .map((row) {
          final p = (row['profiles'] as Map<String, dynamic>?) ?? {};
          return {
            'elder_id': row['elder_id'],
            'full_name': p['full_name'] ?? p['email'] ?? row['elder_id'],
            'email': p['email'],
            'user_type': p['user_type'],
          };
        })
        .toList();
    await cache.writeList(key, list);
    if (!ctrl.isClosed) ctrl.add(list);
  }
}