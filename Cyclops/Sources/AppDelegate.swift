import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: NSPanel!
    var mouseTracker: MouseTracker!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 480),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isMovableByWindowBackground = false
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .transient]
        panel.isOpaque = false
        panel.hasShadow = true

        // Glassmorphism backdrop
        let visualEffect = NSVisualEffectView(frame: panel.contentView!.bounds)
        visualEffect.material = .hudWindow
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 16
        visualEffect.layer?.masksToBounds = true
        visualEffect.autoresizingMask = [.width, .height]
        panel.contentView = visualEffect

        // Host SwiftUI view on top of visual effect
        let hostingView = NSHostingView(rootView: AgentView())
        hostingView.frame = visualEffect.bounds
        hostingView.autoresizingMask = [.width, .height]
        visualEffect.addSubview(hostingView)

        // Position centered under the notch / menu bar
        if let screen = NSScreen.main {
            let screenFrame = screen.frame
            let visibleFrame = screen.visibleFrame
            let menuBarHeight = screenFrame.height - visibleFrame.height - visibleFrame.origin.y + screenFrame.origin.y
            let panelWidth: CGFloat = 360
            let panelHeight: CGFloat = 480
            let x = screenFrame.origin.x + (screenFrame.width - panelWidth) / 2
            let y = screenFrame.origin.y + screenFrame.height - menuBarHeight - panelHeight - 8
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        self.panel = panel

        // Start mouse tracking
        let tracker = MouseTracker()
        tracker.onMouseMoved = { [weak self] location in
            _ = self?.panel
            _ = location
        }
        tracker.start()
        self.mouseTracker = tracker
    }
}
