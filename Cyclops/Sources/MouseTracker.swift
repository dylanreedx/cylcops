import AppKit

class MouseTracker {
    private var globalMonitor: Any?
    private var wasInZone = false

    var panelFrame: NSRect = .zero
    var onShow: (() -> Void)?
    var onHide: (() -> Void)?

    private var hotZone: NSRect {
        guard let screen = NSScreen.main else { return .zero }
        let screenFrame = screen.frame
        let zoneWidth: CGFloat = 400
        let zoneHeight: CGFloat = 24
        let x = screenFrame.origin.x + (screenFrame.width - zoneWidth) / 2
        let y = screenFrame.origin.y + screenFrame.height - zoneHeight
        return NSRect(x: x, y: y, width: zoneWidth, height: zoneHeight)
    }

    func start() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            guard let self = self else { return }
            let location = NSEvent.mouseLocation
            let inZone = self.hotZone.contains(location)
            let inPanel = self.panelFrame.contains(location)

            if (inZone || inPanel) && !self.wasInZone {
                self.wasInZone = true
                self.onShow?()
            } else if !inZone && !inPanel && self.wasInZone {
                self.wasInZone = false
                self.onHide?()
            }
        }
    }

    func stop() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
    }

    deinit {
        stop()
    }
}
