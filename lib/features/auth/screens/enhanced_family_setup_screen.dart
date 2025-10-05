import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import 'package:family_bridge/core/services/auth_service.dart';
import 'package:family_bridge/core/theme/app_theme.dart';
import 'package:family_bridge/features/caregiver/providers/family_data_provider.dart';
import 'package:family_bridge/features/shared/models/family_model.dart';
import 'package:family_bridge/features/shared/models/user_model.dart';

/// Enhanced Family Setup Screen showcasing comprehensive FamilyDataProvider integration
/// Features: family creation, member invitations, role assignment, privacy settings
class EnhancedFamilySetupScreen extends StatefulWidget {
  final String userId;
  final bool isCreatingFamily;

  const EnhancedFamilySetupScreen({
    super.key,
    required this.userId,
    this.isCreatingFamily = true,
  });

  @override
  State<EnhancedFamilySetupScreen> createState() => _EnhancedFamilySetupScreenState();
}

class _EnhancedFamilySetupScreenState extends State<EnhancedFamilySetupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Form controllers
  final _familyNameController = TextEditingController();
  final _familyCodeController = TextEditingController();
  final _inviteEmailController = TextEditingController();
  final _invitePhoneController = TextEditingController();

  // Form data
  FamilyRole _selectedRole = FamilyRole.primaryCaregiver;
  List<PendingInvite> _pendingInvites = [];
  final Map<String, dynamic> _privacySettings = {
    'shareHealthData': true,
    'shareLocation': true,
    'sharePhotos': true,
    'allowEmergencyOverride': true,
    'dataRetentionDays': 365,
    'requirePhotoConsent': false,
    'allowCaregiverAccess': true,
  };

  @override
  void initState() {
    super.initState();
    _initializeFamilyProvider();
  }

  Future<void> _initializeFamilyProvider() async {
    final familyProvider = Provider.of<FamilyDataProvider>(context, listen: false);
    await familyProvider.initialize(widget.userId);
  }

  @override
  void dispose() {
    _familyNameController.dispose();
    _familyCodeController.dispose();
    _inviteEmailController.dispose();
    _invitePhoneController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<FamilyDataProvider>(
          builder: (context, familyProvider, child) {
            return Column(
              children: [
                _buildHeader(),
                _buildProgressIndicator(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildWelcomeStep(),
                      widget.isCreatingFamily 
                          ? _buildFamilyCreationStep(familyProvider)
                          : _buildJoinFamilyStep(familyProvider),
                      _buildInviteMembersStep(familyProvider),
                      _buildPrivacySettingsStep(),
                      _buildCompletionStep(familyProvider),
                    ],
                  ),
                ),
                _buildNavigationButtons(familyProvider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Family Setup',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isCreatingFamily 
                ? 'Create your family care circle'
                : 'Join an existing family',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: List.generate(_totalSteps, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < _totalSteps - 1 ? 8 : 0),
              decoration: BoxDecoration(
                color: index <= _currentStep ? AppTheme.primaryColor : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.family_restroom,
              size: 64,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Welcome to FamilyBridge',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Connect with your family members to coordinate care, share updates, and stay close across generations.',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.security, color: Colors.blue),
                    SizedBox(width: 12),
                    Text(
                      'Your Privacy Matters',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'All health information is encrypted and HIPAA compliant. You control who sees what information.',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyCreationStep(FamilyDataProvider familyProvider) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create Your Family',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Give your family circle a name that everyone will recognize.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _familyNameController,
            decoration: InputDecoration(
              labelText: 'Family Name',
              hintText: 'e.g., The Johnson Family',
              prefixIcon: const Icon(Icons.home),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your Role in the Family',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._buildRoleSelection(),
          const SizedBox(height: 32),
          if (familyProvider.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (familyProvider.error != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      familyProvider.error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildJoinFamilyStep(FamilyDataProvider familyProvider) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Join Family',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter the family code shared by your family member.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _familyCodeController,
            decoration: InputDecoration(
              labelText: 'Family Code',
              hintText: 'Enter 6-digit code',
              prefixIcon: const Icon(Icons.key),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            style: const TextStyle(fontSize: 24, letterSpacing: 2),
            textAlign: TextAlign.center,
            maxLength: 6,
          ),
          const SizedBox(height: 24),
          const Text(
            'Your Role in the Family',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._buildRoleSelection(),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber.shade700),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Family codes are provided by family administrators and expire after 7 days.',
                  ),
                ),
              ],
            ),
          ),
          if (familyProvider.isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (familyProvider.error != null)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      familyProvider.error!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildRoleSelection() {
    return [
      _buildRoleCard(
        FamilyRole.elder,
        'Elder',
        'I am the care recipient',
        Icons.elderly,
        Colors.green,
      ),
      const SizedBox(height: 12),
      _buildRoleCard(
        FamilyRole.primaryCaregiver,
        'Primary Caregiver',
        'I provide primary care and coordination',
        Icons.medical_services,
        Colors.blue,
      ),
      const SizedBox(height: 12),
      _buildRoleCard(
        FamilyRole.secondaryCaregiver,
        'Family Caregiver',
        'I help with care and stay informed',
        Icons.support,
        Colors.orange,
      ),
      const SizedBox(height: 12),
      _buildRoleCard(
        FamilyRole.youth,
        'Youth Member',
        'I help connect and share with the family',
        Icons.child_care,
        Colors.purple,
      ),
    ];
  }

  Widget _buildRoleCard(FamilyRole role, String title, String description, IconData icon, Color color) {
    final isSelected = _selectedRole == role;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(isSelected ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteMembersStep(FamilyDataProvider familyProvider) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Invite Family Members',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add family members to your care circle. You can always invite more later.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inviteEmailController,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _addInvite,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_pendingInvites.isNotEmpty) ...[
            const Text(
              'Pending Invitations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(_pendingInvites.length, (index) {
              final invite = _pendingInvites[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_add, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invite.email,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Role: ${_getRoleName(invite.suggestedRole)}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeInvite(index),
                      icon: const Icon(Icons.close, color: Colors.red),
                    ),
                  ],
                ),
              );
            }),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Column(
                children: [
                  Icon(Icons.group_add, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No invitations yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add family members above or skip this step',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrivacySettingsStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Privacy Settings',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Configure what information is shared within your family.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView(
              children: [
                _buildPrivacyToggle(
                  'Health Data Sharing',
                  'Share medication reminders and health check-ins',
                  'shareHealthData',
                  Icons.health_and_safety,
                ),
                _buildPrivacyToggle(
                  'Photo Sharing',
                  'Allow family members to share photos',
                  'sharePhotos',
                  Icons.photo,
                ),
                _buildPrivacyToggle(
                  'Location Sharing',
                  'Share location for emergency situations',
                  'shareLocation',
                  Icons.location_on,
                ),
                _buildPrivacyToggle(
                  'Emergency Override',
                  'Allow emergency contacts to override privacy settings',
                  'allowEmergencyOverride',
                  Icons.emergency,
                ),
                _buildPrivacyToggle(
                  'Caregiver Access',
                  'Allow designated caregivers to access health data',
                  'allowCaregiverAccess',
                  Icons.medical_services,
                ),
                _buildPrivacyToggle(
                  'Photo Consent Required',
                  'Require explicit consent before sharing photos',
                  'requirePhotoConsent',
                  Icons.privacy_tip,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.security, color: Colors.blue),
                          SizedBox(width: 12),
                          Text(
                            'HIPAA Compliance',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'All health information is encrypted and stored securely. Only authorized family members can access shared data.',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Data Retention: '),
                          Text(
                            '${_privacySettings['dataRetentionDays']} days',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyToggle(String title, String description, String key, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _privacySettings[key] ?? false,
            onChanged: (value) {
              setState(() {
                _privacySettings[key] = value;
              });
            },
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionStep(FamilyDataProvider familyProvider) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Family Setup Complete!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (familyProvider.currentFamily != null) ...[
            Text(
              'Welcome to ${familyProvider.currentFamily!.familyName}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Family Code',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    familyProvider.currentFamily!.familyCode,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Share this code with family members to invite them',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),
          const Text(
            'You can now:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...[
            '✅ Share health updates with family',
            '✅ Coordinate care and appointments',
            '✅ Stay connected across generations',
            '✅ Invite more family members anytime',
          ].map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              item,
              style: const TextStyle(fontSize: 16),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(FamilyDataProvider familyProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                child: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: familyProvider.isLoading ? null : _nextStep,
              child: familyProvider.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_getButtonText()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _nextStep() async {
    final familyProvider = Provider.of<FamilyDataProvider>(context, listen: false);

    switch (_currentStep) {
      case 1:
        if (widget.isCreatingFamily) {
          await _createFamily(familyProvider);
        } else {
          await _joinFamily(familyProvider);
        }
        break;
      case 2:
        await _sendInvitations(familyProvider);
        break;
      case 3:
        await _savePrivacySettings(familyProvider);
        break;
      case 4:
        _completeSetup();
        return;
    }

    if (!familyProvider.isLoading && familyProvider.error == null) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _createFamily(FamilyDataProvider familyProvider) async {
    if (_familyNameController.text.trim().isEmpty) return;

    await familyProvider.createFamily(
      familyName: _familyNameController.text.trim(),
      privacySettings: _privacySettings,
    );
  }

  Future<void> _joinFamily(FamilyDataProvider familyProvider) async {
    if (_familyCodeController.text.trim().isEmpty) return;

    await familyProvider.joinFamily(
      familyCode: _familyCodeController.text.trim(),
      role: _selectedRole,
    );
  }

  Future<void> _sendInvitations(FamilyDataProvider familyProvider) async {
    for (final invite in _pendingInvites) {
      await familyProvider.createInvitation(
        suggestedRole: invite.suggestedRole,
        invitedEmail: invite.email,
      );
    }
  }

  Future<void> _savePrivacySettings(FamilyDataProvider familyProvider) async {
    await familyProvider.updatePrivacySettings(
      privacySettings: _privacySettings,
    );
  }

  void _completeSetup() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _addInvite() {
    final email = _inviteEmailController.text.trim();
    if (email.isNotEmpty && _isValidEmail(email)) {
      setState(() {
        _pendingInvites.add(PendingInvite(
          email: email,
          suggestedRole: FamilyRole.secondaryCaregiver,
        ));
        _inviteEmailController.clear();
      });
    }
  }

  void _removeInvite(int index) {
    setState(() {
      _pendingInvites.removeAt(index);
    });
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  String _getRoleName(FamilyRole role) {
    switch (role) {
      case FamilyRole.elder:
        return 'Elder';
      case FamilyRole.primaryCaregiver:
        return 'Primary Caregiver';
      case FamilyRole.secondaryCaregiver:
        return 'Family Caregiver';
      case FamilyRole.youth:
        return 'Youth Member';
    }
  }

  String _getButtonText() {
    switch (_currentStep) {
      case 0:
        return 'Get Started';
      case 1:
        return widget.isCreatingFamily ? 'Create Family' : 'Join Family';
      case 2:
        return 'Continue';
      case 3:
        return 'Save Settings';
      case 4:
        return 'Complete Setup';
      default:
        return 'Next';
    }
  }
}

class PendingInvite {
  final String email;
  final FamilyRole suggestedRole;

  PendingInvite({
    required this.email,
    required this.suggestedRole,
  });
}