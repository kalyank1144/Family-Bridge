import 'package:flutter/foundation.dart';
import '../services/family_data_service.dart';
import '../../shared/models/family_model.dart';
import '../../shared/models/user_model.dart';
import '../../shared/services/logging_service.dart';

/// Provider for managing family data and member coordination
/// Integrates FamilyDataService with Flutter UI layer using ChangeNotifier
class FamilyDataProvider extends ChangeNotifier {
  final FamilyDataService _familyDataService = FamilyDataService();
  final LoggingService _logger = LoggingService();

  Family? _currentFamily;
  List<FamilyMember> _familyMembers = [];
  List<FamilyMemberWithUser> _familyMembersWithUsers = [];
  FamilyStatistics? _familyStatistics;
  bool _isLoading = false;
  String? _error;
  String? _currentUserId;

  // Getters
  Family? get currentFamily => _currentFamily;
  List<FamilyMember> get familyMembers => _familyMembers;
  List<FamilyMemberWithUser> get familyMembersWithUsers => _familyMembersWithUsers;
  FamilyStatistics? get familyStatistics => _familyStatistics;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasFamily => _currentFamily != null;
  String? get familyId => _currentFamily?.id;

  /// Initialize the provider with user ID
  Future<void> initialize(String userId) async {
    _currentUserId = userId;
    _setLoading(true);
    _clearError();

    try {
      await _familyDataService.initialize(userId);
      
      // Subscribe to real-time updates
      _familyDataService.familyStream.listen(_onFamilyUpdated);
      _familyDataService.familyMembersStream.listen(_onFamilyMembersUpdated);
      
      // Load initial data
      await _loadFamilyData();
      
      _logger.info('FamilyDataProvider initialized for user: $userId');
    } catch (e, stackTrace) {
      _setError('Failed to initialize family data: $e');
      _logger.error('FamilyDataProvider initialization failed: $e', stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new family
  Future<bool> createFamily({
    required String familyName,
    Map<String, dynamic>? privacySettings,
  }) async {
    if (_currentUserId == null) {
      _setError('User not initialized');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final family = await _familyDataService.createFamily(
        familyName: familyName,
        createdBy: _currentUserId!,
        privacySettings: privacySettings,
      );
      
      _currentFamily = family;
      await _loadFamilyStatistics();
      
      notifyListeners();
      _logger.info('Family created via provider: ${family.familyName}');
      return true;
    } catch (e, stackTrace) {
      _setError('Failed to create family: $e');
      _logger.error('Failed to create family via provider: $e', stackTrace);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Join an existing family
  Future<bool> joinFamily({
    required String familyCode,
    required FamilyRole role,
    String? nickname,
    String? relationship,
  }) async {
    if (_currentUserId == null) {
      _setError('User not initialized');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final family = await _familyDataService.joinFamily(
        familyCode: familyCode,
        userId: _currentUserId!,
        role: role,
        nickname: nickname,
        relationship: relationship,
      );
      
      _currentFamily = family;
      await _loadFamilyData();
      
      notifyListeners();
      _logger.info('Joined family via provider: ${family.familyName}');
      return true;
    } catch (e, stackTrace) {
      _setError('Failed to join family: $e');
      _logger.error('Failed to join family via provider: $e', stackTrace);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Add a family member
  Future<bool> addFamilyMember({
    required String userId,
    required FamilyRole role,
    String? nickname,
    String? relationship,
  }) async {
    if (_currentFamily == null) {
      _setError('No family selected');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await _familyDataService.addFamilyMember(
        familyId: _currentFamily!.id,
        userId: userId,
        role: role,
        nickname: nickname,
        relationship: relationship,
      );
      
      await _loadFamilyData();
      notifyListeners();
      
      _logger.info('Family member added via provider: $userId');
      return true;
    } catch (e, stackTrace) {
      _setError('Failed to add family member: $e');
      _logger.error('Failed to add family member via provider: $e', stackTrace);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update member permissions
  Future<bool> updateMemberPermissions({
    required String familyMemberId,
    required Map<String, dynamic> permissions,
  }) async {
    if (_currentUserId == null || _currentFamily == null) {
      _setError('User or family not initialized');
      return false;
    }

    _clearError();

    try {
      await _familyDataService.updateMemberPermissions(
        familyMemberId: familyMemberId,
        permissions: permissions,
        updatedBy: _currentUserId!,
      );
      
      await _loadFamilyData();
      notifyListeners();
      
      _logger.info('Member permissions updated via provider: $familyMemberId');
      return true;
    } catch (e, stackTrace) {
      _setError('Failed to update permissions: $e');
      _logger.error('Failed to update member permissions via provider: $e', stackTrace);
      return false;
    }
  }

  /// Remove family member
  Future<bool> removeFamilyMember({
    required String familyMemberId,
    String? reason,
  }) async {
    if (_currentUserId == null) {
      _setError('User not initialized');
      return false;
    }

    _clearError();

    try {
      await _familyDataService.removeFamilyMember(
        familyMemberId: familyMemberId,
        removedBy: _currentUserId!,
        reason: reason,
      );
      
      await _loadFamilyData();
      notifyListeners();
      
      _logger.info('Family member removed via provider: $familyMemberId');
      return true;
    } catch (e, stackTrace) {
      _setError('Failed to remove family member: $e');
      _logger.error('Failed to remove family member via provider: $e', stackTrace);
      return false;
    }
  }

  /// Update family privacy settings
  Future<bool> updatePrivacySettings({
    required Map<String, dynamic> privacySettings,
  }) async {
    if (_currentUserId == null || _currentFamily == null) {
      _setError('User or family not initialized');
      return false;
    }

    _clearError();

    try {
      await _familyDataService.updateFamilyPrivacySettings(
        familyId: _currentFamily!.id,
        privacySettings: privacySettings,
        updatedBy: _currentUserId!,
      );
      
      _currentFamily = _currentFamily!.copyWith(
        privacySettings: privacySettings,
        updatedAt: DateTime.now(),
      );
      
      notifyListeners();
      _logger.info('Privacy settings updated via provider');
      return true;
    } catch (e, stackTrace) {
      _setError('Failed to update privacy settings: $e');
      _logger.error('Failed to update privacy settings via provider: $e', stackTrace);
      return false;
    }
  }

  /// Create family invitation
  Future<FamilyInvitation?> createInvitation({
    required FamilyRole suggestedRole,
    String? invitedEmail,
    String? invitedPhone,
    Duration validFor = const Duration(days: 7),
  }) async {
    if (_currentUserId == null || _currentFamily == null) {
      _setError('User or family not initialized');
      return null;
    }

    _clearError();

    try {
      final invitation = await _familyDataService.createInvitation(
        familyId: _currentFamily!.id,
        invitedBy: _currentUserId!,
        invitedEmail: invitedEmail,
        invitedPhone: invitedPhone,
        suggestedRole: suggestedRole,
        validFor: validFor,
      );
      
      _logger.info('Family invitation created via provider: ${invitation.id}');
      return invitation;
    } catch (e, stackTrace) {
      _setError('Failed to create invitation: $e');
      _logger.error('Failed to create invitation via provider: $e', stackTrace);
      return null;
    }
  }

  /// Check if current user has specific permission
  bool hasPermission(String permission) {
    if (_currentUserId == null || _currentFamily == null) return false;
    
    return _familyDataService.hasPermission(
      familyId: _currentFamily!.id,
      userId: _currentUserId!,
      permission: permission,
    );
  }

  /// Get family members by role
  List<FamilyMemberWithUser> getMembersByRole(FamilyRole role) {
    return _familyMembersWithUsers.where((member) => 
        member.familyMember.role == role).toList();
  }

  /// Get elder members
  List<FamilyMemberWithUser> get elders => getMembersByRole(FamilyRole.elder);

  /// Get caregiver members
  List<FamilyMemberWithUser> get caregivers => [
    ...getMembersByRole(FamilyRole.primaryCaregiver),
    ...getMembersByRole(FamilyRole.secondaryCaregiver),
  ];

  /// Get youth members
  List<FamilyMemberWithUser> get youth => getMembersByRole(FamilyRole.youth);

  /// Refresh all family data
  Future<void> refresh() async {
    if (_currentFamily == null) return;
    
    _setLoading(true);
    await _loadFamilyData();
    _setLoading(false);
  }

  // Private helper methods

  Future<void> _loadFamilyData() async {
    if (_currentFamily == null) return;

    try {
      final members = await _familyDataService.getFamilyMembers(_currentFamily!.id);
      final membersWithUsers = await _familyDataService.getFamilyMembersWithUserDetails(_currentFamily!.id);
      
      _familyMembers = members;
      _familyMembersWithUsers = membersWithUsers;
      
      await _loadFamilyStatistics();
    } catch (e) {
      _logger.warning('Failed to load family data: $e');
    }
  }

  Future<void> _loadFamilyStatistics() async {
    if (_currentFamily == null) return;

    try {
      final stats = await _familyDataService.getFamilyStatistics(_currentFamily!.id);
      _familyStatistics = stats;
    } catch (e) {
      _logger.warning('Failed to load family statistics: $e');
    }
  }

  void _onFamilyUpdated(Family? family) {
    _currentFamily = family;
    notifyListeners();
  }

  void _onFamilyMembersUpdated(List<FamilyMember> members) {
    _familyMembers = members;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _familyDataService.dispose();
    super.dispose();
  }
}