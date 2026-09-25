#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

swift build -c release
BIN="$ROOT/.build/release/TilawahOverlay"
STAGING="$ROOT/.build/Tilawah Overlay.app"
DEST="/Applications/Tilawah Overlay.app"

rm -rf "$STAGING"
mkdir -p "$STAGING/Contents/MacOS"
cp "$BIN" "$STAGING/Contents/MacOS/TilawahOverlay"
cp "$ROOT/Resources/Info.plist" "$STAGING/Contents/Info.plist"

# Ad-hoc sign so the installed bundle is a proper signed app.
codesign --force --sign - --identifier "dev.tilawah.overlay" "$STAGING" >/dev/null 2>&1 || true

rm -rf "$DEST"
cp -R "$STAGING" "$DEST"

echo "Installed: $DEST"
echo "Double-click it in Applications, or open from Spotlight / Dock."
echo "Quit from the menu bar book icon. Re-run this script after code changes."
