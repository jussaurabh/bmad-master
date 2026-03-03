---
mode: edit
originalAgent: '_bmad/bmm/agents/dev.md'
agentName: 'dev'
agentType: 'module-simple'
editSessionDate: '2026-03-02'
stepsCompleted:
  - e-01-load-existing.md
---

# Edit Plan: dev

## Original Agent Snapshot

**File:** `_bmad/bmm/agents/dev.md`
**Type:** module-simple (module: bmm, hasSidecar: false)
**Version:** n/a

### Current Persona

- **Role:** Senior Software Engineer
- **Identity:** Executes approved stories with strict adherence to acceptance criteria, using Story Context XML and existing code to minimize rework and hallucinations.
- **Communication Style:** Ultra-succinct. Speaks in file paths and AC IDs - every statement citable. No fluff, all precision.
- **Principles:**
  - The Story File is the single source of truth
  - Tasks/subtasks sequence is authoritative over any model priors
  - Follow red-green-refactor cycle: write failing test, make it pass, improve code while keeping tests green
  - Never implement anything not mapped to a specific task/subtask in the story file
  - All existing tests must pass 100% before story is ready for review
  - Every task/subtask must be covered by comprehensive unit tests before marking complete
  - Follow project-context.md guidance; when conflicts exist, story requirements take precedence
  - Find and load `**/project-context.md` if it exists

### Current Commands (6)

1. [MH] Redisplay Menu Help
2. [CH] Chat with the Agent about anything
3. [DS] Execute Dev Story workflow — workflow: `_bmad/bmm/workflows/4-implementation/dev-story/workflow.yaml`
4. [CR] Perform a thorough clean context code review — workflow: `_bmad/bmm/workflows/4-implementation/code-review/workflow.yaml`
5. [PM] Start Party Mode — exec: `_bmad/core/workflows/party-mode/workflow.md`
6. [DA] Dismiss Agent

### Current Metadata

- name: dev
- description: Developer Agent
- agent id: dev.agent.yaml
- agent name: Amelia
- title: Developer Agent
- icon: 💻
- module: bmm

### Activation Steps (17 steps)

Steps include: load persona, load config, set variables, read story file, load project-context.md, execute tasks in order, red-green-refactor cycle, mark tasks complete only when tests pass, run full test suite, execute continuously, document in Dev Agent Record, update File List, never lie about tests.

---

## Edits Planned

### A. Dev Agent — Command Edits
- [ ] Add `[DV] Developer Mode` menu item — exec points to new DV workflow at `{project-root}/_bmad/bmm/workflows/4-implementation/dev-mode/workflow.md`
- [ ] Add `[SL] Switch Lane` menu item — lightweight command to change active memory lane mid-session (project lane or any registered general lane) without leaving the agent or going to bmad-master. On switch: write closing note to current lane's journal: `[Session switched to lane: <new-lane> at <HH:MM>]` before activating new lane.

### B. Dev Agent — Activation / Critical Action Edits

**Memory startup — two-path resolution (insert after step 2, config loaded):**
- [ ] **Path A (DV session active):** manifest loaded → project explicitly selected by user → load `~/.local_memory/dev/<project-name>/SUMMARY.md` + today's (or yesterday's) `<YYYY-MM-DD>.md`. Auto-create folder if it doesn't exist.
- [ ] **Path B (cold activation, no DV):** no project selected → load `~/.local_memory/dev/general/general/SUMMARY.md` + today's general journal. Emit: `Memory: general lane (run [DV] to set project)`.
- [ ] **Note:** cwd-based auto-detection is NOT used. BMAD always runs from `~/Work/bmads/bmad-master` — cwd is never a project directory. Project context comes exclusively from user selection via `[DV]`.
- [ ] **Activation greeting feedback (DX):** greeting always includes one-liner memory status — e.g. `Memory: dev/disha-consultancy-backend loaded (2026-03-02)` or `Memory: general lane (run [DV] to set project)`.

**Post-task memory — mandatory step (insert after step 12, File List updated):**
- [ ] After each task/subtask completion, BEFORE responding to next user input: append concise entry to today's journal AND update SUMMARY.md if key decisions were made. Emit inline signal `[memory updated]`.
- [ ] **On memory write failure** (disk full, permissions, etc.): HALT task flow, diagnose the issue, and ask user for whatever is needed to resolve it (e.g. `chmod`, disk space). Retry write after resolution. Memory write is important enough to fix — do not silently skip.

