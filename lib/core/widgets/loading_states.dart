import 'package:flutter/material.dart';
import '../utils/accessibility_helper.dart';

class LoadingStates {
  // Custom loading indicator with FamilyBridge branding
  static Widget familyBridgeLoader({
    double size = 50,
    Color? color,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: size * 0.08,
              color: color,
            ),
          ),
          Icon(
            Icons.family_restroom,
            size: size * 0.4,
            color: color?.withOpacity(0.7),
          ),
        ],
      ),
    );
  }

  // Pulsing dot loader
  static Widget pulsingDots({
    Color? color,
    double size = 8,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: AlwaysStoppedAnimation(0),
          builder: (context, child) {
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.3, end: 1.0),
              duration: Duration(milliseconds: 600 + (index * 200)),
              curve: Curves.easeInOut,
              onEnd: () {},
              builder: (context, value, child) {
                return Container(
                  width: size,
                  height: size,
                  margin: EdgeInsets.symmetric(horizontal: size * 0.3),
                  decoration: BoxDecoration(
                    color: (color ?? Theme.of(context).primaryColor).withOpacity(value),
                    shape: BoxShape.circle,
                  ),
                );
              },
            );
          },
        );
      }),
    );
  }

  // Button loading state
  static Widget buttonLoader({
    required Widget child,
    required bool isLoading,
    Color? loadingColor,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: loadingColor ?? Colors.white,
              ),
            )
          : child,
    );
  }

  // Page loading overlay
  static Widget pageOverlay({
    required Widget child,
    required bool isLoading,
    String? loadingText,
    Color? overlayColor,
  }) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: (overlayColor ?? Colors.black).withOpacity(0.3),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    familyBridgeLoader(),
                    if (loadingText != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        loadingText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Skeleton loader components
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey.shade300.withOpacity(_animation.value),
            borderRadius: widget.borderRadius ?? BorderRadius.circular(4),
          ),
        );
      },
    );
  }
}

// Pre-built skeleton layouts
class SkeletonLayouts {
  // Profile card skeleton
  static Widget profileCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SkeletonLoader(
              width: 60,
              height: 60,
              borderRadius: BorderRadius.all(Radius.circular(30)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonLoader(width: 120, height: 16),
                  const SizedBox(height: 8),
                  const SkeletonLoader(width: 200, height: 14),
                  const SizedBox(height: 4),
                  SkeletonLoader(
                    width: 80,
                    height: 12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Family member list skeleton
  static Widget familyMembersList() {
    return Column(
      children: List.generate(3, (index) => profileCard()),
    );
  }

  // Form field skeleton
  static Widget formField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonLoader(width: 80, height: 14),
        const SizedBox(height: 8),
        SkeletonLoader(
          width: double.infinity,
          height: 56,
          borderRadius: BorderRadius.circular(8),
        ),
      ],
    );
  }
}

// Animated loading button
class LoadingButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final Color? loadingColor;
  final Duration animationDuration;

  const LoadingButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.loadingColor,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(LoadingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            child: AnimatedSwitcher(
              duration: widget.animationDuration,
              child: widget.isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: widget.loadingColor ?? Colors.white,
                      ),
                    )
                  : widget.child,
            ),
          ),
        );
      },
    );
  }
}