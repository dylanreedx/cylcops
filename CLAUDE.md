# Cyclops — Project Instructions

## Build
```bash
cd Cyclops && swift build
```

## Architecture

Cyclops is a macOS menu bar "Dynamic Island" — a floating HUD that appears when you hover near the notch. It reads from the Conductor SQLite database to show active agent sessions, project progress, and memories.

### File Responsibilities
| File | Role |
|------|------|
| `main.swift` | App entry point — creates NSApplication, sets AppDelegate, runs |
| `AppDelegate.swift` | Creates NSPanel, configures visual effect backdrop, positions under notch, sets up refresh timer |
| `AgentView.swift` | Main SwiftUI view — tabbed HUD showing Sessions / Projects / Memories |
| `SessionCardView.swift` | Individual session card with status badge, elapsed time, click-to-focus |
| `DataBridge.swift` | Shells out to `sqlite3` CLI via `Process()` to read conductor.db |
| `MouseTracker.swift` | Global mouse event monitoring — shows HUD on notch hover, hides on exit |
| `Models.swift` | Data models: `AgentSession`, `ProjectStatus` |

## Constraints
- **Native only** — no external dependencies in Package.swift. Only Apple frameworks.
- **macOS 13+** — SwiftUI + AppKit hybrid. NSPanel for the window.
- **No SQLite library** — use `Process()` to shell out to `sqlite3` CLI.
- **Swift 6 compatible** — use `@MainActor` and `Sendable` where needed.
- **HUD style** — NSVisualEffectView with `.hudWindow` material for glassmorphism.

## Conductor Integration
- DB path: `.conductor/conductor.db` (relative to project root)
- The app reads from tables: `projects`, `features`, `sessions`, `memories`
- Never writes to the DB — read-only consumer

## Key Patterns
- **NSPanel** with `.nonactivatingPanel`, `.borderless`, `.fullSizeContentView` style mask
- **NSVisualEffectView** as the panel's content view with `.hudWindow` material
- **Process()** for sqlite3 — use `-json` flag for structured output
- **NSEvent.addGlobalMonitorForEvents** for mouse tracking outside the app
- App entry uses `NSApplication` directly in main.swift — no `@main` attribute
