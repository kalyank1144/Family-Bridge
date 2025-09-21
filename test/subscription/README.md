# Subscription System Testing Framework

This comprehensive testing framework provides complete test coverage for the Family Bridge subscription and payment processing system.

## Overview

The testing framework covers all critical components of the subscription system:

- **Payment Processing** - Stripe integration, payment methods, transactions
- **Subscription Management** - Trial management, upgrades, cancellations
- **Offline Capabilities** - Payment queuing, network resilience
- **Error Handling** - Comprehensive error scenarios and recovery
- **Feature Access Control** - Premium feature gating and user permissions
- **Integration Flows** - End-to-end user journeys and workflows

## Test Structure

```
test/subscription/
├── services/                    # Unit tests for services
│   ├── subscription_backend_service_test.dart
│   ├── payment_service_test.dart
│   └── offline_payment_service_test.dart
├── providers/                   # State management tests
│   └── subscription_provider_test.dart
├── integration/                 # End-to-end integration tests
│   └── payment_flow_integration_test.dart
├── test_config.dart            # Test configuration and utilities
├── run_subscription_tests.dart # Test runner script
└── README.md                   # This file
```

## Running Tests

### Quick Run - All Tests
```bash
flutter test test/subscription/
```

### Using the Test Runner
```bash
# Run all subscription tests with detailed reporting
dart run test/subscription/run_subscription_tests.dart

# Run with coverage report
dart run test/subscription/run_subscription_tests.dart --coverage

# Run only unit tests
dart run test/subscription/run_subscription_tests.dart --unit

# Run only integration tests
dart run test/subscription/run_subscription_tests.dart --integration

# Generate HTML report
dart run test/subscription/run_subscription_tests.dart --report

# Verbose output
dart run test/subscription/run_subscription_tests.dart --verbose
```

### Individual Test Files
```bash
# Backend service tests
flutter test test/subscription/services/subscription_backend_service_test.dart

# Payment service tests
flutter test test/subscription/services/payment_service_test.dart

# Offline payment tests
flutter test test/subscription/services/offline_payment_service_test.dart

# Provider tests
flutter test test/subscription/providers/subscription_provider_test.dart

# Integration tests
flutter test test/subscription/integration/payment_flow_integration_test.dart
```

## Test Categories

### 1. Unit Tests

#### Subscription Backend Service (`subscription_backend_service_test.dart`)
- ✅ Stripe customer creation
- ✅ Subscription management (create, update, cancel)
- ✅ Payment method handling
- ✅ Trial management
- ✅ Network connectivity handling
- ✅ Error handling and retries
- ✅ API response parsing

#### Payment Service (`payment_service_test.dart`)
- ✅ Payment processing workflows
- ✅ Apple Pay / Google Pay integration
- ✅ Payment method collection
- ✅ Payment failure handling
- ✅ Card validation
- ✅ Currency formatting
- ✅ Stripe integration

#### Offline Payment Service (`offline_payment_service_test.dart`)
- ✅ Payment queuing when offline
- ✅ Queue processing on reconnection
- ✅ Exponential backoff retry logic
- ✅ Payment attempt persistence
- ✅ Queue management
- ✅ App lifecycle handling
- ✅ Error scenarios

#### Subscription Provider (`subscription_provider_test.dart`)
- ✅ State management
- ✅ Subscription status tracking
- ✅ Trial management
- ✅ Feature access control
- ✅ Payment method management
- ✅ Error handling
- ✅ Notification listeners
- ✅ UI state synchronization

### 2. Integration Tests

#### Payment Flow Integration (`payment_flow_integration_test.dart`)
- ✅ Complete trial-to-premium upgrade flow
- ✅ Payment failure and retry scenarios
- ✅ Offline payment queuing and processing
- ✅ Subscription cancellation workflow
- ✅ Payment method update flow
- ✅ Feature access throughout subscription lifecycle
- ✅ Cross-service interactions
- ✅ UI state consistency

## Test Configuration

