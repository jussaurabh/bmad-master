---
skill: smart-commits
category: git
type: workflow
description: "Analyze code changes to draft precise commit messages describing the why, not just the what"
---

# Skill: Smart Commit Messages

## PURPOSE
Analyze code changes and draft precise, meaningful commit messages that describe the "why" not just the "what."

## COMMIT WORKFLOW

### Step 1: Gather Change Context
```bash
git status
git diff --cached --stat
git diff --cached
git diff --stat
git log --oneline -10
```

### Step 2: Analyze Changes
Categorize what changed:
- **New files**: What feature/module do they add?
- **Modified files**: What behavior changed? Bug fix? Enhancement? Refactor?
- **Deleted files**: What was removed and why?
- **Renamed/moved files**: Restructuring? Refactoring?

### Step 3: Draft Commit Message

#### Conventional Commits Format (if repo uses it)
```
<type>(<scope>): <short description>

<optional body -- explain WHY, not WHAT>

<optional footer -- breaking changes, issue refs>
```

**Types:** `feat` | `fix` | `refactor` | `style` | `test` | `docs` | `chore` | `perf` | `ci`

**Examples:**
```
feat(auth): add JWT refresh token rotation

Implement automatic token rotation on refresh to prevent token reuse
attacks. Refresh tokens are now single-use with a 7-day sliding window.

Closes #142
```

```
fix(dashboard): prevent crash when widget data is empty

generateWidgetPayloads was accessing sectionFilters[sectionId] without
checking if builder initialized the filters object. Added null check
with empty object fallback.
```

#### Simple Format (if repo doesn't use conventional commits)
Match whatever `git log --oneline -10` shows.

### Step 4: Present for Approval
Always show:
1. Files that will be committed (staged)
2. Files that will NOT be committed (unstaged/untracked)
3. The proposed commit message
4. Ask for confirmation before executing

### Step 5: Execute
```bash
git commit -m "$(cat <<'EOF'
feat(dashboard): add widget configuration panel

Implement configurable widget settings with real-time preview.

Closes #287
EOF
)"
```

## SMART MESSAGE RULES

- **Lead with WHY**: "prevent crash when..." not "add null check to..."
- **Be specific**: "fix pagination offset for filtered results" not "fix bug"
- **One logical change per commit**: Don't bundle unrelated changes
- **50/72 rule**: Subject line ≤ 50 chars, body lines ≤ 72 chars
- **Imperative mood**: "add feature" not "added feature"
- **No period** at end of subject line
- **Reference issues** when applicable: `Closes #123`

## HANDLING MULTIPLE LOGICAL CHANGES

If changes belong to different logical units:
```
I see changes across multiple concerns:
1. Bug fix in auth module (src/auth/*)
2. New dashboard feature (src/dashboard/*)

I recommend splitting into 2 commits. Shall I:
A. Stage and commit them separately (recommended)
B. Commit everything together with a broader message
```

## FILES TO NEVER COMMIT (warn user)
- `.env`, `.env.local`, `.env.production`
- `credentials.json`, `service-account.json`
- `*.pem`, `*.key`, private keys
- `node_modules/`, `__pycache__/`, `.venv/`
- `.DS_Store`, `Thumbs.db`
