# Branch Protection Rules

This document describes the branch protection rules configured for this repository.

## Main Branch (`main`)

The `main` branch is the production branch and is **protected** with the following rules:

### Pull Request Requirements
- **Require pull request reviews before merging**
  - Required approving reviews: **1**
  - Dismiss stale reviews when new commits are pushed: **Yes**
  - Require review from Code Owners: **No**

### Status Checks
- **Require status checks to pass before merging**
  - Require branches to be up to date before merging: **Yes**
  - Required status checks:
    - `lint`
    - `build (linux, amd64)`
    - `test`

### Other Protections
- **Enforce for administrators**: **Yes**
- **Allow force pushes**: **No**
- **Allow deletions**: **No**
- **Require conversation resolution before merging**: **Yes**

## Dev Branch (`dev`)

The `dev` branch is the development branch and has similar protections but with relaxed admin enforcement:

### Pull Request Requirements
- **Require pull request reviews before merging**
  - Required approving reviews: **1**
  - Dismiss stale reviews when new commits are pushed: **Yes**

### Status Checks
- **Require status checks to pass before merging**
  - Require branches to be up to date before merging: **Yes**
  - Required status checks:
    - `lint`
    - `build (linux, amd64)`
    - `test`

### Other Protections
- **Enforce for administrators**: **No** (allows maintainers to push directly for quick fixes)
- **Allow force pushes**: **No**
- **Allow deletions**: **No**
- **Require conversation resolution before merging**: **Yes**

## Workflow

1. Create a feature branch from `dev`
2. Make changes and push
3. Open a PR against `dev`
4. Wait for CI checks to pass
5. Get at least 1 approval
6. Merge to `dev`
7. After testing, open PR from `dev` to `main`
8. Get approval and merge to `main`
9. Tag release on `main`

## Modifying Protection Rules

Branch protection rules can be modified via:
- GitHub UI: Settings → Branches → Branch protection rules
- GitHub CLI: `gh api` commands
- Terraform/GitHub Actions automation

## References

- [GitHub Branch Protection Rules Documentation](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)