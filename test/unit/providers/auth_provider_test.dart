import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../../lib/features/auth/providers/auth_provider.dart';
import '../../../lib/core/services/auth_service.dart';
import '../../../lib/core/models/user_model.dart';
import '../../helpers/test_helpers.dart';
import '../../helpers/mocks.dart';

@GenerateMocks([AuthService])
void main() {
  group('AuthProvider', () {
    late AuthProvider authProvider;
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
      authProvider = AuthProvider();
      authProvider.dispose();
    });

    tearDown(() {
      authProvider.dispose();
    });

    test('initial state should be unauthenticated', () {
      expect(authProvider.status, equals(AuthStatus.unknown));
      expect(authProvider.session, isNull);
      expect(authProvider.profile, isNull);
    });

    test('login should update state on success', () async {
      final testUser = TestData.testUser;
      when(mockAuthService.signIn(
        email: 'test@example.com',
        password: 'password123',
      )).thenAnswer((_) async => testUser);

      bool wasNotified = false;
      authProvider.addListener(() {
        wasNotified = true;
      });

      await authProvider.login('test@example.com', 'password123');

      expect(wasNotified, isTrue);
      expect(authProvider.status, equals(AuthStatus.authenticated));
      expect(authProvider.profile, isNotNull);
      expect(authProvider.profile?.email, equals('test@example.com'));
    });

    test('login should handle errors gracefully', () async {
      when(mockAuthService.signIn(
        email: any,
        password: any,
      )).thenThrow(Exception('Invalid credentials'));

      bool wasNotified = false;
      authProvider.addListener(() {
        wasNotified = true;
      });

      try {
        await authProvider.login('test@example.com', 'wrongpassword');
      } catch (e) {
        expect(e.toString(), contains('Invalid credentials'));
      }

      expect(wasNotified, isTrue);
      expect(authProvider.status, equals(AuthStatus.unauthenticated));
      expect(authProvider.profile, isNull);
    });

    test('logout should clear session and profile', () async {
      authProvider.setStatus(AuthStatus.authenticated);
      authProvider.setProfile(TestData.testUser);

      when(mockAuthService.signOut()).thenAnswer((_) async {});

      await authProvider.logout();

      expect(authProvider.status, equals(AuthStatus.unauthenticated));
      expect(authProvider.session, isNull);
      expect(authProvider.profile, isNull);
    });

    test('should detect user role correctly', () {
      authProvider.setProfile(TestData.elderUser);
      expect(authProvider.profile?.role, equals(UserRole.elder));

      authProvider.setProfile(TestData.youthUser);
      expect(authProvider.profile?.role, equals(UserRole.youth));

      authProvider.setProfile(TestData.testUser);
      expect(authProvider.profile?.role, equals(UserRole.caregiver));
    });

    test('should handle session expiry', () async {
      final expiredSession = FakeSession();
      authProvider.setSession(expiredSession);

      await Future.delayed(const Duration(seconds: 1));

      expect(authProvider.isSessionExpired, isTrue);
    });

    test('should notify listeners on state change', () {
      int notificationCount = 0;
      authProvider.addListener(() {
        notificationCount++;
      });

      authProvider.setStatus(AuthStatus.authenticated);
      expect(notificationCount, equals(1));

      authProvider.setProfile(TestData.testUser);
      expect(notificationCount, equals(2));

      authProvider.setStatus(AuthStatus.unauthenticated);
      expect(notificationCount, equals(3));
    });

    test('should handle role-based access control', () {
      authProvider.setProfile(TestData.elderUser);
      expect(authProvider.canAccessElderFeatures, isTrue);
      expect(authProvider.canAccessCaregiverFeatures, isFalse);
      expect(authProvider.canAccessYouthFeatures, isFalse);

      authProvider.setProfile(TestData.testUser);
      expect(authProvider.canAccessElderFeatures, isFalse);
      expect(authProvider.canAccessCaregiverFeatures, isTrue);
      expect(authProvider.canAccessYouthFeatures, isFalse);

      authProvider.setProfile(TestData.youthUser);
      expect(authProvider.canAccessElderFeatures, isFalse);
      expect(authProvider.canAccessCaregiverFeatures, isFalse);
      expect(authProvider.canAccessYouthFeatures, isTrue);
    });

    test('should handle accessibility settings', () {
      authProvider.setProfile(TestData.elderUser);
      expect(authProvider.profile?.accessibility.largeText, isTrue);
      expect(authProvider.profile?.accessibility.highContrast, isTrue);
      expect(authProvider.profile?.accessibility.voiceControl, isTrue);

      authProvider.setProfile(TestData.testUser);
      expect(authProvider.profile?.accessibility.largeText, isFalse);
      expect(authProvider.profile?.accessibility.highContrast, isFalse);
      expect(authProvider.profile?.accessibility.voiceControl, isFalse);
    });

    test('should track inactivity timeout', () async {
      authProvider.setStatus(AuthStatus.authenticated);
      authProvider.setProfile(TestData.testUser);

      authProvider.resetInactivityTimer();
      expect(authProvider.isInactive, isFalse);

      await Future.delayed(authProvider.inactivityTimeout + const Duration(seconds: 1));
      expect(authProvider.isInactive, isTrue);
    });
  });
}