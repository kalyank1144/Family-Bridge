import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Family Icon
              Container(
                width: 80,
                height: 60,
                child: CustomPaint(
                  painter: FamilyIconPainter(),
                ),
              ),
              const SizedBox(height: 24),
              
              // Title
              const Text(
                'FamilyBridge',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 16),
              
              // Subtitle
              const Text(
                'Connecting Generations\nThrough Care',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF666666),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 48),
              
              // User Type Preview Cards
              _buildUserTypeCard(Icons.accessibility_new, 'Elder'),
              const SizedBox(height: 16),
              _buildUserTypeCard(Icons.favorite_outline, 'Caregiver'), 
              const SizedBox(height: 16),
              _buildUserTypeCard(Icons.person_outline, 'Youth'),
              const SizedBox(height: 32),
              
              // Get Started Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.push('/user-type'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF666666),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeCard(IconData icon, String title) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 2),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(icon, size: 24, color: Colors.black),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class FamilyIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Draw two connected people figures
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    
    // Left figure (larger)
    // Head
    canvas.drawCircle(Offset(centerX - 20, centerY - 15), 8, paint);
    // Body
    canvas.drawLine(
      Offset(centerX - 20, centerY - 7),
      Offset(centerX - 20, centerY + 15),
      paint,
    );
    // Arms (connected to right figure)
    canvas.drawLine(
      Offset(centerX - 20, centerY),
      Offset(centerX - 5, centerY),
      paint,
    );
    
    // Right figure (smaller)
    // Head
    canvas.drawCircle(Offset(centerX + 15, centerY - 10), 6, paint);
    // Body
    canvas.drawLine(
      Offset(centerX + 15, centerY - 4),
      Offset(centerX + 15, centerY + 15),
      paint,
    );
    // Arms (connected from left figure)
    canvas.drawLine(
      Offset(centerX - 5, centerY),
      Offset(centerX + 15, centerY - 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}