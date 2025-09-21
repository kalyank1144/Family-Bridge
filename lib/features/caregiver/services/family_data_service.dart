import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import '../../shared/models/family_model.dart';
import '../../shared/models/user_model.dart';
import '../../shared/services/logging_service.dart';

/// Service for managing family member data, relationships, and coordination
/// Implements HIPAA-compliant family data management with offline-first functionality
class FamilyDataService {
  static final FamilyDataService _instance = FamilyDataService._internal();
  factory FamilyDataService() => _instance;
  FamilyDataService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final LoggingService _logger = LoggingService();
  final Uuid _uuid = const Uuid();

  final StreamController<Family?> _familyController =
      StreamController<Family?>.broadcast();
  final StreamController<List<FamilyMember>> _familyMembersController =
      StreamController<List<FamilyMember>>.broadcast();

  // Cache for offline functionality
  final Map<String, Family> _familyCache = {};
  final Map<String, List<FamilyMember>> _familyMembersCache = {};
  final Map<String, UserModel> _userCache = {};
  bool _isInitialized = false;
  String? _currentFamilyId;

  /// Stream of current family data
  Stream<Family?> get familyStream => _familyController.stream;

  /// Stream of family members
  Stream<List<FamilyMember>> get familyMembersStream => 
      _familyMembersController.stream;

  /// Current family ID
  String? get currentFamilyId => _currentFamilyId;

  /// Initialize the service with user's family
  Future<void> initialize(String userId) async {
    try {
      if (_isInitialized) return;

      await _loadUserFamilyData(userId);
      await _subscribeToRealtimeUpdates();
      
      _isInitialized = true;
      _logger.info('FamilyDataService initialized for user: $userId');
    } catch (e, stackTrace) {
      _logger.error('Failed to initialize FamilyDataService: $e', stackTrace);
      throw FamilyDataServiceException('Initialization failed: $e');
    }
  }

  /// Create a new family group
  Future<Family> createFamily({
    required String familyName,
    required String createdBy,
    Map<String, dynamic>? privacySettings,
  }) async {
    try {
      final familyCode = _generateFamilyCode();
      final family = Family(
        id: _uuid.v4(),
        familyName: familyName,
        createdBy: createdBy,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        familyCode: familyCode,
        privacySettings: privacySettings ?? _getDefaultPrivacySettings(),
      );

      // Save to database
      await _supabase.from('families').insert(family.toJson());

      // Add creator as primary caregiver
      await addFamilyMember(
        familyId: family.id,
        userId: createdBy,
        role: FamilyRole.primaryCaregiver,
      );

      // Update cache and streams
      _familyCache[family.id] = family;
      _currentFamilyId = family.id;
      _familyController.add(family);

      _logger.info('Family created: ${family.id} - ${family.familyName}');
      return family;
    } catch (e, stackTrace) {
      _logger.error('Failed to create family: $e', stackTrace);
      throw FamilyDataServiceException('Failed to create family: $e');
    }
  }

  /// Get family by ID
  Future<Family?> getFamily(String familyId) async {
    try {
      // Check cache first
      if (_familyCache.containsKey(familyId)) {
        return _familyCache[familyId];
      }

      // Fetch from database
      final response = await _supabase
          .from('families')
          .select()
          .eq('id', familyId)
          .eq('is_active', true)
          .single();

      final family = Family.fromJson(response as Map<String, dynamic>);
      _familyCache[familyId] = family;
      
      return family;
    } catch (e) {
      _logger.warning('Failed to fetch family from database: $e');
      
      // Return cached version if available
      return _familyCache[familyId];
    }
  }

  /// Join a family using invitation code
  Future<Family> joinFamily({
    required String familyCode,
    required String userId,
    required FamilyRole role,
    String? nickname,
    String? relationship,
  }) async {
    try {
      // Find family by code
      final response = await _supabase
          .from('families')
          .select()
          .eq('family_code', familyCode)
          .eq('is_active', true)
          .single();

      final family = Family.fromJson(response as Map<String, dynamic>);

      // Check if user is already a member
      final existingMember = await _getFamilyMember(family.id, userId);
      if (existingMember != null) {
        throw FamilyDataServiceException('User is already a member of this family');
      }

      // Add as family member
      await addFamilyMember(
        familyId: family.id,
        userId: userId,
        role: role,
        nickname: nickname,
        relationship: relationship,
      );

      // Update current family
      _currentFamilyId = family.id;
      _familyCache[family.id] = family;
      _familyController.add(family);

      _logger.info('User $userId joined family: ${family.id}');
      return family;
    } catch (e, stackTrace) {
      _logger.error('Failed to join family: $e', stackTrace);
      throw FamilyDataServiceException('Failed to join family: $e');
    }
  }

