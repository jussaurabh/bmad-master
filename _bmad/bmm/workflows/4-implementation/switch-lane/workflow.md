# Switch Lane — Memory Lane Switcher

**Purpose:** Change the active memory lane mid-session without restarting the agent.

Useful when:
- You want to switch from project work to general brainstorming
- You're moving between two registered projects in one session
- You want to use a named general lane (e.g. `learning`, `architecture`)

---

## Execution Steps

### Step 1: Write closing note to current lane

Before switching, close the current lane gracefully.

Append to `~/.local_memory/{active-memory-lane}/[today].md`:

```
[Session switched to lane: <new-lane-name> at <HH:MM>]
```

This marks the transition point in the journal for continuity.

---

### Step 2: Build lane list

Collect all available lanes from:

1. **Project lanes** — from `manifest.local.yaml projects[].name` (if manifest is loaded)
2. **Named general lanes** — from `manifest.local.yaml general_lanes[].name` (if any registered)
3. **Default general lane** — always available as `general/general`

---

### Step 3: Present lane selection

```
Switch to which memory lane?

Projects:
  1. <project-name> — <summary>
  2. <project-name> — <summary>

General lanes:
  G. general — default general lane
  <N>. <custom-name> — <description>  (if registered)
```

Wait for user selection.

---

### Step 4: Activate new lane

Based on selection:

**Project lane selected:**
- Set `{active-project}` = selected project name
- Clear `{active-lane-override}`
- Auto-create `~/.local_memory/dev/<project-name>/` if it doesn't exist

**Named general lane selected:**
- Clear `{active-project}`
- Set `{active-lane-override}` = custom lane name
- Auto-create `~/.local_memory/dev/general/<custom-name>/` if it doesn't exist

**Default general lane selected:**
- Clear `{active-project}`
- Clear `{active-lane-override}`

---

### Step 5: Load new lane memory

Load `SUMMARY.md` + today's journal from the new lane.

Update `{active-memory-lane}` and `{memory-status}` session variables.

---

### Step 6: Confirm and return

```
✅ Lane switched

Now writing to: <new-lane-path>
Memory:         <new-memory-status>
```

Return to agent menu. All future memory writes will go to the new lane.
