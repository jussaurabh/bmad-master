#!/usr/bin/env bash
# =============================================================================
# BMAD Local Tasks
# Cross-agent, cross-session task queue. Complements memory system.
# ~/.local_tasks/{agent-id}/{project}/tasks.json  — own tasks
# ~/.local_tasks/{agent-id}/{project}/inbox.json  — tasks from other agents
#
# Usage:
#   local-tasks.sh <subcommand> [OPTIONS]
#
# Subcommands:
#   fetch    --agent <id> --project <name> [--status pending] [--priority high] [--tag bug] [--json]
#   inbox    --agent <id> --project <name> [--json]
#   add      --agent <id> --project <name> --title "..." --priority high|medium|low
#            [--tags a,b] [--created-by agent/lane] [--body-file path.md]
#   start    --id <task-id> --agent <id> --project <name>
#   done     --id <task-id> --agent <id> --project <name>
#   accept   --id <task-id> --agent <id> --project <name>
#   reject   --id <task-id> --agent <id> --project <name>
#   prune    --agent <id> --project <name>
#   projects --agent <id>
#   fetch    --global [--status pending] [--json]
#
# Examples:
#   local-tasks.sh add --agent dev --project disha --title "Fix auth bug" --priority high
#   local-tasks.sh fetch --agent dev --project disha --status pending
#   local-tasks.sh add --agent sm --project disha --title "Plan sprint" --created-by dev/disha
#   local-tasks.sh accept --id t-20260302-001 --agent sm --project disha
#   local-tasks.sh done --id t-20260302-001 --agent dev --project disha
#   local-tasks.sh prune --agent dev --project disha
#   local-tasks.sh projects --agent dev
# =============================================================================

set -euo pipefail

TASKS_ROOT="${HOME}/.local_tasks"
MANIFEST_LOCAL="${BMAD_ROOT:-${HOME}/Work/bmads/bmad-master}/_bmad/manifest.local.yaml"
DEFAULT_RETENTION=90

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

usage() {
  grep '^#' "$0" | grep -v '^#!/' | sed 's/^# \?//' | sed -n '/^Usage/,/^===/p' | head -n -1
  exit 0
}

die() {
  echo "[local-tasks] ERROR: $*" >&2
  exit 1
}

# Read retention days from manifest or use default
get_retention_days() {
  local days=""
  if [[ -f "${MANIFEST_LOCAL}" ]]; then
    days=$(grep 'task_retention_days\|memory_journal_retention_days' "${MANIFEST_LOCAL}" 2>/dev/null \
      | grep -i 'task' | head -1 | sed 's/.*: *//' | tr -d '[:space:]') || true
  fi
  echo "${days:-${DEFAULT_RETENTION}}"
}

# Ensure directory exists (graceful first-run)
ensure_dir() {
  mkdir -p "$1"
}

# Get the tasks.json path for an agent/project
tasks_file() {
  local agent="$1" project="$2"
  echo "${TASKS_ROOT}/${agent}/${project}/tasks.json"
}

# Get the inbox.json path for an agent/project
inbox_file() {
  local agent="$1" project="$2"
  echo "${TASKS_ROOT}/${agent}/${project}/inbox.json"
}

# Initialize a tasks.json if it doesn't exist
init_tasks_file() {
  local file="$1"
  if [[ ! -f "${file}" ]]; then
    ensure_dir "$(dirname "${file}")"
    python3 -c "
import json, sys
data = {'version': 1, 'pruned_at': None, 'tasks': []}
with open(sys.argv[1], 'w') as f:
    json.dump(data, f, indent=2)
" "${file}"
  fi
}

# Generate next task ID for today
next_task_id() {
  local file="$1"
  local today
  today=$(date +%Y%m%d)
  python3 -c "
import json, sys

file = sys.argv[1]
today = sys.argv[2]

try:
    with open(file) as f:
        data = json.load(f)
    tasks = data.get('tasks', [])
except Exception:
    tasks = []

# Count tasks created today across both tasks.json and inbox.json
prefix = 't-' + today + '-'
max_n = 0
for t in tasks:
    tid = t.get('id', '')
    if tid.startswith(prefix):
        try:
            n = int(tid[len(prefix):])
            max_n = max(max_n, n)
        except ValueError:
            pass

print('t-{}-{:03d}'.format(today, max_n + 1))
" "${file}" "${today}"
}

