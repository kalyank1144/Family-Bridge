import 'package:flutter/material.dart';
import '../services/error_service.dart';

/// Standard error display widget with consistent styling
class ErrorWidget extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;
  final bool showDetails;

  const ErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getErrorIcon(),
            size: 64,
            color: _getErrorColor(context),
          ),
          const SizedBox(height: 16),
          Text(
            error.userMessage,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: _getErrorColor(context),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            error.message,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          if (showDetails && error.originalError != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                error.originalError.toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
          if (onRetry != null && error.isRecoverable) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getErrorIcon() {
    switch (error.type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.timeout:
        return Icons.hourglass_empty;
      case ErrorType.authentication:
        return Icons.lock;
      case ErrorType.permission:
        return Icons.block;
      case ErrorType.validation:
        return Icons.error_outline;
      case ErrorType.notFound:
        return Icons.search_off;
      case ErrorType.server:
        return Icons.cloud_off;
      case ErrorType.storage:
        return Icons.storage;
      case ErrorType.unknown:
        return Icons.help_outline;
    }
  }

  Color _getErrorColor(BuildContext context) {
    switch (error.type) {
      case ErrorType.network:
      case ErrorType.timeout:
        return Colors.orange;
      case ErrorType.authentication:
      case ErrorType.permission:
        return Colors.red;
      case ErrorType.validation:
        return Colors.amber;
      case ErrorType.server:
        return Colors.red[700]!;
      default:
        return Theme.of(context).colorScheme.error;
    }
  }
}

/// Inline error message widget for forms and smaller spaces
class InlineErrorWidget extends StatelessWidget {
  final String message;
  final IconData? icon;

  const InlineErrorWidget({
    super.key,
    required this.message,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withOpacity(0.1),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon ?? Icons.error_outline,
            size: 16,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Network error specific widget with retry functionality
class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback onRetry;
  final String? message;

  const NetworkErrorWidget({
    super.key,
    required this.onRetry,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorWidget(
      error: AppError(
        type: ErrorType.network,
        message: message ?? 'Please check your internet connection and try again.',
        userMessage: 'Connection Error',
      ),
      onRetry: onRetry,
    );
  }
}

/// Loading state with error fallback
class LoadingOrErrorWidget extends StatelessWidget {
  final bool isLoading;
  final AppError? error;
  final VoidCallback? onRetry;
  final Widget? loadingWidget;

  const LoadingOrErrorWidget({
    super.key,
    required this.isLoading,
    this.error,
    this.onRetry,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return loadingWidget ?? const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return ErrorWidget(
        error: error!,
        onRetry: onRetry,
      );
    }

    return const SizedBox.shrink();
  }
}

/// Error boundary widget for catching and displaying errors
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(AppError error)? errorBuilder;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  AppError? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_error!);
      }
      
      return ErrorWidget(
        error: _error!,
        onRetry: () => setState(() => _error = null),
      );
    }

    return widget.child;
  }

  void _handleError(Object error, StackTrace stackTrace) {
    setState(() {
      _error = ErrorService.instance.handleApiError(error);
    });

    ErrorService.instance.logError(
      'Error caught by ErrorBoundary',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

/// Snackbar helper for showing errors
class ErrorSnackBar {
  static void show(BuildContext context, AppError error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _getIconForErrorType(error.type),
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    error.userMessage,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (error.message != error.userMessage) ...[
                    const SizedBox(height: 4),
                    Text(
                      error.message,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        backgroundColor: _getColorForErrorType(error.type),
        duration: Duration(seconds: error.type == ErrorType.network ? 5 : 4),
        action: error.isRecoverable
            ? SnackBarAction(
                label: 'RETRY',
                textColor: Colors.white,
                onPressed: () {
                  // Retry callback would be handled by the calling widget
                },
              )
            : null,
      ),
    );
  }

  static IconData _getIconForErrorType(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.timeout:
        return Icons.hourglass_empty;
      case ErrorType.authentication:
        return Icons.lock;
      case ErrorType.permission:
        return Icons.block;
      case ErrorType.validation:
        return Icons.error_outline;
      case ErrorType.notFound:
        return Icons.search_off;
      case ErrorType.server:
        return Icons.cloud_off;
      case ErrorType.storage:
        return Icons.storage;
      case ErrorType.unknown:
        return Icons.help_outline;
    }
  }

  static Color _getColorForErrorType(ErrorType type) {
    switch (type) {
      case ErrorType.network:
      case ErrorType.timeout:
        return Colors.orange;
      case ErrorType.validation:
        return Colors.amber;
      default:
        return Colors.red;
    }
  }
}