#!/bin/bash

# Android Build Script for FamilyBridge
# Usage: ./scripts/build_android.sh [debug|profile|release]

set -e

BUILD_MODE="${1:-release}"
APP_NAME="FamilyBridge"

echo "🚀 Starting Android build process..."
echo "📱 App: $APP_NAME"
echo "🔧 Build mode: $BUILD_MODE"
echo ""

# Check Flutter installation
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    exit 1
fi

# Run Flutter doctor to check for issues
echo "🔍 Checking Flutter environment..."
flutter doctor

# Clean and get dependencies
echo "🧹 Cleaning project..."
flutter clean
flutter pub get

# Run code generation if needed
if [ -f "pubspec.yaml" ] && grep -q "build_runner" pubspec.yaml; then
    echo "⚙️ Running code generation..."
    flutter pub run build_runner build --delete-conflicting-outputs
fi

# Run tests
echo "🧪 Running tests..."
flutter test

# Build Android app
echo "🏗️ Building Android app ($BUILD_MODE)..."
case $BUILD_MODE in
    debug)
        flutter build apk --debug
        APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"
        ;;
    profile)
        flutter build apk --profile
        APK_PATH="build/app/outputs/flutter-apk/app-profile.apk"
        ;;
    release)
        flutter build apk --release
        APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
        ;;
    *)
        echo "❌ Invalid build mode. Use: debug, profile, or release"
        exit 1
        ;;
esac

# Check if build was successful
if [ -f "$APK_PATH" ]; then
    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
    echo ""
    echo "✅ Build successful!"
    echo "📦 APK location: $APK_PATH"
    echo "📏 APK size: $APK_SIZE"
    echo ""
    
    # Optional: Install to connected device
    read -p "📱 Install to connected device? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "📲 Installing to device..."
        flutter install
        echo "✅ Installation complete!"
    fi
else
    echo "❌ Build failed! APK not found at $APK_PATH"
    exit 1
fi

echo "🎉 Android build process completed!"