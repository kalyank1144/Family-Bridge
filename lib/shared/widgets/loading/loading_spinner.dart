import 'package:flutter/material.dart';

/// A customizable loading spinner widget
class LoadingSpinner extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;
  final String? message;
  final bool showMessage;

  const LoadingSpinner({
    super.key,
    this.size = 40.0,
    this.color,
    this.strokeWidth = 3.0,
    this.message,
    this.showMessage = false,
  });

  const LoadingSpinner.small({
    super.key,
    this.color,
    this.strokeWidth = 2.0,
    this.message,
    this.showMessage = false,
  }) : size = 20.0;

  const LoadingSpinner.large({
    super.key,
    this.color,
    this.strokeWidth = 4.0,
    this.message,
    this.showMessage = true,
  }) : size = 60.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget spinner = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? theme.colorScheme.primary,
        ),
      ),
    );

    if (showMessage || message != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          spinner,
          const SizedBox(height: 16.0),
          Text(
            message ?? 'Loading...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onBackground.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return spinner;
  }
}

/// Full-screen loading overlay
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;
  final Color? backgroundColor;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: backgroundColor ?? Colors.black.withOpacity(0.3),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10.0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: LoadingSpinner.large(message: message),
              ),
            ),
          ),
      ],
    );
  }
}