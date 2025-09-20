import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Supabase connectivity', () {
    setUpAll(() async {
      await dotenv.load(fileName: '.env', isOptional: true);
    });

    test('initializes when env vars are present', () async {
      final url = dotenv.maybeGet('SUPABASE_URL') ?? '';
      final key = dotenv.maybeGet('SUPABASE_ANON_KEY') ?? '';

      if (url.isEmpty || key.isEmpty) {
        return; // Skip if not configured
      }

      await Supabase.initialize(url: url, anonKey: key);
      final client = Supabase.instance.client;
      expect(client, isNotNull);
    });
  });
}
