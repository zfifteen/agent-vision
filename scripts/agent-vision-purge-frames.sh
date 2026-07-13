#!/usr/bin/env bash
# Purge local Agent Vision frame JPEGs older than TTL. Never launches the camera.
set -euo pipefail

TTL_DAYS=7
DRY_RUN=0
DO_GROK=0
DO_CODEX=0
DO_ALL=0

usage() {
  cat <<'EOF'
Usage: agent-vision-purge-frames.sh [options]

Options:
  --ttl-days N   Delete frames older than N days (default 7). Use 0 to delete all.
  --dry-run      Print paths that would be deleted; do not delete.
  --grok         Purge ~/.agent-vision/frames
  --codex        Purge ~/.codex/agent-vision/frames
  --all          Purge both (default if no host flag)

Never launches the camera.
EOF
}

require_value() {
  local opt="$1"
  local val="${2:-}"
  if [[ -z "$val" || "$val" == -* ]]; then
    echo "ERROR: $opt requires a value." >&2
    exit 64
  fi
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --ttl-days)
      require_value "$1" "${2:-}"
      TTL_DAYS="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --grok)
      DO_GROK=1
      shift
      ;;
    --codex)
      DO_CODEX=1
      shift
      ;;
    --all)
      DO_ALL=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 64
      ;;
  esac
done

if [[ "$DO_ALL" -eq 1 || ( "$DO_GROK" -eq 0 && "$DO_CODEX" -eq 0 ) ]]; then
  DO_GROK=1
  DO_CODEX=1
fi

DIRS=()
if [[ "$DO_GROK" -eq 1 ]]; then
  DIRS+=("${HOME}/.agent-vision/frames")
fi
if [[ "$DO_CODEX" -eq 1 ]]; then
  DIRS+=("${HOME}/.codex/agent-vision/frames")
fi

python3 - "$TTL_DAYS" "$DRY_RUN" "${DIRS[@]}" <<'PY'
import json
import os
import pathlib
import sys
import time

ttl_days = int(sys.argv[1])
dry_run = sys.argv[2] == "1"
dirs = [pathlib.Path(p) for p in sys.argv[3:]]
now = time.time()
cutoff = now if ttl_days <= 0 else now - (ttl_days * 86400)

deleted = []
would_delete = []
skipped = []
for d in dirs:
    if not d.is_dir():
        continue
    for p in sorted(d.glob("*.jpg")) + sorted(d.glob("*.jpeg")):
        try:
            mtime = p.stat().st_mtime
        except OSError:
            skipped.append(str(p))
            continue
        eligible = ttl_days <= 0 or mtime <= cutoff
        if not eligible:
            continue
        if dry_run:
            would_delete.append(str(p))
        else:
            try:
                p.unlink()
                deleted.append(str(p))
            except OSError:
                skipped.append(str(p))

out = {
    "ttl_days": ttl_days,
    "dry_run": dry_run,
    "dirs": [str(d) for d in dirs],
    "deleted": deleted,
    "would_delete": would_delete,
    "skipped": skipped,
    "deleted_count": len(deleted),
    "would_delete_count": len(would_delete),
}
print(json.dumps(out, indent=2))
PY
