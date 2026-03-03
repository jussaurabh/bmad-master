---
skill: dependency-chain-resolution
category: git
type: workflow
description: "Trace how conflicts in one file affect other conflicts to prevent broken resolution chains"
---

# Skill: Dependency Chain Resolution

## PURPOSE
Trace how conflicts in one file affect other conflicts, ensuring that resolving conflict A doesn't create a broken state in conflict B.

## WHY THIS MATTERS

Conflicts don't exist in isolation:
```
types.ts (conflict in interface)
    └──> service.ts (conflict uses that interface)
            └──> controller.ts (conflict calls the service)
                    └──> component.tsx (conflict consumes the API)
```

Resolving `types.ts` first (adding a new field) means `service.ts` must account for that field. Resolving them independently can produce code that compiles but has missing data flow.

## DEPENDENCY MAPPING PROCESS

### Step 1: List All Conflicted Files
```bash
git diff --name-only --diff-filter=U
```

### Step 2: Identify Dependencies Between Conflicted Files
For each conflicted file, check:
- Does it import from another conflicted file?
- Does it export something consumed by another conflicted file?
- Do they share types, interfaces, or constants?

### Step 3: Build Resolution Order (Upstream First)
```
1. Type definitions / interfaces (no dependencies)
2. Shared utilities / constants
3. Services / business logic
4. Controllers / API handlers
5. Components / UI
6. Tests
7. Configuration files
8. Lockfiles (regenerate last)
```

### Step 4: Propagate Decisions
When resolving an upstream file, track decisions affecting downstream:
```
Decision Log:
- types.ts: Kept incoming's new `timezone` field on DateRange interface
  -> service.ts must handle timezone in processing logic
  -> component.tsx must pass timezone from UI
```

## COMMON DEPENDENCY CHAINS

- **Import chain**: File A's conflict adds new export → File B's conflict imports from A → resolve A first
- **Type chain**: Interface changed → multiple files use it → resolve interface first, propagate type change
- **Function signature chain**: Function signature changed → call sites in other conflicts → resolve definition first
- **Re-export chain**: Barrel/index file conflicts → files that import via barrel → resolve barrel first

## OUTPUT: RESOLUTION ORDER PLAN

```
## Conflict Resolution Order

### Phase 1: Foundation (resolve first)
- src/types/user.ts -- type definitions, no dependencies (2 conflicts)

### Phase 2: Core Logic (depends on Phase 1)
- src/services/userService.ts -- uses types from Phase 1 (3 conflicts)
  Depends on: user.ts resolution

### Phase 3: Consumers (depends on Phase 2)
- src/controllers/userController.ts -- calls service from Phase 2 (1 conflict)

### Phase 4: UI (depends on Phase 2-3)
- src/components/UserProfile.tsx -- consumes API from Phase 3 (2 conflicts)

### Phase 5: Peripheral
- src/tests/user.test.ts
- package.json -- resolve manually
- package-lock.json -- regenerate after package.json
```
