# BMAD Agent Memory System

Cross-session, cross-agent memory for BMAD agents. Agents journal their work so every session starts with context, not cold silence.

---

## Path Conventions

All memory lives under `~/.local_memory/`. Always use the agent's **id** (e.g. `dev`, `sm`, `analyst`) — never the persona name (e.g. `Amelia`). Persona names can be renamed; ids are stable.

### Project Lane
```
~/.local_memory/<agent-id>/<project-name>/SUMMARY.md
~/.local_memory/<agent-id>/<project-name>/<YYYY-MM-DD>.md
~/.local_memory/<agent-id>/<project-name>/SUMMARY-archive-<YYYY-MM>.md
~/.local_memory/<agent-id>/<project-name>/archive/<YYYY-MM-DD>.md  ← old journals
```
- `<project-name>` sourced **only** from `manifest.local.yaml projects[].name`
- Agent auto-creates folder on first use

### Named General Lane
```
~/.local_memory/<agent-id>/general/<custom-name>/SUMMARY.md
~/.local_memory/<agent-id>/general/<custom-name>/<YYYY-MM-DD>.md
```
- `<custom-name>` registered via bmad-master `[RG] Register General Lane`
- Examples: `learning`, `architecture`, `brainstorming`

### Default General Lane
```
~/.local_memory/<agent-id>/general/general/SUMMARY.md
~/.local_memory/<agent-id>/general/general/<YYYY-MM-DD>.md
```
- Used when no project is active and no custom lane name given
- Cold-activation fallback for all agents

---

## Three-Layer Model

| Layer | File | Purpose | Loaded at startup |
|---|---|---|---|
| Long-term brain | `SUMMARY.md` | Key decisions, patterns, active context, pending | ✅ Always |
| Session record | `<YYYY-MM-DD>.md` | What was done today, file paths, problems | ✅ Today or yesterday |
| Deep search | `memory-search.sh` | Grep historical entries by keyword/date | ❌ On-demand only |

**Startup cost = 2 small files.** Stays flat regardless of project age.

---

## SUMMARY.md Canonical Structure

All agents MUST write SUMMARY.md in this format. Consistent structure enables reliable cross-agent reads.

```markdown
## Active Context
[what's currently in progress — feature, bug, epic]

## Key Decisions
- <decision> — <rationale> — <YYYY-MM-DD>
- <decision> — <rationale> — <YYYY-MM-DD>

## Patterns & Conventions
[persistent discoveries: naming conventions, architectural patterns, pitfalls found]

## Pending
[what needs to be done next session]
```

**Pruning rule:** When `wc -l SUMMARY.md` exceeds 80 lines, prune resolved items and archive them to `SUMMARY-archive-<YYYY-MM>.md` in the same folder. Active SUMMARY.md must stay concise.

---

## Daily Journal Format

Concise, token-efficient. Think: "what do I need to remember to continue tomorrow?"

```markdown
## <YYYY-MM-DD> — <agent-id> — <project-name or general-lane>

### Done
- <task/subtask completed> — <key file paths>

### Decisions
- <decision made> — <rationale>

### Problems
- <issue encountered> — <resolution or status>

### Pending
- <what's next>
```

---

## Cross-Agent Access

- Any agent may **READ** any other agent's memory lane: `~/.local_memory/<other-agent-id>/`
- **WRITE** is always agent-scoped: agents only write to `~/.local_memory/<own-agent-id>/`
- Cross-reads are useful for: context handoff between sm → dev, analyst insights referenced by architect, etc.

---

## Journal Retention

Old daily journals are archived (not deleted) by `memory-search.sh` on invocation.

- Default retention: **90 days** (configurable via `memory_journal_retention_days` in `manifest.local.yaml`)
- Journals older than retention threshold → moved to `archive/` subfolder
- Archive folder is never auto-deleted — manual cleanup only

---

## Write Access Rules

| Agent | Project lane | General lane | Other agents' lanes |
|---|---|---|---|
| Any agent | Write own `<agent-id>/` | Write own `<agent-id>/general/` | Read only |
| bmad-master | + Creates new general lanes | + Registers lane names | Read only |

---

## ⚠️ Security Warning

**Do NOT write secrets, credentials, API keys, tokens, or passwords to memory files.**

All memory lanes are readable by all BMAD agents. Memory files may also be committed accidentally if `~/.local_memory/` is ever symlinked inside a project. Keep memory entries professional and secret-free.

---

## Task Files

| File | Purpose |
|---|---|
| `memory-read.md` | Resolve and load the correct memory lane on activation |
| `memory-write.md` | Append to daily journal, update SUMMARY.md, emit signal |
| `memory-search.sh` | On-demand grep search across historical entries |
