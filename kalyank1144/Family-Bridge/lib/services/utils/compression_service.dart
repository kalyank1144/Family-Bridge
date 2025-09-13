import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

class CompressionService {
  static final CompressionService _instance = CompressionService._internal();
  factory CompressionService() => _instance;
  CompressionService._internal();

  final Logger _logger = Logger();
  
  // Compression settings
  static const int _maxImageWidth = 1920;
  static const int _maxImageHeight = 1080;
  static const int _thumbnailSize = 200;
  static const int _jpegQuality = 85;
  static const int _jpegQualityLow = 60;
  static const int _webpQuality = 80;
  
  // Audio settings
  static const int _audioBitrate = 64000; // 64 kbps for voice
  static const int _audioSampleRate = 22050;
  
  Future<Uint8List?> compressImage({
    required Uint8List imageData,
    int? maxWidth,
    int? maxHeight,
    int? quality,
    bool generateThumbnail = false,
    bool useWebP = true,
  }) async {
    try {
      _logger.d('Compressing image: ${imageData.length} bytes');
      
      // Decode image
      final image = img.decodeImage(imageData);
      if (image == null) {
        _logger.e('Failed to decode image');
        return null;
      }
      
      // Calculate new dimensions
      int targetWidth = maxWidth ?? _maxImageWidth;
      int targetHeight = maxHeight ?? _maxImageHeight;
      
      if (image.width > targetWidth || image.height > targetHeight) {
        final aspectRatio = image.width / image.height;
        
        if (aspectRatio > 1) {
          // Landscape
          targetHeight = (targetWidth / aspectRatio).round();
        } else {
          // Portrait
          targetWidth = (targetHeight * aspectRatio).round();
        }
        
        // Resize image
        final resized = img.copyResize(
          image,
          width: targetWidth,
          height: targetHeight,
          interpolation: img.Interpolation.linear,
        );
        
        imageData = Uint8List.fromList(
          useWebP 
              ? img.encodeWebP(resized, quality: quality ?? _webpQuality)
              : img.encodeJpg(resized, quality: quality ?? _jpegQuality)
        );
      } else {
        // Just re-encode for compression
        imageData = Uint8List.fromList(
          useWebP 
              ? img.encodeWebP(image, quality: quality ?? _webpQuality)
              : img.encodeJpg(image, quality: quality ?? _jpegQuality)
        );
      }
      
      _logger.d('Image compressed to: ${imageData.length} bytes');
      
      return imageData;
      
    } catch (e) {
      _logger.e('Image compression failed', error: e);
      return null;
    }
  }
  
