import SwiftUI

struct SessionCardView: View {
    let session: AgentSession

    private var statusColor: Color {
        switch session.status {
        case "active": return .green
        case "pending": return .yellow
        case "completed": return .blue
        default: return .gray
        }
    }

    private var elapsed: String {
        let interval = Date().timeIntervalSince(session.startedAt)
        let minutes = Int(interval) / 60
        let hours = minutes / 60
        if hours > 0 {
            return "\(hours)h \(minutes % 60)m"
        }
        return "\(minutes)m"
    }

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.projectName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Text(String(session.id.prefix(8)))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
            }

            Spacer()

            Text(elapsed)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(10)
        .background(Color.white.opacity(0.06))
        .cornerRadius(8)
    }
}
