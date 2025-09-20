import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/elder_provider.dart';
import '../models/medication_model.dart';
import '../../../core/services/voice_service.dart';
import '../../../core/theme/app_theme.dart';

import '../widgets/medication_photo_widget.dart';
import '../../../services/storage/media_storage_service.dart';

import '../../../core/services/storage_service.dart';


class MedicationReminderScreen extends StatefulWidget {
  const MedicationReminderScreen({super.key});

  @override
  State<MedicationReminderScreen> createState() => _MedicationReminderScreenState();
}

class _MedicationReminderScreenState extends State<MedicationReminderScreen> {
  late VoiceService _voiceService;
  final ImagePicker _imagePicker = ImagePicker();
  File? _capturedImage;
  String? _capturedImageUrl;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    _voiceService = context.read<VoiceService>();
    await _voiceService.announceScreen('Medication Reminders');
    
    final elderProvider = context.read<ElderProvider>();
    
    // Announce next medication
    if (elderProvider.nextMedication != null) {
      await _voiceService.speak(
        'Your next medication is ${elderProvider.nextMedication!.name} '
        '${elderProvider.nextMedication!.dosage} '
        '${elderProvider.nextMedication!.getTimeUntilNext()}',
      );
    }
    
    // Register voice commands
    _voiceService.registerCommand('take medicine', () => _takeMedication());
    _voiceService.registerCommand('i took my medicine', () => _takeMedication());
    _voiceService.registerCommand('take photo', () => _takePhoto());
  }

  Future<void> _takeMedication() async {
    final elderProvider = context.read<ElderProvider>();
    if (elderProvider.nextMedication != null) {
      if (elderProvider.nextMedication!.requiresPhotoConfirmation) {
        await _takePhoto();
      }
      await _confirmMedicationTaken(elderProvider.nextMedication!);
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
      );
      
      if (photo != null) {
        setState(() {
          _capturedImage = File(photo.path);
        });
        try {
          final url = await MediaStorageService().uploadFile(
            file: File(photo.path),
            bucket: MediaStorageService.bucketMedicationPhotos,
            contentType: 'image/jpeg',
          );
          setState(() => _capturedImageUrl = url);
        } catch (_) {}
        await _voiceService.confirmAction('Photo taken');
      }
    } catch (e) {
      await _voiceService.announceError('Could not access camera');
    }
  }

  Future<void> _confirmMedicationTaken(Medication medication) async {
    final elderProvider = context.read<ElderProvider>();

    String? photoUrl;
    if (_capturedImage != null) {
      await _voiceService.speak('Uploading confirmation photo');
      photoUrl = await StorageService.uploadMedicationPhoto(
        file: _capturedImage!,
        elderId: elderProvider.userId,
        medicationId: medication.id,
      );
    }
    
    await elderProvider.markMedicationTaken(
      medication.id,

      photoUrl: _capturedImageUrl ?? _capturedImage?.path,

      photoUrl: photoUrl,

    );
    
    await _voiceService.confirmAction('Medication marked as taken');
    
    setState(() {
      _capturedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 32, color: AppTheme.darkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Medications',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkText,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Consumer<ElderProvider>(
          builder: (context, elderProvider, child) {
            if (elderProvider.isLoadingMedications) {
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 3),
              );
            }

            if (elderProvider.medications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.medication,
                      size: 80,
                      color: AppTheme.neutralGray,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No medications scheduled',
                      style: TextStyle(
                        fontSize: 24,
                        color: AppTheme.darkText,
                      ),
                    ),
                  ],
                ),
              );
            }

            // Show only the next/current medication in a simplified view
            final nextMedication = elderProvider.nextMedication;
            if (nextMedication == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.medication,
                      size: 80,
                      color: AppTheme.neutralGray,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No medications scheduled',
                      style: TextStyle(
                        fontSize: 24,
                        color: AppTheme.darkText,
                      ),
                    ),
                  ],
                ),
              );
            }
            
            return _SimplifiedMedicationView(
              medication: nextMedication,
              onTake: () => _confirmMedicationTaken(nextMedication),
              onTakePhoto: nextMedication.requiresPhotoConfirmation ? _takePhoto : null,
              capturedImage: _capturedImage,
            );
          },
        ),
      ),
    );
  }
}

class _SimplifiedMedicationView extends StatelessWidget {
  final Medication medication;
  final VoidCallback onTake;
  final VoidCallback? onTakePhoto;
  final File? capturedImage;

  const _SimplifiedMedicationView({
    required this.medication,
    required this.onTake,
    this.onTakePhoto,
    this.capturedImage,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          
          // Medication Image Placeholder - matching design
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
            child: medication.photoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      medication.photoUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                : CustomPaint(
                    painter: _XPainter(),
                    size: const Size(200, 200),
                  ),
          ),
          const SizedBox(height: 40),
          
          // Medication Name - Large and Bold
          Text(
            medication.name,
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Dosage and Time - Side by Side
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                medication.dosage,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.darkText,
                ),
              ),
              const SizedBox(width: 40),
              Text(
                timeFormat.format(medication.nextDoseTime),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 60),
          
          // Take Now Button - Large and Prominent
          Container(
            width: double.infinity,
            height: 80,
            margin: const EdgeInsets.only(bottom: 16),
            child: ElevatedButton(
              onPressed: onTake,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.darkText,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'TAKE NOW',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          
          // Taken Button - Outlined
          Container(
            width: double.infinity,
            height: 80,
            margin: const EdgeInsets.only(bottom: 32),
            child: OutlinedButton(
              onPressed: onTake, // Same action for now
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.darkText,
                side: const BorderSide(
                  color: AppTheme.darkText,
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'TAKEN',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          
          // Take Photo to Confirm
          if (medication.requiresPhotoConfirmation && onTakePhoto != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.darkText,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: IconButton(
                    onPressed: onTakePhoto,
                    icon: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Take Photo to Confirm',
                  style: TextStyle(
                    fontSize: 20,
                    color: AppTheme.darkText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
          
          const Spacer(),
          
          // Next Medication Time
          Text(
            'Next: 2:00 PM', // This should be dynamic based on next medication
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.neutralGray,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// Custom painter for the X in the medication placeholder
class _XPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const margin = 40.0;
    
    // Draw X
    canvas.drawLine(
      Offset(margin, margin),
      Offset(size.width - margin, size.height - margin),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - margin, margin),
      Offset(margin, size.height - margin),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}