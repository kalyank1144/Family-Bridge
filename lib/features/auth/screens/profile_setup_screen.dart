import 'dart:io';

import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:family_bridge/core/models/user_model.dart';
import 'package:family_bridge/core/services/voice_service.dart';
import 'package:family_bridge/core/theme/app_theme.dart';
import 'package:family_bridge/core/widgets/enhanced_ui_components.dart';
import 'package:family_bridge/core/widgets/form_validation.dart';
import 'package:family_bridge/core/widgets/loading_states.dart';
import 'package:family_bridge/core/widgets/success_animations.dart';
import 'package:family_bridge/features/auth/providers/auth_provider.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen>
    with TickerProviderStateMixin {
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
  bool _showSuccess = false;
  double _setupProgress = 0.0;

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

  void _updateProgress() {
    double progress = 0.1; // Base progress for being on the screen
    
    if (_profileImage != null) progress += 0.15;
    if (_phoneController.text.isNotEmpty) progress += 0.1;
    if (_dateOfBirth != null) progress += 0.15;
    if (_selectedConditions.isNotEmpty) progress += 0.15;
    if (_emergencyNameController.text.isNotEmpty) progress += 0.15;
    if (_emergencyPhoneController.text.isNotEmpty) progress += 0.15;
    if (_emergencyRelationshipController.text.isNotEmpty) progress += 0.15;

    setState(() => _setupProgress = progress);
  }

  Future<void> _pickImage() async {
    try {
      final result = await EnhancedDialog.show<ImageSource>(
        context: context,
        title: 'Choose photo source',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      );

      if (result != null) {
        final pickedFile = await _picker.pickImage(
          source: result,
          imageQuality: 70,
          maxWidth: 400,
          maxHeight: 400,
        );
        
        if (pickedFile != null) {
          setState(() => _profileImage = File(pickedFile.path));
          _updateProgress();
          
          SuccessToast.show(
            context,
            message: 'Profile photo added!',
            icon: Icons.photo_camera,
          );
        }
      }
    } catch (e) {
      _showSnack('Failed to pick image', isError: true);
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.subtract(const Duration(days: 365 * 70)),
      firstDate: DateTime(1920),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (date != null) {
      setState(() => _dateOfBirth = date);
      _updateProgress();
    }
  }

  Future<void> _completeSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    
    try {
      await Future.delayed(const Duration(milliseconds: 1500)); // Simulate API call
      
      setState(() => _showSuccess = true);
      
      _voice?.announceAction('Profile setup completed successfully');
      
      SuccessToast.show(
        context,
        message: 'Profile setup completed! Welcome to FamilyBridge.',
        icon: Icons.celebration,
        duration: const Duration(seconds: 4),
      );
      
      await Future.delayed(const Duration(milliseconds: 2000));
      
      if (mounted) {
        context.go('/family-setup');
      }
    } catch (e) {
      _voice?.announceError('Failed to complete profile setup');
      _showSnack('Failed to complete setup. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final profile = context.watch<AuthProvider>().profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete your profile'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SuccessCelebration(
        showCelebration: _showSuccess,
        child: LoadingStates.pageOverlay(
          isLoading: _loading,
          loadingText: 'Setting up your profile...',
          child: SafeArea(
            child: Column(
              children: [
                // Progress indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: ProgressCelebration(
                    progress: _setupProgress,
                    showCelebration: _setupProgress >= 0.8,
                    label: 'Profile completion',
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      onChanged: _updateProgress,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOut,
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, (1 - value) * 50),
                                child: Opacity(
                                  opacity: value,
                                  child: child,
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Let\'s set up your profile',
                                  style: textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  semanticsLabel: 'Let\'s set up your profile. Complete the following information',
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'This helps us personalize your FamilyBridge experience',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Profile Photo Section
                          InteractiveCard(
                            onTap: _pickImage,
                            child: Column(
                              children: [
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 60,
                                      backgroundColor: Colors.grey.shade200,
                                      backgroundImage: _profileImage != null 
                                          ? FileImage(_profileImage!) 
                                          : null,
                                      child: _profileImage == null
                                          ? Icon(
                                              Icons.person,
                                              size: 60,
                                              color: Colors.grey.shade400,
                                            )
                                          : null,
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _profileImage == null 
                                      ? 'Tap to add profile photo' 
                                      : 'Tap to change photo',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Personal Information
                          InteractiveCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Personal Information',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                ValidatedFormField(
                                  controller: _phoneController,
                                  labelText: 'Phone number (optional)',
                                  hintText: '+1 (555) 123-4567',
                                  prefixIcon: Icons.phone,
                                  keyboardType: TextInputType.phone,
                                  validationRules: [],
                                ),
                                const SizedBox(height: 16),

                                GestureDetector(
                                  onTap: _selectDate,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            _dateOfBirth == null
                                                ? 'Select your date of birth'
                                                : '${_dateOfBirth!.month}/${_dateOfBirth!.day}/${_dateOfBirth!.year}',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: _dateOfBirth == null 
                                                  ? Colors.grey.shade600 
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          color: Colors.grey.shade400,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Medical Information (for elders)
                          if (profile?.role == UserRole.elder) ...[
                            InteractiveCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Medical conditions (optional)',
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Select any conditions that apply to you',
                                    style: textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
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
                                        _updateProgress();
                                      },
                                      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                                      checkmarkColor: Theme.of(context).primaryColor,
                                    )).toList(),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Emergency Contact
                            InteractiveCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Emergency contact',
                                    style: textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  ValidatedFormField(
                                    controller: _emergencyNameController,
                                    labelText: 'Contact name',
                                    hintText: 'Dr. Smith',
                                    prefixIcon: Icons.person,
                                    validationRules: [],
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  ValidatedFormField(
                                    controller: _emergencyRelationshipController,
                                    labelText: 'Relationship',
                                    hintText: 'Doctor, Daughter, etc.',
                                    prefixIcon: Icons.family_restroom,
                                    validationRules: [],
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  ValidatedFormField(
                                    controller: _emergencyPhoneController,
                                    labelText: 'Contact phone',
                                    hintText: '+1 (555) 123-4567',
                                    prefixIcon: Icons.phone,
                                    keyboardType: TextInputType.phone,
                                    validationRules: [],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Accessibility Preferences
                          InteractiveCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Accessibility preferences',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                
                                SwitchListTile(
                                  title: const Text('Large text'),
                                  subtitle: const Text('Use larger fonts throughout the app'),
                                  value: _largeText,
                                  onChanged: (v) => setState(() => _largeText = v),
                                  contentPadding: EdgeInsets.zero,
                                ),
                                SwitchListTile(
                                  title: const Text('High contrast'),
                                  subtitle: const Text('Use high contrast colors for better visibility'),
                                  value: _highContrast,
                                  onChanged: (v) => setState(() => _highContrast = v),
                                  contentPadding: EdgeInsets.zero,
                                ),
                                SwitchListTile(
                                  title: const Text('Voice guidance'),
                                  subtitle: const Text('Enable voice announcements and guidance'),
                                  value: _voiceGuidance,
                                  onChanged: (v) => setState(() => _voiceGuidance = v),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Privacy Settings
                          InteractiveCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Privacy settings',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                
                                SwitchListTile(
                                  title: const Text('Share health data with caregivers'),
                                  subtitle: const Text('Allow family caregivers to see your health information'),
                                  value: _shareHealthData,
                                  onChanged: (v) => setState(() => _shareHealthData = v),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Complete setup button
                          EnhancedButton(
                            onPressed: _completeSetup,
                            isLoading: _loading,
                            type: ButtonType.primary,
                            size: ButtonSize.large,
                            child: const Text(
                              'Complete setup',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
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