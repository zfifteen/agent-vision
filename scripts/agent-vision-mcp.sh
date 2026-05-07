#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/agent-vision.XXXXXX")"
IN_FIFO="$TMP/in"
OUT_FIFO="$TMP/out"
mkfifo "$IN_FIFO" "$OUT_FIFO"
APP_PID=""
OUT_PID=""

terminate_pid() {
  local pid="$1"
  if [[ -z "$pid" ]] || ! kill -0 "$pid" 2>/dev/null; then
    return 0
  fi

  kill "$pid" 2>/dev/null || true
  for _ in {1..20}; do
    if ! kill -0 "$pid" 2>/dev/null; then
      return 0
    fi
    sleep 0.1
  done

  if kill -0 "$pid" 2>/dev/null; then
    kill -KILL "$pid" 2>/dev/null || true
  fi
}

cleanup() {
  trap - EXIT INT TERM HUP
  terminate_pid "$OUT_PID"
  terminate_pid "$APP_PID"
  wait "$OUT_PID" 2>/dev/null || true
  rm -rf "$TMP"
}
trap cleanup EXIT
trap 'cleanup; exit 143' TERM
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 129' HUP

open -n "$ROOT/dist/AgentVision.app" --args mcp-fifo "$IN_FIFO" "$OUT_FIFO"
for _ in {1..50}; do
  APP_PID="$(ps -axo pid=,command= | awk -v in_fifo="$IN_FIFO" -v out_fifo="$OUT_FIFO" '
    /AgentVision/ && index($0, "mcp-fifo") && index($0, in_fifo) && index($0, out_fifo) {
      print $1
      exit
    }
  ' || true)"
  if [[ -n "$APP_PID" ]]; then
    break
  fi
  sleep 0.1
done

if [[ -z "$APP_PID" ]]; then
  echo "Agent Vision app did not launch for MCP FIFO mode." >&2
  exit 1
fi

cat "$OUT_FIFO" &
OUT_PID="$!"
cat > "$IN_FIFO"
wait "$OUT_PID"
