import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/roles.dart';
import '../data/auth_repository.dart';

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
