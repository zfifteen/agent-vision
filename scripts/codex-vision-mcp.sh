#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/codex-vision.XXXXXX")"
IN_FIFO="$TMP/in"
OUT_FIFO="$TMP/out"
mkfifo "$IN_FIFO" "$OUT_FIFO"

cleanup() {
  rm -rf "$TMP"
}
trap cleanup EXIT

open -n "$ROOT/dist/CodexVision.app" --args mcp-fifo "$IN_FIFO" "$OUT_FIFO"
APP_PID=""
for _ in {1..50}; do
  APP_PID="$(ps -axo pid=,command= | awk -v in_fifo="$IN_FIFO" -v out_fifo="$OUT_FIFO" '
    /CodexVision/ && index($0, "mcp-fifo") && index($0, in_fifo) && index($0, out_fifo) {
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
  echo "Codex Vision app did not launch for MCP FIFO mode." >&2
  exit 1
fi

cat "$OUT_FIFO" &
OUT_PID="$!"
cat > "$IN_FIFO"
wait "$OUT_PID"
