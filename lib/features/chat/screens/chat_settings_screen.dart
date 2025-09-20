import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/presence_model.dart';
import '../../../core/models/message_model.dart';
import '../providers/chat_providers.dart';
import '../services/chat_service.dart';

class ChatSettingsScreen extends ConsumerStatefulWidget {
  final String familyId;
  final String userType;

  const ChatSettingsScreen({
    super.key,
    required this.familyId,
    required this.userType,
  });

  @override
  ConsumerState<ChatSettingsScreen> createState() => _ChatSettingsScreenState();
}

class _ChatSettingsScreenState extends ConsumerState<ChatSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundsEnabled = true;
  bool _autoPlayVoice = true;
  String _textSize = 'Large';
  bool _emergencyAlerts = true;
  bool _showReadReceipts = true;
  bool _saveMediaToGallery = false;

  @override
  Widget build(BuildContext context) {
    final isElder = widget.userType == 'elder';
    final isCaregiver = widget.userType == 'caregiver';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _getAccentColor(),
        title: Text(
          'Chat Settings',
          style: TextStyle(
            fontSize: isElder ? 24 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            size: isElder ? 28 : 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        children: [
          // Family Members Section
          _buildSectionHeader('Family Members'),
          _buildFamilyMembersList(),
          
          // Notification Settings
          _buildSectionHeader('Notifications'),
          _buildSettingTile(
            icon: Icons.notifications_rounded,
            title: 'Message Notifications',
            subtitle: 'Get notified for new messages',
            value: _notificationsEnabled,
            onChanged: (value) => setState(() => _notificationsEnabled = value),
          ),
          _buildSettingTile(
            icon: Icons.volume_up_rounded,
            title: 'Message Sounds',
            subtitle: 'Play sound for incoming messages',
            value: _soundsEnabled,
            onChanged: (value) => setState(() => _soundsEnabled = value),
          ),
          if (isCaregiver || isElder)
            _buildSettingTile(
              icon: Icons.warning_amber_rounded,
              title: 'Emergency Alerts',
              subtitle: 'Always notify for emergency messages',
              value: _emergencyAlerts,
              onChanged: (value) => setState(() => _emergencyAlerts = value),
              iconColor: Colors.orange,
            ),
          
          // Accessibility Settings
          if (isElder) ...[
            _buildSectionHeader('Accessibility'),
            _buildListTile(
              icon: Icons.text_fields_rounded,
              title: 'Text Size',
              subtitle: _textSize,
              onTap: _showTextSizeDialog,
            ),
            _buildSettingTile(
              icon: Icons.mic_rounded,
              title: 'Auto-play Voice Messages',
              subtitle: 'Automatically play incoming voice messages',
              value: _autoPlayVoice,
              onChanged: (value) => setState(() => _autoPlayVoice = value),
            ),
          ],
          
          // Privacy Settings
          _buildSectionHeader('Privacy'),
          _buildSettingTile(
            icon: Icons.done_all_rounded,
            title: 'Read Receipts',
            subtitle: 'Let others know when you\'ve read messages',
            value: _showReadReceipts,
            onChanged: (value) => setState(() => _showReadReceipts = value),
          ),
          
          // Media Settings
          _buildSectionHeader('Media'),
          _buildSettingTile(
            icon: Icons.download_rounded,
            title: 'Save to Gallery',
            subtitle: 'Automatically save photos and videos',
            value: _saveMediaToGallery,
            onChanged: (value) => setState(() => _saveMediaToGallery = value),
          ),
          
          // Advanced Settings
          if (isCaregiver) ...[
            _buildSectionHeader('Advanced'),
            _buildListTile(
              icon: Icons.cloud_download_rounded,
              title: 'Export Chat History',
              subtitle: 'Download chat history as PDF',
              onTap: _exportChatHistory,
            ),
            _buildListTile(
              icon: Icons.cleaning_services_rounded,
              title: 'Clear Chat History',
              subtitle: 'Remove all messages from this chat',
              onTap: _clearChatHistory,
              iconColor: Colors.red,
              textColor: Colors.red,
            ),
          ],
          
          // Emergency Features
          _buildSectionHeader('Emergency Features'),
          _buildEmergencySection(),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    final isElder = widget.userType == 'elder';
    
    return Container(
      padding: EdgeInsets.fromLTRB(20, isElder ? 24 : 20, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: isElder ? 14 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildFamilyMembersList() {
    final presenceAsync = ref.watch(presenceStreamProvider(widget.familyId));
    final isElder = widget.userType == 'elder';
    
    return presenceAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
      data: (presence) {
        final members = presence.values.toList();
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: members.map((member) => ListTile(
              leading: Stack(
                children: [
                  CircleAvatar(
                    radius: isElder ? 28 : 24,
                    backgroundColor: _getUserTypeColor(member.userType),
                    child: Text(
                      member.userName[0].toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isElder ? 20 : 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (member.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              title: Text(
                member.userName,
                style: TextStyle(
                  fontSize: isElder ? 18 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                member.isOnline 
                    ? 'Active now' 
                    : 'Last seen ${_formatLastSeen(member.lastSeen)}',
                style: TextStyle(
                  fontSize: isElder ? 14 : 12,
                  color: member.isOnline ? Colors.green : Colors.grey,
                ),
              ),
              trailing: widget.userType == 'caregiver' 
                  ? IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showMemberOptions(member),
                    )
                  : null,
            )).toList(),
          ),
        );
      },
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? iconColor,
  }) {
    final isElder = widget.userType == 'elder';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? _getAccentColor()).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor ?? _getAccentColor(),
            size: isElder ? 28 : 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: isElder ? 18 : 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: isElder ? 14 : 12,
            color: Colors.grey.shade600,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: _getAccentColor(),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    final isElder = widget.userType == 'elder';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? _getAccentColor()).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor ?? _getAccentColor(),
            size: isElder ? 28 : 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: isElder ? 18 : 16,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: isElder ? 14 : 12,
            color: textColor?.withOpacity(0.7) ?? Colors.grey.shade600,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          size: isElder ? 28 : 24,
          color: Colors.grey.shade400,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildEmergencySection() {
    final isElder = widget.userType == 'elder';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.shade50,
            Colors.orange.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emergency_rounded,
                color: Colors.red,
                size: isElder ? 32 : 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Broadcast',
                      style: TextStyle(
                        fontSize: isElder ? 20 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade800,
                      ),
                    ),
                    Text(
                      'Send urgent message to all family members',
                      style: TextStyle(
                        fontSize: isElder ? 14 : 12,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: isElder ? 56 : 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(
                Icons.warning_rounded,
                size: isElder ? 24 : 20,
              ),
              label: Text(
                'Send Emergency Alert',
                style: TextStyle(
                  fontSize: isElder ? 18 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: _sendEmergencyAlert,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAccentColor() {
    switch (widget.userType) {
      case 'elder':
        return Colors.blue.shade700;
      case 'caregiver':
        return Colors.teal.shade700;
      case 'youth':
        return Colors.purple.shade700;
      default:
        return Colors.blue;
    }
  }

  Color _getUserTypeColor(String userType) {
    switch (userType) {
      case 'elder':
        return Colors.blue.shade700;
      case 'caregiver':
        return Colors.teal.shade700;
      case 'youth':
        return Colors.purple.shade700;
      default:
        return Colors.grey;
    }
  }

  String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'recently';
    
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showTextSizeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Text Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Small', 'Medium', 'Large', 'Extra Large'].map((size) {
            return RadioListTile<String>(
              title: Text(size),
              value: size,
              groupValue: _textSize,
              onChanged: (value) {
                setState(() => _textSize = value!);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showMemberOptions(PresenceInfo member) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('View Profile'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.message_outlined),
              title: const Text('Send Direct Message'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: const Text('Start Voice Call'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            if (widget.userType == 'caregiver')
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: const Text(
                  'Mute Member',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _exportChatHistory() async {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exporting chat history...'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  void _clearChatHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History?'),
        content: const Text(
          'This will permanently delete all messages in this chat. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              HapticFeedback.heavyImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chat history cleared'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _sendEmergencyAlert() {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Send Emergency Alert?'),
          ],
        ),
        content: const Text(
          'This will immediately notify all family members with an emergency message. Use only for urgent situations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {
              Navigator.pop(context);
              ref.read(chatServiceProvider).sendMessage(
                content: '🚨 EMERGENCY ALERT: I need immediate assistance!',
                type: MessageType.announcement,
                priority: MessagePriority.emergency,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Emergency alert sent to all family members'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Send Alert'),
          ),
        ],
      ),
    );
  }
}