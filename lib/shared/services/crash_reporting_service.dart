import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'analytics_service.dart';
import 'package:family_bridge/shared/core/config/env_config.dart';

/// Service for crash reporting and error tracking
class CrashReportingService {
  static CrashReportingService? _instance;
  
  factory CrashReportingService() {
    _instance ??= CrashReportingService._internal();
    return _instance!;
  }
  
  CrashReportingService._internal();
  
  bool _isInitialized = false;
  
  /// Initialize crash reporting
  Future<void> initialize() async {
    if (_isInitialized || !EnvConfig.crashlyticsEnabled) return;
    
    try {
      // Initialize Firebase Crashlytics if available
      // await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      
      // Set up global error handling
      _setupGlobalErrorHandling();
      
      _isInitialized = true;
      _logDebug('Crash reporting initialized');
    } catch (e) {
      _logDebug('Failed to initialize crash reporting: $e');
    }
  }
  
  /// Record a non-fatal error
  Future<void> recordError({
    required dynamic exception,
    StackTrace? stackTrace,
    String? reason,
    Map<String, dynamic>? customKeys,
    bool fatal = false,
  }) async {
    if (!_shouldReport()) return;
    
    try {
      // Record error with Firebase Crashlytics
      // await FirebaseCrashlytics.instance.recordError(
      //   exception,
      //   stackTrace ?? StackTrace.current,
      //   reason: reason,
      //   fatal: fatal,
      // );
      
      // Add custom keys if provided
      if (customKeys != null) {
        for (final entry in customKeys.entries) {
          await setCustomKey(entry.key, entry.value);
        }
      }
      
      // Also track in analytics
      await AnalyticsService().trackError(
        error: exception.toString(),
        stackTrace: stackTrace?.toString(),
        additionalInfo: {
          'reason': reason,
          'fatal': fatal.toString(),
          ...?customKeys?.map((k, v) => MapEntry(k, v?.toString())),
        },
      );
      
      _logDebug('Error recorded: $exception${reason != null ? ' ($reason)' : ''}');
    } catch (e) {
      _logDebug('Failed to record error: $e');
    }
  }
  
  /// Record a Flutter error
  Future<void> recordFlutterError(FlutterErrorDetails errorDetails) async {
    if (!_shouldReport()) return;
    
    await recordError(
      exception: errorDetails.exception,
      stackTrace: errorDetails.stack,
      reason: errorDetails.context?.toString(),
      customKeys: {
        'library': errorDetails.library,
        'silent': errorDetails.silent,
      },
    );
  }
  
  /// Set custom key-value pair for crash reports
  Future<void> setCustomKey(String key, dynamic value) async {
    if (!_shouldReport()) return;
    
    try {
      // await FirebaseCrashlytics.instance.setCustomKey(key, value);
      _logDebug('Custom key set: $key = $value');
    } catch (e) {
      _logDebug('Failed to set custom key $key: $e');
    }
  }
  
  /// Set user identifier for crash reports
  Future<void> setUserIdentifier(String identifier) async {
    if (!_shouldReport()) return;
    
    try {
      // await FirebaseCrashlytics.instance.setUserIdentifier(identifier);
      _logDebug('User identifier set: $identifier');
    } catch (e) {
      _logDebug('Failed to set user identifier: $e');
    }
  }
  
  /// Log a message for crash reports
  Future<void> log(String message) async {
    if (!_shouldReport()) return;
    
    try {
      // await FirebaseCrashlytics.instance.log(message);
      _logDebug('Log message: $message');
    } catch (e) {
      _logDebug('Failed to log message: $e');
    }
  }
  
  /// Force a crash (for testing purposes only)
  Future<void> testCrash() async {
    if (!kDebugMode) return; // Only allow in debug mode
    
    try {
      // await FirebaseCrashlytics.instance.crash();
      throw Exception('Test crash from CrashReportingService');
    } catch (e) {
      _logDebug('Test crash triggered: $e');
      rethrow;
    }
  }
  
