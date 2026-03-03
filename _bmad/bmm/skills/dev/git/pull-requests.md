---
skill: pull-requests
category: git
type: workflow
description: "Create, manage, review, and merge pull requests using the GitHub CLI"
---

# Skill: Pull Request Management (gh CLI)

## PURPOSE
Create, manage, review, and merge pull requests using the GitHub CLI (`gh`).

## CREATING PULL REQUESTS

### Pre-Flight Checks
```bash
git branch --show-current    # ensure on correct branch
git status                   # ensure all changes committed
git push -u origin HEAD      # ensure branch is pushed
gh pr status                 # check if PR already exists
```

### Create PR
```bash
gh pr create \
  --title "feat(dashboard): add widget configuration panel" \
  --body "$(cat <<'EOF'
## Summary
- Added configurable widget settings with real-time preview

## Changes
- `src/dashboard/WidgetConfig.tsx` -- new configuration component
- `src/api/widgets.ts` -- API endpoints for saving config

## Test Plan
- [ ] Unit tests for WidgetConfig component
- [ ] Manual test: change chart type and verify preview updates

Closes #287
EOF
)" \
  --base main \
  --reviewer teammate1,teammate2 \
  --label "feature,frontend"

gh pr create --draft --fill   # draft PR, auto-fill from commits
```

### PR Description Best Practices
- **Summary**: 2-3 bullet points of what changed
- **Changes**: List key files and what changed in each
- **Test Plan**: How to verify the changes work
- **Issue Reference**: Link related issues with `Closes #N`

## VIEWING & MANAGING PRS

```bash
gh pr status                 # your PR status
gh pr list                   # list open PRs
gh pr list --author @me      # your PRs
gh pr view 123               # view specific PR
gh pr view 123 --web         # open in browser
gh pr diff 123               # view PR diff
gh pr checks 123             # view PR checks

# Update PR
gh pr edit 123 --title "new title"
gh pr edit 123 --add-reviewer teammate1
gh pr ready 123              # mark draft as ready
```

## REVIEWING PRS

```bash
gh pr review 123 --approve --body "LGTM"
gh pr review 123 --request-changes --body "Please address X"
gh pr review 123 --comment --body "Question about caching approach"
```

## MERGING PRS

```bash
gh pr merge 123 --merge              # merge commit
gh pr merge 123 --squash --delete-branch  # squash (recommended for feature branches)
gh pr merge 123 --rebase             # rebase
gh pr merge 123 --auto --squash      # auto-merge when checks pass
```

## COMMON ERRORS

| Error | Fix |
|-------|-----|
| `GraphQL: No commits between X and Y` | Ensure branch has new commits vs base |
| `pull request already exists` | `gh pr view` to see existing PR |
| `permission denied` | `gh auth login` |
| `required status check failing` | Fix CI checks, push again |
| `not mergeable` | Resolve conflicts first |

## SAFETY RULES

- Never merge your own PR without review (unless solo project)
- Always check `gh pr checks` before merging
- Use `--squash` for feature branches to keep clean history
- Use `--delete-branch` to clean up after merge
