#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT=""

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --output)
      if [[ "$#" -lt 2 ]]; then
        echo '{"ok":false,"error":{"code":"missing_output","message":"--output requires an absolute path."}}' >&2
        exit 64
      fi
      OUTPUT="$2"
      shift 2
      ;;
    --json)
      shift
      ;;
    *)
      echo '{"ok":false,"error":{"code":"unknown_argument","message":"Unsupported argument."}}' >&2
      exit 64
      ;;
  esac
done

if [[ -z "$OUTPUT" || "$OUTPUT" != /* ]]; then
  echo '{"ok":false,"error":{"code":"invalid_output","message":"--output must be an absolute path."}}' >&2
  exit 64
fi

if [[ -e "$OUTPUT" ]]; then
  echo '{"ok":false,"error":{"code":"output_exists","message":"Output file already exists."}}' >&2
  exit 73
fi

APP="$ROOT/dist/AgentVision.app"
if [[ ! -d "$APP" ]]; then
  echo '{"ok":false,"error":{"code":"app_missing","message":"AgentVision.app is missing from the installed plugin dist directory."}}' >&2
  exit 66
fi

TMP="$(mktemp -d "${TMPDIR:-/tmp}/agent-vision-capture.XXXXXX")"
RESULT_FIFO="$TMP/result"
mkfifo "$RESULT_FIFO"

cleanup() {
  if [[ -n "${CAT_PID:-}" ]] && kill -0 "$CAT_PID" 2>/dev/null; then
    kill "$CAT_PID" 2>/dev/null || true
  fi
  rm -rf "$TMP"
}
trap cleanup EXIT

cat "$RESULT_FIFO" &
CAT_PID="$!"

if ! open -W -n "$APP" --args capture-file "$OUTPUT" "$RESULT_FIFO"; then
  echo '{"ok":false,"error":{"code":"app_launch_failed","message":"AgentVision.app failed to launch for capture-file mode."}}' >&2
  exit 70
fi

for _ in {1..20}; do
  if ! kill -0 "$CAT_PID" 2>/dev/null; then
    wait "$CAT_PID"
    exit 0
  fi
  sleep 0.1
done

echo '{"ok":false,"error":{"code":"capture_result_missing","message":"AgentVision.app exited without returning capture-file JSON."}}' >&2
exit 70