# Format a single task for display
format_task() {
  local task_json="$1"
  python3 -c "
import json, sys

t = json.loads(sys.argv[1])

tid    = t.get('id', '?')
title  = t.get('title', '?')
status = t.get('status', '?')
prio   = t.get('priority', 'medium').upper()[:3]
tags   = t.get('tags', [])
story  = t.get('story_ref', '')
bb     = t.get('blocked_by', [])

prio_fmt = {'HIG': '[HIGH]', 'MED': '[MED] ', 'LOW': '[LOW] '}.get(prio, '[???] ')
status_fmt = '[{}]'.format(status.ljust(11))
tag_str = '  ' + ' '.join('#' + tg for tg in tags) if tags else ''
blocked_str = '  BLOCKED:' + ','.join(bb) if bb else ''

print('{} {} {}  {}{}{}'.format(tid, prio_fmt, status_fmt, title, tag_str, blocked_str))
" "${task_json}"
}

# ---------------------------------------------------------------------------
# Subcommand: fetch
# ---------------------------------------------------------------------------
cmd_fetch() {
  local agent="" project="" status_filter="" priority_filter="" tag_filter=""
  local global_mode=false json_mode=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --agent)    agent="$2";           shift 2 ;;
      --project)  project="$2";         shift 2 ;;
      --status)   status_filter="$2";   shift 2 ;;
      --priority) priority_filter="$2"; shift 2 ;;
      --tag)      tag_filter="$2";      shift 2 ;;
      --global)   global_mode=true;     shift   ;;
      --json)     json_mode=true;       shift   ;;
      *) die "fetch: unknown option $1" ;;
    esac
  done

  if [[ "${global_mode}" == true ]]; then
    local file="${TASKS_ROOT}/global/tasks.json"
    [[ -f "${file}" ]] || { echo "[local-tasks] No global tasks yet."; return 0; }
    _print_tasks "${file}" "${status_filter}" "${priority_filter}" "${tag_filter}" "${json_mode}"
    return 0
  fi

  [[ -n "${agent}" ]]   || die "fetch: --agent required"
  [[ -n "${project}" ]] || die "fetch: --project required"

  local file
  file=$(tasks_file "${agent}" "${project}")

  if [[ ! -f "${file}" ]]; then
    echo "[local-tasks] No tasks yet for ${agent}/${project}."
    return 0
  fi

  _print_tasks "${file}" "${status_filter}" "${priority_filter}" "${tag_filter}" "${json_mode}"
}

_print_tasks() {
  local file="$1" status_filter="$2" priority_filter="$3" tag_filter="$4" json_mode="$5"

  python3 -c "
import json, sys

file           = sys.argv[1]
status_filter  = sys.argv[2]
prio_filter    = sys.argv[3]
tag_filter     = sys.argv[4]
json_mode      = sys.argv[5] == 'true'

with open(file) as f:
    data = json.load(f)

tasks = data.get('tasks', [])

# Apply filters
if status_filter:
    tasks = [t for t in tasks if t.get('status') == status_filter]
if prio_filter:
    tasks = [t for t in tasks if t.get('priority') == prio_filter]
if tag_filter:
    tasks = [t for t in tasks if tag_filter in t.get('tags', [])]

if not tasks:
    print('[local-tasks] No tasks match the criteria.')
    sys.exit(0)

if json_mode:
    print(json.dumps(tasks, indent=2))
    sys.exit(0)

for t in tasks:
    tid    = t.get('id', '?')
    title  = t.get('title', '?')
    status = t.get('status', '?')
    prio   = t.get('priority', 'medium').upper()[:3]
    tags   = t.get('tags', [])
    bb     = t.get('blocked_by', [])

    prio_fmt   = {'HIG': '[HIGH]', 'MED': '[MED] ', 'LOW': '[LOW] '}.get(prio, '[???] ')
    status_fmt = '[{}]'.format(status.ljust(11))
    tag_str    = '  ' + ' '.join('#' + tg for tg in tags) if tags else ''
    blocked_str = '  BLOCKED:' + ','.join(bb) if bb else ''

    print('{} {} {}  {}{}{}'.format(tid, prio_fmt, status_fmt, title, tag_str, blocked_str))
" "${file}" "${status_filter}" "${priority_filter}" "${tag_filter}" "${json_mode}"
}

