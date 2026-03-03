#!/usr/bin/env bash
# =============================================================================
# BMAD Memory Search
# On-demand search across historical journal entries and SUMMARY files.
# Also enforces journal retention (archives old entries).
#
# Usage:
#   memory-search.sh [OPTIONS]
#
# Options:
#   -a, --agent <id>         Agent id to search (e.g. dev, sm, analyst). Default: all agents.
#   -p, --project <name>     Project name to scope search. Default: all lanes.
#   -k, --keyword <term>     Keyword or phrase to search for (grep regex supported).
#   -d, --date <YYYY-MM-DD>  Search entries from a specific date.
#   --from <YYYY-MM-DD>      Search entries from this date onwards.
#   --to <YYYY-MM-DD>        Search entries up to this date.
#   --summary                Search SUMMARY.md files only.
#   --journal                Search daily journal files only (default: both).
#   --retain <days>          Override retention days (default: read from manifest or 90).
#   --archive-only           Only run retention archiving, no search output.
#   -h, --help               Show this help.
#
# Examples:
#   memory-search.sh -a dev -k "Auth0"
#   memory-search.sh -a dev -p disha-consultancy-backend --from 2026-02-01
#   memory-search.sh --archive-only
# =============================================================================

set -euo pipefail

MEMORY_ROOT="${HOME}/.local_memory"
MANIFEST_LOCAL="${BMAD_ROOT:-${HOME}/Work/bmads/bmad-master}/_bmad/manifest.local.yaml"
DEFAULT_RETENTION=90

# --- Graceful first-run: memory root doesn't exist yet ---
if [[ ! -d "${MEMORY_ROOT}" ]]; then
  echo "[memory-search] ~/.local_memory/ not found — no memories yet. Nothing to search or archive."
  exit 0
fi

# --- Parse arguments ---
AGENT_FILTER=""
PROJECT_FILTER=""
KEYWORD=""
DATE_EXACT=""
DATE_FROM=""
DATE_TO=""
SEARCH_SUMMARY=true
SEARCH_JOURNAL=true
ARCHIVE_ONLY=false
RETAIN_DAYS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -a|--agent)     AGENT_FILTER="$2"; shift 2 ;;
    -p|--project)   PROJECT_FILTER="$2"; shift 2 ;;
    -k|--keyword)   KEYWORD="$2"; shift 2 ;;
    -d|--date)      DATE_EXACT="$2"; shift 2 ;;
    --from)         DATE_FROM="$2"; shift 2 ;;
    --to)           DATE_TO="$2"; shift 2 ;;
    --summary)      SEARCH_JOURNAL=false; shift ;;
    --journal)      SEARCH_SUMMARY=false; shift ;;
    --retain)       RETAIN_DAYS="$2"; shift 2 ;;
    --archive-only) ARCHIVE_ONLY=true; shift ;;
    -h|--help)
      sed -n '/^# Usage/,/^# =/p' "$0" | grep '^#' | sed 's/^# \?//'
      exit 0
      ;;
    *) echo "[memory-search] Unknown option: $1" >&2; exit 1 ;;
  esac
done

# --- Read retention days from manifest if not overridden ---
if [[ -z "${RETAIN_DAYS}" ]]; then
  if [[ -f "${MANIFEST_LOCAL}" ]]; then
    RETAIN_DAYS=$(grep 'memory_journal_retention_days' "${MANIFEST_LOCAL}" 2>/dev/null \
      | head -1 | sed 's/.*: *//' | tr -d '[:space:]') || true
  fi
  RETAIN_DAYS="${RETAIN_DAYS:-${DEFAULT_RETENTION}}"
fi

# --- Build search scope ---
if [[ -n "${AGENT_FILTER}" ]]; then
  SEARCH_DIRS=("${MEMORY_ROOT}/${AGENT_FILTER}")
