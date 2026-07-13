#!/usr/bin/env bash
# Mechanical turn gate: record a successful capture for this turn; fail-closed ready.
# Never launches the camera or AgentVision.app.
set -euo pipefail

STATE_DIR="${HOME}/.agent-vision"
GATE_FILE="${STATE_DIR}/turn-gate.json"
DEFAULT_MAX_AGE=600

usage() {
  cat <<'EOF'
Usage: agent-vision-turn-gate.sh <command> [options]

Commands:
  record --path PATH   Record a successful capture (path must exist as a file).
  ready [--max-age SEC]
                       Exit 0 only if a valid capture was recorded and the file
                       still exists and is within max age (default 600s).
                       Fail-closed otherwise (exit 1).
  status               Print gate JSON (always exit 0).
  clear                Clear the gate record.

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

ensure_state_dir() {
  mkdir -p -m 700 "$STATE_DIR"
}

cmd="${1:-}"
if [[ -z "$cmd" || "$cmd" == "-h" || "$cmd" == "--help" ]]; then
  usage
  exit 0
fi
shift || true

PATH_ARG=""
MAX_AGE="$DEFAULT_MAX_AGE"

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --path)
      require_value "$1" "${2:-}"
      PATH_ARG="$2"
      shift 2
      ;;
    --max-age)
      require_value "$1" "${2:-}"
      MAX_AGE="$2"
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

case "$cmd" in
  record)
    if [[ -z "$PATH_ARG" ]]; then
      echo "ERROR: record requires --path." >&2
      exit 64
    fi
    if [[ ! -f "$PATH_ARG" ]]; then
      echo "ERROR: capture path does not exist as a file: $PATH_ARG" >&2
      exit 66
    fi
    ensure_state_dir
    python3 - "$GATE_FILE" "$PATH_ARG" <<'PY'
import json
import os
import pathlib
import sys
from datetime import datetime, timezone

gate = pathlib.Path(sys.argv[1])
path = pathlib.Path(sys.argv[2]).expanduser().resolve()
now = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
st = path.stat()
data = {
    "ok": True,
    "path": str(path),
    "recorded_at": now,
    "bytes": int(st.st_size),
}
gate.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
os.chmod(gate, 0o600)
print(json.dumps(data, indent=2))
PY
    ;;
  ready)
    python3 - "$GATE_FILE" "$MAX_AGE" <<'PY'
import json
import pathlib
import sys
from datetime import datetime, timezone

gate = pathlib.Path(sys.argv[1])
max_age = int(sys.argv[2])
if not gate.is_file():
    print(json.dumps({"ready": False, "reason": "no_record"}))
    sys.exit(1)
try:
    data = json.loads(gate.read_text(encoding="utf-8"))
except Exception:
    print(json.dumps({"ready": False, "reason": "invalid_record"}))
    sys.exit(1)
if not data.get("ok"):
    print(json.dumps({"ready": False, "reason": "not_ok"}))
    sys.exit(1)
path = pathlib.Path(data.get("path") or "")
if not path.is_file():
    print(json.dumps({"ready": False, "reason": "path_missing", "path": str(path)}))
    sys.exit(1)
recorded = data.get("recorded_at")
if not recorded:
    print(json.dumps({"ready": False, "reason": "no_timestamp"}))
    sys.exit(1)
try:
    # support trailing Z
    ts = datetime.fromisoformat(recorded.replace("Z", "+00:00"))
except Exception:
    print(json.dumps({"ready": False, "reason": "bad_timestamp"}))
    sys.exit(1)
now = datetime.now(timezone.utc)
age = (now - ts).total_seconds()
if age < 0:
    age = 0
if age > max_age:
    print(json.dumps({"ready": False, "reason": "stale", "age_seconds": int(age), "max_age": max_age}))
    sys.exit(1)
print(json.dumps({
    "ready": True,
    "path": str(path),
    "age_seconds": int(age),
    "recorded_at": recorded,
    "bytes": data.get("bytes"),
}, indent=2))
sys.exit(0)
PY
    ;;
  status)
    if [[ ! -f "$GATE_FILE" ]]; then
      printf '%s\n' '{"ok":false,"path":null,"recorded_at":null,"bytes":null}'
      exit 0
    fi
    python3 - "$GATE_FILE" <<'PY'
import json
import pathlib
import sys
from datetime import datetime, timezone

gate = pathlib.Path(sys.argv[1])
try:
    data = json.loads(gate.read_text(encoding="utf-8"))
except Exception:
    data = {}
path = data.get("path")
exists = bool(path and pathlib.Path(path).is_file())
age = None
recorded = data.get("recorded_at")
if recorded:
    try:
        ts = datetime.fromisoformat(recorded.replace("Z", "+00:00"))
        age = int((datetime.now(timezone.utc) - ts).total_seconds())
        if age < 0:
            age = 0
    except Exception:
        age = None
out = {
    "ok": bool(data.get("ok")) and exists,
    "path": path,
    "path_exists": exists,
    "recorded_at": recorded,
    "age_seconds": age,
    "bytes": data.get("bytes"),
}
print(json.dumps(out, indent=2))
PY
    ;;
  clear)
    rm -f "$GATE_FILE"
    printf '%s\n' '{"cleared":true}'
    ;;
  *)
    echo "Unknown command: $cmd" >&2
    usage >&2
    exit 64
    ;;
esac
