#!/bin/bash

# Web Build Script for FamilyBridge
# Usage: ./scripts/build_web.sh [debug|release]

set -e

BUILD_MODE="${1:-release}"
APP_NAME="FamilyBridge"

echo "🚀 Starting Web build process..."
echo "🌐 App: $APP_NAME"
echo "🔧 Build mode: $BUILD_MODE"
echo ""

if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed or not in PATH"
    exit 1
fi

echo "🔍 Checking Flutter environment..."
flutter doctor

echo "🧹 Cleaning project..."
flutter clean
flutter pub get

if [ -f "pubspec.yaml" ] && grep -q "build_runner" pubspec.yaml; then
    echo "⚙️ Running code generation..."
    flutter pub run build_runner build --delete-conflicting-outputs
fi

echo "🏗️ Building Web app ($BUILD_MODE)..."
if [ "$BUILD_MODE" == "debug" ]; then
  flutter build web --debug
else
  flutter build web --release --pwa-strategy=offline-first
fi

WEB_PATH="build/web"
if [ -d "$WEB_PATH" ]; then
  SIZE=$(du -sh "$WEB_PATH" | cut -f1)
  echo ""
  echo "✅ Web build successful!"
  echo "📦 Output: $WEB_PATH"
  echo "📏 Size: $SIZE"
else
  echo "❌ Build failed! Web output not found at $WEB_PATH"
  exit 1
fi

echo "🎉 Web build process completed!"