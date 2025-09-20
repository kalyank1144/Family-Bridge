import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:family_bridge/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('FamilyBridge App Integration Tests', () {
    testWidgets('Complete onboarding flow for elder user', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      expect(find.text('Welcome to FamilyBridge'), findsOneWidget);

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      expect(find.text('Select Your Role'), findsOneWidget);
      
      await tester.tap(find.text('Elder'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Let\'s Set Up Your Profile'), findsOneWidget);
      
      await tester.enterText(find.byKey(const Key('nameField')), 'John Doe');
      await tester.enterText(find.byKey(const Key('phoneField')), '+1234567890');
      
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Accessibility Settings'), findsOneWidget);
      
      await tester.tap(find.text('Large Text'));
      await tester.tap(find.text('Voice Control'));
      
      await tester.tap(find.text('Complete Setup'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome, John!'), findsOneWidget);
      expect(find.byType(ElderHomeScreen), findsOneWidget);
    });

    testWidgets('Login flow with valid credentials', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Already have an account? Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back'), findsOneWidget);
      
      await tester.enterText(
        find.byKey(const Key('emailField')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('passwordField')),
        'password123',
      );
      
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('Elder daily check-in flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      await _loginAsElder(tester);

      await tester.tap(find.text('Daily Check-in'));
      await tester.pumpAndSettle();

      expect(find.text('How are you feeling today?'), findsOneWidget);
      
      await tester.tap(find.text('Good'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Did you take your medications?'), findsOneWidget);
      
      await tester.tap(find.text('Yes, all taken'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Complete Check-in'));
      await tester.pumpAndSettle();

      expect(find.text('Check-in Complete!'), findsOneWidget);
    });

    testWidgets('Caregiver health monitoring flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      await _loginAsCaregiver(tester);

      await tester.tap(find.text('Health Monitoring'));
      await tester.pumpAndSettle();

      expect(find.text('Family Health Overview'), findsOneWidget);
      
      await tester.tap(find.text('John Doe'));
      await tester.pumpAndSettle();

      expect(find.text('Health Details'), findsOneWidget);
      expect(find.text('Vitals'), findsOneWidget);
      expect(find.text('Medications'), findsOneWidget);
      
      await tester.tap(find.text('Add Vital'));
      await tester.pumpAndSettle();
      
      await tester.enterText(
        find.byKey(const Key('bloodPressureField')),
        '120/80',
      );
      await tester.enterText(
        find.byKey(const Key('heartRateField')),
        '72',
      );
      
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Vitals saved successfully'), findsOneWidget);
    });

    testWidgets('Youth story recording flow', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      await _loginAsYouth(tester);

      await tester.tap(find.text('Record Story'));
      await tester.pumpAndSettle();

      expect(find.text('Share Your Story'), findsOneWidget);
      
      await tester.tap(find.byIcon(Icons.mic));
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      await tester.tap(find.byIcon(Icons.stop));
      await tester.pumpAndSettle();

      expect(find.text('Great recording!'), findsOneWidget);
      
      await tester.enterText(
        find.byKey(const Key('storyTitleField')),
        'My School Day',
      );
      
      await tester.tap(find.text('Share with Family'));
      await tester.pumpAndSettle();

      expect(find.text('Story shared!'), findsOneWidget);
      expect(find.text('+10 Care Points'), findsOneWidget);
    });

    testWidgets('Family chat interaction', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      await _loginAsCaregiver(tester);

      await tester.tap(find.byIcon(Icons.chat));
      await tester.pumpAndSettle();

      expect(find.text('Family Chat'), findsOneWidget);
      
      await tester.enterText(
        find.byKey(const Key('messageField')),
        'Hello family!',
      );
      
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(find.text('Hello family!'), findsOneWidget);
      
      await tester.longPress(find.text('Hello family!'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('❤️'));
      await tester.pumpAndSettle();

      expect(find.text('❤️'), findsOneWidget);
    });

    testWidgets('Emergency contact quick access', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      await _loginAsElder(tester);

      await tester.tap(find.text('Emergency'));
      await tester.pumpAndSettle();

      expect(find.text('Emergency Contacts'), findsOneWidget);
      expect(find.text('Doctor'), findsOneWidget);
      expect(find.text('Family'), findsOneWidget);
      
      await tester.tap(find.text('Call Doctor'));
      await tester.pumpAndSettle();

      expect(find.text('Calling Dr. Smith...'), findsOneWidget);
    });

    testWidgets('Accessibility features work correctly', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      await _loginAsElder(tester);

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Accessibility'));
      await tester.pumpAndSettle();

      final largeTextSwitch = find.byKey(const Key('largeTextSwitch'));
      await tester.tap(largeTextSwitch);
      await tester.pumpAndSettle();

      final textWidget = find.text('Settings').first;
      final fontSize1 = tester.widget<Text>(textWidget).style?.fontSize ?? 14;
      
      expect(fontSize1, greaterThan(14));

      final voiceControlSwitch = find.byKey(const Key('voiceControlSwitch'));
      await tester.tap(voiceControlSwitch);
      await tester.pumpAndSettle();

      expect(find.text('Voice control enabled'), findsOneWidget);
    });
  });
}

Future<void> _loginAsElder(WidgetTester tester) async {
  await tester.tap(find.text('Already have an account? Sign In'));
  await tester.pumpAndSettle();
  
  await tester.enterText(
    find.byKey(const Key('emailField')),
    'elder@example.com',
  );
  await tester.enterText(
    find.byKey(const Key('passwordField')),
    'password123',
  );
  
  await tester.tap(find.text('Sign In'));
  await tester.pumpAndSettle(const Duration(seconds: 3));
}

Future<void> _loginAsCaregiver(WidgetTester tester) async {
  await tester.tap(find.text('Already have an account? Sign In'));
  await tester.pumpAndSettle();
  
  await tester.enterText(
    find.byKey(const Key('emailField')),
    'caregiver@example.com',
  );
  await tester.enterText(
    find.byKey(const Key('passwordField')),
    'password123',
  );
  
  await tester.tap(find.text('Sign In'));
  await tester.pumpAndSettle(const Duration(seconds: 3));
}

Future<void> _loginAsYouth(WidgetTester tester) async {
  await tester.tap(find.text('Already have an account? Sign In'));
  await tester.pumpAndSettle();
  
  await tester.enterText(
    find.byKey(const Key('emailField')),
    'youth@example.com',
  );
  await tester.enterText(
    find.byKey(const Key('passwordField')),
    'password123',
  );
  
  await tester.tap(find.text('Sign In'));
  await tester.pumpAndSettle(const Duration(seconds: 3));
}