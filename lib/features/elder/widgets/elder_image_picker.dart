import 'dart:io';

import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:family_bridge/core/theme/app_theme.dart';
import 'package:family_bridge/services/storage/media_storage_service.dart';

class ElderImagePicker extends StatefulWidget {
  final String bucket;
  final void Function(String url)? onUploaded;
  final void Function(File file)? onCapturedLocal;
  final String buttonText;
  final IconData buttonIcon;

  const ElderImagePicker({
    super.key,
    required this.bucket,
    this.onUploaded,
    this.onCapturedLocal,
    this.buttonText = 'Take Photo',
    this.buttonIcon = Icons.camera_alt,
  });

  @override
  State<ElderImagePicker> createState() => _ElderImagePickerState();
}

class _ElderImagePickerState extends State<ElderImagePicker> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  double _progress = 0;
  File? _preview;
  String? _uploadedUrl;

  Future<void> _takePhoto() async {
    final hasPerm = await Permission.camera.request();
    if (!hasPerm.isGranted) return;

    final xfile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (xfile == null) return;

    final file = File(xfile.path);
    setState(() => _preview = file);
    widget.onCapturedLocal?.call(file);

    setState(() {
      _isUploading = true;
      _progress = 0;
    });

    try {
      final url = await MediaStorageService().uploadFile(
        file: file,
        bucket: widget.bucket,
        contentType: 'image/jpeg',
        onProgress: (p) => setState(() => _progress = p),
      );
      setState(() => _uploadedUrl = url);
      widget.onUploaded?.call(url);
    } catch (e) {
      // Kept in queue for offline - UI can reflect pending state
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
              image: DecorationImage(
                image: FileImage(_preview!),
                fit: BoxFit.cover,
              ),
            ),
          ),
        if (_isUploading) ...[
          const SizedBox(height: 12),
          LinearProgressIndicator(value: _progress == 0 ? null : _progress),
        ],
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _takePhoto,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            minimumSize: const Size(double.infinity, 72),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          icon: Icon(widget.buttonIcon, size: 28, color: Colors.white),
          label: Text(
            _uploadedUrl != null ? 'Photo Captured ✓' : widget.buttonText,
            style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
