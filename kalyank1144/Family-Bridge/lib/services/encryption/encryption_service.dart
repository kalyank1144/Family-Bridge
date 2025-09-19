import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';

/// Core encryption service implementing AES-256 encryption
/// for HIPAA-compliant data protection
class EncryptionService {
  static const String _encryptionKey = String.fromEnvironment(
    'ENCRYPTION_KEY',
    defaultValue: 'YOUR_32_CHAR_BASE64_ENCODED_KEY_HERE',
  );
  
  late final Key _key;
  late final IV _iv;
  late final Encrypter _encrypter;
  
  // Singleton instance
  static EncryptionService? _instance;
  
  EncryptionService._() {
    _key = Key.fromBase64(_encryptionKey);
    _iv = IV.fromLength(16);
    _encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
  }
  
  factory EncryptionService() {
    _instance ??= EncryptionService._();
    return _instance!;
  }
  
  /// Encrypt sensitive string data
  String encryptData(String plainText) {
    try {
      final encrypted = _encrypter.encrypt(plainText, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      throw EncryptionException('Failed to encrypt data: $e');
    }
  }
  
  /// Decrypt encrypted string data
  String decryptData(String encryptedText) {
    try {
      final encrypted = Encrypted.fromBase64(encryptedText);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      throw EncryptionException('Failed to decrypt data: $e');
    }
  }
  
  /// Encrypt file contents
  Future<void> encryptFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final encrypted = _encrypter.encryptBytes(bytes, iv: _iv);
      await file.writeAsBytes(encrypted.bytes);
    } catch (e) {
      throw EncryptionException('Failed to encrypt file: $e');
    }
  }
  
  /// Decrypt file contents
  Future<void> decryptFile(File file) async {
    try {
      final encryptedBytes = await file.readAsBytes();
      final encrypted = Encrypted(encryptedBytes);
      final decrypted = _encrypter.decryptBytes(encrypted, iv: _iv);
      await file.writeAsBytes(decrypted);
    } catch (e) {
      throw EncryptionException('Failed to decrypt file: $e');
    }
  }
  
  /// Encrypt JSON data
  String encryptJson(Map<String, dynamic> jsonData) {
    final jsonString = jsonEncode(jsonData);
    return encryptData(jsonString);
  }
  
  /// Decrypt JSON data
  Map<String, dynamic> decryptJson(String encryptedJson) {
    final decryptedString = decryptData(encryptedJson);
    return jsonDecode(decryptedString) as Map<String, dynamic>;
  }
  
  /// Generate hash for data integrity
  String generateHash(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Verify data integrity
  bool verifyIntegrity(String data, String expectedHash) {
    final actualHash = generateHash(data);
    return actualHash == expectedHash;
  }
  
  /// Encrypt health data with additional metadata
  Map<String, dynamic> encryptHealthData(Map<String, dynamic> healthData) {
    final encrypted = encryptJson(healthData);
    final hash = generateHash(encrypted);
    
    return {
      'data': encrypted,
      'hash': hash,
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
  }
  
  /// Decrypt and verify health data
  Map<String, dynamic>? decryptHealthData(Map<String, dynamic> encryptedData) {
    final data = encryptedData['data'] as String;
    final hash = encryptedData['hash'] as String;
    
    // Verify integrity
    if (!verifyIntegrity(data, hash)) {
      throw EncryptionException('Data integrity check failed');
    }
    
    return decryptJson(data);
  }
}

/// Custom exception for encryption errors
class EncryptionException implements Exception {
  final String message;
  
  EncryptionException(this.message);
  
  @override
  String toString() => 'EncryptionException: $message';
}