# FamilyBridge Deployment Guide

This guide covers deployment procedures for the FamilyBridge Flutter application across different environments and platforms.

## Table of Contents

- [Overview](#overview)
- [Environment Setup](#environment-setup)
- [Android Deployment](#android-deployment)
- [iOS Deployment](#ios-deployment)
- [Backend Deployment](#backend-deployment)
- [CI/CD Pipeline](#cicd-pipeline)
- [Environment Management](#environment-management)
- [Security Considerations](#security-considerations)
- [Monitoring & Analytics](#monitoring--analytics)
- [Rollback Procedures](#rollback-procedures)

## Overview

### Deployment Environments

- **Development**: Local development environment
- **Staging**: Pre-production testing environment
- **Production**: Live production environment

### Release Types

- **Alpha**: Internal testing releases
- **Beta**: External beta testing releases
- **Production**: Public releases

## Environment Setup

### Prerequisites

- Flutter SDK (>= 3.16.0)
- Android Studio / Xcode (for mobile development)
- Google Play Console account (Android)
- Apple Developer account (iOS)
- Supabase project (Backend)

### Environment Variables

Each environment requires specific configuration:

```bash
# Development
SUPABASE_URL=https://your-dev-project.supabase.co
SUPABASE_ANON_KEY=your-dev-anon-key
DEBUG_MODE=true

# Staging
SUPABASE_URL=https://your-staging-project.supabase.co
SUPABASE_ANON_KEY=your-staging-anon-key
DEBUG_MODE=false

# Production
SUPABASE_URL=https://your-prod-project.supabase.co
SUPABASE_ANON_KEY=your-prod-anon-key
DEBUG_MODE=false
```

## Android Deployment

### App Signing Setup

1. **Generate Upload Key**:
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. **Configure Signing in `android/app/build.gradle`**:
   ```gradle
   android {
       signingConfigs {
           release {
               keyAlias keystoreProperties['keyAlias']
               keyPassword keystoreProperties['keyPassword']
               storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
               storePassword keystoreProperties['storePassword']
           }
       }
       
       buildTypes {
           release {
               signingConfig signingConfigs.release
           }
       }
   }
   ```

3. **Create Key Properties** (`android/key.properties`):
   ```properties
   storePassword=your_store_password
   keyPassword=your_key_password
   keyAlias=upload
   storeFile=../upload-keystore.jks
   ```

### Build Process

1. **Production Build**:
   ```bash
   ./scripts/build_android.sh release
   ```

2. **Build Configuration**:
   - Update version in `pubspec.yaml`
   - Configure build flavors if needed
   - Run tests before building

### Google Play Console Deployment

1. **Initial Setup**:
   - Create app listing in Google Play Console
   - Configure store listing details
   - Set up content rating
   - Define target audience

2. **Release Tracks**:
   - **Internal Testing**: Quick testing with internal team
   - **Closed Testing**: Beta testing with specific users
   - **Open Testing**: Public beta testing
   - **Production**: Live release

3. **Upload Process**:
   ```bash
   # Build release APK
   ./scripts/build_android.sh release
   
   # Upload to Play Console (manual or via CI/CD)
   ```

4. **Release Notes**:
   - Document new features
   - List bug fixes
   - Include breaking changes
   - Specify version compatibility

### App Bundle vs APK

Prefer App Bundle for Play Store:
```bash
flutter build appbundle --release
```

## iOS Deployment

### Prerequisites

- macOS with Xcode installed
- Apple Developer Program membership
- Provisioning profiles configured

### Code Signing Setup

1. **Development Certificates**:
   - iOS Development certificate
   - Provisioning profile for development

2. **Distribution Certificates**:
   - iOS Distribution certificate
   - App Store provisioning profile

### Build Process

1. **Production Build**:
   ```bash
   ./scripts/build_ios.sh release
   ```

2. **Xcode Configuration**:
   - Open `ios/Runner.xcworkspace`
   - Configure signing & capabilities
   - Set deployment target
   - Update version and build number

### App Store Connect Deployment

1. **Archive Build**:
   - Product → Archive in Xcode
   - Validate archive
   - Upload to App Store Connect

2. **TestFlight Distribution**:
   - Internal testing with team members
   - External testing with beta users
   - Collect feedback and crash reports

3. **App Store Review**:
   - Submit for review
   - Respond to reviewer feedback
   - Monitor review status

### Automated iOS Deployment

Using Fastlane for automation:

```ruby
# Fastfile
lane :beta do
  build_app(scheme: "Runner")
  upload_to_testflight
end

lane :release do
  build_app(scheme: "Runner")
  upload_to_app_store
end
```

## Backend Deployment

### Supabase Configuration

1. **Database Migrations**:
   ```sql
   -- Apply migrations in order
   \i migrations/001_initial_schema.sql
   \i migrations/002_add_chat_features.sql
   ```

2. **Environment Variables**:
   - Configure in Supabase dashboard
   - Set up different projects for each environment

3. **Edge Functions**:
   ```bash
   supabase functions deploy function-name
   ```

### Database Management

1. **Backup Procedures**:
   - Automated daily backups
   - Point-in-time recovery setup
   - Test restore procedures

2. **Migration Strategy**:
   - Version-controlled schema changes
   - Backwards compatibility
   - Rollback procedures

## CI/CD Pipeline

### GitHub Actions Workflow

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy

on:
  push:
    branches: [main]
  release:
    types: [published]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: flutter pub get
      - run: flutter test
      - run: flutter analyze

  build-android:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - name: Setup Android signing
        run: |
          echo "$ANDROID_KEYSTORE" | base64 -d > android/app/keystore.jks
        env:
          ANDROID_KEYSTORE: ${{ secrets.ANDROID_KEYSTORE }}
      - run: flutter build appbundle --release
      - name: Upload to Play Store
        uses: r0adkll/upload-google-play@v1
        with:
          serviceAccountJsonPlainText: ${{ secrets.SERVICE_ACCOUNT_JSON }}
          packageName: com.familybridge.app
          releaseFiles: build/app/outputs/bundle/release/app-release.aab
          track: production

  build-ios:
    needs: test
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - name: Setup iOS certificates
        run: |
          # Configure certificates and provisioning profiles
      - run: flutter build ios --release --no-codesign
      - name: Build and upload to TestFlight
        run: |
          xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release archive -archivePath build/ios/Runner.xcarchive
          xcodebuild -exportArchive -archivePath build/ios/Runner.xcarchive -exportPath build/ios/Runner.ipa -exportOptionsPlist ios/ExportOptions.plist
```

### Deployment Stages

1. **Build Stage**:
   - Checkout code
   - Install dependencies
   - Run tests
   - Build application

2. **Test Stage**:
   - Unit tests
   - Widget tests
   - Integration tests
   - Code quality checks

3. **Deploy Stage**:
   - Upload to stores
   - Deploy backend changes
   - Update monitoring

## Environment Management

### Configuration Management

Use different configuration files:

```yaml
# config/development.yaml
supabase:
  url: https://dev-project.supabase.co
  key: dev-anon-key

# config/production.yaml
supabase:
  url: https://prod-project.supabase.co
  key: prod-anon-key
```

### Feature Flags

Implement feature toggles:

```dart
class FeatureFlags {
  static const bool enableNewChatUI = bool.fromEnvironment(
    'ENABLE_NEW_CHAT_UI',
    defaultValue: false,
  );
}
```

## Security Considerations

### Secrets Management

- Store sensitive data in CI/CD secrets
- Use environment variables for configuration
- Never commit secrets to version control
- Rotate keys regularly

### Code Obfuscation

Enable obfuscation for production builds:

```bash
flutter build apk --release --obfuscate --split-debug-info=debug-info
```

### Network Security

- Use HTTPS for all communications
- Implement certificate pinning
- Validate SSL certificates
- Use secure authentication flows

## Monitoring & Analytics

### Crash Reporting

Implement crash reporting with Firebase Crashlytics:

```dart
void main() async {
  await Firebase.initializeApp();
  
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  
  runApp(MyApp());
}
```

### Performance Monitoring

- Monitor app startup time
- Track network requests
- Monitor memory usage
- Track user engagement

### Analytics

Implement analytics tracking:

```dart
// Track user events
FirebaseAnalytics.instance.logEvent(
  name: 'message_sent',
  parameters: {
    'chat_type': 'family',
    'message_length': message.length,
  },
);
```

## Rollback Procedures

### Quick Rollback

1. **App Stores**:
   - Halt rollout in Play Console/App Store Connect
   - Promote previous version
   - Communicate with users

2. **Backend**:
   - Revert database migrations
   - Rollback Supabase functions
   - Restore from backup if necessary

### Hotfix Deployment

1. **Create hotfix branch** from production tag
2. **Apply minimal fix**
3. **Fast-track testing**
4. **Emergency deployment**

## Release Checklist

### Pre-Release

- [ ] Version number updated
- [ ] Release notes prepared
- [ ] Tests passing
- [ ] Performance benchmarks met
- [ ] Security scan completed
- [ ] Backup created

### Release

- [ ] Build artifacts generated
- [ ] Uploaded to app stores
- [ ] Backend deployed
- [ ] Monitoring enabled
- [ ] Team notified

### Post-Release

- [ ] Monitor crash reports
- [ ] Check performance metrics
- [ ] Monitor user feedback
- [ ] Document lessons learned
- [ ] Plan next release

## Emergency Procedures

### Incident Response

1. **Detection**: Monitor alerts and user reports
2. **Assessment**: Evaluate severity and impact
3. **Communication**: Notify stakeholders
4. **Mitigation**: Apply immediate fixes
5. **Recovery**: Restore full functionality
6. **Post-mortem**: Document and improve

### Contact Information

- **DevOps Team**: devops@familybridge.app
- **Security Team**: security@familybridge.app
- **On-call Engineer**: +1-xxx-xxx-xxxx

## Resources

- [Flutter Deployment Documentation](https://docs.flutter.dev/deployment)
- [Google Play Console](https://play.google.com/console)
- [App Store Connect](https://appstoreconnect.apple.com)
- [Supabase Dashboard](https://app.supabase.com)

Happy deploying! 🚀