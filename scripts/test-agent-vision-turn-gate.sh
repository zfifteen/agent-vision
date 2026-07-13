#!/usr/bin/env bash
# Unit tests for turn-gate (no camera). Drives shipped scripts/agent-vision-turn-gate.sh.
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
echo "$out" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["ok"] is True; assert d["path"]; assert d.get("consumed") is False' \
  && pass "record success" || fail "record success"

if "$GATE" ready --max-age 600 >/dev/null; then pass "ready after record"; else fail "ready after record"; fi

# Critical: same capture file still exists within max-age, but ready was consumed —
# a later turn must NOT pass without a new record.
if ! "$GATE" ready >/dev/null 2>&1; then
  pass "ready fails on later turn without re-record (consumed)"
else
  fail "ready must fail on later turn without re-record even if file exists"
fi

# begin also invalidates until record
"$GATE" record --path "$fake" >/dev/null
if "$GATE" ready >/dev/null; then pass "ready after re-record"; else fail "ready after re-record"; fi
"$GATE" begin >/dev/null
if ! "$GATE" ready >/dev/null 2>&1; then
  pass "ready fails after begin until record"
else
  fail "ready should fail after begin without record"
fi
# Prior file still on disk within max-age — still must fail
if ! "$GATE" ready --max-age 600 >/dev/null 2>&1; then
  pass "ready fails after begin even with existing file in max-age"
else
  fail "ready must not reuse prior capture after begin"
fi
"$GATE" record --path "$fake" >/dev/null
if "$GATE" ready >/dev/null; then pass "ready after begin+record"; else fail "ready after begin+record"; fi

status="$("$GATE" status)"
echo "$status" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert "turn_id" in d; assert "consumed" in d' \
  && pass "status has turn fields" || fail "status has turn fields"

# Missing path → ready fails
"$GATE" record --path "$fake" >/dev/null
rm -f "$fake"
if ! "$GATE" ready >/dev/null 2>&1; then pass "ready fails when path missing"; else fail "ready should fail when path missing"; fi

# Recreate and stale age
echo x >"$fake"
"$GATE" record --path "$fake" >/dev/null
python3 - <<PY
import json, pathlib
from datetime import datetime, timezone, timedelta
p = pathlib.Path("$HOME/.agent-vision/turn-gate.json")
d = json.loads(p.read_text())
old = (datetime.now(timezone.utc) - timedelta(seconds=900)).replace(microsecond=0).isoformat().replace("+00:00","Z")
d["recorded_at"] = old
d["consumed"] = False
d["ok"] = True
p.write_text(json.dumps(d, indent=2)+"\n")
PY
if ! "$GATE" ready --max-age 60 >/dev/null 2>&1; then pass "ready fails when stale"; else fail "ready should fail when stale"; fi

"$GATE" clear >/dev/null
if ! "$GATE" ready >/dev/null 2>&1; then pass "ready fail after clear"; else fail "ready should fail after clear"; fi

if ! "$GATE" record --path "$TMP_HOME/nope.jpg" >/dev/null 2>&1; then pass "record rejects missing path"; else fail "record should reject missing path"; fi

if [[ "$FAIL" -ne 0 ]]; then
  echo "test-agent-vision-turn-gate: FAILED" >&2
  exit 1
fi
echo "test-agent-vision-turn-gate: OK"
