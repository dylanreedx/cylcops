import SwiftUI

struct SessionCardView: View {
    let session: AgentSession

    private var statusColor: Color {
        session.isActive ? .green : .gray
    }

    private var statusLabel: String {
        session.isActive ? "ACTIVE" : "INACTIVE"
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
            if session.isActive {
                // Active: terminal preview
                terminalPreview
                    .frame(height: 110)
                    .clipped()
            } else {
                // Inactive: "last active" placeholder
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

                    if session.isActive && (session.linesAdded > 0 || session.linesRemoved > 0) {
                        Text("+\(session.linesAdded)")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(.green)
                        Text("-\(session.linesRemoved)")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(.red)
                    }

                    Spacer()

                    if session.isActive {
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
        .background(Color.black.opacity(0.3))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(session.isActive ? 0.15 : 0.08), lineWidth: 1)
        )
        .opacity(session.isActive ? 1.0 : 0.5)
        .onTapGesture {
            if session.isActive {
                focusSession()
            }
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
        // Activate Ghostty
        let osascript = Process()
        osascript.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        osascript.arguments = ["-e", "tell application \"Ghostty\" to activate"]
        osascript.standardOutput = Pipe()
        osascript.standardError = Pipe()
        try? osascript.run()
        osascript.waitUntilExit()

        // Switch tmux client to session
        let tmux = Process()
        tmux.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        let target = session.tmuxSession.isEmpty ? session.projectName : session.tmuxSession
        tmux.arguments = ["tmux", "switch-client", "-t", target]
        tmux.standardOutput = Pipe()
        tmux.standardError = Pipe()
        try? tmux.run()
        tmux.waitUntilExit()
    }
}
