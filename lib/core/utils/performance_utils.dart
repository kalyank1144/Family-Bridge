import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Performance optimization utilities for the FamilyBridge app
class PerformanceUtils {
  /// Debounce function calls to prevent excessive operations
  static Timer? _debounceTimer;
  
  static void debounce(Duration delay, VoidCallback callback) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, callback);
  }

  /// Throttle function calls to limit frequency
  static DateTime? _lastThrottleTime;
  
  static bool throttle(Duration interval, VoidCallback callback) {
    final now = DateTime.now();
    
    if (_lastThrottleTime == null || 
        now.difference(_lastThrottleTime!) >= interval) {
      _lastThrottleTime = now;
      callback();
      return true;
    }
    
    return false;
  }

  /// Check if two objects are deeply equal to prevent unnecessary rebuilds
  static bool deepEquals(dynamic a, dynamic b) {
    if (identical(a, b)) return true;
    if (a.runtimeType != b.runtimeType) return false;
    
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (!deepEquals(a[i], b[i])) return false;
      }
      return true;
    }
    
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key) || !deepEquals(a[key], b[key])) {
          return false;
        }
      }
      return true;
    }
    
    return a == b;
  }

  /// Memoization cache for expensive computations
  static final Map<String, dynamic> _memoCache = {};
  
  static T memoize<T>(String key, T Function() computation) {
    if (_memoCache.containsKey(key)) {
      return _memoCache[key] as T;
    }
    
    final result = computation();
    _memoCache[key] = result;
    return result;
  }

  /// Clear memoization cache
  static void clearMemoCache() {
    _memoCache.clear();
  }

  /// Clear specific memoization entry
  static void clearMemoEntry(String key) {
    _memoCache.remove(key);
  }

  /// Measure and log performance of operations in debug mode
  static Future<T> measureAsync<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    if (!kDebugMode) return operation();
    
    final stopwatch = Stopwatch()..start();
    final result = await operation();
    stopwatch.stop();
    
    debugPrint('Performance: $operationName took ${stopwatch.elapsedMilliseconds}ms');
    
    if (stopwatch.elapsedMilliseconds > 100) {
      debugPrint('⚠️ Slow operation detected: $operationName');
    }
    
    return result;
  }

  /// Measure synchronous operations
  static T measureSync<T>(
    String operationName,
    T Function() operation,
  ) {
    if (!kDebugMode) return operation();
    
    final stopwatch = Stopwatch()..start();
    final result = operation();
    stopwatch.stop();
    
    debugPrint('Performance: $operationName took ${stopwatch.elapsedMilliseconds}ms');
    
    if (stopwatch.elapsedMilliseconds > 50) {
      debugPrint('⚠️ Slow sync operation detected: $operationName');
    }
    
    return result;
  }
}

/// Timer import helper
class Timer {
  Timer(Duration duration, VoidCallback callback) {
    Future.delayed(duration, callback);
  }
  
  void cancel() {
    // No-op for simple implementation
  }
}

