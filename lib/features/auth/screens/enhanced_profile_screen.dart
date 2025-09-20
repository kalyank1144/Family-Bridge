import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/user_model.dart';
import '../../../core/services/enhanced_auth_service.dart';
import '../../../core/services/role_based_access_service.dart';
import '../../../core/services/voice_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/enhanced_ui_components.dart';
import '../../../core/widgets/loading_states.dart';
import '../../../core/widgets/success_animations.dart';
import '../providers/auth_provider.dart';

class EnhancedProfileScreen extends StatefulWidget {
  const EnhancedProfileScreen({super.key});

  @override
  State<EnhancedProfileScreen> createState() => _EnhancedProfileScreenState();
}

class _EnhancedProfileScreenState extends State<EnhancedProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _authService = EnhancedAuthService.instance;
  final _accessService = RoleBasedAccessService.instance;
  final _voiceService = VoiceService.instance;
  final _supabase = Supabase.instance.client;
  final _imagePicker = ImagePicker();

  bool _isLoading = false;
  bool _isSaving = false;
  File? _selectedImage;

  // Form controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _medicalConditionsController = TextEditingController();

  // Emergency contacts
  final List<EmergencyContact> _emergencyContacts = [];
  
  // MFA settings
  MfaSettings? _mfaSettings;
  List<DeviceInfo>? _userDevices;
  List<String>? _backupCodes;

  // Accessibility preferences
  bool _largeText = false;
  bool _highContrast = false;
  bool _voiceGuidance = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProfile();
    _loadSecuritySettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _dateOfBirthController.dispose();
    _medicalConditionsController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = context.read<AuthProvider>();
      final profile = authProvider.currentUser;
      
      if (profile != null) {
        _nameController.text = profile.name;
        _phoneController.text = profile.phone ?? '';
        if (profile.dateOfBirth != null) {
          _dateOfBirthController.text = 
              '${profile.dateOfBirth!.month}/${profile.dateOfBirth!.day}/${profile.dateOfBirth!.year}';
        }
        _medicalConditionsController.text = 
            profile.medicalConditions.join(', ');
        
        setState(() {
          _largeText = profile.accessibility.largeText;
          _highContrast = profile.accessibility.highContrast;
          _voiceGuidance = profile.accessibility.voiceGuidance;
          _biometricEnabled = profile.accessibility.biometricEnabled;
          _emergencyContacts.clear();
          _emergencyContacts.addAll(profile.emergencyContacts);
        });
      }
    } catch (e) {
      _showError('Failed to load profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSecuritySettings() async {
    try {
      _mfaSettings = await _authService.getMfaSettings();
      _userDevices = await _authService.getUserDevices();
      setState(() {});
    } catch (e) {
      debugPrint('Error loading security settings: $e');
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final currentProfile = authProvider.currentUser;
      
      if (currentProfile != null) {
        // Parse date of birth
        DateTime? dateOfBirth;
        if (_dateOfBirthController.text.isNotEmpty) {
          final parts = _dateOfBirthController.text.split('/');
          if (parts.length == 3) {
            dateOfBirth = DateTime(
              int.parse(parts[2]),
              int.parse(parts[0]),
              int.parse(parts[1]),
            );
          }
        }

        // Parse medical conditions
        final medicalConditions = _medicalConditionsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        // Update profile
        await _supabase.from('users').update({
          'name': _nameController.text,
          'phone': _phoneController.text,
          'date_of_birth': dateOfBirth?.toIso8601String(),
        }).eq('id', currentProfile.id);

        await _supabase.from('user_profiles').upsert({
          'user_id': currentProfile.id,
          'medical_conditions': medicalConditions,
          'accessibility': {
            'large_text': _largeText,
            'high_contrast': _highContrast,
            'voice_guidance': _voiceGuidance,
            'biometric_enabled': _biometricEnabled,
          },
        });

        // Upload profile photo if selected
        if (_selectedImage != null) {
          await _uploadProfilePhoto(currentProfile.id);
        }

        // Update emergency contacts
        await _saveEmergencyContacts();

        // Reload profile
        await authProvider.loadCurrentUser();

        if (mounted) {
          await SuccessAnimations.show(
            context,
            message: 'Profile updated successfully!',
          );
        }

        _voiceService.speak('Profile updated successfully');
      }
    } catch (e) {
      _showError('Failed to save profile: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _uploadProfilePhoto(String userId) async {
    if (_selectedImage == null) return;

    try {
      final bytes = await _selectedImage!.readAsBytes();
      final fileExt = _selectedImage!.path.split('.').last;
      final fileName = '$userId/profile.$fileExt';

      await _supabase.storage.from('profile-photos').uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );

      final photoUrl = _supabase.storage
          .from('profile-photos')
          .getPublicUrl(fileName);

      await _supabase.from('user_profiles').upsert({
        'user_id': userId,
        'photo_url': photoUrl,
      });
    } catch (e) {
      debugPrint('Error uploading profile photo: $e');
    }
  }

  Future<void> _saveEmergencyContacts() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      
      // Delete existing contacts
      await _supabase
          .from('emergency_contacts')
          .delete()
          .eq('user_id', userId);

      // Insert new contacts
      if (_emergencyContacts.isNotEmpty) {
        await _supabase.from('emergency_contacts').insert(
          _emergencyContacts.map((contact) => {
            'user_id': userId,
            'name': contact.name,
            'phone': contact.phone,
            'relationship': contact.relationship,
          }).toList(),
        );
      }
    } catch (e) {
      debugPrint('Error saving emergency contacts: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _configureMfa(MfaSettings settings) async {
    setState(() => _isLoading = true);

    try {
      await _authService.configureMfa(settings);
      _mfaSettings = settings;
      
      if (settings.enabled && _backupCodes == null) {
        _backupCodes = await _authService.generateMfaBackupCodes();
        if (_backupCodes!.isNotEmpty && mounted) {
          _showBackupCodes();
        }
      }

      _voiceService.speak('Security settings updated');
    } catch (e) {
      _showError('Failed to configure MFA: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showBackupCodes() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('MFA Backup Codes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Save these backup codes in a secure location. '
              'Each code can only be used once.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: _backupCodes!.map((code) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        code,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Code copied to clipboard'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: _backupCodes!.join('\n')),
              );
              Navigator.of(context).pop();
            },
            child: const Text('Copy All & Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _trustDevice(DeviceInfo device) async {
    setState(() => _isLoading = true);

    try {
      await _authService.trustDevice(deviceName: device.deviceName);
      await _loadSecuritySettings();
      _voiceService.speak('Device trusted successfully');
    } catch (e) {
      _showError('Failed to trust device: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeTrustedDevice(String deviceId) async {
    setState(() => _isLoading = true);

    try {
      await _authService.removeTrustedDevice(deviceId);
      await _loadSecuritySettings();
      _voiceService.speak('Device trust removed');
    } catch (e) {
      _showError('Failed to remove trusted device: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
    _voiceService.speak('Error: $message');
  }

  void _addEmergencyContact() {
    showDialog(
      context: context,
      builder: (context) => _EmergencyContactDialog(
        onSave: (contact) {
          setState(() {
            _emergencyContacts.add(contact);
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final isElder = authProvider.currentUser?.role == UserRole.elder;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: isElder ? AppStyles.displayLarge : null,
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: isElder,
          tabs: [
            Tab(
              icon: Icon(Icons.person, size: isElder ? 32 : 24),
              text: 'Profile',
            ),
            Tab(
              icon: Icon(Icons.security, size: isElder ? 32 : 24),
              text: 'Security',
            ),
            Tab(
              icon: Icon(Icons.accessibility, size: isElder ? 32 : 24),
              text: 'Accessibility',
            ),
            Tab(
              icon: Icon(Icons.emergency, size: isElder ? 32 : 24),
              text: 'Emergency',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingStates()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProfileTab(isElder),
                _buildSecurityTab(isElder),
                _buildAccessibilityTab(isElder),
                _buildEmergencyTab(isElder),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveProfile,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.save),
        label: Text(
          'Save Changes',
          style: isElder ? const TextStyle(fontSize: 18) : null,
        ),
      ),
    );
  }

  Widget _buildProfileTab(bool isElder) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: isElder ? 80 : 60,
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!)
                      : null,
                  child: _selectedImage == null
                      ? Icon(
                          Icons.person,
                          size: isElder ? 80 : 60,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: EnhancedButton(
                    onPressed: _pickImage,
                    type: ButtonType.icon,
                    icon: Icons.camera_alt,
                    size: isElder ? ButtonSize.large : ButtonSize.medium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          EnhancedTextField(
            controller: _nameController,
            label: 'Full Name',
            prefixIcon: Icons.person_outline,
            isElder: isElder,
          ),
          const SizedBox(height: 16),
          EnhancedTextField(
            controller: _phoneController,
            label: 'Phone Number',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            isElder: isElder,
          ),
          const SizedBox(height: 16),
          EnhancedTextField(
            controller: _dateOfBirthController,
            label: 'Date of Birth (MM/DD/YYYY)',
            prefixIcon: Icons.cake_outlined,
            keyboardType: TextInputType.datetime,
            isElder: isElder,
          ),
          const SizedBox(height: 16),
          EnhancedTextField(
            controller: _medicalConditionsController,
            label: 'Medical Conditions (comma separated)',
            prefixIcon: Icons.medical_services_outlined,
            maxLines: 3,
            isElder: isElder,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTab(bool isElder) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Multi-Factor Authentication',
            style: isElder ? AppStyles.headlineLarge : AppStyles.headlineMedium,
          ),
          const SizedBox(height: 16),
          EnhancedCard(
            isElder: isElder,
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(
                    'Enable MFA',
                    style: isElder ? const TextStyle(fontSize: 20) : null,
                  ),
                  subtitle: const Text('Add extra security to your account'),
                  value: _mfaSettings?.enabled ?? false,
                  onChanged: (value) {
                    _configureMfa(MfaSettings(enabled: value));
                  },
                ),
                if (_mfaSettings?.enabled ?? false) ...[
                  const Divider(),
                  CheckboxListTile(
                    title: Text(
                      'SMS',
                      style: isElder ? const TextStyle(fontSize: 18) : null,
                    ),
                    value: _mfaSettings?.sms ?? false,
                    onChanged: (value) {
                      if (_mfaSettings != null && value != null) {
                        _configureMfa(MfaSettings(
                          enabled: true,
                          sms: value,
                          email: _mfaSettings!.email,
                          authenticator: _mfaSettings!.authenticator,
                          biometric: _mfaSettings!.biometric,
                        ));
                      }
                    },
                  ),
                  CheckboxListTile(
                    title: Text(
                      'Email',
                      style: isElder ? const TextStyle(fontSize: 18) : null,
                    ),
                    value: _mfaSettings?.email ?? false,
                    onChanged: (value) {
                      if (_mfaSettings != null && value != null) {
                        _configureMfa(MfaSettings(
                          enabled: true,
                          sms: _mfaSettings!.sms,
                          email: value,
                          authenticator: _mfaSettings!.authenticator,
                          biometric: _mfaSettings!.biometric,
                        ));
                      }
                    },
                  ),
                  CheckboxListTile(
                    title: Text(
                      'Authenticator App',
                      style: isElder ? const TextStyle(fontSize: 18) : null,
                    ),
                    value: _mfaSettings?.authenticator ?? false,
                    onChanged: (value) {
                      if (_mfaSettings != null && value != null) {
                        _configureMfa(MfaSettings(
                          enabled: true,
                          sms: _mfaSettings!.sms,
                          email: _mfaSettings!.email,
                          authenticator: value,
                          biometric: _mfaSettings!.biometric,
                        ));
                      }
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Trusted Devices',
            style: isElder ? AppStyles.headlineLarge : AppStyles.headlineMedium,
          ),
          const SizedBox(height: 16),
          if (_userDevices?.isNotEmpty ?? false)
            ..._userDevices!.map((device) => EnhancedCard(
              isElder: isElder,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  _getDeviceIcon(device.deviceType),
                  size: isElder ? 32 : 24,
                ),
                title: Text(
                  device.deviceName ?? 'Unknown Device',
                  style: isElder ? const TextStyle(fontSize: 18) : null,
                ),
                subtitle: Text(
                  '${device.platform ?? 'Unknown'} • Last used: ${device.lastUsedAt?.toString() ?? 'Never'}',
                ),
                trailing: device.isTrusted
                    ? Chip(
                        label: const Text('Trusted'),
                        backgroundColor: Colors.green.shade100,
                      )
                    : EnhancedButton(
                        onPressed: () => _trustDevice(device),
                        type: ButtonType.secondary,
                        text: 'Trust',
                        size: ButtonSize.small,
                      ),
              ),
            )).toList()
          else
            const Center(
              child: Text('No devices found'),
            ),
        ],
      ),
    );
  }

  Widget _buildAccessibilityTab(bool isElder) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accessibility Settings',
            style: isElder ? AppStyles.headlineLarge : AppStyles.headlineMedium,
          ),
          const SizedBox(height: 16),
          EnhancedCard(
            isElder: isElder,
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(
                    'Large Text',
                    style: isElder ? const TextStyle(fontSize: 20) : null,
                  ),
                  subtitle: const Text('Increase text size throughout the app'),
                  value: _largeText,
                  onChanged: (value) {
                    setState(() => _largeText = value);
                  },
                ),
                const Divider(),
                SwitchListTile(
                  title: Text(
                    'High Contrast',
                    style: isElder ? const TextStyle(fontSize: 20) : null,
                  ),
                  subtitle: const Text('Improve visibility with higher contrast'),
                  value: _highContrast,
                  onChanged: (value) {
                    setState(() => _highContrast = value);
                  },
                ),
                const Divider(),
                SwitchListTile(
                  title: Text(
                    'Voice Guidance',
                    style: isElder ? const TextStyle(fontSize: 20) : null,
                  ),
                  subtitle: const Text('Enable voice announcements'),
                  value: _voiceGuidance,
                  onChanged: (value) {
                    setState(() => _voiceGuidance = value);
                    if (value) {
                      _voiceService.speak('Voice guidance enabled');
                    }
                  },
                ),
                const Divider(),
                SwitchListTile(
                  title: Text(
                    'Biometric Login',
                    style: isElder ? const TextStyle(fontSize: 20) : null,
                  ),
                  subtitle: const Text('Use fingerprint or face to login'),
                  value: _biometricEnabled,
                  onChanged: (value) async {
                    if (value) {
                      final authenticated = await _authService
                          .authenticateWithBiometrics(
                        reason: 'Enable biometric login',
                      );
                      if (authenticated) {
                        setState(() => _biometricEnabled = true);
                      }
                    } else {
                      setState(() => _biometricEnabled = false);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyTab(bool isElder) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Emergency Contacts',
                style: isElder ? AppStyles.headlineLarge : AppStyles.headlineMedium,
              ),
              EnhancedButton(
                onPressed: _addEmergencyContact,
                type: ButtonType.primary,
                icon: Icons.add,
                text: 'Add',
                size: isElder ? ButtonSize.large : ButtonSize.medium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_emergencyContacts.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.emergency,
                    size: isElder ? 80 : 60,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No emergency contacts added',
                    style: TextStyle(
                      fontSize: isElder ? 20 : 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._emergencyContacts.map((contact) => EnhancedCard(
              isElder: isElder,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red.shade100,
                  child: Icon(
                    Icons.emergency,
                    color: Colors.red,
                    size: isElder ? 32 : 24,
                  ),
                ),
                title: Text(
                  contact.name,
                  style: isElder ? const TextStyle(fontSize: 20) : null,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.phone,
                      style: isElder ? const TextStyle(fontSize: 18) : null,
                    ),
                    Text(
                      contact.relationship,
                      style: TextStyle(
                        fontSize: isElder ? 16 : 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: Colors.red,
                    size: isElder ? 32 : 24,
                  ),
                  onPressed: () {
                    setState(() {
                      _emergencyContacts.remove(contact);
                    });
                  },
                ),
              ),
            )).toList(),
          const SizedBox(height: 32),
          EnhancedCard(
            isElder: isElder,
            color: Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.warning,
                    color: Colors.red,
                    size: isElder ? 48 : 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Emergency Button',
                    style: TextStyle(
                      fontSize: isElder ? 24 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Press and hold for 3 seconds to trigger emergency alert',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isElder ? 18 : 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onLongPress: () {
                      HapticFeedback.heavyImpact();
                      _voiceService.speak('Emergency alert triggered');
                      // Trigger emergency alert
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Emergency alert sent!'),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
                    child: Container(
                      width: isElder ? 200 : 150,
                      height: isElder ? 200 : 150,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.emergency,
                        color: Colors.white,
                        size: isElder ? 80 : 60,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDeviceIcon(String deviceType) {
    switch (deviceType) {
      case 'mobile':
        return Icons.phone_android;
      case 'tablet':
        return Icons.tablet;
      case 'desktop':
        return Icons.computer;
      case 'web':
        return Icons.web;
      default:
        return Icons.devices;
    }
  }
}

class _EmergencyContactDialog extends StatefulWidget {
  final Function(EmergencyContact) onSave;

  const _EmergencyContactDialog({required this.onSave});

  @override
  State<_EmergencyContactDialog> createState() =>
      _EmergencyContactDialogState();
}

class _EmergencyContactDialogState extends State<_EmergencyContactDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationshipController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Emergency Contact'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: Icon(Icons.phone),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _relationshipController,
            decoration: const InputDecoration(
              labelText: 'Relationship',
              prefixIcon: Icon(Icons.family_restroom),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty &&
                _phoneController.text.isNotEmpty &&
                _relationshipController.text.isNotEmpty) {
              widget.onSave(EmergencyContact(
                name: _nameController.text,
                phone: _phoneController.text,
                relationship: _relationshipController.text,
              ));
              Navigator.of(context).pop();
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}