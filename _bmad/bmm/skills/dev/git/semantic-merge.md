---
skill: semantic-merge
category: git
type: workflow
description: "Resolve conflicts by understanding semantic intent of both sides and merging logic correctly"
---

# Skill: Semantic Merge

## PURPOSE
Resolve conflicts by understanding the semantic intent of both sides and producing a merged result that preserves correct logic from each -- not blindly accepting one side.

## CORE PRINCIPLE

**A conflict is NOT a binary choice.** Often the correct resolution is a NEW version taking specific parts from each side.

```
<<<<<<< HEAD
function processOrder(order: Order) {
  validateOrder(order);
  const discount = getDiscount(order.userId);  // CURRENT added this
  const total = calculateTotal(order.items);
  return { total: total - discount, status: 'processed' };
}
=======
function processOrder(order: Order) {
  validateOrder(order);
  const total = calculateTotal(order.items);
  logOrderMetrics(order);                      // INCOMING added this
  return { total, status: 'processed' };
}
>>>>>>> feature/metrics
```

**Wrong**: Pick one side (loses either discount or metrics)
**Right**: Merge both additions:
```typescript
function processOrder(order: Order) {
  validateOrder(order);
  const discount = getDiscount(order.userId);  // from current
  const total = calculateTotal(order.items);
  logOrderMetrics(order);                       // from incoming
  return { total: total - discount, status: 'processed' };  // merged
}
```

## SEMANTIC MERGE PROCESS

### Step 1: Identify Common Ancestor
- Lines identical on both sides = unchanged from ancestor
- Lines unique to current = current branch additions/modifications
- Lines unique to incoming = incoming branch additions/modifications

### Step 2: Classify Each Line
- `[UNCHANGED]` -- same on both sides, keep as-is
- `[CURRENT-ONLY]` -- keep (unless conflicts with incoming's intent)
- `[INCOMING-ONLY]` -- keep (unless conflicts with current's intent)
- `[BOTH-MODIFIED]` -- requires judgment

### Step 3: Merge Strategy
- `[UNCHANGED]` → keep
- `[CURRENT-ONLY]` → keep
- `[INCOMING-ONLY]` → keep
- `[BOTH-MODIFIED]`:
  - Both additive and independent → keep both
  - One is refinement of the other → keep the refinement
  - Truly contradictory → **ASK THE USER**

### Step 4: Verify Coherence
Read the result as a complete unit -- does logic flow? Are variables declared before use? Are return values consistent?

## MERGE PATTERNS

- **Both added independent lines** → combine both
- **Both modified same value differently** → ASK USER which is correct
- **One restructured, other added** → keep refactor + add the new item to the new structure
- **One deleted lines, other modified them** → ASK USER

## WHEN TO ASK THE USER (NON-NEGOTIABLE)

- Two lines have different values and you can't determine which is correct
- Code was deleted on one side and modified on the other
- Business logic differs and both seem valid
- The merged result changes behavior in a way that might be unintended
- Confidence is less than high

**Format your question with full context so the user can decide quickly.**
