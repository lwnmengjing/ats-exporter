# Contributing to ATS Exporter

Thank you for your interest in contributing to ATS Exporter! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Submitting Changes](#submitting-changes)
- [Coding Standards](#coding-standards)

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## Getting Started

1. Fork the repository on GitHub
2. Clone your fork locally:
   ```bash
   git clone git@github.com:YOUR_USERNAME/ats-exporter.git
   cd ats-exporter
   ```
3. Create a branch for your changes:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Setup

### Prerequisites

- Go 1.24 or later
- Make (optional, for using Makefile commands)
- Docker (optional, for containerized builds)

### Building

```bash
# Build locally
go build -o ats-exporter .

# Or using Make
make build
```

### Running Tests

```bash
# Run tests
go test -v ./...

# Run tests with coverage
go test -v -race -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
```

### Linting

We use golangci-lint for code quality checks:

```bash
# Install golangci-lint
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# Run linter
golangci-lint run
```

## Making Changes

### Code Style

- Follow standard Go conventions and idioms
- Use `gofmt` to format your code
- Run `golangci-lint` before submitting
- Add comments for exported functions and types
- Keep functions small and focused

### Commit Messages

Follow the conventional commits specification:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

Types:
- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Examples:
```
feat(metrics): add new cache hit ratio metric
fix(client): resolve timeout handling issue
docs(readme): update installation instructions
```

### Testing

- Add tests for new functionality
- Ensure all tests pass before submitting
- Aim for meaningful test coverage

## Submitting Changes

### Pull Request Process

1. Push your changes to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```

2. Create a Pull Request on GitHub from your fork to the main repository

3. Ensure the PR description clearly describes:
   - The problem being solved
   - The solution implemented
   - Any relevant issue numbers

4. Wait for CI checks to pass

5. Address any review feedback

### PR Requirements

- All CI checks must pass
- Code must be lint-free
- Tests must pass
- Documentation must be updated if applicable

## Coding Standards

### Go Code Review Comments

Follow the guidelines at [Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments).

### Effective Go

Read and follow [Effective Go](https://golang.org/doc/effective_go.html).

### Project-Specific Guidelines

- Use structured logging with `slog`
- Handle errors explicitly, do not ignore them
- Use context for cancellation when appropriate
- Prefer composition over inheritance

## Questions?

If you have questions, feel free to:
- Open an issue with the `question` label
- Start a discussion in the Discussions section

Thank you for contributing!