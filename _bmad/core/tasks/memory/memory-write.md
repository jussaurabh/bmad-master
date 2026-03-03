# Task: Memory Write

Append a journal entry and maintain SUMMARY.md after task completion.

Called after every task/subtask completes (dev agent step 14). Emits `[memory updated]`.

---

## Inputs

| Variable | Source |
|---|---|
| `{active-memory-lane}` | Set by memory-read on activation |
| `{agent-id}` | Agent metadata `id` field |
| `{task-summary}` | What was just completed — agent constructs this |

---

## Execution Steps

### Step 1: Resolve today's journal path
```
{lane-path} = ~/.local_memory/{active-memory-lane}/
{journal-file} = {lane-path}/{YYYY-MM-DD}.md   (today's date)
```

### Step 2: Append journal entry

Append the following to `{journal-file}` (create file if it doesn't exist):

```markdown
### <HH:MM> — <brief task description>

**Done:** <what was implemented/completed>
**Files:** <key file paths changed>
**Decisions:** <any architectural or implementation decisions made>
**Problems:** <issues encountered and resolution>
**Pending:** <what's next for this task/story>
```

Keep entries concise — token-efficient. Think: "what do I need to remember tomorrow?"

### Step 3: Check SUMMARY.md line count

```bash
wc -l ~/.local_memory/{active-memory-lane}/SUMMARY.md
```

- If file doesn't exist: create it using the canonical structure (see below) and skip pruning
- If line count ≤ 80: no pruning needed
- If line count > 80: proceed to Step 4 (prune)

### Step 4: Prune SUMMARY.md (only if > 80 lines)

1. Read current SUMMARY.md
2. Identify resolved/stale items:
   - Completed pending items
   - Old decisions that are now established convention (no longer need reminding)
   - Resolved problems
3. Move removed items to `SUMMARY-archive-{YYYY-MM}.md` in the same folder (append, don't overwrite)
4. Rewrite SUMMARY.md with pruned content — keep it under 60 lines after pruning

### Step 5: Update SUMMARY.md content

Update the relevant sections based on what just happened:

```markdown
## Active Context
[Update: what's currently in progress]

## Key Decisions
[Append if new decision made: <decision> — <rationale> — <YYYY-MM-DD>]

## Patterns & Conventions
[Append if new pattern discovered]

## Pending
[Update: what needs to be done next]
```

Only update sections that changed. Don't rewrite the whole file for minor tasks.

### Step 6: Emit signal

Output to user (inline, one line):
```
[memory updated]
```

---

## Failure Handling

If any write fails (permission denied, disk full, path error):

1. **STOP** — do not continue to next user response
2. **Diagnose** — identify the specific cause:
   - Permission: show `ls -la ~/.local_memory/` output
   - Disk: show `df -h ~` output
3. **Ask user** for the specific fix:
   - Permission: `"Run: chmod -R 755 ~/.local_memory/"`
   - Disk: `"Free up disk space — currently X% full"`
4. **Retry** the write after user confirms fix
5. Only continue story execution after successful write

Never skip memory write silently. Memory integrity is worth the pause.

---

## SUMMARY.md Canonical Structure

All agents use this exact structure. Consistent format enables reliable cross-agent reads.

```markdown
## Active Context
[what's currently in progress — feature, bug, epic]

## Key Decisions
- <decision> — <rationale> — <YYYY-MM-DD>

## Patterns & Conventions
[persistent discoveries: naming conventions, architectural patterns, pitfalls]

## Pending
[what needs to be done next session]
```

---

## Notes

- `{active-memory-lane}` uses agent `id`, never persona name — paths survive persona renames
- Journal entries are append-only — never edit or delete past entries
- SUMMARY.md is the only file that gets rewritten (pruning)
- `memory-search.sh` handles journal retention (archiving old files) — not this task
