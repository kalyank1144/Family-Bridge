import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/roles.dart';
import '../providers/auth_providers.dart';
import '../widgets/family_code_input.dart';

class YouthRegistrationScreen extends ConsumerStatefulWidget {
  const YouthRegistrationScreen({super.key});
  @override
  ConsumerState<YouthRegistrationScreen> createState() => _YouthRegistrationScreenState();
}

class _YouthRegistrationScreenState extends ConsumerState<YouthRegistrationScreen> {
  final emailC = TextEditingController();
  final passC = TextEditingController();
  final guardianEmailC = TextEditingController();
  final codeC = TextEditingController();
  bool sending = false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authServiceProvider);
    final family = ref.watch(familyServiceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Youth registration')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(controller: emailC, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              TextField(controller: passC, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
              const SizedBox(height: 12),
              TextField(controller: guardianEmailC, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Parent/guardian email')),
              const SizedBox(height: 12),
              FamilyCodeInput(controller: codeC),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 60),
                child: FilledButton(
                  onPressed: sending
                      ? null
                      : () async {
                          setState(() => sending = true);
                          try {
                            final res = await auth.signUpWithEmail(email: emailC.text.trim(), password: passC.text, userType: UserType.youth.name, metadata: {
                              'guardian_email': guardianEmailC.text.trim(),
                            });
                            if (res.user == null) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Check your email to verify your account.')));
                              }
                              return;
                            }
                            final fam = await family.getFamilyByCode(codeC.text.trim().toUpperCase());
                            if (fam == null) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid family code')));
                              }
                              return;
                            }
                            await family.joinFamily(familyId: fam['id'] as String, role: UserType.youth, relation: 'child');
                            // create approval request
                            await ref.read(supabaseProvider).from('user_approvals').insert({
                              'youth_id': res.user!.id,
                              'guardian_email': guardianEmailC.text.trim(),
                              'status': 'pending',
                            });
                            if (mounted) context.go('/youth');
                          } finally {
                            setState(() => sending = false);
                          }
                        },
                  child: const Text('Create account'),
                ),
              ),
              const SizedBox(height: 8),
              const Text('A parent/guardian will need to approve your account.'),
            ],
          ),
        ),
      ),
    );
  }
}