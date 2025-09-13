import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/health_data.dart';

class HealthDataService {
  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _channel;

  Future<List<HealthData>> getHealthData(String memberId, {int days = 7}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));
      
      final response = await _supabase
          .from('health_data')
          .select()
          .eq('member_id', memberId)
          .gte('timestamp', startDate.toIso8601String())
          .order('timestamp', ascending: true);
      
      return (response as List)
          .map((json) => HealthData.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load health data: $e');
    }
  }

  Future<List<MedicationRecord>> getMedicationRecords(String memberId, {int days = 7}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));
      
      final response = await _supabase
          .from('medication_records')
          .select()
          .eq('member_id', memberId)
          .gte('scheduled_time', startDate.toIso8601String())
          .order('scheduled_time', ascending: true);
      
      return (response as List)
          .map((json) => MedicationRecord.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load medication records: $e');
    }
  }

  Future<void> addHealthData(String memberId, HealthData data) async {
    try {
      final json = data.toJson();
      json['member_id'] = memberId;
      
      await _supabase.from('health_data').insert(json);
    } catch (e) {
      throw Exception('Failed to add health data: $e');
    }
  }

  Future<void> markMedicationTaken(String memberId, String medicationId) async {
    try {
      await _supabase
          .from('medication_records')
          .update({
            'is_taken': true,
            'taken_time': DateTime.now().toIso8601String(),
          })
          .eq('id', medicationId)
          .eq('member_id', memberId);
    } catch (e) {
      throw Exception('Failed to update medication record: $e');
    }
  }

  void subscribeToHealthUpdates(String memberId, Function(HealthData) onUpdate) {
    _channel = _supabase.channel('health_updates_$memberId')
      ..on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: 'INSERT',
          schema: 'public',
          table: 'health_data',
          filter: 'member_id=eq.$memberId',
        ),
        (payload, [ref]) {
          if (payload['new'] != null) {
            final data = HealthData.fromJson(payload['new']);
            onUpdate(data);
          }
        },
      )
      ..subscribe();
  }

  void dispose() {
    _channel?.unsubscribe();
  }
}