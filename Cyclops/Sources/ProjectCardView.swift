import SwiftUI

struct ProjectCardView: View {
    let project: ProjectStatus
    @State private var isHovered = false

    private var progressPercent: Int {
        guard project.totalFeatures > 0 else { return 0 }
        return Int((Double(project.passedFeatures) / Double(project.totalFeatures)) * 100)
    }

    var body: some View {
        VStack(spacing: 6) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: project.progressPercent)
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                Text("\(progressPercent)%")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
            }
            .frame(width: 36, height: 36)

            // Project name
            Text(project.name)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)

            // Badge row
            HStack(spacing: 4) {
                badgeDot(count: project.passedFeatures, color: .green)
                if project.failedFeatures > 0 {
                    badgeDot(count: project.failedFeatures, color: .red)
                }
                if project.inProgressFeatures > 0 {
                    badgeDot(count: project.inProgressFeatures, color: .yellow)
                }
            }
        }
        .frame(width: 160, height: 95)
        .background(Color.black.opacity(isHovered ? 0.4 : 0.3))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(isHovered ? 0.35 : 0.15), lineWidth: isHovered ? 1.5 : 1)
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }

    @ViewBuilder
    private func badgeDot(count: Int, color: Color) -> some View {
        HStack(spacing: 2) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text("\(count)")
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundColor(color.opacity(0.9))
        }
    }
}
