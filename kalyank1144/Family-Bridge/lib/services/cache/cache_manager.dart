import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import 'package:cached_network_image/cached_network_image.dart';

enum CacheType {
  image,
  audio,
  video,
  document,
  data,
  temporary,
}

class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  final Logger _logger = Logger();
  
  // Storage limits in MB
  static const int _maxCacheSize = 500;
  static const int _maxMediaCache = 200;
  static const int _maxDataCache = 100;
  static const int _maxTempCache = 50;
  
  // Per-user allocation
  static const int _perUserAllocation = 100;
  
  late Directory _cacheDirectory;
  late Directory _mediaDirectory;
  late Directory _dataDirectory;
  late Directory _tempDirectory;
  
  late Box _cacheMetadata;
  
  final Map<String, CacheEntry> _memoryCache = {};
  Timer? _cleanupTimer;
  
  Future<void> initialize() async {
    // Get cache directories
    final appDir = await getApplicationDocumentsDirectory();
    _cacheDirectory = Directory('${appDir.path}/cache');
    _mediaDirectory = Directory('${appDir.path}/cache/media');
    _dataDirectory = Directory('${appDir.path}/cache/data');
    _tempDirectory = Directory('${appDir.path}/cache/temp');
    
    // Create directories if they don't exist
    await _cacheDirectory.create(recursive: true);
    await _mediaDirectory.create(recursive: true);
    await _dataDirectory.create(recursive: true);
    await _tempDirectory.create(recursive: true);
    
    // Open metadata box
    _cacheMetadata = await Hive.openBox('cache_metadata');
    
    // Start periodic cleanup
    _startPeriodicCleanup();
    
    // Initial cleanup
    await _performCleanup();
    
    _logger.i('CacheManager initialized');
  }
  
  void _startPeriodicCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(hours: 6), (_) {
      _performCleanup();
    });
  }
  
  Future<void> _performCleanup() async {
    try {
      _logger.d('Starting cache cleanup');
      
      // Check total cache size
      final totalSize = await _calculateCacheSize();
      
      if (totalSize > _maxCacheSize * 1024 * 1024) {
        _logger.w('Cache size exceeded: ${totalSize ~/ (1024 * 1024)} MB');
        await _evictOldestFiles();
      }
      
      // Clean temporary files older than 24 hours
      await _cleanTempFiles();
      
      // Clean expired entries
      await _cleanExpiredEntries();
      
      // Update memory cache
      _cleanMemoryCache();
      
      _logger.d('Cache cleanup completed');
      
    } catch (e) {
      _logger.e('Cache cleanup failed', error: e);
    }
  }
  
  Future<int> _calculateCacheSize() async {
    int totalSize = 0;
    
    await for (final entity in _cacheDirectory.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
    
    return totalSize;
  }
  
  Future<void> _evictOldestFiles() async {
    final files = <FileSystemEntity>[];
    
    await for (final entity in _mediaDirectory.list(recursive: true)) {
      if (entity is File) {
        files.add(entity);
      }
    }
    
    // Sort by last accessed time (LRU)
    files.sort((a, b) {
      final aStats = (a as File).statSync();
      final bStats = (b as File).statSync();
      return aStats.accessed.compareTo(bStats.accessed);
    });
    
    // Remove oldest files until we're under the limit
    int totalSize = await _calculateCacheSize();
    final targetSize = (_maxCacheSize * 0.8 * 1024 * 1024).toInt(); // 80% of max
    
    for (final file in files) {
      if (totalSize <= targetSize) break;
      
      final fileSize = await (file as File).length();
      await file.delete();
      totalSize -= fileSize;
      
      // Remove from metadata
      final key = _getKeyFromPath(file.path);
      if (key != null) {
        await _cacheMetadata.delete(key);
      }
      
      _logger.d('Evicted: ${file.path}');
    }
  }
  
  Future<void> _cleanTempFiles() async {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(hours: 24));
    
    await for (final entity in _tempDirectory.list()) {
      if (entity is File) {
        final stats = await entity.stat();
        if (stats.modified.isBefore(cutoff)) {
          await entity.delete();
          _logger.d('Deleted temp file: ${entity.path}');
        }
      }
    }
  }
  
  Future<void> _cleanExpiredEntries() async {
    final now = DateTime.now();
    final keysToDelete = <String>[];
    
    for (final key in _cacheMetadata.keys) {
      final metadata = _cacheMetadata.get(key);
      if (metadata is Map && metadata['expiry'] != null) {
        final expiry = DateTime.parse(metadata['expiry']);
        if (expiry.isBefore(now)) {
          keysToDelete.add(key as String);
        }
      }
    }
    
    for (final key in keysToDelete) {
      await _cacheMetadata.delete(key);
      // Delete associated file
      final path = _cacheMetadata.get(key)?['path'];
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
    }
    
    if (keysToDelete.isNotEmpty) {
      _logger.d('Cleaned ${keysToDelete.length} expired entries');
    }
  }
  
  void _cleanMemoryCache() {
    // Keep only last 100 items in memory
    if (_memoryCache.length > 100) {
      final entries = _memoryCache.entries.toList();
      entries.sort((a, b) => 
          a.value.lastAccessed.compareTo(b.value.lastAccessed));
      
      final toRemove = entries.take(entries.length - 100);
      for (final entry in toRemove) {
        _memoryCache.remove(entry.key);
      }
    }
  }
  
  String? _getKeyFromPath(String path) {
    // Extract cache key from file path
    final filename = path.split('/').last;
    return filename.split('.').first;
  }
  
  Future<String?> cacheFile({
    required String key,
    required String url,
    required CacheType type,
    Duration? maxAge,
    bool forceRefresh = false,
  }) async {
    try {
      // Check memory cache first
      if (!forceRefresh && _memoryCache.containsKey(key)) {
        final entry = _memoryCache[key]!;
        entry.lastAccessed = DateTime.now();
        return entry.path;
      }
      
      // Check disk cache
      if (!forceRefresh) {
        final cachedPath = await _getCachedFile(key);
        if (cachedPath != null) {
          _memoryCache[key] = CacheEntry(
            key: key,
            path: cachedPath,
            type: type,
            lastAccessed: DateTime.now(),
          );
          return cachedPath;
        }
      }
      
      // Download and cache
      final directory = _getDirectoryForType(type);
      final extension = _getExtensionFromUrl(url);
      final filePath = '${directory.path}/$key$extension';
      
      // Download file (implementation would use Dio or similar)
      // For now, this is a placeholder
      // await _downloadFile(url, filePath);
      
      // Save metadata
      await _cacheMetadata.put(key, {
        'path': filePath,
        'url': url,
        'type': type.toString(),
        'cached': DateTime.now().toIso8601String(),
        'expiry': maxAge != null 
            ? DateTime.now().add(maxAge).toIso8601String() 
            : null,
      });
      
      // Add to memory cache
      _memoryCache[key] = CacheEntry(
        key: key,
        path: filePath,
        type: type,
        lastAccessed: DateTime.now(),
      );
      
      _logger.d('Cached file: $key -> $filePath');
      return filePath;
      
    } catch (e) {
      _logger.e('Failed to cache file: $key', error: e);
      return null;
    }
  }
  
  Future<String?> _getCachedFile(String key) async {
    final metadata = _cacheMetadata.get(key);
    if (metadata == null) return null;
    
    final path = metadata['path'];
    if (path == null) return null;
    
    final file = File(path);
    if (!await file.exists()) {
      await _cacheMetadata.delete(key);
      return null;
    }
    
    // Check expiry
    if (metadata['expiry'] != null) {
      final expiry = DateTime.parse(metadata['expiry']);
      if (expiry.isBefore(DateTime.now())) {
        await file.delete();
        await _cacheMetadata.delete(key);
        return null;
      }
    }
    
    // Update last accessed time
    await file.setLastAccessed(DateTime.now());
    
    return path;
  }
  
  Directory _getDirectoryForType(CacheType type) {
    switch (type) {
      case CacheType.image:
      case CacheType.audio:
      case CacheType.video:
        return _mediaDirectory;
      case CacheType.document:
      case CacheType.data:
        return _dataDirectory;
      case CacheType.temporary:
        return _tempDirectory;
    }
  }
  
  String _getExtensionFromUrl(String url) {
    final uri = Uri.parse(url);
    final path = uri.path;
    if (path.contains('.')) {
      return '.${path.split('.').last}';
    }
    return '';
  }
  
  Future<void> preloadData({
    required String userId,
    required List<String> urls,
    CacheType type = CacheType.data,
  }) async {
    _logger.i('Preloading ${urls.length} items for user $userId');
    
    for (final url in urls) {
      final key = '${userId}_${url.hashCode}';
      await cacheFile(
        key: key,
        url: url,
        type: type,
        maxAge: const Duration(days: 7),
      );
    }
  }
  
  Future<void> clearUserCache(String userId) async {
    final keysToDelete = <String>[];
    
    for (final key in _cacheMetadata.keys) {
      if ((key as String).startsWith(userId)) {
        keysToDelete.add(key);
      }
    }
    
    for (final key in keysToDelete) {
      final metadata = _cacheMetadata.get(key);
      if (metadata != null && metadata['path'] != null) {
        final file = File(metadata['path']);
        if (await file.exists()) {
          await file.delete();
        }
      }
      await _cacheMetadata.delete(key);
    }
    
    _logger.i('Cleared cache for user $userId: ${keysToDelete.length} items');
  }
  
  Future<Map<String, dynamic>> getCacheStatistics() async {
    final totalSize = await _calculateCacheSize();
    final mediaSize = await _calculateDirectorySize(_mediaDirectory);
    final dataSize = await _calculateDirectorySize(_dataDirectory);
    final tempSize = await _calculateDirectorySize(_tempDirectory);
    
    int fileCount = 0;
    await for (final _ in _cacheDirectory.list(recursive: true)) {
      fileCount++;
    }
    
    return {
      'totalSize': '${totalSize ~/ (1024 * 1024)} MB',
      'mediaSize': '${mediaSize ~/ (1024 * 1024)} MB',
      'dataSize': '${dataSize ~/ (1024 * 1024)} MB',
      'tempSize': '${tempSize ~/ (1024 * 1024)} MB',
      'fileCount': fileCount,
      'metadataEntries': _cacheMetadata.length,
      'memoryCacheEntries': _memoryCache.length,
      'maxSize': '$_maxCacheSize MB',
      'usage': '${(totalSize / (_maxCacheSize * 1024 * 1024) * 100).toStringAsFixed(1)}%',
    };
  }
  
  Future<int> _calculateDirectorySize(Directory dir) async {
    int size = 0;
    
    if (await dir.exists()) {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          size += await entity.length();
        }
      }
    }
    
    return size;
  }
  
  Future<void> clearAll() async {
    await _cacheDirectory.delete(recursive: true);
    await _cacheDirectory.create(recursive: true);
    await _mediaDirectory.create(recursive: true);
    await _dataDirectory.create(recursive: true);
    await _tempDirectory.create(recursive: true);
    
    await _cacheMetadata.clear();
    _memoryCache.clear();
    
    _logger.i('All cache cleared');
  }
  
  Future<void> clearOldData({Duration maxAge = const Duration(days: 30)}) async {
    final cutoff = DateTime.now().subtract(maxAge);
    final keysToDelete = <String>[];
    
    for (final key in _cacheMetadata.keys) {
      final metadata = _cacheMetadata.get(key);
      if (metadata is Map && metadata['cached'] != null) {
        final cached = DateTime.parse(metadata['cached']);
        if (cached.isBefore(cutoff)) {
          keysToDelete.add(key as String);
        }
      }
    }
    
    for (final key in keysToDelete) {
      final metadata = _cacheMetadata.get(key);
      if (metadata != null && metadata['path'] != null) {
        final file = File(metadata['path']);
        if (await file.exists()) {
          await file.delete();
        }
      }
      await _cacheMetadata.delete(key);
    }
    
    _logger.i('Cleared ${keysToDelete.length} old cache entries');
  }
  
  void dispose() {
    _cleanupTimer?.cancel();
  }
}

class CacheEntry {
  final String key;
  final String path;
  final CacheType type;
  DateTime lastAccessed;
  
  CacheEntry({
    required this.key,
    required this.path,
    required this.type,
    required this.lastAccessed,
  });
}