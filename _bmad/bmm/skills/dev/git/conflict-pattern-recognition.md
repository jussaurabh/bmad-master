---
skill: conflict-pattern-recognition
category: git
type: patterns
description: "Identify common conflict patterns with reliable resolution strategies for fast resolution"
---

# Skill: Conflict Pattern Recognition

## PURPOSE
Identify predictable conflict patterns with reliable resolution strategies -- resolve the easy cases fast, focus on the hard ones.

## AUTO-RESOLVABLE PATTERNS (High Confidence)

### Both Added Imports
Both sides added different imports to the same import block.
**Resolution**: Keep both imports. Check for naming conflicts.

### Both Added to a List/Array
Both sides appended different entries to routes, config arrays, etc.
**Resolution**: Keep both additions. Check for duplicates. Maintain ordering if the file uses one.

### Both Added Methods to a Class/Object
Both sides added different methods.
**Resolution**: Keep both. Verify no naming conflicts.

### Adjacent Line Edits (False Conflict)
Git flagged a conflict because changes are close together but don't actually overlap.
**Resolution**: Keep current's change + incoming's change — they're independent.

## SEMI-AUTO PATTERNS (Medium Confidence -- Verify)

### Package.json Dependency Conflicts
Both branches added different dependencies or changed versions.
**Resolution**: Keep both additions. For version conflicts, take the higher version. Regenerate lockfile.

### One Side Reformatted
One branch ran a formatter, other made logic changes.
**Resolution**: Keep the logic changes, apply formatting. Ensure logic changes aren't lost.

### Config Value Changes
Both sides changed the same config value (timeout, limit, feature flag).
**Resolution**: ASK USER -- you can't know which value is correct.

## NEVER-AUTO-RESOLVE (Always Ask User)

- **Delete vs Modify**: One side deleted code, other side modified it
- **Contradictory Logic**: Both sides changed the same business logic in different directions
- **Test conflicts with changed expectations**: User must decide which expectation is correct
- **Database Migration / Schema Conflicts**: Migration ordering matters

## LOCKFILE HANDLING (Special Rule)

**NEVER manually merge lockfiles.** Always:
1. Resolve `package.json` first
2. Delete the lockfile
3. Regenerate: `npm install` / `yarn install` / `pip freeze`
4. Stage the regenerated lockfile

## RECOGNITION CHECKLIST

For each conflict block:
- [ ] Both-added pattern? → Auto-resolve
- [ ] Adjacent-line false conflict? → Auto-resolve
- [ ] Format-only on one side? → Apply logic + format
- [ ] Parallel edit to same logic? → Semantic merge needed
- [ ] Delete vs modify? → ASK USER
- [ ] Config/value conflict? → ASK USER
- [ ] Lockfile? → Regenerate
