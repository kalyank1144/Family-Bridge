import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';

import 'package:family_bridge/features/chat/models/presence_model.dart';

class TypingIndicatorWidget extends StatelessWidget {
  final List<TypingIndicator> typingUsers;
  final String userType;

  const TypingIndicatorWidget({
    super.key,
    required this.typingUsers,
    required this.userType,
  });

  @override
  Widget build(BuildContext context) {
    if (typingUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    final isElder = userType == 'elder';
    String typingText;
    
    if (typingUsers.length == 1) {
      typingText = '${typingUsers[0].userName} is typing';
    } else if (typingUsers.length == 2) {
      typingText = '${typingUsers[0].userName} and ${typingUsers[1].userName} are typing';
    } else {
      typingText = '${typingUsers.length} people are typing';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isElder ? 12 : 8,
      ),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          _buildDots(),
          const SizedBox(width: 8),
          Text(
            typingText,
            style: TextStyle(
              fontSize: isElder ? 16 : 14,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    ).animate(onPlay: (controller) => controller.repeat())
      .fadeIn(duration: 300.ms);
  }

  Widget _buildDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade500,
            shape: BoxShape.circle,
          ),
        ).animate(
          delay: (index * 200).ms,
          onPlay: (controller) => controller.repeat(),
        ).fadeIn(duration: 300.ms)
         .then()
         .fadeOut(duration: 300.ms);
      }),
    );
  }
}