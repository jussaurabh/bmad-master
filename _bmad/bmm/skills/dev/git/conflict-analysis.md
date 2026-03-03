---
skill: conflict-analysis
category: git
type: workflow
description: "Parse and categorize git conflict blocks to understand their structure and complexity"
---

# Skill: Conflict Analysis

## PURPOSE
Parse and categorize git conflict blocks to understand their structure, scope, and complexity before attempting resolution.

## CONFLICT ANATOMY

```
<<<<<<< HEAD (current branch -- YOUR changes)
[Current branch code]
=======
[Incoming branch code]
>>>>>>> incoming-branch
```

- **Above `=======`**: Current branch (ours)
- **Below `=======`**: Incoming branch (theirs)

**Important:** A single file can have multiple conflict blocks. Always survey ALL blocks before resolving ANY of them -- they may be related (import in block 1, usage in block 2).

## CONFLICT CATEGORIES

### Category 1: Both-Added (Low Risk)
Both sides added new, non-overlapping content (different imports, different list entries, different functions).
**Resolution**: Keep both. Check for duplicates or ordering conflicts.

### Category 2: Parallel Edit (Medium Risk)
Both sides modified the same existing code differently.
**Resolution**: Requires understanding WHAT each side changed and WHY. Often needs semantic merge.

### Category 3: Divergent Refactor (High Risk)
One side refactored/restructured while the other modified the original code.
**Resolution**: Keep the refactor + update the other side's changes to work with the new structure.

### Category 4: Delete vs Modify (High Risk -- ASK USER)
One side deleted code that the other side modified.
**Resolution**: ALWAYS ask the user. You cannot know which intent should win.

### Category 5: Config/Lockfile (Special)
- `package-lock.json`, `yarn.lock` → delete and regenerate
- `package.json` dependencies → keep both additions, resolve version conflicts manually

## ANALYSIS OUTPUT

For each conflict block, produce:
```
File: path/to/file.ts
Block: [N] of [total] (lines X-Y)
Category: [1-5 from above]
Risk: [Low / Medium / High]
Current intent: [what the current branch was trying to do]
Incoming intent: [what the incoming branch was trying to do]
Overlap: [what specifically conflicts]
Confidence: [High / Medium / Low]
```

If confidence is Low → flag for user decision immediately.
