import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';
import 'hipaa_audit_service.dart';

/// Permission types for the application
enum Permission {
  // Health data permissions
  viewHealthData,
  editHealthData,
  exportHealthData,
  deleteHealthData,

  // Family permissions
  viewFamilyMembers,
  inviteFamilyMembers,
  removeFamilyMembers,
  manageFamilySettings,

  // Medication permissions
  viewMedications,
  manageMedications,
  acknowledgeMedications,

  // Appointment permissions
  viewAppointments,
  scheduleAppointments,
  editAppointments,
  cancelAppointments,

  // Emergency permissions
  viewEmergencyContacts,
  editEmergencyContacts,
  triggerEmergencyAlert,
  accessEmergencyOverride,

  // Chat permissions
  viewFamilyChat,
  sendMessages,
  deleteMessages,
  moderateChat,

  // Report permissions
  viewReports,
  generateReports,
  exportReports,

  // Admin permissions
  viewAuditLogs,
  manageUsers,
  manageRoles,
  viewCompliance,
  manageSystem,

  // Youth-specific permissions
  playGames,
  recordStories,
  sharePhotos,
  viewRewards,

  // Caregiver-specific permissions
  monitorAllElders,
  createCarePlans,
  viewProfessionalTools,
  manageAlerts,

  // Elder-specific permissions
  simplifiedInterface,
  voiceControl,
  emergencyButton,
  dailyCheckin,
}

/// Feature that can be accessed
enum Feature {
  dashboard,
  profile,
  familyChat,
  medications,
  appointments,
  healthMonitoring,
  emergencyContacts,
  dailyCheckin,
  reports,
  games,
  storyTime,
  photoSharing,
  carePlans,
  alerts,
  adminPanel,
  complianceDashboard,
  auditLogs,
}

/// Role-based permission mapping
class RolePermissions {
  static final Map<UserRole, Set<Permission>> _rolePermissions = {
    UserRole.elder: {
      Permission.viewHealthData,
      Permission.viewFamilyMembers,
      Permission.viewMedications,
      Permission.acknowledgeMedications,
      Permission.viewAppointments,
      Permission.viewEmergencyContacts,
      Permission.editEmergencyContacts,
      Permission.triggerEmergencyAlert,
      Permission.viewFamilyChat,
      Permission.sendMessages,
      Permission.simplifiedInterface,
      Permission.voiceControl,
      Permission.emergencyButton,
      Permission.dailyCheckin,
    },
    UserRole.caregiver: {
      Permission.viewHealthData,
      Permission.editHealthData,
      Permission.exportHealthData,
      Permission.viewFamilyMembers,
      Permission.inviteFamilyMembers,
      Permission.manageFamilySettings,
      Permission.viewMedications,
      Permission.manageMedications,
      Permission.viewAppointments,
      Permission.scheduleAppointments,
      Permission.editAppointments,
      Permission.cancelAppointments,
      Permission.viewEmergencyContacts,
      Permission.editEmergencyContacts,
      Permission.accessEmergencyOverride,
      Permission.viewFamilyChat,
      Permission.sendMessages,
      Permission.deleteMessages,
      Permission.moderateChat,
      Permission.viewReports,
      Permission.generateReports,
      Permission.exportReports,
      Permission.monitorAllElders,
      Permission.createCarePlans,
      Permission.viewProfessionalTools,
      Permission.manageAlerts,
    },
    UserRole.youth: {
      Permission.viewFamilyMembers,
      Permission.viewFamilyChat,
      Permission.sendMessages,
      Permission.playGames,
      Permission.recordStories,
      Permission.sharePhotos,
      Permission.viewRewards,
      Permission.viewAppointments,
    },
  };

  static final Map<UserRole, Set<Feature>> _roleFeatures = {
    UserRole.elder: {
      Feature.dashboard,
      Feature.profile,
      Feature.familyChat,
      Feature.medications,
      Feature.appointments,
      Feature.emergencyContacts,
      Feature.dailyCheckin,
    },
    UserRole.caregiver: {
      Feature.dashboard,
      Feature.profile,
      Feature.familyChat,
      Feature.medications,
      Feature.appointments,
      Feature.healthMonitoring,
      Feature.emergencyContacts,
      Feature.reports,
      Feature.carePlans,
      Feature.alerts,
    },
    UserRole.youth: {
      Feature.dashboard,
      Feature.profile,
      Feature.familyChat,
      Feature.games,
      Feature.storyTime,
      Feature.photoSharing,
    },
  };

