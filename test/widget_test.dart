// FamilyBridge Widget Test
//
// This test suite verifies core widget functionality and app initialization.
// Tests the main app widget and basic navigation behavior.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:family_bridge/main.dart';
import 'package:family_bridge/core/services/voice_service.dart';
import 'package:family_bridge/features/onboarding/providers/user_type_provider.dart';

import 'test_config.dart';
import 'helpers/test_helpers.dart';
import 'mocks/mock_services.dart';

void main() {
  setUpAll(() async {
    await TestConfig.initialize(environment: TestEnvironment.widget);
  });

  tearDownAll(() async {
    await TestConfig.tearDown();
  });

  group('FamilyBridge App Widget Tests', () {
    late MockVoiceService mockVoiceService;
    late SharedPreferences mockPrefs;
    late UserTypeProvider mockUserTypeProvider;

    setUp(() async {
      mockVoiceService = MockVoiceService();
      mockUserTypeProvider = UserTypeProvider();
      
      // Set up SharedPreferences mock
      SharedPreferences.setMockInitialValues({});
      mockPrefs = await SharedPreferences.getInstance();

      // Configure mock voice service
      when(mockVoiceService.initialize()).thenAnswer((_) async {});
      when(mockVoiceService.isInitialized).thenReturn(true);
    });

    testWidgets('FamilyBridge app initializes without errors', (WidgetTester tester) async {
      // Build the FamilyBridge app with mocked dependencies
      await tester.pumpWidget(
        FamilyBridgeApp(
          prefs: mockPrefs,
          voiceService: mockVoiceService,
          userTypeProvider: mockUserTypeProvider,
        ),
      );

      // Verify app builds successfully
      expect(tester.takeException(), isNull);
      
      // Allow for async operations to complete
      await tester.pumpAndSettle();

      // Verify MaterialApp is present
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Error app displays when initialization fails', (WidgetTester tester) async {
      const testError = 'Test initialization error';
      
      await tester.pumpWidget(
        const ErrorApp(error: testError),
      );

      await tester.pumpAndSettle();

      // Verify error screen elements
      expect(find.text('Failed to Start'), findsOneWidget);
      expect(find.text(testError), findsOneWidget);
      expect(find.text('Restart App'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('Error app restart button is interactive', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ErrorApp(error: 'Test error'),
      );

      await tester.pumpAndSettle();

      // Find and verify restart button
      final restartButton = find.text('Restart App');
      expect(restartButton, findsOneWidget);
      
      // Verify button is tappable (won't actually restart in test)
      await tester.tap(restartButton);
      await tester.pump();
      
      // No errors should occur
      expect(tester.takeException(), isNull);
    });

    testWidgets('App uses correct title', (WidgetTester tester) async {
      await tester.pumpWidget(
        FamilyBridgeApp(
          prefs: mockPrefs,
          voiceService: mockVoiceService,
          userTypeProvider: mockUserTypeProvider,
        ),
      );

      await tester.pumpAndSettle();

      // Find MaterialApp and check title
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.title, equals('FamilyBridge'));
    });

    // Additional test from main branch - simplified version
    testWidgets('App renders welcome screen', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final voiceService = VoiceService();
      final userTypeProvider = UserTypeProvider();

      await tester.pumpWidget(FamilyBridgeApp(
        prefs: prefs,
        voiceService: voiceService,
        userTypeProvider: userTypeProvider,
      ));

      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.text('FamilyBridge'), findsOneWidget);
    });
  });
}
