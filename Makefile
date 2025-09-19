.PHONY: setup clean build build-android build-ios test analyze format lint doctor get upgrade outdated help

# Default target
help:
	@echo "Available commands:"
	@echo "  setup      - Setup development environment"
	@echo "  clean      - Clean build artifacts"
	@echo "  build      - Build debug APK"
	@echo "  build-android - Build Android release APK"
	@echo "  build-ios  - Build iOS release app"
	@echo "  test       - Run all tests"
	@echo "  analyze    - Run static analysis"
	@echo "  format     - Format all Dart files"
	@echo "  lint       - Run linting checks"
	@echo "  doctor     - Run flutter doctor"
	@echo "  get        - Get dependencies"
	@echo "  upgrade    - Upgrade dependencies"
	@echo "  outdated   - Check for outdated packages"

setup:
	@echo "Setting up development environment..."
	flutter doctor -v
	flutter pub get
	flutter pub run build_runner build --delete-conflicting-outputs
	@echo "Setup complete!"

clean:
	@echo "Cleaning build artifacts..."
	flutter clean
	flutter pub get
	@echo "Clean complete!"

build:
	@echo "Building debug APK..."
	flutter build apk --debug
	@echo "Debug APK built successfully!"

build-android:
	@echo "Building Android release APK..."
	flutter build apk --release
	@echo "Android release APK built successfully!"

build-ios:
	@echo "Building iOS release app..."
	flutter build ios --release
	@echo "iOS release app built successfully!"

test:
	@echo "Running tests..."
	flutter test --coverage
	@echo "Tests completed!"

test-integration:
	@echo "Running integration tests..."
	flutter test integration_test/
	@echo "Integration tests completed!"

analyze:
	@echo "Running static analysis..."
	flutter analyze
	@echo "Analysis complete!"

format:
	@echo "Formatting Dart files..."
	dart format lib/ test/ integration_test/
	@echo "Formatting complete!"

lint:
	@echo "Running linting checks..."
	dart fix --dry-run
	flutter analyze
	@echo "Linting complete!"

doctor:
	@echo "Running Flutter doctor..."
	flutter doctor -v

get:
	@echo "Getting dependencies..."
	flutter pub get

upgrade:
	@echo "Upgrading dependencies..."
	flutter pub upgrade

outdated:
	@echo "Checking for outdated packages..."
	flutter pub outdated

generate:
	@echo "Running code generation..."
	flutter pub run build_runner build --delete-conflicting-outputs

watch:
	@echo "Watching for file changes and running code generation..."
	flutter pub run build_runner watch --delete-conflicting-outputs