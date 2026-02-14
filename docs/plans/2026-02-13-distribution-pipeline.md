# Distribution Pipeline Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Package Cyclops as a downloadable `.app` in a `.dmg`, built automatically by GitHub Actions on tag push.

**Architecture:** `swift build -c release` produces the binary. A shell script assembles the `.app` bundle (Info.plist, icon, ad-hoc codesign). A second script wraps it in a styled DMG via `create-dmg`. GitHub Actions ties it together: push a `v*` tag → macOS runner builds everything → DMG published as a GitHub Release. No Apple Developer account — users bypass Gatekeeper once on first launch.

**Tech Stack:** Swift Package Manager, bash scripts, `create-dmg` (npm), GitHub Actions, `codesign` (ad-hoc), `hdiutil`

**Constraints:**
- Apple Silicon only (arm64) — no universal binary
- No code signing identity — ad-hoc signing only
- No notarization — Gatekeeper bypass instructions provided
- Two assets required from user before Tasks 2 and 4: app icon PNG (1024x1024) and DMG background PNG (~600x400)

---

## Task 1: Create Info.plist template

**Files:**
- Create: `resources/Info.plist.template`

**Step 1: Create the resources directory and template**

```bash
mkdir -p resources
```

Write `resources/Info.plist.template`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>Cyclops</string>
    <key>CFBundleDisplayName</key>
    <string>Cyclops</string>
    <key>CFBundleIdentifier</key>
    <string>com.dylan.cyclops</string>
    <key>CFBundleVersion</key>
    <string>__VERSION__</string>
    <key>CFBundleShortVersionString</key>
    <string>__VERSION__</string>
    <key>CFBundleExecutable</key>
    <string>Cyclops</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
```

Key entries explained:
- `LSUIElement = true` — hides from Dock (background agent)
- `__VERSION__` — placeholder replaced by build script at build time
- `CFBundleIconFile = AppIcon` — expects `AppIcon.icns` in Resources/
- `NSHighResolutionCapable = true` — Retina support

**Step 2: Verify the plist is valid XML**

```bash
plutil -lint resources/Info.plist.template
```

Expected: `resources/Info.plist.template: OK`

**Step 3: Commit**

```bash
git add resources/Info.plist.template
git commit -m "feat: add Info.plist template for app bundle"
```

---

## Task 2: Create build-app.sh

**Prerequisite:** User must provide a 1024x1024 PNG app icon. This task converts it to `.icns` and uses it in the bundle.

**Files:**
- Create: `scripts/build-app.sh`
- Create: `resources/AppIcon.icns` (generated from user-provided PNG)

**Step 1: Convert user's PNG to icns**

Given a file `resources/AppIcon.png` (1024x1024, provided by user):

```bash
mkdir -p /tmp/AppIcon.iconset
sips -z 16 16     resources/AppIcon.png --out /tmp/AppIcon.iconset/icon_16x16.png
sips -z 32 32     resources/AppIcon.png --out /tmp/AppIcon.iconset/icon_16x16@2x.png
sips -z 32 32     resources/AppIcon.png --out /tmp/AppIcon.iconset/icon_32x32.png
sips -z 64 64     resources/AppIcon.png --out /tmp/AppIcon.iconset/icon_32x32@2x.png
sips -z 128 128   resources/AppIcon.png --out /tmp/AppIcon.iconset/icon_128x128.png
sips -z 256 256   resources/AppIcon.png --out /tmp/AppIcon.iconset/icon_128x128@2x.png
sips -z 256 256   resources/AppIcon.png --out /tmp/AppIcon.iconset/icon_256x256.png
sips -z 512 512   resources/AppIcon.png --out /tmp/AppIcon.iconset/icon_256x256@2x.png
sips -z 512 512   resources/AppIcon.png --out /tmp/AppIcon.iconset/icon_512x512.png
sips -z 1024 1024 resources/AppIcon.png --out /tmp/AppIcon.iconset/icon_512x512@2x.png
iconutil -c icns /tmp/AppIcon.iconset -o resources/AppIcon.icns
rm -rf /tmp/AppIcon.iconset
```

`sips` and `iconutil` are built into macOS — no dependencies needed. `sips` resizes the PNG to each required size, `iconutil` packs them into a single `.icns` file.

**Step 2: Write the build script**

Create `scripts/build-app.sh`:

```bash
#!/bin/bash
set -euo pipefail

