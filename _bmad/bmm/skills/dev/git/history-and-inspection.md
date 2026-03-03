---
skill: history-and-inspection
category: git
type: patterns
description: "Navigate git history, inspect changes, compare branches, and find information across the timeline"
---

# Skill: History, Diffs, and Inspection

## PURPOSE
Navigate git history, inspect changes, compare branches, and find information across the repository timeline.

## VIEWING HISTORY

```bash
git log --oneline -20                                        # compact log
git log --stat -10                                           # with file stats
git log --oneline --graph --all --decorate -20              # branch topology
git log --oneline -- path/to/file.ts                        # log for specific file
git log --author="saurabh" --oneline -10                    # by author
git log --after="2026-01-01" --before="2026-02-01" --oneline  # date range
git log -S "functionName" --oneline                         # commits that changed a string
git log -G "pattern" --oneline                              # commits whose diff matches regex

git show <commit-hash>                  # full commit details with diff
git show --stat <commit-hash>           # just files changed
git show <commit-hash>:path/to/file.ts  # file at specific commit
```

## DIFFS

```bash
git diff                    # unstaged changes
git diff --cached           # staged changes (ready to commit)
git diff HEAD               # all changes (staged + unstaged)
git diff -- path/to/file.ts # specific file
git diff --stat             # stats only

# Branch comparisons
git diff main..feature/widget-config         # what's in feature not in main
git diff main...feature/widget-config        # what changed since branching
git diff --name-only main..feature/widget-config  # just file names
git diff --stat main..feature/widget-config  # stat summary
```

## FINDING THINGS

### Blame (Who Changed What)
```bash
git blame path/to/file.ts          # who last modified each line
git blame -L 50,80 path/to/file.ts # specific line range
git blame -w path/to/file.ts       # ignore whitespace changes
```

### Bisect (Find Bug-Introducing Commit)
```bash
git bisect start
git bisect bad                   # mark current as bad
git bisect good <known-good>     # mark known good commit
# Test each checkout, then:
git bisect good   # or: git bisect bad
git bisect reset  # clean up when done
```

### Search Across History
```bash
git log -S "searchTerm" --oneline           # commits that added/removed string
git log -G "regex_pattern" --oneline        # commits where diff matches regex
git log --diff-filter=D --summary -- "**/filename.ts"  # when file was deleted
git log --diff-filter=A --summary -- "**/filename.ts"  # when file was added
```

## STATUS AND REMOTE STATE

```bash
git status              # full status
git status -s           # short status
git status -b -s        # with branch tracking info
git remote -v           # list remotes
git remote show origin  # remote details
git fetch --dry-run     # preview what would be fetched
```

## USEFUL COMBINATIONS

```bash
# What did I do today?
git log --author="$(git config user.name)" --after="midnight" --oneline

# What's different between my branch and main?
git log --oneline main..HEAD
git diff --stat main...HEAD

# What branches contain this commit?
git branch --contains <commit-hash>

# Show file at a previous point
git show HEAD~5:path/to/file.ts
```
