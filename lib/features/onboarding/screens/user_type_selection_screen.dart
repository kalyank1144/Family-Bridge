import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/user_type_provider.dart';

class UserTypeSelectionScreen extends StatefulWidget {
  const UserTypeSelectionScreen({super.key});

  @override
  State<UserTypeSelectionScreen> createState() => _UserTypeSelectionScreenState();
}

class _UserTypeSelectionScreenState extends State<UserTypeSelectionScreen> {
  UserType? _selected;

  void _onContinue(UserTypeProvider provider) async {
    if (_selected == null) return;
    await provider.setUserType(_selected!);
    switch (_selected!) {
      case UserType.elder:
        if (!mounted) return;
        context.go('/elder');
        break;
      case UserType.caregiver:
        if (!mounted) return;
        context.go('/caregiver');
        break;
      case UserType.youth:
        if (!mounted) return;
        context.go('/youth');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserTypeProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Select User Type'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Who are you?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose your role to personalize your experience',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              _RoleCard(
                icon: Icons.elderly,
                title: 'I am an Elder',
                subtitle: 'Simple interface with voice commands',
                color: AppTheme.primaryBlue,
                selected: _selected == UserType.elder,
                onTap: () => setState(() => _selected = UserType.elder),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                icon: Icons.volunteer_activism,
                title: 'I am a Caregiver',
                subtitle: 'Monitor and coordinate family care',
                color: AppTheme.successGreen,
                selected: _selected == UserType.caregiver,
                onTap: () => setState(() => _selected = UserType.caregiver),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                icon: Icons.group,
                title: 'I am Youth/Family',
                subtitle: 'Help and connect with family',
                color: AppTheme.secondaryColor,
                selected: _selected == UserType.youth,
                onTap: () => setState(() => _selected = UserType.youth),
              ),
              const Spacer(),
              Semantics(
                button: true,
                enabled: _selected != null,
                label: 'Continue',
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selected == null ? null : () => _onContinue(provider),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(64),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
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

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: title,
      hint: subtitle,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? color : Colors.grey.shade200,
              width: selected ? 3 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(minHeight: 96),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 36),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? color : Colors.transparent,
                  border: Border.all(color: selected ? color : Colors.grey.shade300, width: 2),
                ),
                child: selected
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}