#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="1.5.0"
OUT="$ROOT/release/agent-vision-$VERSION"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Agent Vision release packaging is macOS-only." >&2
  exit 1
fi

SIGN_IDENTITY="${AGENT_VISION_SIGN_IDENTITY:-}"
if [[ -z "$SIGN_IDENTITY" ]]; then
  echo "AGENT_VISION_SIGN_IDENTITY is required for release packaging." >&2
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
plutil -lint "$OUT/dist/AgentVision.app/Contents/Info.plist" >/dev/null
/usr/bin/codesign --force --sign "$SIGN_IDENTITY" "$OUT/dist/AgentVision.app" >/dev/null
cp "$ROOT/scripts/agent-vision-capture-file.sh" "$OUT/dist/agent-vision-capture-file"
chmod +x "$OUT/dist/agent-vision-capture-file"
cp "$ROOT/scripts/install-packaged.sh" "$OUT/install.sh"
chmod +x "$OUT/install.sh"
cp "$ROOT/scripts/uninstall-packaged.sh" "$OUT/uninstall.sh"
chmod +x "$OUT/uninstall.sh"

# Grok Build host adapter + shared runtime installers (Ship A)
mkdir -p "$OUT/scripts" "$OUT/hosts"
cp "$ROOT/scripts/install-runtime.sh" "$OUT/scripts/install-runtime.sh"
cp "$ROOT/scripts/uninstall-runtime.sh" "$OUT/scripts/uninstall-runtime.sh"
cp "$ROOT/scripts/install-grok.sh" "$OUT/scripts/install-grok.sh"
cp "$ROOT/scripts/uninstall-grok.sh" "$OUT/scripts/uninstall-grok.sh"
cp "$ROOT/scripts/agent-vision-sticky.sh" "$OUT/scripts/agent-vision-sticky.sh"
cp "$ROOT/scripts/agent-vision-turn-gate.sh" "$OUT/scripts/agent-vision-turn-gate.sh"
cp "$ROOT/scripts/agent-vision-purge-frames.sh" "$OUT/scripts/agent-vision-purge-frames.sh"
chmod +x \
  "$OUT/scripts/install-runtime.sh" \
  "$OUT/scripts/uninstall-runtime.sh" \
  "$OUT/scripts/install-grok.sh" \
  "$OUT/scripts/uninstall-grok.sh" \
  "$OUT/scripts/agent-vision-sticky.sh" \
  "$OUT/scripts/agent-vision-turn-gate.sh" \
  "$OUT/scripts/agent-vision-purge-frames.sh"
cp -R "$ROOT/hosts/grok" "$OUT/hosts/grok"

cp -R "$ROOT/.codex-plugin" "$OUT/.codex-plugin"
cp "$ROOT/.mcp.json" "$OUT/.mcp.json"
cp -R "$ROOT/assets" "$OUT/assets"
cp -R "$ROOT/commands" "$OUT/commands"
cp -R "$ROOT/skills" "$OUT/skills"
cp -R "$ROOT/docs" "$OUT/docs"
cp "$ROOT/README.md" "$OUT/README.md"
cp "$ROOT/INSTALL.md" "$OUT/INSTALL.md"
cp "$ROOT/CODEX_INSTALL.md" "$OUT/CODEX_INSTALL.md"
cp "$ROOT/PRIVACY.md" "$OUT/PRIVACY.md"
cp "$ROOT/RELEASE_NOTES.md" "$OUT/RELEASE_NOTES.md"
cp "$ROOT/LICENSE" "$OUT/LICENSE"

tar -C "$ROOT/release" -czf "$OUT.tar.gz" "agent-vision-$VERSION"
echo "$OUT.tar.gz"
