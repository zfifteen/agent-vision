#!/usr/bin/env bash
# Install the Grok Build host adapter (skill + optional user plugin tree).
# Requires a separate runtime install (scripts/install-runtime.sh). Never starts the camera.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOST_SRC="${ROOT}/hosts/grok"
SKILL_SRC="${HOST_SRC}/skills/agent-vision"
PLUGIN_SRC="${HOST_SRC}"
USER_SKILL_DIR="${HOME}/.grok/skills/agent-vision"
USER_PLUGIN_DIR="${HOME}/.grok/plugins/agent-vision"
DRY_RUN=0
SKIP_PLUGIN=0

usage() {
  cat <<'EOF'
Usage: scripts/install-grok.sh [--dry-run] [--skill-only]

Installs the Agent Vision Grok skill to ~/.grok/skills/agent-vision and stages a
user plugin tree at ~/.grok/plugins/agent-vision (unless --skill-only).

Does not install the camera runtime, launch the camera, or register MCP servers.
Run scripts/install-runtime.sh first (or ensure AGENT_VISION_HOME is populated).
EOF
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --skill-only)
      SKIP_PLUGIN=1
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

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Agent Vision is macOS-only." >&2
  exit 1
fi

if [[ ! -f "${SKILL_SRC}/SKILL.md" ]]; then
  echo "Missing Grok skill at ${SKILL_SRC}/SKILL.md" >&2
  exit 66
fi
if [[ ! -f "${PLUGIN_SRC}/plugin.json" ]]; then
  echo "Missing Grok plugin.json at ${PLUGIN_SRC}/plugin.json" >&2
  exit 66
fi

# Static contract checks (same suite as CI-friendly L1 tests).
bash "${ROOT}/scripts/test-grok-adapter.sh"

if [[ "$DRY_RUN" == "1" ]]; then
  echo "Dry-run OK. Would install:"
  echo "  skill -> $USER_SKILL_DIR"
  if [[ "$SKIP_PLUGIN" != "1" ]]; then
    echo "  plugin -> $USER_PLUGIN_DIR"
  fi
  exit 0
fi

baseline_pids="$(pgrep -f 'agent-vision-capture-file|agent-vision-mcp|AgentVision.app|mcp-fifo' 2>/dev/null || true)"

mkdir -p "${HOME}/.grok/skills"
rm -rf "$USER_SKILL_DIR"
mkdir -p "$USER_SKILL_DIR"
cp "${SKILL_SRC}/SKILL.md" "${USER_SKILL_DIR}/SKILL.md"

if [[ "$SKIP_PLUGIN" != "1" ]]; then
  mkdir -p "${HOME}/.grok/plugins"
  rm -rf "$USER_PLUGIN_DIR"
  mkdir -p "${USER_PLUGIN_DIR}/skills/agent-vision"
  cp "${PLUGIN_SRC}/plugin.json" "${USER_PLUGIN_DIR}/plugin.json"
  cp "${SKILL_SRC}/SKILL.md" "${USER_PLUGIN_DIR}/skills/agent-vision/SKILL.md"
fi

# Refuse to add Agent Vision MCP to Grok config if present.
if [[ -f "${HOME}/.grok/config.toml" ]]; then
  if rg -n '\[mcp_servers\.agent-vision\]|\[mcp_servers\."agent-vision"\]' "${HOME}/.grok/config.toml" >/dev/null 2>&1; then
    echo "ERROR: ~/.grok/config.toml already registers an agent-vision MCP server. Remove it before installing." >&2
    exit 70
  fi
fi

after_pids="$(pgrep -f 'agent-vision-capture-file|agent-vision-mcp|AgentVision.app|mcp-fifo' 2>/dev/null || true)"
if [[ "$after_pids" != "$baseline_pids" ]]; then
  echo "ERROR: install-grok started an Agent Vision process (lifecycle violation)." >&2
  exit 70
fi

DEFAULT_HOME="${HOME}/.local/share/agent-vision"
RUNTIME_HOME="${AGENT_VISION_HOME:-$DEFAULT_HOME}"
if [[ ! -x "${RUNTIME_HOME}/dist/agent-vision-capture-file" ]]; then
  echo "WARNING: runtime helper not found at ${RUNTIME_HOME}/dist/agent-vision-capture-file"
  echo "  Run: scripts/install-runtime.sh"
else
  echo "Runtime helper present at ${RUNTIME_HOME}/dist/agent-vision-capture-file"
fi

echo "Grok adapter installed."
echo "  Skill:  $USER_SKILL_DIR"
if [[ "$SKIP_PLUGIN" != "1" ]]; then
  echo "  Plugin: $USER_PLUGIN_DIR"
  echo "  If the plugin does not load, enable it via /plugins or:"
  echo "    grok plugin install $USER_PLUGIN_DIR --trust"
  echo "  and ensure it is listed under [plugins] enabled when required."
fi
echo "  Slash:  /agent-vision snapshot"
echo "  Ship A: snapshot + disabled streaming only (roast/mood are Milestone 2)."
