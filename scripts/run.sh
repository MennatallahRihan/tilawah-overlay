#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

swift build -c debug
BIN="$ROOT/.build/debug/TilawahOverlay"
APP="$ROOT/.build/TilawahOverlay.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN" "$APP/Contents/MacOS/TilawahOverlay"
cp "$ROOT/Resources/Info.plist" "$APP/Contents/Info.plist"

# Ad-hoc sign so Automation prompts attach to this app bundle.
codesign --force --sign - --identifier "dev.tilawah.overlay" "$APP" >/dev/null 2>&1 || true

echo "Launching Tilawah Overlay (menu bar + floating panel)."
echo "The terminal will return immediately. Quit from the menu bar icon."
open "$APP"
