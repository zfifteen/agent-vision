#!/usr/bin/env bash
# Mechanical turn gate: per-turn capture record; fail-closed ready.
# Never launches the camera or AgentVision.app.
set -euo pipefail

STATE_DIR="${HOME}/.agent-vision"
GATE_FILE="${STATE_DIR}/turn-gate.json"
DEFAULT_MAX_AGE=600

usage() {
  cat <<'EOF'
Usage: agent-vision-turn-gate.sh <command> [options]

Commands:
  begin                Start a new turn (invalidates prior ready).
  record --path PATH   Record a successful capture for a fresh/open turn.
                       Path must exist as a file.
  ready [--max-age SEC]
                       Exit 0 only if the CURRENT turn has an unconsumed successful
                       record, the file still exists, and age <= max-age (default 600).
                       On success, CONSUMES the record so a later turn cannot reuse it
                       without a new record. Fail-closed otherwise (exit 1).
  status               Print gate JSON (always exit 0). Does not consume.
  clear                Clear the gate record.

Per-turn isolation:
  - begin invalidates ready until record.
  - ready is single-use: after a successful ready, another ready fails until
    record runs again (even if the capture file still exists within max-age).

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
  begin)
    ensure_state_dir
    python3 - "$GATE_FILE" <<'PY'
import json
import os
import pathlib
import sys
import uuid
from datetime import datetime, timezone

gate = pathlib.Path(sys.argv[1])
prev = {}
if gate.is_file():
    try:
        prev = json.loads(gate.read_text(encoding="utf-8"))
    except Exception:
        prev = {}
now = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
turn_id = str(uuid.uuid4())
data = {
    "turn_id": turn_id,
    "recorded_for_turn": None,
    "ok": False,
    "consumed": False,
    "path": prev.get("path"),
    "recorded_at": prev.get("recorded_at"),
    "bytes": prev.get("bytes"),
    "begun_at": now,
    "last_capture_path": prev.get("path") or prev.get("last_capture_path"),
    "last_capture_at": prev.get("recorded_at") or prev.get("last_capture_at"),
}
gate.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
os.chmod(gate, 0o600)
print(json.dumps(data, indent=2))
PY
    ;;
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
import uuid
from datetime import datetime, timezone

gate = pathlib.Path(sys.argv[1])
path = pathlib.Path(sys.argv[2]).expanduser().resolve()
now = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")

if gate.is_file():
    try:
        data = json.loads(gate.read_text(encoding="utf-8"))
    except Exception:
        data = {}
else:
    data = {}

turn_id = data.get("turn_id")
# Open a new turn when: no turn, already recorded+unconsumed, or already consumed.
need_new = (
    not turn_id
    or data.get("consumed") is True
    or data.get("recorded_for_turn") == turn_id
)
if need_new:
    turn_id = str(uuid.uuid4())
    data["turn_id"] = turn_id
    data["begun_at"] = now

st = path.stat()
data.update({
    "recorded_for_turn": turn_id,
    "ok": True,
    "consumed": False,
    "path": str(path),
    "recorded_at": now,
    "bytes": int(st.st_size),
    "last_capture_path": str(path),
    "last_capture_at": now,
})
gate.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
os.chmod(gate, 0o600)
print(json.dumps(data, indent=2))
PY
    ;;
  ready)
    python3 - "$GATE_FILE" "$MAX_AGE" <<'PY'
import json
import os
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

turn_id = data.get("turn_id")
recorded_for = data.get("recorded_for_turn")
if not turn_id:
    print(json.dumps({"ready": False, "reason": "no_turn"}))
    sys.exit(1)
if data.get("consumed") is True:
    print(json.dumps({
        "ready": False,
        "reason": "already_consumed",
        "turn_id": turn_id,
        "hint": "call record again for this turn (or begin then record)",
    }))
    sys.exit(1)
if recorded_for != turn_id:
    print(json.dumps({
        "ready": False,
        "reason": "no_record_for_current_turn",
        "turn_id": turn_id,
        "recorded_for_turn": recorded_for,
    }))
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
    ts = datetime.fromisoformat(recorded.replace("Z", "+00:00"))
except Exception:
    print(json.dumps({"ready": False, "reason": "bad_timestamp"}))
    sys.exit(1)
now = datetime.now(timezone.utc)
age = max(0, (now - ts).total_seconds())
if age > max_age:
    print(json.dumps({"ready": False, "reason": "stale", "age_seconds": int(age), "max_age": max_age}))
    sys.exit(1)

# Consume so a later turn cannot reuse this record without a new capture record.
consumed_at = now.replace(microsecond=0).isoformat().replace("+00:00", "Z")
data["consumed"] = True
data["consumed_at"] = consumed_at
data["ok"] = False  # must re-record for next ready
gate.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
os.chmod(gate, 0o600)

print(json.dumps({
    "ready": True,
    "path": str(path),
    "turn_id": turn_id,
    "age_seconds": int(age),
    "recorded_at": recorded,
    "bytes": data.get("bytes"),
    "consumed": True,
}, indent=2))
sys.exit(0)
PY
    ;;
  status)
    if [[ ! -f "$GATE_FILE" ]]; then
      printf '%s\n' '{"ok":false,"turn_id":null,"recorded_for_turn":null,"consumed":false,"path":null,"recorded_at":null,"bytes":null}'
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
turn_id = data.get("turn_id")
recorded_for = data.get("recorded_for_turn")
consumed = bool(data.get("consumed"))
ready = bool(data.get("ok")) and exists and turn_id and recorded_for == turn_id and not consumed
age = None
recorded = data.get("recorded_at") or data.get("last_capture_at")
if recorded:
    try:
        ts = datetime.fromisoformat(recorded.replace("Z", "+00:00"))
        age = max(0, int((datetime.now(timezone.utc) - ts).total_seconds()))
    except Exception:
        age = None
out = {
    "ok": ready,
    "turn_id": turn_id,
    "recorded_for_turn": recorded_for,
    "consumed": consumed,
    "path": path or data.get("last_capture_path"),
    "path_exists": exists,
    "recorded_at": data.get("recorded_at") or data.get("last_capture_at"),
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
