import 'package:flutter/material.dart';

class ErrorView extends StatelessWidget {
  final String message;
  const ErrorView(this.message, {super.key});
  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message));
  }
}