  /// Add a family member
  Future<FamilyMember> addFamilyMember({
    required String familyId,
    required String userId,
    required FamilyRole role,
    String? nickname,
    String? relationship,
    Map<String, dynamic>? permissions,
  }) async {
    try {
      final familyMember = FamilyMember(
        id: _uuid.v4(),
        familyId: familyId,
        userId: userId,
        role: role,
        permissions: permissions ?? _getDefaultPermissions(role),
        joinedAt: DateTime.now(),
        nickname: nickname,
        relationship: relationship,
      );

      // Save to database
      await _supabase.from('family_members').insert(familyMember.toJson());

      // Update cache
      if (!_familyMembersCache.containsKey(familyId)) {
        _familyMembersCache[familyId] = [];
      }
      _familyMembersCache[familyId]!.add(familyMember);

      // Update stream
      _familyMembersController.add(_familyMembersCache[familyId]!);

      _logger.info('Family member added: $userId to family $familyId');
      return familyMember;
    } catch (e, stackTrace) {
      _logger.error('Failed to add family member: $e', stackTrace);
      throw FamilyDataServiceException('Failed to add family member: $e');
    }
  }

  /// Get all family members
  Future<List<FamilyMember>> getFamilyMembers(String familyId) async {
    try {
      // Check cache first
      if (_familyMembersCache.containsKey(familyId)) {
        return _familyMembersCache[familyId]!;
      }

      // Fetch from database
      final response = await _supabase
          .from('family_members')
          .select()
          .eq('family_id', familyId)
          .eq('is_active', true)
          .order('joined_at');

      final members = (response as List)
          .map((json) => FamilyMember.fromJson(json as Map<String, dynamic>))
          .toList();

      // Update cache
      _familyMembersCache[familyId] = members;
      
      return members;
    } catch (e) {
      _logger.warning('Failed to fetch family members from database: $e');
      
      // Return cached version if available
      return _familyMembersCache[familyId] ?? [];
    }
  }

  /// Get family members with user details
  Future<List<FamilyMemberWithUser>> getFamilyMembersWithUserDetails(
      String familyId) async {
    try {
      final members = await getFamilyMembers(familyId);
      final result = <FamilyMemberWithUser>[];

      for (final member in members) {
        final user = await _getUserDetails(member.userId);
        if (user != null) {
          result.add(FamilyMemberWithUser(
            familyMember: member,
            user: user,
          ));
        }
      }

      return result;
    } catch (e, stackTrace) {
      _logger.error('Failed to get family members with user details: $e', stackTrace);
      throw FamilyDataServiceException('Failed to get family members with user details: $e');
    }
  }

  /// Update family member permissions
  Future<void> updateMemberPermissions({
    required String familyMemberId,
    required Map<String, dynamic> permissions,
    required String updatedBy,
  }) async {
    try {
      // Verify updatedBy has permission to modify permissions
      final updater = await _getFamilyMemberByUserId(_currentFamilyId!, updatedBy);
      if (updater == null || 
          (updater.role != FamilyRole.primaryCaregiver && 
           updater.role != FamilyRole.secondaryCaregiver)) {
        throw FamilyDataServiceException('Insufficient permissions to update member permissions');
      }

      await _supabase.from('family_members').update({
        'permissions': permissions,
      }).eq('id', familyMemberId);

      // Update cache
      await _refreshFamilyMembersCache(_currentFamilyId!);
      
      _logger.info('Member permissions updated: $familyMemberId by $updatedBy');
    } catch (e, stackTrace) {
      _logger.error('Failed to update member permissions: $e', stackTrace);
      throw FamilyDataServiceException('Failed to update member permissions: $e');
    }
  }

  /// Remove family member
  Future<void> removeFamilyMember({
    required String familyMemberId,
    required String removedBy,
    String? reason,
  }) async {
    try {
      // Verify permissions
      final remover = await _getFamilyMemberByUserId(_currentFamilyId!, removedBy);
      if (remover == null || 
          (remover.role != FamilyRole.primaryCaregiver && 
           remover.role != FamilyRole.secondaryCaregiver)) {
        throw FamilyDataServiceException('Insufficient permissions to remove family member');
      }

      // Soft delete - set as inactive
      await _supabase.from('family_members').update({
        'is_active': false,
        'removed_at': DateTime.now().toIso8601String(),
        'removed_by': removedBy,
        'removal_reason': reason,
      }).eq('id', familyMemberId);

      // Update cache
      await _refreshFamilyMembersCache(_currentFamilyId!);
      
      _logger.info('Family member removed: $familyMemberId by $removedBy');
    } catch (e, stackTrace) {
      _logger.error('Failed to remove family member: $e', stackTrace);
      throw FamilyDataServiceException('Failed to remove family member: $e');
    }
  }

