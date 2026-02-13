import AppKit

struct NotchSizing {
    /// Detect if the screen has a physical notch
    static func hasNotch(screen: NSScreen = NSScreen.main ?? NSScreen.screens[0]) -> Bool {
        return screen.safeAreaInsets.top > 0
    }

    /// Get the closed notch size matching the physical notch dimensions
    static func getClosedNotchSize(screen: NSScreen = NSScreen.main ?? NSScreen.screens[0]) -> CGSize {
        if hasNotch(screen: screen) {
            let height = screen.safeAreaInsets.top
            // Calculate width from the gap between auxiliary areas
            if let auxLeft = screen.auxiliaryTopLeftArea,
               let auxRight = screen.auxiliaryTopRightArea {
                let width = auxRight.origin.x - (auxLeft.origin.x + auxLeft.width)
                return CGSize(width: max(width, 185), height: max(height, 32))
            }
            return CGSize(width: 185, height: max(height, 32))
        } else {
            // Non-notch Mac: use menu bar height and reasonable width
            let menuBarHeight = screen.frame.height - screen.visibleFrame.height
                - (screen.visibleFrame.origin.y - screen.frame.origin.y)
            return CGSize(width: 185, height: max(menuBarHeight, 24))
        }
    }

    /// Open panel size — wide enough for carousel content
    static let openSize = CGSize(width: 700, height: 300)

    /// Shadow padding below content area
    static let shadowPadding: CGFloat = 20

    /// Get the screen-top Y position (top of the physical screen)
    static func screenTopY(screen: NSScreen = NSScreen.main ?? NSScreen.screens[0]) -> CGFloat {
        return screen.frame.origin.y + screen.frame.height
    }

    /// Closed frame: centered at notch position, flush with screen top
    static func closedFrame(screen: NSScreen = NSScreen.main ?? NSScreen.screens[0]) -> NSRect {
        let size = getClosedNotchSize(screen: screen)
        let x = screen.frame.origin.x + (screen.frame.width - size.width) / 2
        let y = screenTopY(screen: screen) - size.height
        return NSRect(x: x, y: y, width: size.width, height: size.height)
    }

    /// Expanded frame: expands downward from screen top, centered
    static func expandedFrame(screen: NSScreen = NSScreen.main ?? NSScreen.screens[0]) -> NSRect {
        let totalHeight = openSize.height + shadowPadding
        let x = screen.frame.origin.x + (screen.frame.width - openSize.width) / 2
        let y = screenTopY(screen: screen) - totalHeight
        return NSRect(x: x, y: y, width: openSize.width, height: totalHeight)
    }

    /// The one permanent window size — open width + full height with shadow padding
    static var windowSize: CGSize {
        CGSize(width: openSize.width, height: openSize.height + shadowPadding)
    }

    /// Fixed frame that the panel uses for its entire lifetime (never resized)
    static func fixedFrame(screen: NSScreen = NSScreen.main ?? NSScreen.screens[0]) -> NSRect {
        let size = windowSize
        let x = screen.frame.origin.x + (screen.frame.width - size.width) / 2
        let y = screenTopY(screen: screen) - size.height
        return NSRect(x: x, y: y, width: size.width, height: size.height)
    }
}
