import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

class MediaService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _imagePicker = ImagePicker();
  final _uuid = const Uuid();
  
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();

  Future<String?> pickImage({required ImageSource source}) async {
    try {
      final status = await Permission.camera.request();
      if (source == ImageSource.camera && !status.isGranted) {
        throw Exception('Camera permission denied');
      }
      
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      
      if (image != null) {
        return await _uploadImage(File(image.path));
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  Future<String?> pickVideo({required ImageSource source}) async {
    try {
      final status = await Permission.camera.request();
      if (source == ImageSource.camera && !status.isGranted) {
        throw Exception('Camera permission denied');
      }
      
      final XFile? video = await _imagePicker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 3),
      );
      
      if (video != null) {
        final videoUrl = await _uploadVideo(File(video.path));
        final thumbnailUrl = await _generateVideoThumbnail(video.path);
        
        return videoUrl;
      }
      return null;
    } catch (e) {
      debugPrint('Error picking video: $e');
      return null;
    }
  }

  Future<String> _uploadImage(File imageFile) async {
    try {
      final fileName = '${_uuid.v4()}.jpg';
      final bytes = await imageFile.readAsBytes();
      
      await _supabase.storage
          .from('chat_images')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );
      
      final url = _supabase.storage
          .from('chat_images')
          .getPublicUrl(fileName);
      
      return url;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
    }
  }

  Future<String> _uploadVideo(File videoFile) async {
    try {
      final fileName = '${_uuid.v4()}.mp4';
      final bytes = await videoFile.readAsBytes();
      
      await _supabase.storage
          .from('chat_videos')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'video/mp4',
              upsert: false,
            ),
          );
      
      final url = _supabase.storage
          .from('chat_videos')
          .getPublicUrl(fileName);
      
      return url;
    } catch (e) {
      debugPrint('Error uploading video: $e');
      rethrow;
    }
  }

  Future<String?> _generateVideoThumbnail(String videoPath) async {
    try {
      final controller = VideoPlayerController.file(File(videoPath));
      await controller.initialize();
      
      await controller.seekTo(Duration.zero);
      
      controller.dispose();
      
      return null;
    } catch (e) {
      debugPrint('Error generating video thumbnail: $e');
      return null;
    }
  }

  Future<String?> optimizeImageForElder(String imageUrl) async {
    try {
      return imageUrl;
    } catch (e) {
      debugPrint('Error optimizing image for elder: $e');
      return imageUrl;
    }
  }

  Future<File?> downloadMedia(String url, String fileName) async {
    try {
      final response = await _supabase.storage
          .from(_getStorageBucket(url))
          .download(fileName);
      
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(response);
      
      return file;
    } catch (e) {
      debugPrint('Error downloading media: $e');
      return null;
    }
  }

  String _getStorageBucket(String url) {
    if (url.contains('chat_images')) {
      return 'chat_images';
    } else if (url.contains('chat_videos')) {
      return 'chat_videos';
    } else if (url.contains('voice_messages')) {
      return 'voice_messages';
    }
    return 'chat_media';
  }

  Future<bool> requestMediaPermissions() async {
    final statuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.photos,
      Permission.storage,
    ].request();
    
    return statuses.values.every((status) => 
      status == PermissionStatus.granted || 
      status == PermissionStatus.limited
    );
  }

  String getMediaCacheKey(String url) {
    return 'media_${url.hashCode}';
  }

  Future<void> clearMediaCache() async {
    try {
      final directory = await getTemporaryDirectory();
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    } catch (e) {
      debugPrint('Error clearing media cache: $e');
    }
  }
}