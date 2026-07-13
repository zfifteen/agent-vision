#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OLD_SLUG="codex""-vision"
PREV_PACKAGE_VERSION="1.0.3"
OLD_RUNTIME_VERSION="1.0.2"
OLD_VERSION="1.0.1"
LEGACY_VERSION="1.0.0"
VERSION="1.5.0"
DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Agent Vision is macOS-only." >&2
  exit 1
fi

command -v swift >/dev/null || { echo "swift is required." >&2; exit 1; }
command -v python3 >/dev/null || { echo "python3 is required." >&2; exit 1; }

python3 - "$ROOT" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
for rel in [".codex-plugin/plugin.json", ".mcp.json"]:
    path = root / rel
    data = json.loads(path.read_text(encoding="utf-8"))
    if rel == ".codex-plugin/plugin.json" and data["name"] != "agent-vision":
        raise SystemExit(f"{rel} has wrong plugin name")
    if rel == ".codex-plugin/plugin.json" and "mcpServers" in data:
        raise SystemExit(f"{rel} must not advertise Agent Vision MCP servers in 1.5.0")
    if rel == ".mcp.json":
        if data.get("mcpServers", {}).get("agent-vision") is not None:
            raise SystemExit(f"{rel} must not register an agent-vision MCP server in 1.5.0")

command = root / "commands" / "agent-vision.md"
text = command.read_text(encoding="utf-8")
if not text.startswith("---\n"):
    raise SystemExit("commands/agent-vision.md must start with YAML frontmatter so Codex can index the slash command")
if "\ndescription: HARD GATE sticky Agent Vision" not in text and "HARD GATE sticky Agent Vision" not in text:
    raise SystemExit("commands/agent-vision.md has wrong slash command description")
if "\nargument-hint: mood|snapshot|roast|off|status|streaming\n" not in text:
    raise SystemExit("commands/agent-vision.md has wrong slash command argument hint")
required_command_snippets = [
    "HARD GATE",
    "turn-gate begin",
    "USE image in reasoning",
    "ready` is single-use",
    "Topic irrelevant",
    "Blind-identical INVALID",
    "Ambiguity burst",
    "Playbooks",
    "agent-vision-purge-frames",
]
for snippet in required_command_snippets:
    if snippet not in text:
        raise SystemExit(f"commands/agent-vision.md is missing required slash command contract: {snippet}")

skill = root / "skills" / "camera-control" / "SKILL.md"
skill_text = skill.read_text(encoding="utf-8")
required_skill_snippets = [
    "CRITICAL WHILE ARMED",
    "HARD GATE",
    "USE",
    "turn-gate",
    "Disposition playbooks",
    "Ambiguity burst",
    "agent-vision-capture-file",
    "frustrated_or_blocked",
    "codex exec",
    "Topic irrelevant",
    "FORBIDDEN",
]
for snippet in required_skill_snippets:
    if snippet not in skill_text:
        raise SystemExit(f"skills/camera-control/SKILL.md is missing required camera contract: {snippet}")
PY

if [[ "$DRY_RUN" == "1" ]]; then
  swift build --disable-sandbox -c release --package-path "$ROOT" >/dev/null
  echo "Agent Vision dry-run validation succeeded."
  exit 0
fi

command -v codex >/dev/null || { echo "codex CLI is required." >&2; exit 1; }
SIGN_IDENTITY="$(security find-identity -v -p codesigning 2>/dev/null | awk -F'\"' '/Apple Development/ { print $2; exit }')"
if [[ -z "$SIGN_IDENTITY" ]]; then
  echo "An Apple Development code signing identity is required so macOS preserves Camera permission for AgentVision.app." >&2
  exit 1
fi

BUILD_DIR="$(swift build --disable-sandbox -c release --package-path "$ROOT" --show-bin-path)"
swift build --disable-sandbox -c release --package-path "$ROOT"
APP="$ROOT/dist/AgentVision.app"
PLUGIN_HOME="$HOME/plugins/agent-vision"
CACHE_HOME="$HOME/.codex/plugins/cache/local/agent-vision/$VERSION"
PREV_PACKAGE_CACHE_HOME="$HOME/.codex/plugins/cache/local/agent-vision/$PREV_PACKAGE_VERSION"
OLD_CACHE_HOME="$HOME/.codex/plugins/cache/local/agent-vision/$OLD_VERSION"
OLD_RUNTIME_CACHE_HOME="$HOME/.codex/plugins/cache/local/agent-vision/$OLD_RUNTIME_VERSION"
LEGACY_CACHE_HOME="$HOME/.codex/plugins/cache/local/agent-vision/$LEGACY_VERSION"
MARKETPLACE="$HOME/.agents/plugins/marketplace.json"
CODEX_CONFIG="$HOME/.codex/config.toml"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
rm -f "$ROOT/dist/prompt-input-check.json"
cp "$BUILD_DIR/AgentVision" "$APP/Contents/MacOS/AgentVision"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>AgentVision</string>
  <key>CFBundleIdentifier</key>
  <string>works.velocity.agent-vision</string>
  <key>CFBundleName</key>
  <string>Agent Vision</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.5.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>NSCameraUsageDescription</key>
  <string>Agent Vision lets a local coding agent request camera frames when you explicitly use its slash command.</string>
