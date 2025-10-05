# FamilyBridge Development Setup Guide

Complete guide to setting up your development environment for FamilyBridge.

---

## Prerequisites

Before you begin, ensure you have the following installed:

### Required Software

1. **Flutter SDK** (3.0+)
   - Download from: https://flutter.dev/docs/get-started/install
   - Add Flutter to your PATH
   - Verify: `flutter --version`

2. **Dart SDK** (3.0+)
   - Comes with Flutter
   - Verify: `dart --version`

3. **Git**
   - Download from: https://git-scm.com/downloads
   - Verify: `git --version`

4. **IDE** (Choose one)
   - **VS Code** (Recommended)
     - Download from: https://code.visualstudio.com/
   - **Android Studio**
     - Download from: https://developer.android.com/studio

5. **Mobile Development Tools**
   - **For Android**:
     - Android Studio
     - Android SDK
     - Android Emulator or physical device
   - **For iOS** (Mac only):
     - Xcode
     - CocoaPods
     - iOS Simulator or physical device

---

## Initial Setup

### 1. Clone the Repository

```bash
git clone https://github.com/kalyank1144/Family-Bridge.git
cd Family-Bridge
```

### 2. Verify Flutter Installation

Run Flutter doctor to check your environment:

```bash
flutter doctor -v
```

Fix any issues reported by Flutter doctor before proceeding.

### 3. Install Dependencies

```bash
flutter pub get
```

This will download all packages specified in `pubspec.yaml`.

---

## IDE Setup

### VS Code Setup (Recommended)

#### 1. Install Required Extensions

Open VS Code and install these extensions:

- **Flutter** (by Dart Code)
  - Extension ID: `Dart-Code.flutter`
- **Dart** (by Dart Code)
  - Extension ID: `Dart-Code.dart-code`
- **Error Lens** (Optional but recommended)
  - Extension ID: `usernamehw.errorlens`
- **GitLens** (Optional)
  - Extension ID: `eamodio.gitlens`

#### 2. Configure VS Code Settings

Create `.vscode/settings.json` in the project root:

```json
{
  "dart.flutterSdkPath": "/path/to/flutter",
  "dart.lineLength": 80,
  "editor.formatOnSave": true,
  "editor.rulers": [80],
  "dart.debugExternalPackageLibraries": true,
  "dart.debugSdkLibraries": false,
  "[dart]": {
    "editor.formatOnSave": true,
    "editor.formatOnType": true,
    "editor.selectionHighlight": false,
    "editor.suggest.snippetsPreventQuickSuggestions": false,
    "editor.suggestSelection": "first",
    "editor.tabCompletion": "onlySnippets",
    "editor.wordBasedSuggestions": false
  }
}
```

#### 3. Configure Launch Configuration

Create `.vscode/launch.json`:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "FamilyBridge (Dev)",
      "request": "launch",
      "type": "dart",
      "program": "lib/main.dart",
      "args": [
        "--dart-define=SUPABASE_URL=${env:SUPABASE_URL}",
        "--dart-define=SUPABASE_ANON_KEY=${env:SUPABASE_ANON_KEY}"
      ]
    },
    {
      "name": "FamilyBridge (Profile)",
      "request": "launch",
      "type": "dart",
      "program": "lib/main.dart",
      "flutterMode": "profile"
    },
    {
      "name": "FamilyBridge (Release)",
      "request": "launch",
      "type": "dart",
      "program": "lib/main.dart",
      "flutterMode": "release"
    }
  ]
}
```

#### 4. Useful VS Code Shortcuts

- **F5**: Start debugging
- **Shift + F5**: Stop debugging
- **Ctrl/Cmd + Shift + P**: Command palette
- **r**: Hot reload (while debugging)
- **R**: Hot restart (while debugging)
- **p**: Toggle performance overlay
- **o**: Toggle platform (iOS/Android)

### Android Studio Setup

#### 1. Install Flutter Plugin

1. Open Android Studio
2. Go to `File > Settings > Plugins` (Windows/Linux) or `Android Studio > Preferences > Plugins` (Mac)
3. Search for "Flutter" and install
4. Restart Android Studio

#### 2. Configure Flutter SDK

1. Go to `File > Settings > Languages & Frameworks > Flutter`
2. Set Flutter SDK path
3. Click "Apply"

---

## Supabase Setup

### 1. Create Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Sign in or create an account
3. Click "New Project"
4. Fill in project details:
   - **Name**: FamilyBridge
   - **Database Password**: (choose a strong password)
   - **Region**: (choose closest to your users)
5. Wait for project to be created

### 2. Get API Credentials

1. Go to Project Settings > API
2. Copy the following:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon public key**: `eyJhbGciOiJIUzI1...`

### 3. Configure Environment

Create `.env` file in project root:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

Update `lib/config/app_config.dart`:

```dart
static const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://your-project.supabase.co',
);

static const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'your-anon-key-here',
);
```

### 4. Create Database Schema

Run these SQL commands in Supabase SQL Editor:

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  email TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  user_type TEXT NOT NULL CHECK (user_type IN ('elder', 'caregiver', 'youth')),
  family_id UUID,
  profile_image_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Families table
CREATE TABLE families (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Family members table
CREATE TABLE family_members (
  family_id UUID REFERENCES families(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  role TEXT NOT NULL,
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY (family_id, user_id)
);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE families ENABLE ROW LEVEL SECURITY;
ALTER TABLE family_members ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own data"
  ON users FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own data"
  ON users FOR UPDATE
  USING (auth.uid() = id);
```

---

## Device Setup

### Android Emulator

1. Open Android Studio
2. Go to `Tools > AVD Manager`
3. Click "Create Virtual Device"
4. Select a device (e.g., Pixel 5)
5. Select a system image (API 30+)
6. Click "Finish"
7. Launch the emulator

