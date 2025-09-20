import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/family_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/services/voice_service.dart';

class FamilyMembersScreen extends StatefulWidget {
  const FamilyMembersScreen({super.key});

  @override
  State<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends State<FamilyMembersScreen> {
  final _inviteEmailController = TextEditingController();
  
  List<Map<String, dynamic>> _familyMembers = [];
  String? _familyCode;
  bool _loading = false;

  VoiceService? get _voice => context.read<VoiceService?>();

  @override
  void initState() {
    super.initState();
    _loadFamilyMembers();
  }

  @override
  void dispose() {
    _inviteEmailController.dispose();
    super.dispose();
  }

  Future<void> _loadFamilyMembers() async {
    setState(() => _loading = true);
    try {
      // In real app, would get family ID from user's family membership
      const demoFamilyId = 'demo-family-123';
      final members = await AuthService.instance.listFamilyMembers(demoFamilyId);
      setState(() {
        _familyMembers = members;
        _familyCode = 'DEMO123'; // Would come from API
      });
    } catch (e) {
      _voice?.announceError('Failed to load family members');
      _showSnack('Failed to load family members');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _inviteMember(FamilyRole role) async {
    if (_inviteEmailController.text.trim().isEmpty) {
      _showSnack('Please enter an email address');
      return;
    }

    try {
      await AuthService.instance.inviteFamilyMember(
        familyId: 'demo-family-123',
        email: _inviteEmailController.text.trim(),
        role: role,
      );
      
      _voice?.announceAction('Invitation sent successfully');
      _showSnack('Invitation sent!');
      _inviteEmailController.clear();
      Navigator.pop(context);
    } catch (e) {
      _voice?.announceError('Failed to send invitation');
      _showSnack('Failed to send invitation');
    }
  }

  Future<void> _removeMember(String userId, String memberName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove member'),
        content: Text('Are you sure you want to remove $memberName from the family?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await AuthService.instance.removeFamilyMember(
          familyId: 'demo-family-123',
          userId: userId,
        );
        _voice?.announceAction('Family member removed');
        _showSnack('Member removed');
        _loadFamilyMembers();
      } catch (e) {
        _voice?.announceError('Failed to remove member');
        _showSnack('Failed to remove member');
      }
    }
  }

  void _showInviteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite family member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _inviteEmailController,
              decoration: const InputDecoration(
                labelText: 'Email address',
                hintText: 'member@example.com',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            const Text('Select their role:'),
            const SizedBox(height: 8),
            ...FamilyRole.values.map((role) => ListTile(
                  title: Text(_roleLabel(role)),
                  subtitle: Text(_roleDescription(role)),
                  onTap: () => _inviteMember(role),
                  dense: true,
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _inviteEmailController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family members'),
        actions: [
          IconButton(
            onPressed: _showInviteDialog,
            icon: const Icon(Icons.person_add),
            tooltip: 'Invite member',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Family code section
                  if (_familyCode != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Family Code',
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _familyCode!,
                            style: textTheme.headlineMedium?.copyWith(
                              letterSpacing: 2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _familyCode!));
                              _showSnack('Code copied to clipboard');
                            },
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy code'),
                          ),
                          Text(
                            'Share this code with family members to join',
                            style: textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                  // Family members list
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Family members (${_familyMembers.length})',
                          style: textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        if (_familyMembers.isEmpty)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  const Icon(Icons.people, size: 48, color: Colors.grey),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No family members yet',
                                    style: textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Invite family members to get started',
                                    style: textTheme.bodyMedium?.copyWith(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _showInviteDialog,
                                    icon: const Icon(Icons.person_add),
                                    label: const Text('Invite member'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...(_familyMembers.map((member) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _getRoleColor(member['role'] as String?),
                                    child: Text(
                                      (member['name'] as String? ?? 'U')[0].toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Text(member['name'] as String? ?? 'Unknown'),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_roleLabel(_parseRole(member['role'] as String?))),
                                      if (member['last_active'] != null)
                                        Text(
                                          'Last active: ${_formatLastActive(member['last_active'] as String)}',
                                          style: textTheme.bodySmall,
                                        ),
                                    ],
                                  ),
                                  trailing: member['permissions'] == 'owner'
                                      ? const Icon(Icons.star, color: Colors.amber)
                                      : PopupMenuButton(
                                          onSelected: (action) {
                                            if (action == 'remove') {
                                              _removeMember(
                                                member['user_id'] as String? ?? '',
                                                member['name'] as String? ?? 'Unknown',
                                              );
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 'remove',
                                              child: Text('Remove from family'),
                                            ),
                                          ],
                                        ),
                                  isThreeLine: member['last_active'] != null,
                                ),
                              ))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showInviteDialog,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Color _getRoleColor(String? role) {
    switch (_parseRole(role)) {
      case FamilyRole.primaryCaregiver:
        return Colors.blue;
      case FamilyRole.secondaryCaregiver:
        return Colors.teal;
      case FamilyRole.elder:
        return Colors.purple;
      case FamilyRole.youth:
        return Colors.orange;
    }
  }

  FamilyRole _parseRole(String? role) {
    return FamilyRole.values.firstWhere(
      (e) => e.name == (role ?? 'youth').replaceAll('-', ''),
      orElse: () => FamilyRole.youth,
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

  String _formatLastActive(String lastActive) {
    try {
      final date = DateTime.parse(lastActive);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}