# ---------------------------------------------------------------------------
# Subcommand: inbox
# ---------------------------------------------------------------------------
cmd_inbox() {
  local agent="" project="" json_mode=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --agent)   agent="$2";   shift 2 ;;
      --project) project="$2"; shift 2 ;;
      --json)    json_mode=true; shift ;;
      *) die "inbox: unknown option $1" ;;
    esac
  done

  [[ -n "${agent}" ]]   || die "inbox: --agent required"
  [[ -n "${project}" ]] || die "inbox: --project required"

  local file
  file=$(inbox_file "${agent}" "${project}")

  if [[ ! -f "${file}" ]]; then
    echo "[local-tasks] Inbox empty for ${agent}/${project}."
    return 0
  fi

  python3 -c "
import json, sys

file      = sys.argv[1]
json_mode = sys.argv[2] == 'true'

with open(file) as f:
    data = json.load(f)

tasks = [t for t in data.get('tasks', []) if t.get('status') == 'inbox']

if not tasks:
    print('[local-tasks] Inbox empty.')
    sys.exit(0)

if json_mode:
    print(json.dumps(tasks, indent=2))
    sys.exit(0)

print('Inbox ({} item{}):'.format(len(tasks), 's' if len(tasks) != 1 else ''))
for t in tasks:
    tid    = t.get('id', '?')
    title  = t.get('title', '?')
    prio   = t.get('priority', 'medium').upper()[:3]
    by     = t.get('created_by', '?')
    tags   = t.get('tags', [])

    prio_fmt = {'HIG': '[HIGH]', 'MED': '[MED] ', 'LOW': '[LOW] '}.get(prio, '[???] ')
    tag_str  = '  ' + ' '.join('#' + tg for tg in tags) if tags else ''
    print('{} {} [inbox]      {}  from:{}{}'.format(tid, prio_fmt, title, by, tag_str))
" "${file}" "${json_mode}"
}

# ---------------------------------------------------------------------------
# Subcommand: add
# ---------------------------------------------------------------------------
cmd_add() {
  local agent="" project="" title="" priority="medium"
  local tags="" created_by="" body_file=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --agent)       agent="$2";      shift 2 ;;
      --project)     project="$2";    shift 2 ;;
      --title)       title="$2";      shift 2 ;;
      --priority)    priority="$2";   shift 2 ;;
      --tags)        tags="$2";       shift 2 ;;
      --created-by)  created_by="$2"; shift 2 ;;
      --body-file)   body_file="$2";  shift 2 ;;
      *) die "add: unknown option $1" ;;
    esac
  done

  [[ -n "${agent}" ]]   || die "add: --agent required"
  [[ -n "${project}" ]] || die "add: --project required"
  [[ -n "${title}" ]]   || die "add: --title required"

  # Validate priority
  case "${priority}" in
    high|medium|low) ;;
    *) die "add: --priority must be high, medium, or low" ;;
  esac

  # If created_by is set AND it differs from agent/project → goes to inbox
  local is_cross_agent=false
  if [[ -n "${created_by}" ]]; then
    local creator_agent
    creator_agent=$(echo "${created_by}" | cut -d/ -f1)
    if [[ "${creator_agent}" != "${agent}" ]]; then
      is_cross_agent=true
    fi
  fi

  local target_file
  if [[ "${is_cross_agent}" == true ]]; then
    target_file=$(inbox_file "${agent}" "${project}")
  else
    target_file=$(tasks_file "${agent}" "${project}")
  fi

  ensure_dir "$(dirname "${target_file}")"
  init_tasks_file "${target_file}"

  local task_id
  task_id=$(next_task_id "${target_file}")

  local status="pending"
  [[ "${is_cross_agent}" == true ]] && status="inbox"

  python3 -c "
