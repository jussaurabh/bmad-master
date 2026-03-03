---
skill: diagnostic-workflow
category: debugging
type: workflow
description: "Structured hypothesis-driven diagnosis process to find root causes efficiently"
---

# Skill: Systematic Diagnostic Workflow

## PURPOSE
Guide structured, hypothesis-driven diagnosis to find root causes efficiently.

## THE DIAGNOSTIC LOOP

```
1. OBSERVE     -> What are the exact symptoms?
2. HYPOTHESIZE -> What are the 3 most likely causes?
3. TEST        -> Read code/logs to confirm or eliminate each hypothesis
4. NARROW      -> Update hypotheses based on evidence
5. CONFIRM     -> Verify root cause explains ALL symptoms
6. PRESCRIBE   -> Describe the fix for implementation
```

### Step 1: OBSERVE
Gather all available evidence before forming hypotheses:
- What's the exact error message or unexpected behavior?
- When did it start? (recent deployment, code change, data change?)
- Is it consistent or intermittent?
- What's expected vs actual behavior?
- Which users/environments are affected?

### Step 2: HYPOTHESIZE
Form at least 3 hypotheses, ordered by likelihood:
```
H1 (most likely): [description] -- because [reasoning]
H2: [description] -- because [reasoning]
H3 (least likely): [description] -- because [reasoning]
```
Rules: each must be testable by reading specific code or logs; cover different categories (data issue, logic error, race condition, config problem); don't anchor on the first idea.

### Step 3: TEST
For each hypothesis, identify what evidence would confirm or eliminate it:
```
To confirm H1: Read [specific file/function] and check [specific condition]
To eliminate H1: If [specific thing] is correct, H1 is ruled out
```

### Step 4: NARROW
Mark each as CONFIRMED, ELIMINATED, or NEEDS_MORE_DATA.
If all eliminated, form new hypotheses based on what you learned.

### Step 5: CONFIRM
The root cause must explain ALL symptoms:
- Does fixing this explain symptom 1? Yes/No
- Does it explain symptom 2? Yes/No
- Does it explain the timing/intermittence pattern? Yes/No
If any answer is No, keep investigating.

### Step 6: PRESCRIBE
- What file(s) to change
- What specifically to change
- Why this fixes the root cause
- What guard to add to prevent recurrence

## COMMON BUG PATTERNS

| Pattern | Look For |
|---------|----------|
| Off-by-one | Array indexing, loop boundaries, pagination offsets, date ranges |
| Null/Undefined access | Missing optional chaining, destructuring without defaults, missing API fields |
| Race conditions | Concurrent state updates, async without sequencing, stale closures |
| State mutation | Direct object/array mutation, Redux state modified outside reducers |
| Type mismatch | String vs number comparisons, date object vs string, API response shape changes |
| Timezone issues | UTC storage, timezone conversion in serialization, frontend display formatting |
