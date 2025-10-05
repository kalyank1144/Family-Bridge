import 'package:flutter/material.dart';

import 'package:family_bridge/core/services/access_control_service.dart';
import 'package:family_bridge/core/services/encryption_service.dart';
import 'package:family_bridge/core/services/hipaa_audit_service.dart';
import 'package:family_bridge/features/admin/providers/hipaa_compliance_provider.dart';

/// Mixin to add HIPAA compliance features to any screen
mixin HipaaComplianceMixin<T extends StatefulWidget> on State<T> {
  HipaaComplianceProvider? _complianceProvider;
  String? _currentPhiContext;

  @override
  void initState() {
    super.initState();
    _initializeCompliance();
  }

  void _initializeCompliance() {
    // In production, this would be injected via Provider or similar
    _complianceProvider = HipaaComplianceProvider();
    _currentPhiContext = _getPhiContext();
  }

  /// Override this method to specify the PHI context for audit logging
  String _getPhiContext() {
    return runtimeType.toString();
  }

  /// Log PHI access when viewing health data
  Future<void> logPhiAccess(String phiId, String accessType, {Map<String, dynamic>? metadata}) async {
    if (_complianceProvider != null) {
      try {
        await _complianceProvider!.logPhiAccess(
          phiId: phiId,
          accessType: accessType,
          context: _currentPhiContext ?? 'unknown',
          metadata: metadata,
        );
      } catch (e) {
        _showSecurityError('PHI access denied: $e');
      }
    }
  }

  /// Check if user has required permission
  bool hasPermission(Permission permission) {
    return _complianceProvider?.hasPermission(permission) ?? false;
  }

  /// Require elevated access for sensitive operations
  Future<bool> requireElevatedAccess(Permission permission) async {
    if (_complianceProvider != null) {
      final hasAccess = await _complianceProvider!.requireElevatedAccess(permission);
      if (!hasAccess) {
        _showSecurityError('Elevated access required for this operation');
      }
      return hasAccess;
    }
    return false;
  }

  /// Encrypt sensitive data before storage
  Future<EncryptedData> encryptSensitiveData(String data, {Map<String, String>? metadata}) async {
    if (_complianceProvider != null) {
      return await _complianceProvider!.encryptPhiData(data, metadata: metadata);
    }
    throw Exception('Compliance provider not initialized');
  }

  /// Decrypt sensitive data after retrieval
  Future<String> decryptSensitiveData(EncryptedData encryptedData) async {
    if (_complianceProvider != null) {
      return await _complianceProvider!.decryptPhiData(encryptedData);
    }
    throw Exception('Compliance provider not initialized');
  }

  /// Show security-related error messages  
  void _showSecurityError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.security, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: Colors.red[700],
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  /// Build security warning widget
  Widget buildSecurityWarning(String message, {VoidCallback? onAction, String? actionLabel}) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.security, color: Colors.red[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Security Notice',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(message),
              ],
            ),
          ),
          if (onAction != null) ...[
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
              child: Text(actionLabel ?? 'Action'),
            ),
          ],
        ],
      ),
    );
  }

  /// Build compliance status indicator
  Widget buildComplianceStatusIndicator() {
    if (_complianceProvider == null) return const SizedBox.shrink();

    final complianceScore = _complianceProvider!.getComplianceScore();
    final riskLevel = _complianceProvider!.getRiskLevel();
    final hasBreaches = _complianceProvider!.hasActiveBreaches;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (hasBreaches || riskLevel == 'critical') {
      statusColor = Colors.red[700]!;
      statusIcon = Icons.error;
      statusText = 'Critical';
    } else if (riskLevel == 'high' || complianceScore < 85) {
      statusColor = Colors.orange[700]!;
      statusIcon = Icons.warning;
      statusText = 'Warning';
    } else if (complianceScore >= 95) {
      statusColor = Colors.green[700]!;
      statusIcon = Icons.verified;
      statusText = 'Compliant';
    } else {
      statusColor = Colors.blue[700]!;
      statusIcon = Icons.info;
      statusText = 'Good';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 16, color: statusColor),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          if (hasBreaches) ...[
            const SizedBox(width: 4),
            Text(
              '(${_complianceProvider!.criticalIncidentCount})',
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Protected method to access PHI data
  Future<T> accessPhiData<T>(
    String phiId, 
    Future<T> Function() dataAccessor, {
    String accessType = 'read',
    Map<String, dynamic>? metadata,
  }) async {
    // Log PHI access
    await logPhiAccess(phiId, accessType, metadata: metadata);
    
    // Execute the data access
    try {
      final result = await dataAccessor();
      
      // Log successful access
      await HipaaAuditService.instance.logEvent(
        eventType: AuditEventType.phiView,
        description: 'PHI data accessed successfully',
        phiIdentifier: phiId,
        metadata: {'accessType': accessType, ...?metadata},
      );
      
      return result;
    } catch (e) {
      // Log failed access
      await HipaaAuditService.instance.logEvent(
        eventType: AuditEventType.phiAccess,
        description: 'PHI data access failed',
        success: false,
        failureReason: e.toString(),
        phiIdentifier: phiId,
        metadata: {'accessType': accessType, ...?metadata},
      );
      rethrow;
    }
  }

  /// Protected method to modify PHI data
  Future<T> modifyPhiData<T>(
    String phiId,
    Future<T> Function() dataModifier, {
    String modificationType = 'update',
    Map<String, dynamic>? metadata,
  }) async {
    // Check elevated permissions for data modification
    final hasAccess = await requireElevatedAccess(Permission.writePhi);
    if (!hasAccess) {
      throw Exception('Insufficient permissions to modify PHI data');
    }

    // Log PHI modification attempt
    await HipaaAuditService.instance.logEvent(
      eventType: AuditEventType.phiModification,
      description: 'PHI modification initiated: $modificationType',
      phiIdentifier: phiId,
      metadata: {'modificationType': modificationType, ...?metadata},
    );

    try {
      final result = await dataModifier();
      
      // Log successful modification
      await HipaaAuditService.instance.logEvent(
        eventType: AuditEventType.phiModification,
        description: 'PHI modification completed successfully',
        phiIdentifier: phiId,
        metadata: {'modificationType': modificationType, ...?metadata},
      );
      
      return result;
    } catch (e) {
      // Log failed modification
      await HipaaAuditService.instance.logEvent(
        eventType: AuditEventType.phiModification,
        description: 'PHI modification failed',
        success: false,
        failureReason: e.toString(),
        phiIdentifier: phiId,
        metadata: {'modificationType': modificationType, ...?metadata},
      );
      rethrow;
    }
  }

  /// Build access permission gate widget
  Widget buildPermissionGate({
    required Permission requiredPermission,
    required Widget child,
    Widget? unauthorizedWidget,
  }) {
    if (hasPermission(requiredPermission)) {
      return child;
    }

    return unauthorizedWidget ?? Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Access Denied',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You do not have permission to access this content.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}