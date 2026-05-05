#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
fi

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Codex Vision is macOS-only." >&2
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
    if rel == ".codex-plugin/plugin.json" and data["name"] != "codex-vision":
        raise SystemExit(f"{rel} has wrong plugin name")
    if rel == ".mcp.json" and "codex-vision" not in data.get("mcpServers", {}):
        raise SystemExit(f"{rel} has no codex-vision MCP server")
PY

if [[ "$DRY_RUN" == "1" ]]; then
  swift build -c release --package-path "$ROOT" >/dev/null
  echo "Codex Vision dry-run validation succeeded."
  exit 0
fi

command -v codex >/dev/null || { echo "codex CLI is required." >&2; exit 1; }
SIGN_IDENTITY="$(security find-identity -v -p codesigning 2>/dev/null | awk -F'\"' '/Apple Development/ { print $2; exit }')"
if [[ -z "$SIGN_IDENTITY" ]]; then
  echo "An Apple Development code signing identity is required so macOS preserves Camera permission for CodexVision.app." >&2
  exit 1
fi

swift build -c release --package-path "$ROOT"
BUILD_DIR="$(swift build -c release --package-path "$ROOT" --show-bin-path)"
APP="$ROOT/dist/CodexVision.app"
PLUGIN_HOME="$HOME/plugins/codex-vision"
CACHE_HOME="$HOME/.codex/plugins/cache/local/codex-vision/1.0.0"
MARKETPLACE="$HOME/.agents/plugins/marketplace.json"
CODEX_CONFIG="$HOME/.codex/config.toml"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
rm -f "$ROOT/dist/prompt-input-check.json"
cp "$BUILD_DIR/CodexVision" "$APP/Contents/MacOS/CodexVision"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>CodexVision</string>
  <key>CFBundleIdentifier</key>
  <string>works.velocity.codex-vision</string>
  <key>CFBundleName</key>
  <string>Codex Vision</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>NSCameraUsageDescription</key>
  <string>Codex Vision lets a local Codex session request camera frames when you explicitly use its MCP tools.</string>
</dict>
</plist>
PLIST
plutil -lint "$APP/Contents/Info.plist" >/dev/null
/usr/bin/codesign --force --sign "$SIGN_IDENTITY" "$APP" >/dev/null
cat > "$ROOT/dist/codex-vision-mcp" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/codex-vision.XXXXXX")"
IN_FIFO="$TMP/in"
OUT_FIFO="$TMP/out"
mkfifo "$IN_FIFO" "$OUT_FIFO"
cleanup() {
  rm -rf "$TMP"
}
trap cleanup EXIT

open -n "$ROOT/dist/CodexVision.app" --args mcp-fifo "$IN_FIFO" "$OUT_FIFO"
APP_PATTERN="$ROOT/dist/[C]odexVision.app/Contents/MacOS/CodexVision mcp-fifo $IN_FIFO $OUT_FIFO"
APP_PID=""
for _ in {1..50}; do
  APP_PID="$(pgrep -f "$APP_PATTERN" | head -n 1 || true)"
  if [[ -n "$APP_PID" ]]; then
    break
  fi
  sleep 0.1
done
if [[ -z "$APP_PID" ]]; then
  echo "Codex Vision app did not launch for MCP FIFO mode." >&2
  exit 1
fi
cat "$OUT_FIFO" &
OUT_PID="$!"
cat > "$IN_FIFO"
wait "$OUT_PID"
SH
chmod +x "$ROOT/dist/codex-vision-mcp"

rm -rf "$PLUGIN_HOME"
mkdir -p "$PLUGIN_HOME"
cp -R "$ROOT/.codex-plugin" "$PLUGIN_HOME/.codex-plugin"
cp "$ROOT/.mcp.json" "$PLUGIN_HOME/.mcp.json"
cp -R "$ROOT/assets" "$PLUGIN_HOME/assets"
cp -R "$ROOT/commands" "$PLUGIN_HOME/commands"
cp -R "$ROOT/skills" "$PLUGIN_HOME/skills"
cp -R "$ROOT/dist" "$PLUGIN_HOME/dist"

rm -rf "$CACHE_HOME"
mkdir -p "$CACHE_HOME"
cp -R "$ROOT/.codex-plugin" "$CACHE_HOME/.codex-plugin"
cp "$ROOT/.mcp.json" "$CACHE_HOME/.mcp.json"
cp -R "$ROOT/assets" "$CACHE_HOME/assets"
cp -R "$ROOT/commands" "$CACHE_HOME/commands"
cp -R "$ROOT/skills" "$CACHE_HOME/skills"
cp -R "$ROOT/dist" "$CACHE_HOME/dist"

mkdir -p "$(dirname "$MARKETPLACE")"
python3 - "$MARKETPLACE" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
if path.exists():
    data = json.loads(path.read_text(encoding="utf-8"))
else:
    data = {
        "name": "local",
        "interface": {"displayName": "Local Plugins"},
        "plugins": []
    }

entry = {
    "name": "codex-vision",
    "source": {
        "source": "local",
        "path": "./plugins/codex-vision"
    },
    "policy": {
        "installation": "INSTALLED_BY_DEFAULT",
        "authentication": "ON_INSTALL"
    },
    "category": "Productivity"
}

plugins = [plugin for plugin in data.get("plugins", []) if plugin.get("name") != "codex-vision"]
plugins.append(entry)
data["plugins"] = plugins
path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY

codex plugin marketplace add "$HOME" >/dev/null

mkdir -p "$(dirname "$CODEX_CONFIG")"
python3 - "$CODEX_CONFIG" "$HOME" <<'PY'
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
text = path.read_text(encoding="utf-8") if path.exists() else ""

def remove_section(source: str, header: str) -> str:
    pattern = re.compile(rf"(?ms)^\[{re.escape(header)}\]\n.*?(?=^\[|\Z)")
    return pattern.sub("", source).strip() + ("\n" if source.strip() else "")

text = remove_section(text, 'plugins."codex-vision@local"')
text = remove_section(text, 'plugins."codex-vision@openai-curated"')

addition = f"""
[plugins."codex-vision@local"]
enabled = true
"""

path.write_text(text.rstrip() + "\n" + addition.lstrip(), encoding="utf-8")
PY

rm -rf \
  "$HOME/.codex/.tmp/plugins/plugins/codex-vision" \
  "$HOME/.codex/plugins/cache/openai-curated/codex-vision"

PROMPT_CHECK="$(mktemp "${TMPDIR:-/tmp}/codex-vision-prompt-input.XXXXXX.json")"
trap 'rm -f "$PROMPT_CHECK"' EXIT
codex debug prompt-input "codex vision install check" > "$PROMPT_CHECK"
python3 - "$PROMPT_CHECK" <<'PY'
import json
import sys

path = sys.argv[1]
text = json.dumps(json.loads(open(path, encoding="utf-8").read()))
count = text.count("`Codex Vision`: macOS-only Codex plugin for explicit live camera frames through MCP.")
if count != 1:
    raise SystemExit(f"Codex Vision plugin admission check failed: expected exactly one generated plugin entry, found {count}.")
PY

echo "Codex Vision installed at $PLUGIN_HOME"
echo "Codex Vision cached at $CACHE_HOME"
echo "Codex Vision registered in $CODEX_CONFIG"
echo "Use /codex-vision snapshot or /codex-vision streaming."
