# FamilyBridge Code Standards & Guidelines

## Table of Contents
1. [General Principles](#general-principles)
2. [Dart/Flutter Standards](#dartflutter-standards)
3. [File Organization](#file-organization)
4. [Naming Conventions](#naming-conventions)
5. [Code Style](#code-style)
6. [State Management](#state-management)
7. [Widget Guidelines](#widget-guidelines)
8. [Testing Standards](#testing-standards)
9. [Documentation](#documentation)
10. [Git Workflow](#git-workflow)
11. [Performance Guidelines](#performance-guidelines)
12. [Security Standards](#security-standards)

## General Principles

### Core Values
- **Accessibility First**: Every feature must be accessible to all user groups
- **HIPAA Compliance**: All health data must be encrypted and audit-logged
- **Offline First**: App must function without internet connection
- **Performance**: Keep UI responsive (60fps) and minimize memory usage
- **Maintainability**: Write clear, self-documenting code

### Development Philosophy
- Prefer composition over inheritance
- Keep it simple and readable
- Don't repeat yourself (DRY)
- You aren't gonna need it (YAGNI)
- Single responsibility principle

## Dart/Flutter Standards

### Import Organization

Order imports in the following groups, separated by blank lines:

```dart
// 1. Dart imports
import 'dart:async';
import 'dart:io';

// 2. Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 3. Package imports (alphabetical)
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 4. Project imports (relative imports)
import '../../core/services/auth_service.dart';
import '../models/user_model.dart';
import '../widgets/custom_button.dart';
```

### Code Formatting

- **Line Length**: Maximum 80 characters (enforced by formatter)
- **Indentation**: 2 spaces (no tabs)
- **Trailing Commas**: Always use for better diffs
- **Blank Lines**: Single blank line between methods, two between classes

```dart
class ExampleClass {
  final String name;
  final int age;
  
  ExampleClass({
    required this.name,
    required this.age,
  }); // Note trailing comma
  
  void method1() {
    // Implementation
  }
  
  void method2() {
    // Implementation
  }
}


class AnotherClass {
  // Implementation
}
```

## File Organization

### File Structure

Each file should follow this structure:

```dart
// 1. File header comment (optional for complex files)

// 2. Imports

// 3. Constants
const kDefaultPadding = 16.0;

// 4. Enums
enum UserRole { elder, caregiver, youth }

// 5. Main class/widget

// 6. Helper classes

// 7. Private helper functions
```

### File Naming

- **Files**: `snake_case.dart`
- **Test Files**: `[file_name]_test.dart`
- **Generated Files**: `[file_name].g.dart`

## Naming Conventions

### Identifiers

| Type | Convention | Example |
|------|------------|---------|
| Classes | PascalCase | `UserProfile` |
| Mixins | PascalCase | `HipaaCompliance` |
| Extensions | PascalCase | `StringExtensions` |
| Enums | PascalCase | `AuthStatus` |
| Typedef | PascalCase | `JsonMap` |
| Variables | camelCase | `userName` |
| Constants | camelCase or SCREAMING_CAPS | `kPadding` or `MAX_RETRIES` |
| Private | Leading underscore | `_privateMethod` |
| Parameters | camelCase | `userId` |
| Libraries | snake_case | `auth_service` |

### Prefixes and Suffixes

- **Providers**: Suffix with `Provider` (e.g., `AuthProvider`)
- **Services**: Suffix with `Service` (e.g., `StorageService`)
- **Screens**: Suffix with `Screen` (e.g., `LoginScreen`)
- **Widgets**: Descriptive name (e.g., `CustomButton`, `LoadingSpinner`)
- **Models**: Suffix with `Model` or descriptive (e.g., `UserModel`, `Message`)
- **Repositories**: Suffix with `Repository` (e.g., `UserRepository`)

## Code Style

### Variables and Types

```dart
// GOOD
final String name = 'John';
final users = <User>[];
final Map<String, dynamic> json = {};

// BAD
var name = 'John';
final users = [];
Map json = {};
```

### Null Safety

```dart
// GOOD
String? nullableString;
final nonNullString = nullableString ?? 'default';
final length = nullableString?.length ?? 0;

// BAD
String? nullableString;
final nonNullString = nullableString != null ? nullableString : 'default';
```

### Async/Await

```dart
// GOOD
Future<void> fetchData() async {
  try {
    final data = await api.getData();
    processData(data);
  } catch (e) {
    handleError(e);
  }
}

// BAD
Future<void> fetchData() {
  return api.getData().then((data) {
    processData(data);
  }).catchError((e) {
    handleError(e);
  });
}
```

### Collections

```dart
// GOOD
final items = [
  if (condition) item1,
  ...otherItems,
  for (var i in list) transform(i),
];

// BAD
final items = [];
if (condition) items.add(item1);
items.addAll(otherItems);
for (var i in list) {
  items.add(transform(i));
}
```

## State Management

### Provider Pattern

```dart
class FeatureProvider extends ChangeNotifier {
  // Private state
  bool _isLoading = false;
  String? _error;
  List<Item> _items = [];
  
  // Public getters (immutable)
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Item> get items => List.unmodifiable(_items);
  
  // Constructor
  FeatureProvider() {
    _initialize();
  }
  
  // Private initialization
  Future<void> _initialize() async {
    await loadItems();
  }
  
  // Public methods
  Future<void> loadItems() async {
    _setLoading(true);
    _clearError();
    
    try {
      _items = await repository.getItems();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  // Private setters
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
  
  void _clearError() => _setError(null);
  
  @override
  void dispose() {
    // Clean up subscriptions, controllers, etc.
    super.dispose();
  }
}
```

### Using Providers

```dart
// Reading
final provider = context.read<AuthProvider>();
final authState = context.watch<AuthProvider>();
final isLoggedIn = context.select<AuthProvider, bool>((p) => p.isLoggedIn);

// Updating
context.read<AuthProvider>().login(email, password);
```

## Widget Guidelines

### Stateless vs Stateful

```dart
// Use StatelessWidget when possible
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
  });
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

// Use StatefulWidget when needed
class CounterWidget extends StatefulWidget {
  const CounterWidget({super.key});
  
  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int _counter = 0;
  
  @override
  Widget build(BuildContext context) {
    return Text('Count: $_counter');
  }
}
```

### Widget Composition

```dart
// GOOD - Extracted widgets
class UserProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildContent(),
        _buildFooter(),
      ],
    );
  }
  
  Widget _buildHeader() => const ProfileHeader();
  Widget _buildContent() => const ProfileContent();
  Widget _buildFooter() => const ProfileFooter();
}

// BAD - Everything in one build method
class UserProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 200 lines of nested widgets...
      ],
    );
  }
}
```

### Accessibility

```dart
// Every interactive widget must have semantics
Semantics(
  label: 'Submit form',
  hint: 'Double tap to submit the form',
  button: true,
  child: GestureDetector(
    onTap: _submitForm,
    child: Container(
      // ...
    ),
  ),
)

// Use semantic widgets when available
ElevatedButton(  // Already has semantics
  onPressed: _submitForm,
  child: const Text('Submit'),
)
```

## Testing Standards

### Test Organization

```
test/
├── unit/
│   ├── services/
│   ├── providers/
│   └── utils/
├── widget/
│   ├── screens/
│   └── widgets/
└── integration/
    └── flows/
```

### Unit Tests

```dart
void main() {
  group('AuthService', () {
    late AuthService authService;
    late MockSupabaseClient mockClient;
    
    setUp(() {
      mockClient = MockSupabaseClient();
      authService = AuthService(client: mockClient);
    });
    
    tearDown(() {
      // Clean up
    });
    
    test('should successfully log in user', () async {
      // Arrange
      const email = 'test@example.com';
      const password = 'password123';
      when(() => mockClient.auth.signIn(email: email, password: password))
          .thenAnswer((_) async => mockAuthResponse);
      
      // Act
      final result = await authService.login(email, password);
      
      // Assert
      expect(result, isNotNull);
      expect(result.user?.email, equals(email));
      verify(() => mockClient.auth.signIn(email: email, password: password)).called(1);
    });
    
    test('should handle login failure', () async {
      // Test implementation
    });
  });
}
```

### Widget Tests

```dart
void main() {
  testWidgets('CustomButton displays label and handles tap', (tester) async {
    // Arrange
    var tapped = false;
    
    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: CustomButton(
          label: 'Test Button',
          onPressed: () => tapped = true,
        ),
      ),
    );
    
    // Assert
    expect(find.text('Test Button'), findsOneWidget);
    
    await tester.tap(find.byType(CustomButton));
    await tester.pump();
    
    expect(tapped, isTrue);
  });
}
```

### Integration Tests

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('User can complete onboarding flow', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    
    // Welcome screen
    expect(find.text('Welcome to FamilyBridge'), findsOneWidget);
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    
    // User type selection
    await tester.tap(find.text('Elder'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    
    // Profile setup
    // ... continue flow
  });
}
```

## Documentation

### Code Comments

```dart
/// Manages user authentication and session state.
/// 
/// This service handles:
/// - User login/logout
/// - Session persistence
/// - Token refresh
/// - HIPAA compliance logging
class AuthService {
  /// Logs in a user with email and password.
  /// 
  /// Throws [AuthException] if login fails.
  /// Returns [UserProfile] on success.
  Future<UserProfile> login(String email, String password) async {
    // Implementation details commented only when complex
    // ...
  }
}
```

### README Files

Each feature should have a README:

```markdown
# Feature Name

## Overview
Brief description of the feature.

## Architecture
How the feature is structured.

## Key Components
- Component 1: Description
- Component 2: Description

## Usage
How to use this feature.

## Testing
How to test this feature.
```

## Git Workflow

### Branch Naming

- `feature/description` - New features
- `fix/description` - Bug fixes
- `refactor/description` - Code refactoring
- `docs/description` - Documentation
- `test/description` - Tests only

### Commit Messages

Follow conventional commits:

```
type(scope): subject

body (optional)

footer (optional)
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `refactor`: Code refactoring
- `docs`: Documentation
- `test`: Tests
- `style`: Code style
- `perf`: Performance
- `chore`: Maintenance

Examples:
```
feat(auth): add biometric authentication
fix(elder): resolve voice command issues
refactor(chat): optimize message rendering
docs(api): update API documentation
test(caregiver): add health monitoring tests
```

### Pull Request Template

```markdown
## Description
Brief description of changes.

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Refactoring
- [ ] Documentation

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No accessibility regressions
- [ ] HIPAA compliance maintained

## Screenshots (if applicable)
Before/After screenshots.

## Testing
How to test these changes.
```

## Performance Guidelines

### Image Optimization

```dart
// Use cached network images
CachedNetworkImage(
  imageUrl: url,
  placeholder: (context, url) => const CircularProgressIndicator(),
  errorWidget: (context, url, error) => const Icon(Icons.error),
  memCacheHeight: 200, // Limit memory usage
  memCacheWidth: 200,
)

// Prefer SVG for icons
SvgPicture.asset(
  'assets/icons/icon.svg',
  height: 24,
  width: 24,
)
```

### List Optimization

```dart
// Use ListView.builder for long lists
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ListItem(item: items[index]);
  },
)

// Add keys for stateful widgets in lists
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ListItem(
      key: ValueKey(items[index].id),
      item: items[index],
    );
  },
)
```

### Memory Management

```dart
class _MyWidgetState extends State<MyWidget> {
  late final StreamSubscription _subscription;
  late final TextEditingController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _subscription = stream.listen(_handleData);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _subscription.cancel();
    super.dispose();
  }
}
```

## Security Standards

### Data Encryption

```dart
// Always encrypt sensitive data
class SecureStorage {
  static Future<void> saveSecure(String key, String value) async {
    final encrypted = await EncryptionService.encrypt(value);
    await storage.write(key: key, value: encrypted);
  }
  
  static Future<String?> getSecure(String key) async {
    final encrypted = await storage.read(key: key);
    if (encrypted == null) return null;
    return EncryptionService.decrypt(encrypted);
  }
}
```

### Input Validation

```dart
// Validate all user input
class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Invalid email format';
    }
    return null;
  }
  
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(value)) {
      return 'Password must contain letters and numbers';
    }
    return null;
  }
}
```

### HIPAA Compliance

```dart
// Log all PHI access
mixin HipaaAudit<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    HipaaLogger.logAccess(
      screen: widget.runtimeType.toString(),
      action: 'view',
      userId: currentUser.id,
    );
  }
  
  void logDataAccess(String dataType, String action) {
    HipaaLogger.logDataAccess(
      dataType: dataType,
      action: action,
      userId: currentUser.id,
      timestamp: DateTime.now(),
    );
  }
}
```

## Code Review Checklist

Before submitting a PR, ensure:

- [ ] Code compiles without warnings
- [ ] All tests pass
- [ ] Code follows naming conventions
- [ ] No hardcoded values (use constants)
- [ ] No commented-out code
- [ ] No print statements (use proper logging)
- [ ] Accessibility features maintained
- [ ] HIPAA compliance maintained
- [ ] Documentation updated
- [ ] Performance impact considered
- [ ] Security best practices followed
- [ ] Error handling implemented
- [ ] Loading states handled
- [ ] Offline functionality works

## Resources

- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [Flutter Best Practices](https://flutter.dev/docs/perf/best-practices)
- [Provider Documentation](https://pub.dev/packages/provider)
- [WCAG Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [HIPAA Security Rule](https://www.hhs.gov/hipaa/for-professionals/security)