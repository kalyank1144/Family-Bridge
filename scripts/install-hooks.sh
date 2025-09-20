#!/bin/bash

# Install Git hooks for code quality

echo "Installing git hooks..."

# Create hooks directory if it doesn't exist
mkdir -p .git/hooks

# Pre-commit hook
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash

echo "Running pre-commit checks..."

# Format check
echo "Checking formatting..."
dart format --set-exit-if-changed lib test
if [ $? -ne 0 ]; then
    echo "❌ Code formatting issues found. Run 'make format' to fix."
    exit 1
fi

# Analyze code
echo "Analyzing code..."
flutter analyze
if [ $? -ne 0 ]; then
    echo "❌ Code analysis failed. Fix the issues and try again."
    exit 1
fi

# Check for TODO comments
TODOS=$(grep -r "TODO\|FIXME\|XXX" lib/ --include="*.dart" | wc -l)
if [ $TODOS -gt 0 ]; then
    echo "⚠️  Warning: Found $TODOS TODO/FIXME comments"
    grep -r "TODO\|FIXME\|XXX" lib/ --include="*.dart" | head -5
fi

# Check for print statements
PRINTS=$(grep -r "print(" lib/ --include="*.dart" | grep -v "// ignore" | wc -l)
if [ $PRINTS -gt 0 ]; then
    echo "❌ Found print statements. Use proper logging instead."
    grep -r "print(" lib/ --include="*.dart" | grep -v "// ignore" | head -5
    exit 1
fi

echo "✅ Pre-commit checks passed!"
EOF

# Pre-push hook
cat > .git/hooks/pre-push << 'EOF'
#!/bin/bash

echo "Running pre-push checks..."

# Run tests
echo "Running tests..."
flutter test
if [ $? -ne 0 ]; then
    echo "❌ Tests failed. Fix failing tests before pushing."
    exit 1
fi

echo "✅ Pre-push checks passed!"
EOF

# Commit message hook
cat > .git/hooks/commit-msg << 'EOF'
#!/bin/bash

# Check commit message format
commit_regex='^(feat|fix|docs|style|refactor|perf|test|chore|revert)(\([a-z]+\))?: .{1,50}'

if ! grep -qE "$commit_regex" "$1"; then
    echo "❌ Invalid commit message format!"
    echo ""
    echo "Commit message must follow the format:"
    echo "  type(scope): subject"
    echo ""
    echo "Examples:"
    echo "  feat(auth): add biometric authentication"
    echo "  fix(elder): resolve voice command issues"
    echo "  refactor(chat): optimize message rendering"
    echo ""
    echo "Types: feat, fix, docs, style, refactor, perf, test, chore, revert"
    exit 1
fi

echo "✅ Commit message format is valid!"
EOF

# Make hooks executable
chmod +x .git/hooks/pre-commit
chmod +x .git/hooks/pre-push
chmod +x .git/hooks/commit-msg

echo "✅ Git hooks installed successfully!"
echo ""
echo "Hooks installed:"
echo "  - pre-commit: Runs formatting and analysis checks"
echo "  - pre-push: Runs tests before pushing"
echo "  - commit-msg: Validates commit message format"
echo ""
echo "To skip hooks temporarily, use:"
echo "  git commit --no-verify"
echo "  git push --no-verify"