The `test_config.dart` file provides:

- **Mock Data** - Predefined test data for subscriptions, payment methods, users
- **Test Utilities** - Helper functions for common test operations
- **Error Scenarios** - Standardized error conditions for testing
- **Environment Variables** - Test-specific configuration
- **Feature Flags** - Testing different feature combinations

## Key Test Scenarios

### Happy Path Scenarios
1. **New User Trial** - User signs up and starts 30-day trial
2. **Trial Upgrade** - User upgrades trial to premium subscription
3. **Payment Success** - Successful recurring payment processing
4. **Feature Access** - Premium features correctly enabled/disabled

### Error Scenarios
1. **Payment Declined** - Card declined, retry logic, user notification
2. **Network Failure** - Offline payment queuing and processing
3. **Expired Card** - Payment failure due to expired payment method
4. **Subscription Cancellation** - User cancels subscription, feature access updated

### Edge Cases
1. **Concurrent Operations** - Multiple payment operations simultaneously
2. **Rapid Network Changes** - Network connectivity fluctuations
3. **App Lifecycle Events** - Background/foreground transitions
4. **Data Corruption** - Malformed local storage data

## Mock Strategy

Tests use comprehensive mocking to isolate components:

- **Stripe API Calls** - Mocked to prevent real charges during testing
- **Network Requests** - Controlled responses for different scenarios
- **Local Storage** - In-memory storage for test isolation
- **Platform Services** - Apple Pay, Google Pay availability mocking
- **Notifications** - Mocked notification delivery

## Continuous Integration

The testing framework is designed for CI/CD integration:

- **Exit Codes** - Proper exit codes for CI systems
- **JSON Output** - Machine-readable test results
- **Coverage Reports** - Code coverage tracking
- **HTML Reports** - Human-readable test reports
- **Parallel Execution** - Tests can run in parallel

## Coverage Goals

Current coverage targets:
- **Services**: 90%+ line coverage
- **Providers**: 85%+ line coverage  
- **Integration**: 100% critical user flows
- **Error Handling**: 95%+ error scenarios

## Debugging Tests

### Common Issues

1. **SharedPreferences** - Tests failing due to persistence issues
   ```dart
   // Add to setUp()
   SharedPreferences.setMockInitialValues({});
   ```

2. **Async Operations** - Race conditions in async tests
   ```dart
   // Use pumpAndSettle() for widget tests
   await tester.pumpAndSettle();
   ```

3. **Mock Verification** - Unexpected mock calls
   ```dart
   // Use verifyInOrder() for sequential calls
   verifyInOrder([
     mockService.method1(),
     mockService.method2(),
   ]);
   ```

### Debugging Tips

- Run tests with `--verbose` flag for detailed output
- Use `debugPrint()` in test code for debugging
- Check mock setup matches actual service calls
- Verify async operations complete before assertions

## Contributing

When adding new subscription features:

1. **Add Unit Tests** - Test the service/provider in isolation
2. **Add Integration Tests** - Test the complete user flow
3. **Update Test Config** - Add new mock data as needed
4. **Update Documentation** - Document new test scenarios
5. **Run Full Suite** - Ensure all existing tests still pass

## Performance

Test suite performance targets:
- **Unit Tests**: < 30 seconds total
- **Integration Tests**: < 60 seconds total
- **Full Suite**: < 90 seconds total

## Security Testing

Tests include security scenarios:
- **PCI Compliance** - No payment data stored locally
- **API Security** - Proper authentication headers
- **Error Messages** - No sensitive data in error logs
- **Input Validation** - Malformed data handling

## Future Enhancements

Planned testing improvements:
- **E2E Tests** - Full browser-based testing with Stripe test mode
- **Load Testing** - High-volume subscription operations
- **A/B Testing** - Payment flow variations
- **Accessibility Testing** - Screen reader compatibility
- **Localization Testing** - Multi-language payment flows

---

For questions or issues with the testing framework, please check the main project documentation or create an issue in the project repository.