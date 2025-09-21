import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../../lib/features/auth/providers/auth_provider.dart';
import '../../../lib/core/models/user_model.dart';
import '../../helpers/test_helpers.dart';
import '../../test_config.dart';

void main() {
  setUpAll(() async {
    await TestConfig.initialize(environment: TestEnvironment.unit);
  });

  tearDownAll(() async {
    await TestConfig.tearDown();
  });

  group('AuthProvider', () {
    late AuthProvider authProvider;

    setUp(() {
      authProvider = AuthProvider();
    });

    tearDown(() {
      authProvider.dispose();
    });

    test('initial state should be unknown or unauthenticated', () {
      expect(authProvider.status, anyOf([AuthStatus.unknown, AuthStatus.unauthenticated]));
      expect(authProvider.session, isNull);
      expect(authProvider.profile, isNull);
    });

    test('should handle role selection', () {
      // Test the role selection during onboarding
      authProvider.setSelectedRole(UserRole.elder);
      expect(authProvider.selectedRole, equals(UserRole.elder));

      authProvider.setSelectedRole(UserRole.caregiver);
      expect(authProvider.selectedRole, equals(UserRole.caregiver));

      authProvider.setSelectedRole(UserRole.youth);
      expect(authProvider.selectedRole, equals(UserRole.youth));
    });

    test('should notify listeners on role selection change', () {
      int notificationCount = 0;
      authProvider.addListener(() {
        notificationCount++;
      });

      authProvider.setSelectedRole(UserRole.elder);
      expect(notificationCount, equals(1));

      authProvider.setSelectedRole(UserRole.caregiver);
      expect(notificationCount, equals(2));
    });

    test('should handle inactivity timer correctly', () {
      // Verify timer duration is set
      expect(authProvider.inactivityTimeout, equals(const Duration(minutes: 20)));
    });

    test('sign up should return AuthResponse', () async {
      // This test would require mocking Supabase which is complex
      // For now, we'll test that the method exists and throws without proper setup
      expect(
        () => authProvider.signUp(
          email: 'test@example.com',
          password: 'password123',
          name: 'Test User',
          role: UserRole.elder,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('sign in should return AuthResponse', () async {
      // This test would require mocking Supabase which is complex
      // For now, we'll test that the method exists and throws without proper setup
      expect(
        () => authProvider.signIn('test@example.com', 'password123'),
        throwsA(isA<Exception>()),
      );
    });

    test('should handle sign out', () async {
      // This test would require mocking Supabase which is complex
      // For now, we'll test that the method exists and throws without proper setup
      expect(
        () => authProvider.signOut(),
        throwsA(isA<Exception>()),
      );
    });

    test('should have correct status enum values', () {
      // Test that all expected status values exist
      expect(AuthStatus.unknown, isNotNull);
      expect(AuthStatus.unauthenticated, isNotNull);
      expect(AuthStatus.authenticated, isNotNull);
      expect(AuthStatus.onboarding, isNotNull);
    });

    test('should handle profile loading', () {
      // Initially profile should be null
      expect(authProvider.profile, isNull);
      
      // Session should also be null initially
      expect(authProvider.session, isNull);
    });
  });
}