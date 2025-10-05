import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  static final _client = Supabase.instance.client;

  static Future<String?> uploadMedicationPhoto({
    required File file,
    required String elderId,
    required String medicationId,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      final ext = p.extension(file.path).replaceAll('.', '').toLowerCase();
      final contentType = ext == 'png'
          ? 'image/png'
          : ext == 'webp'
              ? 'image/webp'
              : 'image/jpeg';

      final path = 'elders/$elderId/medications/$medicationId/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await _client.storage.from('medication-photos').uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      final signed = await _client.storage
          .from('medication-photos')
          .createSignedUrl(path, 60 * 60 * 24 * 7); // 7 days
      return signed;
    } catch (e) {
      // ignore: avoid_print
      print('Upload medication photo error: $e');
      return null;
    }
  }

  static Future<String?> uploadVoiceNote({
    required File file,
    required String elderId,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      final ext = p.extension(file.path).replaceAll('.', '').toLowerCase();
      final contentType = ext == 'm4a'
          ? 'audio/mp4'
          : ext == 'aac'
              ? 'audio/aac'
              : 'audio/mpeg';

      final path = 'elders/$elderId/voice-notes/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await _client.storage.from('voice-notes').uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      final signed = await _client.storage
          .from('voice-notes')
          .createSignedUrl(path, 60 * 60 * 24 * 7); // 7 days
      return signed;
    } catch (e) {
      // ignore: avoid_print
      print('Upload voice note error: $e');
      return null;
    }
  }
}