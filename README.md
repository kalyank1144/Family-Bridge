# FamilyBridge

A comprehensive multi-generational family care coordination app built with Flutter, focusing on accessibility, HIPAA compliance, and seamless communication between family members.

## 📋 Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
- [Development](#development)
- [Testing](#testing)
- [Code Quality](#code-quality)
- [Documentation](#documentation)
- [Contributing](#contributing)

## 🎯 Overview

FamilyBridge connects three generations of family members through tailored interfaces:
- **Elders**: Simplified UI with large buttons, voice control, and easy medication tracking
- **Caregivers**: Comprehensive health monitoring, appointment management, and family coordination
- **Youth**: Gamified engagement with story recording, photo sharing, and care points system

## ✨ Features

### For Elders
- Large, accessible interface with voice control
- Daily check-ins with voice recording
- Medication reminders with photo confirmation
- One-tap emergency contacts
- Simplified family chat

### For Caregivers
- Real-time health monitoring dashboard
- Appointment scheduling and reminders
- Professional health reports generation
- Family member management
- Advanced analytics and insights
- HIPAA-compliant data handling

### For Youth
- Story recording and sharing
- Photo memories with family
- Educational games
- Care points and achievements
- Modern chat interface with reactions

## 🏗 Architecture

The project follows **Clean Architecture** principles with clear separation of concerns:

```
lib/
├── core/           # Core functionality
├── features/       # Feature modules
├── models/         # Data models
├── repositories/   # Data repositories
├── services/       # Application services
└── shared/         # Shared resources
```

### State Management
- **Provider** for state management (standardized across the app)
- Reactive UI updates with ChangeNotifier pattern
- Immutable state with controlled mutations

### Key Technologies
- **Flutter 3.x** - Cross-platform framework
- **Supabase** - Backend and authentication
- **Provider** - State management
- **GoRouter** - Navigation
- **Hive** - Local storage
- **Encryption** - HIPAA-compliant data protection

## 🚀 Getting Started

### Prerequisites
- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0
- Android Studio / VS Code with Flutter extensions
- iOS development setup (for iOS builds)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/kalyank1144/Family-Bridge.git
cd Family-Bridge
```

2. Install dependencies:
```bash
make setup
# OR
flutter pub get
```

3. Set up environment variables:
```bash
cp .env.example .env
# Edit .env with your configuration
```

4. Run the app:
```bash
make run
# OR
flutter run
```

## 💻 Development

### Available Commands

Use the Makefile for common tasks:

```bash
make help          # Show all available commands
make setup         # Initial project setup
make clean         # Clean build artifacts
make format        # Format code
make analyze       # Analyze code
make test          # Run all tests
make coverage      # Generate coverage report
make build-apk     # Build Android APK
make build-ios     # Build iOS app
```

### Code Generation

```bash
make generate      # Run build_runner once
make watch         # Watch for changes and regenerate
```

### Git Hooks

Install pre-commit hooks for code quality:

```bash
make install-hooks
```

## 🧪 Testing

### Test Structure

```
test/
├── unit/          # Unit tests
├── widget/        # Widget tests
├── helpers/       # Test utilities
└── fixtures/      # Test data
integration_test/  # Integration tests
```

### Running Tests

```bash
make test              # Run all tests
make test-unit         # Run unit tests
make test-widget       # Run widget tests
make test-integration  # Run integration tests
make coverage          # Generate coverage report
```

### Test Coverage

View coverage reports:
```bash
make serve-coverage    # Serve HTML coverage report
open coverage/html/index.html
```

## 📊 Code Quality

### Linting & Analysis

The project enforces strict code quality standards:

- **analysis_options.yaml** - Comprehensive linting rules
- **dart_code_metrics** - Code complexity analysis
- **Pre-commit hooks** - Automated checks before commit

Run analysis:
```bash
make analyze       # Flutter analyze + metrics
make metrics       # Detailed code metrics
make lint          # Run linter
make fix           # Auto-fix issues
```

### Code Standards

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- Use trailing commas for better diffs
- Maximum line length: 80 characters
- Consistent naming conventions
- Comprehensive documentation for public APIs

See [docs/STANDARDS.md](docs/STANDARDS.md) for detailed coding standards.

## 📚 Documentation

### Architecture Documentation
- [Architecture Overview](docs/ARCHITECTURE.md) - System design and patterns
- [Code Standards](docs/STANDARDS.md) - Coding guidelines and best practices

### API Documentation
Generate API documentation:
```bash
dart doc .
```

## 🔧 VS Code Configuration

The project includes VS Code configurations for optimal development:

- **settings.json** - Editor and Flutter settings
- **launch.json** - Debug configurations
- **extensions.json** - Recommended extensions

## 🔒 Security & Compliance

### HIPAA Compliance
- End-to-end encryption for PHI data
- Audit logging for all data access
- Automatic session timeout
- Secure storage with encryption

### Security Features
- Biometric authentication
- Secure token storage
- Certificate pinning
- Input validation and sanitization

## 🚀 Performance

### Monitoring
- Built-in performance tracking
- Memory leak detection
- Network request monitoring
- Crash reporting

### Optimization
- Lazy loading
- Image caching and compression
- Code splitting
- Efficient state management

## 🤝 Contributing

Please read our contributing guidelines before submitting PRs:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Commit Convention

Follow conventional commits:
```
feat(scope): add new feature
fix(scope): fix bug
docs(scope): update documentation
refactor(scope): refactor code
test(scope): add tests
```

## 📝 License

This project is proprietary software. All rights reserved.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Supabase for backend infrastructure
- All contributors and testers
- Families using FamilyBridge to stay connected

## 📞 Support

For support, email support@familybridge.app or create an issue in this repository.

---

Built with ❤️ for families everywhere