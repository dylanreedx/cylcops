import AppKit
import SwiftUI

class AppState: ObservableObject {
    @Published var sessions: [AgentSession] = []
    @Published var projects: [ProjectStatus] = []

    private let bridge = DataBridge()

    func refresh() {
        sessions = bridge.fetchSessions()
        projects = bridge.fetchProjects()
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: NSPanel!
    var mouseTracker: MouseTracker!
    var appState = AppState()
    var refreshTimer: Timer?
    var keyMonitor: Any?
    private var panelVisible = false

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
        let hostingView = NSHostingView(rootView: AgentView().environmentObject(appState))
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

        // Start hidden
        panel.alphaValue = 0
        panel.orderOut(nil)

        // Start mouse tracking
        let tracker = MouseTracker()
        tracker.panelFrame = panel.frame
        tracker.onShow = { [weak self] in
            self?.showPanel()
        }
        tracker.onHide = { [weak self] in
            self?.hidePanel()
        }
        tracker.start()
        self.mouseTracker = tracker

        // Global keyboard shortcut: Cmd+Shift+C
        keyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.modifierFlags.contains([.command, .shift]),
                  event.charactersIgnoringModifiers == "c" else { return }
            self?.togglePanel()
        }

        // Periodic data refresh
        appState.refresh()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.appState.refresh()
        }
    }

    private func togglePanel() {
        if panelVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }

    private func showPanel() {
        guard !panelVisible else { return }
        panelVisible = true
        panel.alphaValue = 0
        panel.orderFront(nil)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            panel.animator().alphaValue = 1
        }
    }

    private func hidePanel() {
        guard panelVisible else { return }
        panelVisible = false
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            self?.panel.orderOut(nil)
        })
    }
}
