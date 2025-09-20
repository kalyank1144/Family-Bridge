/// Widget Tests for Elder Home Screen
/// 
/// Comprehensive testing of the Elder interface including:
/// - Large button interactions
/// - Voice navigation
/// - Accessibility features
/// - Emergency button functionality
/// - Simplified navigation

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:family_bridge/features/elder/screens/elder_home_screen.dart';
import 'package:family_bridge/features/elder/providers/elder_provider.dart';
import 'package:family_bridge/features/elder/widgets/large_action_button.dart';
import 'package:family_bridge/features/elder/widgets/voice_navigation_widget.dart';
import 'package:family_bridge/core/services/voice_service.dart';
import 'package:family_bridge/core/services/emergency_escalation_service.dart';
import 'package:family_bridge/core/theme/app_theme.dart';
import '../../../test_config.dart';
import '../../../mocks/mock_services.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  late ElderProvider mockElderProvider;
  late ConfigurableMockVoiceService mockVoiceService;
  late MockEmergencyEscalationService mockEmergencyService;
  late TestPerformanceTracker performanceTracker;
  late TestQualityMetrics qualityMetrics;
  
  setUpAll(() async {
    await TestConfig.initialize(env: TestEnvironment.widget);
    performanceTracker = TestPerformanceTracker();
    qualityMetrics = TestQualityMetrics();
  });
  
  setUp(() {
    mockElderProvider = MockElderProvider();
    mockVoiceService = ConfigurableMockVoiceService();
    mockEmergencyService = MockEmergencyEscalationService();
    
    when(mockElderProvider.userName).thenReturn('John');
    when(mockElderProvider.hasUnreadMessages).thenReturn(false);
    when(mockElderProvider.nextMedication).thenReturn(null);
    when(mockElderProvider.dailyCheckInCompleted).thenReturn(false);
  });
  
  tearDown(() async {
    mockVoiceService.dispose();
    await TestConfig.tearDown();
  });
  
  tearDownAll(() {
    print('\nElder Home Screen Widget Test Results:');
    print(qualityMetrics.getQualityReport());
    print('\nPerformance Metrics:');
    print(performanceTracker.getReport());
  });
  
  Widget createTestWidget(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ElderProvider>.value(
          value: mockElderProvider,
        ),
        Provider<VoiceService>.value(
          value: mockVoiceService,
        ),
        Provider<EmergencyEscalationService>.value(
          value: mockEmergencyService,
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.elderTheme,
        home: child,
      ),
    );
  }
  
  group('Screen Layout and Rendering', () {
    testWidgets('should render all main action buttons', (tester) async {
      final testName = 'elder_home_render_buttons';
      final stopwatch = performanceTracker.startTiming(testName);
      
      try {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(const ElderHomeScreen()));
        await tester.pumpAndSettle();
        
        // Assert
        expect(find.text('Daily Check-in'), findsOneWidget);
        expect(find.text('Medications'), findsOneWidget);
        expect(find.text('Family Chat'), findsOneWidget);
        expect(find.text('Emergency Contacts'), findsOneWidget);
        
        // Verify large buttons are present
        expect(find.byType(LargeActionButton), findsWidgets);
        
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
    
    testWidgets('should display emergency button prominently', (tester) async {
      final testName = 'elder_home_emergency_button';
      final stopwatch = performanceTracker.startTiming(testName);
      
      try {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(const ElderHomeScreen()));
        await tester.pumpAndSettle();
        
        // Assert
        final emergencyButton = find.widgetWithText(
          ElevatedButton,
          'EMERGENCY',
        );
        expect(emergencyButton, findsOneWidget);
        
        // Verify button is large and visible
        final button = tester.widget<ElevatedButton>(emergencyButton);
        expect(button.style?.backgroundColor?.resolve({}), Colors.red);
        
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
    
    testWidgets('should use large fonts and high contrast', (tester) async {
      final testName = 'elder_home_accessibility_visual';
      final stopwatch = performanceTracker.startTiming(testName);
      
      try {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(const ElderHomeScreen()));
        await tester.pumpAndSettle();
        
        // Assert - Check text size
        final greeting = find.text('Good morning, John');
        if (greeting.evaluate().isNotEmpty) {
          final greetingWidget = tester.widget<Text>(greeting);
          expect(
            greetingWidget.style?.fontSize ?? 0,
            greaterThanOrEqualTo(24),
          );
        }
        
        // Check button text size
        final buttonText = find.text('Daily Check-in');
        final textWidget = tester.widget<Text>(buttonText);
        expect(
          textWidget.style?.fontSize ?? 0,
          greaterThanOrEqualTo(20),
        );
        
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
  });
  
  group('Button Interactions', () {
    testWidgets('should navigate to daily check-in on button tap', (tester) async {
      final testName = 'elder_home_navigate_checkin';
      final stopwatch = performanceTracker.startTiming(testName);
      
      try {
        // Arrange
        await tester.pumpWidget(createTestWidget(const ElderHomeScreen()));
        await tester.pumpAndSettle();
        
        // Act
        await tester.tap(find.text('Daily Check-in'));
        await tester.pumpAndSettle();
        
        // Assert
        verify(mockElderProvider.navigateToDailyCheckIn()).called(1);
        
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
    
    testWidgets('should navigate to medications on button tap', (tester) async {
      final testName = 'elder_home_navigate_medications';
      final stopwatch = performanceTracker.startTiming(testName);
      
      try {
        // Arrange
        await tester.pumpWidget(createTestWidget(const ElderHomeScreen()));
        await tester.pumpAndSettle();
        
        // Act
        await tester.tap(find.text('Medications'));
        await tester.pumpAndSettle();
        
        // Assert
        verify(mockElderProvider.navigateToMedications()).called(1);
        
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
    
    testWidgets('should trigger emergency on emergency button tap', (tester) async {
      final testName = 'elder_home_emergency_trigger';
      final stopwatch = performanceTracker.startTiming(testName);
      
      try {
        // Arrange
        await tester.pumpWidget(createTestWidget(const ElderHomeScreen()));
        await tester.pumpAndSettle();
        
        // Act
        await tester.tap(find.text('EMERGENCY'));
        await tester.pump(); // Don't wait for settle due to dialog
        
        // Assert - Should show confirmation dialog
        expect(find.text('Emergency Help'), findsOneWidget);
        expect(find.text('Do you need emergency assistance?'), findsOneWidget);
        
        // Confirm emergency
        await tester.tap(find.text('YES, GET HELP'));
        await tester.pumpAndSettle();
        
        verify(mockEmergencyService.triggerSOS(any, any, any)).called(1);
        
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
    
    testWidgets('should handle long press for voice activation', (tester) async {
      final testName = 'elder_home_long_press_voice';
      final stopwatch = performanceTracker.startTiming(testName);
      
      try {
        // Arrange
        await tester.pumpWidget(createTestWidget(const ElderHomeScreen()));
        await tester.pumpAndSettle();
        
        // Act
        await tester.longPress(find.text('Family Chat'));
        await tester.pumpAndSettle();
        
        // Assert - Voice service should start listening
        verify(mockVoiceService.startListening()).called(1);
        
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
  });
  
  group('Voice Navigation', () {
    testWidgets('should show voice navigation widget', (tester) async {
      final testName = 'elder_home_voice_widget';
      final stopwatch = performanceTracker.startTiming(testName);
      
      try {
        // Arrange
        when(mockElderProvider.voiceNavigationEnabled).thenReturn(true);
        
        // Act
        await tester.pumpWidget(createTestWidget(const ElderHomeScreen()));
        await tester.pumpAndSettle();
        
        // Assert
        expect(find.byType(VoiceNavigationWidget), findsOneWidget);
        
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
    
    testWidgets('should respond to voice commands', (tester) async {
      final testName = 'elder_home_voice_commands';
      final stopwatch = performanceTracker.startTiming(testName);
      
      try {
        // Arrange
        await tester.pumpWidget(createTestWidget(const ElderHomeScreen()));
        await tester.pumpAndSettle();
        
        // Act - Simulate voice command
        mockVoiceService.simulateSpeechRecognition('Open medications');
        await tester.pumpAndSettle();
        
        // Assert
        verify(mockElderProvider.processVoiceCommand('Open medications')).called(1);
        
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
    
    testWidgets('should provide voice feedback', (tester) async {
      final testName = 'elder_home_voice_feedback';
      final stopwatch = performanceTracker.startTiming(testName);
      
      try {
        // Arrange
        await tester.pumpWidget(createTestWidget(const ElderHomeScreen()));
        await tester.pumpAndSettle();
        
        // Act
        await tester.tap(find.text('Daily Check-in'));
        await tester.pumpAndSettle();
        
        // Assert - Should speak feedback
        verify(mockVoiceService.speak('Opening Daily Check-in')).called(1);
        
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
  });
  
  group('Accessibility Features', () {
    testWidgets('should have proper semantic labels', (tester) async {
      final testName = 'elder_home_semantic_labels';
      final stopwatch = performanceTracker.startTiming(testName);
      
      try {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(const ElderHomeScreen()));
        await tester.pumpAndSettle();
        
        // Assert
        expect(
          find.bySemanticsLabel('Daily Check-in button'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('Medications button'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('Emergency help button'),
          findsOneWidget,
        );
        
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
    
    testWidgets('should support screen reader navigation', (tester) async {
      final testName = 'elder_home_screen_reader';
      final stopwatch = performanceTracker.startTiming(testName);
      
      try {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(const ElderHomeScreen()));
        await tester.pumpAndSettle();
        
        // Get semantic tree
        final semantics = tester.getSemantics(find.byType(ElderHomeScreen));
        
        // Assert
        expect(semantics.label, isNotNull);
        expect(semantics.hasAction(SemanticsAction.tap), isTrue);
        
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
    
    testWidgets('should handle keyboard navigation', (tester) async {
      final testName = 'elder_home_keyboard_navigation';
      final stopwatch = performanceTracker.startTiming(testName);
      
      try {
        // Arrange & Act
        await tester.pumpWidget(createTestWidget(const ElderHomeScreen()));
        await tester.pumpAndSettle();
        
        // Simulate tab key to focus first button
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        
        // Assert - First button should be focused
        final focusedWidget = Focus.of(
          tester.element(find.text('Daily Check-in')),
        );
        expect(focusedWidget.hasFocus, isTrue);
        
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
    
    testWidgets('should support high contrast mode', (tester) async {
      final testName = 'elder_home_high_contrast';
      final stopwatch = performanceTracker.startTiming(testName);
      
      try {
        // Arrange
        when(mockElderProvider.highContrastMode).thenReturn(true);
        
        // Act
        await tester.pumpWidget(createTestWidget(const ElderHomeScreen()));
        await tester.pumpAndSettle();
        
        // Assert - Check contrast ratios
        final buttonFinder = find.byType(LargeActionButton).first;
        final button = tester.widget<LargeActionButton>(buttonFinder);
        
        // High contrast mode should use black/white colors
        expect(button.backgroundColor, anyOf(Colors.black, Colors.white));
        
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
  });
  
  group('Notifications and Alerts', () {
    testWidgets('should show medication reminder', (tester) async {
      final testName = 'elder_home_medication_reminder';
      final stopwatch = performanceTracker.startTiming(testName);
      
      try {
        // Arrange
        when(mockElderProvider.nextMedication).thenReturn(
          MedicationReminder(
            name: 'Heart Medicine',
            time: TimeOfDay.now(),
            taken: false,
          ),
        );
        
        // Act
        await tester.pumpWidget(createTestWidget(const ElderHomeScreen()));
        await tester.pumpAndSettle();
        
        // Assert
        expect(find.text('Medication Reminder'), findsOneWidget);
        expect(find.text('Heart Medicine'), findsOneWidget);
        
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
    
    testWidgets('should show unread message indicator', (tester) async {
      final testName = 'elder_home_unread_messages';
      final stopwatch = performanceTracker.startTiming(testName);
      
      try {
        // Arrange
        when(mockElderProvider.hasUnreadMessages).thenReturn(true);
        when(mockElderProvider.unreadMessageCount).thenReturn(3);
        
        // Act
        await tester.pumpWidget(createTestWidget(const ElderHomeScreen()));
        await tester.pumpAndSettle();
        
        // Assert
        expect(find.text('3'), findsOneWidget); // Badge count
        expect(find.byIcon(Icons.circle), findsOneWidget); // Notification dot
        
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(testName, passed: true);
      } catch (e) {
        performanceTracker.recordTiming(testName, stopwatch);
        qualityMetrics.recordTestResult(
          testName,
          passed: false,
          failureReason: e.toString(),
        );
        rethrow;
      }
    });
  });
}