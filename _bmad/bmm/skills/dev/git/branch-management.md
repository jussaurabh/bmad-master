---
skill: branch-management
category: git
type: patterns
description: "Handle all branch operations including creating, switching, tracking, deleting, and renaming"
---

# Skill: Branch Management

## PURPOSE
Handle all branch operations -- creating, switching, tracking, deleting, renaming, and managing remote branches.

## COMMON OPERATIONS

### Create and Switch to New Branch
```bash
git checkout -b feature/widget-config
git checkout -b feature/widget-config origin/develop
git switch -c feature/widget-config  # modern syntax
```

### Branch Naming Conventions
- `feature/description` -- new feature
- `fix/description` -- bug fix
- `hotfix/description` -- urgent production fix
- `refactor/description` -- code restructuring
- `chore/description` -- maintenance tasks

### List Branches
```bash
git branch              # local branches
git branch -r           # remote branches
git branch -a           # all branches
git branch -v           # with last commit info
git branch --merged     # branches merged into current
git branch --no-merged  # branches not yet merged
```

### Delete Branches
```bash
git branch -d feature/old-feature           # safe -- won't delete if unmerged
git branch -D feature/old-feature           # force -- CONFIRM WITH USER FIRST
git push origin --delete feature/old-feature  # delete remote branch
```

### Track Remote Branch
```bash
git push -u origin feature/widget-config
git branch --set-upstream-to=origin/feature/widget-config
```

### Rename Branch
```bash
git branch -m new-name              # rename current branch
git branch -m old-name new-name     # rename specific branch
# Update remote after rename:
git push origin --delete old-name
git push -u origin new-name
```

### Sync with Remote
```bash
git fetch --all --prune              # fetch all remote changes
git pull
git pull --rebase                    # pull with rebase (cleaner history)
```

## BRANCH WORKFLOW PATTERNS

### Feature Branch Workflow
```bash
git checkout main && git pull
git checkout -b feature/new-feature
git push -u origin feature/new-feature
gh pr create --base main
```

### Keeping Feature Branch Up to Date
```bash
# Option A: Merge main into feature (preserves history)
git checkout feature/my-feature
git merge main

# Option B: Rebase onto main (cleaner history, only if not shared)
git checkout feature/my-feature
git rebase main
```

## SAFETY PROTOCOLS

- Before deleting: check if branch has unmerged commits (`git branch --no-merged`)
- Before force operations: always `git stash` uncommitted work first
- Before rebasing: confirm branch hasn't been pushed/shared with others
- Always `git fetch --prune` before listing remote branches to get current state
