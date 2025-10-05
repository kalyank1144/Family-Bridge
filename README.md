# FamilyBridge - Intergenerational Care Coordination App

<img src="https://img.shields.io/badge/Flutter-3.0+-blue.svg" alt="Flutter Version">
<img src="https://img.shields.io/badge/Dart-3.0+-blue.svg" alt="Dart Version">
<img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License">

## Overview

FamilyBridge is an innovative intergenerational care coordination mobile application designed to bridge the technology gap between elderly family members, their caregivers, and younger family members. The app features three distinct user interfaces optimized for different age groups:

- **Elder Interface**: Simplified, voice-first interface with large buttons and high contrast
- **Caregiver Dashboard**: Comprehensive health monitoring and task coordination
- **Youth Interface**: Engaging, gamified experience with care points and achievements

## Features

### Elder Interface
- ✅ Voice-first interaction system
- ✅ Large, accessible UI elements (60px minimum touch targets)
- ✅ Emergency contact system with one-tap calling
- ✅ Medication management with photo verification
- ✅ Daily check-in with mood tracking
- ✅ High contrast design optimized for vision impairments

### Caregiver Dashboard
- ✅ Real-time health monitoring
- ✅ Medication compliance tracking
- ✅ Shared medical appointment calendar
- ✅ Task delegation and family coordination
- ✅ Activity and mood analytics
- ✅ Multi-information display with clear data visualization

### Youth Interface
- ✅ Gamification with care points and achievements
- ✅ Story recording and sharing
- ✅ Photo sharing with automatic optimization
- ✅ Interactive games and activities
- ✅ Tech helper mode for remote assistance
- ✅ Modern, engaging UI design

### Shared Features
- ✅ Family chat with voice and text messaging
- ✅ Real-time synchronization
- ✅ Secure authentication
- ✅ Cross-platform support (iOS & Android)

## Technology Stack

- **Frontend**: Flutter 3.0+ / Dart 3.0+
- **Backend**: Supabase (PostgreSQL, Real-time, Auth, Storage)
- **State Management**: Provider
- **Voice Recognition**: speech_to_text, flutter_tts
- **Permissions**: permission_handler
- **Health Integration**: health package
- **UI Components**: Material Design 3

## Project Structure

```
lib/
├── config/
│   └── app_config.dart          # App-wide configuration
├── models/
│   └── user_model.dart          # Data models
├── routes/
│   └── app_routes.dart          # Navigation routes
├── screens/
│   ├── common/                  # Shared screens
│   │   ├── welcome_screen.dart
│   │   ├── user_type_selection_screen.dart
│   │   └── family_chat_screen.dart
│   ├── elder/                   # Elder interface screens
│   │   ├── elder_home_screen.dart
│   │   ├── elder_emergency_contacts_screen.dart
│   │   ├── elder_medication_screen.dart
│   │   └── elder_daily_checkin_screen.dart
│   ├── caregiver/               # Caregiver interface screens
│   │   ├── caregiver_home_screen.dart
│   │   ├── caregiver_health_monitoring_screen.dart
│   │   └── caregiver_appointments_screen.dart
│   └── youth/                   # Youth interface screens
│       ├── youth_home_screen.dart
│       └── youth_story_time_screen.dart
├── services/
│   ├── supabase_service.dart    # Supabase integration
│   └── auth_service.dart        # Authentication service
├── utils/
│   ├── constants.dart           # App constants
│   ├── helpers.dart             # Helper functions
│   └── validators.dart          # Form validators
├── widgets/
│   ├── elder/                   # Elder interface widgets
│   │   ├── elder_action_button.dart
│   │   ├── elder_contact_card.dart
│   │   └── elder_medication_card.dart
│   ├── caregiver/               # Caregiver interface widgets
│   │   ├── family_member_card.dart
│   │   ├── quick_action_button.dart
│   │   └── health_metric_card.dart
│   └── youth/                   # Youth interface widgets
│       ├── care_points_card.dart
│       └── youth_action_card.dart
└── main.dart                    # App entry point
```

## Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:
- Flutter SDK (3.0 or higher)
- Dart SDK (3.0 or higher)
- Android Studio / Xcode (for mobile development)
- Git

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/yourusername/family-bridge.git
cd family-bridge
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure Supabase**

Create a Supabase project at [https://supabase.com](https://supabase.com)

Update the Supabase configuration in `lib/config/app_config.dart`:
```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

Or use environment variables:
```bash
flutter run --dart-define=SUPABASE_URL=your_url --dart-define=SUPABASE_ANON_KEY=your_key
```

4. **Run the app**
```bash
# For development
flutter run

# For specific platform
flutter run -d ios
flutter run -d android
```

## Development

### Code Style

This project follows the official [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style) and uses `flutter_lints` for code analysis.

Run linter:
```bash
flutter analyze
```

Format code:
```bash
flutter format .
```

### Testing

Run tests:
```bash
flutter test
```

### Building

Build for release:
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release
```

## Configuration

### Android Configuration

Update `android/app/build.gradle`:
- Minimum SDK: 21
- Target SDK: 33
- Compile SDK: 33

### iOS Configuration

Update `ios/Podfile`:
- iOS Deployment Target: 12.0

Add required permissions in `ios/Runner/Info.plist`:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access for voice recording</string>
<key>NSCameraUsageDescription</key>
<string>We need camera access for photo sharing</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access for sharing photos</string>
```

## Environment Variables

Create a `.env` file in the root directory (not committed to git):
```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Architecture Decisions

### Three-Generation Approach
FamilyBridge's unique three-generation design addresses the needs of elderly users, caregivers, and youth simultaneously within a single platform, creating a sustainable ecosystem of family support.

### Accessibility-First Design
Every interface element is designed with accessibility as a primary consideration, including WCAG 2.1 AA compliance standards, screen reader support, and alternative input methods.

### Modular Architecture
The codebase is organized into distinct modules (screens, widgets, models, services, utils) to ensure scalability, maintainability, and code reusability.

### State Management
Provider is used for state management due to its simplicity, performance, and official support from the Flutter team.

## Security & Privacy

- End-to-end encryption for sensitive communications
- HIPAA compliance for healthcare data
- Role-based access control
- Secure authentication with Supabase
- Family-controlled data management

## Roadmap

### Phase 1 - MVP (Current)
- [x] Basic user interfaces for all three generations
- [x] Authentication and user management
- [x] Core features for each interface
- [x] Supabase integration

### Phase 2 - Enhanced Features
- [ ] Voice recognition implementation
- [ ] Health monitoring device integration
- [ ] Push notifications
- [ ] Offline mode support

### Phase 3 - AI Features
- [ ] Communication translation
- [ ] Predictive health insights
- [ ] Smart scheduling
- [ ] Intelligent notifications

### Phase 4 - Integrations
- [ ] Healthcare provider integration
- [ ] Pharmacy integration
- [ ] Telehealth support
- [ ] Third-party service integration

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Designed based on comprehensive research on intergenerational care coordination
- Built with Flutter and Supabase
- Inspired by the need to bridge the technology gap between generations

## Support

For support, email support@familybridge.com or join our Slack channel.

## Contact

Project Link: [https://github.com/yourusername/family-bridge](https://github.com/yourusername/family-bridge)

---

Made with ❤️ for families everywhere
