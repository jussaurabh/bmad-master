# Task: Tasks Write

Proactive task creation protocol. Fires after any task completion to surface cross-agent follow-up work.

Called after every task/subtask completes (alongside memory-write). Emits `[tasks updated ✓]` only if tasks were created.

---

## Inputs

| Variable | Source |
|---|---|
| `{active-task-lane}` | Set by tasks-read on DV activation |
| `{agent-id}` | Agent metadata `id` field |
| `{task-summary}` | What was just completed — agent constructs this |

---

## Execution Steps

### Step 1: Assess cross-agent follow-up

After completing any task, ask: **Does this work generate follow-up tasks for another agent or for self?**

Use the trigger table below as a guide. This is a judgment call — not every task generates follow-up.
Only create tasks when there is genuinely actionable work that another agent (or your future self) needs to do.

### Step 2: For each follow-up task identified

```bash
local-tasks.sh add \
  --agent <target-agent-id> \
  --project <target-project> \
  --title "<clear, actionable task title>" \
  --priority <high|medium|low> \
  --created-by {agent-id}/{active-project}
```

**Routing rules:**
- Adding to **another agent** → goes to their `inbox.json` (awaits their confirmation)
- Adding to **self** → goes directly to `tasks.json` (pending, no confirmation needed)

### Step 3: Optional — attach body file for complex tasks

For epics, stories, or tasks requiring a detailed spec:

1. Create a `.md` file in the target agent's task lane:
   `~/.local_tasks/<target-agent>/<project>/<task-id>-brief.md`
2. Re-add the task with `--body-file <path>` pointing to that file

### Step 4: Emit signal

If at least one task was created:
```
[tasks updated ✓ → <agent>/<project>: N added]
```

If zero tasks were created: **omit the emit entirely** — do not print anything.

---

## Common Triggers

Use this table as guidance for when to proactively create tasks:

| Agent completing work | Work completed | Creates task for |
|---|---|---|
| `dev` | Finishes API endpoint | `tech-writer/{project}` — document the endpoint |
| `dev` | Hits UX decision mid-impl | `ux-designer/{project}` — resolve the UX decision |
| `dev` | Identifies follow-up refactor | `dev/{project}` (self) — don't forget |
| `pm` | Creates epics/stories | `dev/{project}` — review and plan sprint |
| `architect` | Makes API contract decision | `dev/{project}` — implement to spec |
| `brainstorming-coach` | Session ends with action items | `dev/{project}` or relevant agent |
| `sm` | Creates sprint plan | `dev/{project}` — sprint kickoff ready |
| `any` | Session ends with unresolved items | self — carry forward |

---

## Failure Handling

If task write fails (permission denied, disk full, path error):

1. **Note** the failure (do not STOP session — tasks-write is advisory, not blocking)
2. **Inform** the user briefly: `"[tasks-write] Could not write task: <reason>"`
3. **Continue** — unlike memory-write, task creation failure is non-blocking

Tasks-write is best-effort. Memory-write is non-negotiable.

---

## Notes

- `{active-task-lane}` uses agent `id`, never persona name — paths survive persona renames
- Cross-agent tasks are placed in `inbox.json` and require the target agent to explicitly `accept` them
- Self-tasks go directly to `tasks.json` as `pending`
- The emit signal `[tasks updated ✓]` is distinct from `[memory updated ✓]` — both may appear in the same response
