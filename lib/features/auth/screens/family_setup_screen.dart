import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:family_bridge/core/models/family_model.dart';
import 'package:family_bridge/core/services/auth_service.dart';
import 'package:family_bridge/core/services/voice_service.dart';
import 'package:family_bridge/core/theme/app_theme.dart';
import 'package:family_bridge/features/auth/providers/auth_provider.dart';

class FamilySetupScreen extends StatefulWidget {
  const FamilySetupScreen({super.key});

  @override
  State<FamilySetupScreen> createState() => _FamilySetupScreenState();
}

class _FamilySetupScreenState extends State<FamilySetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _familyNameController = TextEditingController();
  final _joinCodeController = TextEditingController();

  bool _isCreatingFamily = true;
  bool _loading = false;
  FamilyRole _selectedRole = FamilyRole.elder;

  VoiceService? get _voice => context.read<VoiceService?>();

  @override
  void dispose() {
    _familyNameController.dispose();
    _joinCodeController.dispose();
    super.dispose();
  }

  Future<void> _createFamily() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _loading = true);
    try {
      final family = await AuthService.instance.createFamilyGroup(
        name: _familyNameController.text.trim(),
      );
      
      _voice?.announceAction('Family group created successfully. Code: ${family.code}');
      _showSuccessDialog(family);
    } catch (e) {
      _voice?.announceError('Failed to create family group');
      _showSnack('Failed to create family group. Please try again.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _joinFamily() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _loading = true);
    try {
      await AuthService.instance.joinFamilyByCode(
        code: _joinCodeController.text.trim().toUpperCase(),
        role: _selectedRole,
      );
      
      _voice?.announceAction('Successfully joined family group');
      _showSnack('Successfully joined family!');
      
      if (mounted) context.go(context.read<AuthProvider>().roleBasedHomePath());
    } catch (e) {
      _voice?.announceError('Failed to join family group. Please check the code.');
      _showSnack('Failed to join family. Please check the code.');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showSuccessDialog(FamilyGroup family) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Family created!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your family "${family.name}" has been created.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    'Family Code',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    family.code,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: family.code));
                      _showSnack('Code copied to clipboard');
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy code'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Share this code with family members so they can join your group.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go(context.read<AuthProvider>().roleBasedHomePath());
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final profile = context.watch<AuthProvider>().profile;

    // Set default role based on user profile
    if (profile != null) {
      switch (profile.role) {
        case UserRole.elder:
          _selectedRole = FamilyRole.elder;
          break;
        case UserRole.caregiver:
          _selectedRole = FamilyRole.primaryCaregiver;
          break;
        case UserRole.youth:
          _selectedRole = FamilyRole.youth;
          break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family setup'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Connect with your family',
                style: textTheme.displaySmall,
                semanticsLabel: 'Connect with your family. Create or join a family group',
              ),
              const SizedBox(height: 8),
              Text(
                'Create a new family group or join an existing one using a family code.',
                style: textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),

              // Toggle between create and join
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text('Create family'),
                    icon: Icon(Icons.add_circle),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('Join family'),
                    icon: Icon(Icons.group_add),
                  ),
                ],
                selected: {_isCreatingFamily},
                onSelectionChanged: (Set<bool> selection) {
                  setState(() => _isCreatingFamily = selection.first);
                },
              ),
              const SizedBox(height: 32),

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_isCreatingFamily) ...[
                      TextFormField(
                        controller: _familyNameController,
                        decoration: const InputDecoration(
                          labelText: 'Family name',
                          hintText: 'The Smith Family',
                          prefixIcon: Icon(Icons.family_restroom),
                        ),
                        style: textTheme.bodyLarge?.copyWith(fontSize: 20),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Family name is required';
                          if (v.trim().length < 3) return 'Family name must be at least 3 characters';
                          return null;
                        },
                      ),
                    ] else ...[
                      TextFormField(
                        controller: _joinCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Family code',
                          hintText: 'FAMILY123',
                          prefixIcon: Icon(Icons.key),
                        ),
                        style: textTheme.bodyLarge?.copyWith(
                          fontSize: 20,
                          letterSpacing: 2,
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Family code is required';
                          if (v.trim().length < 6) return 'Please enter a valid family code';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your role in the family:',
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      ...FamilyRole.values.map((role) => RadioListTile<FamilyRole>(
                            title: Text(_roleLabel(role)),
                            subtitle: Text(_roleDescription(role)),
                            value: role,
                            groupValue: _selectedRole,
                            onChanged: (v) => setState(() => _selectedRole = v!),
                            contentPadding: EdgeInsets.zero,
                          )),
                    ],
                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: _loading ? null : (_isCreatingFamily ? _createFamily : _joinFamily),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: _loading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(_isCreatingFamily ? 'Create family' : 'Join family'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              TextButton(
                onPressed: () => context.go(context.read<AuthProvider>().roleBasedHomePath()),
                child: const Text('Skip for now'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _roleLabel(FamilyRole role) {
    switch (role) {
      case FamilyRole.primaryCaregiver:
        return 'Primary caregiver';
      case FamilyRole.secondaryCaregiver:
        return 'Secondary caregiver';
      case FamilyRole.elder:
        return 'Senior family member';
      case FamilyRole.youth:
        return 'Young family member';
    }
  }

  String _roleDescription(FamilyRole role) {
    switch (role) {
      case FamilyRole.primaryCaregiver:
        return 'Main person responsible for care coordination';
      case FamilyRole.secondaryCaregiver:
        return 'Assists with care and support';
      case FamilyRole.elder:
        return 'Receives care and support from family';
      case FamilyRole.youth:
        return 'Young family member staying connected';
    }
  }
}