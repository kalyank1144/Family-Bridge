import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:family_bridge/features/elder/services/medication_service.dart';
import 'package:family_bridge/features/elder/models/medication_model.dart';
import 'package:family_bridge/features/shared/services/notification_service.dart';
import 'package:family_bridge/features/shared/services/logging_service.dart';
import 'package:family_bridge/features/chat/services/media_service.dart';

@GenerateMocks([
  SupabaseClient,
  SupabaseQueryBuilder,
  NotificationService,
  LoggingService,
  MediaService,
])
import 'medication_service_test.mocks.dart';

void main() {
  group('ElderMedicationService', () {
    late ElderMedicationService medicationService;
    late MockSupabaseClient mockSupabase;
    late MockNotificationService mockNotificationService;
    late MockLoggingService mockLogger;
    late MockMediaService mockMediaService;

    setUp(() {
      mockSupabase = MockSupabaseClient();
      mockNotificationService = MockNotificationService();
      mockLogger = MockLoggingService();
      mockMediaService = MockMediaService();
      
      medicationService = ElderMedicationService();
      
      // Reset the singleton instance for testing
      ElderMedicationService._instance._supabase = mockSupabase;
      ElderMedicationService._instance._notificationService = mockNotificationService;
      ElderMedicationService._instance._logger = mockLogger;
      ElderMedicationService._instance._mediaService = mockMediaService;
    });

    group('addMedication', () {
      test('should add medication successfully without photo', () async {
        // Arrange
        const userId = 'test-user-id';
        const medicationName = 'Aspirin';
        const dosage = '100mg';
        const frequency = 'Once daily';
        const reminderTimes = ['08:00', '20:00'];

        when(mockSupabase.from('medications')).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('medications').insert(any)).thenAnswer((_) async => {});
        when(mockSupabase.from('medication_reminders')).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('medication_reminders').insert(any)).thenAnswer((_) async => {});

        // Act
        final medication = await medicationService.addMedication(
          userId: userId,
          medicationName: medicationName,
          dosage: dosage,
          frequency: frequency,
          reminderTimes: reminderTimes,
        );

        // Assert
        expect(medication.userId, equals(userId));
        expect(medication.medicationName, equals(medicationName));
        expect(medication.dosage, equals(dosage));
        expect(medication.frequency, equals(frequency));
        expect(medication.reminderTimes, equals(reminderTimes));
        expect(medication.isActive, isTrue);
        expect(medication.photoUrl, isNull);
        
        verify(mockSupabase.from('medications').insert(any)).called(1);
        verify(mockLogger.info(any)).called(1);
      });

      test('should add medication with photo', () async {
        // Arrange
        const userId = 'test-user-id';
        const medicationName = 'Aspirin';
        const dosage = '100mg';
        const frequency = 'Once daily';
        const reminderTimes = ['08:00'];
        const photoUrl = 'https://example.com/photo.jpg';
        
        final mockPhoto = MockFile();
        
        when(mockMediaService.uploadMedia(
          file: anyNamed('file'),
          bucket: anyNamed('bucket'),
          familyId: anyNamed('familyId'),
          userId: anyNamed('userId'),
          folder: anyNamed('folder'),
        )).thenAnswer((_) async => photoUrl);

        when(mockSupabase.from('medications')).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('medications').insert(any)).thenAnswer((_) async => {});
        when(mockSupabase.from('medication_reminders')).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('medication_reminders').insert(any)).thenAnswer((_) async => {});

        // Act
        final medication = await medicationService.addMedication(
          userId: userId,
          medicationName: medicationName,
          dosage: dosage,
          frequency: frequency,
          reminderTimes: reminderTimes,
          medicationPhoto: mockPhoto,
        );

        // Assert
        expect(medication.photoUrl, equals(photoUrl));
        verify(mockMediaService.uploadMedia(
          file: mockPhoto,
          bucket: 'medication-photos',
          familyId: userId,
          userId: userId,
          folder: 'medications',
        )).called(1);
      });

      test('should create recurring reminders', () async {
        // Arrange
        const userId = 'test-user-id';
        const medicationName = 'Aspirin';
        const dosage = '100mg';
        const frequency = 'Twice daily';
        const reminderTimes = ['08:00', '20:00'];

        when(mockSupabase.from('medications')).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('medications').insert(any)).thenAnswer((_) async => {});
        when(mockSupabase.from('medication_reminders')).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('medication_reminders').insert(any)).thenAnswer((_) async => {});

        // Act
        await medicationService.addMedication(
          userId: userId,
          medicationName: medicationName,
          dosage: dosage,
          frequency: frequency,
          reminderTimes: reminderTimes,
        );

        // Assert
        // Verify that reminders were created (multiple calls expected for recurring reminders)
        verify(mockSupabase.from('medication_reminders').insert(any)).called(greaterThan(1));
      });
    });

    group('recordMedicationTaken', () {
      test('should record medication as taken without verification photo', () async {
        // Arrange
        const reminderId = 'test-reminder-id';
        const userId = 'test-user-id';
        const notes = 'Took with breakfast';

        when(mockSupabase.from('medication_reminders')).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('medication_reminders').update(any)).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('medication_reminders').update(any).eq('id', reminderId))
            .thenAnswer((_) async => {});
        when(mockSupabase.from('medication_logs')).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('medication_logs').insert(any)).thenAnswer((_) async => {});
        when(mockNotificationService.cancelNotification(any)).thenAnswer((_) async {});

        // Act
        await medicationService.recordMedicationTaken(
          reminderId: reminderId,
          userId: userId,
          notes: notes,
        );

        // Assert
        verify(mockSupabase.from('medication_reminders').update({
          'status': 'taken',
          'taken_time': anyNamed('taken_time'),
          'verification_photo_url': null,
          'notes': notes,
          'updated_at': anyNamed('updated_at'),
        }).eq('id', reminderId)).called(1);
        
        verify(mockSupabase.from('medication_logs').insert(any)).called(1);
        verify(mockNotificationService.cancelNotification(reminderId.hashCode)).called(1);
        verify(mockLogger.info(any)).called(1);
      });

      test('should record medication as taken with verification photo', () async {
        // Arrange
        const reminderId = 'test-reminder-id';
        const userId = 'test-user-id';
        const verificationPhotoUrl = 'https://example.com/verification.jpg';
        
        final mockPhoto = MockFile();
        
        when(mockMediaService.uploadMedia(
          file: anyNamed('file'),
          bucket: anyNamed('bucket'),
          familyId: anyNamed('familyId'),
          userId: anyNamed('userId'),
          folder: anyNamed('folder'),
        )).thenAnswer((_) async => verificationPhotoUrl);

        when(mockSupabase.from('medication_reminders')).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('medication_reminders').update(any)).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('medication_reminders').update(any).eq('id', reminderId))
            .thenAnswer((_) async => {});
        when(mockSupabase.from('medication_logs')).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('medication_logs').insert(any)).thenAnswer((_) async => {});
        when(mockNotificationService.cancelNotification(any)).thenAnswer((_) async {});

        // Act
        await medicationService.recordMedicationTaken(
          reminderId: reminderId,
          userId: userId,
          verificationPhoto: mockPhoto,
        );

        // Assert
        verify(mockMediaService.uploadMedia(
          file: mockPhoto,
          bucket: 'medication-verifications',
          familyId: userId,
          userId: userId,
          folder: 'verifications',
        )).called(1);
        
        verify(mockSupabase.from('medication_reminders').update({
          'status': 'taken',
          'taken_time': anyNamed('taken_time'),
          'verification_photo_url': verificationPhotoUrl,
          'notes': null,
          'updated_at': anyNamed('updated_at'),
        }).eq('id', reminderId)).called(1);
      });
    });

    group('markMedicationMissed', () {
      test('should mark medication as missed', () async {
        // Arrange
        const reminderId = 'test-reminder-id';
        const userId = 'test-user-id';
        const reason = 'Forgot to take it';

        when(mockSupabase.from('medication_reminders')).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('medication_reminders').update(any)).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('medication_reminders').update(any).eq('id', reminderId))
            .thenAnswer((_) async => {});
        when(mockNotificationService.cancelNotification(any)).thenAnswer((_) async {});

        // Act
        await medicationService.markMedicationMissed(
          reminderId: reminderId,
          userId: userId,
          reason: reason,
        );

        // Assert
        verify(mockSupabase.from('medication_reminders').update({
          'status': 'missed',
          'notes': reason,
          'updated_at': anyNamed('updated_at'),
        }).eq('id', reminderId)).called(1);
        
        verify(mockNotificationService.cancelNotification(reminderId.hashCode)).called(1);
        verify(mockLogger.info(any)).called(1);
      });
    });

    group('snoozeMedicationReminder', () {
      test('should snooze medication reminder', () async {
        // Arrange
        const reminderId = 'test-reminder-id';
        const userId = 'test-user-id';
        const snoozeDuration = Duration(minutes: 30);

        final reminder = MedicationReminder(
          id: reminderId,
          medicationId: 'med-id',
          userId: userId,
          scheduledTime: DateTime.now().subtract(const Duration(minutes: 5)),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        medicationService._medicationRemindersCache[reminderId] = reminder;

        when(mockSupabase.from('medication_reminders')).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('medication_reminders').select()).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('medication_reminders').select().eq('id', reminderId))
            .thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('medication_reminders').select().eq('id', reminderId).single())
            .thenAnswer((_) async => reminder.toJson());
        
        when(mockSupabase.from('medication_reminders').update(any)).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('medication_reminders').update(any).eq('id', reminderId))
            .thenAnswer((_) async => {});

        when(mockNotificationService.cancelNotification(any)).thenAnswer((_) async {});
        when(mockNotificationService.scheduleNotification(
          id: anyNamed('id'),
          title: anyNamed('title'),
          body: anyNamed('body'),
          scheduledTime: anyNamed('scheduledTime'),
          payload: anyNamed('payload'),
        )).thenAnswer((_) async {});

        // Act
        await medicationService.snoozeMedicationReminder(
          reminderId: reminderId,
          userId: userId,
          snoozeDuration: snoozeDuration,
        );

        // Assert
        verify(mockSupabase.from('medication_reminders').update(any).eq('id', reminderId)).called(1);
        verify(mockNotificationService.cancelNotification(reminderId.hashCode)).called(1);
        verify(mockNotificationService.scheduleNotification(
          id: anyNamed('id'),
          title: anyNamed('title'),
          body: anyNamed('body'),
          scheduledTime: anyNamed('scheduledTime'),
          payload: anyNamed('payload'),
        )).called(1);
        verify(mockLogger.info(any)).called(1);
      });
    });

    group('getComplianceStats', () {
      test('should calculate compliance statistics correctly', () async {
        // Arrange
        const userId = 'test-user-id';
        final now = DateTime.now();
        final startDate = now.subtract(const Duration(days: 7));

        final mockLogs = [
          {
            'id': '1',
            'medication_id': 'med-1',
            'user_id': userId,
            'scheduled_time': now.subtract(const Duration(days: 6)).toIso8601String(),
            'taken_time': now.subtract(const Duration(days: 6)).toIso8601String(),
            'status': 'taken',
            'created_at': now.subtract(const Duration(days: 6)).toIso8601String(),
          },
          {
            'id': '2',
            'medication_id': 'med-1',
            'user_id': userId,
            'scheduled_time': now.subtract(const Duration(days: 5)).toIso8601String(),
            'status': 'missed',
            'created_at': now.subtract(const Duration(days: 5)).toIso8601String(),
          },
          {
            'id': '3',
            'medication_id': 'med-1',
            'user_id': userId,
            'scheduled_time': now.subtract(const Duration(days: 4)).toIso8601String(),
            'taken_time': now.subtract(const Duration(days: 4)).toIso8601String(),
            'status': 'taken',
            'created_at': now.subtract(const Duration(days: 4)).toIso8601String(),
          },
          {
            'id': '4',
            'medication_id': 'med-1',
            'user_id': userId,
            'scheduled_time': now.subtract(const Duration(days: 3)).toIso8601String(),
            'status': 'skipped',
            'created_at': now.subtract(const Duration(days: 3)).toIso8601String(),
          },
        ];

        when(mockSupabase.from('medication_logs')).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('medication_logs').select()).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('medication_logs').select().eq('user_id', userId))
            .thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('medication_logs').select().eq('user_id', userId).gte('scheduled_time', anyNamed('gte')))
            .thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('medication_logs').select().eq('user_id', userId).gte('scheduled_time', anyNamed('gte')).lte('scheduled_time', anyNamed('lte')))
            .thenAnswer((_) async => mockLogs);

        // Act
        final stats = await medicationService.getComplianceStats(
          userId: userId,
          startDate: startDate,
          endDate: now,
        );

        // Assert
        expect(stats.totalDoses, equals(4));
        expect(stats.takenDoses, equals(2));
        expect(stats.missedDoses, equals(1));
        expect(stats.skippedDoses, equals(1));
        expect(stats.complianceRate, equals(50.0)); // 2 taken out of 4 total = 50%
        expect(stats.periodStart, equals(startDate));
        expect(stats.periodEnd, equals(now));
      });

      test('should return empty stats when no data available', () async {
        // Arrange
        const userId = 'test-user-id';
        final now = DateTime.now();
        final startDate = now.subtract(const Duration(days: 7));

        when(mockSupabase.from('medication_logs')).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('medication_logs').select()).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('medication_logs').select().eq('user_id', userId))
            .thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('medication_logs').select().eq('user_id', userId).gte('scheduled_time', anyNamed('gte')))
            .thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('medication_logs').select().eq('user_id', userId).gte('scheduled_time', anyNamed('gte')).lte('scheduled_time', anyNamed('lte')))
            .thenAnswer((_) async => []);

        // Act
        final stats = await medicationService.getComplianceStats(
          userId: userId,
          startDate: startDate,
          endDate: now,
        );

        // Assert
        expect(stats.totalDoses, equals(0));
        expect(stats.takenDoses, equals(0));
        expect(stats.missedDoses, equals(0));
        expect(stats.skippedDoses, equals(0));
        expect(stats.complianceRate, equals(0.0));
      });
    });
  });
}

// Mock File class for testing
class MockFile extends Mock implements File {}

// Extension to access private members for testing
extension ElderMedicationServiceTestExtension on ElderMedicationService {
  Map<String, MedicationReminder> get _medicationRemindersCache => 
      ElderMedicationService._instance._remindersCache.values.expand((list) => list).fold<Map<String, MedicationReminder>>({}, (map, reminder) {
        map[reminder.id] = reminder;
        return map;
      });
}