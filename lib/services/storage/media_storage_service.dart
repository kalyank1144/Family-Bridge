import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

typedef UploadProgress = void Function(double progress);

class MediaStorageService {
  static final MediaStorageService _instance = MediaStorageService._internal();
  factory MediaStorageService() => _instance;
  MediaStorageService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final _uuid = const Uuid();
  final _queueFileName = 'upload_queue.json';

  static const String bucketMedicationPhotos = 'medication-photos';
  static const String bucketVoiceNotes = 'voice-notes';

  Future<bool> requestPermissions({bool mic = false, bool camera = false}) async {
    final permissions = <Permission>[];
    if (mic) permissions.add(Permission.microphone);
    if (camera) permissions.add(Permission.camera);
    if (permissions.isEmpty) return true;
    final results = await permissions.request();
    return results.values.every((s) => s.isGranted);
  }

  Future<String> uploadFile({
    required File file,
    required String bucket,
    UploadProgress? onProgress,
    String? contentType,
    bool makePublic = false,
    int maxRetries = 3,
  }) async {
    // Offline? queue and return local path to be resolved later
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      await _queueUpload(file: file, bucket: bucket, contentType: contentType);
      return file.path; // return local path placeholder
    }

    int attempt = 0;
    late Uint8List bytes;
    bytes = await file.readAsBytes();

    while (true) {
      try {
        final fileName = _buildFileName(file.path, contentType: contentType);
        await _supabase.storage
            .from(bucket)
            .uploadBinary(
              fileName,
              bytes,
              fileOptions: FileOptions(
                cacheControl: '3600',
                upsert: false,
                contentType: contentType ?? _guessContentType(file.path),
              ),
            );

        final url = makePublic
            ? _supabase.storage.from(bucket).getPublicUrl(fileName)
            : await _signedUrl(bucket: bucket, path: fileName);
        return url;
      } catch (e) {
        attempt++;
        if (attempt >= maxRetries) {
          // Queue for later retry
          await _queueUpload(file: file, bucket: bucket, contentType: contentType);
          rethrow;
        }
        await Future.delayed(Duration(milliseconds: 400 * attempt));
      }
    }
  }

  Future<String> _signedUrl({required String bucket, required String path, Duration expiresIn = const Duration(days: 7)}) async {
    try {
      final seconds = expiresIn.inSeconds;
      final res = await _supabase.storage.from(bucket).createSignedUrl(path, seconds);
      return res;
    } catch (_) {
      return _supabase.storage.from(bucket).getPublicUrl(path);
    }
  }

  String _buildFileName(String originalPath, {String? contentType}) {
    final ext = _fileExtensionFromPath(originalPath, contentType: contentType);
    return '${_uuid.v4()}.$ext';
  }

  String _fileExtensionFromPath(String path, {String? contentType}) {
    if (contentType != null) {
      if (contentType.contains('jpeg')) return 'jpg';
      if (contentType.contains('png')) return 'png';
      if (contentType.contains('mp4')) return 'mp4';
      if (contentType.contains('m4a')) return 'm4a';
      if (contentType.contains('aac')) return 'aac';
      if (contentType.contains('wav')) return 'wav';
    }
    final parts = path.split('.');
    return parts.isNotEmpty ? parts.last.toLowerCase() : 'bin';
  }

  String _guessContentType(String path) {
    final ext = path.toLowerCase();
    if (ext.endsWith('.jpg') || ext.endsWith('.jpeg')) return 'image/jpeg';
    if (ext.endsWith('.png')) return 'image/png';
    if (ext.endsWith('.mp4')) return 'video/mp4';
    if (ext.endsWith('.m4a') || ext.endsWith('.aac')) return 'audio/m4a';
    if (ext.endsWith('.wav')) return 'audio/wav';
    return 'application/octet-stream';
  }

  Future<void> _queueUpload({
    required File file,
    required String bucket,
    String? contentType,
  }) async {
    try {
      final queue = await _loadQueue();
      queue.add({
        'path': file.path,
        'bucket': bucket,
        'contentType': contentType,
        'queuedAt': DateTime.now().toIso8601String(),
      });
      await _saveQueue(queue);
    } catch (e) {
      debugPrint('Error queueing upload: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _loadQueue() async {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/$_queueFileName');
    if (!file.existsSync()) return [];
    final text = await file.readAsString();
    final data = jsonDecode(text);
    return List<Map<String, dynamic>>.from(data);
    }

  Future<void> _saveQueue(List<Map<String, dynamic>> queue) async {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/$_queueFileName');
    await file.writeAsString(jsonEncode(queue));
  }

  Future<int> processQueue() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) return 0;

    final queue = await _loadQueue();
    if (queue.isEmpty) return 0;

    final remaining = <Map<String, dynamic>>[];
    int processed = 0;

    for (final item in queue) {
      try {
        final path = item['path'] as String;
        final bucket = item['bucket'] as String;
        final contentType = item['contentType'] as String?;
        final file = File(path);
        if (!file.existsSync()) continue;
        await uploadFile(file: file, bucket: bucket, contentType: contentType);
        processed++;
      } catch (e) {
        remaining.add(item);
      }
    }

    await _saveQueue(remaining);
    return processed;
  }
}
