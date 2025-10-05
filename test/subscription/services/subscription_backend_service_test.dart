import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:family_bridge/core/services/subscription_backend_service.dart';
import 'package:family_bridge/core/models/user_model.dart';
import 'package:family_bridge/features/subscription/models/subscription_status.dart';
import 'package:family_bridge/features/subscription/models/payment_method.dart';

import 'subscription_backend_service_test.mocks.dart';

@GenerateMocks([Dio, Connectivity])
void main() {
  late SubscriptionBackendService subscriptionService;
  late MockDio mockDio;
  late MockConnectivity mockConnectivity;

  setUp(() {
    mockDio = MockDio();
    mockConnectivity = MockConnectivity();
    subscriptionService = SubscriptionBackendService(
      httpClient: mockDio,
      connectivity: mockConnectivity,
    );
  });

  group('SubscriptionBackendService', () {
    group('createStripeCustomer', () {
      test('should create Stripe customer successfully', () async {
        // Arrange
        final user = UserProfile(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'Test User',
        );
        
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => ConnectivityResult.wifi);
        
        when(mockDio.post(
          '/stripe/customers',
          data: any,
        )).thenAnswer((_) async => Response(
          data: {'success': true, 'customer_id': 'cus_test123'},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/stripe/customers'),
        ));

        // Act
        final result = await subscriptionService.createStripeCustomer(user);

        // Assert
        expect(result, isTrue);
        verify(mockDio.post(
          '/stripe/customers',
          data: {
            'email': user.email,
            'name': user.fullName,
            'metadata': {
              'user_id': user.id,
              'app': 'family_bridge',
            },
          },
        )).called(1);
      });

      test('should handle network error gracefully', () async {
        // Arrange
        final user = UserProfile(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'Test User',
        );
        
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => ConnectivityResult.none);

        // Act
        final result = await subscriptionService.createStripeCustomer(user);

        // Assert
        expect(result, isFalse);
        verifyNever(mockDio.post(any, data: any));
      });

      test('should retry on temporary failure', () async {
        // Arrange
        final user = UserProfile(
          id: 'user123',
          email: 'test@example.com',
          fullName: 'Test User',
        );
        
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => ConnectivityResult.wifi);
        
        when(mockDio.post('/stripe/customers', data: any))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: '/stripe/customers'),
              type: DioExceptionType.connectionTimeout,
            ))
            .thenAnswer((_) async => Response(
              data: {'success': true, 'customer_id': 'cus_test123'},
              statusCode: 200,
              requestOptions: RequestOptions(path: '/stripe/customers'),
            ));

        // Act
        final result = await subscriptionService.createStripeCustomer(user);

        // Assert
        expect(result, isTrue);
        verify(mockDio.post('/stripe/customers', data: any)).called(2);
      });
    });

    group('createSubscription', () {
      test('should create subscription successfully', () async {
        // Arrange
        const customerId = 'cus_test123';
        const priceId = 'price_premium_monthly';
        
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => ConnectivityResult.wifi);
        
        when(mockDio.post(
          '/stripe/subscriptions',
          data: any,
        )).thenAnswer((_) async => Response(
          data: {
            'success': true,
            'subscription_id': 'sub_test123',
            'status': 'active',
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/stripe/subscriptions'),
        ));

        // Act
        final result = await subscriptionService.createSubscription(
          customerId,
          priceId,
        );

        // Assert
        expect(result, equals('sub_test123'));
        verify(mockDio.post(
          '/stripe/subscriptions',
          data: {
            'customer': customerId,
            'items': [{'price': priceId}],
            'payment_behavior': 'default_incomplete',
            'payment_settings': {
              'save_default_payment_method': 'on_subscription',
            },
            'expand': ['latest_invoice.payment_intent'],
          },
        )).called(1);
      });

      test('should return empty string on failure', () async {
        // Arrange
        const customerId = 'cus_test123';
        const priceId = 'price_premium_monthly';
        
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => ConnectivityResult.wifi);
        
        when(mockDio.post('/stripe/subscriptions', data: any))
            .thenAnswer((_) async => Response(
              data: {'success': false, 'error': 'Payment method required'},
              statusCode: 400,
              requestOptions: RequestOptions(path: '/stripe/subscriptions'),
            ));

        // Act
        final result = await subscriptionService.createSubscription(
          customerId,
          priceId,
        );

        // Assert
        expect(result, isEmpty);
      });
    });

    group('cancelSubscription', () {
      test('should cancel subscription successfully', () async {
        // Arrange
        const subscriptionId = 'sub_test123';
        
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => ConnectivityResult.wifi);
        
        when(mockDio.delete('/stripe/subscriptions/$subscriptionId'))
            .thenAnswer((_) async => Response(
              data: {'success': true, 'cancelled': true},
              statusCode: 200,
              requestOptions: RequestOptions(path: '/stripe/subscriptions/$subscriptionId'),
            ));

        // Act
        final result = await subscriptionService.cancelSubscription(subscriptionId);

        // Assert
        expect(result, isTrue);
        verify(mockDio.delete('/stripe/subscriptions/$subscriptionId')).called(1);
      });
    });

    group('getSubscriptionStatus', () {
      test('should get subscription status successfully', () async {
        // Arrange
        const customerId = 'cus_test123';
        final expectedSubscription = SubscriptionInfo(
          id: 'sub_test123',
          status: SubscriptionStatus.active,
          currentPeriodEnd: DateTime.now().add(const Duration(days: 30)),
          customerId: customerId,
          priceId: 'price_premium_monthly',
        );
        
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => ConnectivityResult.wifi);
        
        when(mockDio.get('/stripe/customers/$customerId/subscription'))
            .thenAnswer((_) async => Response(
              data: {
                'success': true,
                'subscription': expectedSubscription.toJson(),
              },
              statusCode: 200,
              requestOptions: RequestOptions(path: '/stripe/customers/$customerId/subscription'),
            ));

        // Act
        final result = await subscriptionService.getSubscriptionStatus(customerId);

        // Assert
        expect(result.id, equals(expectedSubscription.id));
        expect(result.status, equals(expectedSubscription.status));
        expect(result.customerId, equals(expectedSubscription.customerId));
      });

      test('should return null when no subscription found', () async {
        // Arrange
        const customerId = 'cus_test123';
        
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => ConnectivityResult.wifi);
        
        when(mockDio.get('/stripe/customers/$customerId/subscription'))
            .thenAnswer((_) async => Response(
              data: {'success': true, 'subscription': null},
              statusCode: 200,
              requestOptions: RequestOptions(path: '/stripe/customers/$customerId/subscription'),
            ));

        // Act
        final result = await subscriptionService.getSubscriptionStatus(customerId);

        // Assert
        expect(result, isNull);
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
        
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => ConnectivityResult.wifi);
        
        when(mockDio.post('/stripe/trials', data: any))
            .thenAnswer((_) async => Response(
              data: {'success': true, 'trial_started': true},
              statusCode: 200,
              requestOptions: RequestOptions(path: '/stripe/trials'),
            ));

        // Act
        final result = await subscriptionService.startTrial(user);

        // Assert
        expect(result, isTrue);
        verify(mockDio.post(
          '/stripe/trials',
          data: {
            'user_id': user.id,
            'email': user.email,
            'trial_days': 30,
          },
        )).called(1);
      });
    });

    group('updatePaymentMethod', () {
      test('should update payment method successfully', () async {
        // Arrange
        const customerId = 'cus_test123';
        const paymentMethodId = 'pm_test123';
        
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => ConnectivityResult.wifi);
        
        when(mockDio.put(
          '/stripe/customers/$customerId/payment-method',
          data: any,
        )).thenAnswer((_) async => Response(
          data: {'success': true, 'updated': true},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/stripe/customers/$customerId/payment-method'),
        ));

        // Act
        final result = await subscriptionService.updatePaymentMethod(
          customerId,
          paymentMethodId,
        );

        // Assert
        expect(result, isTrue);
        verify(mockDio.put(
          '/stripe/customers/$customerId/payment-method',
          data: {'payment_method': paymentMethodId},
        )).called(1);
      });
    });

    group('getStoredPaymentMethods', () {
      test('should get stored payment methods successfully', () async {
        // Arrange
        const customerId = 'cus_test123';
        final expectedPaymentMethods = [
          PaymentMethodInfo(
            id: 'pm_test123',
            type: PaymentMethodType.card,
            card: CardInfo(
              brand: 'visa',
              last4: '4242',
              expMonth: 12,
              expYear: 2025,
            ),
            isDefault: true,
          ),
        ];
        
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => ConnectivityResult.wifi);
        
        when(mockDio.get('/stripe/customers/$customerId/payment-methods'))
            .thenAnswer((_) async => Response(
              data: {
                'success': true,
                'payment_methods': expectedPaymentMethods.map((pm) => pm.toJson()).toList(),
              },
              statusCode: 200,
              requestOptions: RequestOptions(path: '/stripe/customers/$customerId/payment-methods'),
            ));

        // Act
        final result = await subscriptionService.getStoredPaymentMethods(customerId);

        // Assert
        expect(result.length, equals(1));
        expect(result.first.id, equals('pm_test123'));
        expect(result.first.card?.last4, equals('4242'));
      });
    });
  });

  group('Network connectivity handling', () {
    test('should handle offline scenario correctly', () async {
      // Arrange
      final user = UserProfile(
        id: 'user123',
        email: 'test@example.com',
        fullName: 'Test User',
      );
      
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => ConnectivityResult.none);

      // Act
      final result = await subscriptionService.createStripeCustomer(user);

      // Assert
      expect(result, isFalse);
      verifyNever(mockDio.post(any, data: any));
    });

    test('should handle slow network with timeout', () async {
      // Arrange
      final user = UserProfile(
        id: 'user123',
        email: 'test@example.com',
        fullName: 'Test User',
      );
      
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => ConnectivityResult.wifi);
      
      when(mockDio.post('/stripe/customers', data: any))
          .thenThrow(DioException(
            requestOptions: RequestOptions(path: '/stripe/customers'),
            type: DioExceptionType.receiveTimeout,
          ));

      // Act
      final result = await subscriptionService.createStripeCustomer(user);

      // Assert
      expect(result, isFalse);
    });
  });

  group('Error handling', () {
    test('should handle 401 unauthorized error', () async {
      // Arrange
      const customerId = 'cus_test123';
      
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => ConnectivityResult.wifi);
      
      when(mockDio.get('/stripe/customers/$customerId/subscription'))
          .thenThrow(DioException(
            requestOptions: RequestOptions(path: '/stripe/customers/$customerId/subscription'),
            response: Response(
              statusCode: 401,
              data: {'error': 'Unauthorized'},
              requestOptions: RequestOptions(path: '/stripe/customers/$customerId/subscription'),
            ),
            type: DioExceptionType.badResponse,
          ));

      // Act & Assert
      expect(
        () => subscriptionService.getSubscriptionStatus(customerId),
        throwsA(isA<Exception>()),
      );
    });

    test('should handle 500 server error with retry', () async {
      // Arrange
      const customerId = 'cus_test123';
      
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => ConnectivityResult.wifi);
      
      when(mockDio.get('/stripe/customers/$customerId/subscription'))
          .thenThrow(DioException(
            requestOptions: RequestOptions(path: '/stripe/customers/$customerId/subscription'),
            response: Response(
              statusCode: 500,
              data: {'error': 'Internal server error'},
              requestOptions: RequestOptions(path: '/stripe/customers/$customerId/subscription'),
            ),
            type: DioExceptionType.badResponse,
          ))
          .thenAnswer((_) async => Response(
            data: {'success': true, 'subscription': null},
            statusCode: 200,
            requestOptions: RequestOptions(path: '/stripe/customers/$customerId/subscription'),
          ));

      // Act
      final result = await subscriptionService.getSubscriptionStatus(customerId);

      // Assert
      expect(result, isNull);
      verify(mockDio.get('/stripe/customers/$customerId/subscription')).called(2);
    });
  });
}