# ─── Config ──────────────────────────────────────────
APP_NAME="Cyclops"
BUNDLE_ID="com.dylan.cyclops"
BINARY="Cyclops/.build/release/Cyclops"
ICON="resources/AppIcon.icns"
PLIST_TEMPLATE="resources/Info.plist.template"
MIN_MACOS="13.0"
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
```

**Step 3: Make it executable and test locally**

```bash
chmod +x scripts/build-app.sh
./scripts/build-app.sh 0.0.1
```

Expected output:
```
Building Cyclops v0.0.1...
Build complete!
Built Cyclops.app (v0.0.1)
```

**Step 4: Verify the bundle**

```bash
# Check structure
ls -la Cyclops.app/Contents/
ls -la Cyclops.app/Contents/MacOS/
ls -la Cyclops.app/Contents/Resources/

# Verify Info.plist version was injected
plutil -p Cyclops.app/Contents/Info.plist | grep -i version
# Expected: "CFBundleVersion" => "0.0.1"

# Verify codesign
codesign -vv Cyclops.app
# Expected: "valid on disk" (ad-hoc)

# Try launching it
open Cyclops.app
# Expected: Cyclops runs (notch HUD), no Dock icon appears
```

**Step 5: Commit**

```bash
git add scripts/build-app.sh resources/AppIcon.icns resources/AppIcon.png
git commit -m "feat: add build-app.sh and app icon"
```

**Step 6: Add build artifacts to .gitignore**

Append to `.gitignore`:

```
*.app
*.dmg
```

```bash
git add .gitignore
git commit -m "chore: ignore .app and .dmg build artifacts"
```

---

## Task 3: Create build-dmg.sh

**Prerequisite:** User must provide a DMG background PNG (~600x400).

**Files:**
- Create: `scripts/build-dmg.sh`

**Step 1: Install create-dmg locally for testing**

```bash
npm install -g create-dmg
```

`create-dmg` is an npm package that wraps `hdiutil` and AppleScript to create styled DMGs with icon positioning, backgrounds, and the Applications symlink. We only need it installed on the build machine (your Mac for testing, GitHub Actions runner for releases).

**Step 2: Write the DMG script**

Create `scripts/build-dmg.sh`:

```bash
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

create-dmg \
    --volname "$APP_NAME" \
    --window-size 600 400 \
    --icon-size 128 \
    --icon "$APP" 150 200 \
    --app-drop-link 450 200 \
    --background "$DMG_BACKGROUND" \
    --no-internet-enable \
    "$DMG_NAME" \
    "$APP"

echo "Created $DMG_NAME"
```

Flags explained:
- `--volname` — name shown in Finder title bar when DMG is mounted
- `--window-size 600 400` — Finder window dimensions
- `--icon "Cyclops.app" 150 200` — positions app icon on the left
- `--app-drop-link 450 200` — places Applications folder alias on the right
- `--background` — your artwork image behind everything
- `--no-internet-enable` — skips deprecated internet-enable flag

**Step 3: Make executable and test**

```bash
chmod +x scripts/build-dmg.sh
./scripts/build-dmg.sh
```

Expected: `Cyclops.dmg` created in repo root.

**Step 4: Verify the DMG**

```bash
# Mount and inspect
hdiutil attach Cyclops.dmg
ls /Volumes/Cyclops/
# Expected: Cyclops.app and Applications symlink

# Verify it looks right in Finder
open /Volumes/Cyclops/

