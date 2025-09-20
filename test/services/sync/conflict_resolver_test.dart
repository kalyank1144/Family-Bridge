import 'package:flutter_test/flutter_test.dart';
import 'package:family_bridge/services/sync/conflict_resolver.dart';

void main() {
  group('ConflictResolver', () {
    test('lastWriteWins chooses newer updated_at', () {
      final local = {
        'id': '1',
        'prefs': {'theme': 'dark'},
        'updated_at': DateTime(2024, 1, 2).toIso8601String(),
      };
      final remote = {
        'id': '1',
        'prefs': {'theme': 'light'},
        'updated_at': DateTime(2024, 1, 1).toIso8601String(),
      };

      final r = ConflictResolver.resolve(
        local: local,
        remote: remote,
        strategy: ConflictStrategy.lastWriteWins,
      );

      expect(r['prefs']['theme'], 'dark');
    });

    test('merge combines arrays uniquely', () {
      final local = {
        'id': 'h1',
        'symptoms': ['cough', 'fever'],
        'tags': ['morning'],
        'updated_at': DateTime(2024, 1, 2).toIso8601String(),
      };
      final remote = {
        'id': 'h1',
        'symptoms': ['fever', 'nausea'],
        'tags': ['night'],
        'updated_at': DateTime(2024, 1, 1).toIso8601String(),
      };

      final r = ConflictResolver.resolve(
        local: local,
        remote: remote,
        strategy: ConflictStrategy.merge,
        mergeArrayKeys: const ['symptoms', 'tags'],
      );

      expect(r['symptoms'], containsAll(['cough', 'fever', 'nausea']));
      expect(r['tags'], containsAll(['morning', 'night']));
    });
  });
}