  /// Check if crash reporting is available
  Future<bool> isCrashReportingAvailable() async {
    try {
      // return await FirebaseCrashlytics.instance.isCrashlyticsCollectionEnabled();
      return _isInitialized && EnvConfig.crashlyticsEnabled;
    } catch (e) {
      return false;
    }
  }
  
  /// Set up application context information
  Future<void> setAppContext({
    String? version,
    String? buildNumber,
    String? environment,
    String? deviceId,
    String? userId,
    String? userType,
  }) async {
    if (!_shouldReport()) return;
    
    final context = <String, dynamic>{
      if (version != null) 'app_version': version,
      if (buildNumber != null) 'build_number': buildNumber,
      if (environment != null) 'environment': environment,
      if (deviceId != null) 'device_id': deviceId,
      if (userId != null) 'user_id': userId,
      if (userType != null) 'user_type': userType,
      'platform': Platform.operatingSystem,
      'platform_version': Platform.operatingSystemVersion,
    };
    
    for (final entry in context.entries) {
      await setCustomKey(entry.key, entry.value);
    }
  }
  
  /// Record breadcrumb for debugging
  Future<void> recordBreadcrumb({
    required String message,
    String? category,
    Map<String, dynamic>? data,
  }) async {
    if (!_shouldReport()) return;
    
    final breadcrumb = {
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
      if (category != null) 'category': category,
      if (data != null) ...data,
    };
    
    await log('Breadcrumb: ${breadcrumb.toString()}');
  }
  
  /// Handle unhandled exceptions
  void _setupGlobalErrorHandling() {
    // Handle Flutter errors
    FlutterError.onError = (FlutterErrorDetails details) {
      recordFlutterError(details);
    };
    
    // Handle platform errors (Dart errors outside Flutter)
    PlatformDispatcher.instance.onError = (error, stack) {
      recordError(
        exception: error,
        stackTrace: stack,
        reason: 'Unhandled platform error',
        fatal: true,
      );
      return true;
    };
    
    // Handle zone errors
    runZonedGuarded(() {
      // App runs in this zone
    }, (error, stackTrace) {
      recordError(
        exception: error,
        stackTrace: stackTrace,
        reason: 'Unhandled zone error',
        fatal: true,
      );
    });
  }
  
  /// Check if crash reporting should be enabled
  bool _shouldReport() {
    return _isInitialized && 
           EnvConfig.crashlyticsEnabled && 
           !kDebugMode; // Don't report crashes in debug mode
  }
  
  /// Debug logging
  void _logDebug(String message) {
    if (kDebugMode) {
      developer.log(message, name: 'CrashReportingService');
    }
  }
  
  /// Dispose resources
  void dispose() {
    _instance = null;
  }
}

/// Extension to help with error reporting in widgets
extension ErrorReportingWidget on StatefulWidget {
  /// Wrap widget build method with error reporting
  Widget buildWithErrorReporting(
    BuildContext context,
    Widget Function() builder,
  ) {
    try {
      return builder();
    } catch (e, stackTrace) {
      CrashReportingService().recordError(
        exception: e,
        stackTrace: stackTrace,
        reason: 'Widget build error in ${runtimeType}',
      );
      
      // Return error widget
      return ErrorWidget(e);
    }
  }
}

/// Mixin to add error reporting capabilities to any class
mixin ErrorReporting {
  /// Record error with context
  Future<void> reportError({
    required dynamic exception,
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? additionalInfo,
    bool fatal = false,
  }) async {
    await CrashReportingService().recordError(
      exception: exception,
      stackTrace: stackTrace ?? StackTrace.current,
      reason: context ?? 'Error in ${runtimeType}',
      customKeys: additionalInfo,
      fatal: fatal,
    );
  }
  
  /// Execute function with error reporting
  Future<T?> executeWithErrorReporting<T>(
    Future<T> Function() function, {
    String? context,
    T? defaultValue,
    bool rethrow = false,
  }) async {
    try {
      return await function();
    } catch (e, stackTrace) {
      await reportError(
        exception: e,
        stackTrace: stackTrace,
        context: context ?? 'Error executing function in ${runtimeType}',
      );
      
      if (rethrow) rethrow;
      return defaultValue;
    }
  }
}