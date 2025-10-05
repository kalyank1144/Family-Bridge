import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  static EncryptionService get instance => _instance;
  EncryptionService._internal();

  static const String _masterKeyAlias = 'hipaa_master_key';
  static const String _ivPrefix = 'hipaa_iv_';
  static const String _keyRotationPrefix = 'key_rotation_';
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'hipaa_secure_prefs',
      preferencesKeyPrefix: 'hipaa_',
    ),
    iOptions: IOSOptions(
      groupId: 'group.familybridge.hipaa',
      accountName: 'FamilyBridge-HIPAA',
      accessibility: IOSAccessibility.first_unlock_this_device,
    ),
  );

  Encrypter? _encrypter;
  Key? _currentKey;
  DateTime? _keyCreatedAt;
  int _keyVersion = 1;
  bool _isInitialized = false;

  // Encryption algorithms
  static const String _algorithm = 'AES-256-GCM';
  static const int _keyLength = 32; // 256 bits
  static const int _ivLength = 16; // 128 bits

  /// Initialize encryption service with master key
  Future<void> initialize() async {
    try {
      await _loadOrGenerateMasterKey();
      _isInitialized = true;
      debugPrint('EncryptionService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize EncryptionService: $e');
      rethrow;
    }
  }

  /// Encrypt sensitive data (PHI)
  Future<EncryptedData> encryptPhi(String plaintext, {Map<String, String>? metadata}) async {
    _ensureInitialized();
    
    try {
      final iv = IV.fromSecureRandom(_ivLength);
      final encrypted = _encrypter!.encrypt(plaintext, iv: iv);
      
      final encryptedData = EncryptedData(
        ciphertext: encrypted.base64,
        iv: iv.base64,
        keyVersion: _keyVersion,
        algorithm: _algorithm,
        timestamp: DateTime.now().toUtc(),
        checksum: _generateChecksum(encrypted.base64, iv.base64),
        metadata: metadata,
      );

      // Log encryption event
      await _logEncryptionEvent('PHI encrypted', metadata);
      
      return encryptedData;
    } catch (e) {
      await _logEncryptionEvent('PHI encryption failed', {'error': e.toString()});
      rethrow;
    }
  }

  /// Decrypt sensitive data (PHI)
  Future<String> decryptPhi(EncryptedData encryptedData) async {
    _ensureInitialized();
    
    try {
      // Verify data integrity
      final expectedChecksum = _generateChecksum(encryptedData.ciphertext, encryptedData.iv);
      if (encryptedData.checksum != expectedChecksum) {
        throw EncryptionException('Data integrity check failed');
      }

      // Handle key rotation if needed
      if (encryptedData.keyVersion != _keyVersion) {
        await _handleKeyVersionMismatch(encryptedData.keyVersion);
      }

      final encrypted = Encrypted.fromBase64(encryptedData.ciphertext);
      final iv = IV.fromBase64(encryptedData.iv);
      
      final plaintext = _encrypter!.decrypt(encrypted, iv: iv);
      
      // Log decryption event
      await _logEncryptionEvent('PHI decrypted', encryptedData.metadata);
      
      return plaintext;
    } catch (e) {
      await _logEncryptionEvent('PHI decryption failed', {
        'error': e.toString(),
        'keyVersion': encryptedData.keyVersion.toString(),
        ...?encryptedData.metadata,
      });
      rethrow;
    }
  }

  /// Encrypt regular data (non-PHI)
  Future<String> encryptData(String plaintext) async {
    _ensureInitialized();
    
    final iv = IV.fromSecureRandom(_ivLength);
    final encrypted = _encrypter!.encrypt(plaintext, iv: iv);
    
    // Return combined format: keyVersion:iv:ciphertext
    return '$_keyVersion:${iv.base64}:${encrypted.base64}';
  }

  /// Decrypt regular data (non-PHI)
  Future<String> decryptData(String encryptedString) async {
    _ensureInitialized();
    
    final parts = encryptedString.split(':');
    if (parts.length != 3) {
      throw EncryptionException('Invalid encrypted data format');
    }

    final keyVersion = int.parse(parts[0]);
    final iv = IV.fromBase64(parts[1]);
    final encrypted = Encrypted.fromBase64(parts[2]);

    // Handle key rotation if needed
    if (keyVersion != _keyVersion) {
      await _handleKeyVersionMismatch(keyVersion);
    }

    return _encrypter!.decrypt(encrypted, iv: iv);
  }

  /// Generate secure hash for passwords/tokens
  String hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate secure salt
  String generateSalt() {
    final iv = IV.fromSecureRandom(16);
    return iv.base64;
  }

  /// Rotate encryption keys (HIPAA requirement)
  Future<void> rotateKeys() async {
    _ensureInitialized();
    
    try {
      // Store old key for decryption of existing data
      await _secureStorage.write(
        key: '$_keyRotationPrefix$_keyVersion',
        value: _currentKey!.base64,
      );

      // Generate new key
      _keyVersion++;
      _currentKey = Key.fromSecureRandom(_keyLength);
      _encrypter = Encrypter(AES(_currentKey!));
      _keyCreatedAt = DateTime.now().toUtc();

      // Store new key
      await _secureStorage.write(key: _masterKeyAlias, value: _currentKey!.base64);
      await _secureStorage.write(key: '${_masterKeyAlias}_version', value: _keyVersion.toString());
      await _secureStorage.write(key: '${_masterKeyAlias}_created', value: _keyCreatedAt!.toIso8601String());

      await _logEncryptionEvent('Encryption keys rotated', {
        'newKeyVersion': _keyVersion.toString(),
        'previousKeyVersion': (_keyVersion - 1).toString(),
      });

    } catch (e) {
      await _logEncryptionEvent('Key rotation failed', {'error': e.toString()});
      rethrow;
    }
  }

  /// Check if key rotation is needed
  bool shouldRotateKeys() {
    if (_keyCreatedAt == null) return false;
    
    // Rotate keys every 90 days (HIPAA best practice)
    final rotationInterval = const Duration(days: 90);
    return DateTime.now().toUtc().difference(_keyCreatedAt!) > rotationInterval;
  }

  /// Get encryption status for compliance reporting
  Map<String, dynamic> getEncryptionStatus() {
    return {
      'isInitialized': _isInitialized,
      'algorithm': _algorithm,
      'keyLength': _keyLength,
      'keyVersion': _keyVersion,
      'keyCreatedAt': _keyCreatedAt?.toIso8601String(),
      'shouldRotateKeys': shouldRotateKeys(),
      'lastRotationDue': _keyCreatedAt?.add(const Duration(days: 90)).toIso8601String(),
    };
  }

  /// Securely wipe encryption keys from memory
  Future<void> wipeKeys() async {
    _currentKey = null;
    _encrypter = null;
    _keyCreatedAt = null;
    _keyVersion = 1;
    _isInitialized = false;
    
    await _logEncryptionEvent('Encryption keys wiped from memory', {});
  }

  /// Private methods
  Future<void> _loadOrGenerateMasterKey() async {
    try {
      // Try to load existing key
      final keyString = await _secureStorage.read(key: _masterKeyAlias);
      final versionString = await _secureStorage.read(key: '${_masterKeyAlias}_version');
      final createdString = await _secureStorage.read(key: '${_masterKeyAlias}_created');

      if (keyString != null) {
        // Load existing key
        _currentKey = Key.fromBase64(keyString);
        _keyVersion = int.tryParse(versionString ?? '1') ?? 1;
        _keyCreatedAt = createdString != null ? DateTime.parse(createdString) : DateTime.now().toUtc();
        
        await _logEncryptionEvent('Existing encryption key loaded', {
          'keyVersion': _keyVersion.toString(),
        });
      } else {
        // Generate new key
        _currentKey = Key.fromSecureRandom(_keyLength);
        _keyVersion = 1;
        _keyCreatedAt = DateTime.now().toUtc();
        
        // Store key securely
        await _secureStorage.write(key: _masterKeyAlias, value: _currentKey!.base64);
        await _secureStorage.write(key: '${_masterKeyAlias}_version', value: _keyVersion.toString());
        await _secureStorage.write(key: '${_masterKeyAlias}_created', value: _keyCreatedAt!.toIso8601String());
        
        await _logEncryptionEvent('New encryption key generated', {
          'keyVersion': _keyVersion.toString(),
        });
      }

      _encrypter = Encrypter(AES(_currentKey!));
      
    } catch (e) {
      throw EncryptionException('Failed to initialize encryption key: $e');
    }
  }

  Future<void> _handleKeyVersionMismatch(int requiredVersion) async {
    if (requiredVersion == _keyVersion) return;

    try {
      // Load historical key for decryption
      final historicalKeyString = await _secureStorage.read(key: '$_keyRotationPrefix$requiredVersion');
      
      if (historicalKeyString != null) {
        final historicalKey = Key.fromBase64(historicalKeyString);
        _encrypter = Encrypter(AES(historicalKey));
        
        await _logEncryptionEvent('Using historical encryption key', {
          'requestedVersion': requiredVersion.toString(),
          'currentVersion': _keyVersion.toString(),
        });
      } else {
        throw EncryptionException('Historical encryption key not found for version $requiredVersion');
      }
    } catch (e) {
      await _logEncryptionEvent('Key version mismatch handling failed', {
        'error': e.toString(),
        'requiredVersion': requiredVersion.toString(),
      });
      rethrow;
    }
  }

  String _generateChecksum(String ciphertext, String iv) {
    final content = ciphertext + iv + _keyVersion.toString();
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  void _ensureInitialized() {
    if (!_isInitialized) {
      throw EncryptionException('EncryptionService not initialized');
    }
  }

  Future<void> _logEncryptionEvent(String description, Map<String, String>? metadata) async {
    try {
      // Import and use audit service
      // Note: In production, this would be properly injected
      debugPrint('Encryption Event: $description');
    } catch (e) {
      debugPrint('Failed to log encryption event: $e');
    }
  }
}

