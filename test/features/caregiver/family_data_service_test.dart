import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:family_bridge/features/caregiver/services/family_data_service.dart';
import 'package:family_bridge/features/shared/models/family_model.dart';
import 'package:family_bridge/features/shared/models/user_model.dart';
import 'package:family_bridge/features/shared/services/logging_service.dart';

@GenerateMocks([
  SupabaseClient,
  SupabaseQueryBuilder,
  LoggingService,
])
import 'family_data_service_test.mocks.dart';

void main() {
  group('FamilyDataService', () {
    late FamilyDataService familyDataService;
    late MockSupabaseClient mockSupabase;
    late MockLoggingService mockLogger;

    setUp(() {
      mockSupabase = MockSupabaseClient();
      mockLogger = MockLoggingService();
      
      familyDataService = FamilyDataService();
      
      // Reset the singleton instance for testing
      FamilyDataService._instance._supabase = mockSupabase;
      FamilyDataService._instance._logger = mockLogger;
    });

    group('createFamily', () {
      test('should create family successfully', () async {
        // Arrange
        const familyName = 'Test Family';
        const createdBy = 'test-user-id';

        when(mockSupabase.from('families')).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('families').insert(any)).thenAnswer((_) async => {});
        when(mockSupabase.from('family_members')).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('family_members').insert(any)).thenAnswer((_) async => {});

        // Act
        final family = await familyDataService.createFamily(
          familyName: familyName,
          createdBy: createdBy,
        );

        // Assert
        expect(family.familyName, equals(familyName));
        expect(family.createdBy, equals(createdBy));
        expect(family.familyCode, isNotEmpty);
        expect(family.isActive, isTrue);
        expect(family.privacySettings, isNotNull);
        
        verify(mockSupabase.from('families').insert(any)).called(1);
        verify(mockSupabase.from('family_members').insert(any)).called(1);
        verify(mockLogger.info(any)).called(1);
      });

      test('should include default privacy settings', () async {
        // Arrange
        const familyName = 'Test Family';
        const createdBy = 'test-user-id';

        when(mockSupabase.from('families')).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('families').insert(any)).thenAnswer((_) async => {});
        when(mockSupabase.from('family_members')).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('family_members').insert(any)).thenAnswer((_) async => {});

        // Act
        final family = await familyDataService.createFamily(
          familyName: familyName,
          createdBy: createdBy,
        );

        // Assert
        final privacySettings = family.privacySettings!;
        expect(privacySettings['share_health_data'], isTrue);
        expect(privacySettings['share_location'], isFalse);
        expect(privacySettings['share_activity_data'], isTrue);
        expect(privacySettings['allow_third_party_access'], isFalse);
        expect(privacySettings['data_retention_days'], equals(365));
      });
    });

    group('addFamilyMember', () {
      test('should add family member successfully', () async {
        // Arrange
        const familyId = 'test-family-id';
        const userId = 'test-user-id';
        const role = FamilyRole.elder;
        const nickname = 'Grandma';
        const relationship = 'Grandmother';

        when(mockSupabase.from('family_members')).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('family_members').insert(any)).thenAnswer((_) async => {});

        // Act
        final familyMember = await familyDataService.addFamilyMember(
          familyId: familyId,
          userId: userId,
          role: role,
          nickname: nickname,
          relationship: relationship,
        );

        // Assert
        expect(familyMember.familyId, equals(familyId));
        expect(familyMember.userId, equals(userId));
        expect(familyMember.role, equals(role));
        expect(familyMember.nickname, equals(nickname));
        expect(familyMember.relationship, equals(relationship));
        expect(familyMember.isActive, isTrue);
        expect(familyMember.permissions, isNotNull);
        
        verify(mockSupabase.from('family_members').insert(any)).called(1);
        verify(mockLogger.info(any)).called(1);
      });

      test('should set correct permissions for elder role', () async {
        // Arrange
        const familyId = 'test-family-id';
        const userId = 'test-user-id';
        const role = FamilyRole.elder;

        when(mockSupabase.from('family_members')).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('family_members').insert(any)).thenAnswer((_) async => {});

        // Act
        final familyMember = await familyDataService.addFamilyMember(
          familyId: familyId,
          userId: userId,
          role: role,
        );

        // Assert
        final permissions = familyMember.permissions!;
        expect(permissions['view_own_data'], isTrue);
        expect(permissions['edit_own_data'], isTrue);
        expect(permissions['view_family_data'], isFalse);
        expect(permissions['edit_family_data'], isFalse);
        expect(permissions['manage_members'], isFalse);
      });

      test('should set correct permissions for primary caregiver role', () async {
        // Arrange
        const familyId = 'test-family-id';
        const userId = 'test-user-id';
        const role = FamilyRole.primaryCaregiver;

        when(mockSupabase.from('family_members')).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('family_members').insert(any)).thenAnswer((_) async => {});

        // Act
        final familyMember = await familyDataService.addFamilyMember(
          familyId: familyId,
          userId: userId,
          role: role,
        );

        // Assert
        final permissions = familyMember.permissions!;
        expect(permissions['view_own_data'], isTrue);
        expect(permissions['edit_own_data'], isTrue);
        expect(permissions['view_family_data'], isTrue);
        expect(permissions['edit_family_data'], isTrue);
        expect(permissions['manage_members'], isTrue);
        expect(permissions['manage_privacy'], isTrue);
      });
    });

    group('joinFamily', () {
      test('should join family with valid code', () async {
        // Arrange
        const familyCode = 'TEST-CODE-123';
        const userId = 'test-user-id';
        const role = FamilyRole.youth;

        final familyData = {
          'id': 'test-family-id',
          'family_name': 'Test Family',
          'created_by': 'creator-id',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'family_code': familyCode,
          'is_active': true,
        };

        when(mockSupabase.from('families')).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('families').select()).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('families').select().eq('family_code', familyCode))
            .thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('families').select().eq('family_code', familyCode).eq('is_active', true))
            .thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('families').select().eq('family_code', familyCode).eq('is_active', true).single())
            .thenAnswer((_) async => familyData);

        when(mockSupabase.from('family_members')).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('family_members').select()).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('family_members').select().eq('family_id', familyData['id']))
            .thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('family_members').select().eq('family_id', familyData['id']).eq('user_id', userId))
            .thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('family_members').select().eq('family_id', familyData['id']).eq('user_id', userId).eq('is_active', true))
            .thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('family_members').select().eq('family_id', familyData['id']).eq('user_id', userId).eq('is_active', true).maybeSingle())
            .thenAnswer((_) async => null);

        when(mockSupabase.from('family_members').insert(any)).thenAnswer((_) async => {});

        // Act
        final family = await familyDataService.joinFamily(
          familyCode: familyCode,
          userId: userId,
          role: role,
        );

        // Assert
        expect(family.id, equals(familyData['id']));
        expect(family.familyCode, equals(familyCode));
        
        verify(mockSupabase.from('families').select().eq('family_code', familyCode).eq('is_active', true).single()).called(1);
        verify(mockSupabase.from('family_members').insert(any)).called(1);
        verify(mockLogger.info(any)).called(1);
      });

      test('should throw exception for invalid family code', () async {
        // Arrange
        const familyCode = 'INVALID-CODE';
        const userId = 'test-user-id';
        const role = FamilyRole.youth;

        when(mockSupabase.from('families')).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('families').select()).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('families').select().eq('family_code', familyCode))
            .thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('families').select().eq('family_code', familyCode).eq('is_active', true))
            .thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('families').select().eq('family_code', familyCode).eq('is_active', true).single())
            .thenThrow(PostgrestException(message: 'No rows returned'));

        // Act & Assert
        expect(
          () => familyDataService.joinFamily(
            familyCode: familyCode,
            userId: userId,
            role: role,
          ),
          throwsA(isA<FamilyDataServiceException>()),
        );
      });
    });

    group('hasPermission', () {
      test('should return true for granted permission', () {
        // Arrange
        const familyId = 'test-family-id';
        const userId = 'test-user-id';
        const permission = 'view_family_data';

        final familyMember = FamilyMember(
          id: 'member-id',
          familyId: familyId,
          userId: userId,
          role: FamilyRole.primaryCaregiver,
          permissions: {'view_family_data': true},
          joinedAt: DateTime.now(),
        );

        familyDataService._familyMembersCache[familyId] = [familyMember];

        // Act
        final result = familyDataService.hasPermission(
          familyId: familyId,
          userId: userId,
          permission: permission,
        );

        // Assert
        expect(result, isTrue);
      });

      test('should return false for denied permission', () {
        // Arrange
        const familyId = 'test-family-id';
        const userId = 'test-user-id';
        const permission = 'manage_members';

        final familyMember = FamilyMember(
          id: 'member-id',
          familyId: familyId,
          userId: userId,
          role: FamilyRole.youth,
          permissions: {'manage_members': false},
          joinedAt: DateTime.now(),
        );

        familyDataService._familyMembersCache[familyId] = [familyMember];

        // Act
        final result = familyDataService.hasPermission(
          familyId: familyId,
          userId: userId,
          permission: permission,
        );

        // Assert
        expect(result, isFalse);
      });

      test('should return false for non-existent user', () {
        // Arrange
        const familyId = 'test-family-id';
        const userId = 'non-existent-user-id';
        const permission = 'view_family_data';

        familyDataService._familyMembersCache[familyId] = [];

        // Act
        final result = familyDataService.hasPermission(
          familyId: familyId,
          userId: userId,
          permission: permission,
        );

        // Assert
        expect(result, isFalse);
      });
    });

    group('getFamilyStatistics', () {
      test('should return correct family statistics', () async {
        // Arrange
        const familyId = 'test-family-id';

        final members = [
          FamilyMember(
            id: '1',
            familyId: familyId,
            userId: 'elder-1',
            role: FamilyRole.elder,
            joinedAt: DateTime.now(),
          ),
          FamilyMember(
            id: '2',
            familyId: familyId,
            userId: 'caregiver-1',
            role: FamilyRole.primaryCaregiver,
            joinedAt: DateTime.now(),
          ),
          FamilyMember(
            id: '3',
            familyId: familyId,
            userId: 'caregiver-2',
            role: FamilyRole.secondaryCaregiver,
            joinedAt: DateTime.now(),
          ),
          FamilyMember(
            id: '4',
            familyId: familyId,
            userId: 'youth-1',
            role: FamilyRole.youth,
            joinedAt: DateTime.now(),
          ),
          FamilyMember(
            id: '5',
            familyId: familyId,
            userId: 'youth-2',
            role: FamilyRole.youth,
            joinedAt: DateTime.now(),
          ),
        ];

        familyDataService._familyMembersCache[familyId] = members;

        when(mockSupabase.from('family_members')).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('family_members').select()).thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('family_members').select().eq('family_id', familyId))
            .thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('family_members').select().eq('family_id', familyId).eq('is_active', true))
            .thenReturn(MockSupabaseQueryBuilder());
        when(mockSupabase.from('family_members').select().eq('family_id', familyId).eq('is_active', true).order('joined_at'))
            .thenAnswer((_) async => members.map((m) => m.toJson()).toList());

        // Act
        final stats = await familyDataService.getFamilyStatistics(familyId);

        // Assert
        expect(stats.totalMembers, equals(5));
        expect(stats.elderMembers, equals(1));
        expect(stats.caregiverMembers, equals(2));
        expect(stats.youthMembers, equals(2));
      });
    });
  });
}

// Extension to access private members for testing
extension FamilyDataServiceTestExtension on FamilyDataService {
  Map<String, List<FamilyMember>> get _familyMembersCache => 
      FamilyDataService._instance._familyMembersCache;
}