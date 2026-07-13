#!/usr/bin/env bash
# Capture helper CLI contract tests.
# Error paths always run. Live success requires AGENT_VISION_LIVE=1 and a working runtime.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEFAULT_HOME="${HOME}/.local/share/agent-vision"
RUNTIME_HOME="${AGENT_VISION_HOME:-$DEFAULT_HOME}"

# Prefer installed runtime helper; fall back to repo dist for layout-relative checks.
if [[ -x "${RUNTIME_HOME}/dist/agent-vision-capture-file" ]]; then
  HELPER="${RUNTIME_HOME}/dist/agent-vision-capture-file"
elif [[ -x "${ROOT}/dist/agent-vision-capture-file" ]]; then
  HELPER="${ROOT}/dist/agent-vision-capture-file"
else
  echo "No agent-vision-capture-file found (install-runtime or build dist)." >&2
  exit 66
fi

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1" >&2; exit 1; }

# Missing --output
set +e
out="$("$HELPER" --json 2>&1)"
code=$?
set -e
[[ "$code" -ne 0 ]] || fail "missing --output should fail"
[[ "$out" == *invalid_output* || "$out" == *missing_output* || "$out" == *"--output"* ]] && pass "missing/invalid output error" || fail "unexpected missing-output message: $out"

# Relative path
set +e
out="$("$HELPER" --output relative.jpg --json 2>&1)"
code=$?
set -e
[[ "$code" -ne 0 ]] || fail "relative path should fail"
[[ "$out" == *invalid_output* || "$out" == *absolute* ]] && pass "relative path rejected" || fail "unexpected relative message: $out"

# Existing file
tmp="$(mktemp "${TMPDIR:-/tmp}/agent-vision-cli.XXXXXX.jpg")"
set +e
out="$("$HELPER" --output "$tmp" --json 2>&1)"
code=$?
set -e
rm -f "$tmp"
[[ "$code" -ne 0 ]] || fail "existing file should fail"
if [[ "$out" == *output_exists* ]] || [[ "$out" == *"already exists"* ]]; then
  pass "existing file rejected"
else
  fail "unexpected exists message: $out"
fi

if [[ "${AGENT_VISION_LIVE:-0}" != "1" ]]; then
  echo "Skipping live capture (set AGENT_VISION_LIVE=1 to enable)."
  echo "test-capture-file-cli: OK (errors only)"
  exit 0
fi

# Live success path
mkdir -p -m 700 "${HOME}/.agent-vision/frames"
OUT="${HOME}/.agent-vision/frames/agent-vision-live-$(date +%Y%m%d-%H%M%S).jpg"
rm -f "$OUT"
set +e
out="$("$HELPER" --output "$OUT" --json 2>&1)"
code=$?
set -e
echo "$out"
[[ "$code" -eq 0 ]] || fail "live capture exit $code"
[[ "$out" == *'"ok":true'* || "$out" == *'"ok": true'* ]] || fail "live capture not ok"
[[ -f "$OUT" ]] || fail "output file missing"
bytes="$(wc -c <"$OUT" | tr -d ' ')"
[[ "$bytes" -gt 100 ]] || fail "JPEG too small ($bytes)"
pass "live capture wrote $OUT ($bytes bytes)"
echo "test-capture-file-cli: OK (live)"
