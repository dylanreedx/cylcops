# Cyclops Architecture

## Overview

Cyclops is a macOS floating HUD that appears when the user hovers near the MacBook notch. It displays real-time status of Conductor-managed coding agent sessions. Think of it as a "Dynamic Island" for your development workflow.

## System Architecture

```
┌─────────────────────────────────────────┐
│              macOS Screen               │
│         ┌─────────────┐                 │
│         │   Notch      │                 │
│         └──────┬───────┘                 │
│                │ hover                   │
│         ┌──────▼───────┐                 │
│         │  Cyclops HUD │                 │
│         │  (NSPanel)   │                 │
│         └──────┬───────┘                 │
│                │ reads                   │
│         ┌──────▼───────┐                 │
│         │ conductor.db │                 │
│         └──────────────┘                 │
└─────────────────────────────────────────┘
```

## Components

### 1. NSPanel (AppDelegate)
The HUD window is an `NSPanel` configured as:
- **Style mask**: `.borderless | .nonactivatingPanel | .fullSizeContentView`
- **Level**: `.floating` (always on top, but doesn't steal focus)
- **Background**: Transparent (visual effect provides the backdrop)
- **Behavior**: `.canJoinAllSpaces | .transient`

### 2. NSVisualEffectView (Backdrop)
Provides the frosted glass effect:
- **Material**: `.hudWindow` — dark, translucent, system-consistent
- **Blending mode**: `.behindWindow`
- **State**: `.active` (always vibrant, even when app is inactive)
- **Corner radius**: 16pt on the view's layer

### 3. SwiftUI Content (AgentView)
Hosted inside the panel via `NSHostingView`:
- **Tabs**: Sessions | Projects | Memories
- **Sessions tab**: List of `SessionCardView` items showing active agent sessions
- **Projects tab**: Project names with progress bars (passed/total features)
- **Memories tab**: Recent saved patterns and insights

### 4. DataBridge (SQLite Reader)
Reads from `.conductor/conductor.db` using the `sqlite3` CLI:
- Uses `Process()` to run: `sqlite3 -json <db_path> "<query>"`
- Parses JSON output into Swift model types
- Refreshes on a `Timer` (every 5 seconds)
- All queries are SELECT-only (read-only consumer)

### 5. MouseTracker (Show/Hide Logic)
Controls HUD visibility based on mouse position:
- Uses `NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved)`
- Defines a "hot zone" at top-center of the main screen
- Shows HUD with fade-in animation when mouse enters zone
- Hides HUD with fade-out animation when mouse exits both zone and panel

## Conductor DB Schema

The app reads from these tables:

### projects
| Column | Type | Description |
|--------|------|-------------|
| name | TEXT | Project identifier |
| project_type | TEXT | Language/framework (e.g., "swift") |
| workspace_path | TEXT | Filesystem path |
| created_at | TEXT | ISO timestamp |
| ready_threshold | INTEGER | Dependency readiness % |

### features
| Column | Type | Description |
|--------|------|-------------|
| id | TEXT | UUID |
| project_name | TEXT | FK to projects |
| category | TEXT | Feature category |
| phase | INTEGER | Implementation phase (1-6) |
| description | TEXT | What to implement |
| status | TEXT | pending / in_progress / passed / failed / blocked |
| key | TEXT | Unique feature key |
| depends_on | TEXT | JSON array of dependency keys |
| steps | TEXT | JSON array of implementation steps |

### sessions
| Column | Type | Description |
|--------|------|-------------|
| id | TEXT | Session UUID |
| project_name | TEXT | FK to projects |
| started_at | TEXT | ISO timestamp |
| completed_at | TEXT | ISO timestamp (null if active) |
| notes | TEXT | Progress notes |

### memories
| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Auto-increment |
| name | TEXT | Memory identifier |
| content | TEXT | The pattern/insight |
| project_name | TEXT | Associated project |
| tags | TEXT | JSON array of tags |
| created_at | TEXT | ISO timestamp |

## Window Positioning

The HUD is centered horizontally under the notch on the main display:

```
Screen width: NSScreen.main.frame.width
Notch width:  ~200pt (approximate)
HUD width:    360pt
HUD height:   variable (max 480pt)

X = (screenWidth - hudWidth) / 2
Y = screenHeight - menuBarHeight - hudHeight - 8pt gap
```

The Y position accounts for the menu bar (typically 24pt on notch displays, 22pt on non-notch). The HUD appears directly below the notch with an 8pt gap.

## Mouse Tracking Zone

The "hot zone" that triggers the HUD:

```
Zone width:  400pt (centered on screen)
Zone height: 24pt  (the menu bar strip)

Zone X = (screenWidth - 400) / 2
Zone Y = screenHeight - 24
Zone   = NSRect(x, y, 400, 24)
```

When the mouse enters this zone, the HUD fades in (0.2s ease-in-out). The HUD stays visible as long as the mouse is within either the hot zone or the HUD panel itself. When the mouse exits both regions, the HUD fades out (0.15s).

## Interaction Flow

1. **Hover near notch** → MouseTracker detects entry → HUD fades in
2. **Browse sessions** → Scroll through active agent sessions
3. **Click session card** → Launches `osascript` to:
   - Activate Ghostty terminal
   - Run `tmux switch-client -t <session-name>`
4. **Mouse exits** → HUD fades out
5. **Keyboard shortcut** (Cmd+Shift+C) → Toggle HUD visibility

## Data Refresh

- Timer fires every 5 seconds
- DataBridge re-queries conductor.db
- SwiftUI views update via `@Published` / `@Observable`
- No notification mechanism — pure polling
