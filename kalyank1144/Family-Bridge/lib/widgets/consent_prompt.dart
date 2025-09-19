import 'package:flutter/material.dart';
import '../services/security/privacy_manager.dart';
import '../middleware/security_middleware.dart';

class ConsentPrompt extends StatefulWidget {
  final String dataType;
  final String purpose;
  final Widget child;

  const ConsentPrompt({
    super.key,
    required this.dataType,
    required this.purpose,
    required this.child,
  });

  @override
  State<ConsentPrompt> createState() => _ConsentPromptState();
}

class _ConsentPromptState extends State<ConsentPrompt> {
  bool _loading = true;
  bool _hasConsent = false;
  bool _submitting = false;
  bool _granted = true;

  @override
  void initState() {
    super.initState();
    _checkConsent();
  }

  Future<void> _checkConsent() async {
    final ctx = SecurityContext.of(context);
    if (ctx == null) return;
    final consent = await ConsentManager().hasConsent(
      userId: ctx.currentUser.id,
      dataType: widget.dataType,
      purpose: widget.purpose,
    );
    setState(() {
      _hasConsent = consent;
      _loading = false;
    });
  }

  Future<void> _recordConsent() async {
    final ctx = SecurityContext.of(context);
    if (ctx == null) return;
    setState(() => _submitting = true);
    await ConsentManager().recordConsent(
      userId: ctx.currentUser.id,
      dataType: widget.dataType,
      purpose: widget.purpose,
      granted: _granted,
    );
    setState(() {
      _hasConsent = _granted;
      _submitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
    if (_hasConsent) return widget.child;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange.shade200),
        borderRadius: BorderRadius.circular(12),
        color: Colors.orange.shade50,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.privacy_tip, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(
                child: Text('Consent required to access this information'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<bool>(
                  value: _granted,
                  decoration: const InputDecoration(labelText: 'Consent'),
                  items: const [
                    DropdownMenuItem(value: true, child: Text('Grant consent')),
                    DropdownMenuItem(value: false, child: Text('Decline')),
                  ],
                  onChanged: (v) => setState(() => _granted = v ?? true),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _recordConsent,
                  icon: _submitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check),
                  label: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}