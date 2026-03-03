# Task: Memory Read

Resolve the correct memory lane and load SUMMARY.md + today's journal into session context.

Called during agent activation (step 3) and after `[DV]` sets `{active-project}`.

---

## Inputs

| Variable | Source | Description |
|---|---|---|
| `{agent-id}` | Agent metadata `id` field | Stable machine name (e.g. `dev`). Never use persona name. |
| `{active-project}` | Set by `[DV]` workflow | Project name from `manifest.local.yaml`. Empty if DV not run. |
| `{active-lane-override}` | Set by `[SL]` workflow | Named general lane if user switched lanes. Empty otherwise. |

---

## Lane Resolution Logic

Execute in order. Use first matching condition.

```
1. IF {active-project} is set:
   → lane = ~/.local_memory/{agent-id}/{active-project}/
   → type = "project"

2. ELSE IF {active-lane-override} is set:
   → lane = ~/.local_memory/{agent-id}/general/{active-lane-override}/
   → type = "named-general"

3. ELSE (default):
   → lane = ~/.local_memory/{agent-id}/general/general/
   → type = "default-general"
```

---

## Loading Steps

### Step 1: Resolve lane path (see above)

### Step 2: Auto-create folder if missing
If `~/.local_memory/{agent-id}/` or the resolved lane folder doesn't exist, create it now.
This is a first-run scenario — not an error.

### Step 3: Load SUMMARY.md
```
File: {lane}/SUMMARY.md
```
- If exists: load complete file into context
- If missing: note "No SUMMARY.md yet — will be created on first memory write"

### Step 4: Load today's journal
```
File: {lane}/{YYYY-MM-DD}.md   (today's date)
```
- If today's file exists: load it
- If not: try yesterday's date `{lane}/{YYYY-MM-DD-minus-1}.md`
- If neither exists: note "No journal entries yet for this lane"

### Step 5: Set session variables
```
{active-memory-lane} = resolved lane path (relative, e.g. "dev/disha-consultancy-backend")
{memory-status} = human-readable status for greeting
```

Examples of `{memory-status}`:
- `"Memory: dev/disha-consultancy-backend loaded (2026-03-02)"`
- `"Memory: general lane — run [DV] to set project"`
- `"Memory: dev/disha-consultancy-backend — no entries yet"`

---

## Path Safety Note

Paths sourced from `manifest.local.yaml` are configuration values. Never interpolate them directly into shell commands without sanitization. Use them only for file read/write operations via agent tools.

---

## Output

Sets session variables:
- `{active-memory-lane}` — active lane path (used by memory-write)
- `{memory-status}` — displayed in greeting

Does NOT emit any user-visible output. Memory status is shown only in the greeting line.
