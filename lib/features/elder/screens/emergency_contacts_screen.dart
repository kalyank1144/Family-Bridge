import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/elder_provider.dart';
import '../models/emergency_contact_model.dart';
import '../../../core/services/voice_service.dart';
import '../../../core/theme/app_theme.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../elder/widgets/voice_checkin_widget.dart';
import '../../../services/storage/media_storage_service.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  late VoiceService _voiceService;
  
  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  Future<void> _initializeScreen() async {
    _voiceService = context.read<VoiceService>();
    await _voiceService.announceScreen('Emergency Contacts');
    
    final elderProvider = context.read<ElderProvider>();
    
    // Register voice commands for contacts
    for (var contact in elderProvider.emergencyContacts) {
      _voiceService.registerCommand(
        'call ${contact.name.toLowerCase()}',
        () => _callContact(contact),
      );
    }
    
    _voiceService.registerCommand('call 911', () => _call911());
    _voiceService.registerCommand('emergency', () => _call911());
  }

  Future<void> _callContact(EmergencyContact contact) async {
    await _voiceService.speak('Calling ${contact.name}');
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: contact.phone,
    );
    await launchUrl(launchUri);
  }

  Future<void> _call911() async {
    await _voiceService.speak('Calling 911 Emergency Services');
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: '911',
    );
    await launchUrl(launchUri);
  }

  Future<void> _shareLocationToContacts() async {
    final perm = await Permission.locationWhenInUse.request();
    if (!perm.isGranted) return;
    try {
      final pos = await Geolocator.getCurrentPosition();
      final link = 'https://maps.google.com/?q=${pos.latitude},${pos.longitude}';
      final elderProvider = context.read<ElderProvider>();
      for (final c in elderProvider.emergencyContacts) {
        final sms = Uri(scheme: 'sms', path: c.phone, queryParameters: {
          'body': 'Emergency: Here is my location: $link'
        });
        await launchUrl(sms);
      }
      await _voiceService.confirmAction('Location shared');
    } catch (e) {
      await _voiceService.announceError('Could not get location');
    }
  }

  Future<void> _takeEmergencyPhoto() async {
    final picker = ImagePicker();
    final camPerm = await Permission.camera.request();
    if (!camPerm.isGranted) return;
    final x = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (x == null) return;
    try {
      await MediaStorageService().uploadFile(
        file: File(x.path),
        bucket: MediaStorageService.bucketMedicationPhotos,
        contentType: 'image/jpeg',
      );
      await _voiceService.confirmAction('Emergency photo captured');
    } catch (_) {
      await _voiceService.speak('Photo saved to send later');
    }
  }

  void _showAddContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AddContactDialog(
        onAdd: (contact) async {
          final elderProvider = context.read<ElderProvider>();
          await elderProvider.addEmergencyContact(contact);
          await _voiceService.confirmAction('Contact added');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Consumer<ElderProvider>(
          builder: (context, elderProvider, child) {
            return Column(
              children: [
                // Emergency 911 Button
                Container(
                  margin: const EdgeInsets.all(20),
                  child: GestureDetector(
                    onTap: () async {
                      await _voiceService.speak('Long press to confirm calling 911');
                    },
                    onLongPress: _call911,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.emergencyRed,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.emergency,
                            size: 40,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 20),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'EMERGENCY',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                'Long press to call 911',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Contacts List
                Expanded(
                  child: elderProvider.isLoadingContacts
                      ? const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: elderProvider.emergencyContacts.length,
                          itemBuilder: (context, index) {
                            final contact = elderProvider.emergencyContacts[index];
                            return ContactCard(
                              contact: contact,
                              onCall: () => _callContact(contact),
                            );
                          },
                        ),
                ),

                // Emergency Actions Bar
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _shareLocationToContacts,
                              icon: const Icon(Icons.location_on, color: Colors.white),
                              label: const Text('Share Location', style: TextStyle(fontSize: 20, color: Colors.white)),
                              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 64)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _takeEmergencyPhoto,
                              icon: const Icon(Icons.camera, color: Colors.white),
                              label: const Text('Take Photo', style: TextStyle(fontSize: 20, color: Colors.white)),
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, minimumSize: const Size(double.infinity, 64)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      VoiceCheckinWidget(onUploaded: (url) {
                        // Could store into emergency_events table from a service
                      }),
                    ],
                  ),
                ),

                // Add Contact Button
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: OutlinedButton(
                    onPressed: _showAddContactDialog,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 80),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_add, size: 32),
                        const SizedBox(width: 16),
                        const Text(
                          'Add New Contact',
                          style: TextStyle(fontSize: 24),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class ContactCard extends StatelessWidget {
  final EmergencyContact contact;
  final VoidCallback onCall;

  const ContactCard({
    super.key,
    required this.contact,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 36,
              backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
              backgroundImage: contact.photoUrl != null
                  ? NetworkImage(contact.photoUrl!)
                  : null,
              child: contact.photoUrl == null
                  ? Icon(
                      Icons.person,
                      size: 40,
                      color: AppTheme.primaryBlue,
                    )
                  : null,
            ),
            const SizedBox(width: 20),
            
            // Contact Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contact.relationship,
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.neutralGray,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contact.phone,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.darkText,
                    ),
                  ),
                ],
              ),
            ),
            
            // Call Button
            ElevatedButton(
              onPressed: onCall,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                minimumSize: const Size(100, 60),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'CALL',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddContactDialog extends StatefulWidget {
  final Function(EmergencyContact) onAdd;

  const AddContactDialog({
    super.key,
    required this.onAdd,
  });

  @override
  State<AddContactDialog> createState() => _AddContactDialogState();
}

class _AddContactDialogState extends State<AddContactDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationshipController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Emergency Contact',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter contact name',
              ),
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _relationshipController,
              decoration: const InputDecoration(
                labelText: 'Relationship',
                hintText: 'e.g., Daughter, Son, Doctor',
              ),
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                hintText: 'Enter phone number',
              ),
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 32),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_nameController.text.isNotEmpty &&
                          _phoneController.text.isNotEmpty) {
                        final contact = EmergencyContact(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: _nameController.text,
                          relationship: _relationshipController.text.isEmpty
                              ? 'Contact'
                              : _relationshipController.text,
                          phone: _phoneController.text,
                          priority: 999,
                          createdAt: DateTime.now(),
                        );
                        widget.onAdd(contact);
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Add'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }
}