---
skill: code-quality
category: code
type: checklist
description: "Ensure clean, maintainable, production-quality code across all stacks"
---

# Skill: Code Quality Standards

## PURPOSE
Ensure clean, maintainable, production-quality code across all stacks.

## UNIVERSAL PRINCIPLES

### Naming
- Names should reveal intent: `getUserActiveSubscriptions()` not `getData()`
- Booleans read as questions: `isActive`, `hasPermission`, `canEdit`
- Functions describe actions: `calculateTotal`, `validateInput`, `fetchUserProfile`
- No abbreviations unless universally understood (`id`, `url`, `api` are fine; `usr`, `mgr`, `btn` are not)

### Functions
- Single responsibility: one function does one thing
- Keep them short: over 30 lines probably does too much
- Early returns for guard clauses (reduce nesting)
- Maximum 3-4 parameters; use options object for more

### Error Handling
- Never swallow errors silently (`catch (e) {}` is forbidden)
- Throw specific errors with meaningful messages
- Handle expected errors (validation, not found, auth) explicitly
- Let unexpected errors bubble up to global handlers
- Always log errors with context (what operation, what input)

### Comments
- Code should be self-documenting through good naming
- Comment the "why", not the "what": `// Retry because external API has intermittent 503s`
- Don't leave commented-out code -- use git history
- TODO comments: `// TODO(saurabh): remove after migration to v2 API`
- Never remove existing comments or console.logs placed by the user

## PATTERNS TO FOLLOW

### Guard Clauses (Early Return)
```typescript
function processOrder(order: Order): Result {
  if (!order) throw new BadRequestError('Order is required');
  if (order.status === 'cancelled') return { skipped: true };
  if (!order.items.length) throw new BadRequestError('Order has no items');

  // Main logic at low nesting level
  const total = calculateTotal(order.items);
  return { total, processed: true };
}
```

### Const by Default
- Use `const` unless you need to reassign
- Use `readonly` for class properties that shouldn't change

### Destructuring for Clarity
```typescript
const { name, email, role } = user;
const { data: users, isLoading: isUsersLoading } = useGetUsersQuery();
```

### No Magic Numbers/Strings
```typescript
// Bad
if (retryCount > 3) { ... }

// Good
const MAX_RETRY_ATTEMPTS = 3;
if (retryCount > MAX_RETRY_ATTEMPTS) { ... }
```

## CODE SMELLS TO WATCH FOR

- **Long parameter lists**: Use an options/config object
- **Nested callbacks/promises**: Refactor to async/await
- **Repeated conditionals**: Extract to a function
- **Type casting everywhere**: Fix the types at the source
- **God objects/files**: Split by responsibility
- **Copy-paste code**: Extract shared logic into utilities

## BEFORE SUBMITTING CODE

- [ ] No `any` types (TypeScript) or missing type hints (Python)
- [ ] Error cases handled explicitly
- [ ] No hardcoded values that should be constants or config
- [ ] Naming is clear and consistent with the codebase
- [ ] No debug code left behind (unless it's the user's)
- [ ] Imports are clean (no unused imports)
