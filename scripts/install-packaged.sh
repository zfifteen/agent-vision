#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [[ -d "$SCRIPT_DIR/.codex-plugin" ]]; then
  ROOT="$SCRIPT_DIR"
else
  ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
fi
OLD_SLUG="codex""-vision"
OLD_VERSION="1.0.0"
VERSION="1.0.1"
PLUGIN_HOME="$HOME/plugins/agent-vision"
CACHE_HOME="$HOME/.codex/plugins/cache/local/agent-vision/$VERSION"
OLD_CACHE_HOME="$HOME/.codex/plugins/cache/local/agent-vision/$OLD_VERSION"
MARKETPLACE="$HOME/.agents/plugins/marketplace.json"
CODEX_CONFIG="$HOME/.codex/config.toml"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Agent Vision is macOS-only." >&2
  exit 1
fi

command -v codex >/dev/null || { echo "codex CLI is required." >&2; exit 1; }
command -v osascript >/dev/null || { echo "osascript is required." >&2; exit 1; }

for path in \
  "$ROOT/.codex-plugin/plugin.json" \
  "$ROOT/.mcp.json" \
  "$ROOT/assets" \
  "$ROOT/commands" \
  "$ROOT/skills" \
  "$ROOT/dist/AgentVision.app" \
  "$ROOT/dist/agent-vision-mcp" \
  "$ROOT/dist/agent-vision-capture-file"
do
  if [[ ! -e "$path" ]]; then
    echo "Packaged install is missing required artifact: $path" >&2
    exit 66
  fi
done

osascript -l JavaScript - "$ROOT" <<'JXA'
ObjC.import('Foundation')

function readJSON(path) {
  const text = ObjC.unwrap($.NSString.stringWithContentsOfFileEncodingError(path, $.NSUTF8StringEncoding, null))
  return JSON.parse(text)
}

function run(argv) {
  const root = argv[0]
  const plugin = readJSON(root + "/.codex-plugin/plugin.json")
  if (plugin.name !== "agent-vision") {
    throw new Error(".codex-plugin/plugin.json has wrong plugin name")
  }
  const mcp = readJSON(root + "/.mcp.json")
  const server = (((mcp || {}).mcpServers || {})["agent-vision"])
  if (!server || server.command !== "./dist/agent-vision-mcp") {
    throw new Error(".mcp.json has wrong agent-vision MCP command")
  }
}
JXA
/usr/bin/codesign --verify --deep --strict "$ROOT/dist/AgentVision.app" >/dev/null
chmod +x "$ROOT/dist/agent-vision-mcp" "$ROOT/dist/agent-vision-capture-file"

rm -rf "$PLUGIN_HOME"
mkdir -p "$PLUGIN_HOME"
cp -R "$ROOT/.codex-plugin" "$PLUGIN_HOME/.codex-plugin"
cp "$ROOT/.mcp.json" "$PLUGIN_HOME/.mcp.json"
cp -R "$ROOT/assets" "$PLUGIN_HOME/assets"
cp -R "$ROOT/commands" "$PLUGIN_HOME/commands"
cp -R "$ROOT/skills" "$PLUGIN_HOME/skills"
cp -R "$ROOT/dist" "$PLUGIN_HOME/dist"

rm -rf "$CACHE_HOME" "$OLD_CACHE_HOME"
mkdir -p "$CACHE_HOME"
cp -R "$ROOT/.codex-plugin" "$CACHE_HOME/.codex-plugin"
cp "$ROOT/.mcp.json" "$CACHE_HOME/.mcp.json"
cp -R "$ROOT/assets" "$CACHE_HOME/assets"
cp -R "$ROOT/commands" "$CACHE_HOME/commands"
cp -R "$ROOT/skills" "$CACHE_HOME/skills"
cp -R "$ROOT/dist" "$CACHE_HOME/dist"

mkdir -p "$(dirname "$MARKETPLACE")"
osascript -l JavaScript - "$MARKETPLACE" "$OLD_SLUG" <<'JXA'
ObjC.import('Foundation')

function readText(path) {
  if (!$.NSFileManager.defaultManager.fileExistsAtPath(path)) {
    return null
  }
  return ObjC.unwrap($.NSString.stringWithContentsOfFileEncodingError(path, $.NSUTF8StringEncoding, null))
}

function writeText(path, text) {
  $(text).writeToFileAtomicallyEncodingError(path, true, $.NSUTF8StringEncoding, null)
}

function run(argv) {
  const path = argv[0]
  const oldSlug = argv[1]
  const text = readText(path)
  const data = text === null ? {"name":"local","interface":{"displayName":"Local Plugins"},"plugins":[]} : JSON.parse(text)
  const entry = {
    "name": "agent-vision",
    "source": {
      "source": "local",
      "path": "./plugins/agent-vision"
    },
    "policy": {
      "installation": "INSTALLED_BY_DEFAULT",
      "authentication": "ON_INSTALL"
    },
    "category": "Productivity"
  }
  data.plugins = (data.plugins || []).filter(plugin => plugin.name !== "agent-vision" && plugin.name !== oldSlug)
  data.plugins.push(entry)
  writeText(path, JSON.stringify(data, null, 2) + "\n")
}
JXA

codex plugin marketplace add "$HOME" >/dev/null

mkdir -p "$(dirname "$CODEX_CONFIG")"
touch "$CODEX_CONFIG"
CONFIG_TMP="$(mktemp "${TMPDIR:-/tmp}/agent-vision-config.XXXXXX")"
awk -v old_slug="$OLD_SLUG" '
  /^\[/ {
    skip = (
      $0 == "[plugins.\"agent-vision@local\"]" ||
      $0 == "[plugins.\"agent-vision@openai-curated\"]" ||
      $0 == "[plugins.\"" old_slug "@local\"]" ||
      $0 == "[plugins.\"" old_slug "@openai-curated\"]" ||
      $0 == "[mcp_servers.agent_vision]" ||
      $0 == "[mcp_servers.\"agent-vision\"]" ||
      $0 == "[mcp_servers.codex_vision]" ||
      $0 == "[mcp_servers.\"" old_slug "\"]"
    )
  }
  !skip { print }
' "$CODEX_CONFIG" > "$CONFIG_TMP"
{
  sed -e '${/^$/d;}' "$CONFIG_TMP"
  printf '\n[plugins."agent-vision@local"]\n'
  printf 'enabled = true\n'
} > "$CODEX_CONFIG"
rm -f "$CONFIG_TMP"

rm -rf \
  "$HOME/plugins/$OLD_SLUG" \
  "$HOME/.codex/plugins/cache/local/$OLD_SLUG" \
  "$OLD_CACHE_HOME" \
  "$HOME/.codex/.tmp/plugins/plugins/$OLD_SLUG" \
  "$HOME/.codex/.tmp/plugins/plugins/agent-vision" \
  "$HOME/.codex/plugins/cache/openai-curated/$OLD_SLUG" \
  "$HOME/.codex/plugins/cache/openai-curated/agent-vision"

test -x "$CACHE_HOME/dist/agent-vision-mcp"
test -x "$CACHE_HOME/dist/agent-vision-capture-file"
/usr/bin/codesign --verify --deep --strict "$CACHE_HOME/dist/AgentVision.app" >/dev/null

echo "Agent Vision installed at $PLUGIN_HOME"
echo "Agent Vision cached at $CACHE_HOME"
echo "Agent Vision plugin registered in $CODEX_CONFIG"
echo "Open a new Codex chat or session before using /agent-vision."
