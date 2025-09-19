# Contributing to FamilyBridge

Thank you for your interest in contributing to FamilyBridge! This document provides guidelines and information for contributors.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Submitting Changes](#submitting-changes)
- [Pull Request Process](#pull-request-process)
- [Issue Reporting](#issue-reporting)
- [Testing Guidelines](#testing-guidelines)

## Code of Conduct

This project adheres to a code of conduct that we expect all participants to uphold. Please be respectful, inclusive, and constructive in all interactions.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/Family-Bridge.git
   cd Family-Bridge
   ```
3. **Set up the development environment**:
   ```bash
   ./scripts/setup_env.sh
   make setup
   ```

## Development Setup

### Prerequisites

- Flutter SDK (>= 3.16.0)
- Dart SDK (>= 3.0.0)
- Android Studio / VS Code
- Git
- Make (for build commands)

### Environment Configuration

1. Copy `.env.example` to `.env`
2. Update environment variables with your configuration
3. Run `make setup` to install dependencies

### VS Code Setup

The project includes VS Code configuration in `.vscode/`. Recommended extensions will be suggested automatically.

## Coding Standards

### Dart/Flutter Standards

- Follow the official [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use `dart format` to format code (configured to run on save)
- Line length limit: 100 characters
- Use trailing commas for better diffs
- Prefer `const` constructors where possible

### Code Organization

- **Feature-based architecture**: Organize code by features, not by file types
- **Separation of concerns**: Keep business logic separate from UI
- **Provider pattern**: Use Riverpod for state management
- **Repository pattern**: Abstract data access behind repositories

### File Naming

- Use `snake_case` for file names
- Use descriptive names that indicate the file's purpose
- Suffix with the appropriate type (e.g., `_screen.dart`, `_widget.dart`, `_provider.dart`)

### Documentation

- Add dartdoc comments for public APIs
- Include usage examples for complex widgets
- Update README when adding new features
- Document breaking changes in commit messages

## Submitting Changes

### Branch Naming

Use descriptive branch names with prefixes:
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation changes
- `refactor/` - Code refactoring
- `test/` - Test additions/modifications

Example: `feature/caregiver-medication-alerts`

### Commit Messages

Follow conventional commit format:
```
type(scope): brief description

Longer description if necessary

Closes #issue-number
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

Examples:
- `feat(caregiver): add medication reminder notifications`
- `fix(chat): resolve message ordering issue`
- `docs(readme): update installation instructions`

## Pull Request Process

1. **Create a feature branch** from `main`
2. **Write tests** for new functionality
3. **Run the test suite**: `make test`
4. **Run linting**: `make analyze`
5. **Format code**: `make format`
6. **Update documentation** if needed
7. **Create a pull request** with:
   - Clear title and description
   - Reference to related issues
   - Screenshots for UI changes
   - Test coverage information

### PR Requirements

- [ ] All tests pass
- [ ] Code follows style guidelines
- [ ] Documentation updated
- [ ] No merge conflicts
- [ ] Reviewers assigned

## Issue Reporting

### Bug Reports

Include:
- **Clear title** describing the issue
- **Steps to reproduce** the problem
- **Expected behavior**
- **Actual behavior**
- **Device/OS information**
- **Screenshots** if applicable
- **Log output** if relevant

### Feature Requests

Include:
- **Clear description** of the feature
- **Use case** and rationale
- **Acceptance criteria**
- **Mockups/wireframes** if applicable

## Testing Guidelines

### Test Types

1. **Unit Tests** (`test/unit/`)
   - Test individual functions and classes
   - Mock external dependencies
   - Fast execution

2. **Widget Tests** (`test/widget/`)
   - Test UI components in isolation
   - Verify widget rendering and interactions
   - Use `WidgetTester`

3. **Integration Tests** (`test/integration/`)
   - Test complete user workflows
   - Test app behavior end-to-end
   - Use `IntegrationTester`

### Writing Tests

- Write tests for all new features
- Maintain at least 80% code coverage
- Use descriptive test names
- Follow AAA pattern (Arrange, Act, Assert)
- Mock external dependencies

### Running Tests

```bash
# Run all tests
make test

# Run specific test files
flutter test test/unit/caregiver/providers/alert_provider_test.dart

# Run tests with coverage
flutter test --coverage
```

## Development Workflow

1. **Pick an issue** from the GitHub issues
2. **Create a branch** for your work
3. **Write tests** first (TDD approach)
4. **Implement the feature**
5. **Run quality checks**:
   ```bash
   make test
   make analyze
   make format
   ```
6. **Commit changes** with descriptive messages
7. **Push to your fork**
8. **Create a pull request**

## Code Review

### For Authors

- Keep PRs focused and small
- Provide context in PR description
- Respond to feedback promptly
- Be open to suggestions

### For Reviewers

- Be constructive and respectful
- Focus on code quality, not personal preferences
- Suggest improvements with examples
- Approve when ready, don't nitpick

## Getting Help

- **Documentation**: Check the `docs/` directory
- **Discussions**: Use GitHub Discussions for questions
- **Issues**: Report bugs and request features
- **Discord**: Join our development Discord server

## Recognition

Contributors will be recognized in:
- `CONTRIBUTORS.md` file
- GitHub repository contributors page
- Release notes for significant contributions

Thank you for contributing to FamilyBridge! 🚀