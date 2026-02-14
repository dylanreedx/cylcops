import AppKit

class CyclopsWindow: NSPanel {
    override init(
        contentRect: NSRect,
        styleMask style: NSWindow.StyleMask,
        backing backingStoreType: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        configure()
    }

    private func configure() {
        // Window level above menu bar (like BoringNotch)
        level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))
        hasShadow = false
        backgroundColor = .clear
        isOpaque = false
        isMovableByWindowBackground = false
        hidesOnDeactivate = false
        titleVisibility = .hidden
        titlebarAppearsTransparent = true

        acceptsMouseMovedEvents = true

        // Make it behave like a floating overlay
        collectionBehavior = [
            .fullScreenAuxiliary,
            .stationary,
            .canJoinAllSpaces,
            .ignoresCycle
        ]
    }

    // Prevent window from becoming key or main (no focus stealing)
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    /// Register this window with the CGSSpace for top-level z-ordering
    func registerWithNotchSpace() {
        NotchSpaceManager.shared.addWindow(windowNumber)
    }

    /// Remove from the CGSSpace
    func unregisterFromNotchSpace() {
        NotchSpaceManager.shared.removeWindow(windowNumber)
    }
}
