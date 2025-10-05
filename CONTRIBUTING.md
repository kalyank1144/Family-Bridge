# Contributing to FamilyBridge

Thank you for your interest in contributing to FamilyBridge! This document provides guidelines and instructions for contributing to the project.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for all contributors.

## How to Contribute

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- A clear and descriptive title
- Detailed steps to reproduce the issue
- Expected behavior vs actual behavior
- Screenshots if applicable
- Device and OS information
- Flutter and Dart versions

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- A clear and descriptive title
- A detailed description of the proposed feature
- Explain why this enhancement would be useful
- List any potential drawbacks or concerns

### Pull Requests

1. Fork the repository
2. Create a new branch from `main`
3. Make your changes
4. Write or update tests as needed
5. Ensure all tests pass
6. Update documentation if needed
7. Submit a pull request

## Development Guidelines

### Code Style

- Follow the [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- Use `flutter format` to format your code
- Run `flutter analyze` before committing
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions small and focused

### Commit Messages

- Use clear and descriptive commit messages
- Start with a verb in present tense (e.g., "Add", "Fix", "Update")
- Reference issue numbers when applicable
- Example: "Fix medication reminder notification timing (#123)"

### Testing

- Write unit tests for new functionality
- Ensure all existing tests pass
- Test on both iOS and Android when possible
- Test with different user types (Elder, Caregiver, Youth)

### Accessibility

- Follow WCAG 2.1 AA standards
- Test with screen readers
- Ensure sufficient color contrast
- Maintain minimum touch target sizes (especially for Elder interface)

## Project-Specific Guidelines

### Elder Interface
- Minimum font size: 18px
- Button font size: 24px
- Header font size: 36px
- Minimum touch target: 60px
- High contrast colors required
- Simple, clear language

### Caregiver Interface
- Professional, healthcare-inspired design
- Clear data visualization
- Efficient information density
- Multiple information streams

### Youth Interface
- Modern, engaging design
- Gamification elements
- Social interaction features
- Clear point values and rewards

## Getting Help

If you need help:
- Check the README.md for setup instructions
- Review existing issues and discussions
- Create a new issue with the "question" label
- Join our community Slack channel

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (MIT License).
