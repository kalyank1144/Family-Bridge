import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/roles.dart';
import '../data/auth_repository.dart';
import '../services/auth_service.dart';
import '../services/family_service.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

final authStateProvider = StreamProvider<User?>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return supabase.auth.onAuthStateChange.map((event) => event.session?.user);
});

final profileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = await ref.watch(authStateProvider.future);
  if (user == null) return null;
  final data = await ref.read(supabaseProvider)
      .from('profiles')
      .select()
      .eq('id', user.id)
      .single();
  return data;
});

final userRoleProvider = Provider<UserType?>((ref) {
  final profile = ref.watch(profileProvider).maybeWhen(data: (p) => p, orElse: () => null);
  final type = profile?['user_type'] as String?;
  switch (type) {
    case 'elder':
      return UserType.elder;
    case 'caregiver':
      return UserType.caregiver;
    case 'youth':
      return UserType.youth;
    default:
      return null;
  }
});

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(ref.watch(supabaseProvider)));

final authServiceProvider = Provider<AuthService>((ref) => AuthService(ref.watch(supabaseProvider)));
final familyServiceProvider = Provider<FamilyService>((ref) => FamilyService(ref.watch(supabaseProvider)));

final selectedRoleProvider = StateProvider<UserType?>((ref) => null);

final currentFamilyProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = await ref.watch(authStateProvider.future);
  if (user == null) return null;
  final data = await ref.read(supabaseProvider)
      .from('family_members')
      .select('family_id, families:families(id,name,code,owner_id)')
      .eq('user_id', user.id)
      .limit(1)
      .maybeSingle();
  if (data == null) return null;
  return (data['families'] as Map).cast<String, dynamic>();
});

final familyMembersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final family = await ref.watch(currentFamilyProvider.future);
  if (family == null) return [];
  final rows = await ref.read(supabaseProvider)
      .from('family_members')
      .select('user_id, role, relation, profiles:profiles(id,email,user_type)')
      .eq('family_id', family['id']);
  return (rows as List).cast<Map<String, dynamic>>();
});

class Permissions {
  final bool canManageFamily;
  final bool canViewHealth;
  final bool canPostStories;
  const Permissions({required this.canManageFamily, required this.canViewHealth, required this.canPostStories});
}

final permissionProvider = Provider<Permissions>((ref) {
  final role = ref.watch(userRoleProvider);
  switch (role) {
    case UserType.elder:
      return const Permissions(canManageFamily: false, canViewHealth: true, canPostStories: true);
    case UserType.caregiver:
      return const Permissions(canManageFamily: true, canViewHealth: true, canPostStories: true);
    case UserType.youth:
      return const Permissions(canManageFamily: false, canViewHealth: false, canPostStories: true);
    default:
      return const Permissions(canManageFamily: false, canViewHealth: false, canPostStories: false);
  }
});
