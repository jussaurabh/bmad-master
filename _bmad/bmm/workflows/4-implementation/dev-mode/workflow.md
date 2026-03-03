# Developer Mode — Context Loader

**Purpose:** Load project context, manifest, and skill library for this session.

This is a **stateless context loader** — it runs once, enriches the session, then returns control to the agent menu. It does not create a persistent "mode."

---

## Execution Steps

### Step 1: Validate and load manifest.local.yaml

Load `{project-root}/_bmad/manifest.local.yaml`.

**If file is missing:**
> "No manifest found at `_bmad/manifest.local.yaml`.
>
> To get started:
> 1. Copy `_bmad/manifest.local.yaml.example` → `_bmad/manifest.local.yaml`
> 2. Ask bmad-master `[RP]` to register your first project
> 3. Then run `[DV]` again
>
> For now, continuing with general memory lane."

→ Set `{active-project}` = empty, skip to Step 4.

**If file is malformed YAML:**
> "manifest.local.yaml has a YAML syntax error. Please fix it and try again."
> Show the parse error and approximate line number.

→ Abort and return to agent menu.

**If file loads successfully:** continue to Step 2.

---

### Step 2: Load own skills from manifest.yaml

Load `{project-root}/_bmad/manifest.yaml`.

Find the entry where `id: dev` and load its `skills[]` list.

Store available skills grouped by category:
- `git/` skills
- `debugging/` skills
- `infrastructure/` skills
- `code/` skills
- `docs/` skills

---

### Step 3: Project selection

Read `projects[]` from `manifest.local.yaml`.

**If no projects registered:**
> "No projects registered yet. Ask bmad-master `[RP]` to register a project."
→ Skip to Step 4 with general lane.

**If projects exist**, present numbered list:

```
What project are we working on?

1. <project-name> — <summary>
2. <project-name> — <summary>
...
G. Use general lane (no project)
```

Wait for user selection.

On selection:
- Store `{active-project}` = selected `projects[].name`
- Note the project's `repo_path` and `stack` for context

---

### Step 4: Load project memory

Execute memory-read logic for the resolved lane:

- If `{active-project}` set: load `~/.local_memory/dev/{active-project}/SUMMARY.md` + today's journal
- If no project: load `~/.local_memory/dev/general/general/SUMMARY.md` + today's journal

Auto-create folder if it doesn't exist (first use for this project).

Update `{active-memory-lane}` and `{memory-status}` session variables.

---

### Step 5: Surface available skills

Display skills grouped by category. Filter by project stack where possible — if project stack includes `nestjs`, highlight backend-relevant skills.

```
Available skills for this session:

📁 git (13 skills)
  smart-commits, branch-management, pull-requests, rebase-and-merge,
  stash-and-undo, history-and-inspection, error-diagnosis, gh-workflows,
  conflict-analysis, conflict-pattern-recognition, semantic-merge,
  dependency-chain-resolution, post-merge-verification

🐛 debugging (3 skills)
  diagnostic-workflow, log-analysis, cross-service-tracing

🏗️ infrastructure (3 skills)
  docker-patterns, ci-cd-patterns, deployment-patterns

💻 code (2 skills)
  code-quality, testing-patterns

📄 docs (2 skills)
  api-contract-format, type-sync-patterns

To use a skill: tell me what you need and I'll load the relevant skill file.
```

---

### Step 6: Display session summary and return

```
✅ Developer Mode loaded

Project:  <project-name or "general lane">
Stack:    <stack list or "—">
Repo:     <repo_path or "—">
Memory:   <memory-status>
Tasks:    <task-status>
Skills:   23 available across 5 categories
```

Return to agent menu. The session is now enriched with project context and skill awareness.

---

### Step 7: Surface pending tasks

Run task-read logic for the resolved project lane:

```bash
local-tasks.sh fetch --agent dev --project {active-project} --status pending
local-tasks.sh inbox --agent dev --project {active-project}
```

If `{active-project}` is not set, skip silently.

Auto-create `~/.local_tasks/dev/{active-project}/` if it doesn't exist (first-run, not an error).

Run prune pass silently:
```bash
local-tasks.sh prune --agent dev --project {active-project}
```

Update `{task-status}` session variable (examples):
- `"3 pending (1 high), 2 inbox — [TI] to review"`
- `"none pending"`
- `"5 pending (2 high)"`
- `"1 inbox — [TI] to review"`

The `{task-status}` line is already shown in the Step 6 session summary block above.

---

## Notes

- Agent **reads** project files at their registered `repo_path` — BMAD always runs from `{project-root}`, not from project directories
- Skills are loaded inline when needed — invoke by telling the agent what you need
- For parallel multi-agent work, use bmad-master as the orchestrator
- To switch projects or lanes mid-session, use `[SL] Switch Lane`
