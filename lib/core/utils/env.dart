import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get supabaseUrl => const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: '',
      ).isNotEmpty
          ? const String.fromEnvironment('SUPABASE_URL')
          : (dotenv.maybeGet('SUPABASE_URL') ?? '');

  static String get supabaseAnonKey => const String.fromEnvironment(
        'SUPABASE_ANON_KEY',
        defaultValue: '',
      ).isNotEmpty
          ? const String.fromEnvironment('SUPABASE_ANON_KEY')
          : (dotenv.maybeGet('SUPABASE_ANON_KEY') ?? '');
}