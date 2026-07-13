#!/usr/bin/env bash
# Remove the host-neutral Agent Vision runtime home and PATH shim.
# Does not remove Codex or Grok host adapters (use uninstall-grok / Codex uninstall).
set -euo pipefail

DEFAULT_HOME="${HOME}/.local/share/agent-vision"
AGENT_VISION_HOME="${AGENT_VISION_HOME:-$DEFAULT_HOME}"
BIN_DIR="${HOME}/.local/bin"
SHIM="${BIN_DIR}/agent-vision-capture-file"
REMOVE_FRAMES=0

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --home)
      AGENT_VISION_HOME="$2"
      shift 2
      ;;
    --remove-frames)
      REMOVE_FRAMES=1
      shift
      ;;
    -h|--help)
      echo "Usage: scripts/uninstall-runtime.sh [--home DIR] [--remove-frames]"
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 64
      ;;
  esac
done

if [[ -e "$SHIM" ]]; then
  # Only remove shim if it points at our runtime or is our generated wrapper.
  if grep -q 'agent-vision-capture-file' "$SHIM" 2>/dev/null || [[ -L "$SHIM" ]]; then
    rm -f "$SHIM"
    echo "Removed shim: $SHIM"
  else
    echo "Left unexpected file in place: $SHIM" >&2
  fi
fi

if [[ -d "$AGENT_VISION_HOME" ]]; then
  rm -rf "$AGENT_VISION_HOME"
  echo "Removed runtime home: $AGENT_VISION_HOME"
else
  echo "Runtime home already absent: $AGENT_VISION_HOME"
fi

if [[ "$REMOVE_FRAMES" == "1" ]]; then
  rm -rf "${HOME}/.agent-vision"
  echo "Removed frame root: ${HOME}/.agent-vision"
else
  echo "Left frames at ${HOME}/.agent-vision/frames (pass --remove-frames to delete)."
fi

echo "Runtime uninstall complete. Grok/Codex host adapters were not modified."
