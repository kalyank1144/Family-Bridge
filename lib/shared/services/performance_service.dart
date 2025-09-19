import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../core/config/env_config.dart';
import 'analytics_service.dart';

/// Service for monitoring app performance and health
class PerformanceService {
  static PerformanceService? _instance;
  
  factory PerformanceService() {
    _instance ??= PerformanceService._internal();
    return _instance!;
  }
  
  PerformanceService._internal();
  
  Timer? _memoryTimer;
  final Map<String, DateTime> _operationStartTimes = {};
  final List<PerformanceMetric> _metrics = [];
  
  /// Initialize performance monitoring
  void initialize() {
    if (!EnvConfig.performanceMonitoring) return;
    
    _startMemoryMonitoring();
    _setupErrorHandling();
    _logDebug('Performance monitoring initialized');
  }
  
  /// Start timing an operation
  void startOperation(String operationName) {
    if (!EnvConfig.performanceMonitoring) return;
    
    _operationStartTimes[operationName] = DateTime.now();
    _logDebug('Started operation: $operationName');
  }
  
  /// End timing an operation and record the duration
  void endOperation(String operationName) {
    if (!EnvConfig.performanceMonitoring) return;
    
    final startTime = _operationStartTimes.remove(operationName);
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      _recordMetric(
        PerformanceMetric(
          name: operationName,
          value: duration.inMilliseconds.toDouble(),
          unit: 'ms',
          timestamp: DateTime.now(),
        ),
      );
      
      _logDebug('Completed operation: $operationName in ${duration.inMilliseconds}ms');
    }
  }
  
  /// Time a future operation
  Future<T> timeOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    if (!EnvConfig.performanceMonitoring) {
      return await operation();
    }
    
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await operation();
      stopwatch.stop();
      
      _recordMetric(
        PerformanceMetric(
          name: operationName,
          value: stopwatch.elapsedMilliseconds.toDouble(),
          unit: 'ms',
          timestamp: DateTime.now(),
        ),
      );
      
      _logDebug('Operation $operationName completed in ${stopwatch.elapsedMilliseconds}ms');
      return result;
    } catch (e) {
      stopwatch.stop();
      
      _recordMetric(
        PerformanceMetric(
          name: '${operationName}_error',
          value: stopwatch.elapsedMilliseconds.toDouble(),
          unit: 'ms',
          timestamp: DateTime.now(),
          error: e.toString(),
        ),
      );
      
      _logDebug('Operation $operationName failed after ${stopwatch.elapsedMilliseconds}ms: $e');
      rethrow;
    }
  }
  
  /// Record custom performance metric
  void recordMetric({
    required String name,
    required double value,
    String unit = 'count',
    Map<String, String>? attributes,
  }) {
    if (!EnvConfig.performanceMonitoring) return;
    
    _recordMetric(
      PerformanceMetric(
        name: name,
        value: value,
        unit: unit,
        timestamp: DateTime.now(),
        attributes: attributes,
      ),
    );
  }
  
  /// Record network request performance
  void recordNetworkRequest({
    required String url,
    required String method,
    required int statusCode,
    required int duration,
    int? requestSize,
    int? responseSize,
  }) {
    if (!EnvConfig.performanceMonitoring) return;
    
    _recordMetric(
      PerformanceMetric(
        name: 'network_request',
        value: duration.toDouble(),
        unit: 'ms',
        timestamp: DateTime.now(),
        attributes: {
          'url': url,
          'method': method,
          'status_code': statusCode.toString(),
          if (requestSize != null) 'request_size': requestSize.toString(),
          if (responseSize != null) 'response_size': responseSize.toString(),
        },
      ),
    );
  }
  
  /// Get current memory usage
  Future<MemoryInfo?> getMemoryInfo() async {
    if (!EnvConfig.performanceMonitoring) return null;
    
    try {
      // Get memory info from platform
      const channel = MethodChannel('com.familybridge.app/performance');
      final result = await channel.invokeMethod<Map>('getMemoryInfo');
      
      if (result != null) {
        return MemoryInfo(
          totalMemory: result['totalMemory'] ?? 0,
          availableMemory: result['availableMemory'] ?? 0,
          usedMemory: result['usedMemory'] ?? 0,
        );
      }
    } catch (e) {
      _logDebug('Failed to get memory info: $e');
    }
    
    return null;
  }
  
  /// Get app performance summary
  PerformanceSummary getPerformanceSummary({Duration? period}) {
    final cutoff = period != null 
        ? DateTime.now().subtract(period)
        : DateTime.now().subtract(const Duration(hours: 1));
    
    final recentMetrics = _metrics
        .where((metric) => metric.timestamp.isAfter(cutoff))
        .toList();
    
    final operations = <String, List<PerformanceMetric>>{};
    for (final metric in recentMetrics) {
      operations.putIfAbsent(metric.name, () => []).add(metric);
    }
    
    final summaries = operations.entries.map((entry) {
      final metrics = entry.value;
      final values = metrics.map((m) => m.value).toList();
      
      values.sort();
      
      return OperationSummary(
        name: entry.key,
        count: metrics.length,
        averageDuration: values.isNotEmpty 
            ? values.reduce((a, b) => a + b) / values.length
            : 0,
        minDuration: values.isNotEmpty ? values.first : 0,
        maxDuration: values.isNotEmpty ? values.last : 0,
        p95Duration: values.isNotEmpty 
            ? values[(values.length * 0.95).floor()]
            : 0,
        errorCount: metrics.where((m) => m.error != null).length,
      );
    }).toList();
    
    return PerformanceSummary(
      period: period ?? const Duration(hours: 1),
      totalOperations: recentMetrics.length,
      operationSummaries: summaries,
      generatedAt: DateTime.now(),
    );
  }
  
  /// Export performance data
  List<Map<String, dynamic>> exportPerformanceData({Duration? period}) {
    final cutoff = period != null 
        ? DateTime.now().subtract(period)
        : DateTime.now().subtract(const Duration(hours: 24));
    
    return _metrics
        .where((metric) => metric.timestamp.isAfter(cutoff))
        .map((metric) => metric.toJson())
        .toList();
  }
  
  void _recordMetric(PerformanceMetric metric) {
    _metrics.add(metric);
    
    // Keep only recent metrics to prevent memory bloat
    if (_metrics.length > 1000) {
      _metrics.removeRange(0, _metrics.length - 1000);
    }
    
    // Send to analytics if enabled
    AnalyticsService().trackPerformance(
      metricName: metric.name,
      value: metric.value.toInt(),
      attributes: metric.attributes,
    );
  }
  
  void _startMemoryMonitoring() {
    _memoryTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      final memoryInfo = await getMemoryInfo();
      if (memoryInfo != null) {
        _recordMetric(
          PerformanceMetric(
            name: 'memory_usage',
            value: memoryInfo.usedMemory.toDouble(),
            unit: 'bytes',
            timestamp: DateTime.now(),
            attributes: {
              'total_memory': memoryInfo.totalMemory.toString(),
              'available_memory': memoryInfo.availableMemory.toString(),
            },
          ),
        );
      }
    });
  }
  
  void _setupErrorHandling() {
    FlutterError.onError = (FlutterErrorDetails details) {
      // Record Flutter errors as performance metrics
      _recordMetric(
        PerformanceMetric(
          name: 'flutter_error',
          value: 1,
          unit: 'count',
          timestamp: DateTime.now(),
          error: details.exception.toString(),
          attributes: {
            'library': details.library ?? 'unknown',
            'context': details.context?.toString() ?? 'unknown',
          },
        ),
      );
      
      // Send to crash reporting service
      AnalyticsService().trackError(
        error: details.exception.toString(),
        stackTrace: details.stack.toString(),
        additionalInfo: {
          'library': details.library,
          'context': details.context?.toString(),
        },
      );
      
      _logDebug('Flutter error recorded: ${details.exception}');
    };
  }
  
  void _logDebug(String message) {
    if (kDebugMode) {
      developer.log(message, name: 'PerformanceService');
    }
  }
  
  /// Cleanup resources
  void dispose() {
    _memoryTimer?.cancel();
    _operationStartTimes.clear();
    _metrics.clear();
    _instance = null;
  }
}

