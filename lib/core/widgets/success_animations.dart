import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:family_bridge/core/utils/accessibility_helper.dart';

// Animated success checkmark
class AnimatedCheckmark extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;
  final VoidCallback? onComplete;

  const AnimatedCheckmark({
    super.key,
    this.size = 100,
    this.color = Colors.green,
    this.duration = const Duration(milliseconds: 800),
    this.onComplete,
  });

  @override
  State<AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<AnimatedCheckmark>
    with TickerProviderStateMixin {
  late AnimationController _circleController;
  late AnimationController _checkController;
  late Animation<double> _circleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    
    _circleController = AnimationController(
      duration: Duration(milliseconds: (widget.duration.inMilliseconds * 0.6).round()),
      vsync: this,
    );
    
    _checkController = AnimationController(
      duration: Duration(milliseconds: (widget.duration.inMilliseconds * 0.4).round()),
      vsync: this,
    );

    _circleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _circleController, curve: Curves.elasticOut),
    );

    _checkAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.easeInOut),
    );

    _startAnimation();
  }

  void _startAnimation() async {
    await _circleController.forward();
    await _checkController.forward();
    widget.onComplete?.call();
  }

  @override
  void dispose() {
    _circleController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_circleAnimation, _checkAnimation]),
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: CheckmarkPainter(
            circleProgress: _circleAnimation.value,
            checkProgress: _checkAnimation.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class CheckmarkPainter extends CustomPainter {
  final double circleProgress;
  final double checkProgress;
  final Color color;

  CheckmarkPainter({
    required this.circleProgress,
    required this.checkProgress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw circle
    final circlePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      -math.pi / 2,
      2 * math.pi * circleProgress,
      false,
      circlePaint,
    );

    // Draw checkmark
    if (checkProgress > 0) {
      final checkPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;

      final path = Path();
      final checkStart = Offset(size.width * 0.25, size.height * 0.5);
      final checkMiddle = Offset(size.width * 0.4, size.height * 0.65);
      final checkEnd = Offset(size.width * 0.75, size.height * 0.35);

      if (checkProgress <= 0.5) {
        // First part of checkmark
        final progress = checkProgress * 2;
        final currentPoint = Offset.lerp(checkStart, checkMiddle, progress)!;
        path.moveTo(checkStart.dx, checkStart.dy);
        path.lineTo(currentPoint.dx, currentPoint.dy);
      } else {
        // Second part of checkmark
        final progress = (checkProgress - 0.5) * 2;
        final currentPoint = Offset.lerp(checkMiddle, checkEnd, progress)!;
        path.moveTo(checkStart.dx, checkStart.dy);
        path.lineTo(checkMiddle.dx, checkMiddle.dy);
        path.lineTo(currentPoint.dx, currentPoint.dy);
      }

      canvas.drawPath(path, checkPaint);
    }
  }

  @override
  bool shouldRepaint(CheckmarkPainter oldDelegate) {
    return oldDelegate.circleProgress != circleProgress ||
           oldDelegate.checkProgress != checkProgress;
  }
}

// Success celebration with confetti
class SuccessCelebration extends StatefulWidget {
  final Widget child;
  final bool showCelebration;
  final Duration duration;
  final VoidCallback? onComplete;

  const SuccessCelebration({
    super.key,
    required this.child,
    this.showCelebration = false,
    this.duration = const Duration(milliseconds: 2000),
    this.onComplete,
  });

  @override
  State<SuccessCelebration> createState() => _SuccessCelebrationState();
}

class _SuccessCelebrationState extends State<SuccessCelebration>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  List<ConfettiParticle> particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _generateParticles();
  }

  void _generateParticles() {
    final random = math.Random();
    particles = List.generate(50, (index) {
      return ConfettiParticle(
        x: random.nextDouble(),
        y: random.nextDouble() * 0.3,
        color: [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple][
            random.nextInt(5)],
        size: 3 + random.nextDouble() * 4,
        velocityX: (random.nextDouble() - 0.5) * 2,
        velocityY: random.nextDouble() * 2 + 1,
      );
    });
  }

  @override
  void didUpdateWidget(SuccessCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showCelebration && !oldWidget.showCelebration) {
      _controller.forward().then((_) {
        widget.onComplete?.call();
      });
    } else if (!widget.showCelebration && oldWidget.showCelebration) {
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.showCelebration)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: ConfettiPainter(
                      particles: particles,
                      progress: _controller.value,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class ConfettiParticle {
  final double x;
  final double y;
  final Color color;
  final double size;
  final double velocityX;
  final double velocityY;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.velocityX,
    required this.velocityY,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()..color = particle.color;
      
      final currentX = particle.x * size.width + particle.velocityX * progress * 100;
      final currentY = particle.y * size.height + particle.velocityY * progress * size.height;
      
      // Only draw if particle is within bounds
      if (currentX >= 0 && currentX <= size.width && currentY >= 0 && currentY <= size.height) {
        canvas.drawCircle(
          Offset(currentX, currentY),
          particle.size * (1 - progress * 0.5), // Fade out
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// Success toast notification
class SuccessToast {
  static void show(
    BuildContext context, {
    required String message,
    IconData icon = Icons.check_circle,
    Duration duration = const Duration(seconds: 3),
    Color? backgroundColor,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        icon: icon,
        backgroundColor: backgroundColor ?? Colors.green.shade600,
        onDismiss: () => overlayEntry.remove(),
        duration: duration,
      ),
    );

    overlay.insert(overlayEntry);
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onDismiss;
  final Duration duration;

  const _ToastWidget({
    required this.message,
    required this.icon,
    required this.backgroundColor,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);

    _controller.forward();

    // Auto dismiss
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 20,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _dismiss,
                    child: const Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Progress celebration animation
class ProgressCelebration extends StatefulWidget {
  final double progress;
  final bool showCelebration;
  final String? label;
  final Color? color;

  const ProgressCelebration({
    super.key,
    required this.progress,
    this.showCelebration = false,
    this.label,
    this.color,
  });

  @override
  State<ProgressCelebration> createState() => _ProgressCelebrationState();
}

class _ProgressCelebrationState extends State<ProgressCelebration>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _celebrationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );

    _progressController.forward();
  }

  @override
  void didUpdateWidget(ProgressCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.progress != oldWidget.progress) {
      _progressAnimation = Tween<double>(
        begin: _progressAnimation.value,
        end: widget.progress,
      ).animate(CurvedAnimation(parent: _progressController, curve: Curves.easeOut));
      _progressController.forward(from: 0);
    }

    if (widget.showCelebration && !oldWidget.showCelebration) {
      _celebrationController.repeat(reverse: true);
    } else if (!widget.showCelebration && oldWidget.showCelebration) {
      _celebrationController.stop();
      _celebrationController.reset();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_progressAnimation, _celebrationController]),
      builder: (context, child) {
        return Column(
          children: [
            if (widget.label != null) ...[
              Text(
                widget.label!,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
            ],
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progressAnimation.value,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(
                    widget.color ?? Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ),
            if (widget.showCelebration)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Transform.scale(
                  scale: 1 + _celebrationController.value * 0.1,
                  child: Icon(
                    Icons.celebration,
                    color: Colors.amber,
                    size: 24,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}