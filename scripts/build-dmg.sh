#!/bin/bash
set -euo pipefail

# ─── Config ──────────────────────────────────────────
APP_NAME="Cyclops"
DMG_NAME="Cyclops.dmg"
DMG_BACKGROUND="resources/dmg-background.png"
# ─────────────────────────────────────────────────────

APP="$APP_NAME.app"

# Requires build-app.sh to have run first
if [ ! -d "$APP" ]; then
    echo "Error: $APP not found. Run scripts/build-app.sh first."
    exit 1
fi

# Clean previous DMG
rm -f "$DMG_NAME"

echo "Creating $DMG_NAME..."

# Stage the .app in a temp folder (create-dmg expects a source folder)
STAGE_DIR=$(mktemp -d)
cp -R "$APP" "$STAGE_DIR/"

# create-dmg may exit with code 2 on success (cosmetic warning)
# so we check if the DMG file was actually created
set +e
create-dmg \
    --volname "$APP_NAME" \
    --window-size 600 400 \
    --icon-size 128 \
    --icon "$APP" 150 200 \
    --app-drop-link 450 200 \
    --background "$DMG_BACKGROUND" \
    --no-internet-enable \
    "$DMG_NAME" \
    "$STAGE_DIR"
DMG_EXIT=$?
set -e

rm -rf "$STAGE_DIR"

if [ ! -f "$DMG_NAME" ]; then
    echo "Error: Failed to create $DMG_NAME (exit code $DMG_EXIT)"
    exit 1
fi

echo "Created $DMG_NAME"
