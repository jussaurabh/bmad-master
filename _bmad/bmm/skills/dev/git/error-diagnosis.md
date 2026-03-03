---
skill: error-diagnosis
category: git
type: workflow
description: "Diagnose git and gh CLI errors, explain them clearly, and provide the correct fix"
---

# Skill: Git Error Diagnosis

## PURPOSE
Diagnose git and gh CLI errors in plain language and provide the correct fix.

## COMMON GIT ERRORS

### Authentication & Permission
| Error | Fix |
|-------|-----|
| `fatal: Authentication failed` | `gh auth login` or check SSH: `ssh -T git@github.com` |
| `Permission denied (publickey)` | Add SSH key: `gh ssh-key add ~/.ssh/id_ed25519.pub` |
| `remote: Permission to X denied to Y` | Check repo permissions or fork |
| `error: 403` | Re-authenticate: `gh auth login --hostname github.com` |

### Push/Pull
| Error | Fix |
|-------|-----|
| `! [rejected] main (non-fast-forward)` | `git pull --rebase origin main` then push again |
| `error: failed to push some refs` | Pull first: `git pull` or `git pull --rebase` |
| `no upstream branch` | `git push -u origin HEAD` |
| `CONFLICT (content)` | Resolve conflicts → `git add` → `git commit` |
| `local changes would be overwritten` | `git stash` first, then pull, then `git stash pop` |

### Commit
| Error | Fix |
|-------|-----|
| `nothing to commit, working tree clean` | Check you're in the right directory |
| `Changes not staged for commit` | `git add <files>` before committing |
| `pathspec did not match any files` | Check path with `git status` |

### Branch
| Error | Fix |
|-------|-----|
| `branch named 'X' already exists` | Choose a different name or delete the old one |
| `branch 'X' is not fully merged` | Use `-D` to force (confirm with user) or merge first |

### Rebase / Stash
| Error | Fix |
|-------|-----|
| `CONFLICT during rebase` | Resolve → `git add` → `git rebase --continue` |
| `You have unstaged changes` | `git stash push -m "pre-rebase"` |
| `No stash entries found` | Stash list is empty |
| `CONFLICT when applying stash` | Resolve conflicts → `git stash drop` the applied stash |

## COMMON GH CLI ERRORS

| Error | Fix |
|-------|-----|
| `could not determine current user` | `gh auth login` |
| `HTTP 401: Bad credentials` | `gh auth refresh` or `gh auth login` |
| `No commits between X and Y` | Ensure branch has new commits vs base |
| `pull request already exists` | `gh pr view` to see existing PR |
| `Pull request is not mergeable` | Resolve conflicts or fix failing CI |
| `could not determine base repo` | `cd` into repo or `git remote add origin <url>` |

## DIAGNOSIS WORKFLOW

```
Step 1: Capture the error
  <command> 2>&1

Step 2: Check state
  git status
  git branch --show-current
  git remote -v

Step 3: Explain to user
  ## Error: [short description]
  **What happened:** [plain language]
  **Why:** [root cause]
  **How to fix:** [step-by-step]

Step 4: Execute fix (with user approval for destructive ops)
```

## RECOVERY FROM BAD STATE

```bash
# Stuck in rebase
git rebase --abort       # go back to before rebase
git rebase --continue    # after resolving conflicts

# Stuck in merge
git merge --abort

# Stuck in cherry-pick
git cherry-pick --abort

# Detached HEAD
git checkout main        # go back to branch
git checkout -b recovery-branch  # or create branch here if you made commits

# Nuclear option
git reflog
git reset --hard HEAD@{N}  # find last known good state
```
