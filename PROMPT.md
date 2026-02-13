# MISSION
Build "Cyclops" — a macOS notch-based floating HUD that shows conductor agent sessions.

# REFERENCE
Read `CLAUDE.md` for project constraints and build commands.
Read `CYCLOPS_ARCH.md` for full architecture details.

# CONSTRAINTS
1. **Native Only**: No external dependencies in `Package.swift`. Only Apple frameworks.
2. **macOS 13+**: Use SwiftUI + AppKit. NSPanel for the window.
3. **No SQLite Library**: Use `Process()` to shell out to `sqlite3` CLI.
4. **Robustness**: Wrap all `Process()` calls in do/catch blocks.
5. **HUD Style**: Use NSVisualEffectView with `.hudWindow` material for glassmorphism.
6. **Swift 6 compatible**: Use `@MainActor` and `Sendable` where needed. Avoid strict concurrency warnings.

# WORKFLOW
Use the Conductor workflow for implementation:
1. Run `/conductor-start cyclops` to begin an autonomous coding session.
2. Conductor will pick up the next pending feature and implement it.
3. Each feature is built, tested with `cd Cyclops && swift build`, and marked complete.
4. Progress is tracked in `.conductor/conductor.db`.

# RULES
- Do NOT delete working code unless replacing it with something better.
- Do NOT use placeholder/stub implementations — every function must have real logic.
- Do NOT hallucinate APIs. Use only real Apple framework APIs.
- Keep files focused: one responsibility per file.
- The app entry point is `main.swift` — use `NSApplication` directly, not `@main` attribute.
