import 'package:flutter/foundation.dart';

import 'package:logging/logging.dart';

/// Centralized error handling and logging service
/// Provides consistent error reporting, logging, and user-friendly error messages
class ErrorService {
  static final ErrorService _instance = ErrorService._internal();
  static ErrorService get instance => _instance;
  ErrorService._internal();

  static final Logger _logger = Logger('ErrorService');
  
  /// Initialize error service and logging
  void initialize() {
    Logger.root.level = kDebugMode ? Level.ALL : Level.WARNING;
    Logger.root.onRecord.listen((record) {
      debugPrint('${record.level.name}: ${record.time}: ${record.message}');
      if (record.error != null) {
        debugPrint('Error: ${record.error}');
      }
      if (record.stackTrace != null) {
        debugPrint('Stack trace: ${record.stackTrace}');
      }
    });
  }

  /// Log and report application errors
  void logError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    _logger.severe(message, error, stackTrace);
    
    if (context != null) {
      _logger.info('Error context: $context');
    }

    // In production, send to crash reporting service
    if (!kDebugMode) {
      _sendToCrashReporting(message, error, stackTrace, context);
    }
  }

  /// Log warnings
  void logWarning(String message, {Map<String, dynamic>? context}) {
    _logger.warning(message);
    if (context != null) {
      _logger.info('Warning context: $context');
    }
  }

  /// Log informational messages
  void logInfo(String message, {Map<String, dynamic>? context}) {
    _logger.info(message);
    if (context != null) {
      _logger.fine('Info context: $context');
    }
  }

  /// Handle API errors with standardized responses
  AppError handleApiError(dynamic error) {
    if (error is AppError) {
      return error;
    }

    // Handle specific API error types
    if (error.toString().contains('SocketException')) {
      return AppError(
        type: ErrorType.network,
        message: 'No internet connection. Please check your network and try again.',
        userMessage: 'Connection Error',
        originalError: error,
      );
    }

    if (error.toString().contains('TimeoutException')) {
      return AppError(
        type: ErrorType.timeout,
        message: 'Request timeout. Please try again.',
        userMessage: 'Request Timeout',
        originalError: error,
      );
    }

    if (error.toString().contains('401')) {
      return AppError(
        type: ErrorType.authentication,
        message: 'Authentication failed. Please log in again.',
        userMessage: 'Authentication Required',
        originalError: error,
      );
    }

    if (error.toString().contains('403')) {
      return AppError(
        type: ErrorType.permission,
        message: 'You don\'t have permission to access this resource.',
        userMessage: 'Access Denied',
        originalError: error,
      );
    }

    if (error.toString().contains('404')) {
      return AppError(
        type: ErrorType.notFound,
        message: 'The requested resource was not found.',
        userMessage: 'Not Found',
        originalError: error,
      );
    }

    if (error.toString().contains('500') || error.toString().contains('502') || error.toString().contains('503')) {
      return AppError(
        type: ErrorType.server,
        message: 'Server error. Please try again later.',
        userMessage: 'Server Error',
        originalError: error,
      );
    }

    // Default unknown error
    return AppError(
      type: ErrorType.unknown,
      message: 'An unexpected error occurred. Please try again.',
      userMessage: 'Unexpected Error',
      originalError: error,
    );
  }

  /// Handle service-specific errors
  AppError handleServiceError(String service, dynamic error) {
    logError('$service error', error: error);
    
    final baseError = handleApiError(error);
    return baseError.copyWith(
      message: '$service: ${baseError.message}',
      context: {'service': service},
    );
  }

  /// Handle validation errors
  AppError handleValidationError(Map<String, List<String>> validationErrors) {
    final messages = validationErrors.values
        .expand((errors) => errors)
        .join('\n');
    
    return AppError(
      type: ErrorType.validation,
      message: 'Validation failed: $messages',
      userMessage: 'Invalid Input',
      context: {'validation_errors': validationErrors},
    );
  }

  /// Get user-friendly error message
  String getUserMessage(dynamic error) {
    if (error is AppError) {
      return error.userMessage;
    }

    final appError = handleApiError(error);
    return appError.userMessage;
  }

  /// Send error to crash reporting service (Firebase Crashlytics, Sentry, etc.)
  void _sendToCrashReporting(
    String message,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  ) {
    // TODO: Implement crash reporting service integration
    // Example: FirebaseCrashlytics.instance.recordError(error, stackTrace);
    debugPrint('Would send to crash reporting: $message');
  }

  /// Handle HIPAA compliant logging
  void logHipaaEvent(
    String event, {
    String? userId,
    String? familyId,
    Map<String, dynamic>? metadata,
  }) {
    final logData = {
      'event': event,
      'timestamp': DateTime.now().toIso8601String(),
      'user_id': userId,
      'family_id': familyId,
      if (metadata != null) 'metadata': metadata,
    };

    _logger.info('HIPAA Event: $event', logData);
    
    // In production, send to HIPAA-compliant audit logging service
    if (!kDebugMode) {
      _sendToAuditLog(logData);
    }
  }

  /// Send to HIPAA-compliant audit logging
  void _sendToAuditLog(Map<String, dynamic> logData) {
    // TODO: Implement HIPAA-compliant audit logging
    debugPrint('Would send to audit log: $logData');
  }
}