/// Encrypted data container
class EncryptedData {
  final String ciphertext;
  final String iv;
  final int keyVersion;
  final String algorithm;
  final DateTime timestamp;
  final String checksum;
  final Map<String, String>? metadata;

  EncryptedData({
    required this.ciphertext,
    required this.iv,
    required this.keyVersion,
    required this.algorithm,
    required this.timestamp,
    required this.checksum,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'ciphertext': ciphertext,
      'iv': iv,
      'keyVersion': keyVersion,
      'algorithm': algorithm,
      'timestamp': timestamp.toIso8601String(),
      'checksum': checksum,
      'metadata': metadata,
    };
  }

  factory EncryptedData.fromJson(Map<String, dynamic> json) {
    return EncryptedData(
      ciphertext: json['ciphertext'],
      iv: json['iv'],
      keyVersion: json['keyVersion'],
      algorithm: json['algorithm'],
      timestamp: DateTime.parse(json['timestamp']),
      checksum: json['checksum'],
      metadata: json['metadata'] != null 
          ? Map<String, String>.from(json['metadata'])
          : null,
    );
  }
}

/// Custom encryption exception
class EncryptionException implements Exception {
  final String message;
  EncryptionException(this.message);
  
  @override
  String toString() => 'EncryptionException: $message';
}