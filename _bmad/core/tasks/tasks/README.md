# Local Tasks — Cross-Agent Task System

Persistent, cross-agent, cross-session action queue for BMAD agents.

The memory system captures *what happened*. This task system captures *what to do next* —
a durable action queue that survives session boundaries and can route work between agents.

---

## Folder Structure

```
~/.local_tasks/
├── <agent-id>/
│   ├── <project-name>/
│   │   ├── tasks.json       # own task queue (pending/in_progress/done/cancelled)
│   │   ├── inbox.json       # tasks from OTHER agents, awaiting confirmation
│   │   └── *.md             # optional: body files for epics, stories, specs
│   └── global/
│       ├── tasks.json
│       └── *.md
└── global/                  # cross-agent tasks not tied to any project
    ├── tasks.json
    └── *.md
```

---

## tasks.json Schema

```json
{
  "version": 1,
  "pruned_at": "YYYY-MM-DD",
  "tasks": [{
    "id": "t-YYYYMMDD-NNN",
    "title": "string",
    "status": "pending|inbox|in_progress|done|cancelled",
    "priority": "high|medium|low",
    "tags": [],
    "created_at": "ISO8601",
    "created_by": "agent-id/project",
    "body_file": "filename.md or null",
    "blocked_by": [],
    "story_ref": null,
    "done_at": null
  }]
}
```

`inbox.json` uses the same schema. Items move from `inbox.json` → `tasks.json` after the agent
runs `accept`.

---

## Shell Commands

All operations go through `local-tasks.sh`. Agent runs this at install path:
`{project-root}/_bmad/core/tasks/tasks/local-tasks.sh`

### List tasks for a project
```bash
local-tasks.sh fetch --agent dev --project my-project --status pending
local-tasks.sh fetch --agent dev --project my-project --priority high
local-tasks.sh fetch --agent dev --project my-project --tag bug
local-tasks.sh fetch --agent dev --project my-project --json   # full JSON output
```

### Check inbox (tasks from other agents)
```bash
local-tasks.sh inbox --agent dev --project my-project
```

### Add a task to self
```bash
local-tasks.sh add \
  --agent dev \
  --project my-project \
  --title "Implement rate limiting" \
  --priority high \
  --tags security,api
```

### Add a task to another agent (cross-agent → goes to their inbox)
```bash
local-tasks.sh add \
  --agent tech-writer \
  --project my-project \
  --title "Document /payments API endpoint" \
  --priority medium \
  --created-by dev/my-project
```

### Lifecycle transitions
```bash
local-tasks.sh start  --id t-20260302-001 --agent dev --project my-project
local-tasks.sh done   --id t-20260302-001 --agent dev --project my-project

# Inbox management
local-tasks.sh accept --id t-20260302-002 --agent sm  --project my-project
local-tasks.sh reject --id t-20260302-002 --agent sm  --project my-project
```

### Maintenance
```bash
local-tasks.sh prune    --agent dev --project my-project   # archive done/cancelled > 90 days
local-tasks.sh projects --agent dev                         # list all project lanes + counts
local-tasks.sh fetch    --global --status pending           # cross-agent global tasks
```

---

## Agent Integration

### DV load (`tasks-read.md`)

When a developer runs `[DV]` to load project context, the task system automatically:
1. Fetches pending tasks for the active project
2. Checks inbox for cross-agent tasks
3. Runs a silent prune pass
4. Sets `{task-status}` for display in the session summary

The session summary gains a `Tasks:` line:
```
✅ Developer Mode loaded
Project:  my-project
Memory:   dev/my-project loaded (2026-03-02)
Tasks:    3 pending (1 high), 2 inbox — [TI] to review
```

### Post-task protocol (`tasks-write.md`)

After every task completion, agents assess whether their work generates follow-up for other agents.
If yes, they call `local-tasks.sh add` for each follow-up task.

Cross-agent tasks land in the target's inbox; self-tasks go directly to tasks.json.

### Dev agent menu commands

| Cmd | Description |
|-----|-------------|
| `[TL]` | List tasks for active project |
| `[TI]` | Review inbox tasks (accept/reject) |
| `[TA]` | Add a quick task to active project |
| `[TN]` | Create task for another agent/project |
| `[TD]` | Mark a task as done |

---

## ID Format

Task IDs: `t-YYYYMMDD-NNN` where NNN is the zero-padded sequence count for that day.

Example: `t-20260302-001`, `t-20260302-002`, `t-20260302-003`

---

## Retention

Done/cancelled tasks older than `task_retention_days` (default: 90, configurable in
`manifest.local.yaml`) are archived to `tasks-archive-YYYY-MM.json` by `prune`.

The prune pass runs silently on every `[DV]` load.
