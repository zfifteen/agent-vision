#!/usr/bin/env bash
set -euo pipefail

OLD_SLUG="codex""-vision"
PLUGIN_HOME="$HOME/plugins/agent-vision"
CACHE_HOME="$HOME/.codex/plugins/cache/local/agent-vision/1.0.3"
OLD_RUNTIME_CACHE_HOME="$HOME/.codex/plugins/cache/local/agent-vision/1.0.2"
OLD_CACHE_HOME="$HOME/.codex/plugins/cache/local/agent-vision/1.0.1"
LEGACY_CACHE_HOME="$HOME/.codex/plugins/cache/local/agent-vision/1.0.0"
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
  osascript -l JavaScript - "$CODEX_CONFIG" "$OLD_SLUG" <<'JXA'
ObjC.import('Foundation')

function readText(path) {
  return ObjC.unwrap($.NSString.stringWithContentsOfFileEncodingError(path, $.NSUTF8StringEncoding, null))
}

function writeText(path, text) {
  $(text).writeToFileAtomicallyEncodingError(path, true, $.NSUTF8StringEncoding, null)
}

function removeSection(text, header) {
  const escaped = header.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")
  const pattern = new RegExp("^\\[" + escaped + "\\]\\n[\\s\\S]*?(?=^\\[|\\s*$)", "gm")
  return text.replace(pattern, "")
}

function run(argv) {
  const path = argv[0]
  const oldSlug = argv[1]
  let text = readText(path)
  const headers = [
    'plugins."agent-vision@local"',
    'plugins."agent-vision@openai-curated"',
    'plugins."' + oldSlug + '@local"',
    'plugins."' + oldSlug + '@openai-curated"',
    'mcp_servers.agent_vision',
    'mcp_servers."agent-vision"',
    'mcp_servers.codex_vision',
    'mcp_servers."' + oldSlug + '"'
  ]
  for (const header of headers) {
    text = removeSection(text, header)
  }
  writeText(path, text.replace(/\s+$/g, "") + "\n")
}
JXA
fi

rm -rf \
  "$PLUGIN_HOME" \
  "$CACHE_HOME" \
  "$OLD_RUNTIME_CACHE_HOME" \
  "$OLD_CACHE_HOME" \
  "$LEGACY_CACHE_HOME" \
  "$HOME/plugins/$OLD_SLUG" \
  "$HOME/.codex/plugins/cache/local/$OLD_SLUG" \
  "$HOME/.codex/.tmp/plugins/plugins/$OLD_SLUG" \
  "$HOME/.codex/.tmp/plugins/plugins/agent-vision" \
  "$HOME/.codex/plugins/cache/openai-curated/$OLD_SLUG" \
  "$HOME/.codex/plugins/cache/openai-curated/agent-vision"

echo "Agent Vision local plugin files and Codex registration removed."
