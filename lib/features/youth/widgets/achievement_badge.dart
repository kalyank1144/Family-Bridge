import 'package:flutter/material.dart';
import '../../../core/services/gamification_service.dart';

class AchievementBadge extends StatelessWidget {
  final Achievement achievement;
  const AchievementBadge({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.unlockedAt != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: unlocked ? [const Color(0xFF6EE7F9), const Color(0xFF7C3AED)] : [Colors.grey.shade300, Colors.grey.shade200]),
            shape: BoxShape.circle,
            boxShadow: [
              if (unlocked) BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 8)),
            ],
          ),
          child: Center(child: Text(achievement.icon, style: const TextStyle(fontSize: 28))),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 90,
          child: Text(
            achievement.title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: unlocked ? Colors.black : Colors.black38),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}