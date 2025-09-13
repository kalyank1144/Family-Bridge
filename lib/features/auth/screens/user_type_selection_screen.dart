import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/roles.dart';
import '../providers/auth_providers.dart';
import '../widgets/role_card.dart';

class UserTypeSelectionScreen extends ConsumerWidget {
  const UserTypeSelectionScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedRoleProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Choose your role')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  RoleCard(
                    icon: Icons.elderly,
                    title: 'Elder',
                    description: 'Simple, voice-assisted experience',
                    selected: selected == UserType.elder,
                    onTap: () => ref.read(selectedRoleProvider.notifier).state = UserType.elder,
                  ),
                  RoleCard(
                    icon: Icons.favorite,
                    title: 'Caregiver',
                    description: 'Full control and scheduling',
                    selected: selected == UserType.caregiver,
                    onTap: () => ref.read(selectedRoleProvider.notifier).state = UserType.caregiver,
                  ),
                  RoleCard(
                    icon: Icons.child_care,
                    title: 'Youth',
                    description: 'Connect with your family group',
                    selected: selected == UserType.youth,
                    onTap: () => ref.read(selectedRoleProvider.notifier).state = UserType.youth,
                  ),
                ],
              ),
              const Spacer(),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 60),
                child: FilledButton(
                  onPressed: selected == null
                      ? null
                      : () {
                          switch (selected) {
                            case UserType.elder:
                              context.go('/onboarding/register-elder');
                              break;
                            case UserType.caregiver:
                              context.go('/onboarding/register-caregiver');
                              break;
                            case UserType.youth:
                              context.go('/onboarding/register-youth');
                              break;
                            default:
                          }
                        },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    child: Text('Continue'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}