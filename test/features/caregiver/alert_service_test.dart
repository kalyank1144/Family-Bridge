import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:family_bridge/features/caregiver/services/alert_service.dart';
import 'package:family_bridge/features/caregiver/models/alert_model.dart';
import 'package:family_bridge/features/shared/services/notification_service.dart';
import 'package:family_bridge/features/shared/services/logging_service.dart';

@GenerateMocks([
  SupabaseClient,
  SupabaseQueryBuilder,
  NotificationService,
  LoggingService,
])
import 'alert_service_test.mocks.dart';

void main() {
  group('AlertService', () {
    late AlertService alertService;
    late MockSupabaseClient mockSupabase;
    late MockNotificationService mockNotificationService;
    late MockLoggingService mockLogger;

    setUp(() {
      mockSupabase = MockSupabaseClient();
      mockNotificationService = MockNotificationService();
      mockLogger = MockLoggingService();
      
      alertService = AlertService();
      
      // Reset the singleton instance for testing
      AlertService._instance._supabase = mockSupabase;
      AlertService._instance._notificationService = mockNotificationService;
      AlertService._instance._logger = mockLogger;
    });

    group('createAlert', () {
      test('should create alert successfully', () async {
        // Arrange
        const familyId = 'test-family-id';
        const userId = 'test-user-id';
        const title = 'Test Alert';
        const message = 'Test alert message';

        when(mockSupabase.from('alerts')).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('alerts').insert(any)).thenAnswer((_) async => {});
        when(mockNotificationService.sendPushNotification(
          userId: anyNamed('userId'),
          title: anyNamed('title'),
          message: anyNamed('message'),
          data: anyNamed('data'),
        )).thenAnswer((_) async {});

        // Act
        final alert = await alertService.createAlert(
          familyId: familyId,
          userId: userId,
          type: AlertType.medicationMissed,
          severity: AlertSeverity.medium,
          title: title,
          message: message,
        );

        // Assert
        expect(alert.familyId, equals(familyId));
        expect(alert.userId, equals(userId));
        expect(alert.title, equals(title));
        expect(alert.message, equals(message));
        expect(alert.type, equals(AlertType.medicationMissed));
        expect(alert.severity, equals(AlertSeverity.medium));
        expect(alert.status, equals(AlertStatus.active));
        
        verify(mockSupabase.from('alerts').insert(any)).called(1);
        verify(mockLogger.info(any)).called(1);
      });

      test('should handle database error gracefully', () async {
        // Arrange
        const familyId = 'test-family-id';
        
        when(mockSupabase.from('alerts')).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('alerts').insert(any))
            .thenThrow(PostgrestException(message: 'Database error'));

        // Act & Assert
        expect(
          () => alertService.createAlert(
            familyId: familyId,
            type: AlertType.general,
            severity: AlertSeverity.low,
            title: 'Test',
            message: 'Test',
          ),
          throwsA(isA<AlertServiceException>()),
        );
      });
    });

    group('acknowledgeAlert', () {
      test('should acknowledge alert successfully', () async {
        // Arrange
        const alertId = 'test-alert-id';
        const acknowledgedBy = 'test-user-id';
        
        final alert = Alert(
          id: alertId,
          familyId: 'test-family-id',
          type: AlertType.general,
          severity: AlertSeverity.low,
          title: 'Test',
          message: 'Test',
          createdAt: DateTime.now(),
        );

        alertService._alertsCache[alertId] = alert;

        when(mockSupabase.from('alerts')).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('alerts').update(any)).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('alerts').update(any).eq('id', alertId))
            .thenAnswer((_) async => {});

        // Act
        await alertService.acknowledgeAlert(alertId, acknowledgedBy);

        // Assert
        final updatedAlert = alertService._alertsCache[alertId]!;
        expect(updatedAlert.status, equals(AlertStatus.acknowledged));
        expect(updatedAlert.acknowledgedBy, equals(acknowledgedBy));
        expect(updatedAlert.acknowledgedAt, isNotNull);
        
        verify(mockLogger.info(any)).called(1);
      });

      test('should throw exception for non-existent alert', () async {
        // Arrange
        const alertId = 'non-existent-alert-id';
        const acknowledgedBy = 'test-user-id';

        // Act & Assert
        expect(
          () => alertService.acknowledgeAlert(alertId, acknowledgedBy),
          throwsA(isA<AlertServiceException>()),
        );
      });
    });

    group('createMedicationAlert', () {
      test('should create medication missed alert', () async {
        // Arrange
        const familyId = 'test-family-id';
        const userId = 'test-user-id';
        const medicationId = 'test-medication-id';
        const medicationName = 'Aspirin';

        when(mockSupabase.from('alerts')).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('alerts').insert(any)).thenAnswer((_) async => {});

        // Act
        final alert = await alertService.createMedicationAlert(
          familyId: familyId,
          userId: userId,
          medicationId: medicationId,
          type: AlertType.medicationMissed,
          medicationName: medicationName,
        );

        // Assert
        expect(alert.type, equals(AlertType.medicationMissed));
        expect(alert.title, equals('Medication Missed'));
        expect(alert.message, equals('Missed dose of $medicationName'));
        expect(alert.data?['medication_id'], equals(medicationId));
        expect(alert.data?['medication_name'], equals(medicationName));
      });
    });

    group('getAlertStatistics', () {
      test('should return correct statistics', () async {
        // Arrange
        const familyId = 'test-family-id';
        
        final alerts = [
          Alert(
            id: '1',
            familyId: familyId,
            type: AlertType.general,
            severity: AlertSeverity.critical,
            title: 'Test 1',
            message: 'Test',
            status: AlertStatus.active,
            createdAt: DateTime.now(),
          ),
          Alert(
            id: '2',
            familyId: familyId,
            type: AlertType.general,
            severity: AlertSeverity.high,
            title: 'Test 2',
            message: 'Test',
            status: AlertStatus.acknowledged,
            createdAt: DateTime.now(),
          ),
          Alert(
            id: '3',
            familyId: familyId,
            type: AlertType.general,
            severity: AlertSeverity.medium,
            title: 'Test 3',
            message: 'Test',
            status: AlertStatus.resolved,
            createdAt: DateTime.now(),
          ),
        ];

        for (final alert in alerts) {
          alertService._alertsCache[alert.id] = alert;
        }

        when(mockSupabase.from('alerts')).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('alerts').select()).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('alerts').select().eq('family_id', familyId))
            .thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('alerts').select().eq('family_id', familyId).order('created_at', ascending: false))
            .thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('alerts').select().eq('family_id', familyId).order('created_at', ascending: false).limit(100))
            .thenAnswer((_) async => alerts.map((a) => a.toJson()).toList());

        // Act
        final stats = await alertService.getAlertStatistics(familyId);

        // Assert
        expect(stats['total'], equals(3));
        expect(stats['active'], equals(1));
        expect(stats['acknowledged'], equals(1));
        expect(stats['resolved'], equals(1));
        expect(stats['critical'], equals(1));
        expect(stats['high'], equals(1));
        expect(stats['medium'], equals(1));
      });
    });
  });
}

// Extension to access private members for testing
extension AlertServiceTestExtension on AlertService {
  Map<String, Alert> get _alertsCache => AlertService._instance._alertsCache;
}