#!/usr/bin/env bash
# Agent Vision session sticky state (no camera).
# Arm/disarm is agent-session policy; each vision look still uses one-shot capture.
set -euo pipefail

STATE_DIR="${HOME}/.agent-vision"
STATE_FILE="${STATE_DIR}/session-state.json"
GATE_FILE="${STATE_DIR}/turn-gate.json"

usage() {
  cat <<'EOF'
Usage: agent-vision-sticky.sh <command> [options]

Commands:
  on   --host grok|codex [--mode mood|snapshot|roast]
  off  [--host grok|codex]
  status   Print sticky + last-capture age (from turn-gate if present).
  is-on    Exit 0 if sticky true, 1 if false/missing

Never launches the camera or AgentVision.app.
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

ensure_state_dir() {
  mkdir -p -m 700 "$STATE_DIR"
}

write_state() {
  local sticky="$1"
  local host="$2"
  local mode="$3"
  ensure_state_dir
  python3 - "$STATE_FILE" "$sticky" "$host" "$mode" <<'PY'
import json
import pathlib
import sys
from datetime import datetime, timezone

path = pathlib.Path(sys.argv[1])
sticky = sys.argv[2] == "true"
host = sys.argv[3]
mode = sys.argv[4]
now = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
data = {
    "sticky": sticky,
    "host": host if host else None,
    "mode": mode if mode else None,
    "updated_at": now,
}
if sticky:
    data["armed_at"] = now
else:
    data["armed_at"] = None
path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
path.chmod(0o600)
print(path.read_text(encoding="utf-8"), end="")
PY
}

read_status() {
  python3 - "$STATE_FILE" "$GATE_FILE" <<'PY'
import json
import pathlib
import sys
from datetime import datetime, timezone

state_path = pathlib.Path(sys.argv[1])
gate_path = pathlib.Path(sys.argv[2])
if state_path.is_file():
    try:
        data = json.loads(state_path.read_text(encoding="utf-8"))
    except Exception:
        data = {}
else:
    data = {}
out = {
    "sticky": bool(data.get("sticky")),
    "host": data.get("host"),
    "mode": data.get("mode"),
    "armed_at": data.get("armed_at"),
    "updated_at": data.get("updated_at"),
    "last_capture_path": None,
    "last_capture_at": None,
    "last_capture_age_seconds": None,
    "last_capture_ok": False,
}
if gate_path.is_file():
    try:
        gate = json.loads(gate_path.read_text(encoding="utf-8"))
    except Exception:
        gate = {}
    path = gate.get("path")
    recorded = gate.get("recorded_at")
    exists = bool(path and pathlib.Path(path).is_file())
    out["last_capture_path"] = path
    out["last_capture_at"] = recorded
    out["last_capture_ok"] = bool(gate.get("ok")) and exists
    if recorded:
        try:
            ts = datetime.fromisoformat(recorded.replace("Z", "+00:00"))
            age = int((datetime.now(timezone.utc) - ts).total_seconds())
            out["last_capture_age_seconds"] = max(0, age)
        except Exception:
            pass
print(json.dumps(out, indent=2))
PY
}

is_on() {
  if [[ ! -f "$STATE_FILE" ]]; then
    return 1
  fi
  python3 - "$STATE_FILE" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
try:
    data = json.loads(path.read_text(encoding="utf-8"))
except Exception:
    sys.exit(1)
sys.exit(0 if data.get("sticky") is True else 1)
PY
}

cmd="${1:-}"
if [[ -z "$cmd" || "$cmd" == "-h" || "$cmd" == "--help" ]]; then
  usage
  exit 0
fi
shift || true

HOST=""
MODE="mood"

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --host)
      require_value "$1" "${2:-}"
      HOST="$2"
      shift 2
      ;;
    --mode)
      require_value "$1" "${2:-}"
      MODE="$2"
      shift 2
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

case "$HOST" in
  ""|grok|codex) ;;
  *)
    echo "ERROR: --host must be grok or codex." >&2
    exit 64
    ;;
esac

case "$MODE" in
  mood|snapshot|roast) ;;
  *)
    echo "ERROR: --mode must be mood, snapshot, or roast." >&2
    exit 64
    ;;
esac

case "$cmd" in
  on)
    if [[ -z "$HOST" ]]; then
      echo "ERROR: on requires --host grok|codex." >&2
      exit 64
    fi
    write_state true "$HOST" "$MODE"
    ;;
  off)
    if [[ -z "$HOST" && -f "$STATE_FILE" ]]; then
      HOST="$(python3 -c "import json,pathlib; p=pathlib.Path('$STATE_FILE');
print((json.loads(p.read_text()) if p.exists() else {}).get('host') or '')" 2>/dev/null || true)"
    fi
    write_state false "${HOST:-}" ""
    ;;
  status)
    read_status
    ;;
  is-on)
    if is_on; then
      exit 0
    fi
    exit 1
    ;;
  *)
    echo "Unknown command: $cmd" >&2
    usage >&2
    exit 64
    ;;
esac
