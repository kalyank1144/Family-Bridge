import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/storage/media_storage_service.dart';

class MedicationPhotoWidget extends StatefulWidget {
  final String medicationId;
  final void Function(String url)? onUploaded;

  const MedicationPhotoWidget({
    super.key,
    required this.medicationId,
    this.onUploaded,
  });

  @override
  State<MedicationPhotoWidget> createState() => _MedicationPhotoWidgetState();
}

class _MedicationPhotoWidgetState extends State<MedicationPhotoWidget> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  double _progress = 0;
  File? _preview;
  String? _url;

  Future<void> _capture() async {
    final perm = await Permission.camera.request();
    if (!perm.isGranted) return;

    final x = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
      preferredCameraDevice: CameraDevice.front,
    );
    if (x == null) return;

    final file = File(x.path);
    setState(() => _preview = file);

    setState(() {
      _isUploading = true;
      _progress = 0;
    });

    try {
      final url = await MediaStorageService().uploadFile(
        file: file,
        bucket: MediaStorageService.bucketMedicationPhotos,
        contentType: 'image/jpeg',
        onProgress: (p) => setState(() => _progress = p),
      );
      setState(() => _url = url);
      widget.onUploaded?.call(url);
    } catch (_) {
      // queued offline
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_preview != null)
          Container(
            height: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(image: FileImage(_preview!), fit: BoxFit.cover),
            ),
          ),
        if (_isUploading) ...[
          const SizedBox(height: 12),
          LinearProgressIndicator(value: _progress == 0 ? null : _progress),
        ],
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _capture,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            minimumSize: const Size(double.infinity, 72),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          icon: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
          label: Text(
            _url != null ? 'Photo Captured ✓' : 'Take Photo',
            style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
