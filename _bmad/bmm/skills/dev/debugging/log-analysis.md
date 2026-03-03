---
skill: log-analysis
category: debugging
type: workflow
description: "Read and interpret error logs, stack traces, and monitoring data to identify root causes"
---

# Skill: Log and Error Analysis

## PURPOSE
Efficiently read and interpret error logs, stack traces, and monitoring data to identify root causes.

## STACK TRACE READING

### JavaScript/TypeScript
Read **top to bottom** -- the top frame is where the error was thrown:
```
Error: Cannot read property 'name' of undefined
    at UserCard (src/components/UserCard.tsx:15:23)      <- ERROR HERE
    at renderWithHooks (react-dom.development.js:...)     <- Skip (framework)
```
Focus on YOUR code frames (skip framework/library frames).

### Python
Read **bottom to top** -- the bottom frame is where the error was raised:
```
Traceback (most recent call last):
  File "main.py", line 42, in process_data         <- call chain start
  File "utils/parser.py", line 15, in parse_date   <- ERROR HERE
ValueError: time data '2024-13-01' does not match format '%Y-%m-%d'
```

### NestJS Error Responses
The real error is in server logs, not the JSON response. Look for:
- Exception class and message in server console
- Stack trace
- Request that triggered it (method, path, body)

## LOG ANALYSIS TECHNIQUES

### Keyword Scanning (in order of severity)
1. `Error`, `Exception`, `FATAL`, `CRITICAL`
2. `Warning`, `WARN`, `deprecated`
3. `timeout`, `refused`, `unreachable`, `ECONNREFUSED`
4. `null`, `undefined`, `NaN`, `Invalid`
5. `401`, `403`, `404`, `500`, `502`, `503`

### Timeline Reconstruction
1. Find the timestamp of the failure
2. Look at logs 30 seconds before and after
3. Identify what changed: new deployment? Traffic spike? External service issue?
4. Correlate across services: did the API error match a DB timeout?

### Pattern Recognition
- Same error repeating at intervals → likely a cron job or retry loop
- Errors only during peak hours → likely a resource/capacity issue
- Errors only for specific users/data → likely a data quality issue
- Errors after deployment → likely a code change regression

## COMMON ERROR PATTERNS

| Error | Likely Cause |
|-------|-------------|
| `Cannot read property X of undefined` | Missing null check, unexpected API response shape |
| `ECONNREFUSED` | Service is down or wrong port/host |
| `ETIMEOUT` | Service is slow or network issue |
| `401 Unauthorized` | Token expired or missing |
| `403 Forbidden` | User lacks permission |
| `422 Unprocessable Entity` | Validation failure on input |
| `ENOMEM` | Memory leak or insufficient resources |
| `SQLITE_BUSY` / deadlock | Concurrent database access issue |

## OUTPUT FORMAT

```
## Log Analysis: [Error/Issue]

### Error Summary
[Exact error message and where it occurs]

### Timeline
[When it started, frequency, pattern]

### Root Cause (from logs)
[What the logs tell us]

### Evidence
- Log entry at [timestamp]: [relevant log line]
- Stack trace points to: [file:line]
- Correlating event: [what happened around the same time]

### Recommended Investigation
[What to look at next in the code]
```
