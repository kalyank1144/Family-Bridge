import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';

import 'package:family_bridge/features/chat/services/media_service.dart';

class PhotoSharingProvider extends ChangeNotifier {
  final MediaService _media = MediaService();
  final List<String> _photos = [];
  bool _loading = false;
  String _selectedFilter = 'none';

  List<String> get photos => List.unmodifiable(_photos);
  bool get isLoading => _loading;
  String get selectedFilter => _selectedFilter;

  Future<void> loadRecentPhotos() async {
    // Load some sample photos for demo purposes
    _photos.addAll([
      'https://picsum.photos/400/600?random=1',
      'https://picsum.photos/400/600?random=2',
      'https://picsum.photos/400/600?random=3',
      'https://picsum.photos/400/600?random=4',
      'https://picsum.photos/400/600?random=5',
      'https://picsum.photos/400/600?random=6',
    ]);
    notifyListeners();
  }

  Future<void> captureFromCamera() async {
    _loading = true;
    notifyListeners();
    
    try {
      final file = await _media.pickImage(source: ImageSource.camera);
      if (file != null) {
        // Upload image and get URL
        final url = await _media.uploadImage(file);
        _photos.insert(0, url);
      }
    } catch (e) {
      // For demo purposes, add a sample image
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _photos.insert(0, 'https://picsum.photos/400/600?random=$timestamp');
    }
    
    _loading = false;
    notifyListeners();
  }

  Future<void> pickFromGallery() async {
    _loading = true;
    notifyListeners();
    
    try {
      final file = await _media.pickImage(source: ImageSource.gallery);
      if (file != null) {
        // Upload image and get URL
        final url = await _media.uploadImage(file);
        _photos.insert(0, url);
      }
    } catch (e) {
      // For demo purposes, add a sample image
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _photos.insert(0, 'https://picsum.photos/400/600?random=$timestamp');
    }
    
    _loading = false;
    notifyListeners();
  }

  void setFilter(String filterId) {
    _selectedFilter = filterId;
    notifyListeners();
  }

  Future<void> applyFilter(String photoUrl, String filterId) async {
    // In a real app, this would apply the filter to the image
    // For now, just update the selected filter
    _selectedFilter = filterId;
    notifyListeners();
  }

  Future<void> sharePhoto(String photoUrl, {String? caption}) async {
    // In a real app, this would share the photo with the family
    // For now, just simulate the action
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void removePhoto(String photoUrl) {
    _photos.remove(photoUrl);
    notifyListeners();
  }
}