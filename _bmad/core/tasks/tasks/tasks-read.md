# Task: Tasks Read

Resolve the correct task lane and surface pending work into session context.

Called during `[DV]` load (NOT at cold activation). Only runs when project context is set.

---

## Inputs

| Variable | Source | Description |
|---|---|---|
| `{agent-id}` | Agent metadata `id` field | Stable machine name (e.g. `dev`). Never use persona name. |
| `{active-project}` | Set by `[DV]` workflow | Project name from `manifest.local.yaml`. Empty if DV not run. |
| `{active-lane-override}` | Set by `[SL]` workflow | Named general lane if user switched lanes. Empty otherwise. |

---

## Lane Resolution Logic

Same logic as memory-read. Execute in order. Use first matching condition.

```
1. IF {active-project} is set:
   → lane = ~/.local_tasks/{agent-id}/{active-project}/

2. ELSE IF {active-lane-override} is set:
   → lane = ~/.local_tasks/{agent-id}/general/{active-lane-override}/

3. ELSE (default):
   → lane = ~/.local_tasks/{agent-id}/global/
```

---

## Execution Steps

### Step 1: Resolve lane path (see above)

### Step 2: Auto-create folders if missing

If `~/.local_tasks/{agent-id}/` or the resolved lane folder doesn't exist, create it now.
This is a first-run scenario — not an error. Do NOT emit anything to the user about this.

### Step 3: Fetch pending tasks

```bash
local-tasks.sh fetch \
  --agent {agent-id} \
  --project {active-project} \
  --status pending
```

Capture the output. Count total pending tasks and how many are `high` priority.

### Step 4: Check inbox count

```bash
local-tasks.sh inbox \
  --agent {agent-id} \
  --project {active-project}
```

Count the number of inbox items (tasks from other agents awaiting confirmation).

### Step 5: Set session variables

```
{active-task-lane} = resolved lane path (e.g. "dev/disha-consultancy-backend")
{task-status}      = human-readable summary for session display
```

Examples of `{task-status}`:
- `"Tasks: 3 pending (1 high), 2 inbox — [TI] to review"`
- `"Tasks: none pending"`
- `"Tasks: 5 pending (2 high)"`
- `"Tasks: 1 inbox — [TI] to review"`

### Step 6: Run prune pass silently

```bash
local-tasks.sh prune \
  --agent {agent-id} \
  --project {active-project}
```

Run silently (suppress output). This handles retention cleanup of old done/cancelled tasks.

---

## Output

Sets session variables:
- `{active-task-lane}` — active lane path (used by tasks-write)
- `{task-status}` — displayed in DV session summary

Does NOT emit any user-visible output on its own. Task status is shown only in the session summary line.

---

## Path Safety Note

Paths sourced from `manifest.local.yaml` are configuration values. Never interpolate them directly
into shell commands without sanitization. Use them only for file read/write operations via agent tools.
