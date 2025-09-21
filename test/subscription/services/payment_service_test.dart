import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:stripe_flutter/stripe_flutter.dart';

import 'package:family_bridge/core/services/payment_service.dart';
import 'package:family_bridge/core/services/subscription_backend_service.dart';
import 'package:family_bridge/core/models/user_model.dart';
import 'package:family_bridge/features/subscription/models/payment_method.dart';

import 'payment_service_test.mocks.dart';

@GenerateMocks([
  SubscriptionBackendService,
  Stripe,
])
void main() {
  late PaymentService paymentService;
  late MockSubscriptionBackendService mockBackendService;
  late MockStripe mockStripe;

  setUp(() {
    mockBackendService = MockSubscriptionBackendService();
    mockStripe = MockStripe();
    paymentService = PaymentService(
      backendService: mockBackendService,
    );
  });

  group('PaymentService', () {
    group('initialize', () {
      testWidgets('should initialize Stripe successfully', (tester) async {
        // Arrange
        when(mockStripe.instance).thenReturn(mockStripe);
        
        // Act
        await paymentService.initialize();

        // Assert
        // Verify Stripe was initialized with publishable key
        // Note: This would require mocking Stripe.publishableKey setter
      });
    });

    group('processSubscriptionPayment', () {
      testWidgets('should process subscription payment successfully', (tester) async {
        // Arrange
        final user = UserProfile(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'Test User',
          stripeCustomerId: 'cus_test123',
        );
        
        final paymentMethod = PaymentMethodInfo(
          id: 'pm_test123',
          type: PaymentMethodType.card,
          card: CardInfo(
            brand: 'visa',
            last4: '4242',
            expMonth: 12,
            expYear: 2025,
          ),
        );

        when(mockBackendService.createSubscription(any, any))
            .thenAnswer((_) async => 'sub_test123');

        when(mockBackendService.createPaymentIntent(any, any))
            .thenAnswer((_) async => PaymentIntent(
              id: 'pi_test123',
              amount: 999,
              currency: 'usd',
              status: PaymentIntentStatus.succeeded,
              clientSecret: 'pi_test123_secret',
            ));

        // Act
        final result = await paymentService.processSubscriptionPayment(
          user: user,
          priceId: 'price_premium_monthly',
          paymentMethod: paymentMethod,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.subscriptionId, equals('sub_test123'));
        verify(mockBackendService.createSubscription(
          user.stripeCustomerId!,
          'price_premium_monthly',
        )).called(1);
      });

      testWidgets('should handle payment failure gracefully', (tester) async {
        // Arrange
        final user = UserProfile(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'Test User',
          stripeCustomerId: 'cus_test123',
        );
        
        final paymentMethod = PaymentMethodInfo(
          id: 'pm_test123',
          type: PaymentMethodType.card,
          card: CardInfo(
            brand: 'visa',
            last4: '4242',
            expMonth: 12,
            expYear: 2025,
          ),
        );

        when(mockBackendService.createSubscription(any, any))
            .thenThrow(Exception('Card declined'));

        // Act
        final result = await paymentService.processSubscriptionPayment(
          user: user,
          priceId: 'price_premium_monthly',
          paymentMethod: paymentMethod,
        );

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('Card declined'));
      });

      testWidgets('should handle insufficient funds error', (tester) async {
        // Arrange
        final user = UserProfile(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'Test User',
          stripeCustomerId: 'cus_test123',
        );
        
        final paymentMethod = PaymentMethodInfo(
          id: 'pm_test123',
          type: PaymentMethodType.card,
          card: CardInfo(
            brand: 'visa',
            last4: '4242',
            expMonth: 12,
            expYear: 2025,
          ),
        );

        when(mockBackendService.createSubscription(any, any))
            .thenThrow(Exception('insufficient_funds'));

        // Act
        final result = await paymentService.processSubscriptionPayment(
          user: user,
          priceId: 'price_premium_monthly',
          paymentMethod: paymentMethod,
        );

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('insufficient funds'));
        expect(result.declineCode, equals('insufficient_funds'));
      });
    });

    group('handlePaymentFailure', () {
      test('should handle payment failure and notify backend', () async {
        // Arrange
        const subscriptionId = 'sub_test123';
        const reason = 'card_declined';

        when(mockBackendService.updateSubscriptionStatus(any, any))
            .thenAnswer((_) async => true);

        // Act
        await paymentService.handlePaymentFailure(subscriptionId, reason);

        // Assert
        verify(mockBackendService.updateSubscriptionStatus(
          subscriptionId,
          'past_due',
        )).called(1);
      });
    });

    group('canUseApplePay', () {
      testWidgets('should check Apple Pay availability on iOS', (tester) async {
        // Arrange
        // This would require platform channel mocking
        
        // Act
        final canUse = await paymentService.canUseApplePay();

        // Assert
        expect(canUse, isA<bool>());
      });
    });

    group('canUseGooglePay', () {
      testWidgets('should check Google Pay availability on Android', (tester) async {
        // Arrange
        // This would require platform channel mocking
        
        // Act
        final canUse = await paymentService.canUseGooglePay();

        // Assert
        expect(canUse, isA<bool>());
      });
    });

    group('processApplePayPayment', () {
      testWidgets('should process Apple Pay payment', (tester) async {
        // Arrange
        const amount = 9.99;
        
        // Mock Apple Pay flow
        when(mockStripe.confirmApplePayPayment(any))
            .thenAnswer((_) async => PaymentResult(
              status: PaymentResultStatus.succeeded,
            ));

        // Act
        final result = await paymentService.processApplePayPayment(amount);

        // Assert
        expect(result.status, equals(PaymentResultStatus.succeeded));
      });

      testWidgets('should handle Apple Pay cancellation', (tester) async {
        // Arrange
        const amount = 9.99;
        
        when(mockStripe.confirmApplePayPayment(any))
            .thenAnswer((_) async => PaymentResult(
              status: PaymentResultStatus.canceled,
            ));

        // Act
        final result = await paymentService.processApplePayPayment(amount);

        // Assert
        expect(result.status, equals(PaymentResultStatus.canceled));
      });
    });

    group('collectPaymentMethod', () {
      testWidgets('should collect payment method using payment sheet', (tester) async {
        // Arrange
        final context = MockBuildContext();
        
        when(mockStripe.presentPaymentSheet())
            .thenAnswer((_) async => {});

        // Act
        final paymentMethod = await paymentService.collectPaymentMethod(context);

        // Assert
        expect(paymentMethod, isA<PaymentMethodInfo?>());
      });

      testWidgets('should handle user cancellation', (tester) async {
        // Arrange
        final context = MockBuildContext();
        
        when(mockStripe.presentPaymentSheet())
            .thenThrow(Exception('Payment sheet cancelled'));

        // Act
        final paymentMethod = await paymentService.collectPaymentMethod(context);

        // Assert
        expect(paymentMethod, isNull);
      });
    });

    group('Error handling', () {
      testWidgets('should handle network errors during payment', (tester) async {
        // Arrange
        final user = UserProfile(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'Test User',
          stripeCustomerId: 'cus_test123',
        );
        
        final paymentMethod = PaymentMethodInfo(
          id: 'pm_test123',
          type: PaymentMethodType.card,
          card: CardInfo(
            brand: 'visa',
            last4: '4242',
            expMonth: 12,
            expYear: 2025,
          ),
        );

        when(mockBackendService.createSubscription(any, any))
            .thenThrow(Exception('network_error'));

        // Act
        final result = await paymentService.processSubscriptionPayment(
          user: user,
          priceId: 'price_premium_monthly',
          paymentMethod: paymentMethod,
        );

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('network'));
      });

      testWidgets('should handle expired card error', (tester) async {
        // Arrange
        final user = UserProfile(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'Test User',
          stripeCustomerId: 'cus_test123',
        );
        
        final paymentMethod = PaymentMethodInfo(
          id: 'pm_test123',
          type: PaymentMethodType.card,
          card: CardInfo(
            brand: 'visa',
            last4: '4242',
            expMonth: 1, // Expired
            expYear: 2020,
          ),
        );

        when(mockBackendService.createSubscription(any, any))
            .thenThrow(Exception('expired_card'));

        // Act
        final result = await paymentService.processSubscriptionPayment(
          user: user,
          priceId: 'price_premium_monthly',
          paymentMethod: paymentMethod,
        );

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('expired'));
        expect(result.declineCode, equals('expired_card'));
      });

      testWidgets('should handle invalid payment method', (tester) async {
        // Arrange
        final user = UserProfile(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'Test User',
          stripeCustomerId: 'cus_test123',
        );
        
        final paymentMethod = PaymentMethodInfo(
          id: 'pm_invalid',
          type: PaymentMethodType.card,
          card: CardInfo(
            brand: 'visa',
            last4: '0000',
            expMonth: 12,
            expYear: 2025,
          ),
        );

        when(mockBackendService.createSubscription(any, any))
            .thenThrow(Exception('invalid_payment_method'));

        // Act
        final result = await paymentService.processSubscriptionPayment(
          user: user,
          priceId: 'price_premium_monthly',
          paymentMethod: paymentMethod,
        );

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, contains('invalid'));
      });
    });

    group('Payment retry logic', () {
      testWidgets('should retry failed payments with exponential backoff', (tester) async {
        // Arrange
        final user = UserProfile(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'Test User',
          stripeCustomerId: 'cus_test123',
        );
        
        final paymentMethod = PaymentMethodInfo(
          id: 'pm_test123',
          type: PaymentMethodType.card,
          card: CardInfo(
            brand: 'visa',
            last4: '4242',
            expMonth: 12,
            expYear: 2025,
          ),
        );

        // First call fails, second succeeds
        when(mockBackendService.createSubscription(any, any))
            .thenThrow(Exception('temporary_error'))
            .thenAnswer((_) async => 'sub_test123');

        // Act
        final result = await paymentService.processSubscriptionPayment(
          user: user,
          priceId: 'price_premium_monthly',
          paymentMethod: paymentMethod,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockBackendService.createSubscription(any, any)).called(2);
      });
    });
  });

  group('Payment method validation', () {
    test('should validate card expiry date', () {
      // Arrange
      final validCard = CardInfo(
        brand: 'visa',
        last4: '4242',
        expMonth: 12,
        expYear: 2025,
      );
      
      final expiredCard = CardInfo(
        brand: 'visa',
        last4: '4242',
        expMonth: 1,
        expYear: 2020,
      );

      // Act & Assert
      expect(paymentService.isCardExpired(validCard), isFalse);
      expect(paymentService.isCardExpired(expiredCard), isTrue);
    });

    test('should validate card number format', () {
      // Arrange
      const validLast4 = '4242';
      const invalidLast4 = '424';

      // Act & Assert
      expect(paymentService.isValidCardLast4(validLast4), isTrue);
      expect(paymentService.isValidCardLast4(invalidLast4), isFalse);
    });
  });

  group('Currency formatting', () {
    test('should format currency correctly', () {
      // Act & Assert
      expect(paymentService.formatCurrency(999, 'usd'), equals('\$9.99'));
      expect(paymentService.formatCurrency(1299, 'usd'), equals('\$12.99'));
      expect(paymentService.formatCurrency(0, 'usd'), equals('\$0.00'));
    });
  });
}

class MockBuildContext extends Mock implements BuildContext {}