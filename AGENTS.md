# AGENTS.md

## Development Workflow

### Before Making Changes

**IMPORTANT**: Always pull the latest changes before making any modifications:

```bash
git pull --rebase
```

This is required because:
- GitHub Copilot may automatically commit fixes to the PR
- Other contributors may push changes
- Keeping your local branch up-to-date prevents merge conflicts

### Branch Strategy

- `main` - Production branch, protected
- `dev` - Development branch, create PRs against this branch

### Commit Convention

Follow conventional commits specification:

```
<type>(<scope>): <description>

[optional body]
```

Types:
- `feat`: A new feature
- `fix`: A bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Build Commands

```bash
# Build with version info
make build VERSION=v1.0.0 REVISION=$(git rev-parse --short HEAD) BRANCH=$(git branch --show-current)

# Run tests
make test

# Run linter
make lint
```

### PR Process

1. Create branch from `dev`
2. Make changes and commit
3. Push and create PR to `dev`
4. Wait for CI and Copilot review
5. Address review feedback
6. **Pull latest changes** (Copilot may have committed fixes)
7. Merge to `dev`
8. After testing, merge `dev` to `main`
9. Tag release on `main` branch

### Release Process

1. Merge PR to `main`
2. Create and push tag:
   ```bash
   git checkout main
   git pull
   git tag v1.0.0
   git push origin v1.0.0
   ```
3. GitHub Actions will automatically:
   - Build binaries for multiple platforms
   - Push Docker image to GHCR
   - Create GitHub Release