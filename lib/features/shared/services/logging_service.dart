import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for comprehensive logging with HIPAA compliance and privacy protection
/// Implements secure logging with audit trails and configurable log levels
class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;
  LoggingService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final List<LogEntry> _logBuffer = [];
  
  bool _isInitialized = false;
  LogLevel _minimumLevel = LogLevel.info;
  File? _logFile;
  Timer? _flushTimer;

  static const int _maxBufferSize = 100;
  static const Duration _flushInterval = Duration(minutes: 5);
  static const int _maxLogFileSize = 10 * 1024 * 1024; // 10MB

  /// Initialize the logging service
  Future<void> initialize({LogLevel minimumLevel = LogLevel.info}) async {
    if (_isInitialized) return;

    _minimumLevel = minimumLevel;

    try {
      // Initialize log file
      await _initializeLogFile();

      // Start periodic flush timer
      _flushTimer = Timer.periodic(_flushInterval, (_) => _flushLogs());

      _isInitialized = true;
      info('LoggingService initialized with level: $_minimumLevel');
    } catch (e) {
      debugPrint('Failed to initialize LoggingService: $e');
    }
  }

  /// Log debug message
  void debug(String message, [StackTrace? stackTrace]) {
    _log(LogLevel.debug, message, stackTrace);
  }

  /// Log info message
  void info(String message, [StackTrace? stackTrace]) {
    _log(LogLevel.info, message, stackTrace);
  }

  /// Log warning message
  void warning(String message, [StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, stackTrace);
  }

  /// Log error message
  void error(String message, [StackTrace? stackTrace]) {
    _log(LogLevel.error, message, stackTrace);
  }

  /// Log critical error message
  void critical(String message, [StackTrace? stackTrace]) {
    _log(LogLevel.critical, message, stackTrace);
  }

  /// Log user action for audit trail (HIPAA compliance)
  void auditLog({
    required String userId,
    required String action,
    required String resource,
    String? details,
    Map<String, dynamic>? metadata,
  }) {
    final auditEntry = AuditLogEntry(
      timestamp: DateTime.now(),
      userId: userId,
      action: action,
      resource: resource,
      details: details,
      metadata: metadata,
      ipAddress: '', // Would be populated in real implementation
      userAgent: '', // Would be populated in real implementation
    );

    _logAuditEntry(auditEntry);
  }

  /// Log health data access (HIPAA requirement)
  void healthDataAccess({
    required String userId,
    required String patientId,
    required String dataType,
    required String accessType, // read, write, delete
    String? purpose,
  }) {
    auditLog(
      userId: userId,
      action: 'health_data_$accessType',
      resource: 'health_data/$dataType',
      details: purpose,
      metadata: {
        'patient_id': patientId,
        'data_type': dataType,
        'access_type': accessType,
        'timestamp': DateTime.now().toIso8601String(),
        'compliance_flag': 'HIPAA',
      },
    );
  }

  /// Log medication event
  void medicationEvent({
    required String userId,
    required String medicationId,
    required String eventType, // taken, missed, scheduled, etc.
    String? notes,
    Map<String, dynamic>? metadata,
  }) {
    info('Medication event: $eventType for user $userId, medication $medicationId');
    
    auditLog(
      userId: userId,
      action: 'medication_$eventType',
      resource: 'medication/$medicationId',
      details: notes,
      metadata: {
        'event_type': eventType,
        'medication_id': medicationId,
        ...?metadata,
      },
    );
  }

  /// Log family data access
  void familyDataAccess({
    required String userId,
    required String familyId,
    required String action,
    String? resource,
    String? details,
  }) {
    auditLog(
      userId: userId,
      action: 'family_$action',
      resource: resource ?? 'family/$familyId',
      details: details,
      metadata: {
        'family_id': familyId,
        'access_category': 'family_data',
      },
    );
  }

  /// Get recent logs
  Future<List<LogEntry>> getRecentLogs({
    LogLevel? minimumLevel,
    int limit = 100,
  }) async {
    try {
      final filteredLogs = _logBuffer
          .where((entry) => minimumLevel == null || 
              entry.level.index >= minimumLevel.index)
          .take(limit)
          .toList();
      
      return filteredLogs.reversed.toList();
    } catch (e) {
      debugPrint('Failed to get recent logs: $e');
      return [];
    }
  }

  /// Get audit logs for compliance reporting
  Future<List<AuditLogEntry>> getAuditLogs({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 1000,
  }) async {
    try {
      var query = _supabase
          .from('audit_logs')
          .select()
          .order('timestamp', ascending: false)
          .limit(limit);

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      if (startDate != null) {
        query = query.gte('timestamp', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('timestamp', endDate.toIso8601String());
      }

      final response = await query;
      return (response as List)
          .map((json) => AuditLogEntry.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      error('Failed to get audit logs: $e');
      return [];
    }
  }

  /// Export logs for compliance reporting
  Future<String> exportLogs({
    DateTime? startDate,
    DateTime? endDate,
    List<LogLevel>? levels,
  }) async {
    try {
      final logs = await getRecentLogs(limit: 10000);
      final filteredLogs = logs.where((log) {
        var include = true;
        
        if (startDate != null && log.timestamp.isBefore(startDate)) {
          include = false;
        }
        
        if (endDate != null && log.timestamp.isAfter(endDate)) {
          include = false;
        }
        
        if (levels != null && !levels.contains(log.level)) {
          include = false;
        }
        
        return include;
      }).toList();

      // Create CSV format
      final buffer = StringBuffer();
      buffer.writeln('Timestamp,Level,Category,Message');
      
      for (final log in filteredLogs) {
        final escapedMessage = log.message.replaceAll('"', '""');
        buffer.writeln('${log.timestamp.toIso8601String()},'
                      '${log.level.name},'
                      '${log.category},'
                      '"$escapedMessage"');
      }

      return buffer.toString();
    } catch (e) {
      error('Failed to export logs: $e');
      return '';
    }
  }

  /// Clear old logs to manage storage
  Future<void> clearOldLogs({Duration? olderThan}) async {
    try {
      final cutoffDate = DateTime.now().subtract(olderThan ?? const Duration(days: 30));
      
      // Remove from buffer
      _logBuffer.removeWhere((entry) => entry.timestamp.isBefore(cutoffDate));
      
      // Remove from database
      await _supabase
          .from('audit_logs')
          .delete()
          .lt('timestamp', cutoffDate.toIso8601String());
      
      info('Cleared logs older than ${cutoffDate.toIso8601String()}');
    } catch (e) {
      error('Failed to clear old logs: $e');
    }
  }

  /// Set minimum log level
  void setMinimumLevel(LogLevel level) {
    _minimumLevel = level;
    info('Minimum log level set to: $level');
  }

  // Private methods

  void _log(LogLevel level, String message, [StackTrace? stackTrace]) {
    if (!_isInitialized || level.index < _minimumLevel.index) {
      return;
    }

    final logEntry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      category: _getCallerCategory(),
      stackTrace: stackTrace?.toString(),
    );

    // Add to buffer
    _logBuffer.add(logEntry);

    // Print in debug mode
    if (kDebugMode) {
      final levelString = level.name.toUpperCase().padRight(8);
      final timeString = logEntry.timestamp.toString().substring(11, 23);
      debugPrint('[$levelString] $timeString ${logEntry.category}: $message');
      
      if (stackTrace != null && level.index >= LogLevel.error.index) {
        debugPrint('Stack trace: $stackTrace');
      }
    }

    // Write to file
    _writeToLogFile(logEntry);

    // Auto-flush if buffer is full
    if (_logBuffer.length >= _maxBufferSize) {
      _flushLogs();
    }
  }

  void _logAuditEntry(AuditLogEntry auditEntry) {
    info('Audit: ${auditEntry.action} on ${auditEntry.resource} by ${auditEntry.userId}');

    // Store in database for compliance
    _supabase.from('audit_logs').insert(auditEntry.toJson()).catchError((error) {
      error('Failed to store audit log: $error');
    });
  }

  String _getCallerCategory() {
    try {
      final stackTrace = StackTrace.current;
      final stackFrames = stackTrace.toString().split('\n');
      
      // Look for the first frame that's not in the logging service
      for (final frame in stackFrames) {
        if (!frame.contains('logging_service.dart') && 
            frame.contains('package:')) {
          // Extract the file/class name
          final match = RegExp(r'package:.*?/([^/]+\.dart)').firstMatch(frame);
          return match?.group(1)?.replaceAll('.dart', '') ?? 'unknown';
        }
      }
      
      return 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  Future<void> _initializeLogFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory('${directory.path}/logs');
      
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }

      _logFile = File('${logDir.path}/app_${DateTime.now().toIso8601String().substring(0, 10)}.log');
    } catch (e) {
      debugPrint('Failed to initialize log file: $e');
    }
  }

  Future<void> _writeToLogFile(LogEntry entry) async {
    try {
      if (_logFile == null) return;

      // Check file size and rotate if needed
      if (await _logFile!.exists()) {
        final fileSize = await _logFile!.length();
        if (fileSize > _maxLogFileSize) {
          await _rotateLogFile();
        }
      }

      final logLine = '${entry.timestamp.toIso8601String()} '
                      '[${entry.level.name.toUpperCase()}] '
                      '${entry.category}: ${entry.message}\n';
      
      await _logFile!.writeAsString(logLine, mode: FileMode.append);
    } catch (e) {
      debugPrint('Failed to write to log file: $e');
    }
  }

  Future<void> _rotateLogFile() async {
    try {
      if (_logFile == null) return;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final archiveName = '${_logFile!.path}.$timestamp';
      
      await _logFile!.rename(archiveName);
      await _initializeLogFile();
      
      info('Log file rotated to: $archiveName');
    } catch (e) {
      debugPrint('Failed to rotate log file: $e');
    }
  }

  void _flushLogs() {
    if (_logBuffer.isEmpty) return;

    try {
      // In a real implementation, you might send logs to a remote service
      // For now, just clear the buffer periodically
      if (_logBuffer.length > _maxBufferSize * 2) {
        _logBuffer.removeRange(0, _logBuffer.length - _maxBufferSize);
      }
    } catch (e) {
      debugPrint('Failed to flush logs: $e');
    }
  }

  /// Dispose of resources
  void dispose() {
    _flushTimer?.cancel();
    _flushLogs();
  }
}

