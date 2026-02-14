# Project Cyclops: The Architecture

**Concept:** A "Dynamic Island" for macOS hackers. A notch-based, borderless window that visualizes active `conductor` agents and `tmux` sessions.

## 1. The Stack
* **Language:** Swift 6.0 (Native).
* **UI Framework:** SwiftUI (Views) + AppKit (`NSPanel` logic).
* **Build System:** Swift Package Manager (Executable target).
* **Database:** Local SQLite (`~/.conductor/conductor.db`).
* **Terminal Control:** `tmux` (via shell) + Ghostty (via `NSWorkspace`).

## 2. Data Flow (The "Reflex" Loop)
Cyclops does not maintain state. It is a view-layer only.

1. **Trigger:** `NSEvent` detects mouse at `(ScreenWidth/2, ScreenHeight)` (top center near notch).
2. **Fetch:** Swift executes `sqlite3` CLI command -> Returns CSV.
3. **Parse:** Swift maps CSV -> `struct AgentStatus`.
4. **Render:** SwiftUI updates the list (Running = Green, Error = Red, Idle = Grey).
5. **Action:** User clicks row -> Swift runs `tmux switch-client -t <id>`.

## 3. The Components

### A. The Window (`CyclopsPanel.swift` via `AppDelegate.swift`)
* **Type:** `NSPanel`.
* **Style:** `.borderless`, `.nonactivatingPanel` (doesn't steal focus).
* **Level:** `.floating` (always on top).
* **Position:** Centered horizontally at top of screen, just below notch area.
* **Size:** ~480pt wide, height expands based on agent count (max ~300pt).
* **Behavior:** Hidden by default. Shows on mouse hover near notch. Ignores mouse events when not visible.

### B. The Conductor Bridge (`ConductorBridge.swift`)
* **Constraint:** Do NOT use external Swift SQLite libraries. Use `Process()` to shell out to `sqlite3`.
* **DB Path:** `~/.conductor/conductor.db` (but for dev, use the local `.conductor/conductor.db` in the project).
* **Command:**
  ```bash
  sqlite3 -header -csv .conductor/conductor.db "SELECT s.id, p.name, s.status, datetime(s.started_at, 'unixepoch', 'localtime') as started FROM sessions s LEFT JOIN projects p ON s.project_id = p.id WHERE s.status != 'completed' ORDER BY s.started_at DESC LIMIT 10;"
  ```
* **Model:**
  ```swift
  struct AgentStatus: Identifiable {
      let id: String
      let name: String       // project name
      let status: String     // "active", "error", "pending", "completed"
      let startedAt: String  // formatted datetime
  }
  ```

### C. The Tmux/Ghostty Bridge (`TmuxBridge.swift`)
* **Function:** Switches context to a specific tmux session in Ghostty.
* **Logic:**
  1. Focus Ghostty: `NSWorkspace.shared.openApplication(at: ghosttyURL, ...)`
  2. Switch Tmux: `Process("/usr/local/bin/tmux", arguments: ["switch-client", "-t", sessionID])`

### D. The UI (`AgentView.swift`)
* **Style:** Glassmorphism / macOS HUD appearance using `NSVisualEffectView` (`.hudWindow` material).
* **Layout:** Vertical list of agent rows. Each row shows:
  - Status indicator (colored circle: green=running, red=error, grey=idle)
  - Agent name
  - Last updated timestamp
* **Interaction:** Click a row to switch to that tmux session.

## 4. Project Structure
```
Cyclops/
├── Package.swift
└── Sources/
    ├── main.swift           # App entry point, NSApplication setup
    ├── AppDelegate.swift    # Creates and manages the NSPanel
    ├── CyclopsPanel.swift   # Custom NSPanel subclass
    ├── AgentView.swift      # SwiftUI view for the agent list
    ├── ConductorBridge.swift # SQLite query via Process
    └── TmuxBridge.swift     # Tmux/Ghostty switching
```