/// Optimized provider mixin to reduce rebuilds
mixin OptimizedChangeNotifier on ChangeNotifier {
  bool _isDisposed = false;
  DateTime? _lastNotifyTime;
  
  /// Debounced notifyListeners to prevent excessive rebuilds
  void notifyListenersDebounced([Duration delay = const Duration(milliseconds: 16)]) {
    if (_isDisposed) return;
    
    PerformanceUtils.debounce(delay, () {
      if (!_isDisposed) {
        notifyListeners();
      }
    });
  }

  /// Throttled notifyListeners
  void notifyListenersThrottled([Duration interval = const Duration(milliseconds: 100)]) {
    if (_isDisposed) return;
    
    PerformanceUtils.throttle(interval, () {
      if (!_isDisposed) {
        notifyListeners();
      }
    });
  }

  /// Conditional notifyListeners to prevent unnecessary updates
  void notifyListenersIf(bool condition) {
    if (_isDisposed) return;
    
    if (condition) {
      notifyListeners();
    }
  }

  /// Batch multiple updates together
  void batchUpdates(VoidCallback updates) {
    if (_isDisposed) return;
    
    updates();
    notifyListenersDebounced();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  bool get isDisposed => _isDisposed;
}

/// Widget optimization helpers
class OptimizedWidgets {
  /// Conditional wrapper that only rebuilds when condition changes
  static Widget conditionalBuilder({
    required bool condition,
    required Widget Function() builder,
    Widget? fallback,
  }) {
    return condition ? builder() : (fallback ?? const SizedBox.shrink());
  }

  /// Memoized builder that caches results
  static Widget memoizedBuilder({
    required String cacheKey,
    required List<Object?> dependencies,
    required Widget Function() builder,
  }) {
    final depsString = dependencies.map((d) => d.hashCode).join('_');
    final fullKey = '${cacheKey}_$depsString';
    
    return PerformanceUtils.memoize(fullKey, builder);
  }

  /// Sliver that only rebuilds when needed
  static Widget optimizedSliverList({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    bool Function(int, int)? itemComparator,
  }) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        itemBuilder,
        childCount: itemCount,
        findChildIndexCallback: itemComparator != null
            ? (Key key) {
                if (key is ValueKey<int>) {
                  return key.value < itemCount ? key.value : null;
                }
                return null;
              }
            : null,
      ),
    );
  }
}

/// Performance monitoring widget
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final String name;
  final bool enabled;

  const PerformanceMonitor({
    super.key,
    required this.child,
    required this.name,
    this.enabled = kDebugMode,
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  int _buildCount = 0;
  DateTime? _lastBuildTime;

  @override
  Widget build(BuildContext context) {
    if (widget.enabled) {
      _buildCount++;
      final now = DateTime.now();
      
      if (_lastBuildTime != null) {
        final timeSinceLastBuild = now.difference(_lastBuildTime!);
        if (timeSinceLastBuild.inMilliseconds < 16) {
          debugPrint('⚠️ Rapid rebuild detected in ${widget.name}: $timeSinceLastBuild');
        }
      }
      
      _lastBuildTime = now;
      
      if (_buildCount > 10) {
        debugPrint('⚠️ Excessive rebuilds in ${widget.name}: $_buildCount builds');
      }
    }

    return widget.child;
  }
}

/// Efficient list item builder with automatic optimization
class OptimizedListItem extends StatelessWidget {
  final int index;
  final Widget child;
  final bool Function()? shouldRebuild;

  const OptimizedListItem({
    super.key,
    required this.index,
    required this.child,
    this.shouldRebuild,
  });

  @override
  Widget build(BuildContext context) {
    if (shouldRebuild?.call() == false) {
      return RepaintBoundary(
        child: child,
      );
    }

    return RepaintBoundary(
      key: ValueKey(index),
      child: child,
    );
  }
}

/// Memory-efficient image cache
class OptimizedImageCache {
  static const int maxCacheSize = 50;
  static final Map<String, ImageProvider> _cache = {};
  static final List<String> _accessOrder = [];

  static ImageProvider getImage(String url) {
    if (_cache.containsKey(url)) {
      // Move to end of access order
      _accessOrder.remove(url);
      _accessOrder.add(url);
      return _cache[url]!;
    }

    final imageProvider = NetworkImage(url);
    
    // Add to cache
    if (_cache.length >= maxCacheSize) {
      // Remove least recently used
      final oldestKey = _accessOrder.removeAt(0);
      _cache.remove(oldestKey);
    }
    
    _cache[url] = imageProvider;
    _accessOrder.add(url);
    
    return imageProvider;
  }

  static void clearCache() {
    _cache.clear();
    _accessOrder.clear();
  }

  static void preloadImages(List<String> urls) {
    for (final url in urls) {
      if (!_cache.containsKey(url)) {
        getImage(url);
      }
    }
  }
}