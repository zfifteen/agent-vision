#!/usr/bin/env bash
# Unit tests for frame purge (no camera).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PURGE="${ROOT}/scripts/agent-vision-purge-frames.sh"
FAIL=0

pass() { echo "PASS: $1"; }
fail() { echo "FAIL: $1" >&2; FAIL=1; }

TMP_HOME="$(mktemp -d "${TMPDIR:-/tmp}/agent-vision-purge.XXXXXX")"
cleanup() { rm -rf "$TMP_HOME"; }
trap cleanup EXIT
export HOME="$TMP_HOME"
chmod +x "$PURGE"
bash -n "$PURGE" && pass "bash -n purge" || fail "bash -n purge"

mkdir -p "$HOME/.agent-vision/frames" "$HOME/.codex/agent-vision/frames"
old="$HOME/.agent-vision/frames/old.jpg"
new="$HOME/.agent-vision/frames/new.jpg"
codex="$HOME/.codex/agent-vision/frames/c.jpg"
echo old >"$old"
echo new >"$new"
echo c >"$codex"
# age old file
touch -t 202001010101 "$old"

dry="$("$PURGE" --ttl-days 30 --dry-run --all)"
echo "$dry" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["dry_run"] is True; assert d["would_delete_count"]>=1' \
  && pass "dry-run finds old frames" || fail "dry-run finds old frames"
test -f "$old" && pass "dry-run did not delete" || fail "dry-run deleted unexpectedly"

"$PURGE" --ttl-days 30 --grok >/dev/null
test ! -f "$old" && pass "purge deleted old grok frame" || fail "old frame not deleted"
test -f "$new" && pass "purge kept recent frame" || fail "recent frame deleted"
test -f "$codex" && pass "codex untouched without --codex/--all" || fail "codex wrongly deleted"

"$PURGE" --ttl-days 0 --all >/dev/null
test ! -f "$new" && test ! -f "$codex" && pass "ttl 0 deletes all" || fail "ttl 0 did not delete all"

if [[ "$FAIL" -ne 0 ]]; then
  echo "test-agent-vision-purge-frames: FAILED" >&2
  exit 1
fi
echo "test-agent-vision-purge-frames: OK"