/// Application error types
enum ErrorType {
  network,
  timeout,
  authentication,
  permission,
  validation,
  notFound,
  server,
  storage,
  unknown,
}

/// Standardized application error class
class AppError implements Exception {
  final ErrorType type;
  final String message;
  final String userMessage;
  final Object? originalError;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? context;

  const AppError({
    required this.type,
    required this.message,
    required this.userMessage,
    this.originalError,
    this.stackTrace,
    this.context,
  });

  AppError copyWith({
    ErrorType? type,
    String? message,
    String? userMessage,
    Object? originalError,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    return AppError(
      type: type ?? this.type,
      message: message ?? this.message,
      userMessage: userMessage ?? this.userMessage,
      originalError: originalError ?? this.originalError,
      stackTrace: stackTrace ?? this.stackTrace,
      context: context ?? this.context,
    );
  }

  @override
  String toString() {
    return 'AppError{type: $type, message: $message, userMessage: $userMessage}';
  }

  /// Check if error is recoverable
  bool get isRecoverable {
    switch (type) {
      case ErrorType.network:
      case ErrorType.timeout:
      case ErrorType.server:
        return true;
      case ErrorType.authentication:
      case ErrorType.permission:
      case ErrorType.validation:
      case ErrorType.notFound:
      case ErrorType.storage:
      case ErrorType.unknown:
        return false;
    }
  }

  /// Get retry delay for recoverable errors
  Duration get retryDelay {
    switch (type) {
      case ErrorType.network:
        return const Duration(seconds: 5);
      case ErrorType.timeout:
        return const Duration(seconds: 3);
      case ErrorType.server:
        return const Duration(seconds: 10);
      default:
        return Duration.zero;
    }
  }
}

/// Error result wrapper for operations
class Result<T> {
  final T? data;
  final AppError? error;

  const Result._({this.data, this.error});

  factory Result.success(T data) => Result._(data: data);
  factory Result.failure(AppError error) => Result._(error: error);

  bool get isSuccess => error == null && data != null;
  bool get isFailure => error != null;

  /// Get data or throw error
  T get value {
    if (isFailure) throw error!;
    return data!;
  }

  /// Get data or return default
  T getOrElse(T defaultValue) => data ?? defaultValue;

  /// Transform success data
  Result<R> map<R>(R Function(T) transform) {
    if (isFailure) return Result.failure(error!);
    return Result.success(transform(data!));
  }

  /// Chain operations
  Result<R> flatMap<R>(Result<R> Function(T) transform) {
    if (isFailure) return Result.failure(error!);
    return transform(data!);
  }

  /// Handle both success and failure
  R fold<R>(
    R Function(AppError) onFailure,
    R Function(T) onSuccess,
  ) {
    return isFailure ? onFailure(error!) : onSuccess(data!);
  }
}

/// Mixin for consistent error handling in services
mixin ErrorHandlerMixin {
  /// Wrap service operations with error handling
  Future<Result<T>> handleOperation<T>(
    Future<T> Function() operation, {
    String? context,
  }) async {
    try {
      final result = await operation();
      return Result.success(result);
    } catch (error, stackTrace) {
      final appError = ErrorService.instance.handleServiceError(
        context ?? runtimeType.toString(),
        error,
      );
      
      ErrorService.instance.logError(
        'Operation failed in ${context ?? runtimeType.toString()}',
        error: error,
        stackTrace: stackTrace,
      );
      
      return Result.failure(appError);
    }
  }

  /// Wrap synchronous operations
  Result<T> handleSync<T>(
    T Function() operation, {
    String? context,
  }) {
    try {
      final result = operation();
      return Result.success(result);
    } catch (error, stackTrace) {
      final appError = ErrorService.instance.handleServiceError(
        context ?? runtimeType.toString(),
        error,
      );
      
      ErrorService.instance.logError(
        'Sync operation failed in ${context ?? runtimeType.toString()}',
        error: error,
        stackTrace: stackTrace,
      );
      
      return Result.failure(appError);
    }
  }
}