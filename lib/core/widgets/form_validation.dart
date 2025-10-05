import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:family_bridge/core/utils/accessibility_helper.dart';

// Enhanced form field with real-time validation
class ValidatedFormField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<ValidationRule> validationRules;
  final Function(String)? onChanged;
  final Function(String)? onFieldSubmitted;
  final bool showValidationIcon;
  final bool realTimeValidation;
  final Duration validationDelay;
  final String? helperText;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  const ValidatedFormField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validationRules = const [],
    this.onChanged,
    this.onFieldSubmitted,
    this.showValidationIcon = true,
    this.realTimeValidation = true,
    this.validationDelay = const Duration(milliseconds: 500),
    this.helperText,
    this.maxLength,
    this.inputFormatters,
  });

  @override
  State<ValidatedFormField> createState() => _ValidatedFormFieldState();
}

class _ValidatedFormFieldState extends State<ValidatedFormField>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  String? _errorMessage;
  bool _isValid = false;
  bool _hasBeenValidated = false;
  Timer? _validationTimer;
  late AnimationController _animationController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticIn),
    );

    if (widget.realTimeValidation) {
      _controller.addListener(_onTextChanged);
    }
  }

  void _onTextChanged() {
    if (!widget.realTimeValidation) return;

    _validationTimer?.cancel();
    _validationTimer = Timer(widget.validationDelay, () {
      _validateField(_controller.text);
    });
  }

  void _validateField(String value) {
    if (!mounted) return;

    String? error;
    bool isValid = true;

    for (final rule in widget.validationRules) {
      final result = rule.validate(value);
      if (result != null) {
        error = result;
        isValid = false;
        break;
      }
    }

    setState(() {
      _errorMessage = error;
      _isValid = isValid && value.isNotEmpty;
      _hasBeenValidated = true;
    });

    if (error != null && _hasBeenValidated) {
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
    }

    widget.onChanged?.call(value);
  }

  String? _getFormValidator(String? value) {
    if (!_hasBeenValidated && widget.realTimeValidation) {
      return null; // Don't show errors until real-time validation has run
    }
    
    return _errorMessage;
  }

  @override
  void dispose() {
    _validationTimer?.cancel();
    _animationController.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _controller,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType,
                maxLength: widget.maxLength,
                inputFormatters: widget.inputFormatters,
                decoration: InputDecoration(
                  labelText: widget.labelText,
                  hintText: widget.hintText,
                  helperText: widget.helperText,
                  prefixIcon: widget.prefixIcon != null 
                      ? Icon(widget.prefixIcon) 
                      : null,
                  suffixIcon: _buildSuffixIcon(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _getFieldBorderColor(),
                      width: _hasBeenValidated ? 2 : 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _getFieldBorderColor(),
                      width: _hasBeenValidated ? 2 : 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _getFocusedBorderColor(),
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.red,
                      width: 2,
                    ),
                  ),
                ),
                validator: _getFormValidator,
                onChanged: widget.realTimeValidation ? null : widget.onChanged,
                onFieldSubmitted: widget.onFieldSubmitted,
              ),
              if (_hasBeenValidated && _isValid)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Looks good!',
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.suffixIcon != null) return widget.suffixIcon;
    if (!widget.showValidationIcon || !_hasBeenValidated) return null;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _isValid
          ? Icon(
              Icons.check_circle,
              color: Colors.green.shade600,
              key: const ValueKey('valid'),
            )
          : _errorMessage != null
              ? Icon(
                  Icons.error,
                  color: Colors.red.shade600,
                  key: const ValueKey('error'),
                )
              : null,
    );
  }

  Color _getFieldBorderColor() {
    if (!_hasBeenValidated) return Colors.grey.shade300;
    if (_isValid) return Colors.green.shade300;
    if (_errorMessage != null) return Colors.red.shade300;
    return Colors.grey.shade300;
  }

  Color _getFocusedBorderColor() {
    if (_errorMessage != null) return Colors.red;
    if (_isValid) return Colors.green;
    return Theme.of(context).primaryColor;
  }
}

// Password strength indicator
class PasswordStrengthField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final Function(String)? onChanged;
  final bool showStrengthIndicator;
  final List<ValidationRule> additionalRules;

  const PasswordStrengthField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.onChanged,
    this.showStrengthIndicator = true,
    this.additionalRules = const [],
  });

  @override
  State<PasswordStrengthField> createState() => _PasswordStrengthFieldState();
}

class _PasswordStrengthFieldState extends State<PasswordStrengthField> {
  PasswordStrength _strength = PasswordStrength.weak;
  List<PasswordRequirement> _requirements = [];

