import SwiftUI
import AppKit

struct SessionCardView: View {
    let session: AgentSession
    @State private var isHovered = false

    private var statusColor: Color {
        switch session.status {
        case .running: return .green
        case .idle: return .yellow
        case .offline: return .gray
        }
    }

    private var statusLabel: String {
        switch session.status {
        case .running: return "RUNNING"
        case .idle: return "IDLE"
        case .offline: return "OFFLINE"
        }
    }

    private var relativeTime: String {
        let interval = Date().timeIntervalSince(session.lastActivityDate)
        let minutes = Int(interval) / 60
        let hours = minutes / 60
        let days = hours / 24

        if days > 0 {
            return "\(days)d ago"
        } else if hours > 0 {
            return "\(hours)h ago"
        } else if minutes > 0 {
            return "\(minutes)m ago"
        }
        return "just now"
    }

    private var elapsed: String {
        let interval = Date().timeIntervalSince(session.lastActivityDate)
        let minutes = Int(interval) / 60
        let hours = minutes / 60
        if hours > 0 {
            return "\(hours)h \(minutes % 60)m"
        }
        return "\(minutes)m"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if session.status != .offline {
                // Running or Idle: terminal preview
                terminalPreview
                    .frame(height: 110)
                    .clipped()
            } else {
                // Offline: "last active" placeholder
                ZStack {
                    Color.black.opacity(0.5)
                    VStack(spacing: 4) {
                        Text("last active")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.white.opacity(0.25))
                        Text(relativeTime)
                            .font(.system(size: 14, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.35))
                    }
                }
                .frame(height: 110)
            }

            // Metadata bar
            VStack(alignment: .leading, spacing: 4) {
                // Row 1: Status badge, diff stats, elapsed time
                HStack(spacing: 6) {
                    Text(statusLabel)
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(statusColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(statusColor.opacity(0.2))
                        .cornerRadius(4)

                    if session.status != .offline && (session.linesAdded > 0 || session.linesRemoved > 0) {
                        Text("+\(session.linesAdded)")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(.green)
                        Text("-\(session.linesRemoved)")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(.red)
                    }

                    Spacer()

                    if session.status == .running {
                        Text(elapsed)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                // Row 2: Git branch (if available)
                if !session.gitBranch.isEmpty {
                    Text(session.gitBranch)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                        .lineLimit(1)
                }

                // Row 3: Project name
                Text(session.projectName)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(8)
        }
        .frame(width: 220)
        .background(Color.black.opacity(isHovered ? 0.4 : 0.3))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    Color.white.opacity(isHovered ? 0.35 : (session.status != .offline ? 0.15 : 0.08)),
                    lineWidth: isHovered ? 1.5 : 1
                )
        )
        .opacity(session.status != .offline ? 1.0 : (isHovered ? 1.0 : 0.5))
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            focusSession()
        }
    }

    @ViewBuilder
    private var terminalPreview: some View {
        if session.terminalContent.isEmpty {
            ZStack {
                Color.black.opacity(0.5)
                Text("No terminal attached")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.white.opacity(0.2))
            }
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    let lines = session.terminalContent.components(separatedBy: "\n").suffix(20)
                    ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.system(size: 7, design: .monospaced))
                            .foregroundColor(colorForLine(line))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(4)
            }
            .background(Color.black.opacity(0.5))
            .allowsHitTesting(false)
        }
    }

    private func colorForLine(_ line: String) -> Color {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("+") { return .green.opacity(0.8) }
        if trimmed.hasPrefix("-") { return .red.opacity(0.8) }
        if trimmed.lowercased().contains("warn") { return .yellow.opacity(0.8) }
        return .white.opacity(0.7)
    }

    private func focusSession() {
        let target = session.tmuxTarget.isEmpty ? session.projectName : session.tmuxTarget

        // Parse "session:window" target into components
        let parts = target.split(separator: ":", maxSplits: 1)
        let sessionName = String(parts[0])
        let windowIndex: String? = parts.count > 1 ? String(parts[1]) : nil

        // Try to find which Ghostty tab already has this tmux session attached
        if let tabIndex = DataBridge().tmuxClientTabIndex(for: target), tabIndex >= 1, tabIndex <= 9 {
            // Activate Ghostty and send Cmd+<N> to switch to the correct tab
            let script = """
                tell application "Ghostty" to activate
                delay 0.1
                tell application "System Events"
                    keystroke "\(tabIndex)" using command down
                end tell
                """
            let osascript = Process()
            osascript.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            osascript.arguments = ["-e", script]
            osascript.standardOutput = Pipe()
            osascript.standardError = Pipe()
            try? osascript.run()
            osascript.waitUntilExit()
        } else {
            // Fallback: activate Ghostty and switch-client
            let osascript = Process()
            osascript.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            osascript.arguments = ["-e", "tell application \"Ghostty\" to activate"]
            osascript.standardOutput = Pipe()
            osascript.standardError = Pipe()
            try? osascript.run()
            osascript.waitUntilExit()

            let tmux = Process()
            tmux.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            tmux.arguments = ["tmux", "switch-client", "-t", sessionName]
            tmux.standardOutput = Pipe()
            tmux.standardError = Pipe()
            try? tmux.run()
            tmux.waitUntilExit()
        }

        // Navigate to the specific tmux window if we have a window index
        if let window = windowIndex {
            let selectWindow = Process()
            selectWindow.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            selectWindow.arguments = ["tmux", "select-window", "-t", "\(sessionName):\(window)"]
            selectWindow.standardOutput = Pipe()
            selectWindow.standardError = Pipe()
            try? selectWindow.run()
            selectWindow.waitUntilExit()
        }
    }
}
