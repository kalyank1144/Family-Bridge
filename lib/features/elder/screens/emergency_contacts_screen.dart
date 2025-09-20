import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/elder_provider.dart';
import '../models/emergency_contact_model.dart';
import '../../../core/services/voice_service.dart';
import '../../../core/theme/app_theme.dart';

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 32, color: AppTheme.darkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Emergency Contacts',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.darkText,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Consumer<ElderProvider>(
          builder: (context, elderProvider, child) {
            return Column(
              children: [
                const SizedBox(height: 20),
                
                // Contacts List - matching sample design
                Expanded(
                  child: elderProvider.isLoadingContacts
                      ? const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                          ),
                        )
                      : elderProvider.emergencyContacts.isEmpty
                          ? _buildEmptyContactsView()
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: elderProvider.emergencyContacts.length,
                              itemBuilder: (context, index) {
                                final contact = elderProvider.emergencyContacts[index];
                                return _ModernContactCard(
                                  contact: contact,
                                  onCall: () => _callContact(contact),
                                );
                              },
                            ),
                ),
                
                // Add Contact Button - matching sample design
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    width: double.infinity,
                    height: 70,
                    child: ElevatedButton(
                      onPressed: _showAddContactDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.darkText,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Add New Contact',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  Widget _buildEmptyContactsView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Sample contacts matching the design
        _ModernContactCard(
          contact: EmergencyContact(
            id: 'sample1',
            name: 'Anna Taylor',
            relationship: 'Daughter',
            phone: '(555) 123-4567',
            priority: 1,
            createdAt: DateTime.now(),
          ),
          onCall: () {},
        ),
        _ModernContactCard(
          contact: EmergencyContact(
            id: 'sample2',
            name: 'John Smith',
            relationship: 'Son',
            phone: '(555) 987-6543',
            priority: 2,
            createdAt: DateTime.now(),
          ),
          onCall: () {},
        ),
        _ModernContactCard(
          contact: EmergencyContact(
            id: 'sample3',
            name: 'Dr. Doe',
            relationship: 'Doctor',
            phone: '(555) 555-1234',
            priority: 3,
            createdAt: DateTime.now(),
          ),
          onCall: () {},
        ),
      ],
    );
  }
}

class _ModernContactCard extends StatelessWidget {
  final EmergencyContact contact;
  final VoidCallback onCall;

  const _ModernContactCard({
    required this.contact,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Profile Picture
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: contact.photoUrl != null
                ? NetworkImage(contact.photoUrl!)
                : null,
            child: contact.photoUrl == null
                ? const Icon(
                    Icons.person,
                    size: 32,
                    color: Colors.black,
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
                    color: AppTheme.darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  contact.relationship,
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppTheme.darkText,
                  ),
                ),
              ],
            ),
          ),
          
          // Call Button - matching sample design
          Container(
            width: 100,
            height: 50,
            child: ElevatedButton(
              onPressed: onCall,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.darkText,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'CALL',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Keep the existing ContactCard for backward compatibility
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
    return _ModernContactCard(
      contact: contact,
      onCall: onCall,
    );


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