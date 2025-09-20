# FamilyBridge Development Guide

This guide provides detailed information for developers working on the FamilyBridge Flutter application.

## Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Development Environment](#development-environment)
- [Project Structure](#project-structure)
- [State Management](#state-management)
- [Database & Backend](#database--backend)
- [Testing Strategy](#testing-strategy)
- [Build Process](#build-process)
- [Debugging](#debugging)
- [Performance](#performance)
- [Security](#security)

## Project Overview

FamilyBridge is a multi-generational family care coordination app built with Flutter, designed to connect elderly family members, their caregivers, and younger family members in a unified platform.

### Tech Stack

- **Frontend**: Flutter 3.16+, Dart 3.0+
- **State Management**: Riverpod + Provider
- **Backend**: Supabase (PostgreSQL + Auth + Real-time)
- **Navigation**: GoRouter
- **UI Components**: Custom widgets + Material Design 3
- **Animations**: Flutter Animate
- **Testing**: Flutter Test + Integration Tests

## Architecture

### Overall Architecture

The app follows a **feature-based architecture** with clear separation of concerns:

```
lib/
├── core/                 # Shared core functionality
├── features/             # Feature modules
│   ├── elder/           # Elder-specific features
│   ├── caregiver/       # Caregiver-specific features
│   └── chat/            # Family chat features
└── shared/              # Shared components
```

### Design Patterns

- **Provider Pattern**: State management with Riverpod
- **Repository Pattern**: Data access abstraction
- **Service Locator**: Dependency injection
- **Observer Pattern**: Real-time updates via Supabase
- **Factory Pattern**: Model instantiation

## Development Environment

### Setup

1. **Install Flutter**:
   ```bash
   # Check installation
   flutter doctor -v
   ```

2. **Clone and setup project**:
   ```bash
   git clone https://github.com/kalyank1144/Family-Bridge.git
   cd Family-Bridge
   ./scripts/setup_env.sh
   make setup
   ```

3. **Environment variables**:
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

### VS Code Configuration

The project includes optimized VS Code settings:

- **Extensions**: Auto-suggested Flutter/Dart extensions
- **Formatting**: Format on save with 100-character line limit
- **Debugging**: Pre-configured launch configurations
- **Code Actions**: Auto-import organization and fixes

### Make Commands

```bash
make help         # Show available commands
make setup        # Initial project setup
make clean        # Clean build artifacts
make test         # Run all tests
make analyze      # Static analysis
make format       # Format code
make build        # Build debug APK
make build-android # Build release APK
make build-ios    # Build iOS release
```

## Project Structure

### Core Directory (`lib/core/`)

```
core/
├── config/           # App configuration
├── constants/        # App constants
├── router/           # Navigation setup
├── services/         # Core services
├── theme/           # App theme and styling
└── utils/           # Utility functions
```

### Feature Structure

Each feature follows a consistent structure:

```
features/[feature_name]/
├── models/          # Data models
├── providers/       # State management
├── screens/         # UI screens
├── services/        # Feature-specific services
└── widgets/         # Feature-specific widgets
```

### Shared Directory (`lib/shared/`)

```
shared/
├── widgets/         # Reusable UI components
├── services/        # Shared services
├── models/          # Shared data models
└── utils/           # Shared utilities
```

## State Management

### Riverpod Providers

The app uses Riverpod for state management with different provider types:

```dart
// StateProvider - Simple state
final counterProvider = StateProvider<int>((ref) => 0);

// StateNotifierProvider - Complex state
final alertProvider = StateNotifierProvider<AlertNotifier, AlertState>(
  (ref) => AlertNotifier(),
);

// FutureProvider - Async data
final userProvider = FutureProvider<User>((ref) async {
  return await UserService().getCurrentUser();
});

// StreamProvider - Real-time data
final messagesProvider = StreamProvider<List<Message>>((ref) {
  return ChatService().watchMessages();
});
```

### Provider Pattern

Each feature has its own providers organized in the `providers/` directory:

- **Data Providers**: Fetch and cache data
- **State Providers**: Manage UI state
- **Service Providers**: Provide services to widgets

## Database & Backend

### Supabase Setup

The app uses Supabase for backend services:

- **Database**: PostgreSQL with real-time subscriptions
- **Authentication**: Built-in auth with multiple providers
- **Storage**: File storage for images and media
- **Edge Functions**: Server-side logic

### Database Schema

Key tables:
- `users` - User profiles and preferences
- `families` - Family group management
- `messages` - Chat messages with real-time sync
- `appointments` - Caregiver appointment scheduling
- `health_data` - Health monitoring data
- `medications` - Medication tracking
- `emergency_contacts` - Emergency contact information

### Real-time Features

```dart
// Subscribe to real-time updates
final messagesStream = supabase
    .from('messages')
    .stream(primaryKey: ['id'])
    .eq('family_id', familyId)
    .order('created_at');
```

## Testing Strategy

### Test Structure

```
test/
├── unit/            # Unit tests
├── widget/          # Widget tests
└── integration/     # Integration tests
```

### Unit Tests

Test business logic and individual functions:

```dart
void main() {
  group('AlertProvider', () {
    late AlertProvider provider;
    
    setUp(() {
      provider = AlertProvider();
    });
    
    test('should add alert correctly', () {
      // Arrange
      const alert = Alert(message: 'Test alert');
      
      // Act
      provider.addAlert(alert);
      
      // Assert
      expect(provider.alerts.length, 1);
      expect(provider.alerts.first.message, 'Test alert');
    });
  });
}
```

### Widget Tests

Test UI components and interactions:

```dart
void main() {
  testWidgets('AlertCard should display alert message', (tester) async {
    // Arrange
    const alert = Alert(message: 'Test alert');
    
    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: AlertCard(alert: alert),
      ),
    );
    
    // Assert
    expect(find.text('Test alert'), findsOneWidget);
  });
}
```

### Integration Tests

Test complete user workflows:

```dart
void main() {
  group('Family Chat Flow', () {
    testWidgets('should send and receive messages', (tester) async {
      await tester.pumpWidget(MyApp());
      
      // Navigate to chat
      await tester.tap(find.byKey(Key('chat_tab')));
      await tester.pumpAndSettle();
      
      // Send message
      await tester.enterText(find.byType(TextField), 'Hello family!');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();
      
      // Verify message appears
      expect(find.text('Hello family!'), findsOneWidget);
    });
  });
}
```

## Build Process

### Debug Builds

```bash
# Android debug
flutter run
# OR
make build

# iOS debug (macOS only)
flutter run -d ios
```

### Release Builds

```bash
# Android release
./scripts/build_android.sh release
# OR
make build-android

# iOS release (macOS only)
./scripts/build_ios.sh release
# OR
make build-ios
```

### Build Configuration

- **Android**: Configure signing in `android/app/build.gradle`
- **iOS**: Configure signing in Xcode project settings
- **Environment**: Use `.env` files for environment-specific config

## Debugging

### Flutter Inspector

Enable Flutter Inspector in VS Code or Android Studio for:
- Widget tree inspection
- Performance profiling
- Layout debugging

### Debug Console

Use debug prints and logging:

```dart
import 'dart:developer' as developer;

// Debug logging
developer.log('Debug message', name: 'FamilyBridge');

// Conditional debugging
if (kDebugMode) {
  print('Debug info: $data');
}
```

### Network Debugging

Debug Supabase requests:

```dart
// Enable debug mode in Supabase client
final supabase = Supabase.initialize(
  url: 'your_supabase_url',
  anonKey: 'your_anon_key',
  debug: kDebugMode,
);
```

## Performance

### Performance Monitoring

- **Flutter Performance**: Use Flutter DevTools
- **Memory Usage**: Monitor with Observatory
- **Network**: Track API call efficiency
- **Battery**: Profile power consumption

### Optimization Techniques

1. **Widget Rebuilds**: Use `const` constructors and `Provider.select()`
2. **Images**: Optimize image sizes and use `cached_network_image`
3. **Lists**: Use `ListView.builder()` for large lists
4. **State**: Minimize state provider scope
5. **Async**: Use proper async/await patterns

### Code Generation

Use build_runner for code generation:

```bash
# Generate once
flutter pub run build_runner build --delete-conflicting-outputs

# Watch for changes
flutter pub run build_runner watch --delete-conflicting-outputs
```

## Security

### Best Practices

1. **API Keys**: Store in environment variables, never in code
2. **Sensitive Data**: Use `flutter_secure_storage` for sensitive information
3. **Authentication**: Implement proper session management
4. **Validation**: Validate all user inputs
5. **Updates**: Keep dependencies updated

### Supabase Security

- **RLS (Row Level Security)**: Implement database-level security
- **JWT**: Validate tokens properly
- **Policies**: Define strict access policies
- **HTTPS**: Always use secure connections

### Data Privacy

- **GDPR Compliance**: Implement data deletion capabilities
- **Encryption**: Encrypt sensitive data at rest
- **Logging**: Avoid logging sensitive information
- **Permissions**: Request minimal required permissions

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed contribution guidelines.

## Troubleshooting

### Common Issues

1. **Build Failures**: 
   - Run `flutter clean && flutter pub get`
   - Check Flutter doctor output

2. **Hot Reload Issues**:
   - Restart the app
   - Check for syntax errors

3. **Supabase Connection**:
   - Verify environment variables
   - Check network connectivity

4. **iOS Build Issues**:
   - Update CocoaPods: `pod install`
   - Clean Xcode build folder

### Getting Help

- Check the [GitHub Issues](https://github.com/kalyank1144/Family-Bridge/issues)
- Review the [documentation](docs/)
- Ask questions in GitHub Discussions

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [Supabase Documentation](https://supabase.com/docs)
- [Material Design 3](https://m3.material.io/)

Happy coding! 🚀