import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/roles.dart';
import '../../auth/providers/auth_providers.dart';

class FamilyService {
  final SupabaseClient _client;
  FamilyService(this._client);

  String generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    return List.generate(6, (_) => chars[r.nextInt(chars.length)]).join();
  }

  Future<Map<String, dynamic>> createFamily({required String name}) async {
    final code = generateCode();
    final user = _client.auth.currentUser!;
    final inserted = await _client.from('families').insert({
      'name': name,
      'code': code,
      'owner_id': user.id,
    }).select().single();
    return inserted as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> getFamilyByCode(String code) async {
    final data = await _client.from('families').select().eq('code', code).maybeSingle();
    return data;
  }

  Future<void> joinFamily({required String familyId, required UserType role, String? relation}) async {
    final user = _client.auth.currentUser!;
    await _client.from('family_members').upsert({
      'family_id': familyId,
      'user_id': user.id,
      'role': role.name,
      'relation': relation,
    }, onConflict: 'family_id,user_id');
  }

  Future<List<Map<String, dynamic>>> familyMembers(String familyId) async {
    final data = await _client
        .from('family_members')
        .select('user_id, role, relation, profiles:profiles(id,email,user_type)')
        .eq('family_id', familyId);
    return (data as List).cast<Map<String, dynamic>>();
  }
}

final familyServiceProvider = Provider<FamilyService>((ref) => FamilyService(ref.watch(supabaseProvider)));