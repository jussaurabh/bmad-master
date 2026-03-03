---
skill: stash-and-undo
category: git
type: patterns
description: "Safely stash work-in-progress and undo commits or changes without losing data"
---

# Skill: Stash and Undo Operations

## PURPOSE
Safely stash work-in-progress and undo commits/changes without losing data.

## STASH OPERATIONS

### Save Work in Progress
```bash
git stash                                          # stash tracked changes
git stash push -m "WIP: dashboard filter refactor" # with descriptive message (recommended)
git stash push -u -m "WIP: including new files"    # include untracked files
git stash push -m "WIP: only auth" -- src/auth/    # stash specific files
```

### Restore Stashed Work
```bash
git stash apply        # apply most recent (keeps in stash list)
git stash pop          # apply and remove from stash list
git stash apply stash@{2}  # apply specific stash
git stash pop stash@{2}    # apply specific stash and remove
```

### Manage Stash List
```bash
git stash list
git stash show         # summary
git stash show -p      # full diff
git stash drop stash@{0}
git stash clear        # DESTRUCTIVE -- confirm with user
```

## UNDO OPERATIONS

### Undo Last Commit (Keep Changes)
```bash
git reset --soft HEAD~1   # undo last commit, keep changes staged
git reset HEAD~1          # undo last commit, keep changes unstaged (--mixed)
git reset --soft HEAD~3   # undo last 3 commits
```

### Undo Last Commit (Discard Changes -- DANGEROUS)
```bash
# ALWAYS CONFIRM WITH USER FIRST -- permanently destroys changes
git reset --hard HEAD~1
```

### Unstage / Discard Changes
```bash
git restore --staged path/to/file.ts   # unstage specific file
git restore --staged .                  # unstage all files
git restore path/to/file.ts            # discard unstaged changes (CONFIRM)
git restore .                           # discard all unstaged changes (CONFIRM)
```

### Undo a Pushed Commit (Safe)
```bash
git revert <commit-hash>    # creates new commit that undoes it
git revert HEAD             # revert last commit
git revert --no-commit <commit-hash>  # review before committing
```

### Recover Deleted Commits (Reflog)
```bash
git reflog                             # find the lost commit
git reset --hard HEAD@{3}             # restore to specific reflog entry
git checkout -b recovery-branch HEAD@{3}  # or create branch at lost commit
```

## UNDO DECISION TREE

```
Want to undo a commit?
├── Was it pushed to remote?
│   ├── YES: git revert (safe, creates new commit)
│   └── NO: git reset --soft HEAD~1 (keeps changes)

Want to discard uncommitted work?
├── Staged changes: git restore --staged .
├── Unstaged changes: git restore . (CONFIRM WITH USER)
└── Both + untracked: git reset --hard && git clean -fd (VERY DANGEROUS)

Want to save work for later?
└── git stash push -m "description"
```

## SAFETY RULES

- **Always `git stash` before any reset/rebase/undo** -- safety net
- **Never `git reset --hard` without confirming** -- it destroys work
- **Prefer `git revert` for pushed commits** -- don't rewrite shared history
- **Use `git reflog` to recover** -- git rarely truly deletes data within 30 days
- **Show what will be lost** before any destructive operation