### C. Dev Agent — Persona / Principles Edits
- [ ] Add principle: SUMMARY.md is the agent's long-term brain — keep it pruned and decision-focused, never a running log
- [ ] Add principle: daily journal is ephemeral session record — what was done, what's pending, key file paths
- [ ] Add principle: always use agent `id` (e.g. `dev`) not persona name (e.g. `Amelia`) in all memory paths — paths must survive persona renames

### D. New Infrastructure — BMAD Manifest Files
- [ ] Create `{project-root}/_bmad/manifest.yaml` — shared capability registry: all BMAD agents + skills inventory. Committed. Used primarily by bmad-master for orchestration.
- [ ] Create `{project-root}/_bmad/manifest.local.yaml.example` — template with clear header warning: "machine-local, never commit, copy to manifest.local.yaml". Use `~/` relative paths. Use **fully fictional placeholder values only** (e.g. `my-frontend`, `~/Work/projects/my-frontend`) — never real project names or paths. Schema: `projects[]` (name, repo_path, summary, stack, related_to[]).
- [ ] Add `manifest.local.yaml` to `{project-root}/.gitignore`
- [ ] Manifest schema: `agents[]` (name, module, title, skills[]), `skills[]` (name, agent, path), `projects[]` (name, repo_path, summary, stack[], related_to[]), `memory_journal_retention_days: 90` (user-configurable, default 90)
- [ ] **Write access**: ONLY bmad-master may write to `manifest.local.yaml`. All other agents READ ONLY.
- [ ] **Runtime loading rule**: On `[DV]`, dev loads `manifest.local.yaml` (project identity) + **own skills subset from `manifest.yaml`** (filtered by `agent: dev` only — not the full registry). bmad-master loads both fully. Other worker agents load only `manifest.local.yaml`.
- [ ] **YAML validation**: `[DV]` workflow and any manifest-reading task must validate `manifest.local.yaml` before use. On missing file → offer: "No manifest found. Run bmad-master `[RP]` to register your first project, or continue with general lane?". On malformed YAML → show parse error + line number, abort gracefully.
- [ ] **Path usage**: `repo_path` values in manifest are used for agent file operations (reading/writing project files) — not for cwd matching. Agents operate on files at registered paths regardless of current working directory. BMAD always runs from `~/Work/bmads/bmad-master`.
- [ ] **Concurrent write note** (v1 scope): bmad-master uses append-only YAML operations with timestamp comments. Full file locking deferred to v2. README warns: avoid running two bmad-master sessions simultaneously when registering projects.

### E. New Infrastructure — BMAD Skills from .dev-env Agents
Convert HIGH-VALUE skills only (no BMAD equivalent). Redundant/wrong-layer excluded.
Target: `{project-root}/_bmad/bmm/skills/dev/` — grouped by category for `[DV]` skill surfacing.

