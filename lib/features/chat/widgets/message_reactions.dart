import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/message_model.dart';

class MessageReactions extends StatelessWidget {
  final List<MessageReaction> reactions;
  final String userType;
  final Function(String)? onAddReaction;

  const MessageReactions({
    super.key,
    required this.reactions,
    required this.userType,
    this.onAddReaction,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) {
      return const SizedBox.shrink();
    }

    final reactionGroups = _groupReactions();
    final isElder = userType == 'elder';

    return Container(
      margin: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: reactionGroups.entries.map((entry) {
          final emoji = entry.key;
          final users = entry.value;
          
          return GestureDetector(
            onTap: () {
              if (onAddReaction != null) {
                HapticFeedback.lightImpact();
                onAddReaction!(emoji);
              }
            },
            onLongPress: () => _showReactionDetails(context, emoji, users),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isElder ? 10 : 8,
                vertical: isElder ? 6 : 4,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    emoji,
                    style: TextStyle(fontSize: isElder ? 18 : 14),
                  ),
                  if (users.length > 1) ...[
                    const SizedBox(width: 4),
                    Text(
                      users.length.toString(),
                      style: TextStyle(
                        fontSize: isElder ? 14 : 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Map<String, List<MessageReaction>> _groupReactions() {
    final Map<String, List<MessageReaction>> groups = {};
    
    for (final reaction in reactions) {
      if (!groups.containsKey(reaction.emoji)) {
        groups[reaction.emoji] = [];
      }
      groups[reaction.emoji]!.add(reaction);
    }
    
    return groups;
  }

  void _showReactionDetails(
    BuildContext context,
    String emoji,
    List<MessageReaction> users,
  ) {
    HapticFeedback.mediumImpact();
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Text(
                  '${users.length} ${users.length == 1 ? 'reaction' : 'reactions'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...users.map((reaction) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: _getUserColor(reaction.userId),
                    child: Text(
                      reaction.userName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    reaction.userName,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Color _getUserColor(String userId) {
    final colors = [
      Colors.blue,
      Colors.teal,
      Colors.purple,
      Colors.orange,
      Colors.green,
      Colors.red,
    ];
    
    final index = userId.hashCode % colors.length;
    return colors[index];
  }
}