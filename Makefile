.PHONY: help
help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*##"; printf "\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  %-20s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

.PHONY: setup
setup: ## Initial project setup
	@echo "Setting up FamilyBridge project..."
	flutter pub get
	flutter pub global activate flutter_gen
	dart pub global activate dart_code_metrics
	@echo "Creating necessary directories..."
	mkdir -p assets/images assets/icons assets/sounds assets/fonts
	@echo "Setup complete!"

.PHONY: clean
clean: ## Clean build artifacts and caches
	@echo "Cleaning project..."
	flutter clean
	rm -rf build/
	rm -rf .dart_tool/
	rm -rf .packages
	rm -f .flutter-plugins
	rm -f .flutter-plugins-dependencies
	rm -f pubspec.lock
	rm -f .packages
	rm -rf coverage/
	@echo "Clean complete!"

.PHONY: get
get: ## Get dependencies
	flutter pub get

.PHONY: upgrade
upgrade: ## Upgrade dependencies
	flutter pub upgrade

.PHONY: outdated
outdated: ## Check for outdated dependencies
	flutter pub outdated

.PHONY: format
format: ## Format code
	@echo "Formatting code..."
	dart format lib test --line-length=80
	@echo "Format complete!"

.PHONY: analyze
analyze: ## Analyze code
	@echo "Analyzing code..."
	flutter analyze
	dart run dart_code_metrics:metrics analyze lib --reporter=console
	@echo "Analysis complete!"

.PHONY: check
check: format analyze ## Format and analyze code

.PHONY: generate
generate: ## Run code generation
	@echo "Running code generation..."
	flutter pub run build_runner build --delete-conflicting-outputs
	@echo "Code generation complete!"

.PHONY: watch
watch: ## Watch for changes and regenerate code
	flutter pub run build_runner watch --delete-conflicting-outputs

.PHONY: test
test: ## Run all tests
	@echo "Running tests..."
	flutter test --coverage
	@echo "Tests complete!"

.PHONY: test-unit
test-unit: ## Run unit tests
	flutter test test/unit/

.PHONY: test-widget
test-widget: ## Run widget tests
	flutter test test/widget/

.PHONY: test-integration
test-integration: ## Run integration tests
	flutter test integration_test/

.PHONY: coverage
coverage: ## Generate test coverage report
	@echo "Generating coverage report..."
	flutter test --coverage
	lcov --remove coverage/lcov.info 'lib/*/*.g.dart' 'lib/*/*.freezed.dart' -o coverage/lcov.info
	genhtml coverage/lcov.info -o coverage/html
	@echo "Coverage report generated at coverage/html/index.html"

.PHONY: icons
icons: ## Generate app icons
	flutter pub run flutter_launcher_icons

.PHONY: splash
splash: ## Generate splash screens
	flutter pub run flutter_native_splash:create

.PHONY: build-apk
build-apk: ## Build Android APK (debug)
	flutter build apk --debug

.PHONY: build-apk-release
build-apk-release: ## Build Android APK (release)
	flutter build apk --release --obfuscate --split-debug-info=build/debug-info

.PHONY: build-appbundle
build-appbundle: ## Build Android App Bundle
	flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info

.PHONY: build-ios
build-ios: ## Build iOS app
	flutter build ios --release --obfuscate --split-debug-info=build/debug-info

.PHONY: build-ipa
build-ipa: ## Build iOS IPA
	flutter build ipa --release --obfuscate --split-debug-info=build/debug-info

.PHONY: run
run: ## Run app in debug mode
	flutter run

.PHONY: run-dev
run-dev: ## Run app in development flavor
	flutter run --flavor development --dart-define=ENV=development

.PHONY: run-staging
run-staging: ## Run app in staging flavor
	flutter run --flavor staging --dart-define=ENV=staging

.PHONY: run-prod
run-prod: ## Run app in production flavor
	flutter run --flavor production --dart-define=ENV=production --release

.PHONY: devices
devices: ## List available devices
	flutter devices

.PHONY: doctor
doctor: ## Check Flutter installation
	flutter doctor -v

.PHONY: pub-cache-repair
pub-cache-repair: ## Repair pub cache
	flutter pub cache repair

.PHONY: install-hooks
install-hooks: ## Install git hooks
	@echo "Installing git hooks..."
	chmod +x scripts/install-hooks.sh
	./scripts/install-hooks.sh
	@echo "Git hooks installed!"

.PHONY: lint
lint: ## Run linter
	@echo "Running linter..."
	flutter analyze
	@echo "Linting complete!"

.PHONY: fix
fix: ## Auto-fix linter issues
	dart fix --apply

.PHONY: metrics
metrics: ## Calculate code metrics
	@echo "Calculating code metrics..."
	dart run dart_code_metrics:metrics analyze lib --reporter=console
	dart run dart_code_metrics:metrics check-unused-code lib
	dart run dart_code_metrics:metrics check-unused-files lib
	@echo "Metrics complete!"

.PHONY: loc
loc: ## Count lines of code
	@echo "Counting lines of code..."
	@find lib -name '*.dart' | xargs wc -l | sort -n

.PHONY: todo
todo: ## List all TODOs in the project
	@echo "Finding TODOs..."
	@grep -r "TODO\|FIXME\|XXX\|HACK" lib/ --include="*.dart" || echo "No TODOs found!"

.PHONY: security
security: ## Security audit
	@echo "Running security audit..."
	flutter pub audit
	@echo "Security audit complete!"

.PHONY: tree
tree: ## Show project structure
	tree -I 'build|.dart_tool|.idea|*.g.dart|*.freezed.dart' -L 3 lib/

.PHONY: serve-coverage
serve-coverage: coverage ## Serve coverage report
	@echo "Serving coverage report at http://localhost:8000"
	cd coverage/html && python3 -m http.server 8000

.PHONY: commit
commit: check ## Check code before committing
	@echo "Ready to commit!"

.PHONY: pr
pr: check test ## Prepare for pull request
	@echo "Ready for pull request!"

.PHONY: release
release: clean get check test build-appbundle build-ipa ## Prepare release build
	@echo "Release builds complete!"

.PHONY: build-web
build-web: ## Build Web app
	chmod +x scripts/build_web.sh
	./scripts/build_web.sh release
