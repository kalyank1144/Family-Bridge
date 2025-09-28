import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:family_bridge/features/trial_management/models/subscription_model.dart';
import 'package:family_bridge/features/trial_management/providers/subscription_provider.dart';
import 'package:family_bridge/features/trial_management/services/payment_service.dart';
import 'subscription_success_screen.dart';

class PaymentFlowScreen extends ConsumerStatefulWidget {
  final SubscriptionModel subscription;
  final SubscriptionPlan selectedPlan;

  const PaymentFlowScreen({
    Key? key,
    required this.subscription,
    required this.selectedPlan,
  }) : super(key: key);

  @override
  ConsumerState<PaymentFlowScreen> createState() => _PaymentFlowScreenState();
}

class _PaymentFlowScreenState extends ConsumerState<PaymentFlowScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  final _zipController = TextEditingController();

  bool _isProcessing = false;
  bool _savePaymentMethod = true;
  bool _useVoiceGuidance = false;
  PaymentMethod? _selectedPaymentMethod;

  @override
  void initState() {
    super.initState();
    _useVoiceGuidance = widget.subscription.userType == UserType.elder;
    if (_useVoiceGuidance) {
      _startVoiceGuidance();
    }
  }

  void _startVoiceGuidance() {
    // Voice guidance implementation would go here
    // Using TTS to guide elders through payment
  }

  @override
  Widget build(BuildContext context) {
    final isElder = widget.subscription.userType == UserType.elder;
    final isYouth = widget.subscription.userType == UserType.youth;
    final isCaregiver = widget.subscription.userType == UserType.caregiver;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          isElder ? 'Payment Information' : 'Secure Checkout',
          style: TextStyle(fontSize: isElder ? 24 : 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.onBackground,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isElder ? 24 : 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order summary
                _buildOrderSummary(isElder),
                SizedBox(height: isElder ? 32 : 24),

                // Payment method selection
                if (isYouth) _buildModernPaymentMethods(),
                if (isCaregiver) _buildProfessionalPaymentMethods(),
                if (isElder) _buildElderFriendlyPayment(),

                SizedBox(height: isElder ? 32 : 24),

                // Card input form
                if (_selectedPaymentMethod == null ||
                    _selectedPaymentMethod == PaymentMethod.card)
                  _buildCardInputForm(isElder),

                SizedBox(height: isElder ? 32 : 24),

                // Security badges
                _buildSecurityBadges(isElder),

                SizedBox(height: isElder ? 32 : 24),

                // Pay button
                _buildPayButton(),

                if (isElder) ...[
                  SizedBox(height: isElder ? 24 : 16),
                  _buildAssistanceOption(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummary(bool isElder) {
    final plan = widget.selectedPlan;
    final price = plan == SubscriptionPlan.monthly ? 9.99 : 99.99;
    final period = plan == SubscriptionPlan.monthly ? 'month' : 'year';

    return Container(
      padding: EdgeInsets.all(isElder ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isElder ? 20 : 12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: isElder ? 20 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isElder ? 12 : 8,
                  vertical: isElder ? 6 : 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  plan == SubscriptionPlan.annual ? 'SAVE 17%' : 'MONTHLY',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: isElder ? 14 : 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isElder ? 16 : 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FamilyBridge Premium',
                style: TextStyle(
                  fontSize: isElder ? 18 : 14,
                ),
              ),
              Text(
                '\$$price/$period',
                style: TextStyle(
                  fontSize: isElder ? 20 : 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          if (plan == SubscriptionPlan.annual) ...[
            SizedBox(height: isElder ? 8 : 6),
            Container(
              padding: EdgeInsets.all(isElder ? 12 : 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.celebration_rounded,
                    color: Colors.green.shade700,
                    size: isElder ? 20 : 16,
                  ),
                  SizedBox(width: isElder ? 8 : 6),
                  Text(
                    'You\'re saving \$20 with annual billing!',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontSize: isElder ? 16 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Payment',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildQuickPayButton(
                'Apple Pay',
                Icons.apple,
                PaymentMethod.applePay,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickPayButton(
                'Google Pay',
                Icons.g_mobiledata,
                PaymentMethod.googlePay,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            '— or pay with card —',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfessionalPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildPaymentMethodTile(
          'Credit/Debit Card',
          Icons.credit_card,
          PaymentMethod.card,
        ),
        _buildPaymentMethodTile(
          'PayPal',
          Icons.account_balance_wallet,
          PaymentMethod.paypal,
        ),
        _buildPaymentMethodTile(
          'Bank Transfer',
          Icons.account_balance,
          PaymentMethod.bank,
        ),
      ],
    );
  }

  Widget _buildElderFriendlyPayment() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.credit_card,
              size: 32,
              color: Colors.blue,
            ),
            const SizedBox(width: 16),
            const Text(
              'Payment Card',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_useVoiceGuidance)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.shade200,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.volume_up_rounded,
                  color: Colors.blue,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Voice guidance is on. Listen for instructions.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.blue,
                    ),
                  ),
                ),
                Switch(
                  value: _useVoiceGuidance,
                  onChanged: (value) {
                    setState(() {
                      _useVoiceGuidance = value;
                    });
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCardInputForm(bool isElder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card Number
        _buildInputField(
          controller: _cardNumberController,
          label: 'Card Number',
          hint: '1234 5678 9012 3456',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _CardNumberFormatter(),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter card number';
            }
            if (value.replaceAll(' ', '').length < 16) {
              return 'Invalid card number';
            }
            return null;
          },
          isElder: isElder,
          icon: Icons.credit_card,
        ),
        SizedBox(height: isElder ? 20 : 16),

        // Expiry and CVV
        Row(
          children: [
            Expanded(
              child: _buildInputField(
                controller: _expiryController,
                label: 'Expiry Date',
                hint: 'MM/YY',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _ExpiryDateFormatter(),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
                isElder: isElder,
                icon: Icons.calendar_today,
              ),
            ),
            SizedBox(width: isElder ? 20 : 16),
            Expanded(
              child: _buildInputField(
                controller: _cvvController,
                label: 'CVV',
                hint: '123',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
                isElder: isElder,
                icon: Icons.lock,
                helperText: isElder ? 'Back of card' : null,
              ),
            ),
          ],
        ),
        SizedBox(height: isElder ? 20 : 16),

        // Name on Card
        _buildInputField(
          controller: _nameController,
          label: 'Name on Card',
          hint: 'John Smith',
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter cardholder name';
            }
            return null;
          },
          isElder: isElder,
          icon: Icons.person,
        ),
        SizedBox(height: isElder ? 20 : 16),

        // Billing Zip
        _buildInputField(
          controller: _zipController,
          label: 'Billing ZIP Code',
          hint: '12345',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(5),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter ZIP code';
            }
            return null;
          },
          isElder: isElder,
          icon: Icons.location_on,
        ),

        if (!isElder) ...[
          const SizedBox(height: 16),
          CheckboxListTile(
            value: _savePaymentMethod,
            onChanged: (value) {
              setState(() {
                _savePaymentMethod = value ?? true;
              });
            },
            title: const Text('Save payment method for faster checkout'),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool isElder = false,
    IconData? icon,
    String? helperText,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isElder)
          Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        SizedBox(height: isElder ? 8 : 0),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          textCapitalization: textCapitalization,
          style: TextStyle(
            fontSize: isElder ? 20 : 16,
          ),
          decoration: InputDecoration(
            labelText: !isElder ? label : null,
            hintText: hint,
            helperText: helperText,
            helperStyle: TextStyle(
              fontSize: isElder ? 16 : 12,
            ),
            prefixIcon: icon != null
                ? Icon(
                    icon,
                    size: isElder ? 28 : 24,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(isElder ? 16 : 12),
            ),
            contentPadding: EdgeInsets.all(isElder ? 20 : 16),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickPayButton(String label, IconData icon, PaymentMethod method) {
    final isSelected = _selectedPaymentMethod == method;
    
    return Material(
      color: isSelected ? Colors.blue.shade50 : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _handleQuickPay(method),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile(String title, IconData icon, PaymentMethod method) {
    final isSelected = _selectedPaymentMethod == method;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.blue : null),
        title: Text(title),
        trailing: isSelected
            ? const Icon(Icons.check_circle, color: Colors.blue)
            : null,
        onTap: () {
          setState(() {
            _selectedPaymentMethod = method;
          });
        },
      ),
    );
  }

  Widget _buildSecurityBadges(bool isElder) {
    return Container(
      padding: EdgeInsets.all(isElder ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(isElder ? 12 : 8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_rounded,
            color: Colors.green.shade700,
            size: isElder ? 24 : 20,
          ),
          SizedBox(width: isElder ? 12 : 8),
          Text(
            'Your payment is secure and encrypted',
            style: TextStyle(
              color: Colors.green.shade700,
              fontSize: isElder ? 16 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    final isElder = widget.subscription.userType == UserType.elder;
    final price = widget.selectedPlan == SubscriptionPlan.monthly ? 9.99 : 99.99;
    
    return SizedBox(
      width: double.infinity,
      height: isElder ? 70 : 56,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isElder ? 16 : 12),
          ),
        ),
        child: _isProcessing
            ? const CircularProgressIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_rounded,
                    size: isElder ? 28 : 24,
                  ),
                  SizedBox(width: isElder ? 12 : 8),
                  Text(
                    'Pay \$$price Now',
                    style: TextStyle(
                      fontSize: isElder ? 22 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAssistanceOption() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.people,
            color: Colors.orange,
            size: 48,
          ),
          const SizedBox(height: 12),
          const Text(
            'Need Help?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ask a family member to help with payment',
            style: TextStyle(
              fontSize: 18,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _inviteFamilyMember,
            icon: const Icon(Icons.share),
            label: const Text(
              'Share with Family',
              style: TextStyle(fontSize: 18),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleQuickPay(PaymentMethod method) {
    setState(() {
      _selectedPaymentMethod = method;
    });
    _processPayment();
  }

  void _processPayment() async {
    if (_selectedPaymentMethod == null || 
        _selectedPaymentMethod == PaymentMethod.card) {
      if (!_formKey.currentState!.validate()) {
        return;
      }
    }

    setState(() {
      _isProcessing = true;
    });

    // Simulate payment processing
    await Future.delayed(const Duration(seconds: 2));

    // Update subscription status
    ref.read(subscriptionProvider.notifier).upgradeSubscription(
      widget.selectedPlan,
    );

    // Navigate to success screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SubscriptionSuccessScreen(
          subscription: widget.subscription,
          plan: widget.selectedPlan,
        ),
      ),
    );
  }

  void _inviteFamilyMember() {
    // Share payment link with family member
    // Implementation would include sharing functionality
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    _zipController.dispose();
    super.dispose();
  }
}

enum PaymentMethod {
  card,
  applePay,
  googlePay,
  paypal,
  bank,
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i != text.length - 1) {
        buffer.write(' ');
      }
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.toString().length),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length && i < 4; i++) {
      buffer.write(text[i]);
      if (i == 1 && text.length > 2) {
        buffer.write('/');
      }
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.toString().length),
    );
  }
}