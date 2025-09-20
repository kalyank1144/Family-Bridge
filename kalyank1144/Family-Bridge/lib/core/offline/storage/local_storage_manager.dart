import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/offline_operation.dart';
import '../models/cached_data.dart';
import '../../models/user.dart';
import '../../models/message.dart';
import '../../models/health_record.dart';
import '../../models/medication.dart';

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
      Hive.registerAdapter(OfflineOperationAdapter());
      Hive.registerAdapter(CachedDataAdapter());
      Hive.registerAdapter(UserAdapter());
      Hive.registerAdapter(MessageAdapter());
      Hive.registerAdapter(HealthRecordAdapter());
      Hive.registerAdapter(MedicationAdapter());
    } catch (e) {
      debugPrint('Adapters already registered');
    }
  }
  
  // User Management
  Future<void> saveUser(User user) async {
    await _userStorage.put(user.id, user.toJson());
  }
  
  Future<User?> getUser(String userId) async {
    final userData = _userStorage.get(userId);
    if (userData != null) {
      return User.fromJson(Map<String, dynamic>.from(userData));
    }
    return null;
  }
  
  Future<List<User>> getAllUsers() async {
    final users = <User>[];
    for (final key in _userStorage.keys) {
      final userData = _userStorage.get(key);
      if (userData != null) {
        users.add(User.fromJson(Map<String, dynamic>.from(userData)));
      }
    }
    return users;
  }
  
  // Message Management
  Future<void> saveMessage(Message message) async {
    await _messageStorage.put(message.id, message.toJson());
  }
  
  Future<void> saveMessages(List<Message> messages) async {
    final batch = <String, Map<String, dynamic>>{};
    for (final message in messages) {
      batch[message.id] = message.toJson();
    }
    await _messageStorage.putAll(batch);
  }
  
  Future<List<Message>> getMessages({
    String? conversationId,
    int limit = 50,
  }) async {
    final messages = <Message>[];
    
    for (final key in _messageStorage.keys) {
      final messageData = _messageStorage.get(key);
      if (messageData != null) {
        final message = Message.fromJson(Map<String, dynamic>.from(messageData));
        
        if (conversationId == null || message.conversationId == conversationId) {
          messages.add(message);
        }
      }
    }
    
    messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return messages.take(limit).toList();
  }
  
  // Health Records Management
  Future<void> saveHealthRecord(HealthRecord record) async {
    await _healthStorage.put(record.id, record.toJson());
  }
  
  Future<List<HealthRecord>> getHealthRecords({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final records = <HealthRecord>[];
    
    for (final key in _healthStorage.keys) {
      final recordData = _healthStorage.get(key);
      if (recordData != null) {
        final record = HealthRecord.fromJson(Map<String, dynamic>.from(recordData));
        
        bool include = true;
        
        if (userId != null && record.userId != userId) include = false;
        if (startDate != null && record.timestamp.isBefore(startDate)) include = false;
        if (endDate != null && record.timestamp.isAfter(endDate)) include = false;
        
        if (include) records.add(record);
      }
    }
    
    records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return records;
  }
  
  // Medication Management
  Future<void> saveMedication(Medication medication) async {
    await _medicationStorage.put(medication.id, medication.toJson());
  }
  
  Future<List<Medication>> getMedications({String? userId}) async {
    final medications = <Medication>[];
    
    for (final key in _medicationStorage.keys) {
      final medicationData = _medicationStorage.get(key);
      if (medicationData != null) {
        final medication = Medication.fromJson(Map<String, dynamic>.from(medicationData));
        
        if (userId == null || medication.userId == userId) {
          medications.add(medication);
        }
      }
    }
    
    return medications;
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
  
  Future<Uint8List?> getMediaFile(String fileName) async {
    final mediaInfo = _mediaStorage.get(fileName);
    if (mediaInfo != null) {
      final filePath = mediaInfo['path'] as String;
      final file = File(filePath);
      
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    }
    return null;
  }
  
  // Secure Storage for sensitive data
  Future<void> saveSecureData(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }
  
  Future<String?> getSecureData(String key) async {
    return await _secureStorage.read(key: key);
  }
  
  Future<void> deleteSecureData(String key) async {
    await _secureStorage.delete(key: key);
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
    
    // Calculate total size
    final dir = await getApplicationDocumentsDirectory();
    final hiveDir = Directory('${dir.path}/hive');
    
    if (await hiveDir.exists()) {
      int totalSize = 0;
      await for (final entity in hiveDir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      stats['totalSizeBytes'] = totalSize;
      stats['totalSizeMB'] = (totalSize / (1024 * 1024)).toStringAsFixed(2);
    }
    
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
  
  Future<void> clearAllData() async {
    await _userStorage.clear();
    await _messageStorage.clear();
    await _healthStorage.clear();
    await _medicationStorage.clear();
    await _operationStorage.clear();
    await _cacheStorage.clear();
    await _configStorage.clear();
    await _mediaStorage.clear();
    await _secureStorage.deleteAll();
  }
  
  Future<void> saveAppState() async {
    await _configStorage.put('lastSaved', DateTime.now().toIso8601String());
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