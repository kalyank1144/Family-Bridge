import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as img;

class MediaService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _imagePicker = ImagePicker();
  final _uuid = const Uuid();
  
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();

  /// Pick an image from gallery or camera
  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      // Request permissions
      if (source == ImageSource.camera) {
        final cameraStatus = await Permission.camera.request();
        if (!cameraStatus.isGranted) {
          throw Exception('Camera permission denied');
        }
      } else {
        final storageStatus = await Permission.storage.request();
        if (!storageStatus.isGranted) {
          throw Exception('Storage permission denied');
        }
      }
      
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image: $e');
      rethrow;
    }
  }

  /// Pick multiple images from gallery
  Future<List<File>> pickMultipleImages() async {
    try {
      final storageStatus = await Permission.storage.request();
      if (!storageStatus.isGranted) {
        throw Exception('Storage permission denied');
      }

      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 90,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      
      return images.map((image) => File(image.path)).toList();
    } catch (e) {
      debugPrint('Error picking multiple images: $e');
      rethrow;
    }
  }

  /// Pick a video from gallery or camera
  Future<File?> pickVideo({ImageSource source = ImageSource.gallery}) async {
    try {
      // Request permissions
      if (source == ImageSource.camera) {
        final cameraStatus = await Permission.camera.request();
        final microphoneStatus = await Permission.microphone.request();
        if (!cameraStatus.isGranted || !microphoneStatus.isGranted) {
          throw Exception('Camera/Microphone permission denied');
        }
      } else {
        final storageStatus = await Permission.storage.request();
        if (!storageStatus.isGranted) {
          throw Exception('Storage permission denied');
        }
      }
      
      final XFile? video = await _imagePicker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5), // 5 minute limit
      );
      
      if (video != null) {
        return File(video.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking video: $e');
      rethrow;
    }
  }

  /// Upload image to Supabase storage
  Future<String> uploadImage(File imageFile, {String? fileName}) async {
    try {
      final String fileId = fileName ?? '${_uuid.v4()}.jpg';
      final String bucketPath = 'chat_images/$fileId';
      
      // Compress image if needed
      final compressedFile = await _compressImage(imageFile);
      final bytes = await compressedFile.readAsBytes();
      
      // Upload to Supabase
      final response = await _supabase.storage
          .from('chat_images')
          .uploadBinary(fileId, bytes);
      
      if (response.isNotEmpty) {
        // Get public URL
        final String publicUrl = _supabase.storage
            .from('chat_images')
            .getPublicUrl(fileId);
        
        return publicUrl;
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
    }
  }

  /// Upload video to Supabase storage
  Future<String> uploadVideo(File videoFile, {String? fileName}) async {
    try {
      final String fileId = fileName ?? '${_uuid.v4()}.mp4';
      final bytes = await videoFile.readAsBytes();
      
      // Upload to Supabase
      final response = await _supabase.storage
          .from('chat_videos')
          .uploadBinary(fileId, bytes);
      
      if (response.isNotEmpty) {
        // Get public URL
        final String publicUrl = _supabase.storage
            .from('chat_videos')
            .getPublicUrl(fileId);
        
        return publicUrl;
      } else {
        throw Exception('Failed to upload video');
      }
    } catch (e) {
      debugPrint('Error uploading video: $e');
      rethrow;
    }
  }

  /// Generate video thumbnail
  Future<String?> generateVideoThumbnail(String videoUrl) async {
    try {
      // This is a simplified version - in a real app, you'd use video_thumbnail package
      // For now, return a placeholder or use the first frame
      return null; // Placeholder implementation
    } catch (e) {
      debugPrint('Error generating video thumbnail: $e');
      return null;
    }
  }

  /// Compress image while maintaining quality
  Future<File> _compressImage(File originalFile) async {
    try {
      final originalBytes = await originalFile.readAsBytes();
      final image = img.decodeImage(originalBytes);
      
      if (image == null) return originalFile;
      
      // Resize if too large
      img.Image resizedImage = image;
      if (image.width > 1920 || image.height > 1920) {
        resizedImage = img.copyResize(
          image,
          width: image.width > image.height ? 1920 : null,
          height: image.height > image.width ? 1920 : null,
        );
      }
      
      // Compress to JPEG with 85% quality
      final compressedBytes = img.encodeJpg(resizedImage, quality: 85);
      
      // Save compressed image to temp directory
      final tempDir = await getTemporaryDirectory();
      final compressedFile = File('${tempDir.path}/${_uuid.v4()}.jpg');
      await compressedFile.writeAsBytes(compressedBytes);
      
      return compressedFile;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return originalFile;
    }
  }

  /// Save media to device gallery
  Future<void> saveToGallery(String url, {bool isVideo = false}) async {
    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('Storage permission denied');
      }
      
      // Download the file
      final response = await _supabase.storage
          .from(isVideo ? 'chat_videos' : 'chat_images')
          .download(url.split('/').last);
      
      // Save to gallery (implementation depends on platform)
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = '${_uuid.v4()}.${isVideo ? 'mp4' : 'jpg'}';
      final file = File('${appDir.path}/$fileName');
      await file.writeAsBytes(response);
      
      // Note: For actual gallery saving, you'd use packages like gallery_saver
      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('Error saving to gallery: $e');
      rethrow;
    }
  }

  /// Get file size in bytes
  Future<int> getFileSize(File file) async {
    try {
      return await file.length();
    } catch (e) {
      debugPrint('Error getting file size: $e');
      return 0;
    }
  }

  /// Format file size to human readable string
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
  }

  /// Delete media from storage
  Future<void> deleteMedia(String url, {bool isVideo = false}) async {
    try {
      final fileName = url.split('/').last;
      await _supabase.storage
          .from(isVideo ? 'chat_videos' : 'chat_images')
          .remove([fileName]);
    } catch (e) {
      debugPrint('Error deleting media: $e');
      rethrow;
    }
  }

  /// Create image gallery for family sharing
  Future<List<String>> getFamilyImages(String familyId, {int limit = 50}) async {
    try {
      final response = await _supabase.storage
          .from('chat_images')
          .list(path: familyId, sortBy: const SortBy(column: 'created_at', order: SortOrder.descending));
      
      return response
          .take(limit)
          .map((file) => _supabase.storage.from('chat_images').getPublicUrl('${familyId}/${file.name}'))
          .toList();
    } catch (e) {
      debugPrint('Error getting family images: $e');
      return [];
    }
  }

  /// Clean up temporary files
  Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      
      for (final file in files) {
        if (file is File && (file.path.endsWith('.jpg') || file.path.endsWith('.mp4'))) {
          // Delete files older than 1 hour
          final stat = await file.stat();
          final age = DateTime.now().difference(stat.modified);
          if (age.inHours > 1) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up temp files: $e');
    }
  }

  /// Validate media file
  bool validateMediaFile(File file, {bool isVideo = false}) {
    try {
      final extension = file.path.split('.').last.toLowerCase();
      
      if (isVideo) {
        return ['mp4', 'mov', 'avi', 'mkv'].contains(extension);
      } else {
        return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
      }
    } catch (e) {
      debugPrint('Error validating media file: $e');
      return false;
    }
  }

  /// Get media metadata
  Future<Map<String, dynamic>> getMediaMetadata(File file) async {
    try {
      final stat = await file.stat();
      final size = await getFileSize(file);
      final extension = file.path.split('.').last.toLowerCase();
      
      Map<String, dynamic> metadata = {
        'fileName': file.path.split('/').last,
        'fileSize': size,
        'fileSizeFormatted': formatFileSize(size),
        'extension': extension,
        'created': stat.modified.toIso8601String(),
        'isImage': ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension),
        'isVideo': ['mp4', 'mov', 'avi', 'mkv'].contains(extension),
      };
      
      if (metadata['isImage'] == true) {
        try {
          final bytes = await file.readAsBytes();
          final image = img.decodeImage(bytes);
          if (image != null) {
            metadata['width'] = image.width;
            metadata['height'] = image.height;
            metadata['aspectRatio'] = image.width / image.height;
          }
        } catch (e) {
          debugPrint('Error getting image dimensions: $e');
        }
      }
      
      return metadata;
    } catch (e) {
      debugPrint('Error getting media metadata: $e');
      return {};
    }
  }
}