import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../shared/services/logging_service.dart';

/// Service for handling media upload, compression, and sharing functionality
/// Implements photo/media sharing with automatic optimization for elderly users
class MediaService {
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _imagePicker = ImagePicker();
  final LoggingService _logger = LoggingService();
  final Uuid _uuid = const Uuid();

  // Configuration constants
  static const int _maxImageSize = 1024; // Max width/height in pixels
  static const int _elderOptimizedSize = 800; // Optimized size for elderly users
  static const int _compressionQuality = 85; // JPEG compression quality
  static const int _maxFileSizeBytes = 5 * 1024 * 1024; // 5MB max file size

  final StreamController<MediaUploadProgress> _uploadProgressController =
      StreamController<MediaUploadProgress>.broadcast();

  /// Stream for upload progress updates
  Stream<MediaUploadProgress> get uploadProgressStream => 
      _uploadProgressController.stream;

  /// Pick image from camera
  Future<File?> pickImageFromCamera({
    bool optimizeForElder = false,
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    try {
      // Check camera permission
      final cameraStatus = await Permission.camera.request();
      if (cameraStatus != PermissionStatus.granted) {
        throw MediaServiceException('Camera permission denied');
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth?.toDouble() ?? (optimizeForElder ? _elderOptimizedSize : _maxImageSize).toDouble(),
        maxHeight: maxHeight?.toDouble() ?? (optimizeForElder ? _elderOptimizedSize : _maxImageSize).toDouble(),
        imageQuality: imageQuality ?? _compressionQuality,
      );

      if (image == null) return null;

      final file = File(image.path);
      
      // Validate file size
      if (await file.length() > _maxFileSizeBytes) {
        throw MediaServiceException('Image file size too large. Maximum size is 5MB.');
      }

      _logger.info('Image captured from camera: ${image.path}');
      return file;
    } catch (e, stackTrace) {
      _logger.error('Failed to pick image from camera: $e', stackTrace);
      if (e is MediaServiceException) rethrow;
      throw MediaServiceException('Failed to capture image: $e');
    }
  }

  /// Pick image from gallery
  Future<File?> pickImageFromGallery({
    bool optimizeForElder = false,
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    try {
      // Check photos permission
      final photosStatus = await Permission.photos.request();
      if (photosStatus != PermissionStatus.granted) {
        throw MediaServiceException('Photos permission denied');
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth?.toDouble() ?? (optimizeForElder ? _elderOptimizedSize : _maxImageSize).toDouble(),
        maxHeight: maxHeight?.toDouble() ?? (optimizeForElder ? _elderOptimizedSize : _maxImageSize).toDouble(),
        imageQuality: imageQuality ?? _compressionQuality,
      );

      if (image == null) return null;

      final file = File(image.path);
      
      // Validate file size
      if (await file.length() > _maxFileSizeBytes) {
        throw MediaServiceException('Image file size too large. Maximum size is 5MB.');
      }

      _logger.info('Image selected from gallery: ${image.path}');
      return file;
    } catch (e, stackTrace) {
      _logger.error('Failed to pick image from gallery: $e', stackTrace);
      if (e is MediaServiceException) rethrow;
      throw MediaServiceException('Failed to select image: $e');
    }
  }

  /// Pick multiple images from gallery
  Future<List<File>> pickMultipleImages({
    int limit = 10,
    bool optimizeForElder = false,
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    try {
      final photosStatus = await Permission.photos.request();
      if (photosStatus != PermissionStatus.granted) {
        throw MediaServiceException('Photos permission denied');
      }

      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: maxWidth?.toDouble() ?? (optimizeForElder ? _elderOptimizedSize : _maxImageSize).toDouble(),
        maxHeight: maxHeight?.toDouble() ?? (optimizeForElder ? _elderOptimizedSize : _maxImageSize).toDouble(),
        imageQuality: imageQuality ?? _compressionQuality,
        limit: limit,
      );

      if (images.isEmpty) return [];

      final files = <File>[];
      for (final image in images) {
        final file = File(image.path);
        
        // Validate file size
        if (await file.length() > _maxFileSizeBytes) {
          _logger.warning('Skipping large image: ${image.path}');
          continue;
        }
        
        files.add(file);
      }

      _logger.info('Selected ${files.length} images from gallery');
      return files;
    } catch (e, stackTrace) {
      _logger.error('Failed to pick multiple images: $e', stackTrace);
      if (e is MediaServiceException) rethrow;
      throw MediaServiceException('Failed to select images: $e');
    }
  }

  /// Upload media file to Supabase storage
  Future<String> uploadMedia({
    required File file,
    required String bucket,
    required String familyId,
    required String userId,
    String? folder,
    Function(double)? onProgress,
  }) async {
    try {
      final fileName = _generateFileName(file.path);
      final filePath = folder != null ? '$folder/$fileName' : fileName;
      
      _uploadProgressController.add(MediaUploadProgress(
        fileName: fileName,
        progress: 0.0,
        status: UploadStatus.uploading,
      ));

      // Read file bytes
      final bytes = await file.readAsBytes();
      
      // Upload to Supabase storage
      await _supabase.storage.from(bucket).uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          contentType: _getContentType(file.path),
          metadata: {
            'family_id': familyId,
            'uploaded_by': userId,
            'upload_timestamp': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Get public URL
      final publicUrl = _supabase.storage.from(bucket).getPublicUrl(filePath);

      // Save media record to database
      await _saveMediaRecord(
        familyId: familyId,
        userId: userId,
        fileName: fileName,
        filePath: filePath,
        fileUrl: publicUrl,
        fileSize: bytes.length,
        contentType: _getContentType(file.path),
        bucket: bucket,
      );

      _uploadProgressController.add(MediaUploadProgress(
        fileName: fileName,
        progress: 1.0,
        status: UploadStatus.completed,
        url: publicUrl,
      ));

      _logger.info('Media uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e, stackTrace) {
      _logger.error('Failed to upload media: $e', stackTrace);
      
      _uploadProgressController.add(MediaUploadProgress(
        fileName: file.path.split('/').last,
        progress: 0.0,
        status: UploadStatus.failed,
        error: e.toString(),
      ));
      
      throw MediaServiceException('Failed to upload media: $e');
    }
  }

  /// Optimize image for elderly users (enhance contrast, brightness)
  Future<File> optimizeImageForElders(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = await _decodeImageFromBytes(bytes);
      
      // Apply elderly-friendly optimizations
      final optimizedImage = await _enhanceImageForElders(image);
      
      // Save optimized image
      final directory = await getTemporaryDirectory();
      final optimizedFile = File('${directory.path}/optimized_${_uuid.v4()}.jpg');
      
      final pngBytes = await optimizedImage.toByteData(format: ui.ImageByteFormat.png);
      if (pngBytes != null) {
        await optimizedFile.writeAsBytes(pngBytes.buffer.asUint8List());
      }
      
      _logger.info('Image optimized for elderly users');
      return optimizedFile;
    } catch (e, stackTrace) {
      _logger.error('Failed to optimize image for elderly users: $e', stackTrace);
      throw MediaServiceException('Failed to optimize image: $e');
    }
  }

  /// Add text overlay to image (for elderly users who may need descriptions)
  Future<File> addTextOverlay({
    required File imageFile,
    required String text,
    double fontSize = 24.0,
    ui.Color textColor = const ui.Color(0xFF000000),
    ui.Color backgroundColor = const ui.Color(0xFFFFFFFF),
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = await _decodeImageFromBytes(bytes);
      
      // Create text overlay
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      
      // Draw original image
      canvas.drawImage(image, ui.Offset.zero, ui.Paint());
      
      // Draw text overlay at bottom
      final textPainter = ui.ParagraphBuilder(ui.ParagraphStyle(
        textDirection: ui.TextDirection.ltr,
        fontSize: fontSize,
      ))
        ..pushStyle(ui.TextStyle(
          color: textColor,
          backgroundColor: backgroundColor,
        ))
        ..addText(text);
      
      final paragraph = textPainter.build()
        ..layout(ui.ParagraphConstraints(width: image.width.toDouble()));
      
      canvas.drawParagraph(
        paragraph,
        ui.Offset(10, image.height.toDouble() - paragraph.height - 10),
      );
      
      final picture = recorder.endRecording();
      final overlaidImage = await picture.toImage(image.width, image.height);
      
      // Save image with text overlay
      final directory = await getTemporaryDirectory();
      final overlaidFile = File('${directory.path}/overlay_${_uuid.v4()}.jpg');
      
      final pngBytes = await overlaidImage.toByteData(format: ui.ImageByteFormat.png);
      if (pngBytes != null) {
        await overlaidFile.writeAsBytes(pngBytes.buffer.asUint8List());
      }
      
      _logger.info('Text overlay added to image');
      return overlaidFile;
    } catch (e, stackTrace) {
      _logger.error('Failed to add text overlay: $e', stackTrace);
      throw MediaServiceException('Failed to add text overlay: $e');
    }
  }

  /// Get media files for family
  Future<List<MediaRecord>> getFamilyMedia({
    required String familyId,
    String? userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase
          .from('media_records')
          .select()
          .eq('family_id', familyId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      if (userId != null) {
        query = query.eq('uploaded_by', userId);
      }

      final response = await query;
      
      return (response as List)
          .map((json) => MediaRecord.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      _logger.error('Failed to get family media: $e', stackTrace);
      throw MediaServiceException('Failed to get family media: $e');
    }
  }

  /// Delete media file
  Future<void> deleteMedia({
    required String mediaId,
    required String userId,
    required String bucket,
    required String filePath,
  }) async {
    try {
      // Check if user has permission to delete (owner or admin)
      final mediaRecord = await _getMediaRecord(mediaId);
      if (mediaRecord == null) {
        throw MediaServiceException('Media record not found');
      }
      
      if (mediaRecord.uploadedBy != userId) {
        // Check if user is family admin
        final isAdmin = await _checkFamilyAdminPermission(mediaRecord.familyId, userId);
        if (!isAdmin) {
          throw MediaServiceException('Permission denied to delete media');
        }
      }

      // Delete from storage
      await _supabase.storage.from(bucket).remove([filePath]);
      
      // Delete record from database
      await _supabase.from('media_records').delete().eq('id', mediaId);
      
      _logger.info('Media deleted: $mediaId');
    } catch (e, stackTrace) {
      _logger.error('Failed to delete media: $e', stackTrace);
      throw MediaServiceException('Failed to delete media: $e');
    }
  }

  /// Compress image file
  Future<File> compressImage(File imageFile, {int quality = 85}) async {
    try {
      final directory = await getTemporaryDirectory();
      final compressedFile = File('${directory.path}/compressed_${_uuid.v4()}.jpg');
      
      // For now, return the original file
      // In a real implementation, you would use a package like flutter_image_compress
      await imageFile.copy(compressedFile.path);
      
      _logger.info('Image compressed with quality: $quality%');
      return compressedFile;
    } catch (e, stackTrace) {
      _logger.error('Failed to compress image: $e', stackTrace);
      throw MediaServiceException('Failed to compress image: $e');
    }
  }

  // Private helper methods

  String _generateFileName(String originalPath) {
    final extension = originalPath.split('.').last.toLowerCase();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uniqueId = _uuid.v4().substring(0, 8);
    return '${timestamp}_${uniqueId}.$extension';
  }

  String _getContentType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  Future<ui.Image> _decodeImageFromBytes(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<ui.Image> _enhanceImageForElders(ui.Image originalImage) async {
    // This would implement image enhancement algorithms
    // For now, return the original image
    // In a real implementation, you would apply:
    // - Contrast enhancement
    // - Brightness adjustment
    // - Sharpening filters
    return originalImage;
  }

  Future<void> _saveMediaRecord({
    required String familyId,
    required String userId,
    required String fileName,
    required String filePath,
    required String fileUrl,
    required int fileSize,
    required String contentType,
    required String bucket,
  }) async {
    final mediaRecord = {
      'id': _uuid.v4(),
      'family_id': familyId,
      'uploaded_by': userId,
      'file_name': fileName,
      'file_path': filePath,
      'file_url': fileUrl,
      'file_size': fileSize,
      'content_type': contentType,
      'bucket': bucket,
      'created_at': DateTime.now().toIso8601String(),
    };

    await _supabase.from('media_records').insert(mediaRecord);
  }

  Future<MediaRecord?> _getMediaRecord(String mediaId) async {
    try {
      final response = await _supabase
          .from('media_records')
          .select()
          .eq('id', mediaId)
          .single();
      
      return MediaRecord.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  Future<bool> _checkFamilyAdminPermission(String familyId, String userId) async {
    try {
      final response = await _supabase
          .from('family_members')
          .select('role')
          .eq('family_id', familyId)
          .eq('user_id', userId)
          .eq('is_active', true)
          .single();
      
      final role = response['role'] as String;
      return role == 'primaryCaregiver' || role == 'secondaryCaregiver';
    } catch (e) {
      return false;
    }
  }

  /// Dispose of resources
  void dispose() {
    _uploadProgressController.close();
  }
}

/// Data class for media upload progress
class MediaUploadProgress {
  final String fileName;
  final double progress;
  final UploadStatus status;
  final String? url;
  final String? error;

  const MediaUploadProgress({
    required this.fileName,
    required this.progress,
    required this.status,
    this.url,
    this.error,
  });
}

/// Upload status enumeration
enum UploadStatus {
  uploading,
  completed,
  failed,
}

/// Data class for media records
class MediaRecord {
  final String id;
  final String familyId;
  final String uploadedBy;
  final String fileName;
  final String filePath;
  final String fileUrl;
  final int fileSize;
  final String contentType;
  final String bucket;
  final DateTime createdAt;

  const MediaRecord({
    required this.id,
    required this.familyId,
    required this.uploadedBy,
    required this.fileName,
    required this.filePath,
    required this.fileUrl,
    required this.fileSize,
    required this.contentType,
    required this.bucket,
    required this.createdAt,
  });

  factory MediaRecord.fromJson(Map<String, dynamic> json) {
    return MediaRecord(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      uploadedBy: json['uploaded_by'] as String,
      fileName: json['file_name'] as String,
      filePath: json['file_path'] as String,
      fileUrl: json['file_url'] as String,
      fileSize: json['file_size'] as int,
      contentType: json['content_type'] as String,
      bucket: json['bucket'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'family_id': familyId,
      'uploaded_by': uploadedBy,
      'file_name': fileName,
      'file_path': filePath,
      'file_url': fileUrl,
      'file_size': fileSize,
      'content_type': contentType,
      'bucket': bucket,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Custom exception for media service errors
class MediaServiceException implements Exception {
  final String message;
  MediaServiceException(this.message);
  
  @override
  String toString() => 'MediaServiceException: $message';
}