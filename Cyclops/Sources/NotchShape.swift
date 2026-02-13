import SwiftUI

struct NotchShape: Shape {
    var topCornerRadius: CGFloat
    var bottomCornerRadius: CGFloat

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(topCornerRadius, bottomCornerRadius) }
        set {
            topCornerRadius = newValue.first
            bottomCornerRadius = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let minX = rect.minX
        let maxX = rect.maxX
        let minY = rect.minY
        let maxY = rect.maxY

        let br = min(bottomCornerRadius, rect.height / 2, rect.width / 2)

        // Start at top-left — flat against screen top edge
        path.move(to: CGPoint(x: minX, y: minY))

        // Top edge — straight across (flush with screen top)
        path.addLine(to: CGPoint(x: maxX, y: minY))

        // Top-right corner — tight radius
        // Move down along right edge
        path.addLine(to: CGPoint(x: maxX, y: maxY - br))

        // Bottom-right corner — quadratic Bézier curve (notch-like)
        path.addQuadCurve(
            to: CGPoint(x: maxX - br, y: maxY),
            control: CGPoint(x: maxX, y: maxY)
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: minX + br, y: maxY))

        // Bottom-left corner — quadratic Bézier curve (notch-like)
        path.addQuadCurve(
            to: CGPoint(x: minX, y: maxY - br),
            control: CGPoint(x: minX, y: maxY)
        )

        // Left edge back to top
        path.addLine(to: CGPoint(x: minX, y: minY))

        path.closeSubpath()
        return path
    }

    // Preset sizes matching BoringNotch
    static let closed = NotchShape(topCornerRadius: 6, bottomCornerRadius: 14)
    static let open = NotchShape(topCornerRadius: 19, bottomCornerRadius: 24)
}
