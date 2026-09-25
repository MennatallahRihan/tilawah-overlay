#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

VERSION="$(
  /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT/Resources/Info.plist" 2>/dev/null \
    || echo "0.1.0"
)"
APP_NAME="Tilawah Overlay"
DMG_NAME="Tilawah-Overlay-${VERSION}.dmg"
DIST="$ROOT/dist"
STAGING="$DIST/dmg-staging"
APP_BUNDLE="$STAGING/${APP_NAME}.app"
DMG_PATH="$DIST/$DMG_NAME"

echo "Building release..."
swift build -c release
BIN="$ROOT/.build/release/TilawahOverlay"

rm -rf "$STAGING" "$DMG_PATH"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
cp "$BIN" "$APP_BUNDLE/Contents/MacOS/TilawahOverlay"
cp "$ROOT/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

codesign --force --sign - --identifier "dev.tilawah.overlay" "$APP_BUNDLE" >/dev/null 2>&1 || true

ln -s /Applications "$STAGING/Applications"

echo "Creating ${DMG_NAME}..."
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null

rm -rf "$STAGING"

echo
echo "Ready: $DMG_PATH"
echo
echo "Upload to a GitHub Release (example):"
echo "  gh release create v${VERSION} \"$DMG_PATH\" --title \"Tilawah Overlay ${VERSION}\" --notes \"macOS 14+. Open the .dmg, drag Tilawah Overlay to Applications.\""
echo
echo "First open on someone else's Mac may need: right-click the app -> Open (Gatekeeper; unsigned)."
