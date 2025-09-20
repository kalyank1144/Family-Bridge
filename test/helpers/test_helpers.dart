import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../lib/core/models/user_model.dart';
import '../../lib/core/services/auth_service.dart';
import '../../lib/features/auth/providers/auth_provider.dart';

Widget createTestableWidget({
  required Widget child,
  List<ChangeNotifierProvider>? providers,
  List<Provider>? valueProviders,
  NavigatorObserver? navigatorObserver,
  ThemeData? theme,
}) {
  return MultiProvider(
    providers: [
      ...?providers,
      ...?valueProviders ?? [],
    ],
    child: MaterialApp(
      theme: theme ?? ThemeData.light(),
      home: Scaffold(body: child),
      navigatorObservers: [
        if (navigatorObserver != null) navigatorObserver,
      ],
    ),
  );
}

Widget wrapWithMaterialApp(Widget widget, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? ThemeData.light(),
    home: Scaffold(body: widget),
  );
}

Future<void> pumpAndSettle(WidgetTester tester) async {
  await tester.pump();
  await tester.pumpAndSettle();
}

class TestData {
  static final testUser = UserProfile(
    id: 'test-user-123',
    email: 'test@example.com',
    name: 'Test User',
    role: UserRole.caregiver,
    familyId: 'test-family-456',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    phoneNumber: '+1234567890',
    profileImageUrl: 'https://example.com/avatar.jpg',
    dateOfBirth: DateTime(1990, 1, 1),
    accessibility: AccessibilitySettings(
      largeText: false,
      highContrast: false,
      voiceControl: false,
      screenReader: false,
    ),
    emergencyContacts: [],
    medications: [],
    healthConditions: [],
    preferences: UserPreferences(
      notificationsEnabled: true,
      theme: 'light',
      language: 'en',
    ),
  );

  static final elderUser = UserProfile(
    id: 'elder-user-123',
    email: 'elder@example.com',
    name: 'Elder User',
    role: UserRole.elder,
    familyId: 'test-family-456',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    phoneNumber: '+1234567890',
    accessibility: AccessibilitySettings(
      largeText: true,
      highContrast: true,
      voiceControl: true,
      screenReader: false,
    ),
    emergencyContacts: [],
    medications: [],
    healthConditions: [],
    preferences: UserPreferences(
      notificationsEnabled: true,
      theme: 'elder',
      language: 'en',
    ),
  );

  static final youthUser = UserProfile(
    id: 'youth-user-123',
    email: 'youth@example.com',
    name: 'Youth User',
    role: UserRole.youth,
    familyId: 'test-family-456',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    phoneNumber: '+1234567890',
    accessibility: AccessibilitySettings(
      largeText: false,
      highContrast: false,
      voiceControl: false,
      screenReader: false,
    ),
    emergencyContacts: [],
    medications: [],
    healthConditions: [],
    preferences: UserPreferences(
      notificationsEnabled: true,
      theme: 'youth',
      language: 'en',
    ),
  );
}

extension WidgetTesterExtension on WidgetTester {
  Future<void> pumpWidget(
    Widget widget, {
    Duration? duration,
    EnginePhase phase = EnginePhase.sendSemanticsUpdate,
  }) async {
    await this.binding.setSurfaceSize(const Size(414, 896));
    return TestAsyncUtils.guard<void>(() async {
      await binding.attachRootWidget(widget);
      await pump(duration, phase);
    });
  }
}