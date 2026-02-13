import AppKit
import SwiftUI

// MARK: - Notch State

enum NotchState {
    case closed
    case open
}

// MARK: - NotchViewModel

class NotchViewModel: ObservableObject {
    @Published var notchState: NotchState = .closed

    let closedSize: CGSize
    let openSize: CGSize

    init() {
        self.closedSize = NotchSizing.getClosedNotchSize()
        self.openSize = NotchSizing.openSize
    }

    func open() {
        notchState = .open
    }

    func close() {
        notchState = .closed
    }
}

// MARK: - AppState

class AppState: ObservableObject {
    @Published var sessions: [AgentSession] = []
    @Published var projects: [ProjectStatus] = []
    @Published var memories: [Memory] = []

    private let bridge = DataBridge()
    private let refreshQueue = DispatchQueue(label: "cyclops.refresh", qos: .userInitiated)

    func refresh() {
        refreshQueue.async { [self] in
            var sessions = bridge.fetchSessions()
            let projects = bridge.fetchProjects()
            let memories = bridge.fetchMemories()

            for i in sessions.indices {
                guard sessions[i].isActive else { continue }
                let tmuxTarget = sessions[i].tmuxSession.isEmpty ? sessions[i].projectName : sessions[i].tmuxSession
                sessions[i].terminalContent = bridge.captureTerminalContent(for: tmuxTarget)
                let stats = bridge.fetchDiffStats(workspacePath: sessions[i].workspacePath)
                sessions[i].linesAdded = stats.added
                sessions[i].linesRemoved = stats.removed
            }

            DispatchQueue.main.async { [self] in
                self.sessions = sessions
                self.projects = projects
                self.memories = memories
            }
        }
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: CyclopsWindow!
    var mouseTracker: MouseTracker!
    var appState = AppState()
    var notchVM = NotchViewModel()
    var refreshTimer: Timer?
    var keyMonitor: Any?
    private var panelVisible = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create panel at fixed frame — it will NEVER be resized
        let frame = NotchSizing.fixedFrame()
        let newPanel = CyclopsWindow(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        // Host SwiftUI view — it handles its own background via NotchShape clip
        let hostingView = NSHostingView(
            rootView: AgentView()
                .environmentObject(appState)
                .environmentObject(notchVM)
        )
        hostingView.frame = NSRect(origin: .zero, size: frame.size)
        hostingView.autoresizingMask = [.width, .height]
        newPanel.contentView = hostingView

        self.panel = newPanel

        // Register with CGSSpace for above-everything rendering
        newPanel.orderFront(nil)
        newPanel.registerWithNotchSpace()

        // Panel stays at fixed frame forever — SwiftUI handles all animation
        panel.alphaValue = 1

        // Mouse tracking
        let tracker = MouseTracker()
        tracker.onShow = { [weak self] in self?.showPanel() }
        tracker.onHide = { [weak self] in self?.hidePanel() }
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
        notchVM.open()
    }

    private func hidePanel() {
        guard panelVisible else { return }
        panelVisible = false
        notchVM.close()
    }
}