  /// Update family privacy settings
  Future<void> updateFamilyPrivacySettings({
    required String familyId,
    required Map<String, dynamic> privacySettings,
    required String updatedBy,
  }) async {
    try {
      // Verify permissions
      final updater = await _getFamilyMemberByUserId(familyId, updatedBy);
      if (updater == null || updater.role != FamilyRole.primaryCaregiver) {
        throw FamilyDataServiceException('Only primary caregiver can update privacy settings');
      }

      await _supabase.from('families').update({
        'privacy_settings': privacySettings,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', familyId);

      // Update cache
      final family = _familyCache[familyId];
      if (family != null) {
        _familyCache[familyId] = family.copyWith(
          privacySettings: privacySettings,
          updatedAt: DateTime.now(),
        );
        _familyController.add(_familyCache[familyId]);
      }

      _logger.info('Family privacy settings updated: $familyId by $updatedBy');
    } catch (e, stackTrace) {
      _logger.error('Failed to update family privacy settings: $e', stackTrace);
      throw FamilyDataServiceException('Failed to update family privacy settings: $e');
    }
  }

  /// Create family invitation
  Future<FamilyInvitation> createInvitation({
    required String familyId,
    required String invitedBy,
    String? invitedEmail,
    String? invitedPhone,
    required FamilyRole suggestedRole,
    Duration validFor = const Duration(days: 7),
  }) async {
    try {
      final invitation = FamilyInvitation(
        id: _uuid.v4(),
        familyId: familyId,
        invitedBy: invitedBy,
        invitedEmail: invitedEmail,
        invitedPhone: invitedPhone,
        suggestedRole: suggestedRole,
        invitationCode: _generateInvitationCode(),
        expiresAt: DateTime.now().add(validFor),
        createdAt: DateTime.now(),
      );

      await _supabase.from('family_invitations').insert(invitation.toJson());

      _logger.info('Family invitation created: ${invitation.id}');
      return invitation;
    } catch (e, stackTrace) {
      _logger.error('Failed to create family invitation: $e', stackTrace);
      throw FamilyDataServiceException('Failed to create family invitation: $e');
    }
  }

  /// Get family statistics
  Future<FamilyStatistics> getFamilyStatistics(String familyId) async {
    try {
      final members = await getFamilyMembers(familyId);
      
      final elderCount = members.where((m) => m.role == FamilyRole.elder).length;
      final caregiverCount = members.where((m) => 
          m.role == FamilyRole.primaryCaregiver || 
          m.role == FamilyRole.secondaryCaregiver).length;
      final youthCount = members.where((m) => m.role == FamilyRole.youth).length;
      
      // Get recent activity count (this would be from other services)
      final recentActivityCount = await _getRecentActivityCount(familyId);
      
      return FamilyStatistics(
        totalMembers: members.length,
        elderMembers: elderCount,
        caregiverMembers: caregiverCount,
        youthMembers: youthCount,
        recentActivityCount: recentActivityCount,
        familyCreatedAt: _familyCache[familyId]?.createdAt,
      );
    } catch (e, stackTrace) {
      _logger.error('Failed to get family statistics: $e', stackTrace);
      return FamilyStatistics.empty();
    }
  }

  /// Check if user has specific permission
  bool hasPermission({
    required String familyId,
    required String userId,
    required String permission,
  }) {
    try {
      final members = _familyMembersCache[familyId] ?? [];
      final member = members.firstWhere(
        (m) => m.userId == userId,
        orElse: () => throw StateError('Member not found'),
      );

      final permissions = member.permissions ?? {};
      return permissions[permission] == true;
    } catch (e) {
      _logger.warning('Failed to check permission: $permission for user $userId');
      return false;
    }
  }

  // Private helper methods

  Future<void> _loadUserFamilyData(String userId) async {
    try {
      // Get user's family membership
      final response = await _supabase
          .from('family_members')
          .select('family_id')
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      if (response != null) {
        final familyId = response['family_id'] as String;
        _currentFamilyId = familyId;
        
        // Load family and members
        final family = await getFamily(familyId);
        final members = await getFamilyMembers(familyId);
        
        // Update streams
        _familyController.add(family);
        _familyMembersController.add(members);
      }
    } catch (e) {
      _logger.warning('Failed to load user family data: $e');
    }
  }

  Future<void> _subscribeToRealtimeUpdates() async {
    if (_currentFamilyId == null) return;

    try {
      // Subscribe to family updates
      _supabase
          .from('families')
          .stream(primaryKey: ['id'])
          .eq('id', _currentFamilyId!)
          .listen((data) {
            if (data.isNotEmpty) {
              final family = Family.fromJson(data.first as Map<String, dynamic>);
              _familyCache[family.id] = family;
              _familyController.add(family);
            }
          });

      // Subscribe to family member updates
      _supabase
          .from('family_members')
          .stream(primaryKey: ['id'])
          .eq('family_id', _currentFamilyId!)
          .eq('is_active', true)
          .listen((data) {
            final members = data
                .map((json) => FamilyMember.fromJson(json as Map<String, dynamic>))
                .toList();
            _familyMembersCache[_currentFamilyId!] = members;
            _familyMembersController.add(members);
          });
    } catch (e) {
      _logger.warning('Failed to subscribe to realtime updates: $e');
    }
  }

  String _generateFamilyCode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = _uuid.v4().substring(0, 8);
    return '$timestamp-$random'.toUpperCase();
  }

  String _generateInvitationCode() {
    final bytes = utf8.encode(_uuid.v4());
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 8).toUpperCase();
  }

