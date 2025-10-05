import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'package:family_bridge/shared/core/config/env_config.dart';
import 'package:family_bridge/shared/core/constants/app_constants.dart';

/// Service for tracking user events and app analytics
class AnalyticsService {
  static AnalyticsService? _instance;
  
  factory AnalyticsService() {
    _instance ??= AnalyticsService._internal();
    return _instance!;
  }
  
  AnalyticsService._internal();
  
  bool _isInitialized = false;
  
  /// Initialize analytics service
  Future<void> initialize() async {
    if (_isInitialized || !EnvConfig.analyticsEnabled) return;
    
    try {
      // Initialize Firebase Analytics if available
      // await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
      
      _isInitialized = true;
      _logDebug('Analytics service initialized');
    } catch (e) {
      _logDebug('Failed to initialize analytics: $e');
    }
  }
  
  /// Track user login event
  Future<void> trackLogin(String method) async {
    if (!_shouldTrack()) return;
    
    await _trackEvent(AppConstants.loginEventName, parameters: {
      'method': method,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// Track user logout event
  Future<void> trackLogout() async {
    if (!_shouldTrack()) return;
    
    await _trackEvent(AppConstants.logoutEventName, parameters: {
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// Track message sent event
  Future<void> trackMessageSent(String messageType, String chatType) async {
    if (!_shouldTrack()) return;
    
    await _trackEvent(AppConstants.messageEventName, parameters: {
      'message_type': messageType,
      'chat_type': chatType,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// Track appointment creation
  Future<void> trackAppointmentCreated(String appointmentType) async {
    if (!_shouldTrack()) return;
    
    await _trackEvent(AppConstants.appointmentEventName, parameters: {
      'appointment_type': appointmentType,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// Track health data addition
  Future<void> trackHealthDataAdded(String dataType) async {
    if (!_shouldTrack()) return;
    
    await _trackEvent(AppConstants.healthDataEventName, parameters: {
      'data_type': dataType,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// Track emergency alert
  Future<void> trackEmergencyAlert(String alertType) async {
    if (!_shouldTrack()) return;
    
    await _trackEvent(AppConstants.emergencyEventName, parameters: {
      'alert_type': alertType,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// Track screen view
  Future<void> trackScreenView(String screenName) async {
    if (!_shouldTrack()) return;
    
    await _trackEvent('screen_view', parameters: {
      'screen_name': screenName,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  /// Track custom event
  Future<void> trackEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
  }) async {
    if (!_shouldTrack()) return;
    
    await _trackEvent(eventName, parameters: parameters);
  }
  
  /// Track user properties
  Future<void> setUserProperties({
    String? userId,
    String? userType,
    int? age,
    String? location,
    Map<String, dynamic>? customProperties,
  }) async {
    if (!_shouldTrack()) return;
    
    try {
      // Set user properties in Firebase Analytics
      // if (userId != null) {
      //   await FirebaseAnalytics.instance.setUserId(id: userId);
      // }
      
      final properties = <String, dynamic>{
        if (userType != null) 'user_type': userType,
        if (age != null) 'age': age,
        if (location != null) 'location': location,
        ...?customProperties,
      };
      
      for (final entry in properties.entries) {
        // await FirebaseAnalytics.instance.setUserProperty(
        //   name: entry.key,
        //   value: entry.value?.toString(),
        // );
      }
      
      _logDebug('User properties set: $properties');
    } catch (e) {
      _logDebug('Failed to set user properties: $e');
    }
  }
  
  /// Set current screen
  Future<void> setCurrentScreen(String screenName) async {
    if (!_shouldTrack()) return;
    
    try {
      // await FirebaseAnalytics.instance.setCurrentScreen(screenName: screenName);
      _logDebug('Current screen set: $screenName');
    } catch (e) {
      _logDebug('Failed to set current screen: $e');
    }
  }
  
  /// Track app performance metrics
  Future<void> trackPerformance({
    required String metricName,
    required int value,
    Map<String, String>? attributes,
  }) async {
    if (!_shouldTrack()) return;
    
    try {
      // Track performance metrics
      await _trackEvent('performance_metric', parameters: {
        'metric_name': metricName,
        'value': value,
        'attributes': attributes,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      _logDebug('Performance tracked: $metricName = $value');
    } catch (e) {
      _logDebug('Failed to track performance: $e');
    }
  }
  
  /// Track error/exception
  Future<void> trackError({
    required String error,
    String? stackTrace,
    Map<String, dynamic>? additionalInfo,
  }) async {
    if (!_shouldTrack()) return;
    
    try {
      await _trackEvent('app_error', parameters: {
        'error': error,
        'stack_trace': stackTrace,
        'additional_info': additionalInfo,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      _logDebug('Error tracked: $error');
    } catch (e) {
      _logDebug('Failed to track error: $e');
    }
  }
  
  /// Internal method to track events
  Future<void> _trackEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
  }) async {
    try {
      // Track event in Firebase Analytics
      // await FirebaseAnalytics.instance.logEvent(
      //   name: eventName,
      //   parameters: parameters,
      // );
      
      _logDebug('Event tracked: $eventName with parameters: $parameters');
    } catch (e) {
      _logDebug('Failed to track event $eventName: $e');
    }
  }
  
  /// Check if tracking should be enabled
  bool _shouldTrack() {
    return _isInitialized && 
           EnvConfig.analyticsEnabled && 
           !kDebugMode; // Don't track in debug mode by default
  }
  
  /// Debug logging
  void _logDebug(String message) {
    if (kDebugMode) {
      developer.log(message, name: 'AnalyticsService');
    }
  }
  
  /// Dispose resources
  void dispose() {
    _instance = null;
  }
}