import json, sys
from datetime import datetime, timezone

file       = sys.argv[1]
task_id    = sys.argv[2]
title      = sys.argv[3]
status     = sys.argv[4]
priority   = sys.argv[5]
tags_raw   = sys.argv[6]
created_by = sys.argv[7]
body_file  = sys.argv[8]

tags = [t.strip() for t in tags_raw.split(',') if t.strip()] if tags_raw else []

now = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')

task = {
    'id':         task_id,
    'title':      title,
    'status':     status,
    'priority':   priority,
    'tags':       tags,
    'created_at': now,
    'created_by': created_by if created_by else 'unknown',
    'body_file':  body_file if body_file else None,
    'blocked_by': [],
    'story_ref':  None,
    'done_at':    None
}

with open(file) as f:
    data = json.load(f)

data['tasks'].append(task)

with open(file, 'w') as f:
    json.dump(data, f, indent=2)

dest = 'inbox' if status == 'inbox' else 'tasks'
print('[local-tasks] Added {} → {}/{} {} ({})'.format(task_id, sys.argv[9], sys.argv[10], dest, priority))
" "${target_file}" "${task_id}" "${title}" "${status}" "${priority}" \
    "${tags}" "${created_by}" "${body_file}" "${agent}" "${project}"
}

# ---------------------------------------------------------------------------
# Subcommand: start
# ---------------------------------------------------------------------------
cmd_start() {
  local task_id="" agent="" project=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --id)      task_id="$2"; shift 2 ;;
      --agent)   agent="$2";   shift 2 ;;
      --project) project="$2"; shift 2 ;;
      *) die "start: unknown option $1" ;;
    esac
  done

  [[ -n "${task_id}" ]] || die "start: --id required"
  [[ -n "${agent}" ]]   || die "start: --agent required"
  [[ -n "${project}" ]] || die "start: --project required"

  local file
  file=$(tasks_file "${agent}" "${project}")
  [[ -f "${file}" ]] || die "No tasks.json found for ${agent}/${project}"

  _update_task_status "${file}" "${task_id}" "in_progress" ""
  echo "[local-tasks] ${task_id} → in_progress"
}

# ---------------------------------------------------------------------------
# Subcommand: done
# ---------------------------------------------------------------------------
cmd_done() {
  local task_id="" agent="" project=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --id)      task_id="$2"; shift 2 ;;
      --agent)   agent="$2";   shift 2 ;;
      --project) project="$2"; shift 2 ;;
      *) die "done: unknown option $1" ;;
    esac
  done

  [[ -n "${task_id}" ]] || die "done: --id required"
  [[ -n "${agent}" ]]   || die "done: --agent required"
  [[ -n "${project}" ]] || die "done: --project required"

  local file
  file=$(tasks_file "${agent}" "${project}")
  [[ -f "${file}" ]] || die "No tasks.json found for ${agent}/${project}"

  local now
  now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  _update_task_status "${file}" "${task_id}" "done" "${now}"
  echo "[local-tasks] ${task_id} → done"
}

# ---------------------------------------------------------------------------
# Subcommand: accept
# ---------------------------------------------------------------------------
cmd_accept() {
  local task_id="" agent="" project=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --id)      task_id="$2"; shift 2 ;;
      --agent)   agent="$2";   shift 2 ;;
      --project) project="$2"; shift 2 ;;
      *) die "accept: unknown option $1" ;;
    esac
  done

  [[ -n "${task_id}" ]] || die "accept: --id required"
  [[ -n "${agent}" ]]   || die "accept: --agent required"
  [[ -n "${project}" ]] || die "accept: --project required"

  local inbox
  inbox=$(inbox_file "${agent}" "${project}")
  local tasks
  tasks=$(tasks_file "${agent}" "${project}")

  [[ -f "${inbox}" ]] || die "No inbox.json found for ${agent}/${project}"

  ensure_dir "$(dirname "${tasks}")"
  init_tasks_file "${tasks}"

  python3 -c "
