#!/usr/bin/env bash
# Unit tests for turn-gate (no camera).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GATE="${ROOT}/scripts/agent-vision-turn-gate.sh"
FAIL=0

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1" >&2; FAIL=1; }

TMP_HOME="$(mktemp -d "${TMPDIR:-/tmp}/agent-vision-turn-gate.XXXXXX")"
cleanup() { rm -rf "$TMP_HOME"; }
trap cleanup EXIT
export HOME="$TMP_HOME"
chmod +x "$GATE"
bash -n "$GATE" && pass "bash -n turn-gate" || fail "bash -n turn-gate"

if ! "$GATE" ready >/dev/null 2>&1; then pass "ready fail-closed without record"; else fail "ready should fail without record"; fi

fake="$TMP_HOME/fake.jpg"
echo "not a real jpeg but a file" >"$fake"

out="$("$GATE" record --path "$fake")"
echo "$out" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["ok"] is True; assert d["path"]' \
  && pass "record success" || fail "record success"

if "$GATE" ready --max-age 600 >/dev/null; then pass "ready after record"; else fail "ready after record"; fi

status="$("$GATE" status)"
echo "$status" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["ok"] is True; assert d["path_exists"] is True' \
  && pass "status after record" || fail "status after record"

# Missing path → ready fails
rm -f "$fake"
if ! "$GATE" ready >/dev/null 2>&1; then pass "ready fails when path missing"; else fail "ready should fail when path missing"; fi

# Recreate and stale age
echo x >"$fake"
"$GATE" record --path "$fake" >/dev/null
# force old timestamp
python3 - <<PY
import json, pathlib
from datetime import datetime, timezone, timedelta
p = pathlib.Path("$HOME/.agent-vision/turn-gate.json")
d = json.loads(p.read_text())
old = (datetime.now(timezone.utc) - timedelta(seconds=900)).replace(microsecond=0).isoformat().replace("+00:00","Z")
d["recorded_at"] = old
p.write_text(json.dumps(d, indent=2)+"\n")
PY
if ! "$GATE" ready --max-age 60 >/dev/null 2>&1; then pass "ready fails when stale"; else fail "ready should fail when stale"; fi

"$GATE" clear >/dev/null
if ! "$GATE" ready >/dev/null 2>&1; then pass "ready fail after clear"; else fail "ready should fail after clear"; fi

# record rejects missing path
if ! "$GATE" record --path "$TMP_HOME/nope.jpg" >/dev/null 2>&1; then pass "record rejects missing path"; else fail "record should reject missing path"; fi

if [[ "$FAIL" -ne 0 ]]; then
  echo "test-agent-vision-turn-gate: FAILED" >&2
  exit 1
fi
echo "test-agent-vision-turn-gate: OK"
