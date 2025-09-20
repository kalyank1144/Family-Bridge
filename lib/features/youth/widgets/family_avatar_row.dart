import 'package:flutter/material.dart';
import '../../caregiver/models/family_member.dart';

class FamilyAvatarRow extends StatelessWidget {
  final List<FamilyMember> family;
  final void Function(FamilyMember)? onTap;

  const FamilyAvatarRow({super.key, required this.family, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: family.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final m = family[index];
          return GestureDetector(
            onTap: onTap != null ? () => onTap!(m) : null,
            child: Column(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey.shade200,
                      child: Text(m.name.characters.first, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: m.isOnline ? const Color(0xFF22C55E) : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(m.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        },
      ),
    );
  }
}