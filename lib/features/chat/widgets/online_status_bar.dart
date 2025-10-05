import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:family_bridge/features/chat/models/presence_model.dart';
import 'package:family_bridge/features/chat/providers/chat_providers.dart';

class OnlineStatusBar extends ConsumerWidget {
  final String familyId;
  final String userType;

  const OnlineStatusBar({
    super.key,
    required this.familyId,
    required this.userType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presenceAsync = ref.watch(presenceStreamProvider(familyId));
    
    return presenceAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (presenceMap) {
        final onlineMembers = presenceMap.values
            .where((p) => p.isOnline)
            .toList();
        
        if (onlineMembers.isEmpty) {
          return const SizedBox.shrink();
        }
        
        final isElder = userType == 'elder';
        
        return Container(
          height: isElder ? 80 : 60,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            border: Border(
              bottom: BorderSide(
                color: Colors.green.shade200,
                width: 1,
              ),
            ),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: onlineMembers.length,
            itemBuilder: (context, index) {
              final member = onlineMembers[index];
              return _buildMemberAvatar(member, isElder);
            },
          ),
        );
      },
    );
  }

  Widget _buildMemberAvatar(FamilyMemberPresence member, bool isElder) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: isElder ? 24 : 20,
                backgroundColor: _getUserColor(member.userType),
                backgroundImage: member.avatarUrl != null
                    ? NetworkImage(member.avatarUrl!)
                    : null,
                child: member.avatarUrl == null
                    ? Text(
                        member.userName[0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isElder ? 18 : 14,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: isElder ? 14 : 12,
                  height: isElder ? 14 : 12,
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
          const SizedBox(height: 4),
          Text(
            member.userName.split(' ')[0],
            style: TextStyle(
              fontSize: isElder ? 14 : 12,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getUserColor(String userType) {
    switch (userType) {
      case 'elder':
        return Colors.blue.shade700;
      case 'caregiver':
        return Colors.teal.shade700;
      case 'youth':
        return Colors.purple.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
}