import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

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

import 'subscription_provider_test.mocks.dart';

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
  late SubscriptionProvider subscriptionProvider;
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

    subscriptionProvider = SubscriptionProvider(
      paymentService: mockPaymentService,
      backendService: mockBackendService,
      lifecycleService: mockLifecycleService,
      errorHandler: mockErrorHandler,
      offlinePaymentService: mockOfflinePaymentService,
      notificationService: mockNotificationService,
      authService: mockAuthService,
    );
  });

  group('SubscriptionProvider', () {
    group('initialization', () {
      test('should initialize successfully', () async {
        // Arrange
        when(mockPaymentService.initialize()).thenAnswer((_) async {});
        when(mockAuthService.currentUser).thenReturn(null);

        // Act
        await subscriptionProvider.initialize();

        // Assert
        expect(subscriptionProvider.isInitialized, isTrue);
        expect(subscriptionProvider.isLoading, isFalse);
        verify(mockPaymentService.initialize()).called(1);
      });

      test('should handle initialization error gracefully', () async {
        // Arrange
        when(mockPaymentService.initialize())
            .thenThrow(Exception('Initialization failed'));
        when(mockAuthService.currentUser).thenReturn(null);

        // Act
        await subscriptionProvider.initialize();

        // Assert
        expect(subscriptionProvider.error, contains('Failed to initialize'));
        expect(subscriptionProvider.isLoading, isFalse);
      });
    });

    group('loadSubscriptionStatus', () {
      test('should load subscription status successfully', () async {
        // Arrange
        final user = UserProfile(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'Test User',
          stripeCustomerId: 'cus_test123',
        );
        
        final subscription = SubscriptionInfo(
          id: 'sub_test123',
          status: SubscriptionStatus.active,
          currentPeriodEnd: DateTime.now().add(const Duration(days: 30)),
          customerId: 'cus_test123',
          priceId: 'price_premium_monthly',
        );

        when(mockAuthService.currentUser).thenReturn(user);
        when(mockBackendService.getSubscriptionStatus(any))
            .thenAnswer((_) async => subscription);

        // Act
        await subscriptionProvider.loadSubscriptionStatus();

        // Assert
        expect(subscriptionProvider.subscription, equals(subscription));
        expect(subscriptionProvider.hasActiveSubscription, isTrue);
        expect(subscriptionProvider.isPremiumActive, isTrue);
        verify(mockBackendService.getSubscriptionStatus('cus_test123')).called(1);
      });

      test('should handle user without Stripe customer ID', () async {
        // Arrange
        final user = UserProfile(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'Test User',
        );

        when(mockAuthService.currentUser).thenReturn(user);

        // Act
        await subscriptionProvider.loadSubscriptionStatus();

        // Assert
        expect(subscriptionProvider.subscription, isNull);
        verifyNever(mockBackendService.getSubscriptionStatus(any));
      });

      test('should handle no authenticated user', () async {
        // Arrange
        when(mockAuthService.currentUser).thenReturn(null);

        // Act
        await subscriptionProvider.loadSubscriptionStatus();

        // Assert
        expect(subscriptionProvider.subscription, isNull);
        verifyNever(mockBackendService.getSubscriptionStatus(any));
      });
    });

    group('startTrial', () {
      test('should start trial successfully', () async {
        // Arrange
        final user = UserProfile(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'Test User',
        );

        when(mockAuthService.currentUser).thenReturn(user);
        when(mockBackendService.startTrial(any)).thenAnswer((_) async => true);
        when(mockLifecycleService.onTrialStarted(any)).thenAnswer((_) async {});
        when(mockBackendService.getSubscriptionStatus(any)).thenAnswer((_) async => null);

        // Act
        final result = await subscriptionProvider.startTrial();

        // Assert
        expect(result, isTrue);
        verify(mockBackendService.startTrial(user)).called(1);
        verify(mockLifecycleService.onTrialStarted(user)).called(1);
      });

      test('should handle trial start failure', () async {
        // Arrange
        final user = UserProfile(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'Test User',
        );

        when(mockAuthService.currentUser).thenReturn(user);
        when(mockBackendService.startTrial(any)).thenAnswer((_) async => false);

        // Act
        final result = await subscriptionProvider.startTrial();

        // Assert
        expect(result, isFalse);
        expect(subscriptionProvider.error, equals('Failed to start trial'));
      });

      test('should handle unauthenticated user', () async {
        // Arrange
        when(mockAuthService.currentUser).thenReturn(null);

        // Act
        final result = await subscriptionProvider.startTrial();

        // Assert
        expect(result, isFalse);
        expect(subscriptionProvider.error, equals('User not authenticated'));
      });
    });

    group('upgradeTrialToPremium', () {
      test('should upgrade trial to premium successfully', () async {
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

        final successResult = SubscriptionResult(
          isSuccess: true,
          subscriptionId: 'sub_test123',
        );

        when(mockAuthService.currentUser).thenReturn(user);
        when(mockPaymentService.processSubscriptionPayment(
          user: anyNamed('user'),
          priceId: anyNamed('priceId'),
          paymentMethod: anyNamed('paymentMethod'),
        )).thenAnswer((_) async => successResult);
        when(mockLifecycleService.onSubscriptionActivated(any)).thenAnswer((_) async {});
        when(mockBackendService.getSubscriptionStatus(any)).thenAnswer((_) async => null);
        when(mockBackendService.getStoredPaymentMethods(any)).thenAnswer((_) async => []);

        // Act
        final result = await subscriptionProvider.upgradeTrialToPremium(paymentMethod);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(mockPaymentService.processSubscriptionPayment(
          user: user,
          priceId: 'price_premium_monthly',
          paymentMethod: paymentMethod,
        )).called(1);
        verify(mockLifecycleService.onSubscriptionActivated(user)).called(1);
      });

      test('should handle payment failure during upgrade', () async {
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

        final failureResult = SubscriptionResult(
          isSuccess: false,
          error: 'Card declined',
        );

        when(mockAuthService.currentUser).thenReturn(user);
        when(mockPaymentService.processSubscriptionPayment(
          user: anyNamed('user'),
          priceId: anyNamed('priceId'),
          paymentMethod: anyNamed('paymentMethod'),
        )).thenAnswer((_) async => failureResult);

        // Act
        final result = await subscriptionProvider.upgradeTrialToPremium(paymentMethod);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.message, contains('Card declined'));
      });
    });

    group('cancelSubscription', () {
      test('should cancel subscription successfully', () async {
        // Arrange
        final user = UserProfile(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'Test User',
          stripeSubscriptionId: 'sub_test123',
        );

        when(mockAuthService.currentUser).thenReturn(user);
        when(mockBackendService.cancelSubscription(any)).thenAnswer((_) async => true);
        when(mockLifecycleService.onSubscriptionCancelled(any)).thenAnswer((_) async {});
        when(mockNotificationService.showLocalNotification(
          title: anyNamed('title'),
          body: anyNamed('body'),
          data: anyNamed('data'),
        )).thenAnswer((_) async {});
        when(mockBackendService.getSubscriptionStatus(any)).thenAnswer((_) async => null);

        // Act
        final result = await subscriptionProvider.cancelSubscription();

        // Assert
        expect(result, isTrue);
        verify(mockBackendService.cancelSubscription('sub_test123')).called(1);
        verify(mockLifecycleService.onSubscriptionCancelled(user)).called(1);
        verify(mockNotificationService.showLocalNotification(
          title: 'Subscription Cancelled',
          body: 'Your subscription has been cancelled successfully',
          data: {'type': 'subscription_cancelled'},
        )).called(1);
      });

      test('should handle cancellation failure', () async {
        // Arrange
        final user = UserProfile(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'Test User',
          stripeSubscriptionId: 'sub_test123',
        );

        when(mockAuthService.currentUser).thenReturn(user);
        when(mockBackendService.cancelSubscription(any)).thenAnswer((_) async => false);

        // Act
        final result = await subscriptionProvider.cancelSubscription();

        // Assert
        expect(result, isFalse);
        expect(subscriptionProvider.error, equals('Failed to cancel subscription'));
      });

      test('should handle user without subscription', () async {
        // Arrange
        final user = UserProfile(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'Test User',
        );

        when(mockAuthService.currentUser).thenReturn(user);

        // Act
        final result = await subscriptionProvider.cancelSubscription();

        // Assert
        expect(result, isFalse);
        expect(subscriptionProvider.error, equals('No active subscription to cancel'));
      });
    });

    group('feature access', () {
      test('should allow premium features for active subscription', () async {
        // Arrange
        final subscription = SubscriptionInfo(
          id: 'sub_test123',
          status: SubscriptionStatus.active,
          currentPeriodEnd: DateTime.now().add(const Duration(days: 30)),
          customerId: 'cus_test123',
          priceId: 'price_premium_monthly',
        );

        when(mockAuthService.currentUser).thenReturn(UserProfile(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'Test User',
          stripeCustomerId: 'cus_test123',
        ));
        when(mockBackendService.getSubscriptionStatus(any))
            .thenAnswer((_) async => subscription);

        await subscriptionProvider.loadSubscriptionStatus();

        // Act & Assert
        expect(subscriptionProvider.canAccessPremiumFeatures, isTrue);
        expect(subscriptionProvider.canAccessCaregiverDashboard, isTrue);
        expect(subscriptionProvider.canUseAdvancedHealthMonitoring, isTrue);
        expect(subscriptionProvider.canCreateFamilyGroups, isTrue);
        expect(subscriptionProvider.hasUnlimitedMembers, isTrue);
        expect(subscriptionProvider.maxFamilyMembers, equals(-1));
      });

      test('should allow premium features for trial subscription', () async {
        // Arrange
        final subscription = SubscriptionInfo(
          id: 'sub_test123',
          status: SubscriptionStatus.trial,
          currentPeriodEnd: DateTime.now().add(const Duration(days: 5)),
          customerId: 'cus_test123',
          priceId: 'price_premium_monthly',
        );

        when(mockAuthService.currentUser).thenReturn(UserProfile(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'Test User',
          stripeCustomerId: 'cus_test123',
        ));
        when(mockBackendService.getSubscriptionStatus(any))
            .thenAnswer((_) async => subscription);

        await subscriptionProvider.loadSubscriptionStatus();

        // Act & Assert
        expect(subscriptionProvider.canAccessPremiumFeatures, isTrue);
        expect(subscriptionProvider.isTrialActive, isTrue);
        expect(subscriptionProvider.trialDaysRemaining, equals(5));
        expect(subscriptionProvider.hasUnlimitedMembers, isFalse); // Trial doesn't have unlimited
        expect(subscriptionProvider.maxFamilyMembers, equals(5));
      });

      test('should restrict features for expired subscription', () async {
        // Arrange
        final subscription = SubscriptionInfo(
          id: 'sub_test123',
          status: SubscriptionStatus.trialExpired,
          currentPeriodEnd: DateTime.now().subtract(const Duration(days: 1)),
          customerId: 'cus_test123',
          priceId: 'price_premium_monthly',
        );

        when(mockAuthService.currentUser).thenReturn(UserProfile(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'Test User',
          stripeCustomerId: 'cus_test123',
        ));
        when(mockBackendService.getSubscriptionStatus(any))
            .thenAnswer((_) async => subscription);

        await subscriptionProvider.loadSubscriptionStatus();

        // Act & Assert
        expect(subscriptionProvider.canAccessPremiumFeatures, isFalse);
        expect(subscriptionProvider.isTrialExpired, isTrue);
        expect(subscriptionProvider.trialDaysRemaining, equals(0));
      });

      test('should check specific feature access correctly', () async {
        // Arrange
        final subscription = SubscriptionInfo(
          id: 'sub_test123',
          status: SubscriptionStatus.active,
          currentPeriodEnd: DateTime.now().add(const Duration(days: 30)),
          customerId: 'cus_test123',
          priceId: 'price_premium_monthly',
        );

        when(mockAuthService.currentUser).thenReturn(UserProfile(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'Test User',
          stripeCustomerId: 'cus_test123',
        ));
        when(mockBackendService.getSubscriptionStatus(any))
            .thenAnswer((_) async => subscription);

        await subscriptionProvider.loadSubscriptionStatus();

        // Act & Assert
        expect(subscriptionProvider.canAccessFeature('caregiver_dashboard'), isTrue);
        expect(subscriptionProvider.canAccessFeature('advanced_health_monitoring'), isTrue);
        expect(subscriptionProvider.canAccessFeature('family_groups'), isTrue);
        expect(subscriptionProvider.canAccessFeature('unlimited_members'), isTrue);
        expect(subscriptionProvider.canAccessFeature('premium_support'), isTrue);
      });

      test('should provide detailed feature access info', () async {
        // Arrange
        final subscription = SubscriptionInfo(
          id: 'sub_test123',
          status: SubscriptionStatus.trialExpired,
          currentPeriodEnd: DateTime.now().subtract(const Duration(days: 1)),
          customerId: 'cus_test123',
          priceId: 'price_premium_monthly',
        );

        when(mockAuthService.currentUser).thenReturn(UserProfile(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'Test User',
          stripeCustomerId: 'cus_test123',
        ));
        when(mockBackendService.getSubscriptionStatus(any))
            .thenAnswer((_) async => subscription);

        await subscriptionProvider.loadSubscriptionStatus();

        // Act
        final featureAccess = subscriptionProvider.getFeatureAccess('caregiver_dashboard');

        // Assert
        expect(featureAccess.hasAccess, isFalse);
        expect(featureAccess.reason, equals('Trial period expired'));
        expect(featureAccess.canUpgrade, isTrue);
      });
    });

    group('trial ending notifications', () {
      test('should detect trial ending', () async {
        // Arrange
        final subscription = SubscriptionInfo(
          id: 'sub_test123',
          status: SubscriptionStatus.trial,
          currentPeriodEnd: DateTime.now().add(const Duration(days: 2)),
          customerId: 'cus_test123',
          priceId: 'price_premium_monthly',
        );

        when(mockAuthService.currentUser).thenReturn(UserProfile(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'Test User',
          stripeCustomerId: 'cus_test123',
        ));
        when(mockBackendService.getSubscriptionStatus(any))
            .thenAnswer((_) async => subscription);

        await subscriptionProvider.loadSubscriptionStatus();

        // Act & Assert
        expect(subscriptionProvider.isTrialEnding, isTrue);
        expect(subscriptionProvider.trialDaysRemaining, equals(2));
      });
    });

    group('subscription status text', () {
      test('should return correct status text for different states', () async {
        // Test active subscription
        var subscription = SubscriptionInfo(
          id: 'sub_test123',
          status: SubscriptionStatus.active,
          currentPeriodEnd: DateTime.now().add(const Duration(days: 30)),
          customerId: 'cus_test123',
          priceId: 'price_premium_monthly',
        );

        when(mockAuthService.currentUser).thenReturn(UserProfile(
          id: 'user123',
          stripeCustomerId: 'cus_test123',
        ));
        when(mockBackendService.getSubscriptionStatus(any))
            .thenAnswer((_) async => subscription);

        await subscriptionProvider.loadSubscriptionStatus();
        expect(subscriptionProvider.subscriptionStatusText, equals('Premium Active'));

        // Test trial subscription
        subscription = subscription.copyWith(
          status: SubscriptionStatus.trial,
          currentPeriodEnd: DateTime.now().add(const Duration(days: 5)),
        );
        when(mockBackendService.getSubscriptionStatus(any))
            .thenAnswer((_) async => subscription);

        await subscriptionProvider.loadSubscriptionStatus();
        expect(subscriptionProvider.subscriptionStatusText, equals('Trial (5 days remaining)'));

        // Test past due subscription
        subscription = subscription.copyWith(status: SubscriptionStatus.pastDue);
        when(mockBackendService.getSubscriptionStatus(any))
            .thenAnswer((_) async => subscription);

        await subscriptionProvider.loadSubscriptionStatus();
        expect(subscriptionProvider.subscriptionStatusText, equals('Payment Past Due'));
      });
    });

    group('error handling', () {
      test('should handle subscription loading error', () async {
        // Arrange
        when(mockAuthService.currentUser).thenReturn(UserProfile(
          id: 'user123',
          stripeCustomerId: 'cus_test123',
        ));
        when(mockBackendService.getSubscriptionStatus(any))
            .thenThrow(Exception('Network error'));

        // Act
        await subscriptionProvider.loadSubscriptionStatus();

        // Assert
        expect(subscriptionProvider.error, contains('Failed to load subscription status'));
      });

      test('should clear error on successful operation', () async {
        // Arrange
        subscriptionProvider.error; // Set initial error
        
        when(mockAuthService.currentUser).thenReturn(UserProfile(
          id: 'user123',
          stripeCustomerId: 'cus_test123',
        ));
        when(mockBackendService.getSubscriptionStatus(any))
            .thenAnswer((_) async => null);

        // Act
        await subscriptionProvider.loadSubscriptionStatus();

        // Assert
        expect(subscriptionProvider.error, isNull);
      });
    });

    group('refresh', () {
      test('should refresh subscription data', () async {
        // Arrange
        when(mockAuthService.currentUser).thenReturn(UserProfile(
          id: 'user123',
          stripeCustomerId: 'cus_test123',
        ));
        when(mockBackendService.getSubscriptionStatus(any))
            .thenAnswer((_) async => null);
        when(mockBackendService.getStoredPaymentMethods(any))
            .thenAnswer((_) async => []);

        // Act
        await subscriptionProvider.refresh();

        // Assert
        verify(mockBackendService.getSubscriptionStatus('cus_test123')).called(1);
        verify(mockBackendService.getStoredPaymentMethods('cus_test123')).called(1);
      });
    });
  });

  group('ChangeNotifier behavior', () {
    test('should notify listeners on subscription status change', () async {
      // Arrange
      var notificationCount = 0;
      subscriptionProvider.addListener(() => notificationCount++);

      when(mockAuthService.currentUser).thenReturn(UserProfile(
        id: 'user123',
        stripeCustomerId: 'cus_test123',
      ));
      when(mockBackendService.getSubscriptionStatus(any))
          .thenAnswer((_) async => null);

      // Act
      await subscriptionProvider.loadSubscriptionStatus();

      // Assert
      expect(notificationCount, greaterThan(0));
    });

    test('should notify listeners on loading state change', () async {
      // Arrange
      var notificationCount = 0;
      subscriptionProvider.addListener(() => notificationCount++);

      when(mockAuthService.currentUser).thenReturn(null);

      // Act
      await subscriptionProvider.startTrial();

      // Assert
      expect(notificationCount, greaterThan(0));
    });
  });
}