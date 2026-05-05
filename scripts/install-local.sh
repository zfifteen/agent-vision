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

swift build -c release --package-path "$ROOT"
BUILD_DIR="$(swift build -c release --package-path "$ROOT" --show-bin-path)"
APP="$ROOT/dist/CodexVision.app"
PLUGIN_HOME="$HOME/plugins/codex-vision"
MARKETPLACE="$HOME/.agents/plugins/marketplace.json"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
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
/usr/bin/codesign --force --sign - "$APP" >/dev/null

rm -rf "$PLUGIN_HOME"
mkdir -p "$PLUGIN_HOME"
cp -R "$ROOT/.codex-plugin" "$PLUGIN_HOME/.codex-plugin"
cp "$ROOT/.mcp.json" "$PLUGIN_HOME/.mcp.json"
cp -R "$ROOT/assets" "$PLUGIN_HOME/assets"
cp -R "$ROOT/skills" "$PLUGIN_HOME/skills"
cp -R "$ROOT/dist" "$PLUGIN_HOME/dist"

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
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
    },
    "category": "Productivity"
}

plugins = [plugin for plugin in data.get("plugins", []) if plugin.get("name") != "codex-vision"]
plugins.append(entry)
data["plugins"] = plugins
path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY

echo "Codex Vision installed at $PLUGIN_HOME"
echo "Restart Codex, enable the Codex Vision plugin if prompted, then ask Codex to use codex_vision_start and codex_vision_frame."