/// Performance metric data class
class PerformanceMetric {
  final String name;
  final double value;
  final String unit;
  final DateTime timestamp;
  final String? error;
  final Map<String, String>? attributes;
  
  PerformanceMetric({
    required this.name,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.error,
    this.attributes,
  });
  
  Map<String, dynamic> toJson() => {
    'name': name,
    'value': value,
    'unit': unit,
    'timestamp': timestamp.toIso8601String(),
    if (error != null) 'error': error,
    if (attributes != null) 'attributes': attributes,
  };
}

/// Memory information data class
class MemoryInfo {
  final int totalMemory;
  final int availableMemory;
  final int usedMemory;
  
  MemoryInfo({
    required this.totalMemory,
    required this.availableMemory,
    required this.usedMemory,
  });
  
  double get usagePercentage => 
      totalMemory > 0 ? (usedMemory / totalMemory) * 100 : 0;
}

/// Operation performance summary
class OperationSummary {
  final String name;
  final int count;
  final double averageDuration;
  final double minDuration;
  final double maxDuration;
  final double p95Duration;
  final int errorCount;
  
  OperationSummary({
    required this.name,
    required this.count,
    required this.averageDuration,
    required this.minDuration,
    required this.maxDuration,
    required this.p95Duration,
    required this.errorCount,
  });
  
  double get errorRate => count > 0 ? (errorCount / count) * 100 : 0;
}

/// Performance summary data class
class PerformanceSummary {
  final Duration period;
  final int totalOperations;
  final List<OperationSummary> operationSummaries;
  final DateTime generatedAt;
  
  PerformanceSummary({
    required this.period,
    required this.totalOperations,
    required this.operationSummaries,
    required this.generatedAt,
  });
}