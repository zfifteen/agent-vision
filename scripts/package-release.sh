#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="1.0.1"
OUT="$ROOT/release/agent-vision-$VERSION"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Agent Vision release packaging is macOS-only." >&2
  exit 1
fi

SIGN_IDENTITY="$(security find-identity -v -p codesigning 2>/dev/null | awk -F'\"' '/Apple Development/ { print $2; exit }')"
if [[ -z "$SIGN_IDENTITY" ]]; then
  echo "An Apple Development code signing identity is required so macOS preserves Camera permission for AgentVision.app." >&2
  exit 1
fi

rm -rf "$OUT" "$OUT.tar.gz"
mkdir -p "$OUT"
"$ROOT/scripts/install-local.sh" --dry-run
BUILD_DIR="$(swift build -c release --package-path "$ROOT" --show-bin-path)"
swift build -c release --package-path "$ROOT"

mkdir -p "$OUT/dist/AgentVision.app/Contents/MacOS" "$OUT/dist/AgentVision.app/Contents/Resources"
cp "$BUILD_DIR/AgentVision" "$OUT/dist/AgentVision.app/Contents/MacOS/AgentVision"
cat > "$OUT/dist/AgentVision.app/Contents/Info.plist" <<'PLIST'
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
  <string>1.0.1</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>NSCameraUsageDescription</key>
  <string>Agent Vision lets a local Codex session request camera frames when you explicitly use its MCP tools.</string>
</dict>
</plist>
PLIST
plutil -lint "$OUT/dist/AgentVision.app/Contents/Info.plist" >/dev/null
/usr/bin/codesign --force --sign "$SIGN_IDENTITY" "$OUT/dist/AgentVision.app" >/dev/null
cp "$ROOT/scripts/agent-vision-mcp.sh" "$OUT/dist/agent-vision-mcp"
chmod +x "$OUT/dist/agent-vision-mcp"
cp "$ROOT/scripts/agent-vision-capture-file.sh" "$OUT/dist/agent-vision-capture-file"
chmod +x "$OUT/dist/agent-vision-capture-file"
cp -R "$ROOT/.codex-plugin" "$OUT/.codex-plugin"
cp "$ROOT/.mcp.json" "$OUT/.mcp.json"
cp -R "$ROOT/assets" "$OUT/assets"
cp -R "$ROOT/commands" "$OUT/commands"
cp -R "$ROOT/skills" "$OUT/skills"
cp "$ROOT/README.md" "$OUT/README.md"
cp "$ROOT/INSTALL.md" "$OUT/INSTALL.md"
cp "$ROOT/CODEX_INSTALL.md" "$OUT/CODEX_INSTALL.md"
cp "$ROOT/PRIVACY.md" "$OUT/PRIVACY.md"
cp "$ROOT/LICENSE" "$OUT/LICENSE"

tar -C "$ROOT/release" -czf "$OUT.tar.gz" "agent-vision-$VERSION"
echo "$OUT.tar.gz"
