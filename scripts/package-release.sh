#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="1.0.0"
OUT="$ROOT/release/codex-vision-$VERSION"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Codex Vision release packaging is macOS-only." >&2
  exit 1
fi

rm -rf "$OUT" "$OUT.tar.gz"
mkdir -p "$OUT"
"$ROOT/scripts/install-local.sh" --dry-run
swift build -c release --package-path "$ROOT"
BUILD_DIR="$(swift build -c release --package-path "$ROOT" --show-bin-path)"

mkdir -p "$OUT/dist/CodexVision.app/Contents/MacOS" "$OUT/dist/CodexVision.app/Contents/Resources"
cp "$BUILD_DIR/CodexVision" "$OUT/dist/CodexVision.app/Contents/MacOS/CodexVision"
cat > "$OUT/dist/CodexVision.app/Contents/Info.plist" <<'PLIST'
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
/usr/bin/codesign --force --sign - "$OUT/dist/CodexVision.app" >/dev/null
cp -R "$ROOT/.codex-plugin" "$OUT/.codex-plugin"
cp "$ROOT/.mcp.json" "$OUT/.mcp.json"
cp -R "$ROOT/assets" "$OUT/assets"
cp -R "$ROOT/skills" "$OUT/skills"
cp "$ROOT/README.md" "$OUT/README.md"
cp "$ROOT/INSTALL.md" "$OUT/INSTALL.md"
cp "$ROOT/CODEX_INSTALL.md" "$OUT/CODEX_INSTALL.md"
cp "$ROOT/LICENSE" "$OUT/LICENSE"

tar -C "$ROOT/release" -czf "$OUT.tar.gz" "codex-vision-$VERSION"
echo "$OUT.tar.gz"
