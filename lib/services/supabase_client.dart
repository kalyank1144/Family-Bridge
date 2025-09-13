import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/env.dart';

Future<void> initializeSupabase() async {
  if (kSupabaseUrl.isEmpty || kSupabaseAnonKey.isEmpty) {
    return;
  }
  await Supabase.initialize(
    url: kSupabaseUrl,
    anonKey: kSupabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(autoRefreshToken: true, persistSession: true),
  );
}