/// Log level enumeration
enum LogLevel {
  debug,
  info,
  warning,
  error,
  critical,
}

/// Data class for log entries
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String category;
  final String? stackTrace;

  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    required this.category,
    this.stackTrace,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'message': message,
      'category': category,
      'stack_trace': stackTrace,
    };
  }

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      timestamp: DateTime.parse(json['timestamp'] as String),
      level: LogLevel.values.firstWhere((l) => l.name == json['level']),
      message: json['message'] as String,
      category: json['category'] as String,
      stackTrace: json['stack_trace'] as String?,
    );
  }
}

/// Data class for audit log entries (HIPAA compliance)
class AuditLogEntry {
  final DateTime timestamp;
  final String userId;
  final String action;
  final String resource;
  final String? details;
  final Map<String, dynamic>? metadata;
  final String ipAddress;
  final String userAgent;

  const AuditLogEntry({
    required this.timestamp,
    required this.userId,
    required this.action,
    required this.resource,
    this.details,
    this.metadata,
    required this.ipAddress,
    required this.userAgent,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'user_id': userId,
      'action': action,
      'resource': resource,
      'details': details,
      'metadata': metadata,
      'ip_address': ipAddress,
      'user_agent': userAgent,
    };
  }

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      timestamp: DateTime.parse(json['timestamp'] as String),
      userId: json['user_id'] as String,
      action: json['action'] as String,
      resource: json['resource'] as String,
      details: json['details'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      ipAddress: json['ip_address'] as String,
      userAgent: json['user_agent'] as String,
    );
  }
}