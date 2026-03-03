---
skill: cross-service-tracing
category: debugging
type: workflow
description: "Trace bugs spanning multiple services from frontend through API to data layer"
---

# Skill: Cross-Service Bug Tracing

## PURPOSE
Trace bugs that span multiple services (frontend → API → database/external services).

## TRACING STRATEGY

### Identify the Boundary First
- **Frontend shows wrong data** → Is API returning wrong data, or is frontend mishandling correct data?
- **API returns an error** → Is it in the API logic, or from a downstream service/database?
- **Feature works in dev but not prod** → Configuration, data, or environment difference?

### Trace from Symptom to Source
```
1. Start at the SYMPTOM (where the user sees the problem)
2. Check the data at that point (component state, API response)
3. Move ONE layer back (API call, service method, DB query)
4. Check the data at that point
5. Repeat until you find where CORRECT data becomes INCORRECT
6. That boundary is where the bug lives
```

## CROSS-SERVICE TRACE TEMPLATE

```
## Trace: [Bug Description]

### Layer 1: Frontend
- Component: [path]
- Data received: [what the component has]
- Expected: [what it should have]
- Verdict: [correct/incorrect at this layer]

### Layer 2: API Client
- Service call: [path, method]
- Request sent: [params, body]
- Response received: [data shape and content]
- Verdict: [correct/incorrect at this layer]

### Layer 3: Backend Controller
- Endpoint: [route]
- Request received: [what controller gets]
- Response sent: [what controller returns]
- Verdict: [correct/incorrect at this layer]

### Layer 4: Backend Service
- Method: [service method]
- Input/Output: [what it receives/returns]
- Business logic: [transformation applied]
- Verdict: [correct/incorrect at this layer]

### Layer 5: Database/External
- Query/Call: [what was executed]
- Result: [what was returned]
- Verdict: [correct/incorrect at this layer]

### Bug Location
Data becomes incorrect between Layer [X] and Layer [Y].
Root cause: [specific code that transforms data incorrectly]
```

## COMMON CROSS-SERVICE ISSUES

| Issue | Check |
|-------|-------|
| API contract mismatch | DTO/response serialization, case transformation middleware (`userName` vs `user_name`) |
| Stale cache | Cache invalidation, ETag/Last-Modified headers, Redux cache TTL |
| Auth token issues | Token refresh flow, interceptor handling, race conditions in refresh |
| Pagination discrepancy | Offset calculation, 0-indexed vs 1-indexed, sort order consistency |
| Timezone issues | UTC storage, timezone conversion in serialization, frontend display formatting |
