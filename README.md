# Cyclops

A macOS notch-style HUD for monitoring Claude Code sessions, project progress, and memories.

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

## Building from Source

```bash
cd Cyclops && swift build
```

Requires macOS 13+ and Xcode Command Line Tools.
