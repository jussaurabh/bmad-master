---
skill: rebase-and-merge
category: git
type: patterns
description: "Handle advanced git history operations -- rebasing, merging, and cherry-picking -- safely"
---

# Skill: Rebase, Merge, and Cherry-Pick

## PURPOSE
Handle advanced git history operations -- rebasing, merging, and cherry-picking -- safely and correctly.

## REBASE

### Interactive Rebase (Clean Up History Before PR)
```bash
# NOTE: git rebase -i requires interactive terminal -- instruct user to run manually
git rebase -i HEAD~5
```
Commands: `pick` | `squash` | `fixup` | `reword` | `drop` | `edit`

### Non-Interactive Rebase (Sync with Base Branch)
```bash
git fetch origin
git rebase origin/main
# On conflict: resolve -> git add -> git rebase --continue
git rebase --abort   # abort if things go wrong
```

### Rebase vs Merge Decision
- **Rebase when**: branch is local only, want clean linear history, preparing for PR
- **Merge when**: branch has been pushed and others are working on it, want to preserve branching history

## MERGE

```bash
git merge feature/widget-config          # basic merge
git merge --no-ff feature/widget-config  # always create merge commit
git merge --no-commit feature/widget-config  # merge but don't auto-commit

# Abort a merge
git merge --abort
```

### Handling Merge Conflicts
```bash
git status              # see conflicted files
# Resolve conflict markers in each file
git add <resolved-files>
git merge --continue    # or git commit
```

**Conflict markers:**
```
<<<<<<< HEAD (your changes)
=======
>>>>>>> feature/branch (incoming changes)
```

## CHERRY-PICK

```bash
git cherry-pick <commit-hash>             # pick single commit
git cherry-pick --no-commit <commit-hash> # stage changes only, don't commit
git cherry-pick <oldest>^..<newest>       # pick range of commits
# On conflict: resolve -> git add -> git cherry-pick --continue
git cherry-pick --abort
```

**Use cases:** backporting a fix, pulling a specific commit into a hotfix branch, recovering from a deleted branch.

**Note:** Cherry-pick creates duplicate commits -- note this when cherry-picking between long-lived branches.

## ADVANCED OPERATIONS

### Squash Last N Commits (Non-Interactive)
```bash
git reset --soft HEAD~3
git commit -m "feat(dashboard): implement complete widget system"
```

### Move Commits to Different Branch (Committed to Wrong Branch)
```bash
git log --oneline -5           # note commit hashes
git branch feature/accidental-work  # create branch at current point
git reset --hard HEAD~N        # reset original branch back
git checkout feature/accidental-work
```

## CONFLICT RESOLUTION CHECKLIST

1. `git status` to list all conflicted files
2. For each file, understand "ours" vs "theirs":
   - During **merge**: ours = current branch, theirs = incoming branch
   - During **rebase**: ours = branch being rebased onto, theirs = your commits
   - During **cherry-pick**: ours = current branch, theirs = picked commit
3. Resolve each file
4. `git add <files>`
5. `git rebase --continue` / `git merge --continue` / `git cherry-pick --continue`

## SAFETY RULES

- **Never rebase commits that have been pushed and shared** -- inform user of consequences
- **Always `git stash` before rebase** to preserve uncommitted work
- **Always confirm before `git reset --hard`** -- it's irreversible
- **After rebasing a pushed branch**: user must force push -- warn them
