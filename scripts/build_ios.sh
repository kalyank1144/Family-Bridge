#!/bin/bash

# iOS Build Script for FamilyBridge
# Usage: ./scripts/build_ios.sh [debug|profile|release]

set -e

BUILD_MODE="${1:-release}"
APP_NAME="FamilyBridge"

echo "🚀 Starting iOS build process..."
echo "📱 App: $APP_NAME"
echo "🔧 Build mode: $BUILD_MODE"
echo ""

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ iOS builds require macOS"
    exit 1
fi

# Check Flutter installation
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    exit 1
fi

# Check Xcode installation
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode is not installed or command line tools are not available"
    echo "Please install Xcode and run: sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer"
    exit 1
fi

# Run Flutter doctor to check for issues
echo "🔍 Checking Flutter environment..."
flutter doctor

# Clean and get dependencies
echo "🧹 Cleaning project..."
flutter clean
flutter pub get

# Install iOS dependencies (CocoaPods)
echo "📦 Installing iOS dependencies..."
cd ios
pod install --repo-update
cd ..

# Run code generation if needed
if [ -f "pubspec.yaml" ] && grep -q "build_runner" pubspec.yaml; then
    echo "⚙️ Running code generation..."
    flutter pub run build_runner build --delete-conflicting-outputs
fi

# Run tests
echo "🧪 Running tests..."
flutter test

# Build iOS app
echo "🏗️ Building iOS app ($BUILD_MODE)..."
case $BUILD_MODE in
    debug)
        flutter build ios --debug --no-codesign
        ;;
    profile)
        flutter build ios --profile --no-codesign
        ;;
    release)
        flutter build ios --release --no-codesign
        ;;
    *)
        echo "❌ Invalid build mode. Use: debug, profile, or release"
        exit 1
        ;;
esac

# Check if build was successful
IOS_BUILD_PATH="build/ios/iphoneos/Runner.app"
if [ -d "$IOS_BUILD_PATH" ]; then
    BUILD_SIZE=$(du -sh "$IOS_BUILD_PATH" | cut -f1)
    echo ""
    echo "✅ Build successful!"
    echo "📦 iOS app location: $IOS_BUILD_PATH"
    echo "📏 Build size: $BUILD_SIZE"
    echo ""
    
    # Optional: Open in Xcode for further actions
    read -p "🔧 Open in Xcode for signing and deployment? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🔧 Opening Xcode..."
        open ios/Runner.xcworkspace
    fi
else
    echo "❌ Build failed! iOS app not found at $IOS_BUILD_PATH"
    exit 1
fi

echo "🎉 iOS build process completed!"
echo ""
echo "Next steps for App Store deployment:"
echo "1. Open ios/Runner.xcworkspace in Xcode"
echo "2. Configure signing and provisioning profiles"
echo "3. Archive the app (Product > Archive)"
echo "4. Upload to App Store Connect"