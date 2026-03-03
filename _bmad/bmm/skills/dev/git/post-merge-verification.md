---
skill: post-merge-verification
category: git
type: checklist
description: "Verify merged result is correct and won't introduce silent bugs before committing"
---

# Skill: Post-Merge Verification

## PURPOSE
After all conflicts are resolved, verify the merged result is correct and won't introduce silent bugs before the user commits.

## VERIFICATION CHECKLIST

### 1. No Remaining Conflict Markers
```bash
grep -rn "<<<<<<< " --include="*.ts" --include="*.tsx" --include="*.js" --include="*.py" .
grep -rn "=======" --include="*.ts" --include="*.tsx" --include="*.js" --include="*.py" .
grep -rn ">>>>>>> " --include="*.ts" --include="*.tsx" --include="*.js" --include="*.py" .
```
One remaining marker = incomplete resolution.

### 2. Import Consistency
- All imports reference files/modules that exist
- No duplicate imports
- No unused imports from a removed conflict side
- Named imports match actual exports from the source

### 3. Type Consistency
- All consumers of changed types still match the resolved type
- No type errors from mismatched interfaces

### 4. Logic Flow Verification
Read each resolved file as a complete unit:
- Variables declared before use
- Renamed functions called by the new name everywhere
- Return types match what callers expect
- No dead code from a partially kept conflict side

### 5. Cross-File Consistency
- API contracts (function signatures, HTTP endpoints) match between caller and callee
- Shared state (Redux, context) is consistent
- Event names and payloads match between emitter and listener

### 6. Linter / Compiler Check
```bash
npx tsc --noEmit          # TypeScript
npx eslint <resolved-files>  # ESLint
python -m py_compile <files>  # Python
```

### 7. Test Sanity (If Quick)
```bash
npm test -- --testPathPattern="<affected-module>"
pytest tests/<affected-module>/
```

## VERIFICATION OUTPUT

```
## Post-Merge Verification

### Conflict Markers    [PASS / FAIL]
### Import Consistency  [PASS / WARN] -- details
### Type Consistency    [PASS / WARN] -- details
### Logic Flow         [PASS / WARN] -- details
### Cross-File         [PASS / WARN] -- details
### Linter/Compiler    [PASS / FAIL / SKIPPED]

### Overall Verdict
[CLEAN -- ready to commit / ISSUES FOUND -- see above]
```

## COMMON POST-MERGE BUGS

- **Silent data loss**: A field was dropped -- code compiles but data is missing at runtime
- **Duplicate logic**: Both sides' code kept, causing double execution
- **Broken control flow**: if/else or try/catch partially merged, creating unreachable code
- **Stale references**: Old function/variable name survived from the other side

## WHEN VERIFICATION FAILS

1. Report the specific issue with file and line reference
2. Explain what went wrong in the merge
3. Propose a fix
4. **ASK THE USER before applying the fix** -- don't silently modify already-resolved code
