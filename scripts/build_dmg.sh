#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="WindowPilot"
APP_DIR="$ROOT_DIR/.build/app/$APP_NAME.app"
DIST_DIR="$ROOT_DIR/dist"
STAGING_DIR="$ROOT_DIR/.build/dmg-staging"
DMG_TEMP="$DIST_DIR/$APP_NAME-temp.dmg"
DMG_FINAL="$DIST_DIR/$APP_NAME.dmg"
VOLUME_NAME="$APP_NAME"

cd "$ROOT_DIR"

"$ROOT_DIR/scripts/build_app.sh"

rm -rf "$STAGING_DIR"
rm -f "$DMG_TEMP" "$DMG_FINAL"
mkdir -p "$DIST_DIR" "$STAGING_DIR"

cp -R "$APP_DIR" "$STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDRW \
  "$DMG_TEMP"

cleanup() {
  hdiutil detach "$VOLUME_PATH" >/dev/null 2>&1 || true
}
trap cleanup EXIT

VOLUME_PATH="/Volumes/$VOLUME_NAME"
ATTACH_OUTPUT="$(hdiutil attach "$DMG_TEMP" -readwrite -noverify -noautoopen)"
echo "$ATTACH_OUTPUT"
VOLUME_PATH="$(echo "$ATTACH_OUTPUT" | awk -F'\t' '/\/Volumes\// { print $NF; exit }')"
MOUNTED_VOLUME_NAME="$(basename "$VOLUME_PATH")"

if [[ ! -d "$VOLUME_PATH" ]]; then
  echo "Could not attach temporary DMG at $VOLUME_PATH" >&2
  exit 1
fi

osascript <<APPLESCRIPT
tell application "Finder"
  tell disk "$MOUNTED_VOLUME_NAME"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set bounds of container window to {100, 100, 640, 390}
    set theViewOptions to the icon view options of container window
    set arrangement of theViewOptions to not arranged
    set icon size of theViewOptions to 96
    set position of item "$APP_NAME.app" of container window to {170, 150}
    set position of item "Applications" of container window to {430, 150}
    close
    open
    update without registering applications
    delay 1
  end tell
end tell
APPLESCRIPT

sync
hdiutil detach "$VOLUME_PATH"
trap - EXIT

hdiutil convert "$DMG_TEMP" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o "$DMG_FINAL"

rm -f "$DMG_TEMP"
codesign --force --sign - "$DMG_FINAL"

echo "Built $DMG_FINAL"
