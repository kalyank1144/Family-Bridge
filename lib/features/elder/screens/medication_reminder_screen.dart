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
    _voiceService.registerCommand('skip medicine', () => _skipMedication());
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

  Future<void> _skipMedication() async {
    final elderProvider = context.read<ElderProvider>();
    if (elderProvider.nextMedication != null) {
      await _showSkipDialog(elderProvider.nextMedication!);
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
    
    await elderProvider.markMedicationTaken(
      medication.id,
      photoUrl: _capturedImageUrl ?? _capturedImage?.path,
    );
    
    await _voiceService.confirmAction('Medication marked as taken');
    
    setState(() {
      _capturedImage = null;
    });
  }

  Future<void> _showSkipDialog(Medication medication) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Skip Medication?',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Why are you skipping ${medication.name}?',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            _SkipReasonButton(
              reason: 'Not feeling well',
              onTap: () => _skipWithReason(medication, 'Not feeling well'),
            ),
            _SkipReasonButton(
              reason: 'Out of medication',
              onTap: () => _skipWithReason(medication, 'Out of medication'),
            ),
            _SkipReasonButton(
              reason: 'Doctor advised to skip',
              onTap: () => _skipWithReason(medication, 'Doctor advised'),
            ),
            _SkipReasonButton(
              reason: 'Other reason',
              onTap: () => _skipWithReason(medication, 'Other'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _skipWithReason(Medication medication, String reason) async {
    final elderProvider = context.read<ElderProvider>();
    await elderProvider.skipMedication(medication.id, reason);
    Navigator.pop(context);
    await _voiceService.confirmAction('Medication skipped');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('My Medications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
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
                    Text(
                      'No medications scheduled',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: elderProvider.medications.length,
              itemBuilder: (context, index) {
                final medication = elderProvider.medications[index];
                final isNext = medication.id == elderProvider.nextMedication?.id;
                
                return MedicationCard(
                  medication: medication,
                  isNext: isNext,
                  onTake: () => _confirmMedicationTaken(medication),
                  onSkip: () => _showSkipDialog(medication),
                  onTakePhoto: medication.requiresPhotoConfirmation ? _takePhoto : null,
                  capturedImage: _capturedImage,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class MedicationCard extends StatelessWidget {
  final Medication medication;
  final bool isNext;
  final VoidCallback onTake;
  final VoidCallback onSkip;
  final VoidCallback? onTakePhoto;
  final File? capturedImage;

  const MedicationCard({
    super.key,
    required this.medication,
    required this.isNext,
    required this.onTake,
    required this.onSkip,
    this.onTakePhoto,
    this.capturedImage,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: isNext ? 8 : 2,
      color: isNext ? Colors.white : Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isNext
            ? BorderSide(color: AppTheme.primaryBlue, width: 3)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isNext)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: medication.isDue()
                      ? AppTheme.emergencyRed
                      : AppTheme.warningYellow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  medication.isDue() ? 'TAKE NOW' : 'NEXT DOSE',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (isNext) const SizedBox(height: 16),
            
            // Medication Image
            if (medication.photoUrl != null)
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: NetworkImage(medication.photoUrl!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              )
            else
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.medication,
                    size: 60,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            
            // Medication Name
            Text(
              medication.name,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 8),
            
            // Dosage
            Text(
              medication.dosage,
              style: const TextStyle(
                fontSize: 24,
                color: AppTheme.darkText,
              ),
            ),
            const SizedBox(height: 8),
            
            // Time
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 24,
                  color: AppTheme.neutralGray,
                ),
                const SizedBox(width: 8),
                Text(
                  timeFormat.format(medication.nextDoseTime),
                  style: TextStyle(
                    fontSize: 20,
                    color: AppTheme.neutralGray,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  medication.getTimeUntilNext(),
                  style: TextStyle(
                    fontSize: 18,
                    color: medication.isDue()
                        ? AppTheme.emergencyRed
                        : AppTheme.neutralGray,
                    fontWeight: medication.isDue() ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            
            // Instructions
            if (medication.instructions != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        medication.instructions!,
                        style: const TextStyle(
                          fontSize: 18,
                          color: AppTheme.darkText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Photo Confirmation
            if (medication.requiresPhotoConfirmation && isNext) ...[
              const SizedBox(height: 20),
              if (capturedImage != null)
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: FileImage(capturedImage!),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: onTakePhoto,
                  icon: const Icon(Icons.camera_alt, size: 28),
                  label: const Text(
                    'Take Photo to Confirm',
                    style: TextStyle(fontSize: 20),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 70),
                  ),
                ),
            ],
            
            // Action Buttons
            if (isNext) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onTake,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successGreen,
                        minimumSize: const Size(double.infinity, 70),
                      ),
                      child: const Text(
                        'TAKEN',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onSkip,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 70),
                        side: const BorderSide(
                          color: AppTheme.neutralGray,
                          width: 2,
                        ),
                      ),
                      child: Text(
                        'SKIP',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.neutralGray,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SkipReasonButton extends StatelessWidget {
  final String reason;
  final VoidCallback onTap;

  const _SkipReasonButton({
    required this.reason,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 60),
        ),
        child: Text(
          reason,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}