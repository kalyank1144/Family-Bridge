import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/roles.dart';
import '../../../services/supabase_client.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.read(authRepositoryProvider).authStateChanges();
});

final authUserProvider = Provider<User?>((ref) {
  final state = ref.watch(authStateChangesProvider).value;
  return state?.session?.user ?? SupabaseService.client.auth.currentUser;
});

final userTypeProvider = FutureProvider<UserType?>((ref) async {
  final user = ref.watch(authUserProvider);
  if (user == null) return null;
  final res = await SupabaseService.client
      .from('users')
      .select('user_type')
      .eq('id', user.id)
      .maybeSingle();
  final type = (res?['user_type'] as String?)?.toLowerCase();
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
