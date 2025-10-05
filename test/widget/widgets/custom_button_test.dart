import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/shared/widgets/buttons/custom_button.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('CustomButton Widget Tests', () {
    testWidgets('renders with correct label', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          CustomButton(
            label: 'Test Button',
            onPressed: () {},
          ),
        ),
      );

      expect(find.text('Test Button'), findsOneWidget);
      expect(find.byType(CustomButton), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        wrapWithMaterialApp(
          CustomButton(
            label: 'Tap Me',
            onPressed: () => wasPressed = true,
          ),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      await tester.pump();

      expect(wasPressed, isTrue);
    });

    testWidgets('shows loading indicator when loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          CustomButton(
            label: 'Loading',
            onPressed: () {},
            isLoading: true,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading'), findsNothing);
    });

    testWidgets('is disabled when onPressed is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          const CustomButton(
            label: 'Disabled',
            onPressed: null,
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );

      expect(button.onPressed, isNull);
    });

    testWidgets('applies custom style when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          CustomButton(
            label: 'Styled',
            onPressed: () {},
            backgroundColor: Colors.red,
            textColor: Colors.white,
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );

      expect(
        button.style?.backgroundColor?.resolve({}),
        equals(Colors.red),
      );
    });

    testWidgets('shows icon when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          CustomButton(
            label: 'With Icon',
            onPressed: () {},
            icon: Icons.add,
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('With Icon'), findsOneWidget);
    });

    testWidgets('applies correct size variants', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          Column(
            children: [
              CustomButton(
                label: 'Small',
                onPressed: () {},
                size: ButtonSize.small,
              ),
              CustomButton(
                label: 'Medium',
                onPressed: () {},
                size: ButtonSize.medium,
              ),
              CustomButton(
                label: 'Large',
                onPressed: () {},
                size: ButtonSize.large,
              ),
            ],
          ),
        ),
      );

      expect(find.text('Small'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Large'), findsOneWidget);

      final smallButton = tester.getSize(find.text('Small').first);
      final mediumButton = tester.getSize(find.text('Medium').first);
      final largeButton = tester.getSize(find.text('Large').first);

      expect(smallButton.height < mediumButton.height, isTrue);
      expect(mediumButton.height < largeButton.height, isTrue);
    });

    testWidgets('has proper accessibility labels', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          CustomButton(
            label: 'Accessible',
            onPressed: () {},
            semanticLabel: 'Tap to perform action',
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(CustomButton));
      expect(semantics.label, contains('Tap to perform action'));
      expect(semantics.hasAction(SemanticsAction.tap), isTrue);
    });

    testWidgets('handles long press when configured', (WidgetTester tester) async {
      bool wasLongPressed = false;

      await tester.pumpWidget(
        wrapWithMaterialApp(
          CustomButton(
            label: 'Long Press',
            onPressed: () {},
            onLongPress: () => wasLongPressed = true,
          ),
        ),
      );

      await tester.longPress(find.text('Long Press'));
      await tester.pump();

      expect(wasLongPressed, isTrue);
    });

    testWidgets('adapts to theme', (WidgetTester tester) async {
      final lightTheme = ThemeData.light();
      final darkTheme = ThemeData.dark();

      await tester.pumpWidget(
        MaterialApp(
          theme: lightTheme,
          home: Scaffold(
            body: CustomButton(
              label: 'Theme Test',
              onPressed: () {},
            ),
          ),
        ),
      );

      var button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      final lightBackground = button.style?.backgroundColor?.resolve({});

      await tester.pumpWidget(
        MaterialApp(
          theme: darkTheme,
          home: Scaffold(
            body: CustomButton(
              label: 'Theme Test',
              onPressed: () {},
            ),
          ),
        ),
      );

      button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      final darkBackground = button.style?.backgroundColor?.resolve({});

      expect(lightBackground != darkBackground, isTrue);
    });
  });
}