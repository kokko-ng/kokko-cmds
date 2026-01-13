# Feature Branch Setup

Create a new feature branch with proper tracking and initial structure.

## Arguments

`$ARGUMENTS` - Required: Feature name or GitHub issue reference (e.g., "user-auth", "#42")

If arguments are unclear or missing critical details, use AskUserQuestion to clarify before proceeding.

## Process

### 1. Parse Input

Determine branch type from input:
- `#XX` → GitHub issue number
- Plain text → Feature name

If input is ambiguous, ask user to clarify the feature scope.

### 2. Fetch Issue Details (if applicable)

```bash
gh issue view XX --json title,body,labels
```

### 3. Generate Branch Name

Create branch name following convention:
- `feature/` - New functionality
- `bugfix/` - Bug fixes
- `hotfix/` - Urgent production fixes
- `refactor/` - Code improvements

Format: `{type}/{issue-id}-{short-description}`
Example: `feature/42-user-authentication`

### 4. Create Branch

```bash
# Ensure main is up to date
git checkout main
git pull origin main

# Create and checkout new branch
git checkout -b {branch-name}

# Push and set upstream
git push -u origin {branch-name}
```

### 5. Link to Issue

Branch name containing issue number auto-links to GitHub issues.

### 6. Generate Initial TODO List

Based on issue details, create a TODO list using TodoWrite:
- Break down the feature into implementation steps
- Include standard items: implementation, tests, documentation update

### 7. Output Summary

```
## Feature Branch Created

Branch: feature/42-user-authentication
Tracking: origin/feature/42-user-authentication
Based on: main (commit abc1234)

### Linked Issue
Title: Implement user authentication
Labels: enhancement
Status: open

### Initial TODOs
- [ ] Review existing auth code
- [ ] Implement authentication logic
- [ ] Add unit tests
- [ ] Update API documentation
- [ ] Create PR

Ready to start coding!
```

## Notes

- Always branch from latest main
- If branch already exists, offer to check it out instead
- Validate branch name doesn't contain invalid characters
- If no issue provided, ask for a brief description to generate branch name