  @override
  void initState() {
    super.initState();
    _requirements = [
      PasswordRequirement('At least 8 characters', (p) => p.length >= 8),
      PasswordRequirement('Contains uppercase letter', (p) => p.contains(RegExp(r'[A-Z]'))),
      PasswordRequirement('Contains lowercase letter', (p) => p.contains(RegExp(r'[a-z]'))),
      PasswordRequirement('Contains number', (p) => p.contains(RegExp(r'[0-9]'))),
      PasswordRequirement('Contains special character', (p) => p.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))),
    ];
  }

  void _onPasswordChanged(String password) {
    _updatePasswordStrength(password);
    widget.onChanged?.call(password);
  }

  void _updatePasswordStrength(String password) {
    int metRequirements = 0;
    
    for (final requirement in _requirements) {
      if (requirement.validator(password)) {
        metRequirements++;
      }
    }

    PasswordStrength newStrength;
    if (metRequirements <= 1) {
      newStrength = PasswordStrength.weak;
    } else if (metRequirements <= 3) {
      newStrength = PasswordStrength.medium;
    } else if (metRequirements <= 4) {
      newStrength = PasswordStrength.strong;
    } else {
      newStrength = PasswordStrength.veryStrong;
    }

    if (newStrength != _strength) {
      setState(() {
        _strength = newStrength;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ValidatedFormField(
          controller: widget.controller,
          labelText: widget.labelText,
          hintText: widget.hintText,
          prefixIcon: Icons.lock,
          obscureText: true,
          onChanged: _onPasswordChanged,
          validationRules: [
            ValidationRule('Password must be at least 8 characters', (value) {
              return value.length >= 8 ? null : 'Password must be at least 8 characters';
            }),
            ...widget.additionalRules,
          ],
        ),
        if (widget.showStrengthIndicator) ...[
          const SizedBox(height: 8),
          _buildStrengthIndicator(),
          const SizedBox(height: 8),
          _buildRequirementsList(),
        ],
      ],
    );
  }

  Widget _buildStrengthIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password strength: ${_strength.label}',
          style: TextStyle(
            fontSize: 12,
            color: _strength.color,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: _strength.value,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation(_strength.color),
        ),
      ],
    );
  }

  Widget _buildRequirementsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _requirements.map((requirement) {
        final isMet = requirement.validator(widget.controller?.text ?? '');
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  isMet ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 16,
                  color: isMet ? Colors.green : Colors.grey,
                  key: ValueKey(isMet),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                requirement.description,
                style: TextStyle(
                  fontSize: 12,
                  color: isMet ? Colors.green : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// Email field with suggestions
class EmailFormField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final Function(String)? onChanged;
  final List<ValidationRule> additionalRules;

  const EmailFormField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.onChanged,
    this.additionalRules = const [],
  });

  @override
  State<EmailFormField> createState() => _EmailFormFieldState();
}

class _EmailFormFieldState extends State<EmailFormField> {
  String? _suggestion;
  
  final List<String> _commonDomains = [
    'gmail.com',
    'yahoo.com',
    'hotmail.com',
    'outlook.com',
    'icloud.com',
    'aol.com',
  ];

  void _onEmailChanged(String email) {
    _updateSuggestion(email);
    widget.onChanged?.call(email);
  }

  void _updateSuggestion(String email) {
    if (email.contains('@') && !email.endsWith('@')) {
      final parts = email.split('@');
      if (parts.length == 2) {
        final domain = parts[1].toLowerCase();
        
        // Find close matches
        for (final commonDomain in _commonDomains) {
          if (commonDomain.startsWith(domain) && domain != commonDomain) {
            final newSuggestion = '${parts[0]}@$commonDomain';
            if (_suggestion != newSuggestion) {
              setState(() {
                _suggestion = newSuggestion;
              });
            }
            return;
          }
        }
      }
    }
    
    if (_suggestion != null) {
      setState(() {
        _suggestion = null;
      });
    }
  }

  void _applySuggestion() {
    if (_suggestion != null && widget.controller != null) {
      widget.controller!.text = _suggestion!;
      widget.controller!.selection = TextSelection.fromPosition(
        TextPosition(offset: _suggestion!.length),
      );
      setState(() {
        _suggestion = null;
      });
      widget.onChanged?.call(_suggestion!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ValidatedFormField(
          controller: widget.controller,
          labelText: widget.labelText,
          hintText: widget.hintText,
          prefixIcon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          onChanged: _onEmailChanged,
          validationRules: [
            ValidationRule('Please enter a valid email', (value) {
              if (value.isEmpty) return 'Email is required';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            }),
            ...widget.additionalRules,
          ],
        ),
        if (_suggestion != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: GestureDetector(
              onTap: _applySuggestion,
              child: Text.rich(
                TextSpan(
                  text: 'Did you mean: ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  children: [
                    TextSpan(
                      text: _suggestion,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Validation rule class
class ValidationRule {
  final String message;
  final String? Function(String) validator;

  ValidationRule(this.message, this.validator);

  String? validate(String value) {
    return validator(value);
  }
}

// Password requirement class
class PasswordRequirement {
  final String description;
  final bool Function(String) validator;

  PasswordRequirement(this.description, this.validator);
}

// Password strength enum
enum PasswordStrength {
  weak(0.25, Colors.red, 'Weak'),
  medium(0.5, Colors.orange, 'Medium'),
  strong(0.75, Colors.blue, 'Strong'),
  veryStrong(1.0, Colors.green, 'Very Strong');

  const PasswordStrength(this.value, this.color, this.label);

  final double value;
  final Color color;
  final String label;
}