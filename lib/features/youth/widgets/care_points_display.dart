import 'package:flutter/material.dart';

class CarePointsDisplay extends StatelessWidget {
  final int points;
  const CarePointsDisplay({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFF8A00), Color(0xFFFFC167)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color(0xFFFF8A00).withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.favorite, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              Text('Care Points', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
              SizedBox(height: 2),
              Text('Engage with family to earn', style: TextStyle(color: Colors.white, fontSize: 12)),
            ]),
          ),
          Text(points.toString(), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}