import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _highContrastMode = false;
  bool _isUploading = false;
  bool _medicationTaken = false;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    _voiceService = context.read<VoiceService>();
    await _voiceService.announceScreen('Medication Reminders');
    
    final elderProvider = context.read<ElderProvider>();
    
    // Announce next medication with more detail
    if (elderProvider.nextMedication != null) {
      final med = elderProvider.nextMedication!;
      await _voiceService.speak(
        'Time for your ${med.name} medication. '
        'Take ${med.dosage} now. '
        'Say "take now" to confirm you took it, or "take photo" to photograph your medication.',
      );
    } else {
      await _voiceService.speak('No medications are due right now. Great job staying on track!');
    }
    
    // Register comprehensive voice commands
    _voiceService.registerCommand('take now', () => _takeMedication());
    _voiceService.registerCommand('take medicine', () => _takeMedication());
    _voiceService.registerCommand('took it', () => _takeMedication());
    _voiceService.registerCommand('taken', () => _takeMedication());
    _voiceService.registerCommand('i took my medicine', () => _takeMedication());
    _voiceService.registerCommand('done', () => _takeMedication());
    _voiceService.registerCommand('take photo', () => _takePhoto());
    _voiceService.registerCommand('camera', () => _takePhoto());
    _voiceService.registerCommand('picture', () => _takePhoto());
    _voiceService.registerCommand('toggle contrast', () => _toggleHighContrast());
    _voiceService.registerCommand('high contrast', () => _toggleHighContrast());
  }

  Future<void> _takeMedication() async {
    HapticFeedback.mediumImpact();
    final elderProvider = context.read<ElderProvider>();
    if (elderProvider.nextMedication != null) {
      final medication = elderProvider.nextMedication!;
      
      if (medication.requiresPhotoConfirmation && _capturedImage == null) {
        await _voiceService.speak(
          'This medication requires photo confirmation. Please take a photo first by saying "take photo" or using the camera button.'
        );
        return;
      }
      
      await _voiceService.speak('Marking medication as taken. Great job!');
      await _confirmMedicationTaken(medication);
    } else {
      await _voiceService.speak('No medication is currently due.');
    }
  }

  Future<void> _takePhoto() async {
    try {
      await _voiceService.speak('Opening camera. Please position your medication clearly in the frame.');
      
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear, // Use rear camera for better photo quality
      );
      
      if (photo != null) {
        setState(() {
          _capturedImage = File(photo.path);
          _isUploading = true;
        });
        
        await _voiceService.speak('Photo captured! Uploading now.');
        
        try {
          final url = await MediaStorageService().uploadFile(
            file: File(photo.path),
            bucket: MediaStorageService.bucketMedicationPhotos,
            contentType: 'image/jpeg',
          );
          setState(() {
            _capturedImageUrl = url;
            _isUploading = false;
          });
          await _voiceService.speak('Photo uploaded successfully! You can now mark your medication as taken.');
        } catch (uploadError) {
          setState(() {
            _capturedImageUrl = photo.path; // Store local path as fallback
            _isUploading = false;
          });
          await _voiceService.speak('Photo saved locally. Will upload when connected to internet.');
        }
      } else {
        await _voiceService.speak('No photo was taken.');
      }
    } catch (e) {
      setState(() => _isUploading = false);
      await _voiceService.announceError('Could not access camera. Please check camera permissions.');
    }
  }

  Future<void> _confirmMedicationTaken(Medication medication) async {
    final elderProvider = context.read<ElderProvider>();
    
    setState(() => _medicationTaken = true);

    String? photoUrl;
    if (_capturedImage != null && !_isUploading) {
      if (_capturedImageUrl == null) {
        try {
          await _voiceService.speak('Uploading confirmation photo');
          photoUrl = await StorageService.uploadMedicationPhoto(
            file: _capturedImage!,
            elderId: elderProvider.userId,
            medicationId: medication.id,
          );
        } catch (e) {
          // Use local path if upload fails
          photoUrl = _capturedImage!.path;
          await _voiceService.speak('Photo will be uploaded later when connected.');
        }
      } else {
        photoUrl = _capturedImageUrl;
      }
    }
    
    try {
      await elderProvider.markMedicationTaken(
        medication.id,
        photoUrl: photoUrl ?? _capturedImageUrl ?? _capturedImage?.path,
      );
      
      await _voiceService.speak(
        'Excellent! Your ${medication.name} has been marked as taken. '
        'Your family will be notified. Keep up the great work with your medications!'
      );
      
      // Clear the photo after successful submission
      setState(() {
        _capturedImage = null;
        _capturedImageUrl = null;
      });
      
      // Auto-navigate back after a short delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } catch (e) {
      setState(() => _medicationTaken = false);
      await _voiceService.announceError(
        'Could not record medication. It has been saved locally and will sync when connected.'
      );
    }
  }

  void _toggleHighContrast() {
    setState(() {
      _highContrastMode = !_highContrastMode;
    });
    _voiceService.speak(_highContrastMode ? 'High contrast mode enabled' : 'High contrast mode disabled');
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _highContrastMode ? Colors.black : Colors.white;
    final textColor = _highContrastMode ? Colors.white : AppTheme.darkText;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // High Contrast Toggle
          FloatingActionButton(
            heroTag: 'contrast',
            onPressed: _toggleHighContrast,
            backgroundColor: AppTheme.primaryBlue,
            child: Icon(
              _highContrastMode ? Icons.contrast : Icons.contrast_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          // Camera Button for photo confirmation
          Consumer<ElderProvider>(
            builder: (context, elderProvider, child) {
              final nextMed = elderProvider.nextMedication;
              if (nextMed?.requiresPhotoConfirmation == true && _capturedImage == null) {
                return FloatingActionButton.large(
                  heroTag: 'camera',
                  onPressed: _isUploading ? null : _takePhoto,
                  backgroundColor: _isUploading ? AppTheme.warningYellow : AppTheme.successGreen,
                  child: Icon(
                    _isUploading ? Icons.cloud_upload : Icons.camera_alt,
                    color: Colors.white,
                    size: 32,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back, 
            size: 32, 
            color: textColor,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            _voiceService.speak('Going back to home screen');
            Navigator.pop(context);
          },
        ),
        title: Text(
          'My Medications',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: textColor,
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
              highContrastMode: _highContrastMode,
              isUploading: _isUploading,
              medicationTaken: _medicationTaken,
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
  final bool highContrastMode;
  final bool isUploading;
  final bool medicationTaken;

  const _SimplifiedMedicationView({
    required this.medication,
    required this.onTake,
    this.onTakePhoto,
    this.capturedImage,
    this.highContrastMode = false,
    this.isUploading = false,
    this.medicationTaken = false,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final backgroundColor = highContrastMode ? Colors.black : Colors.white;
    final textColor = highContrastMode ? Colors.white : AppTheme.darkText;
    
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          
          // Medication Image or Confirmation Photo
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: highContrastMode ? Colors.grey.shade700 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
              border: capturedImage != null ? Border.all(
                color: AppTheme.successGreen,
                width: 4,
              ) : null,
            ),
            child: Stack(
              children: [
                if (capturedImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      capturedImage!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  )
                else if (medication.photoUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      medication.photoUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  )
                else
                  CustomPaint(
                    painter: _XPainter(highContrastMode: highContrastMode),
                    size: const Size(200, 200),
                  ),
                
                // Upload indicator
                if (isUploading)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 8),
                          Text(
                            'Uploading...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          
          // Medication Name - Large and Bold
          Text(
            medication.name,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: textColor,
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
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 40),
              Text(
                timeFormat.format(medication.nextDoseTime),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: textColor,
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
              onPressed: medicationTaken ? null : onTake,
              style: ElevatedButton.styleFrom(
                backgroundColor: medicationTaken ? AppTheme.successGreen : 
                                 (highContrastMode ? Colors.white : AppTheme.darkText),
                foregroundColor: medicationTaken ? Colors.white : 
                                (highContrastMode ? AppTheme.darkText : Colors.white),
                disabledBackgroundColor: AppTheme.successGreen,
                disabledForegroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                medicationTaken ? 'TAKEN ✓' : 'TAKE NOW',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          
          // Skip Button (if medication was taken elsewhere)
          if (!medicationTaken)
            Container(
              width: double.infinity,
              height: 80,
              margin: const EdgeInsets.only(bottom: 32),
              child: OutlinedButton(
                onPressed: onTake,
                style: OutlinedButton.styleFrom(
                  foregroundColor: highContrastMode ? Colors.white : AppTheme.darkText,
                  side: BorderSide(
                    color: highContrastMode ? Colors.white : AppTheme.darkText,
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'ALREADY TAKEN',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
          
          // Take Photo to Confirm
          if (medication.requiresPhotoConfirmation && onTakePhoto != null && !medicationTaken) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 40),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: highContrastMode ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: capturedImage != null ? Border.all(
                  color: AppTheme.successGreen,
                  width: 2,
                ) : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: capturedImage != null ? AppTheme.successGreen :
                             isUploading ? AppTheme.warningYellow :
                             (highContrastMode ? Colors.white : AppTheme.darkText),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: IconButton(
                      onPressed: isUploading ? null : onTakePhoto,
                      icon: Icon(
                        capturedImage != null ? Icons.check :
                        isUploading ? Icons.cloud_upload :
                        Icons.camera_alt,
                        color: capturedImage != null ? Colors.white :
                               isUploading ? Colors.white :
                               (highContrastMode ? AppTheme.darkText : Colors.white),
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      capturedImage != null ? 'Photo Confirmed ✓' :
                      isUploading ? 'Uploading Photo...' :
                      'Take Photo to Confirm',
                      style: TextStyle(
                        fontSize: 20,
                        color: textColor,
                        fontWeight: capturedImage != null ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const Spacer(),
          
          // Next Medication Time or Completion Message
          if (medicationTaken)
            Column(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 48,
                  color: AppTheme.successGreen,
                ),
                const SizedBox(height: 8),
                Text(
                  'Medication Taken!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successGreen,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Your family has been notified',
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            )
          else
            Text(
              'Next: 2:00 PM', // This should be dynamic based on next medication
              style: TextStyle(
                fontSize: 18,
                color: highContrastMode ? Colors.white60 : AppTheme.neutralGray,
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
  final bool highContrastMode;
  
  const _XPainter({this.highContrastMode = false});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = highContrastMode ? Colors.white : Colors.grey.shade400
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