import json, sys

inbox_file = sys.argv[1]
tasks_file = sys.argv[2]
task_id    = sys.argv[3]

with open(inbox_file) as f:
    inbox = json.load(f)

# Find the task
task = None
remaining = []
for t in inbox.get('tasks', []):
    if t.get('id') == task_id:
        task = t
    else:
        remaining.append(t)

if task is None:
    print('[local-tasks] Task {} not found in inbox.'.format(task_id))
    sys.exit(1)

# Move to tasks.json with status = pending
task['status'] = 'pending'
inbox['tasks'] = remaining

with open(inbox_file, 'w') as f:
    json.dump(inbox, f, indent=2)

with open(tasks_file) as f:
    tasks = json.load(f)

tasks['tasks'].append(task)

with open(tasks_file, 'w') as f:
    json.dump(tasks, f, indent=2)

print('[local-tasks] {} accepted → tasks.json (pending)'.format(task_id))
" "${inbox}" "${tasks}" "${task_id}"
}

# ---------------------------------------------------------------------------
# Subcommand: reject
# ---------------------------------------------------------------------------
cmd_reject() {
  local task_id="" agent="" project=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --id)      task_id="$2"; shift 2 ;;
      --agent)   agent="$2";   shift 2 ;;
      --project) project="$2"; shift 2 ;;
      *) die "reject: unknown option $1" ;;
    esac
  done

  [[ -n "${task_id}" ]] || die "reject: --id required"
  [[ -n "${agent}" ]]   || die "reject: --agent required"
  [[ -n "${project}" ]] || die "reject: --project required"

  local file
  file=$(inbox_file "${agent}" "${project}")
  [[ -f "${file}" ]] || die "No inbox.json found for ${agent}/${project}"

  _update_task_status "${file}" "${task_id}" "cancelled" ""
  echo "[local-tasks] ${task_id} → rejected (cancelled in inbox)"
}

# ---------------------------------------------------------------------------
# Subcommand: prune
# ---------------------------------------------------------------------------
cmd_prune() {
  local agent="" project=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --agent)   agent="$2";   shift 2 ;;
      --project) project="$2"; shift 2 ;;
      *) die "prune: unknown option $1" ;;
    esac
  done

  [[ -n "${agent}" ]]   || die "prune: --agent required"
  [[ -n "${project}" ]] || die "prune: --project required"

  local file
  file=$(tasks_file "${agent}" "${project}")

  if [[ ! -f "${file}" ]]; then
    echo "[local-tasks] Nothing to prune for ${agent}/${project}."
    return 0
  fi

  local retention_days
  retention_days=$(get_retention_days)

  local dir
  dir=$(dirname "${file}")

  python3 -c "
import json, sys
from datetime import datetime, timezone, timedelta

file           = sys.argv[1]
retention_days = int(sys.argv[2])
dir_path       = sys.argv[3]

cutoff = datetime.now(timezone.utc) - timedelta(days=retention_days)

with open(file) as f:
    data = json.load(f)

active = []
archived = []

for t in data.get('tasks', []):
    status = t.get('status', '')
    if status not in ('done', 'cancelled'):
        active.append(t)
        continue

    done_at_str = t.get('done_at') or t.get('created_at', '')
    try:
        done_at = datetime.fromisoformat(done_at_str.replace('Z', '+00:00'))
    except Exception:
        active.append(t)
        continue

    if done_at < cutoff:
        archived.append(t)
    else:
        active.append(t)

if not archived:
    print('[local-tasks] Nothing to archive — all done/cancelled tasks within retention window.')
    sys.exit(0)

# Write archive file
month = datetime.now().strftime('%Y-%m')
archive_file = '{}/tasks-archive-{}.json'.format(dir_path, month)

try:
    with open(archive_file) as f:
        arch_data = json.load(f)
