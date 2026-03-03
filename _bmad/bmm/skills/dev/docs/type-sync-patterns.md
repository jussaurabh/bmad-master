---
skill: type-sync-patterns
category: docs
type: patterns
description: "Maintain consistent TypeScript types and interfaces across frontend and backend repositories"
---

# Skill: Cross-Repo Type Synchronization

## PURPOSE
Maintain consistent TypeScript types and interfaces across frontend and backend repositories.

## THE SYNC PROBLEM

When frontend and backend are in separate repos, type definitions can drift:
- Backend adds a field but frontend doesn't know about it
- Frontend expects a field that backend renamed
- Enum values differ between repos
- Nullable fields handled differently

## SYNC STRATEGIES

### Strategy 1: Shared Types File (Manual Sync)
```typescript
// Backend DTO (source of truth)
export interface UserResponse {
  id: string;
  name: string;
  email: string;
  role: 'admin' | 'editor' | 'viewer';
  lastLoginAt: string | null;  // ISO 8601 or null
  createdAt: string;
}

// Frontend type (must match exactly)
export interface User {
  id: string;
  name: string;
  email: string;
  role: 'admin' | 'editor' | 'viewer';
  lastLoginAt: string | null;
  createdAt: string;
}
```

### Strategy 2: API Response Type Generation
```typescript
// Frontend: type derived from OpenAPI spec
import { paths } from './api-schema'; // generated from backend

type UserResponse = paths['/api/users/{id}']['get']['responses']['200']['content']['application/json'];
```

### Strategy 3: Shared Package
```
@company/shared-types/
├── src/
│   ├── user.types.ts
│   └── index.ts
└── package.json
```
Both repos depend on `@company/shared-types`.

## TYPE CHANGE WORKFLOW

1. **Document the change** in the API contract first
2. **Update backend** DTO/entity with the new field/type
3. **Update shared types** or frontend types to match
4. **Check all consumers** in the frontend that use this type
5. **Update API client** methods if request/response shape changed
6. **Verify** with TypeScript compiler -- type errors reveal missed updates

## COMMON SYNC ISSUES

| Issue | Solution |
|-------|----------|
| Field casing (`userName` vs `user_name`) | Serialization layer (NestJS interceptor or API client transformer) |
| Date handling (string vs Date object) | Keep as strings in types, convert in utility functions |
| Enum discrepancy | Define enums in one place, import in both |
| Optional vs nullable | Agree on convention: `null` = explicitly empty, `undefined` = not included |

## OUTPUT FORMAT

```
## Type Sync: [Change Name]

### Changed Type
[Type name and what changed]

### Backend (source of truth)
[Updated DTO with changes highlighted]

### Frontend (must update)
[Updated type with changes highlighted]

### Files to Update
- Backend: src/modules/user/dto/user-response.dto.ts
- Frontend: src/types/user.types.ts
- Frontend: src/services/userService.ts (if API call shape changed)
- Frontend: src/components/UserProfile.tsx (if consuming the changed field)
```
