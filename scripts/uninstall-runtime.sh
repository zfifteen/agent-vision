#!/usr/bin/env bash
# Remove the host-neutral Agent Vision runtime home and PATH shim.
# Does not remove Codex or Grok host adapters (use uninstall-grok / Codex uninstall).
set -euo pipefail

DEFAULT_HOME="${HOME}/.local/share/agent-vision"
AGENT_VISION_HOME="${AGENT_VISION_HOME:-$DEFAULT_HOME}"
BIN_DIR="${HOME}/.local/bin"
SHIM="${BIN_DIR}/agent-vision-capture-file"
REMOVE_FRAMES=0

usage() {
  echo "Usage: scripts/uninstall-runtime.sh [--home DIR] [--remove-frames]"
}

require_value() {
  local opt="$1"
  local val="${2:-}"
  if [[ -z "$val" || "$val" == -* ]]; then
    echo "ERROR: $opt requires a path argument." >&2
    usage >&2
    exit 64
  fi
}

# Refuse paths that would make rm -rf catastrophic or ambiguous.
assert_safe_runtime_home() {
  local path="$1"
  if [[ -z "$path" ]]; then
    echo "ERROR: runtime home path is empty." >&2
    exit 64
  fi
  if [[ "$path" != /* ]]; then
    echo "ERROR: runtime home must be an absolute path: $path" >&2
    exit 64
  fi
  case "$path" in
    /|/Users|/home|"$HOME"|"$HOME/"|"$HOME/."|"$HOME/..")
      echo "ERROR: refusing to delete unsafe runtime home path: $path" >&2
      exit 64
      ;;
  esac
  # Never treat a git work tree / source checkout as a runtime home.
  if [[ -d "${path}/.git" || -f "${path}/.git" ]]; then
    echo "ERROR: refusing to delete a git work tree as runtime home: $path" >&2
    exit 64
  fi
  # Require positive evidence of an *installed* runtime — not basename alone
  # (basename agent-vision would match a source clone path).
  if [[ ! -f "${path}/INSTALL_META.txt" && ! -d "${path}/dist/AgentVision.app" ]]; then
    echo "ERROR: refusing to delete path that is not an Agent Vision runtime home: $path" >&2
    echo "  Expected INSTALL_META.txt and/or dist/AgentVision.app under the path." >&2
    exit 64
  fi
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --home)
      require_value "--home" "${2:-}"
      AGENT_VISION_HOME="$2"
      shift 2
      ;;
    --remove-frames)
      REMOVE_FRAMES=1
      shift
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

assert_safe_runtime_home "$AGENT_VISION_HOME"

if [[ -e "$SHIM" ]]; then
  remove_shim=0
  if [[ -L "$SHIM" ]]; then
    target="$(readlink "$SHIM" 2>/dev/null || true)"
    case "$target" in
      *agent-vision*/*agent-vision-capture-file|*agent-vision/dist/agent-vision-capture-file)
        remove_shim=1
        ;;
    esac
  elif [[ -f "$SHIM" ]] && grep -q 'Agent Vision runtime helper not found' "$SHIM" 2>/dev/null; then
    # Generated wrapper text from install-runtime.sh
    remove_shim=1
  elif [[ -f "$SHIM" ]] && grep -q 'HOME/\.local/share/agent-vision' "$SHIM" 2>/dev/null && grep -q 'agent-vision-capture-file' "$SHIM" 2>/dev/null; then
    remove_shim=1
  fi

  if [[ "$remove_shim" == "1" ]]; then
    rm -f "$SHIM"
    echo "Removed shim: $SHIM"
  else
    echo "Left non-Agent-Vision file/symlink in place: $SHIM" >&2
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
