import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:family_bridge/config/app_config.dart';

class SupabaseService {
  static SupabaseClient? _client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }

  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase client not initialized. Call initialize() first.');
    }
    return _client!;
  }

  static User? get currentUser => _client?.auth.currentUser;

  static bool get isAuthenticated => currentUser != null;

  static Stream<AuthState> get authStateChanges => 
      _client!.auth.onAuthStateChange;
}
