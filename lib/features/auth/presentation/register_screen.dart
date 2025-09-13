import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../providers/auth_providers.dart';
import '../../../core/config/theme_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final emailC = TextEditingController();
  final passC = TextEditingController();
  String userType = 'caregiver';

  @override
  Widget build(BuildContext context) {
    final authRepo = ref.watch(authRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: userType,
              items: const [
                DropdownMenuItem(value: 'elder', child: Text('Elder')),
                DropdownMenuItem(value: 'caregiver', child: Text('Caregiver')),
                DropdownMenuItem(value: 'youth', child: Text('Youth')),
              ],
              onChanged: (v) {
                setState(() => userType = v ?? 'caregiver');
                switch (userType) {
                  case 'elder':
                    ref.read(themeProvider.notifier).setTheme(AppTheme.elder);
                    break;
                  case 'caregiver':
                    ref.read(themeProvider.notifier).setTheme(AppTheme.caregiver);
                    break;
                  case 'youth':
                    ref.read(themeProvider.notifier).setTheme(AppTheme.youth);
                    break;
                }
              },
              decoration: const InputDecoration(labelText: 'Role'),
            ),
            const SizedBox(height: 12),
            AppTextField(controller: emailC, label: 'Email', keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            AppTextField(controller: passC, label: 'Password', obscure: true),
            const SizedBox(height: 16),
            AppButton(
              label: 'Sign up',
              onPressed: () async {
                await authRepo.signUpWithEmail(email: emailC.text.trim(), password: passC.text, userType: userType);
              },
            ),
          ],
        ),
      ),
    );
  }
}
