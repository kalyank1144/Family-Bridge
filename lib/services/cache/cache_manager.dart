class CacheEntry<T> {
  final T value;
  final DateTime insertedAt;
  final Duration ttl;

  CacheEntry({required this.value, required this.ttl}) : insertedAt = DateTime.now();

  bool get isFresh => DateTime.now().difference(insertedAt) < ttl;
}

class CacheManager {
  CacheManager._internal();
  static final CacheManager instance = CacheManager._internal();

  final Map<String, CacheEntry<dynamic>> _cache = {};

  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (!entry.isFresh) return null;
    return entry.value as T;
  }

  void set<T>(String key, T value, {Duration ttl = const Duration(minutes: 5)}) {
    _cache[key] = CacheEntry<T>(value: value, ttl: ttl);
  }

  void invalidate(String key) => _cache.remove(key);
  void invalidateWhere(bool Function(String key) test) {
    final keys = _cache.keys.where(test).toList();
    for (final k in keys) {
      _cache.remove(k);
    }
  }

  void clear() => _cache.clear();
}
