import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/roles.dart';
import '../providers/auth_providers.dart';
import '../widgets/family_code_input.dart';

class CaregiverRegistrationScreen extends ConsumerStatefulWidget {
  const CaregiverRegistrationScreen({super.key});
  @override
  ConsumerState<CaregiverRegistrationScreen> createState() => _CaregiverRegistrationScreenState();
}

class _CaregiverRegistrationScreenState extends ConsumerState<CaregiverRegistrationScreen> {
  final emailC = TextEditingController();
  final passC = TextEditingController();
  final familyNameC = TextEditingController();
  final codeC = TextEditingController();
  bool createFamily = true;
  bool sending = false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authServiceProvider);
    final family = ref.watch(familyServiceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Caregiver registration')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Create family')),
                  ButtonSegment(value: false, label: Text('Join with code')),
                ],
                selected: {createFamily},
                onSelectionChanged: (s) => setState(() => createFamily = s.first),
              ),
              const SizedBox(height: 16),
              TextField(controller: emailC, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              TextField(controller: passC, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
              const SizedBox(height: 12),
              if (createFamily) ...[
                TextField(controller: familyNameC, decoration: const InputDecoration(labelText: 'Family name')),
              ] else ...[
                FamilyCodeInput(controller: codeC),
              ],
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 60),
                child: FilledButton(
                  onPressed: sending
                      ? null
                      : () async {
                          setState(() => sending = true);
                          try {
                            final res = await auth.signUpWithEmail(email: emailC.text.trim(), password: passC.text, userType: UserType.caregiver.name);
                            if (res.user == null) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check your email to verify your account.')));
                              }
                              return;
                            }
                            if (createFamily) {
                              final fam = await family.createFamily(name: familyNameC.text.trim().isEmpty ? 'Family' : familyNameC.text.trim());
                              await family.joinFamily(familyId: fam['id'] as String, role: UserType.caregiver);
                              if (mounted) context.go('/caregiver');
                            } else {
                              final fam = await family.getFamilyByCode(codeC.text.trim().toUpperCase());
                              if (fam == null) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid family code')));
                                }
                                return;
                              }
                              await family.joinFamily(familyId: fam['id'] as String, role: UserType.caregiver);
                              if (mounted) context.go('/caregiver');
                            }
                          } finally {
                            setState(() => sending = false);
                          }
                        },
                  child: const Text('Create account'),
                ),
              ),
              const SizedBox(height: 8),
              const Text('You will receive a verification email after sign up.'),
            ],
          ),
        ),
      ),
    );
  }
}