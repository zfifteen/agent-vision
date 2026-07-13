#!/usr/bin/env bash
# Install signed AgentVision.app + capture helper to a host-neutral runtime home.
# Does not start the camera, register MCP, or install Codex/Grok host adapters.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="1.0.3-grok-ship-a"
DEFAULT_HOME="${HOME}/.local/share/agent-vision"
AGENT_VISION_HOME="${AGENT_VISION_HOME:-$DEFAULT_HOME}"
FRAME_ROOT="${HOME}/.agent-vision"
BIN_DIR="${HOME}/.local/bin"
DRY_RUN=0
SOURCE_DIST="${ROOT}/dist"

usage() {
  cat <<'EOF'
Usage: scripts/install-runtime.sh [--dry-run] [--home DIR] [--source-dist DIR]

Installs AgentVision.app and agent-vision-capture-file into AGENT_VISION_HOME
(default: ~/.local/share/agent-vision). Installs a PATH shim at
~/.local/bin/agent-vision-capture-file when possible.

Does not launch the camera or register MCP servers.
EOF
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

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --home)
      require_value "--home" "${2:-}"
      AGENT_VISION_HOME="$2"
      shift 2
      ;;
    --source-dist)
      require_value "--source-dist" "${2:-}"
      SOURCE_DIST="$2"
      shift 2
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

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Agent Vision is macOS-only." >&2
  exit 1
fi

APP_SRC="${SOURCE_DIST}/AgentVision.app"
HELPER_SRC="${SOURCE_DIST}/agent-vision-capture-file"

if [[ ! -d "$APP_SRC" ]]; then
  echo "Missing AgentVision.app at: $APP_SRC" >&2
  exit 66
fi
if [[ ! -x "$HELPER_SRC" && ! -f "$HELPER_SRC" ]]; then
  echo "Missing agent-vision-capture-file at: $HELPER_SRC" >&2
  exit 66
fi

echo "Verifying codesign on source app..."
/usr/bin/codesign --verify --deep --strict "$APP_SRC"

if [[ "$DRY_RUN" == "1" ]]; then
  echo "Dry-run OK."
  echo "  Would install to: $AGENT_VISION_HOME"
  echo "  Would create frames root: $FRAME_ROOT (mode 0700)"
  echo "  Would install PATH shim: $BIN_DIR/agent-vision-capture-file"
  exit 0
fi

# Baseline process check: install must not start camera-capable helpers.
baseline_pids="$(pgrep -f 'agent-vision-capture-file|agent-vision-mcp|AgentVision.app|mcp-fifo' 2>/dev/null || true)"

mkdir -p "$AGENT_VISION_HOME/dist"
mkdir -p -m 700 "$FRAME_ROOT"
mkdir -p -m 700 "$FRAME_ROOT/frames"
mkdir -p "$BIN_DIR"

# Prefer copy without re-signing so TCC identity stays stable (R-I8).
rm -rf "${AGENT_VISION_HOME}/dist/AgentVision.app"
rm -f "${AGENT_VISION_HOME}/dist/agent-vision-capture-file"
cp -R "$APP_SRC" "${AGENT_VISION_HOME}/dist/AgentVision.app"
cp "$HELPER_SRC" "${AGENT_VISION_HOME}/dist/agent-vision-capture-file"
chmod +x "${AGENT_VISION_HOME}/dist/agent-vision-capture-file"

echo "Verifying codesign on installed app..."
/usr/bin/codesign --verify --deep --strict "${AGENT_VISION_HOME}/dist/AgentVision.app"

# PATH shim: evaluate HOME / AGENT_VISION_HOME at runtime (quoted heredoc).
SHIM="${BIN_DIR}/agent-vision-capture-file"
cat >"$SHIM" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
HOME_DIR="${AGENT_VISION_HOME:-$HOME/.local/share/agent-vision}"
HELPER="${HOME_DIR}/dist/agent-vision-capture-file"
if [[ ! -x "$HELPER" ]]; then
  echo "{\"ok\":false,\"error\":{\"code\":\"runtime_missing\",\"message\":\"Agent Vision runtime helper not found at $HELPER. Run scripts/install-runtime.sh (or install the packaged runtime).\"}}" >&2
  exit 66
fi
exec "$HELPER" "$@"
EOF
chmod +x "$SHIM"

cat >"${AGENT_VISION_HOME}/INSTALL_META.txt" <<EOF
agent_vision_runtime_version=${VERSION}
installed_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
agent_vision_home=${AGENT_VISION_HOME}
source_dist=${SOURCE_DIST}
frames=${FRAME_ROOT}/frames
shim=${SHIM}
EOF

after_pids="$(pgrep -f 'agent-vision-capture-file|agent-vision-mcp|AgentVision.app|mcp-fifo' 2>/dev/null || true)"
if [[ "$after_pids" != "$baseline_pids" ]]; then
  echo "ERROR: install-runtime started an Agent Vision process (lifecycle violation)." >&2
  echo "baseline: $baseline_pids" >&2
  echo "after:    $after_pids" >&2
  exit 70
fi

echo "Agent Vision runtime installed."
echo "  AGENT_VISION_HOME=$AGENT_VISION_HOME"
echo "  Helper: $AGENT_VISION_HOME/dist/agent-vision-capture-file"
echo "  Shim:   $SHIM"
echo "  Frames: $FRAME_ROOT/frames"
echo "  Ensure $BIN_DIR is on PATH for the shim name to resolve."
echo "  Host adapters: scripts/install-grok.sh (Grok) or existing Codex installer."
