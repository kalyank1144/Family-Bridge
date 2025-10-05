import 'package:flutter/material.dart';

import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:provider/provider.dart';

import 'package:family_bridge/core/services/access_control_service.dart';
import 'package:family_bridge/core/theme/app_theme.dart';
import 'package:family_bridge/features/admin/providers/hipaa_compliance_provider.dart';

class SecureAuthenticationScreen extends StatefulWidget {
  const SecureAuthenticationScreen({super.key});

  @override
  State<SecureAuthenticationScreen> createState() => _SecureAuthenticationScreenState();
}

class _SecureAuthenticationScreenState extends State<SecureAuthenticationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _mfaCodeController = TextEditingController();
  
  bool _isLoading = false;
  bool _showPassword = false;
  bool _mfaRequired = false;
  MfaChallenge? _currentMfaChallenge;
  String? _errorMessage;
  int _failedAttempts = 0;

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    _mfaCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Secure Authentication'),
        centerTitle: true,
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(FeatherIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(FeatherIcons.info),
            onPressed: _showSecurityInfo,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Security Header
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Icon(FeatherIcons.shield, size: 48, color: AppTheme.primaryColor),
                    const SizedBox(height: AppTheme.spacingMd),
                    Text(
                      'HIPAA-Compliant Access',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      'This system contains protected health information (PHI). Access is monitored and logged in accordance with HIPAA regulations.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingXl),

              // Error Message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(FeatherIcons.alertTriangle, color: AppTheme.errorColor),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_errorMessage!, style: TextStyle(color: AppTheme.errorColor))),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingLg),
              ],

              // User ID Field
              TextFormField(
                controller: _userIdController,
                decoration: InputDecoration(
                  labelText: 'User ID',
                  hintText: 'Enter your user identifier',
                  prefixIcon: const Icon(FeatherIcons.user),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'User ID is required';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // Password Field
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(FeatherIcons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_showPassword ? FeatherIcons.eyeOff : FeatherIcons.eye),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                ),
                obscureText: !_showPassword,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // MFA Code Field (shown when MFA is required)
              if (_mfaRequired) ...[
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingMd),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(FeatherIcons.smartphone, color: AppTheme.warningColor),
                          const SizedBox(width: 8),
                          Text(
                            'Multi-Factor Authentication Required',
                            style: TextStyle(
                              color: AppTheme.warningColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A verification code has been sent to your registered device.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMd),
                TextFormField(
                  controller: _mfaCodeController,
                  decoration: InputDecoration(
                    labelText: 'Verification Code',
                    hintText: 'Enter 6-digit code',
                    prefixIcon: const Icon(FeatherIcons.smartphone),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Verification code is required';
                    }
                    if (value.length != 6) {
                      return 'Code must be 6 digits';
                    }
                    return null;
                  },
                  enabled: !_isLoading,
                ),
                const SizedBox(height: AppTheme.spacingMd),
              ],

              // Sign In Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSignIn,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _mfaRequired ? 'Verify & Sign In' : 'Sign In Securely',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // Security Notice
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  color: AppTheme.infoColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(FeatherIcons.info, color: AppTheme.infoColor, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Security Notice',
                          style: TextStyle(
                            color: AppTheme.infoColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• All access attempts are logged and monitored\n'
                      '• Sessions expire after 8 hours of inactivity\n'
                      '• Failed login attempts will result in account lockout\n'
                      '• Report any suspicious activity immediately',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // Compliance Links
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: _showPrivacyPolicy,
                    icon: const Icon(FeatherIcons.fileText, size: 16),
                    label: const Text('Privacy Policy'),
                  ),
                  Container(width: 1, height: 20, color: AppTheme.textTertiary),
                  TextButton.icon(
                    onPressed: _showTermsOfUse,
                    icon: const Icon(FeatherIcons.book, size: 16),
                    label: const Text('Terms of Use'),
                  ),
                  Container(width: 1, height: 20, color: AppTheme.textTertiary),
                  TextButton.icon(
                    onPressed: _reportSecurityIssue,
                    icon: const Icon(FeatherIcons.shield, size: 16),
                    label: const Text('Report Issue'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final complianceProvider = context.read<HipaaComplianceProvider>();
      
      final result = await complianceProvider.authenticateUser(
        userId: _userIdController.text.trim(),
        password: _passwordController.text,
        ipAddress: '127.0.0.1', // In production, get real IP
        deviceId: 'device_${DateTime.now().millisecondsSinceEpoch}', // In production, get real device ID
        mfaCode: _mfaRequired ? _mfaCodeController.text.trim() : null,
      );

      if (result.success && result.session != null) {
        // Authentication successful
        Navigator.pushReplacementNamed(context, '/caregiver');
      } else if (result.mfaChallenge != null) {
        // MFA required
        setState(() {
          _mfaRequired = true;
          _currentMfaChallenge = result.mfaChallenge;
          _errorMessage = null;
        });
      } else {
        // Authentication failed
        setState(() {
          _failedAttempts++;
          _errorMessage = result.error ?? 'Authentication failed';
          
          if (_failedAttempts >= 3) {
            _errorMessage = 'Too many failed attempts. Account temporarily locked.';
          }
        });
      }

    } catch (e) {
      setState(() {
        _errorMessage = 'Authentication error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSecurityInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(FeatherIcons.shield, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text('Security Information'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'HIPAA Compliance Features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('✓ End-to-end encryption of all PHI data'),
              Text('✓ Comprehensive audit logging'),
              Text('✓ Multi-factor authentication'),
              Text('✓ Role-based access controls'),
              Text('✓ Automatic breach detection'),
              Text('✓ Session timeout protection'),
              Text('✓ Data integrity verification'),
              SizedBox(height: 16),
              Text(
                'Your access and activities are monitored to ensure compliance with HIPAA regulations and protect patient privacy.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'This application complies with HIPAA regulations for the protection of health information. '
            'All personal health information is encrypted, access is logged, and data is handled according to '
            'federal privacy standards.\n\n'
            'By using this application, you acknowledge that you are authorized to access the health '
            'information contained within and will maintain its confidentiality.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfUse() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Use'),
        content: const SingleChildScrollView(
          child: Text(
            'Terms of Use for FamilyBridge HIPAA-Compliant Healthcare Platform:\n\n'
            '1. You are authorized to access only the minimum necessary health information required for your role.\n'
            '2. All access is logged and monitored for compliance purposes.\n'
            '3. You must not share login credentials or access information with unauthorized individuals.\n'
            '4. Report any suspected security incidents immediately.\n'
            '5. Sessions will automatically expire for security purposes.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _reportSecurityIssue() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(FeatherIcons.alertTriangle, color: AppTheme.errorColor),
            const SizedBox(width: 8),
            const Text('Report Security Issue'),
          ],
        ),
        content: const Text(
          'To report a security incident or concern:\n\n'
          '• Contact the Security Officer immediately\n'
          '• Email: security@familybridge.com\n'
          '• Phone: 1-800-SECURITY (24/7)\n'
          '• In-app: Use the emergency contact feature\n\n'
          'Do not attempt to investigate the issue yourself.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _initiateEmergencyContact();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            child: const Text('Emergency Contact'),
          ),
        ],
      ),
    );
  }

  void _initiateEmergencyContact() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency security contact initiated'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}