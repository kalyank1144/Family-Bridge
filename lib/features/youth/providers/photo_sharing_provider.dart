import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../chat/services/media_service.dart';

class PhotoSharingProvider extends ChangeNotifier {
  final MediaService _media = MediaService();
  final List<String> _photos = [];
  bool _loading = false;

  List<String> get photos => List.unmodifiable(_photos);
  bool get isLoading => _loading;

  Future<void> captureFromCamera() async {
    _loading = true;
    notifyListeners();
    final url = await _media.pickImage(source: ImageSource.camera);
    if (url != null) _photos.insert(0, url);
    _loading = false;
    notifyListeners();
  }

  Future<void> pickFromGallery() async {
    _loading = true;
    notifyListeners();
    final url = await _media.pickImage(source: ImageSource.gallery);
    if (url != null) _photos.insert(0, url);
    _loading = false;
    notifyListeners();
  }
}