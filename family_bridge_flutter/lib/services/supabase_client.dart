import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
}

class SupabaseService {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
      realtimeClientOptions: const RealtimeClientOptions(
        eventsPerSecond: 20,
        logLevel: RealtimeLogLevel.info,
      ),
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: true, persistSession: true),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
