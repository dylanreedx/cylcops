import SwiftUI

struct MemoryCardView: View {
    let memory: Memory
    @State private var isHovered = false

    private static let tagColors: [Color] = [
        .teal, .purple, .orange, .pink, .blue, .green
    ]

    private static func colorForTag(_ tag: String) -> Color {
        // djb2 hash
        var hash: UInt64 = 5381
        for char in tag.utf8 {
            hash = ((hash &<< 5) &+ hash) &+ UInt64(char)
        }
        return tagColors[Int(hash % UInt64(tagColors.count))]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Memory name (2 lines max)
            Text(memory.name)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Content preview (2 lines max)
            Text(memory.content)
                .font(.system(size: 8))
                .foregroundColor(.white.opacity(0.5))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

            // Tag pills + project name
            HStack(spacing: 3) {
                let visibleTags = Array(memory.tags.prefix(3))
                let overflow = memory.tags.count - 3

                ForEach(visibleTags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 7, weight: .medium))
                        .foregroundColor(Self.colorForTag(tag))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Self.colorForTag(tag).opacity(0.15))
                        .cornerRadius(3)
                }

                if overflow > 0 {
                    Text("+\(overflow)")
                        .font(.system(size: 7, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }

                Spacer(minLength: 0)

                if !memory.projectName.isEmpty {
                    Text(memory.projectName)
                        .font(.system(size: 7, design: .monospaced))
                        .foregroundColor(.white.opacity(0.3))
                        .lineLimit(1)
                }
            }
        }
        .padding(8)
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
}
