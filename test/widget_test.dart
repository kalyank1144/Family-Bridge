import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:family_bridge/main.dart';
import 'package:family_bridge/core/services/voice_service.dart';
import 'package:family_bridge/features/onboarding/providers/user_type_provider.dart';

void main() {
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
}