</dict>
</plist>
PLIST
plutil -lint "$APP/Contents/Info.plist" >/dev/null
/usr/bin/codesign --force --sign "$SIGN_IDENTITY" "$APP" >/dev/null
rm -f "$ROOT/dist/agent-vision-mcp"
cp "$ROOT/scripts/agent-vision-capture-file.sh" "$ROOT/dist/agent-vision-capture-file"
chmod +x "$ROOT/dist/agent-vision-capture-file"

rm -rf "$PLUGIN_HOME"
mkdir -p "$PLUGIN_HOME"
cp -R "$ROOT/.codex-plugin" "$PLUGIN_HOME/.codex-plugin"
cp "$ROOT/.mcp.json" "$PLUGIN_HOME/.mcp.json"
cp -R "$ROOT/assets" "$PLUGIN_HOME/assets"
cp -R "$ROOT/commands" "$PLUGIN_HOME/commands"
cp -R "$ROOT/skills" "$PLUGIN_HOME/skills"
cp -R "$ROOT/dist" "$PLUGIN_HOME/dist"

rm -rf "$CACHE_HOME" "$PREV_PACKAGE_CACHE_HOME" "$OLD_RUNTIME_CACHE_HOME" "$OLD_CACHE_HOME" "$LEGACY_CACHE_HOME"
mkdir -p "$CACHE_HOME"
cp -R "$ROOT/.codex-plugin" "$CACHE_HOME/.codex-plugin"
cp "$ROOT/.mcp.json" "$CACHE_HOME/.mcp.json"
cp -R "$ROOT/assets" "$CACHE_HOME/assets"
cp -R "$ROOT/commands" "$CACHE_HOME/commands"
cp -R "$ROOT/skills" "$CACHE_HOME/skills"
cp -R "$ROOT/dist" "$CACHE_HOME/dist"

mkdir -p "$(dirname "$MARKETPLACE")"
python3 - "$MARKETPLACE" "$OLD_SLUG" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
old_slug = sys.argv[2]
if path.exists():
    data = json.loads(path.read_text(encoding="utf-8"))
else:
    data = {
        "name": "local",
        "interface": {"displayName": "Local Plugins"},
        "plugins": []
    }

entry = {
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

plugins = [
    plugin
    for plugin in data.get("plugins", [])
    if plugin.get("name") not in {"agent-vision", old_slug}
]
plugins.append(entry)
data["plugins"] = plugins
path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY

codex plugin marketplace add "$HOME" >/dev/null

mkdir -p "$(dirname "$CODEX_CONFIG")"
python3 - "$CODEX_CONFIG" "$OLD_SLUG" <<'PY'
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
old_slug = sys.argv[2]
text = path.read_text(encoding="utf-8") if path.exists() else ""

def remove_section(source: str, header: str) -> str:
    pattern = re.compile(rf"(?ms)^\[{re.escape(header)}\]\n.*?(?=^\[|\Z)")
    return pattern.sub("", source).strip() + ("\n" if source.strip() else "")

text = remove_section(text, 'plugins."agent-vision@local"')
text = remove_section(text, 'plugins."agent-vision@openai-curated"')
text = remove_section(text, f'plugins."{old_slug}@local"')
text = remove_section(text, f'plugins."{old_slug}@openai-curated"')
text = remove_section(text, "mcp_servers.agent_vision")
text = remove_section(text, 'mcp_servers."agent-vision"')
text = remove_section(text, "mcp_servers.codex_vision")
text = remove_section(text, f'mcp_servers."{old_slug}"')

addition = f"""
[plugins."agent-vision@local"]
enabled = true
"""

path.write_text(text.rstrip() + "\n" + addition.lstrip(), encoding="utf-8")
PY

rm -rf \
  "$HOME/plugins/$OLD_SLUG" \
  "$HOME/.codex/plugins/cache/local/$OLD_SLUG" \
  "$PREV_PACKAGE_CACHE_HOME" \
  "$OLD_RUNTIME_CACHE_HOME" \
  "$OLD_CACHE_HOME" \
  "$LEGACY_CACHE_HOME" \
  "$HOME/.codex/.tmp/plugins/plugins/$OLD_SLUG" \
  "$HOME/.codex/.tmp/plugins/plugins/agent-vision" \
  "$HOME/.codex/plugins/cache/openai-curated/$OLD_SLUG" \
  "$HOME/.codex/plugins/cache/openai-curated/agent-vision"

test ! -e "$CACHE_HOME/dist/agent-vision-mcp"
test -x "$CACHE_HOME/dist/agent-vision-capture-file"

PROMPT_CHECK="$(mktemp "${TMPDIR:-/tmp}/agent-vision-prompt-input.XXXXXX.json")"
trap 'rm -f "$PROMPT_CHECK"' EXIT
codex debug prompt-input "agent vision install check" > "$PROMPT_CHECK"
python3 - "$PROMPT_CHECK" <<'PY'
import json
import sys

path = sys.argv[1]
text = json.dumps(json.loads(open(path, encoding="utf-8").read()))
count = text.count("`Agent Vision`: macOS-only plugin for explicit local camera frames.")
if count != 1:
    raise SystemExit(f"Agent Vision plugin admission check failed: expected exactly one generated plugin entry, found {count}.")
PY

echo "Agent Vision installed at $PLUGIN_HOME"
echo "Agent Vision cached at $CACHE_HOME"
echo "Agent Vision plugin registered in $CODEX_CONFIG"
echo "Use /agent-vision snapshot, /agent-vision roast, or /agent-vision mood. Streaming is disabled in 1.5.0."
