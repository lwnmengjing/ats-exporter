# AGENTS.md

## GitHub Contribution Rules

### Branch Protection Policy

**IMPORTANT: Direct commits to the `main` branch are NOT allowed.**

The `main` branch is protected and requires all changes to go through a Pull Request process.

### Required Workflow for All Changes

1. **Pull latest changes from main branch**
   ```bash
   git checkout main
   git pull --rebase
   ```

2. **Create a new feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```
   
   Branch naming conventions:
   - `feature/xxx` - New features
   - `fix/xxx` - Bug fixes
   - `docs/xxx` - Documentation changes
   - `refactor/xxx` - Code refactoring

3. **Make your changes and commit**
   ```bash
   # Make changes...
   git add .
   git commit -m "type(scope): description"
   ```

4. **Push your branch and create PR**
   ```bash
   git push -u origin feature/your-feature-name
   ```
   
   Then create a Pull Request on GitHub targeting the `main` branch.

5. **Wait for review and CI checks**
   - All CI checks must pass
   - At least 1 approval required (or admin override)
   - Address any review feedback

6. **Pull latest changes before final merge**
   ```bash
   git pull --rebase
   ```
   
   This is required because:
   - GitHub Copilot may automatically commit fixes to the PR
   - Other contributors may push changes
   - Keeping your local branch up-to-date prevents merge conflicts

### Summary: Do NOT do this

❌ **NEVER commit directly to main**
```bash
git checkout main
git add .
git commit -m "my changes"
git push  # This will be rejected
```

✅ **ALWAYS use feature branches and PRs**
```bash
git checkout main
git pull --rebase
git checkout -b feature/my-feature
# ... make changes ...
git add .
git commit -m "feat: add new feature"
git push -u origin feature/my-feature
# Create PR on GitHub
```

## Branch Strategy

- `main` - Production branch, **protected** (direct commits forbidden)
- Feature branches - Create from `main`, merge back via PR

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

## Build Commands

```bash
# Build with version info
make build VERSION=v1.0.0 REVISION=$(git rev-parse --short HEAD) BRANCH=$(git branch --show-current)

# Run tests
make test

# Run linter
make lint
```

## PR Process

1. Create branch from `main`
2. Make changes and commit
3. Push and create PR to `main`
4. Wait for CI and Copilot review
5. Address review feedback
6. **Pull latest changes** (Copilot may have committed fixes)
7. Merge to `main`
8. Tag release on `main` branch

## Release Process

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