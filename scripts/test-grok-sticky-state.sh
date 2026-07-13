#!/usr/bin/env bash
# Unit tests for sticky session state scripts. No camera.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
STICKY="${ROOT}/scripts/agent-vision-sticky.sh"
FAIL=0

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1" >&2; FAIL=1; }

command -v python3 >/dev/null || { echo "python3 required" >&2; exit 1; }
[[ -x "$STICKY" ]] || chmod +x "$STICKY"

# Isolate state file in a temp HOME
TMP_HOME="$(mktemp -d "${TMPDIR:-/tmp}/agent-vision-sticky.XXXXXX")"
cleanup() { rm -rf "$TMP_HOME"; }
trap cleanup EXIT
export HOME="$TMP_HOME"

before="$(pgrep -f 'agent-vision-capture-file|AgentVision.app|agent-vision-mcp' 2>/dev/null || true)"

bash -n "$STICKY" && pass "bash -n sticky" || fail "bash -n sticky"

if ! "$STICKY" is-on; then pass "default is-on false"; else fail "default is-on should be false"; fi

out="$("$STICKY" on --host grok --mode mood)"
echo "$out" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["sticky"] is True; assert d["host"]=="grok"; assert d["mode"]=="mood"' \
  && pass "on writes sticky true for grok" || fail "on writes sticky true for grok"

if "$STICKY" is-on; then pass "is-on after arm"; else fail "is-on after arm"; fi

status="$("$STICKY" status)"
echo "$status" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["sticky"] is True' \
  && pass "status sticky true" || fail "status sticky true"

"$STICKY" off >/dev/null
if ! "$STICKY" is-on; then pass "is-on after off"; else fail "is-on after off"; fi

out="$("$STICKY" on --host codex --mode snapshot)"
echo "$out" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["host"]=="codex"; assert d["mode"]=="snapshot"' \
  && pass "on codex snapshot" || fail "on codex snapshot"

"$STICKY" off --host codex >/dev/null
echo "$("$STICKY" status)" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["sticky"] is False' \
  && pass "off clears sticky" || fail "off clears sticky"

# Invalid host
if "$STICKY" on --host nope --mode mood >/dev/null 2>&1; then fail "invalid host rejected"; else pass "invalid host rejected"; fi

after="$(pgrep -f 'agent-vision-capture-file|AgentVision.app|agent-vision-mcp' 2>/dev/null || true)"
if [[ "$before" == "$after" ]]; then pass "no camera process started"; else fail "camera process appeared during sticky tests"; fi

if [[ "$FAIL" -ne 0 ]]; then
  echo "test-grok-sticky-state: FAILED" >&2
  exit 1
fi
echo "test-grok-sticky-state: OK"
