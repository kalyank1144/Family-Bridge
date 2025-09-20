import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/offline_operation.dart';
import '../models/cached_data.dart';

class LocalStorageManager {
  static const String _userBox = 'users';
  static const String _messageBox = 'messages';
  static const String _healthBox = 'health_records';
  static const String _medicationBox = 'medications';
  static const String _operationBox = 'offline_operations';
  static const String _cacheBox = 'cache';
  static const String _configBox = 'config';
  static const String _mediaBox = 'media';
  
  late Box<dynamic> _userStorage;
  late Box<dynamic> _messageStorage;
  late Box<dynamic> _healthStorage;
  late Box<dynamic> _medicationStorage;
  late Box<dynamic> _operationStorage;
  late Box<dynamic> _cacheStorage;
  late Box<dynamic> _configStorage;
  late Box<dynamic> _mediaStorage;
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  bool _isInitialized = false;
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await Hive.initFlutter();
    
    // Register Hive adapters
    _registerAdapters();
    
    // Open Hive boxes
    _userStorage = await Hive.openBox(_userBox);
    _messageStorage = await Hive.openBox(_messageBox);
    _healthStorage = await Hive.openBox(_healthBox);
    _medicationStorage = await Hive.openBox(_medicationBox);
    _operationStorage = await Hive.openBox(_operationBox);
    _cacheStorage = await Hive.openBox(_cacheBox);
    _configStorage = await Hive.openBox(_configBox);
    _mediaStorage = await Hive.openBox(_mediaBox);
    
    _isInitialized = true;
  }
  
  void _registerAdapters() {
    // Register type adapters for custom objects
    try {
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(OfflineOperationAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(CachedDataAdapter());
      }
    } catch (e) {
      debugPrint('Adapters registration error: $e');
    }
  }
  
  // Generic data operations
  Future<void> saveData(String box, String key, Map<String, dynamic> data) async {
    switch (box) {
      case _userBox:
        await _userStorage.put(key, data);
        break;
      case _messageBox:
        await _messageStorage.put(key, data);
        break;
      case _healthBox:
        await _healthStorage.put(key, data);
        break;
      case _medicationBox:
        await _medicationStorage.put(key, data);
        break;
      default:
        await _configStorage.put('${box}_$key', data);
    }
  }
  
  Future<Map<String, dynamic>?> getData(String box, String key) async {
    dynamic data;
    switch (box) {
      case _userBox:
        data = _userStorage.get(key);
        break;
      case _messageBox:
        data = _messageStorage.get(key);
        break;
      case _healthBox:
        data = _healthStorage.get(key);
        break;
      case _medicationBox:
        data = _medicationStorage.get(key);
        break;
      default:
        data = _configStorage.get('${box}_$key');
    }
    
    if (data != null) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }
  
  Future<List<Map<String, dynamic>>> getAllData(String box) async {
    final results = <Map<String, dynamic>>[];
    Box<dynamic> targetBox;
    
    switch (box) {
      case _userBox:
        targetBox = _userStorage;
        break;
      case _messageBox:
        targetBox = _messageStorage;
        break;
      case _healthBox:
        targetBox = _healthStorage;
        break;
      case _medicationBox:
        targetBox = _medicationStorage;
        break;
      default:
        return results;
    }
    
    for (final key in targetBox.keys) {
      final data = targetBox.get(key);
      if (data != null) {
        results.add(Map<String, dynamic>.from(data));
      }
    }
    
    return results;
  }
  
  // Offline Operations Management
  Future<void> savePendingOperations(List<OfflineOperation> operations) async {
    await _operationStorage.clear();
    
    final batch = <String, Map<String, dynamic>>{};
    for (final operation in operations) {
      batch[operation.id] = operation.toJson();
    }
    await _operationStorage.putAll(batch);
  }
  
  Future<List<OfflineOperation>> getPendingOperations() async {
    final operations = <OfflineOperation>[];
    
    for (final key in _operationStorage.keys) {
      final operationData = _operationStorage.get(key);
      if (operationData != null) {
        operations.add(OfflineOperation.fromJson(
          Map<String, dynamic>.from(operationData),
        ));
      }
    }
    
    operations.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    
    return operations;
  }
  
  // Cache Management
  Future<void> cacheData(String key, CachedData data) async {
    await _cacheStorage.put(key, data.toJson());
  }
  
  Future<CachedData?> getCachedData(String key) async {
    final cachedData = _cacheStorage.get(key);
    if (cachedData != null) {
      final cached = CachedData.fromJson(Map<String, dynamic>.from(cachedData));
      
      // Check if cache is still valid
      if (cached.isValid()) {
        return cached;
      } else {
        // Remove expired cache
        await _cacheStorage.delete(key);
      }
    }
    return null;
  }
  
  Future<void> clearExpiredCache() async {
    final keysToDelete = <dynamic>[];
    
    for (final key in _cacheStorage.keys) {
      final cachedData = _cacheStorage.get(key);
      if (cachedData != null) {
        final cached = CachedData.fromJson(Map<String, dynamic>.from(cachedData));
        if (!cached.isValid()) {
          keysToDelete.add(key);
        }
      }
    }
    
    await _cacheStorage.deleteAll(keysToDelete);
  }
  
  // Media Storage
  Future<String> saveMediaFile(String fileName, Uint8List data) async {
    final dir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory('${dir.path}/media');
    
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    
    final filePath = '${mediaDir.path}/$fileName';
    final file = File(filePath);
    await file.writeAsBytes(data);
    
    // Store reference in Hive
    await _mediaStorage.put(fileName, {
      'path': filePath,
      'size': data.length,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    return filePath;
  }
  
  // Secure Storage for sensitive data
  Future<void> saveSecureData(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }
  
  Future<String?> getSecureData(String key) async {
    return await _secureStorage.read(key: key);
  }
  
  // Configuration Management
  Future<void> saveConfig(String key, dynamic value) async {
    await _configStorage.put(key, value);
  }
  
  Future<dynamic> getConfig(String key) async {
    return _configStorage.get(key);
  }
  
  // Storage Statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    final stats = <String, dynamic>{};
    
    stats['users'] = _userStorage.length;
    stats['messages'] = _messageStorage.length;
    stats['healthRecords'] = _healthStorage.length;
    stats['medications'] = _medicationStorage.length;
    stats['pendingOperations'] = _operationStorage.length;
    stats['cachedItems'] = _cacheStorage.length;
    stats['mediaFiles'] = _mediaStorage.length;
    
    return stats;
  }
  
  // Cleanup and Optimization
  Future<void> optimizeStorage() async {
    await clearExpiredCache();
    await _compactBoxes();
  }
  
  Future<void> _compactBoxes() async {
    await _userStorage.compact();
    await _messageStorage.compact();
    await _healthStorage.compact();
    await _medicationStorage.compact();
    await _operationStorage.compact();
    await _cacheStorage.compact();
    await _configStorage.compact();
    await _mediaStorage.compact();
  }
  
  Future<void> clearOfflineData() async {
    await _operationStorage.clear();
    await _cacheStorage.clear();
  }
  
  void dispose() {
    if (_isInitialized) {
      _userStorage.close();
      _messageStorage.close();
      _healthStorage.close();
      _medicationStorage.close();
      _operationStorage.close();
      _cacheStorage.close();
      _configStorage.close();
      _mediaStorage.close();
    }
  }
}