# Unmount
hdiutil detach /Volumes/Cyclops/
```

Check in Finder: background image visible, app icon on left, Applications on right.

**Step 5: Commit**

```bash
git add scripts/build-dmg.sh resources/dmg-background.png
git commit -m "feat: add build-dmg.sh for styled DMG creation"
```

---

## Task 4: Create GitHub Actions release workflow

**Files:**
- Create: `.github/workflows/release.yml`

**Step 1: Write the workflow**

Create `.github/workflows/release.yml`:

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: macos-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Node (for create-dmg)
        uses: actions/setup-node@v4
        with:
          node-version: '20'

      - name: Install create-dmg
        run: npm install -g create-dmg

      - name: Extract version from tag
        run: echo "VERSION=${GITHUB_REF_NAME#v}" >> $GITHUB_ENV

      - name: Build app bundle
        run: ./scripts/build-app.sh ${{ env.VERSION }}

      - name: Build DMG
        run: ./scripts/build-dmg.sh

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          files: Cyclops.dmg
          generate_release_notes: true
```

How this works:
- `on: push: tags: - 'v*'` — only runs when you push a tag starting with `v`
- `macos-latest` — GitHub provides a macOS runner with Swift, Xcode, codesign pre-installed
- `${GITHUB_REF_NAME#v}` — bash parameter expansion: strips the `v` prefix from tag name (`v1.0.0` → `1.0.0`)
- `$GITHUB_ENV` — GitHub Actions way to set environment variables for subsequent steps
- `softprops/action-gh-release@v2` — creates a Release page on GitHub, attaches the DMG file, and auto-generates release notes from commits since the last tag

**Step 2: Commit**

```bash
mkdir -p .github/workflows
git add .github/workflows/release.yml
git commit -m "feat: add GitHub Actions release workflow"
```

**Step 3: Test with a dry run tag**

```bash
git tag v0.0.1
git push --tags
```

Go to GitHub → Actions tab → watch the "Release" workflow run.
Expected: workflow succeeds, `v0.0.1` release appears with `Cyclops.dmg` attached.

If the workflow fails, check the Actions log for the failing step. Common issues:
- `swift build` fails — check that `Cyclops/Package.swift` is at the right path relative to repo root
- `create-dmg` fails — check that `resources/dmg-background.png` exists
- codesign fails — this shouldn't happen with ad-hoc signing on a macOS runner

**Step 4: Verify the release**

Download `Cyclops.dmg` from the GitHub Release page. Mount it, drag to Applications, launch. Verify:
- App runs correctly
- No Dock icon (LSUIElement)
- Gatekeeper warning appears (expected — no developer identity)

---

## Task 5: Add install instructions to README

**Files:**
- Modify: `README.md` (create if it doesn't exist)

**Step 1: Write installation section**

Add to `README.md`:

```markdown
## Installation

### Download

Download the latest `Cyclops.dmg` from [Releases](../../releases/latest).

### Install

1. Open `Cyclops.dmg`
2. Drag **Cyclops** to **Applications**
3. Eject the disk image

### First Launch

We don't have an Apple Developer account yet, so macOS will show a warning on first launch.

1. Open Cyclops from Applications — macOS will say it's from an "unidentified developer"
2. Click **OK** to dismiss
3. Open **System Settings → Privacy & Security**
4. Scroll down and click **Open Anyway** next to the Cyclops warning
5. Confirm when prompted

You only need to do this once.
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add installation instructions with Gatekeeper bypass"
```

---

## Summary

| Task | Creates | Depends On | Blocked By User? |
|------|---------|------------|------------------|
| 1 | `resources/Info.plist.template` | — | No |
| 2 | `scripts/build-app.sh`, `resources/AppIcon.icns` | Task 1 | Yes — needs 1024x1024 PNG |
| 3 | `scripts/build-dmg.sh` | Task 2 | Yes — needs DMG background PNG |
| 4 | `.github/workflows/release.yml` | Task 3 | No |
| 5 | `README.md` install instructions | Task 4 | No |

**Release flow after implementation:**
```
git tag v1.0.0 && git push --tags
→ GitHub Actions: swift build → .app bundle → .dmg → GitHub Release
→ Users: download DMG → drag to Applications → Open Anyway once → done
```
