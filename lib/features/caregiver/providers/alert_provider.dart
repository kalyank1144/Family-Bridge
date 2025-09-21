import 'package:flutter/foundation.dart';
import '../models/alert_model.dart';
import '../services/alert_service.dart';
import '../../shared/services/logging_service.dart';

/// Provider for managing caregiver alerts and notifications
/// Integrates AlertService with Flutter UI layer using ChangeNotifier
class AlertProvider extends ChangeNotifier {
  final AlertService _alertService = AlertService();
  final LoggingService _logger = LoggingService();

  List<Alert> _alerts = [];
  bool _isLoading = false;
  String? _error;
  String? _currentFamilyId;
  Map<String, int> _alertStats = {};

  // Getters
  List<Alert> get alerts => _alerts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, int> get alertStats => _alertStats;
  List<Alert> get activeAlerts => _alerts.where((alert) => alert.isActive).toList();
  List<Alert> get criticalAlerts => _alerts.where((alert) => 
      alert.severity == AlertSeverity.critical && alert.isActive).toList();

  /// Initialize the provider with family ID
  Future<void> initialize(String familyId) async {
    _currentFamilyId = familyId;
    _setLoading(true);
    _clearError();

    try {
      await _alertService.initialize(familyId);
      await _loadAlerts();
      await _loadAlertStatistics();
      
      // Subscribe to real-time updates
      _alertService.alertsStream.listen(_onAlertsUpdated);
      _alertService.newAlertStream.listen(_onNewAlert);
      
      _logger.info('AlertProvider initialized for family: $familyId');
    } catch (e, stackTrace) {
      _setError('Failed to initialize alerts: $e');
      _logger.error('AlertProvider initialization failed: $e', stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new alert
  Future<void> createAlert({
    required AlertType type,
    required AlertSeverity severity,
    required String title,
    required String message,
    String? userId,
    Map<String, dynamic>? data,
    String? actionRequired,
  }) async {
    if (_currentFamilyId == null) {
      _setError('Family not initialized');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      await _alertService.createAlert(
        familyId: _currentFamilyId!,
        userId: userId,
        type: type,
        severity: severity,
        title: title,
        message: message,
        data: data,
        actionRequired: actionRequired,
      );
      
      // Refresh alerts and statistics
      await _loadAlerts();
      await _loadAlertStatistics();
      
      _logger.info('Alert created via provider: $type - $title');
    } catch (e, stackTrace) {
      _setError('Failed to create alert: $e');
      _logger.error('Failed to create alert via provider: $e', stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  /// Create medication-specific alert
  Future<void> createMedicationAlert({
    required String userId,
    required String medicationId,
    required AlertType type,
    required String medicationName,
    String? notes,
  }) async {
    if (_currentFamilyId == null) return;

    try {
      await _alertService.createMedicationAlert(
        familyId: _currentFamilyId!,
        userId: userId,
        medicationId: medicationId,
        type: type,
        medicationName: medicationName,
        notes: notes,
      );
      
      await _loadAlerts();
      await _loadAlertStatistics();
    } catch (e) {
      _setError('Failed to create medication alert: $e');
    }
  }

  /// Create health concern alert
  Future<void> createHealthConcernAlert({
    required String userId,
    required String concern,
    required AlertSeverity severity,
    Map<String, dynamic>? healthData,
  }) async {
    if (_currentFamilyId == null) return;

    try {
      await _alertService.createHealthConcernAlert(
        familyId: _currentFamilyId!,
        userId: userId,
        concern: concern,
        severity: severity,
        healthData: healthData,
      );
      
      await _loadAlerts();
      await _loadAlertStatistics();
    } catch (e) {
      _setError('Failed to create health concern alert: $e');
    }
  }

  /// Create emergency alert
  Future<void> createEmergencyAlert({
    required String userId,
    required String emergencyType,
    String? location,
    Map<String, dynamic>? emergencyData,
  }) async {
    if (_currentFamilyId == null) return;

    try {
      await _alertService.createEmergencyAlert(
        familyId: _currentFamilyId!,
        userId: userId,
        emergencyType: emergencyType,
        location: location,
        emergencyData: emergencyData,
      );
      
      await _loadAlerts();
      await _loadAlertStatistics();
    } catch (e) {
      _setError('Failed to create emergency alert: $e');
    }
  }

  /// Acknowledge an alert
  Future<void> acknowledgeAlert(String alertId, String acknowledgedBy) async {
    _clearError();

    try {
      await _alertService.acknowledgeAlert(alertId, acknowledgedBy);
      await _loadAlerts();
      await _loadAlertStatistics();
    } catch (e) {
      _setError('Failed to acknowledge alert: $e');
    }
  }

  /// Resolve an alert
  Future<void> resolveAlert(String alertId, String resolvedBy, [String? resolution]) async {
    _clearError();

    try {
      await _alertService.resolveAlert(alertId, resolvedBy, resolution);
      await _loadAlerts();
      await _loadAlertStatistics();
    } catch (e) {
      _setError('Failed to resolve alert: $e');
    }
  }

  /// Process escalations for alerts
  Future<void> processEscalations() async {
    if (_currentFamilyId == null) return;

    try {
      await _alertService.processEscalations(_currentFamilyId!);
      await _loadAlerts();
    } catch (e) {
      _setError('Failed to process escalations: $e');
    }
  }

  /// Get alerts by type
  List<Alert> getAlertsByType(AlertType type) {
    return _alerts.where((alert) => alert.type == type).toList();
  }

  /// Get alerts by severity
  List<Alert> getAlertsBySeverity(AlertSeverity severity) {
    return _alerts.where((alert) => alert.severity == severity).toList();
  }

  /// Clear all alerts for UI reset
  void clearAlerts() {
    _alerts.clear();
    _alertStats.clear();
    notifyListeners();
  }

  // Private methods

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

  Future<void> _loadAlerts() async {
    if (_currentFamilyId == null) return;

    try {
      final alerts = await _alertService.getAlerts(familyId: _currentFamilyId!);
      _alerts = alerts;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load alerts: $e');
    }
  }

  Future<void> _loadAlertStatistics() async {
    if (_currentFamilyId == null) return;

    try {
      final stats = await _alertService.getAlertStatistics(_currentFamilyId!);
      _alertStats = stats;
      notifyListeners();
    } catch (e) {
      _logger.warning('Failed to load alert statistics: $e');
    }
  }

  void _onAlertsUpdated(List<Alert> alerts) {
    _alerts = alerts;
    notifyListeners();
  }

  void _onNewAlert(Alert alert) {
    if (!_alerts.any((a) => a.id == alert.id)) {
      _alerts.insert(0, alert);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _alertService.dispose();
    super.dispose();
  }
}