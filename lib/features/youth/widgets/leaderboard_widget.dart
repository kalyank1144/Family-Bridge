import 'package:flutter/material.dart';

import 'package:family_bridge/core/services/gamification_service.dart';

class LeaderboardWidget extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  const LeaderboardWidget({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Family Leaderboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        ...entries.asMap().entries.take(5).map((e) {
          final rank = e.key + 1;
          final item = e.value;
          final color = rank == 1 ? const Color(0xFFFFD54F) : rank == 2 ? Colors.grey.shade400 : const Color(0xFFCD7F32);
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))]),
            child: Row(
              children: [
                CircleAvatar(radius: 16, backgroundColor: color, child: Text(rank.toString(), style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.white))),
                const SizedBox(width: 12),
                Text(item.avatar, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                Text('${item.points} pts', style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.black54)),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}