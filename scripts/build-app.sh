#!/bin/bash
set -euo pipefail

# ─── Config ──────────────────────────────────────────
APP_NAME="Cyclops"
BUNDLE_ID="com.dylan.cyclops"
BINARY="Cyclops/.build/release/Cyclops"
ICON="resources/AppIcon.icns"
PLIST_TEMPLATE="resources/Info.plist.template"
# ─────────────────────────────────────────────────────

VERSION="${1:-0.0.1}"
APP="$APP_NAME.app"

echo "Building $APP_NAME v$VERSION..."

# 1. Build release binary
cd Cyclops && swift build -c release && cd ..

# 2. Assemble .app bundle
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

cp "$BINARY" "$APP/Contents/MacOS/$APP_NAME"
cp "$ICON" "$APP/Contents/Resources/AppIcon.icns"

# 3. Generate Info.plist with version
sed "s/__VERSION__/$VERSION/g" "$PLIST_TEMPLATE" > "$APP/Contents/Info.plist"

# 4. Ad-hoc codesign
codesign -s - --force --deep "$APP"

echo "Built $APP (v$VERSION)"