else
  SEARCH_DIRS=("${MEMORY_ROOT}"/*)
fi

# --- Retention archiving ---
archive_old_journals() {
  local lane_dir="$1"
  local cutoff_date
  cutoff_date=$(date -v-"${RETAIN_DAYS}"d +%Y-%m-%d 2>/dev/null \
    || date -d "${RETAIN_DAYS} days ago" +%Y-%m-%d 2>/dev/null \
    || echo "")

  if [[ -z "${cutoff_date}" ]]; then
    return  # Can't determine cutoff, skip archiving
  fi

  local archive_dir="${lane_dir}/archive"
  local archived=0

  for journal in "${lane_dir}"/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md; do
    [[ -f "${journal}" ]] || continue
    local file_date
    file_date=$(basename "${journal}" .md)
    if [[ "${file_date}" < "${cutoff_date}" ]]; then
      mkdir -p "${archive_dir}"
      mv "${journal}" "${archive_dir}/"
      ((archived++)) || true
    fi
  done

  if [[ ${archived} -gt 0 ]]; then
    echo "[memory-search] Archived ${archived} journal(s) older than ${RETAIN_DAYS} days → ${archive_dir}"
  fi
}

# Run archiving across all lanes
for agent_dir in "${SEARCH_DIRS[@]}"; do
  [[ -d "${agent_dir}" ]] || continue
  # Walk all lane directories (project lanes + general/*)
  while IFS= read -r -d '' lane_dir; do
    archive_old_journals "${lane_dir}"
  done < <(find "${agent_dir}" -mindepth 1 -type d -not -path "*/archive" -print0)
done

[[ "${ARCHIVE_ONLY}" == true ]] && exit 0

# --- Search ---
if [[ -z "${KEYWORD}" && -z "${DATE_EXACT}" && -z "${DATE_FROM}" && -z "${DATE_TO}" ]]; then
  echo "[memory-search] No search criteria provided. Use -k <keyword> or -d <date>."
  echo "Run with -h for usage."
  exit 0
fi

RESULTS_FOUND=0

for agent_dir in "${SEARCH_DIRS[@]}"; do
  [[ -d "${agent_dir}" ]] || continue
  agent_id=$(basename "${agent_dir}")

  # Build file list based on flags
  FILE_PATTERN=""
  if [[ "${SEARCH_SUMMARY}" == true && "${SEARCH_JOURNAL}" == true ]]; then
    FILE_PATTERN="*.md"
  elif [[ "${SEARCH_SUMMARY}" == true ]]; then
    FILE_PATTERN="SUMMARY*.md"
  else
    FILE_PATTERN="[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md"
  fi

  # Scope by project if specified
  if [[ -n "${PROJECT_FILTER}" ]]; then
    LANE_GLOB="${agent_dir}/${PROJECT_FILTER}"
  else
    LANE_GLOB="${agent_dir}"
  fi

  while IFS= read -r -d '' file; do
    # Date filtering
    filename=$(basename "${file}")
    if [[ "${filename}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\.md$ ]]; then
      file_date="${filename%.md}"
      [[ -n "${DATE_EXACT}" && "${file_date}" != "${DATE_EXACT}" ]] && continue
      [[ -n "${DATE_FROM}" && "${file_date}" < "${DATE_FROM}" ]] && continue
      [[ -n "${DATE_TO}" && "${file_date}" > "${DATE_TO}" ]] && continue
    fi

    # Keyword search
    if [[ -n "${KEYWORD}" ]]; then
      matches=$(grep -n "${KEYWORD}" "${file}" 2>/dev/null || true)
      if [[ -n "${matches}" ]]; then
        echo ""
        echo "=== ${file} ==="
        echo "${matches}"
        RESULTS_FOUND=$((RESULTS_FOUND + 1))
      fi
    else
      # No keyword — just show matching files by date
      echo "${file}"
      RESULTS_FOUND=$((RESULTS_FOUND + 1))
    fi
  done < <(find "${LANE_GLOB}" -name "${FILE_PATTERN}" -not -path "*/archive/*" -print0 2>/dev/null)
done

if [[ ${RESULTS_FOUND} -eq 0 ]]; then
  echo "[memory-search] No results found."
else
  echo ""
  echo "[memory-search] ${RESULTS_FOUND} result(s) found."
fi
