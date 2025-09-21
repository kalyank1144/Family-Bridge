import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../chat/services/media_service.dart';
import '../../shared/services/logging_service.dart';

/// Provider for managing youth photo sharing functionality
/// Integrates MediaService with Flutter UI layer for youth interface
class PhotoSharingProvider extends ChangeNotifier {
  final MediaService _mediaService = MediaService();
  final LoggingService _logger = LoggingService();

  List<MediaRecord> _familyPhotos = [];
  bool _isLoading = false;
  bool _isUploading = false;
  String? _error;
  double _uploadProgress = 0.0;
  String? _currentFamilyId;
  String? _currentUserId;

  // Getters
  List<MediaRecord> get familyPhotos => _familyPhotos;
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get error => _error;
  double get uploadProgress => _uploadProgress;

  /// Initialize the provider
  Future<void> initialize(String familyId, String userId) async {
    _currentFamilyId = familyId;
    _currentUserId = userId;
    _setLoading(true);
    _clearError();

    try {
      // Subscribe to upload progress
      _mediaService.uploadProgressStream.listen(_onUploadProgress);
      
      // Load family photos
      await _loadFamilyPhotos();
      
      _logger.info('PhotoSharingProvider initialized for family: $familyId');
    } catch (e, stackTrace) {
      _setError('Failed to initialize photo sharing: $e');
      _logger.error('PhotoSharingProvider initialization failed: $e', stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  /// Pick image from camera
  Future<File?> pickFromCamera({bool optimizeForElder = true}) async {
    _clearError();

    try {
      final imageFile = await _mediaService.pickImageFromCamera(
        optimizeForElder: optimizeForElder,
      );
      
      if (imageFile != null) {
        _logger.info('Image picked from camera via provider');
      }
      
      return imageFile;
    } catch (e, stackTrace) {
      _setError('Failed to pick image from camera: $e');
      _logger.error('Failed to pick image from camera via provider: $e', stackTrace);
      return null;
    }
  }

  /// Pick image from gallery
  Future<File?> pickFromGallery({bool optimizeForElder = true}) async {
    _clearError();

    try {
      final imageFile = await _mediaService.pickImageFromGallery(
        optimizeForElder: optimizeForElder,
      );
      
      if (imageFile != null) {
        _logger.info('Image picked from gallery via provider');
      }
      
      return imageFile;
    } catch (e, stackTrace) {
      _setError('Failed to pick image from gallery: $e');
      _logger.error('Failed to pick image from gallery via provider: $e', stackTrace);
      return null;
    }
  }

  /// Pick multiple images from gallery
  Future<List<File>> pickMultipleImages({
    int limit = 5,
    bool optimizeForElder = true,
  }) async {
    _clearError();

    try {
      final imageFiles = await _mediaService.pickMultipleImages(
        limit: limit,
        optimizeForElder: optimizeForElder,
      );
      
      _logger.info('${imageFiles.length} images picked from gallery via provider');
      return imageFiles;
    } catch (e, stackTrace) {
      _setError('Failed to pick multiple images: $e');
      _logger.error('Failed to pick multiple images via provider: $e', stackTrace);
      return [];
    }
  }

  /// Share photo with family
  Future<bool> sharePhoto({
    required File imageFile,
    String? caption,
    bool optimizeForElders = true,
  }) async {
    if (_currentFamilyId == null || _currentUserId == null) {
      _setError('Family or user not initialized');
      return false;
    }

    _setUploading(true);
    _clearError();

    try {
      File processedImage = imageFile;
      
      // Optimize image for elderly users if requested
      if (optimizeForElders) {
        processedImage = await _mediaService.optimizeImageForElders(imageFile);
      }
      
      // Add text overlay if caption provided
      if (caption != null && caption.isNotEmpty) {
        processedImage = await _mediaService.addTextOverlay(
          imageFile: processedImage,
          text: caption,
          fontSize: 24.0,
        );
      }

      // Upload to family photos bucket
      await _mediaService.uploadMedia(
        file: processedImage,
        bucket: 'family-photos',
        familyId: _currentFamilyId!,
        userId: _currentUserId!,
        folder: 'shared',
        onProgress: (progress) {
          _uploadProgress = progress;
          notifyListeners();
        },
      );
      
      // Refresh family photos
      await _loadFamilyPhotos();
      notifyListeners();
      
      _logger.info('Photo shared successfully via provider');
      return true;
    } catch (e, stackTrace) {
      _setError('Failed to share photo: $e');
      _logger.error('Failed to share photo via provider: $e', stackTrace);
      return false;
    } finally {
      _setUploading(false);
      _uploadProgress = 0.0;
    }
  }

  /// Share multiple photos with family
  Future<bool> shareMultiplePhotos({
    required List<File> imageFiles,
    String? caption,
    bool optimizeForElders = true,
  }) async {
    if (_currentFamilyId == null || _currentUserId == null) {
      _setError('Family or user not initialized');
      return false;
    }

    _setUploading(true);
    _clearError();

    try {
      int completedUploads = 0;
      
      for (final imageFile in imageFiles) {
        File processedImage = imageFile;
        
        // Optimize for elderly users
        if (optimizeForElders) {
          processedImage = await _mediaService.optimizeImageForElders(imageFile);
        }
        
        // Add caption as overlay if provided
        if (caption != null && caption.isNotEmpty) {
          processedImage = await _mediaService.addTextOverlay(
            imageFile: processedImage,
            text: caption,
            fontSize: 24.0,
          );
        }

        await _mediaService.uploadMedia(
          file: processedImage,
          bucket: 'family-photos',
          familyId: _currentFamilyId!,
          userId: _currentUserId!,
          folder: 'shared',
        );
        
        completedUploads++;
        _uploadProgress = completedUploads / imageFiles.length;
        notifyListeners();
      }
      
      // Refresh family photos
      await _loadFamilyPhotos();
      notifyListeners();
      
      _logger.info('${imageFiles.length} photos shared successfully via provider');
      return true;
    } catch (e, stackTrace) {
      _setError('Failed to share photos: $e');
      _logger.error('Failed to share multiple photos via provider: $e', stackTrace);
      return false;
    } finally {
      _setUploading(false);
      _uploadProgress = 0.0;
    }
  }

  /// Delete photo
  Future<bool> deletePhoto(String mediaId, String bucket, String filePath) async {
    if (_currentUserId == null) {
      _setError('User not initialized');
      return false;
    }

    _clearError();

    try {
      await _mediaService.deleteMedia(
        mediaId: mediaId,
        userId: _currentUserId!,
        bucket: bucket,
        filePath: filePath,
      );
      
      await _loadFamilyPhotos();
      notifyListeners();
      
      _logger.info('Photo deleted via provider: $mediaId');
      return true;
    } catch (e, stackTrace) {
      _setError('Failed to delete photo: $e');
      _logger.error('Failed to delete photo via provider: $e', stackTrace);
      return false;
    }
  }

  /// Get photos uploaded by specific user
  List<MediaRecord> getPhotosByUser(String userId) {
    return _familyPhotos.where((photo) => photo.uploadedBy == userId).toList();
  }

  /// Get recent photos (last 30 days)
  List<MediaRecord> get recentPhotos {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    return _familyPhotos.where((photo) => 
        photo.createdAt.isAfter(cutoffDate)).toList();
  }

  /// Refresh photo data
  Future<void> refresh() async {
    _setLoading(true);
    await _loadFamilyPhotos();
    _setLoading(false);
  }

  // Private helper methods

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setUploading(bool uploading) {
    _isUploading = uploading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _loadFamilyPhotos() async {
    if (_currentFamilyId == null) return;

    try {
      final photos = await _mediaService.getFamilyMedia(
        familyId: _currentFamilyId!,
        limit: 100,
      );
      
      _familyPhotos = photos;
    } catch (e) {
      _logger.warning('Failed to load family photos: $e');
    }
  }

  void _onUploadProgress(MediaUploadProgress progress) {
    _uploadProgress = progress.progress;
    
    if (progress.status == UploadStatus.failed) {
      _setError(progress.error ?? 'Upload failed');
    }
    
    notifyListeners();
  }

  @override
  void dispose() {
    _mediaService.dispose();
    super.dispose();
  }
}