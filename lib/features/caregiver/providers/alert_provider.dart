import 'package:flutter/material.dart';
import '../models/alert.dart';
import '../services/alert_service.dart';
import '../../../core/services/notification_service.dart';

class AlertProvider extends ChangeNotifier {
  final AlertService _service = AlertService();
  final NotificationService _notificationService = NotificationService.instance;
  
  List<Alert> _alerts = [];
  bool _isLoading = false;
  String? _error;
  Map<AlertType, bool> _alertPreferences = {};
  Map<String, AlertPriority> _memberAlertThresholds = {};

  List<Alert> get alerts => _alerts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<AlertType, bool> get alertPreferences => _alertPreferences;

  List<Alert> get unreadAlerts => _alerts.where((a) => !a.isRead).toList();
  List<Alert> get criticalAlerts => _alerts.where((a) => a.priority == AlertPriority.critical).toList();
  List<Alert> get highPriorityAlerts => _alerts.where((a) => 
    a.priority == AlertPriority.critical || a.priority == AlertPriority.high
  ).toList();

  int get unreadCount => unreadAlerts.length;
  int get criticalCount => criticalAlerts.length;

  List<Alert> getAlertsForMember(String memberId) {
    return _alerts.where((a) => a.familyMemberId == memberId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<Alert> getAlertsByType(AlertType type) {
    return _alerts.where((a) => a.type == type).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  AlertProvider() {
    loadAlerts();
    _initializeAlertPreferences();
    _subscribeToRealTimeAlerts();
  }

  void _initializeAlertPreferences() {
    for (final type in AlertType.values) {
      _alertPreferences[type] = true;
    }
  }

  Future<void> loadAlerts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _alerts = await _service.getAlerts();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _loadMockAlerts();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _loadMockAlerts() {
    final now = DateTime.now();
    
    _alerts = [
      Alert(
        id: '1',
        familyMemberId: '2',
        familyMemberName: 'Eva',
        type: AlertType.missedMedication,
        priority: AlertPriority.high,
        title: 'Missed Medication',
        description: 'Eva missed her morning medication (Lisinopril 10mg)',
        timestamp: now.subtract(const Duration(minutes: 30)),
        actionRequired: 'Contact Eva to remind about medication',
        metadata: {'medication': 'Lisinopril', 'dosage': '10mg', 'time': '8:00 AM'},
      ),
      Alert(
        id: '2',
        familyMemberId: '2',
        familyMemberName: 'Eva',
        type: AlertType.abnormalVitals,
        priority: AlertPriority.critical,
        title: 'High Blood Pressure Alert',
        description: 'Eva\'s blood pressure reading is 160/95 (Critical)',
        timestamp: now.subtract(const Duration(minutes: 15)),
        actionRequired: 'Contact doctor immediately',
        metadata: {'systolic': 160, 'diastolic': 95},
      ),
      Alert(
        id: '3',
        familyMemberId: '1',
        familyMemberName: 'Walter',
        type: AlertType.appointmentReminder,
        priority: AlertPriority.medium,
        title: 'Appointment Tomorrow',
        description: 'Walter has an appointment with Dr. Smith at 9:00 AM',
        timestamp: now.subtract(const Duration(hours: 1)),
        metadata: {'doctor': 'Dr. Smith', 'time': '9:00 AM', 'location': 'Medical Center'},
      ),
      Alert(
        id: '4',
        familyMemberId: '2',
        familyMemberName: 'Eva',
        type: AlertType.missedCheckIn,
        priority: AlertPriority.medium,
        title: 'Missed Daily Check-in',
        description: 'Eva hasn\'t completed her daily check-in',
        timestamp: now.subtract(const Duration(hours: 2)),
        actionRequired: 'Call Eva to check on her',
      ),
      Alert(
        id: '5',
        familyMemberId: '1',
        familyMemberName: 'Walter',
        type: AlertType.batteryLow,
        priority: AlertPriority.low,
        title: 'Device Battery Low',
        description: 'Walter\'s health monitor battery is at 15%',
        timestamp: now.subtract(const Duration(hours: 3)),
        isRead: true,
        metadata: {'battery_level': 15},
      ),
      Alert(
        id: '6',
        familyMemberId: '3',
        familyMemberName: 'Eugene',
        type: AlertType.systemUpdate,
        priority: AlertPriority.low,
        title: 'System Update Available',
        description: 'New features available for Eugene\'s app',
        timestamp: now.subtract(const Duration(days: 1)),
        isRead: true,
        isAcknowledged: true,
      ),
    ];
  }

  Future<void> markAlertAsRead(String alertId) async {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _alerts[index] = Alert(
        id: _alerts[index].id,
        familyMemberId: _alerts[index].familyMemberId,
        familyMemberName: _alerts[index].familyMemberName,
        type: _alerts[index].type,
        priority: _alerts[index].priority,
        title: _alerts[index].title,
        description: _alerts[index].description,
        timestamp: _alerts[index].timestamp,
        isRead: true,
        isAcknowledged: _alerts[index].isAcknowledged,
        actionRequired: _alerts[index].actionRequired,
        metadata: _alerts[index].metadata,
      );
      notifyListeners();
      
      await _service.markAlertAsRead(alertId);
    }
  }

  Future<void> acknowledgeAlert(String alertId) async {
    final index = _alerts.indexWhere((a) => a.id == alertId);
    if (index != -1) {
      _alerts[index] = Alert(
        id: _alerts[index].id,
        familyMemberId: _alerts[index].familyMemberId,
        familyMemberName: _alerts[index].familyMemberName,
        type: _alerts[index].type,
        priority: _alerts[index].priority,
        title: _alerts[index].title,
        description: _alerts[index].description,
        timestamp: _alerts[index].timestamp,
        isRead: true,
        isAcknowledged: true,
        actionRequired: _alerts[index].actionRequired,
        metadata: _alerts[index].metadata,
      );
      notifyListeners();
      
      await _service.acknowledgeAlert(alertId);
    }
  }

  Future<void> clearAlert(String alertId) async {
    _alerts.removeWhere((a) => a.id == alertId);
    notifyListeners();
    
    await _service.deleteAlert(alertId);
  }

  void updateAlertPreference(AlertType type, bool enabled) {
    _alertPreferences[type] = enabled;
    notifyListeners();
    _service.updateAlertPreferences(_alertPreferences);
  }

  void updateMemberAlertThreshold(String memberId, AlertPriority threshold) {
    _memberAlertThresholds[memberId] = threshold;
    notifyListeners();
    _service.updateMemberAlertThreshold(memberId, threshold);
  }

  void _subscribeToRealTimeAlerts() {
    _service.subscribeToAlerts((alert) {
      _alerts.insert(0, alert);
      notifyListeners();
      
      if (alert.priority == AlertPriority.critical) {
        _notificationService.showCriticalAlert(alert);
      } else if (alert.priority == AlertPriority.high) {
        _notificationService.showHighPriorityAlert(alert);
      } else {
        _notificationService.showNotification(alert);
      }
    });
  }

  Future<void> refresh() async {
    await loadAlerts();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}