  Map<String, dynamic> _getDefaultPrivacySettings() {
    return {
      'share_health_data': true,
      'share_location': false,
      'share_activity_data': true,
      'allow_third_party_access': false,
      'data_retention_days': 365,
    };
  }

  Map<String, dynamic> _getDefaultPermissions(FamilyRole role) {
    switch (role) {
      case FamilyRole.elder:
        return {
          'view_own_data': true,
          'edit_own_data': true,
          'view_family_data': false,
          'edit_family_data': false,
          'manage_members': false,
        };
      case FamilyRole.primaryCaregiver:
        return {
          'view_own_data': true,
          'edit_own_data': true,
          'view_family_data': true,
          'edit_family_data': true,
          'manage_members': true,
          'manage_privacy': true,
        };
      case FamilyRole.secondaryCaregiver:
        return {
          'view_own_data': true,
          'edit_own_data': true,
          'view_family_data': true,
          'edit_family_data': true,
          'manage_members': false,
          'manage_privacy': false,
        };
      case FamilyRole.youth:
        return {
          'view_own_data': true,
          'edit_own_data': true,
          'view_family_data': true,
          'edit_family_data': false,
          'manage_members': false,
        };
    }
  }

  Future<FamilyMember?> _getFamilyMember(String familyId, String userId) async {
    try {
      final response = await _supabase
          .from('family_members')
          .select()
          .eq('family_id', familyId)
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      return response != null ? FamilyMember.fromJson(response as Map<String, dynamic>) : null;
    } catch (e) {
      return null;
    }
  }

  Future<FamilyMember?> _getFamilyMemberByUserId(String familyId, String userId) async {
    final members = await getFamilyMembers(familyId);
    try {
      return members.firstWhere((m) => m.userId == userId);
    } catch (e) {
      return null;
    }
  }

  Future<UserModel?> _getUserDetails(String userId) async {
    try {
      // Check cache first
      if (_userCache.containsKey(userId)) {
        return _userCache[userId];
      }

      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      final user = UserModel.fromJson(response as Map<String, dynamic>);
      _userCache[userId] = user;
      
      return user;
    } catch (e) {
      return null;
    }
  }

  Future<void> _refreshFamilyMembersCache(String familyId) async {
    final members = await getFamilyMembers(familyId);
    _familyMembersController.add(members);
  }

  Future<int> _getRecentActivityCount(String familyId) async {
    // This would integrate with other services to get activity count
    // For now, return a placeholder
    return 0;
  }

  /// Dispose of resources
  void dispose() {
    _familyController.close();
    _familyMembersController.close();
  }
}

/// Data class for family member with user details
class FamilyMemberWithUser {
  final FamilyMember familyMember;
  final UserModel user;

  const FamilyMemberWithUser({
    required this.familyMember,
    required this.user,
  });
}

/// Data class for family statistics
class FamilyStatistics {
  final int totalMembers;
  final int elderMembers;
  final int caregiverMembers;
  final int youthMembers;
  final int recentActivityCount;
  final DateTime? familyCreatedAt;

  const FamilyStatistics({
    required this.totalMembers,
    required this.elderMembers,
    required this.caregiverMembers,
    required this.youthMembers,
    required this.recentActivityCount,
    this.familyCreatedAt,
  });

  factory FamilyStatistics.empty() {
    return const FamilyStatistics(
      totalMembers: 0,
      elderMembers: 0,
      caregiverMembers: 0,
      youthMembers: 0,
      recentActivityCount: 0,
    );
  }
}

/// Custom exception for family data service errors
class FamilyDataServiceException implements Exception {
  final String message;
  FamilyDataServiceException(this.message);
  
  @override
  String toString() => 'FamilyDataServiceException: $message';
}