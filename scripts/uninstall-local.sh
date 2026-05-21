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

command -v python3 >/dev/null || { echo "python3 is required." >&2; exit 1; }

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

python3 - "$MARKETPLACE" "$OLD_SLUG" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
old_slug = sys.argv[2]
if not path.exists():
    raise SystemExit(0)

data = json.loads(path.read_text(encoding="utf-8"))
plugins = data.get("plugins")
if isinstance(plugins, list):
    data["plugins"] = [
        plugin
        for plugin in plugins
        if not (
            isinstance(plugin, dict)
            and plugin.get("name") in {"agent-vision", old_slug}
        )
    ]
path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY

python3 - "$CODEX_CONFIG" "$OLD_SLUG" <<'PY'
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
old_slug = sys.argv[2]
if not path.exists():
    raise SystemExit(0)

text = path.read_text(encoding="utf-8")

def remove_section(source: str, header: str) -> str:
    pattern = re.compile(rf"(?ms)^\[{re.escape(header)}\]\n.*?(?=^\[|\Z)")
    return pattern.sub("", source).strip() + ("\n" if source.strip() else "")

for header in [
    'plugins."agent-vision@local"',
    'plugins."agent-vision@openai-curated"',
    f'plugins."{old_slug}@local"',
    f'plugins."{old_slug}@openai-curated"',
    "mcp_servers.agent_vision",
    'mcp_servers."agent-vision"',
    "mcp_servers.codex_vision",
    f'mcp_servers."{old_slug}"',
]:
    text = remove_section(text, header)

path.write_text(text.rstrip() + "\n", encoding="utf-8")
PY

echo "Agent Vision local plugin files and Codex registration removed."
