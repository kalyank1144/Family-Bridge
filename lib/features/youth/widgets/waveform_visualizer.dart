import 'package:flutter/material.dart';

class WaveformVisualizer extends StatelessWidget {
  final double amplitude;
  const WaveformVisualizer({super.key, required this.amplitude});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(24, (i) {
          final h = 10.0 + (amplitude * 60.0 * ((i % 3) == 0 ? 1.0 : 0.7));
          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 4,
            height: h,
            decoration: BoxDecoration(
              color: Colors.orangeAccent,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}