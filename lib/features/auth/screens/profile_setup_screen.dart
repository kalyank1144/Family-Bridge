import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/models/user_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/services/voice_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyRelationshipController = TextEditingController();

  DateTime? _dateOfBirth;
  File? _profileImage;
  List<String> _selectedConditions = [];
  bool _largeText = false;
  bool _highContrast = false;
  bool _voiceGuidance = true;
  bool _shareHealthData = true;
  bool _loading = false;

  final _picker = ImagePicker();
  
  VoiceService? get _voice => context.read<VoiceService?>();

  final List<String> _commonConditions = [
    'Diabetes',
    'Hypertension',
    'Heart Disease',
    'Arthritis',
    'COPD',
    'Dementia',
    'Depression',
    'Anxiety',
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationshipController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 400,
        maxHeight: 400,
      );
      if (pickedFile != null) {
        setState(() => _profileImage = File(pickedFile.path));
      }
    } catch (e) {
      _showSnack('Failed to pick image');
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.subtract(const Duration(days: 365 * 70)),
      firstDate: DateTime(1920),
      lastDate: now,
    );
    if (date != null) {
      setState(() => _dateOfBirth = date);
    }
  }

  Future<void> _completeSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final currentProfile = authProvider.profile;
      
      if (currentProfile != null) {
        // Update profile with setup data
        final updatedProfile = UserProfile(
          id: currentProfile.id,
          email: currentProfile.email,
          name: currentProfile.name,
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          role: currentProfile.role,
          dateOfBirth: _dateOfBirth,
          photoUrl: null, // Would upload to Supabase storage in real app
          medicalConditions: _selectedConditions,
          emergencyContacts: _emergencyNameController.text.trim().isEmpty ? [] : [
            EmergencyContactBasic(
              name: _emergencyNameController.text.trim(),
              relationship: _emergencyRelationshipController.text.trim(),
              phone: _emergencyPhoneController.text.trim(),
            ),
          ],
          accessibility: AccessibilityPrefs(
            largeText: _largeText,
            highContrast: _highContrast,
            voiceGuidance: _voiceGuidance,
            biometricEnabled: false,
          ),
          consent: ConsentInfo(
            termsAcceptedAt: DateTime.now(),
            privacyAcceptedAt: DateTime.now(),
            shareHealthDataWithCaregivers: _shareHealthData,
          ),
        );

        // In a real app, this would save to Supabase
        // await AuthService.instance.upsertExtendedProfile(updatedProfile);
        
        _voice?.announceAction('Profile setup completed successfully');
        _showSnack('Profile setup completed!');
        
        // Navigate to family setup or home based on role
        if (mounted) {
          context.go('/family-setup');
        }
      }
    } catch (e) {
      _voice?.announceError('Failed to complete profile setup');
      _showSnack('Failed to complete setup. Please try again.');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final profile = context.watch<AuthProvider>().profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete your profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Let\'s set up your profile',
                  style: textTheme.displaySmall,
                  semanticsLabel: 'Let\'s set up your profile. Complete the following information',
                ),
                const SizedBox(height: 24),
                
                // Profile Photo
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                        child: _profileImage == null
                            ? const Icon(Icons.person, size: 60, color: Colors.grey)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: FloatingActionButton.small(
                          onPressed: _pickImage,
                          child: const Icon(Icons.camera_alt),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number (optional)',
                    hintText: '+1 (555) 123-4567',
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 16),

                InkWell(
                  onTap: _selectDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date of birth',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _dateOfBirth == null
                          ? 'Select your date of birth'
                          : '${_dateOfBirth!.month}/${_dateOfBirth!.day}/${_dateOfBirth!.year}',
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                if (profile?.role == UserRole.elder) ...[
                  Text(
                    'Medical conditions (optional)',
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _commonConditions.map((condition) => FilterChip(
                      label: Text(condition),
                      selected: _selectedConditions.contains(condition),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedConditions.add(condition);
                          } else {
                            _selectedConditions.remove(condition);
                          }
                        });
                      },
                    )).toList(),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Emergency contact',
                    style: textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emergencyNameController,
                    decoration: const InputDecoration(
                      labelText: 'Contact name',
                      hintText: 'Dr. Smith',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emergencyRelationshipController,
                    decoration: const InputDecoration(
                      labelText: 'Relationship',
                      hintText: 'Doctor, Daughter, etc.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emergencyPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Contact phone',
                      hintText: '+1 (555) 123-4567',
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                Text(
                  'Accessibility preferences',
                  style: textTheme.titleMedium,
                ),
                SwitchListTile(
                  title: const Text('Large text'),
                  subtitle: const Text('Use larger fonts throughout the app'),
                  value: _largeText,
                  onChanged: (v) => setState(() => _largeText = v),
                ),
                SwitchListTile(
                  title: const Text('High contrast'),
                  subtitle: const Text('Use high contrast colors for better visibility'),
                  value: _highContrast,
                  onChanged: (v) => setState(() => _highContrast = v),
                ),
                SwitchListTile(
                  title: const Text('Voice guidance'),
                  subtitle: const Text('Enable voice announcements and guidance'),
                  value: _voiceGuidance,
                  onChanged: (v) => setState(() => _voiceGuidance = v),
                ),
                const SizedBox(height: 16),

                Text(
                  'Privacy settings',
                  style: textTheme.titleMedium,
                ),
                SwitchListTile(
                  title: const Text('Share health data with caregivers'),
                  subtitle: const Text('Allow family caregivers to see your health information'),
                  value: _shareHealthData,
                  onChanged: (v) => setState(() => _shareHealthData = v),
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _loading ? null : _completeSetup,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _loading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Complete setup'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}