import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:family_bridge/features/subscription/providers/subscription_provider.dart';
import 'package:family_bridge/core/services/payment_service.dart';
import 'package:family_bridge/core/services/subscription_backend_service.dart';
import 'package:family_bridge/core/services/subscription_lifecycle_service.dart';
import 'package:family_bridge/core/services/subscription_error_handler.dart';
import 'package:family_bridge/core/services/offline_payment_service.dart';
import 'package:family_bridge/core/services/notification_service.dart';
import 'package:family_bridge/core/services/auth_service.dart';
import 'package:family_bridge/core/models/user_model.dart';
import 'package:family_bridge/features/subscription/models/subscription_status.dart';
import 'package:family_bridge/features/subscription/models/payment_method.dart';

import 'payment_flow_integration_test.mocks.dart';

@GenerateMocks([
  PaymentService,
  SubscriptionBackendService,
  SubscriptionLifecycleService,
  SubscriptionErrorHandler,
  OfflinePaymentService,
  NotificationService,
  AuthService,
])
void main() {
  late MockPaymentService mockPaymentService;
  late MockSubscriptionBackendService mockBackendService;
  late MockSubscriptionLifecycleService mockLifecycleService;
  late MockSubscriptionErrorHandler mockErrorHandler;
  late MockOfflinePaymentService mockOfflinePaymentService;
  late MockNotificationService mockNotificationService;
  late MockAuthService mockAuthService;

  setUp(() {
    mockPaymentService = MockPaymentService();
    mockBackendService = MockSubscriptionBackendService();
    mockLifecycleService = MockSubscriptionLifecycleService();
    mockErrorHandler = MockSubscriptionErrorHandler();
    mockOfflinePaymentService = MockOfflinePaymentService();
    mockNotificationService = MockNotificationService();
    mockAuthService = MockAuthService();

    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestApp(SubscriptionProvider subscriptionProvider) {
    return MaterialApp(
      home: ChangeNotifierProvider.value(
        value: subscriptionProvider,
        child: const TestSubscriptionScreen(),
      ),
    );
  }

  group('Payment Flow Integration Tests', () {
    testWidgets('Complete trial to premium upgrade flow', (tester) async {
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

      final trialSubscription = SubscriptionInfo(
        id: 'sub_trial123',
        status: SubscriptionStatus.trial,
        currentPeriodEnd: DateTime.now().add(const Duration(days: 2)),
        customerId: 'cus_test123',
        priceId: 'price_premium_monthly',
      );

      final activeSubscription = trialSubscription.copyWith(
        status: SubscriptionStatus.active,
        currentPeriodEnd: DateTime.now().add(const Duration(days: 30)),
      );

      final subscriptionProvider = SubscriptionProvider(
        paymentService: mockPaymentService,
        backendService: mockBackendService,
        lifecycleService: mockLifecycleService,
        errorHandler: mockErrorHandler,
        offlinePaymentService: mockOfflinePaymentService,
        notificationService: mockNotificationService,
        authService: mockAuthService,
      );

      // Setup mocks
      when(mockAuthService.currentUser).thenReturn(user);
      when(mockPaymentService.initialize()).thenAnswer((_) async {});
      when(mockBackendService.getSubscriptionStatus(any))
          .thenAnswer((_) async => trialSubscription)
          .thenAnswer((_) async => activeSubscription);
      when(mockBackendService.getStoredPaymentMethods(any))
          .thenAnswer((_) async => [paymentMethod]);
      
      when(mockPaymentService.processSubscriptionPayment(
        user: anyNamed('user'),
        priceId: anyNamed('priceId'),
        paymentMethod: anyNamed('paymentMethod'),
      )).thenAnswer((_) async => SubscriptionResult(
        isSuccess: true,
        subscriptionId: 'sub_test123',
      ));
      
      when(mockLifecycleService.onSubscriptionActivated(any))
          .thenAnswer((_) async {});

      // Act - Initialize provider
      await subscriptionProvider.initialize();
      
      await tester.pumpWidget(createTestApp(subscriptionProvider));
      await tester.pumpAndSettle();

      // Assert initial state - trial active
      expect(subscriptionProvider.isTrialActive, isTrue);
      expect(subscriptionProvider.isTrialEnding, isTrue);
      expect(subscriptionProvider.trialDaysRemaining, equals(2));

      // Act - Upgrade to premium
      final upgradeResult = await subscriptionProvider.upgradeTrialToPremium(paymentMethod);
      await tester.pumpAndSettle();

      // Assert upgrade successful
      expect(upgradeResult.isSuccess, isTrue);
      expect(subscriptionProvider.isPremiumActive, isTrue);
      expect(subscriptionProvider.hasUnlimitedMembers, isTrue);
      
      // Verify service calls
      verify(mockPaymentService.processSubscriptionPayment(
        user: user,
        priceId: 'price_premium_monthly',
        paymentMethod: paymentMethod,
      )).called(1);
      verify(mockLifecycleService.onSubscriptionActivated(user)).called(1);
    });

    testWidgets('Payment failure and retry flow', (tester) async {
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

      final subscriptionProvider = SubscriptionProvider(
        paymentService: mockPaymentService,
        backendService: mockBackendService,
        lifecycleService: mockLifecycleService,
        errorHandler: mockErrorHandler,
        offlinePaymentService: mockOfflinePaymentService,
        notificationService: mockNotificationService,
        authService: mockAuthService,
      );

      // Setup mocks for payment failure scenario
      when(mockAuthService.currentUser).thenReturn(user);
      when(mockPaymentService.initialize()).thenAnswer((_) async {});
      when(mockBackendService.getSubscriptionStatus(any))
          .thenAnswer((_) async => null);
      when(mockBackendService.getStoredPaymentMethods(any))
          .thenAnswer((_) async => []);

      // First payment attempt fails
      when(mockPaymentService.processSubscriptionPayment(
        user: anyNamed('user'),
        priceId: anyNamed('priceId'),
        paymentMethod: anyNamed('paymentMethod'),
      )).thenAnswer((_) async => SubscriptionResult(
        isSuccess: false,
        error: 'Your card was declined',
        declineCode: 'card_declined',
      ));

      when(mockErrorHandler.retryFailedPayment(any))
          .thenAnswer((_) async => true);

      // Act - Initialize and attempt upgrade
      await subscriptionProvider.initialize();
      await tester.pumpWidget(createTestApp(subscriptionProvider));

      final upgradeResult = await subscriptionProvider.upgradeTrialToPremium(paymentMethod);
      await tester.pumpAndSettle();

      // Assert payment failed
      expect(upgradeResult.isSuccess, isFalse);
      expect(upgradeResult.message, contains('Your card was declined'));
      expect(subscriptionProvider.error, contains('Your card was declined'));

      // Act - Retry payment
      final retryResult = await subscriptionProvider.retryFailedPayment();
      await tester.pumpAndSettle();

      // Assert retry successful
      expect(retryResult, isTrue);
      verify(mockErrorHandler.retryFailedPayment(any)).called(1);
    });

    testWidgets('Offline payment queueing and processing flow', (tester) async {
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

      final subscriptionProvider = SubscriptionProvider(
        paymentService: mockPaymentService,
        backendService: mockBackendService,
        lifecycleService: mockLifecycleService,
        errorHandler: mockErrorHandler,
        offlinePaymentService: mockOfflinePaymentService,
        notificationService: mockNotificationService,
        authService: mockAuthService,
      );

      // Setup mocks for offline scenario
      when(mockAuthService.currentUser).thenReturn(user);
      when(mockPaymentService.initialize()).thenAnswer((_) async {});
      when(mockBackendService.getSubscriptionStatus(any))
          .thenAnswer((_) async => null);
      when(mockBackendService.getStoredPaymentMethods(any))
          .thenAnswer((_) async => []);

      // Payment fails due to network issue (simulating offline)
      when(mockPaymentService.processSubscriptionPayment(
        user: anyNamed('user'),
        priceId: anyNamed('priceId'),
        paymentMethod: anyNamed('paymentMethod'),
      )).thenThrow(Exception('Network error'));

      when(mockOfflinePaymentService.queuePaymentForRetry(any))
          .thenAnswer((_) async {});
      when(mockOfflinePaymentService.getQueuedPaymentCount())
          .thenAnswer((_) async => 1);
      when(mockOfflinePaymentService.processQueuedPayments())
          .thenAnswer((_) async {});

      // Act - Initialize and attempt upgrade
      await subscriptionProvider.initialize();
      await tester.pumpWidget(createTestApp(subscriptionProvider));

      final upgradeResult = await subscriptionProvider.upgradeTrialToPremium(paymentMethod);
      await tester.pumpAndSettle();

      // Assert payment failed and was queued
      expect(upgradeResult.isSuccess, isFalse);
      verify(mockOfflinePaymentService.queuePaymentForRetry(any)).called(1);

      // Act - Process queued payments (simulating network restoration)
      await subscriptionProvider.refresh();
      await tester.pumpAndSettle();

      // Assert queued payments were processed
      verify(mockOfflinePaymentService.processQueuedPayments()).called(1);
    });

    testWidgets('Subscription cancellation flow', (tester) async {
      // Arrange
      final user = UserProfile(
        id: 'user123',
        email: 'test@example.com',
        fullName: 'Test User',
        stripeCustomerId: 'cus_test123',
        stripeSubscriptionId: 'sub_test123',
      );

      final activeSubscription = SubscriptionInfo(
        id: 'sub_test123',
        status: SubscriptionStatus.active,
        currentPeriodEnd: DateTime.now().add(const Duration(days: 30)),
        customerId: 'cus_test123',
        priceId: 'price_premium_monthly',
      );

      final cancelledSubscription = activeSubscription.copyWith(
        status: SubscriptionStatus.cancelled,
      );

      final subscriptionProvider = SubscriptionProvider(
        paymentService: mockPaymentService,
        backendService: mockBackendService,
        lifecycleService: mockLifecycleService,
        errorHandler: mockErrorHandler,
        offlinePaymentService: mockOfflinePaymentService,
        notificationService: mockNotificationService,
        authService: mockAuthService,
      );

      // Setup mocks
      when(mockAuthService.currentUser).thenReturn(user);
      when(mockPaymentService.initialize()).thenAnswer((_) async {});
      when(mockBackendService.getSubscriptionStatus(any))
          .thenAnswer((_) async => activeSubscription)
          .thenAnswer((_) async => cancelledSubscription);
      when(mockBackendService.getStoredPaymentMethods(any))
          .thenAnswer((_) async => []);
      
      when(mockBackendService.cancelSubscription(any))
          .thenAnswer((_) async => true);
      when(mockLifecycleService.onSubscriptionCancelled(any))
          .thenAnswer((_) async {});
      when(mockNotificationService.showLocalNotification(
        title: anyNamed('title'),
        body: anyNamed('body'),
        data: anyNamed('data'),
      )).thenAnswer((_) async {});

      // Act - Initialize provider
      await subscriptionProvider.initialize();
      await tester.pumpWidget(createTestApp(subscriptionProvider));

      // Assert initial state - active subscription
      expect(subscriptionProvider.isPremiumActive, isTrue);
      expect(subscriptionProvider.canAccessPremiumFeatures, isTrue);

      // Act - Cancel subscription
      final cancelResult = await subscriptionProvider.cancelSubscription(
        reason: 'User requested cancellation',
      );
      await tester.pumpAndSettle();

      // Assert cancellation successful
      expect(cancelResult, isTrue);
      expect(subscriptionProvider.isCancelled, isTrue);
      expect(subscriptionProvider.canAccessPremiumFeatures, isFalse);

      // Verify service calls
      verify(mockBackendService.cancelSubscription('sub_test123')).called(1);
      verify(mockLifecycleService.onSubscriptionCancelled(user)).called(1);
      verify(mockNotificationService.showLocalNotification(
        title: 'Subscription Cancelled',
        body: 'Your subscription has been cancelled successfully',
        data: {'type': 'subscription_cancelled'},
      )).called(1);
    });

    testWidgets('Payment method update flow', (tester) async {
      // Arrange
      final user = UserProfile(
        id: 'user123',
        email: 'test@example.com',
        fullName: 'Test User',
        stripeCustomerId: 'cus_test123',
      );

      final oldPaymentMethod = PaymentMethodInfo(
        id: 'pm_old123',
        type: PaymentMethodType.card,
        card: CardInfo(
          brand: 'visa',
          last4: '1234',
          expMonth: 12,
          expYear: 2024,
        ),
        isDefault: true,
      );

      final newPaymentMethod = PaymentMethodInfo(
        id: 'pm_new123',
        type: PaymentMethodType.card,
        card: CardInfo(
          brand: 'mastercard',
          last4: '5678',
          expMonth: 12,
          expYear: 2026,
        ),
        isDefault: true,
      );

      final subscriptionProvider = SubscriptionProvider(
        paymentService: mockPaymentService,
        backendService: mockBackendService,
        lifecycleService: mockLifecycleService,
        errorHandler: mockErrorHandler,
        offlinePaymentService: mockOfflinePaymentService,
        notificationService: mockNotificationService,
        authService: mockAuthService,
      );

      // Setup mocks
      when(mockAuthService.currentUser).thenReturn(user);
      when(mockPaymentService.initialize()).thenAnswer((_) async {});
      when(mockBackendService.getSubscriptionStatus(any))
          .thenAnswer((_) async => null);
      when(mockBackendService.getStoredPaymentMethods(any))
          .thenAnswer((_) async => [oldPaymentMethod])
          .thenAnswer((_) async => [newPaymentMethod]);
      
      when(mockBackendService.updatePaymentMethod(any, any))
          .thenAnswer((_) async => true);

      // Act - Initialize provider
      await subscriptionProvider.initialize();
      await tester.pumpWidget(createTestApp(subscriptionProvider));

      // Assert initial state
      expect(subscriptionProvider.paymentMethods.length, equals(1));
      expect(subscriptionProvider.paymentMethods.first.card?.last4, equals('1234'));

      // Act - Update payment method
      final updateResult = await subscriptionProvider.updatePaymentMethod(newPaymentMethod);
      await tester.pumpAndSettle();

      // Assert update successful
      expect(updateResult, isTrue);
      expect(subscriptionProvider.paymentMethods.length, equals(1));
      expect(subscriptionProvider.paymentMethods.first.card?.last4, equals('5678'));

      // Verify service calls
      verify(mockBackendService.updatePaymentMethod(
        'cus_test123',
        'pm_new123',
      )).called(1);
    });

    testWidgets('Feature access control throughout subscription lifecycle', (tester) async {
      // Arrange
      final user = UserProfile(
        id: 'user123',
        email: 'test@example.com',
        fullName: 'Test User',
        stripeCustomerId: 'cus_test123',
      );

      final subscriptionProvider = SubscriptionProvider(
        paymentService: mockPaymentService,
        backendService: mockBackendService,
        lifecycleService: mockLifecycleService,
        errorHandler: mockErrorHandler,
        offlinePaymentService: mockOfflinePaymentService,
        notificationService: mockNotificationService,
        authService: mockAuthService,
      );

      when(mockAuthService.currentUser).thenReturn(user);
      when(mockPaymentService.initialize()).thenAnswer((_) async {});
      when(mockBackendService.getStoredPaymentMethods(any))
          .thenAnswer((_) async => []);

      await subscriptionProvider.initialize();
      await tester.pumpWidget(createTestApp(subscriptionProvider));

      // Test 1: No subscription - no premium features
      when(mockBackendService.getSubscriptionStatus(any))
          .thenAnswer((_) async => null);
      await subscriptionProvider.loadSubscriptionStatus();
      await tester.pumpAndSettle();

      expect(subscriptionProvider.canAccessPremiumFeatures, isFalse);
      expect(subscriptionProvider.canAccessFeature('caregiver_dashboard'), isFalse);

      // Test 2: Trial subscription - has premium features but limited
      final trialSubscription = SubscriptionInfo(
        id: 'sub_trial123',
        status: SubscriptionStatus.trial,
        currentPeriodEnd: DateTime.now().add(const Duration(days: 5)),
        customerId: 'cus_test123',
        priceId: 'price_premium_monthly',
      );

      when(mockBackendService.getSubscriptionStatus(any))
          .thenAnswer((_) async => trialSubscription);
      await subscriptionProvider.loadSubscriptionStatus();
      await tester.pumpAndSettle();

      expect(subscriptionProvider.canAccessPremiumFeatures, isTrue);
      expect(subscriptionProvider.canAccessFeature('caregiver_dashboard'), isTrue);
      expect(subscriptionProvider.hasUnlimitedMembers, isFalse);
      expect(subscriptionProvider.maxFamilyMembers, equals(5));

      // Test 3: Active subscription - full premium features
      final activeSubscription = trialSubscription.copyWith(
        status: SubscriptionStatus.active,
      );

      when(mockBackendService.getSubscriptionStatus(any))
          .thenAnswer((_) async => activeSubscription);
      await subscriptionProvider.loadSubscriptionStatus();
      await tester.pumpAndSettle();

      expect(subscriptionProvider.canAccessPremiumFeatures, isTrue);
      expect(subscriptionProvider.hasUnlimitedMembers, isTrue);
      expect(subscriptionProvider.maxFamilyMembers, equals(-1));

      // Test 4: Past due subscription - restricted features
      final pastDueSubscription = activeSubscription.copyWith(
        status: SubscriptionStatus.pastDue,
      );

      when(mockBackendService.getSubscriptionStatus(any))
          .thenAnswer((_) async => pastDueSubscription);
      await subscriptionProvider.loadSubscriptionStatus();
      await tester.pumpAndSettle();

      expect(subscriptionProvider.canAccessPremiumFeatures, isFalse);
      expect(subscriptionProvider.isPaymentPastDue, isTrue);

      final featureAccess = subscriptionProvider.getFeatureAccess('caregiver_dashboard');
      expect(featureAccess.hasAccess, isFalse);
      expect(featureAccess.reason, equals('Payment past due'));
      expect(featureAccess.canUpgrade, isTrue);
    });
  });
}

class TestSubscriptionScreen extends StatelessWidget {
  const TestSubscriptionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription Test')),
      body: Consumer<SubscriptionProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}'),
                  ElevatedButton(
                    onPressed: () => provider.refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Text('Status: ${provider.subscriptionStatusText}'),
              Text('Can access premium: ${provider.canAccessPremiumFeatures}'),
              Text('Trial days remaining: ${provider.trialDaysRemaining}'),
              Text('Max family members: ${provider.maxFamilyMembers}'),
              ElevatedButton(
                onPressed: provider.canAccessPremiumFeatures ? null : () {},
                child: const Text('Premium Feature'),
              ),
            ],
          );
        },
      ),
    );
  }
}