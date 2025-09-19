import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/user_type_provider.dart';

class UserTypeSelectionScreen extends StatefulWidget {
  const UserTypeSelectionScreen({super.key});

  @override
  State<UserTypeSelectionScreen> createState() => _UserTypeSelectionScreenState();
}

class _UserTypeSelectionScreenState extends State<UserTypeSelectionScreen> {
  UserType? _selected;

  void _onContinue(UserTypeProvider provider) async {
    if (_selected == null) return;
    await provider.setUserType(_selected!);
    switch (_selected!) {
      case UserType.elder:
        if (!mounted) return;
        context.go('/elder');
        break;
      case UserType.caregiver:
        if (!mounted) return;
        context.go('/caregiver');
        break;
      case UserType.youth:
        if (!mounted) return;
        context.go('/youth');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserTypeProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE0E0E0), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
                    onPressed: () => context.pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'USER TYPE SELECTION',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Elder Card
              _UserTypeCard(
                icon: const ElderIcon(),
                title: 'I am an Elder',
                subtitle: 'Simple interface\nwith voice commands',
                selected: _selected == UserType.elder,
                onTap: () => setState(() => _selected = UserType.elder),
              ),
              const SizedBox(height: 16),
              
              // Caregiver Card
              _UserTypeCard(
                icon: const CaregiverIcon(),
                title: 'I am a Caregiver',
                subtitle: 'Monitor and\ncoordinate family care',
                selected: _selected == UserType.caregiver,
                onTap: () => setState(() => _selected = UserType.caregiver),
              ),
              const SizedBox(height: 16),
              
              // Youth Card
              _UserTypeCard(
                icon: const YouthIcon(),
                title: 'I am\nYouth/Family',
                subtitle: 'Help and connect\nwith family',
                selected: _selected == UserType.youth,
                onTap: () => setState(() => _selected = UserType.youth),
              ),
              const SizedBox(height: 32),
              
              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selected == null ? null : () => _onContinue(provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF333333),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFCCCCCC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continue',
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
}

class _UserTypeCard extends StatelessWidget {
  final Widget icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _UserTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.black : const Color(0xFFE0E0E0),
            width: selected ? 3 : 2,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: icon,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF666666),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Icon Widgets
class ElderIcon extends StatelessWidget {
  const ElderIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ElderIconPainter(),
      size: const Size(60, 60),
    );
  }
}

class CaregiverIcon extends StatelessWidget {
  const CaregiverIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: CaregiverIconPainter(),
      size: const Size(60, 60),
    );
  }
}

class YouthIcon extends StatelessWidget {
  const YouthIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: YouthIconPainter(),
      size: const Size(60, 60),
    );
  }
}

// Custom Painters for Icons
class ElderIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Head
    canvas.drawCircle(Offset(centerX, centerY - 12), 8, paint);
    
    // Glasses
    canvas.drawCircle(Offset(centerX - 5, centerY - 12), 4, paint);
    canvas.drawCircle(Offset(centerX + 5, centerY - 12), 4, paint);
    canvas.drawLine(
      Offset(centerX - 1, centerY - 12),
      Offset(centerX + 1, centerY - 12),
      paint,
    );

    // Body
    canvas.drawLine(
      Offset(centerX, centerY - 4),
      Offset(centerX, centerY + 12),
      paint,
    );

    // Arms
    canvas.drawLine(
      Offset(centerX, centerY + 2),
      Offset(centerX - 8, centerY + 8),
      paint,
    );
    canvas.drawLine(
      Offset(centerX, centerY + 2),
      Offset(centerX + 8, centerY + 8),
      paint,
    );

    // Legs
    canvas.drawLine(
      Offset(centerX, centerY + 12),
      Offset(centerX - 6, centerY + 20),
      paint,
    );
    canvas.drawLine(
      Offset(centerX, centerY + 12),
      Offset(centerX + 6, centerY + 20),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class CaregiverIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Adult figure (larger, left)
    // Head
    canvas.drawCircle(Offset(centerX - 8, centerY - 10), 6, paint);
    // Body
    canvas.drawLine(
      Offset(centerX - 8, centerY - 4),
      Offset(centerX - 8, centerY + 8),
      paint,
    );
    // Arms
    canvas.drawLine(
      Offset(centerX - 8, centerY),
      Offset(centerX - 2, centerY + 3),
      paint,
    );
    // Legs
    canvas.drawLine(
      Offset(centerX - 8, centerY + 8),
      Offset(centerX - 12, centerY + 16),
      paint,
    );
    canvas.drawLine(
      Offset(centerX - 8, centerY + 8),
      Offset(centerX - 4, centerY + 16),
      paint,
    );

    // Child figure (smaller, right)
    // Head
    canvas.drawCircle(Offset(centerX + 8, centerY - 4), 4, paint);
    // Body
    canvas.drawLine(
      Offset(centerX + 8, centerY),
      Offset(centerX + 8, centerY + 8),
      paint,
    );
    // Arms (one connected to adult)
    canvas.drawLine(
      Offset(centerX + 8, centerY + 2),
      Offset(centerX + 2, centerY + 3),
      paint,
    );
    // Legs
    canvas.drawLine(
      Offset(centerX + 8, centerY + 8),
      Offset(centerX + 5, centerY + 14),
      paint,
    );
    canvas.drawLine(
      Offset(centerX + 8, centerY + 8),
      Offset(centerX + 11, centerY + 14),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class YouthIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Head
    canvas.drawCircle(Offset(centerX, centerY - 8), 8, paint);
    
    // Hair (simple curved lines)
    final hairPath = Path();
    hairPath.moveTo(centerX - 6, centerY - 14);
    hairPath.quadraticBezierTo(centerX, centerY - 18, centerX + 6, centerY - 14);
    canvas.drawPath(hairPath, paint);

    // Body
    canvas.drawLine(
      Offset(centerX, centerY),
      Offset(centerX, centerY + 12),
      paint,
    );

    // Arms
    canvas.drawLine(
      Offset(centerX, centerY + 3),
      Offset(centerX - 10, centerY + 8),
      paint,
    );
    canvas.drawLine(
      Offset(centerX, centerY + 3),
      Offset(centerX + 10, centerY + 8),
      paint,
    );

    // Legs
    canvas.drawLine(
      Offset(centerX, centerY + 12),
      Offset(centerX - 8, centerY + 20),
      paint,
    );
    canvas.drawLine(
      Offset(centerX, centerY + 12),
      Offset(centerX + 8, centerY + 20),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}