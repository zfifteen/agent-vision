#!/usr/bin/env bash
set -euo pipefail

OLD_SLUG="codex""-vision"
PLUGIN_HOME="$HOME/plugins/agent-vision"
CACHE_HOME="$HOME/.codex/plugins/cache/local/agent-vision/1.0.1"
OLD_CACHE_HOME="$HOME/.codex/plugins/cache/local/agent-vision/1.0.0"
MARKETPLACE="$HOME/.agents/plugins/marketplace.json"
CODEX_CONFIG="$HOME/.codex/config.toml"

command -v osascript >/dev/null || { echo "osascript is required." >&2; exit 1; }

if [[ -f "$MARKETPLACE" ]]; then
  osascript -l JavaScript - "$MARKETPLACE" "$OLD_SLUG" <<'JXA'
ObjC.import('Foundation')

function readText(path) {
  return ObjC.unwrap($.NSString.stringWithContentsOfFileEncodingError(path, $.NSUTF8StringEncoding, null))
}

function writeText(path, text) {
  $(text).writeToFileAtomicallyEncodingError(path, true, $.NSUTF8StringEncoding, null)
}

function run(argv) {
  const path = argv[0]
  const oldSlug = argv[1]
  const data = JSON.parse(readText(path))
  data.plugins = (data.plugins || []).filter(plugin => plugin.name !== "agent-vision" && plugin.name !== oldSlug)
  writeText(path, JSON.stringify(data, null, 2) + "\n")
}
JXA
fi

if [[ -f "$CODEX_CONFIG" ]]; then
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
  mv "$CONFIG_TMP" "$CODEX_CONFIG"
fi

rm -rf \
  "$PLUGIN_HOME" \
  "$CACHE_HOME" \
  "$OLD_CACHE_HOME" \
  "$HOME/plugins/$OLD_SLUG" \
  "$HOME/.codex/plugins/cache/local/$OLD_SLUG" \
  "$HOME/.codex/.tmp/plugins/plugins/$OLD_SLUG" \
  "$HOME/.codex/.tmp/plugins/plugins/agent-vision" \
  "$HOME/.codex/plugins/cache/openai-curated/$OLD_SLUG" \
  "$HOME/.codex/plugins/cache/openai-curated/agent-vision"

echo "Agent Vision local plugin files and Codex registration removed."
