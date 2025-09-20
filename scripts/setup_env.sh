#!/bin/bash

# Environment Setup Script for FamilyBridge
# This script sets up the development environment

set -e

APP_NAME="FamilyBridge"
FLUTTER_VERSION="3.16.0"

echo "🚀 Setting up $APP_NAME development environment..."
echo ""

# Check operating system
OS_TYPE=""
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS_TYPE="Linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macOS"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    OS_TYPE="Windows"
else
    echo "⚠️ Unknown operating system: $OSTYPE"
    OS_TYPE="Unknown"
fi

echo "💻 Detected OS: $OS_TYPE"

# Check Flutter installation
echo "🔍 Checking Flutter installation..."
if command -v flutter &> /dev/null; then
    CURRENT_FLUTTER_VERSION=$(flutter --version | grep -o "Flutter [0-9]*\.[0-9]*\.[0-9]*" | cut -d' ' -f2)
    echo "✅ Flutter found: v$CURRENT_FLUTTER_VERSION"
    
    if [ "$CURRENT_FLUTTER_VERSION" != "$FLUTTER_VERSION" ]; then
        echo "⚠️ Recommended Flutter version: v$FLUTTER_VERSION"
        echo "Current version: v$CURRENT_FLUTTER_VERSION"
    fi
else
    echo "❌ Flutter not found!"
    echo "Please install Flutter from: https://docs.flutter.dev/get-started/install"
    exit 1
fi

# Run Flutter doctor
echo ""
echo "🏥 Running Flutter doctor..."
flutter doctor

# Check Git installation
echo ""
echo "🔍 Checking Git installation..."
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version | cut -d' ' -f3)
    echo "✅ Git found: v$GIT_VERSION"
else
    echo "❌ Git not found!"
    echo "Please install Git from: https://git-scm.com/"
    exit 1
fi

# Check VS Code installation (optional)
echo ""
echo "🔍 Checking VS Code installation..."
if command -v code &> /dev/null; then
    echo "✅ VS Code found"
    echo "🔧 Installing recommended extensions..."
    
    # Install Flutter and Dart extensions
    code --install-extension dart-code.dart-code
    code --install-extension dart-code.flutter
    code --install-extension alexisvt.flutter-snippets
    code --install-extension nash.awesome-flutter-snippets
    
    echo "✅ VS Code extensions installed"
else
    echo "⚠️ VS Code not found (optional)"
    echo "You can install it from: https://code.visualstudio.com/"
fi

# Setup project dependencies
echo ""
echo "📦 Setting up project dependencies..."
flutter pub get

# Check for .env file
if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        echo "📝 Creating .env file from .env.example..."
        cp .env.example .env
        echo "⚠️ Please update the .env file with your actual configuration values"
    else
        echo "⚠️ No .env.example file found. You may need to create a .env file manually."
    fi
fi

# Make build scripts executable
echo ""
echo "🔧 Making build scripts executable..."
chmod +x scripts/*.sh

# Run code generation if needed
if grep -q "build_runner" pubspec.yaml; then
    echo ""
    echo "⚙️ Running initial code generation..."
    flutter pub run build_runner build --delete-conflicting-outputs
fi

# Create necessary directories
echo ""
echo "📁 Creating project directories..."
mkdir -p test/unit
mkdir -p test/integration
mkdir -p test/widget
mkdir -p assets/images
mkdir -p assets/icons
mkdir -p assets/fonts
mkdir -p assets/sounds

# Platform-specific setup
case $OS_TYPE in
    "macOS")
        echo ""
        echo "🍎 macOS-specific setup..."
        if [ -d "ios" ]; then
            echo "📦 Installing iOS dependencies..."
            cd ios && pod install && cd ..
        fi
        ;;
    "Linux")
        echo ""
        echo "🐧 Linux-specific setup..."
        echo "Make sure you have the required packages for Flutter development"
        ;;
    "Windows")
        echo ""
        echo "🪟 Windows-specific setup..."
        echo "Ensure Android Studio and Visual Studio are properly configured"
        ;;
esac

# Final checks
echo ""
echo "🔍 Running final environment checks..."
flutter doctor -v

echo ""
echo "🎉 Environment setup completed successfully!"
echo ""
echo "Next steps:"
echo "1. Update .env file with your configuration"
echo "2. Run 'make setup' to initialize the project"
echo "3. Run 'flutter run' to start development"
echo ""
echo "Available make commands:"
echo "  make setup      - Setup development environment"
echo "  make test       - Run tests"
echo "  make build      - Build debug APK"
echo "  make analyze    - Run static analysis"
echo "  make format     - Format code"
echo ""
echo "Happy coding! 🚀"