except FileNotFoundError:
    arch_data = {'version': 1, 'tasks': []}

arch_data['tasks'].extend(archived)

with open(archive_file, 'w') as f:
    json.dump(arch_data, f, indent=2)

# Update tasks.json
from datetime import date
data['tasks'] = active
data['pruned_at'] = date.today().isoformat()

with open(file, 'w') as f:
    json.dump(data, f, indent=2)

print('[local-tasks] Pruned {} task(s) → {}'.format(len(archived), archive_file))
" "${file}" "${retention_days}" "${dir}"
}

# ---------------------------------------------------------------------------
# Subcommand: projects
# ---------------------------------------------------------------------------
cmd_projects() {
  local agent=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --agent) agent="$2"; shift 2 ;;
      *) die "projects: unknown option $1" ;;
    esac
  done

  [[ -n "${agent}" ]] || die "projects: --agent required"

  local agent_dir="${TASKS_ROOT}/${agent}"

  if [[ ! -d "${agent_dir}" ]]; then
    echo "[local-tasks] No task lanes found for agent: ${agent}"
    return 0
  fi

  python3 -c "
import os, json, sys

agent_dir = sys.argv[1]

projects = sorted(d for d in os.listdir(agent_dir)
                  if os.path.isdir(os.path.join(agent_dir, d)))

if not projects:
    print('[local-tasks] No project lanes found.')
    sys.exit(0)

print('Task lanes for {}:'.format(os.path.basename(agent_dir)))
for proj in projects:
    proj_dir = os.path.join(agent_dir, proj)
    tasks_path = os.path.join(proj_dir, 'tasks.json')
    inbox_path = os.path.join(proj_dir, 'inbox.json')

    pending = done = inbox = 0
    if os.path.exists(tasks_path):
        with open(tasks_path) as f:
            data = json.load(f)
        for t in data.get('tasks', []):
            s = t.get('status')
            if s in ('pending', 'in_progress'):
                pending += 1
            elif s == 'done':
                done += 1

    if os.path.exists(inbox_path):
        with open(inbox_path) as f:
            data = json.load(f)
        inbox = sum(1 for t in data.get('tasks', []) if t.get('status') == 'inbox')

    print('  {:30s}  pending:{:3d}  inbox:{:3d}  done:{:3d}'.format(proj, pending, inbox, done))
" "${agent_dir}"
}

# ---------------------------------------------------------------------------
# Helper: update a task status in a JSON file
# ---------------------------------------------------------------------------
_update_task_status() {
  local file="$1" task_id="$2" new_status="$3" done_at="$4"

  python3 -c "
import json, sys

file       = sys.argv[1]
task_id    = sys.argv[2]
new_status = sys.argv[3]
done_at    = sys.argv[4]

with open(file) as f:
    data = json.load(f)

found = False
for t in data.get('tasks', []):
    if t.get('id') == task_id:
        t['status'] = new_status
        if done_at:
            t['done_at'] = done_at
        found = True
        break

if not found:
    print('[local-tasks] Task {} not found.'.format(task_id))
    sys.exit(1)

with open(file, 'w') as f:
    json.dump(data, f, indent=2)
" "${file}" "${task_id}" "${new_status}" "${done_at}"
}

# ---------------------------------------------------------------------------
# Main dispatcher
# ---------------------------------------------------------------------------

if [[ $# -eq 0 ]]; then
  usage
fi

SUBCOMMAND="$1"
shift

case "${SUBCOMMAND}" in
  fetch)    cmd_fetch    "$@" ;;
  inbox)    cmd_inbox    "$@" ;;
  add)      cmd_add      "$@" ;;
  start)    cmd_start    "$@" ;;
  done)     cmd_done     "$@" ;;
  accept)   cmd_accept   "$@" ;;
  reject)   cmd_reject   "$@" ;;
  prune)    cmd_prune    "$@" ;;
  projects) cmd_projects "$@" ;;
  -h|--help|help) usage ;;
  *) die "Unknown subcommand: ${SUBCOMMAND}. Run with --help for usage." ;;
esac
