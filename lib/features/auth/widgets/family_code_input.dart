import 'package:flutter/material.dart';

class FamilyCodeInput extends StatelessWidget {
  final TextEditingController controller;
  const FamilyCodeInput({super.key, required this.controller});
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: 6,
      textCapitalization: TextCapitalization.characters,
      decoration: const InputDecoration(
        labelText: 'Family Code',
        helperText: 'Enter 6-character code',
      ),
    );
  }
}