### iOS Simulator (Mac only)

1. Open Xcode
2. Go to `Xcode > Preferences > Components`
3. Download desired iOS simulators
4. Run: `open -a Simulator`

### Physical Device

#### Android

1. Enable Developer Options:
   - Go to `Settings > About Phone`
   - Tap "Build Number" 7 times
2. Enable USB Debugging:
   - Go to `Settings > Developer Options`
   - Enable "USB Debugging"
3. Connect device via USB
4. Accept the debugging authorization prompt

#### iOS (Mac only)

1. Connect device via USB
2. Trust the computer when prompted
3. In Xcode, add your Apple ID:
   - `Xcode > Preferences > Accounts`
4. Select your team in project settings

---

## Running the App

### Check Connected Devices

```bash
flutter devices
```

### Run on Specific Device

```bash
# Run on first available device
flutter run

# Run on specific device
flutter run -d <device-id>

# Run on Android
flutter run -d android

# Run on iOS
flutter run -d ios

# Run in release mode
flutter run --release
```

### Hot Reload

While the app is running:
- Press `r` for hot reload (preserves state)
- Press `R` for hot restart (resets state)
- Press `q` to quit

---

## Development Workflow

### 1. Create a Feature Branch

```bash
git checkout -b feature/your-feature-name
```

### 2. Make Changes

Edit files, add features, fix bugs.

### 3. Format Code

```bash
flutter format .
```

### 4. Analyze Code

```bash
flutter analyze
```

### 5. Test Your Changes

```bash
flutter test
```

### 6. Commit Changes

```bash
git add .
git commit -m "Description of changes"
```

### 7. Push to Remote

```bash
git push origin feature/your-feature-name
```

---

## Common Commands

### Project Commands

```bash
# Get dependencies
flutter pub get

# Update dependencies
flutter pub upgrade

# Clean build files
flutter clean

# Build APK
flutter build apk

# Build iOS
flutter build ios

# Generate icons
flutter pub run flutter_launcher_icons:main
```

### Analysis Commands

```bash
# Analyze code
flutter analyze

# Format code
flutter format .

# Check outdated packages
flutter pub outdated
```

### Testing Commands

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage
```

---

## Troubleshooting

### Issue: "Flutter command not found"

**Solution**: Add Flutter to your PATH

```bash
# macOS/Linux - add to ~/.bashrc or ~/.zshrc
export PATH="$PATH:/path/to/flutter/bin"

# Windows - add to System Environment Variables
```

### Issue: "No devices available"

**Solution**: 
1. Check if emulator/device is connected: `flutter devices`
2. Start emulator or connect device
3. Enable USB debugging on Android devices

### Issue: "Packages not found"

**Solution**:
```bash
flutter clean
flutter pub get
```

### Issue: "Gradle build failed" (Android)

**Solution**:
1. Update Android SDK
2. Check `android/build.gradle` for version compatibility
3. Run `flutter clean`
4. Rebuild project

### Issue: "Pod install failed" (iOS)

**Solution**:
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter run
```

### Issue: "Supabase connection failed"

**Solution**:
1. Check `.env` file exists with correct credentials
2. Verify Supabase project is active
3. Check internet connection
4. Verify API keys in Supabase dashboard

---

## Code Quality Tools

### Linting

The project uses `flutter_lints` with custom rules in `analysis_options.yaml`.

Key rules:
- Prefer const constructors
- Use single quotes for strings
- Require trailing commas
- Avoid unnecessary containers

### Code Formatting

```bash
# Format all Dart files
flutter format .

# Check formatting without changes
flutter format --set-exit-if-changed .
```

### Static Analysis

```bash
# Run analyzer
flutter analyze

# Fix auto-fixable issues
dart fix --apply
```

---

## Performance Profiling

### Check Performance

```bash
# Run in profile mode
flutter run --profile

# Generate performance overlay
# Press 'p' while app is running
```

### Analyze App Size

```bash
# Analyze release build
flutter build apk --analyze-size
flutter build ios --analyze-size
```

---

## Debugging Tips

### Debug Console

- View logs in VS Code Debug Console
- Use `debugPrint()` instead of `print()` for production

### Flutter DevTools

```bash
# Open DevTools
flutter pub global activate devtools
flutter pub global run devtools
```

### Common Debug Techniques

1. **Widget Inspector**: View widget tree and properties
2. **Network Tab**: Monitor API calls
3. **Memory Tab**: Check memory usage and leaks
4. **Performance Tab**: Identify performance bottlenecks

---

## Additional Resources

### Documentation
- [FamilyBridge README](README.md)
- [Contributing Guidelines](CONTRIBUTING.md)
- [Project Summary](PROJECT_SUMMARY.md)

### Flutter Resources
- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Documentation](https://dart.dev/guides)
- [Flutter Codelabs](https://flutter.dev/docs/codelabs)

### Community
- [Flutter Discord](https://discord.gg/flutter)
- [Flutter Reddit](https://www.reddit.com/r/FlutterDev/)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/flutter)

---

## Quick Start Checklist

- [ ] Install Flutter SDK
- [ ] Install IDE (VS Code or Android Studio)
- [ ] Clone repository
- [ ] Run `flutter doctor`
- [ ] Run `flutter pub get`
- [ ] Create Supabase project
- [ ] Configure `.env` file
- [ ] Set up emulator/device
- [ ] Run `flutter run`
- [ ] Verify app launches successfully

---

## Need Help?

If you encounter issues:

1. Check this setup guide
2. Review Flutter documentation
3. Check existing GitHub issues
4. Create a new issue with:
   - Detailed problem description
   - Steps to reproduce
   - Flutter doctor output
   - Error messages
   - OS and device information

---

**Happy Coding! 🚀**
