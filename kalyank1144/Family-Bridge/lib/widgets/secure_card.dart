import 'package:flutter/material.dart';
import '../middleware/security_middleware.dart';

class SecureCard extends StatelessWidget {
  final String resource;
  final String action;
  final Widget child;
  final Widget? unauthorized;

  const SecureCard({
    super.key,
    required this.resource,
    required this.action,
    required this.child,
    this.unauthorized,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SecureWidget(
          resource: resource,
          action: action,
          unauthorizedWidget: unauthorized ?? _defaultUnauthorized(),
          child: child,
        ),
      ),
    );
  }

  Widget _defaultUnauthorized() {
    return Row(
      children: const [
        Icon(Icons.lock, size: 18, color: Colors.grey),
        SizedBox(width: 8),
        Expanded(child: Text('Access restricted')),
      ],
    );
  }
}