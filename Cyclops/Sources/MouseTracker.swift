import AppKit

class MouseTracker {
    private var globalMonitor: Any?
    var onMouseMoved: ((NSPoint) -> Void)?

    func start() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            let location = NSEvent.mouseLocation
            self?.onMouseMoved?(location)
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
