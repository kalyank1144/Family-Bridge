import 'package:flutter/material.dart';

class SimpleGestureDetector extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPressConfirm;
  final bool disableSwipe;

  const SimpleGestureDetector({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPressConfirm,
    this.disableSwipe = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPressConfirm,
      onVerticalDragStart: disableSwipe ? (_) {} : null,
      onHorizontalDragStart: disableSwipe ? (_) {} : null,
      child: child,
    );
  }
}
