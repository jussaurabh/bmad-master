# repo-onboarding-guide-sidecar

Persistent memory for the **Scout** (Repo Onboarding Guide) Expert agent.

## Purpose

Stores Scout's operating instructions and cross-session user preferences.
Project-specific onboarding data lives separately at `~/.local_memory/repo-guide/{project-name}/`.

## Files

- `instructions.md` — Core operating protocols (loaded on every activation)
- `memories.md` — General user preferences observed across all repo sessions

## Runtime Access

After BMAD installation, this folder is accessible at:
`{project-root}/_bmad/_memory/repo-onboarding-guide-sidecar/`

## Project Memory (separate)

Per-project onboarding data lives at:
`~/.local_memory/repo-guide/{project-name}/onboarding/`
- `overview.md`
- `file-index.md`
- `session-state.md`
- `qa-log.md`
