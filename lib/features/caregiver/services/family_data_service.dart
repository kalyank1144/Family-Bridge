import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:family_bridge/features/caregiver/models/family_member.dart';

class FamilyDataService {
  final SupabaseClient _supabase = Supabase.instance.client;
  RealtimeChannel? _channel;

  Future<List<FamilyMember>> getFamilyMembers() async {
    try {
      final response = await _supabase
          .from('family_members')
          .select()
          .order('name', ascending: true);
      
      return (response as List)
          .map((json) => FamilyMember.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load family members: $e');
    }
  }

  Future<FamilyMember> getFamilyMemberById(String id) async {
    try {
      final response = await _supabase
          .from('family_members')
          .select()
          .eq('id', id)
          .single();
      
      return FamilyMember.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load family member: $e');
    }
  }

  Future<void> updateFamilyMember(FamilyMember member) async {
    try {
      await _supabase
          .from('family_members')
          .update(member.toJson())
          .eq('id', member.id);
    } catch (e) {
      throw Exception('Failed to update family member: $e');
    }
  }

  void subscribeToFamilyUpdates(Function(FamilyMember) onUpdate) {
    _channel = _supabase.channel('family_updates')
      ..on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: '*',
          schema: 'public',
          table: 'family_members',
        ),
        (payload, [ref]) {
          if (payload['new'] != null) {
            final member = FamilyMember.fromJson(payload['new']);
            onUpdate(member);
          }
        },
      )
      ..subscribe();
  }

  void dispose() {
    _channel?.unsubscribe();
  }
}