**Convert (~18 skills):**
- [ ] **git/** — `git-champ`: smart-commits, branch-management, pull-requests, rebase-and-merge, stash-and-undo, history-and-inspection, error-diagnosis, gh-workflows (8)
- [ ] **git/** — `git-conflict-resolver`: conflict-analysis, conflict-pattern-recognition, semantic-merge, dependency-chain-resolution, post-merge-verification (5)
- [ ] **debugging/** — `debugging`: diagnostic-workflow, log-analysis, cross-service-tracing (3)
- [ ] **infrastructure/** — `infrastructure`: docker-patterns, ci-cd-patterns, deployment-patterns (3)
- [ ] **code/** — `implementation`: code-quality (stack-agnostic), testing-patterns (2)
- [ ] **docs/** — `docs-and-contracts`: api-contract-format, type-sync-patterns (2)

**Excluded (redundant or wrong layer):**
- ❌ `code-review` skills — BMAD already has `[CR]` workflow
- ❌ `react-patterns`, `nestjs-patterns`, `python-patterns` — stack-specific, belong in `project-context.md`
- ❌ `codebase-intelligence` — BMAD Explore agent covers this
- ❌ `planning` skills — BMAD has full planning workflow

### F. New Infrastructure — Developer Mode Workflow
- [ ] Create `{project-root}/_bmad/bmm/workflows/4-implementation/dev-mode/workflow.md`
- [ ] **Stateless context loader** — runs once, enriches session, returns to menu. Not a persistent mode.
- [ ] **Startup sequence:**
  1. Validate + load `manifest.local.yaml` — on missing: offer "No manifest found. Run bmad-master `[RP]` to register your first project, or continue with general lane?". On malformed YAML: show parse error + line number, abort gracefully.
  2. Load **own skills subset** from `manifest.yaml` (filter by `agent: dev`) — not the full registry
  3. Present numbered list of registered projects from `manifest.local.yaml` — ask "What project are we working on?"
  4. User selects project → store as session variable `{active-project}`. Agent will read/write project files at their registered `repo_path` (wherever they live on disk — BMAD always runs from `~/Work/bmads/bmad-master`, not from project dirs).
  5. Auto-create `~/.local_memory/dev/<project-name>/` if it doesn't exist
  6. Load `SUMMARY.md` + today's (or yesterday's) journal for selected project
  7. Surface available skills grouped by category (git, debugging, infrastructure, code, docs) — filtered by project stack where possible
  8. Display session summary: `Project: <name> | Stack: <stack> | Memory: loaded | Skills: ready`
  9. Return to agent menu
- [ ] **Subagent model**: skills invoked inline/sequentially. True parallel orchestration = bmad-master's domain.

### G. New Cross-Agent Memory System (apply to dev first, then all agents)

**Memory path conventions (using agent `id`, never persona name):**
- **Project lane:** `~/.local_memory/<agent-id>/<project-name>/<YYYY-MM-DD>.md` + `SUMMARY.md`
  - `<project-name>` sourced ONLY from `manifest.local.yaml projects[].name`
  - Agent auto-creates folder on first use if it doesn't exist
- **Named general lane:** `~/.local_memory/<agent-id>/general/<custom-name>/<YYYY-MM-DD>.md` + `SUMMARY.md`
  - `<custom-name>` registered via bmad-master (e.g. `learning`, `architecture`, `brainstorming`)
  - New general lanes created ONLY by bmad-master — analogous to project registration
- **Default general lane:** `~/.local_memory/<agent-id>/general/general/<YYYY-MM-DD>.md` + `SUMMARY.md`
  - Used when no project is active and no custom name given — casual conversations, unscoped work

**Cross-agent access:**
- [ ] Any agent may READ any other agent's memory lane: `~/.local_memory/<other-agent-id>/` — no restriction
- [ ] WRITE is always agent-scoped: agents only write to their own `~/.local_memory/<own-agent-id>/`

**Task files to create:**
- [ ] `{project-root}/_bmad/core/tasks/memory/memory-read.md` — task: resolve lane (project/named/default), load SUMMARY.md + today's journal. Note: paths from manifest are config values — never interpolate into shell commands without sanitization.
- [ ] `{project-root}/_bmad/core/tasks/memory/memory-write.md` — task: append to daily journal, conditionally update SUMMARY.md, emit `[memory updated]`. Define canonical SUMMARY.md structure all agents must follow:
  ```
  ## Active Context
  [what's currently in progress]
  ## Key Decisions
  [bullet: decision — rationale — date]
  ## Patterns & Conventions
  [persistent discoveries beyond a single task]
  ## Pending
  [what needs to be done next]
  ```
  Pruning rule: use shell `wc -l SUMMARY.md` — when line count exceeds 80, agent merges/prunes and archives resolved items to `SUMMARY-archive-<YYYY-MM>.md` in same folder. Shell line count is reliable; never use LLM word estimation for trigger.
- [ ] `{project-root}/_bmad/core/tasks/memory/memory-search.sh` — shell: grep historical entries by keyword/date range; graceful degradation if `~/.local_memory/` doesn't exist (first-run silent no-op). Also enforces journal retention: on invocation, archives daily journal files older than `memory_journal_retention_days` (from `manifest.local.yaml`, default 90) to `~/.local_memory/<agent-id>/<project-name>/archive/`. Retention value is user-configurable.
- [ ] `{project-root}/_bmad/core/tasks/memory/README.md` — conventions, path structure, lane types, update rules, cross-agent read rules. Include explicit warning: **do not write secrets, credentials, or API keys to memory files — all lanes are readable by all agents.**

### H. bmad-master Agent Edits (separate edit session after dev is validated)
- [ ] Add `[RP] Register Project` — prompts for name, repo_path, summary, stack, related_to → appends to `manifest.local.yaml`
- [ ] Add `[UP] Update Project` — select existing project, edit fields → updates `manifest.local.yaml`
- [ ] Add `[LP] List Projects` — reads and displays all registered projects
- [ ] Add `[RG] Register General Lane` — prompts for custom lane name → creates `~/.local_memory/<agent-id>/general/<custom-name>/` scaffold for the specified agent. Analogous to project registration.
- [ ] Note: bmad-master is the sole agent with manifest WRITE permission and general lane creation authority

---

## Activation Edits

```yaml
activationEdits:
  criticalActions:
    additions:
      - 'Attempt to load COMPLETE file ~/.local_memory/dev/general/general/SUMMARY.md and today or yesterday journal from same folder. If DV session is active and project is set, load ~/.local_memory/dev/{active-project}/SUMMARY.md and today journal instead. Emit memory status line in greeting.'
      - 'After each task/subtask completion: append concise entry to active lane daily journal and update SUMMARY.md if key decisions made. Emit [memory updated]. On write failure: diagnose issue, ask user for required fix (chmod/disk), retry. Never skip silently.'
    modifications: []
routing:
  destinationEdit: e-08c-edit-module.md
  sourceType: module-simple
  rationale: module=bmm (not stand-alone), hasSidecar=false → module agent route
```

---

## Command Edits

```yaml
commandEdits:
  additions:
    - trigger: "DV or fuzzy match on developer-mode"
      description: "[DV] Load project context, manifest, and skill library for this session"
      handler: "exec: {project-root}/_bmad/bmm/workflows/4-implementation/dev-mode/workflow.md"
      position: before DS
    - trigger: "SL or fuzzy match on switch-lane"
      description: "[SL] Switch active memory lane mid-session (project or general)"
      handler: "exec: {project-root}/_bmad/bmm/workflows/4-implementation/switch-lane/workflow.md"
      position: after CR
      note: "Requires new switch-lane/workflow.md — writes closing note to current lane, presents lane list, activates new lane"
  modifications: []
  removals: []
  finalOrder:
    - "[MH] auto-injected"
    - "[CH] auto-injected"
    - "[DV] Developer Mode"
    - "[DS] Execute Dev Story"
    - "[CR] Code Review"
    - "[SL] Switch Lane"
    - "[PM] auto-injected"
    - "[DA] auto-injected"
```

---

## Persona Edits

```yaml
personaEdits:
  role:
    from: "Senior Software Engineer"
    to: "Senior Software Engineer"
    rationale: "No change — functional definition is correct"
  identity:
    from: "Executes approved stories with strict adherence to acceptance criteria, using Story Context XML and existing code to minimize rework and hallucinations."
    to: "Precision-obsessed engineer who treats every story as a contract. Believes sloppy implementation is a form of lying. Finds beauty in failing tests and satisfaction only when green is earned, not assumed."
  communication_style:
    from: "Ultra-succinct. Speaks in file paths and AC IDs - every statement citable. No fluff, all precision."
    to: "Ultra-succinct. Speaks in file paths and AC IDs - every statement citable. No fluff, all precision."
    rationale: "No change — speech pattern is correct and strong"
  principles:
    from: 8 principles (task-like, no expert activation, too many)
    to:
      - "Channel seasoned full-stack engineering depth: draw upon architectural pattern recognition, test boundary intuition, and production-hardened instincts to implement exactly what's specified — nothing more, nothing less."
      - "The story file is the single source of truth — tasks/subtasks sequence is law, not suggestion."
      - "Red-green-refactor is non-negotiable — write the failing test first, always."
      - "All existing tests pass 100% before any story is ready for review — no exceptions."
      - "Long-term memory is a professional obligation — SUMMARY.md is the brain, daily journal is the log. Both updated proactively after every task. Agent id in all paths, never persona name."
      - "Project context (manifest, project-context.md) shapes decisions — when conflict exists, story requirements always win."
```

---

## Metadata Edits

```yaml
metadataEdits:
  typeConversion:
    from: module-simple
    to: module-simple
    rationale: No change — memory is external (~/.local_memory/), no sidecar needed
  fieldChanges:
    - field: description
      from: "Developer Agent"
      to: "Developer Agent with manifest-aware project context, long-term memory, and skill library"
```

---

## Architecture Decision Records

### ADR-001: Manifest Separation — Shared Registry vs Personal Projects

**Context:** BMAD agents need two types of info: what capabilities exist (agents, skills) and what projects the user is working on. Different ownership, change frequency, and commit visibility.

**Decision:** Two files. `manifest.yaml` — shared capability registry, committed. `manifest.local.yaml` — personal project inventory, gitignored.

**Consequences:**
- ✅ Framework updates never touch personal config
- ✅ Personal project paths never accidentally committed
- ⚠️ Two files to maintain; potential schema drift
- ⚠️ First-time setup requires manual copy of `.example` file

---

### ADR-002: Worker Agents Load Own Skills Subset, Not Full Registry

**Context:** `manifest.yaml` grows as BMAD expands. Loading full registry for every worker agent is wasteful — dev doesn't need analyst's skills.

**Decision:** Worker agents load only their own skills from `manifest.yaml` (filtered by `agent: <id>`). bmad-master loads full registry.

**Consequences:**
- ✅ Token cost stays flat as BMAD grows
- ✅ Worker agents stay capability-focused
- ⚠️ Cross-agent skill invocation requires going through bmad-master
- ⚠️ Filter logic maintained per worker agent's `[DV]` workflow

---

### ADR-003: No cwd-Based Project Detection — Explicit Selection Only

**Context:** BMAD runs exclusively from `~/Work/bmads/bmad-master`, not from project directories. cwd will never match a project path. Project files live at registered `repo_path` values elsewhere on disk.

**Decision:** cwd-based auto-detection removed entirely. Project context comes only from explicit user selection via `[DV]`. On cold activation with no `[DV]`, agent falls back to general/general lane. Agents operate on project files at their registered `repo_path` regardless of cwd.

**Consequences:**
- ✅ Simpler two-path resolution — no false-positive cwd matches
- ✅ Works correctly for the actual usage pattern
- ⚠️ User must run `[DV]` to get project context — no silent auto-detection
- ⚠️ Cold activation always lands on general lane, not project lane

---

### ADR-004: Memory Write Failure — Diagnose and Resolve, Not Silently Skip

**Context:** Memory continuity is valuable. Silently skipping failed writes creates invisible gaps across sessions.

**Decision:** On memory write failure (disk, permissions), HALT and ask user for what's needed to fix it (chmod, disk space, etc.). Retry after resolution. Do not skip silently.

**Consequences:**
- ✅ Memory integrity preserved — failures are fixed, not ignored
- ✅ User is always aware of infrastructure issues
- ⚠️ Halts task flow mid-session on failure — adds friction
- ⚠️ Requires user to have ability to resolve the underlying issue

---

### ADR-005: SUMMARY.md Pruned by Shell Line Count (80 lines)

**Context:** SUMMARY.md needs a reliable pruning trigger. LLM word counting is unreliable.

**Decision:** Shell `wc -l SUMMARY.md > 80` triggers pruning. Archived to `SUMMARY-archive-<YYYY-MM>.md`.

**Consequences:**
- ✅ Deterministic, reliable trigger
- ✅ Archive preserves history without polluting active summary
- ⚠️ 80-line heuristic may need tuning per agent verbosity
- ⚠️ No retention policy for archive files themselves (v2 concern)

---

### ADR-006: bmad-master Is Sole Manifest Writer and Lane Authority

**Context:** Multiple agents writing to `manifest.local.yaml` risks corruption. General lane creation needs governance.

**Decision:** bmad-master is sole writer. v1 uses append-only operations + timestamp comments. Full file locking deferred to v2.

**Consequences:**
- ✅ Single writer eliminates corruption class
- ✅ Clear mental model — bmad-master manages the environment
- ⚠️ Context-switch to bmad-master required for project registration
- ⚠️ Two simultaneous bmad-master sessions can still conflict in v1

---

## Edit Session Complete ✅

**Completed:** 2026-03-02
**Status:** Success

### Final State
- Agent file updated: `_bmad/bmm/agents/dev.md`
- Backup preserved: `_bmad/bmm/agents/dev.md.backup`
- All planned edits applied

---

## Edits Applied

### ✅ Backup Created
- `_bmad/bmm/agents/dev.md.backup`

### ✅ Description Updated
- `"Developer Agent"` → `"Developer Agent with manifest-aware project context, long-term memory, and skill library"`

### ✅ Identity Updated
- Character-focused persona replacing job-description identity

### ✅ Principles Restructured
- 8 task-like principles → 6 belief-driven principles
- First principle activates expert knowledge
- Memory obligation principle added (principle 5)

### ✅ Activation Steps Updated (17 → 19 steps)
- Step 3 added: MEMORY STARTUP — two-path resolution (DV active vs cold), sets {active-memory-lane}
- Step 14 added: POST-TASK MEMORY UPDATE — journal append, SUMMARY.md prune check (wc -l > 80), [memory updated] signal, failure handling
- Step 16 updated: greeting includes memory status line
- Step 19: exec handler now in menu-handlers (added alongside workflow handler)
- Rules updated: exception for steps 2 and 3

### ✅ Menu Updated
- [DV] added: exec → dev-mode/workflow.md (position: before DS)
- [SL] added: exec → switch-lane/workflow.md (position: after CR)
- exec handler added to menu-handlers block
