---
skill: gh-workflows
category: git
type: patterns
description: "Handle GitHub workflows beyond PRs -- issues, releases, actions, and repo management via gh CLI"
---

# Skill: GitHub CLI Workflows (Issues, Releases, Actions)

## PURPOSE
Handle GitHub-specific workflows beyond PRs -- issues, releases, workflow runs, gists, and repo management using `gh` CLI.

## ISSUES

```bash
# Create issue
gh issue create \
  --title "Bug: dashboard crashes on empty dataset" \
  --body "$(cat <<'EOF'
## Description
Steps to Reproduce / Expected / Actual behavior
EOF
)" \
  --label "bug,dashboard" \
  --assignee @me

# Manage issues
gh issue list
gh issue list --assignee @me
gh issue view 456
gh issue close 456 --reason completed
gh issue comment 456 --body "Fixed in PR #789"
gh issue edit 456 --add-label "in-progress"
```

## RELEASES

```bash
# Create release
gh release create v1.2.3 \
  --title "Release 1.2.3" \
  --notes "$(cat <<'EOF'
## What's New
- Added widget config panel (#287)
- Fixed dashboard crash (#456)
EOF
)"

gh release create v1.2.3 --generate-notes    # auto-generated notes
gh release create v1.2.3 --draft --generate-notes  # draft release
gh release upload v1.2.3 ./dist/app.zip       # upload assets

# Manage releases
gh release list
gh release view v1.2.3
gh release download v1.2.3
```

## GITHUB ACTIONS / WORKFLOW RUNS

```bash
# View runs
gh run list
gh run list --workflow=ci.yml
gh run view <run-id>
gh run view <run-id> --log
gh run watch <run-id>    # live updates

# Trigger workflows
gh workflow run deploy.yml
gh workflow run deploy.yml -f environment=staging -f version=1.2.3
gh workflow list

# Re-run
gh run rerun <run-id>
gh run rerun <run-id> --failed  # re-run only failed jobs
```

## REPO MANAGEMENT

```bash
gh repo clone owner/repo
gh repo fork owner/repo --clone
gh repo create my-new-project --public --clone
gh repo view
gh repo view --web
gh repo sync owner/fork  # sync fork with upstream
```

## API ACCESS (Advanced)

```bash
gh api repos/{owner}/{repo}/pulls/123/comments
gh api repos/{owner}/{repo}/issues -f title="New issue" -f body="Description"
gh api repos/{owner}/{repo}/issues --paginate

# GraphQL
gh api graphql -f query='
  query {
    repository(owner: "owner", name: "repo") {
      pullRequests(last: 5, states: OPEN) {
        nodes { title number }
      }
    }
  }
'
```

## COMPOSITE WORKFLOWS

### Full Feature Delivery
```bash
# 1. Create issue for tracking
gh issue create --title "feat: widget config" --assignee @me --label feature
# 2. Create branch, implement, commit
# 3. Create PR linking the issue
gh pr create --title "feat(dashboard): add widget config" --body "Closes #<issue>"
# 4. After approval
gh pr merge --squash --delete-branch
# 5. Create release if needed
gh release create v1.3.0 --generate-notes
```

### Quick Hotfix Delivery
```bash
git checkout main && git pull
git checkout -b hotfix/fix-auth-bypass
# Fix, commit, push
git push -u origin HEAD
gh pr create --title "fix: critical auth bypass" --label "hotfix,urgent" --reviewer lead
gh pr merge --merge --delete-branch
git checkout main && git pull
git tag -a v1.2.4 -m "Hotfix: auth bypass"
git push --tags
```