  Future<File?> compressImageFile({
    required File file,
    int? maxWidth,
    int? maxHeight,
    int? quality,
    bool keepExif = false,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        minWidth: maxWidth ?? _maxImageWidth,
        minHeight: maxHeight ?? _maxImageHeight,
        quality: quality ?? _jpegQuality,
        keepExif: keepExif,
        format: CompressFormat.jpeg,
      );
      
      if (result != null) {
        final originalSize = await file.length();
        final compressedSize = await File(result.path).length();
        
        _logger.i('Image file compressed: ${originalSize ~/ 1024}KB -> ${compressedSize ~/ 1024}KB');
        
        return File(result.path);
      }
      
      return null;
      
    } catch (e) {
      _logger.e('Image file compression failed', error: e);
      return null;
    }
  }
  
  Future<Uint8List?> generateThumbnail({
    required Uint8List imageData,
    int size = _thumbnailSize,
  }) async {
    try {
      final image = img.decodeImage(imageData);
      if (image == null) return null;
      
      // Generate square thumbnail
      final thumbnail = img.copyResizeCropSquare(image, size: size);
      
      // Encode as JPEG with lower quality
      return Uint8List.fromList(
        img.encodeJpg(thumbnail, quality: 70)
      );
      
    } catch (e) {
      _logger.e('Thumbnail generation failed', error: e);
      return null;
    }
  }
  
  Future<List<Uint8List>> generateImageSizes({
    required Uint8List imageData,
    bool includeThumbnail = true,
    bool includeSmall = true,
    bool includeMedium = true,
    bool includeLarge = true,
  }) async {
    final sizes = <Uint8List>[];
    
    try {
      final image = img.decodeImage(imageData);
      if (image == null) return sizes;
      
      if (includeThumbnail) {
        final thumbnail = img.copyResizeCropSquare(image, size: 200);
        sizes.add(Uint8List.fromList(img.encodeJpg(thumbnail, quality: 70)));
      }
      
      if (includeSmall) {
        final small = img.copyResize(image, width: 480);
        sizes.add(Uint8List.fromList(img.encodeJpg(small, quality: 75)));
      }
      
      if (includeMedium) {
        final medium = img.copyResize(image, width: 960);
        sizes.add(Uint8List.fromList(img.encodeJpg(medium, quality: 80)));
      }
      
      if (includeLarge) {
        final large = img.copyResize(image, width: 1920);
        sizes.add(Uint8List.fromList(img.encodeJpg(large, quality: 85)));
      }
      
      return sizes;
      
    } catch (e) {
      _logger.e('Failed to generate image sizes', error: e);
      return sizes;
    }
  }
  
  Uint8List compressJson(Map<String, dynamic> data) {
    try {
      final jsonString = json.encode(data);
      final bytes = utf8.encode(jsonString);
      
      // Use gzip compression
      final compressed = gzip.encode(bytes);
      
      _logger.d('JSON compressed: ${bytes.length} -> ${compressed.length} bytes');
      
      return Uint8List.fromList(compressed);
      
    } catch (e) {
      _logger.e('JSON compression failed', error: e);
      return Uint8List(0);
    }
  }
  
  Map<String, dynamic>? decompressJson(Uint8List compressedData) {
    try {
      final decompressed = gzip.decode(compressedData);
      final jsonString = utf8.decode(decompressed);
      return json.decode(jsonString);
      
    } catch (e) {
      _logger.e('JSON decompression failed', error: e);
      return null;
    }
  }
  
  Future<File?> compressAudioFile({
    required File file,
    int bitrate = _audioBitrate,
    int sampleRate = _audioSampleRate,
    bool trimSilence = true,
  }) async {
    try {
      // This would use FFmpeg or similar for actual audio compression
      // For now, returning placeholder
      _logger.d('Audio compression requested for: ${file.path}');
      
      // In production, you would:
      // 1. Use flutter_ffmpeg or similar package
      // 2. Reduce bitrate and sample rate
      // 3. Trim silence from beginning and end
      // 4. Convert to efficient format (like AAC or Opus)
      
      return file;
      
    } catch (e) {
      _logger.e('Audio compression failed', error: e);
      return null;
    }
  }
  
  Future<String> getCompressionRecommendation({
    required int fileSize,
    required String fileType,
    required bool isWifi,
    required int availableStorage,
  }) async {
    // Provide intelligent compression recommendations
    
    if (availableStorage < 100 * 1024 * 1024) {
      // Less than 100MB available
      return 'aggressive';
    }
    
    if (!isWifi && fileSize > 5 * 1024 * 1024) {
      // On mobile data and file > 5MB
      return 'high';
    }
    
    if (fileType == 'image') {
      if (fileSize > 2 * 1024 * 1024) {
        return 'medium';
      }
    }
    
    if (fileType == 'video') {
      if (fileSize > 10 * 1024 * 1024) {
        return 'high';
      }
    }
    
    return 'low';
  }
  
  int calculateCompressedSize({
    required int originalSize,
    required String compressionLevel,
  }) {
    switch (compressionLevel) {
      case 'aggressive':
        return (originalSize * 0.2).round();
      case 'high':
        return (originalSize * 0.4).round();
      case 'medium':
        return (originalSize * 0.6).round();
      case 'low':
        return (originalSize * 0.8).round();
      default:
        return originalSize;
    }
  }
  
  Future<Map<String, dynamic>> analyzeImage(Uint8List imageData) async {
    try {
      final image = img.decodeImage(imageData);
      if (image == null) return {};
      
      return {
        'width': image.width,
        'height': image.height,
        'size': imageData.length,
        'format': _detectImageFormat(imageData),
        'hasAlpha': image.channels == img.Channels.rgba,
        'isLandscape': image.width > image.height,
        'aspectRatio': (image.width / image.height).toStringAsFixed(2),
        'megapixels': ((image.width * image.height) / 1000000).toStringAsFixed(2),
      };
      
    } catch (e) {
      _logger.e('Image analysis failed', error: e);
      return {};
    }
  }
  
  String _detectImageFormat(Uint8List data) {
    if (data.length < 4) return 'unknown';
    
    // Check magic numbers
    if (data[0] == 0xFF && data[1] == 0xD8) return 'jpeg';
    if (data[0] == 0x89 && data[1] == 0x50 && data[2] == 0x4E && data[3] == 0x47) return 'png';
    if (data[0] == 0x47 && data[1] == 0x49 && data[2] == 0x46) return 'gif';
    if (data[0] == 0x52 && data[1] == 0x49 && data[2] == 0x46 && data[3] == 0x46) {
      if (data.length > 11 && data[8] == 0x57 && data[9] == 0x45 && data[10] == 0x42 && data[11] == 0x50) {
        return 'webp';
      }
    }
    
    return 'unknown';
  }
  
  Future<void> cleanupTempFiles() async {
    try {
      final dir = await getTemporaryDirectory();
      final tempFiles = dir.listSync()
          .where((entity) => entity.path.contains('compressed_'))
          .toList();
      
      for (final file in tempFiles) {
        await file.delete();
      }
      
      _logger.d('Cleaned up ${tempFiles.length} temporary compression files');
      
    } catch (e) {
      _logger.e('Failed to cleanup temp files', error: e);
    }
  }
}