  static Set<Permission> getPermissionsForRole(UserRole role) {
    return _rolePermissions[role] ?? {};
  }

  static Set<Feature> getFeaturesForRole(UserRole role) {
    return _roleFeatures[role] ?? {};
  }
}

/// Access decision result
class AccessDecision {
  final bool granted;
  final String? reason;
  final bool requiresMfa;
  final bool requiresEmergencyAccess;

  AccessDecision({
    required this.granted,
    this.reason,
    this.requiresMfa = false,
    this.requiresEmergencyAccess = false,
  });
}

/// Role-based access control service
class RoleBasedAccessService {
  RoleBasedAccessService._();
  static final RoleBasedAccessService instance = RoleBasedAccessService._();

  final _supabase = Supabase.instance.client;
  final _auditService = HipaaAuditService.instance;

  UserProfile? _currentUser;
  Set<Permission>? _userPermissions;
  Set<Feature>? _userFeatures;
  Map<String, dynamic>? _familyPermissions;
  bool _hasEmergencyAccess = false;

  /// Initialize the service with current user
  Future<void> initialize() async {
    await _loadCurrentUser();
    await _loadFamilyPermissions();
    await _checkEmergencyAccess();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final userData = await _supabase
          .from('users')
          .select('*, user_profiles(*)')
          .eq('id', user.id)
          .maybeSingle();

      if (userData != null) {
        _currentUser = UserProfile(
          id: userData['id'],
          email: user.email ?? '',
          name: userData['name'] ?? '',
          phone: userData['phone'],
          role: UserRole.values.firstWhere(
            (e) => e.name == userData['role'],
            orElse: () => UserRole.elder,
          ),
          dateOfBirth: userData['date_of_birth'] != null
              ? DateTime.parse(userData['date_of_birth'])
              : null,
        );

        _userPermissions = RolePermissions.getPermissionsForRole(_currentUser!.role);
        _userFeatures = RolePermissions.getFeaturesForRole(_currentUser!.role);
      }
    } catch (e) {
      debugPrint('Error loading current user: $e');
    }
  }

  Future<void> _loadFamilyPermissions() async {
    if (_currentUser == null) return;

    try {
      final familyMemberships = await _supabase
          .from('family_members')
          .select('family_id, role, permissions')
          .eq('user_id', _currentUser!.id);

      _familyPermissions = {};
      for (final membership in familyMemberships) {
        _familyPermissions![membership['family_id']] = {
          'role': membership['role'],
          'permissions': membership['permissions'],
        };
      }
    } catch (e) {
      debugPrint('Error loading family permissions: $e');
    }
  }

  Future<void> _checkEmergencyAccess() async {
    if (_currentUser == null) return;

    try {
      final emergencyAccess = await _supabase
          .from('emergency_access')
          .select('id')
          .eq('caregiver_id', _currentUser!.id)
          .is_('revoked_at', null)
          .gt('expires_at', DateTime.now().toIso8601String())
          .limit(1);

      _hasEmergencyAccess = emergencyAccess.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking emergency access: $e');
    }
  }

  /// Check if user has a specific permission
  Future<bool> hasPermission(Permission permission) async {
    if (_currentUser == null || _userPermissions == null) {
      await initialize();
    }

    // Super admins have all permissions
    if (_currentUser?.role == UserRole.caregiver && 
        await _isAdminUser()) {
      return true;
    }

    // Check regular role permissions
    final hasPermission = _userPermissions?.contains(permission) ?? false;

    // Check for emergency override
    if (!hasPermission && _hasEmergencyAccess) {
      // Emergency access grants certain permissions
      const emergencyPermissions = {
        Permission.viewHealthData,
        Permission.viewMedications,
        Permission.viewAppointments,
        Permission.viewEmergencyContacts,
        Permission.accessEmergencyOverride,
      };
      
      if (emergencyPermissions.contains(permission)) {
        await _auditService.logAuthEvent(
          action: 'emergency_permission_used',
          metadata: {
            'permission': permission.name,
            'user_id': _currentUser!.id,
          },
          phiAccessed: true,
        );
        return true;
      }
    }

    return hasPermission;
  }

  /// Check if user can access a feature
  Future<bool> canAccessFeature(Feature feature) async {
    if (_currentUser == null || _userFeatures == null) {
      await initialize();
    }

    // Super admins can access all features
    if (_currentUser?.role == UserRole.caregiver && 
        await _isAdminUser()) {
      return true;
    }

    return _userFeatures?.contains(feature) ?? false;
  }

  /// Check if user can perform action on a resource
  Future<AccessDecision> canPerformAction({
    required Permission permission,
    String? resourceId,
    String? resourceType,
    Map<String, dynamic>? context,
  }) async {
    // Check basic permission
    if (!await hasPermission(permission)) {
      return AccessDecision(
        granted: false,
        reason: 'Insufficient permissions',
      );
    }

    // Check resource-specific rules
    if (resourceId != null && resourceType != null) {
      final decision = await _checkResourceAccess(
        permission: permission,
        resourceId: resourceId,
        resourceType: resourceType,
        context: context,
      );

      if (!decision.granted) {
        return decision;
      }
    }

    // Check if MFA is required for sensitive operations
    final requiresMfa = await _requiresMfaForAction(permission);
    if (requiresMfa) {
      return AccessDecision(
        granted: true,
        requiresMfa: true,
        reason: 'MFA verification required',
      );
    }

    // Log successful access check
    await _auditService.logAuthEvent(
      action: 'access_granted',
      metadata: {
        'permission': permission.name,
        'resource_id': resourceId,
        'resource_type': resourceType,
      },
      phiAccessed: _isPhiRelated(permission),
    );

    return AccessDecision(granted: true);
  }

  Future<AccessDecision> _checkResourceAccess({
    required Permission permission,
    required String resourceId,
    required String resourceType,
    Map<String, dynamic>? context,
  }) async {
    // Check family-based access
    if (resourceType == 'family_member') {
      return await _checkFamilyMemberAccess(permission, resourceId, context);
    }

    // Check elder data access
    if (resourceType == 'elder_data') {
      return await _checkElderDataAccess(permission, resourceId, context);
    }

    // Check medication access
    if (resourceType == 'medication') {
      return await _checkMedicationAccess(permission, resourceId, context);
    }

    return AccessDecision(granted: true);
  }

  Future<AccessDecision> _checkFamilyMemberAccess(
    Permission permission,
    String memberId,
    Map<String, dynamic>? context,
  ) async {
    final familyId = context?['family_id'];
    if (familyId == null) {
      return AccessDecision(
        granted: false,
        reason: 'Family context required',
      );
    }

    // Check if user is in the same family
    final myPermissions = _familyPermissions?[familyId];
    if (myPermissions == null) {
      return AccessDecision(
        granted: false,
        reason: 'Not a member of this family',
      );
    }

    // Check family role permissions
    final familyPermLevel = myPermissions['permissions'] as String;
    if (permission == Permission.removeFamilyMembers) {
      // Only owners and admins can remove members
      if (!['owner', 'admin'].contains(familyPermLevel)) {
        return AccessDecision(
          granted: false,
          reason: 'Only family owners and admins can remove members',
        );
      }
    }

    return AccessDecision(granted: true);
  }

  Future<AccessDecision> _checkElderDataAccess(
    Permission permission,
    String elderId,
    Map<String, dynamic>? context,
  ) async {
    // Check if caregiver has relationship with elder
    if (_currentUser?.role == UserRole.caregiver) {
      final hasRelationship = await _hasRelationshipWithElder(elderId);
      
      if (!hasRelationship && !_hasEmergencyAccess) {
        return AccessDecision(
          granted: false,
          reason: 'No relationship with this elder',
          requiresEmergencyAccess: true,
        );
      }
    }

    return AccessDecision(granted: true);
  }

  Future<AccessDecision> _checkMedicationAccess(
    Permission permission,
    String medicationId,
    Map<String, dynamic>? context,
  ) async {
    // Elders can only acknowledge their own medications
    if (_currentUser?.role == UserRole.elder &&
        permission == Permission.acknowledgeMedications) {
      final medication = await _supabase
          .from('medications')
          .select('user_id')
          .eq('id', medicationId)
          .maybeSingle();

      if (medication?['user_id'] != _currentUser!.id) {
        return AccessDecision(
          granted: false,
          reason: 'Can only acknowledge your own medications',
        );
      }
    }

    return AccessDecision(granted: true);
  }

  Future<bool> _hasRelationshipWithElder(String elderId) async {
    try {
      // Check if they're in the same family
      final relationship = await _supabase
          .from('family_members')
          .select('family_id')
          .eq('user_id', elderId)
          .limit(1);

      if (relationship.isEmpty) return false;

      final familyId = relationship[0]['family_id'];
      return _familyPermissions?.containsKey(familyId) ?? false;
    } catch (e) {
      debugPrint('Error checking elder relationship: $e');
      return false;
    }
  }

  Future<bool> _requiresMfaForAction(Permission permission) async {
    // List of sensitive permissions requiring MFA
    const sensitivePermissions = {
      Permission.exportHealthData,
      Permission.deleteHealthData,
      Permission.removeFamilyMembers,
      Permission.manageFamilySettings,
      Permission.accessEmergencyOverride,
      Permission.manageUsers,
      Permission.manageRoles,
      Permission.manageSystem,
    };

    if (!sensitivePermissions.contains(permission)) {
      return false;
    }

    // Check user's MFA settings
    try {
      final mfaSettings = await _supabase
          .from('user_mfa_settings')
          .select('require_mfa_for_sensitive_ops')
          .eq('user_id', _currentUser!.id)
          .maybeSingle();

      return mfaSettings?['require_mfa_for_sensitive_ops'] ?? true;
    } catch (e) {
      debugPrint('Error checking MFA requirement: $e');
      return true; // Default to requiring MFA for safety
    }
  }

  bool _isPhiRelated(Permission permission) {
    const phiPermissions = {
      Permission.viewHealthData,
      Permission.editHealthData,
      Permission.exportHealthData,
      Permission.deleteHealthData,
      Permission.viewMedications,
      Permission.manageMedications,
      Permission.viewReports,
      Permission.generateReports,
      Permission.exportReports,
    };

    return phiPermissions.contains(permission);
  }

  Future<bool> _isAdminUser() async {
    // Check if user has admin role in database
    try {
      if (_currentUser == null) return false;

      final adminCheck = await _supabase
          .from('users')
          .select('role')
          .eq('id', _currentUser!.id)
          .maybeSingle();

      final role = adminCheck?['role'] as String?;
      return role == 'Admin' || role == 'SuperAdmin';
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  /// Get list of permissions for current user
  Set<Permission> getCurrentUserPermissions() {
    return _userPermissions ?? {};
  }

  /// Get list of accessible features for current user
  Set<Feature> getCurrentUserFeatures() {
    return _userFeatures ?? {};
  }

  /// Check if user is in a specific family
  bool isInFamily(String familyId) {
    return _familyPermissions?.containsKey(familyId) ?? false;
  }

  /// Get user's role in a family
  String? getFamilyRole(String familyId) {
    return _familyPermissions?[familyId]?['role'];
  }

  /// Get user's permission level in a family
  String? getFamilyPermissionLevel(String familyId) {
    return _familyPermissions?[familyId]?['permissions'];
  }

  /// Refresh permissions (call after role changes)
  Future<void> refreshPermissions() async {
    _currentUser = null;
    _userPermissions = null;
    _userFeatures = null;
    _familyPermissions = null;
    _hasEmergencyAccess = false;
    await initialize();
  }

  /// Create a scoped permission check for UI
  Widget createPermissionGate({
    required Permission permission,
    required Widget child,
    Widget? fallback,
    String? resourceId,
    String? resourceType,
  }) {
    return FutureBuilder<AccessDecision>(
      future: canPerformAction(
        permission: permission,
        resourceId: resourceId,
        resourceType: resourceType,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final decision = snapshot.data;
        if (decision?.granted == true && decision?.requiresMfa == false) {
          return child;
        }

        return fallback ?? const SizedBox.shrink();
      },
    );
  }
}

/// Extension for easy permission checking
extension PermissionCheck on BuildContext {
  Future<bool> hasPermission(Permission permission) async {
    return RoleBasedAccessService.instance.hasPermission(permission);
  }

  Future<bool> canAccessFeature(Feature feature) async {
    return RoleBasedAccessService.instance.canAccessFeature(feature);
  }
}