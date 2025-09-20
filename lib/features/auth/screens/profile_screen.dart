import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/user_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/services/voice_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  VoiceService? get _voice => context.read<VoiceService?>();

  Future<void> _signOut() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      await context.read<AuthProvider>().signOut();
      _voice?.announceAction('Signed out successfully');
      context.go('/login');
    }
  }

  Future<void> _signOutAllDevices() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out all devices'),
        content: const Text('This will sign you out from all devices. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out all'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      await context.read<AuthProvider>().signOut(allDevices: true);
      _voice?.announceAction('Signed out from all devices');
      context.go('/login');
    }
  }

  Future<void> _deleteAccount() async {
    final confirm1 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account'),
        content: const Text('This will permanently delete your account and all data. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Continue'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirm1 != true) return;

    final confirm2 = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Are you absolutely sure?'),
        content: const Text('Type "DELETE" to confirm account deletion.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete account'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirm2 == true && mounted) {
      // In real app, this would call a delete account service
      _voice?.announceError('Account deletion is not implemented in this demo');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deletion would happen here')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().profile;
    final textTheme = Theme.of(context).textTheme;

    if (profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: profile.photoUrl != null
                        ? NetworkImage(profile.photoUrl!)
                        : null,
                    child: profile.photoUrl == null
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile.name,
                    style: textTheme.headlineMedium,
                  ),
                  Text(
                    profile.email,
                    style: textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
                  ),
                  Text(
                    _roleLabel(profile.role),
                    style: textTheme.titleMedium?.copyWith(color: Theme.of(context).primaryColor),
                  ),
                ],
              ),
            ),

            // Profile Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _ProfileItem(
                    icon: Icons.edit,
                    title: 'Edit profile',
                    subtitle: 'Update your personal information',
                    onTap: () => context.push('/edit-profile'),
                  ),
                  _ProfileItem(
                    icon: Icons.phone,
                    title: 'Phone',
                    subtitle: profile.phone ?? 'Not set',
                    onTap: () => context.push('/edit-profile'),
                  ),
                  if (profile.age != null)
                    _ProfileItem(
                      icon: Icons.cake,
                      title: 'Age',
                      subtitle: '${profile.age} years old',
                    ),
                  _ProfileItem(
                    icon: Icons.family_restroom,
                    title: 'Family groups',
                    subtitle: 'Manage your family connections',
                    onTap: () => context.push('/family-members'),
                  ),
                  _ProfileItem(
                    icon: Icons.accessibility,
                    title: 'Accessibility',
                    subtitle: 'Customize your experience',
                    onTap: () => context.push('/accessibility-settings'),
                  ),
                  _ProfileItem(
                    icon: Icons.security,
                    title: 'Security',
                    subtitle: 'Password and biometric settings',
                    onTap: () => context.push('/security-settings'),
                  ),
                  _ProfileItem(
                    icon: Icons.privacy_tip,
                    title: 'Privacy',
                    subtitle: 'Manage your data and privacy',
                    onTap: () => context.push('/privacy-settings'),
                  ),
                  _ProfileItem(
                    icon: Icons.help,
                    title: 'Help & Support',
                    subtitle: 'Get help using FamilyBridge',
                    onTap: () => context.push('/help'),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Sign out options
                  Card(
                    color: Colors.red.shade50,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.orange),
                          title: const Text('Sign out'),
                          subtitle: const Text('Sign out from this device only'),
                          onTap: _signOut,
                        ),
                        ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text('Sign out all devices'),
                          subtitle: const Text('Sign out from all your devices'),
                          onTap: _signOutAllDevices,
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete_forever, color: Colors.red),
                          title: const Text('Delete account'),
                          subtitle: const Text('Permanently delete your account'),
                          onTap: _deleteAccount,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.elder:
        return 'Senior family member';
      case UserRole.caregiver:
        return 'Family caregiver';
      case UserRole.youth:
        return 'Young family member';
    }
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ProfileItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
      ),
    );
  }
}