import AppKit

class MouseTracker {
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var showDebounceTimer: Timer?
    private var hideDebounceTimer: Timer?

    var onShow: (() -> Void)?
    var onHide: (() -> Void)?

    private var isShowing = false

    /// Hot zone matches the actual notch dimensions and position
    private var hotZone: NSRect {
        guard let screen = NSScreen.main else { return .zero }
        let notchSize = NotchSizing.getClosedNotchSize(screen: screen)
        let screenFrame = screen.frame
        let x = screenFrame.origin.x + (screenFrame.width - notchSize.width) / 2
        let y = screenFrame.origin.y + screenFrame.height - notchSize.height
        return NSRect(x: x, y: y, width: notchSize.width, height: notchSize.height)
    }

    /// Expanded zone covers the full fixed panel frame
    private var expandedZone: NSRect {
        NotchSizing.fixedFrame()
    }

    private func isInActiveArea(_ point: NSPoint) -> Bool {
        if isShowing {
            return expandedZone.contains(point)
        } else {
            return hotZone.contains(point)
        }
    }

    func start() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] _ in
            self?.handleMouseMove()
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .mouseEntered, .mouseExited]) { [weak self] event in
            self?.handleMouseMove()
            return event
        }
    }

    private func handleMouseMove() {
        let location = NSEvent.mouseLocation
        let inActive = isInActiveArea(location)

        if inActive && !isShowing {
            // Mouse entered hot zone — debounce before opening
            hideDebounceTimer?.invalidate()
            hideDebounceTimer = nil

            if showDebounceTimer == nil {
                showDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
                    guard let self = self else { return }
                    let currentLocation = NSEvent.mouseLocation
                    if self.hotZone.contains(currentLocation) {
                        self.isShowing = true
                        self.onShow?()
                    }
                    self.showDebounceTimer = nil
                }
            }
        } else if inActive && isShowing {
            // Mouse still in expanded zone — cancel any pending hide
            hideDebounceTimer?.invalidate()
            hideDebounceTimer = nil
            showDebounceTimer?.invalidate()
            showDebounceTimer = nil
        } else if !inActive && isShowing {
            // Mouse left expanded zone — debounce before closing
            showDebounceTimer?.invalidate()
            showDebounceTimer = nil

            if hideDebounceTimer == nil {
                hideDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
                    guard let self = self else { return }
                    let currentLocation = NSEvent.mouseLocation
                    if !self.isInActiveArea(currentLocation) {
                        self.isShowing = false
                        self.onHide?()
                    }
                    self.hideDebounceTimer = nil
                }
            }
        } else {
            // Mouse not in any zone and not showing — cancel pending show
            showDebounceTimer?.invalidate()
            showDebounceTimer = nil
        }
    }

    func stop() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        showDebounceTimer?.invalidate()
        showDebounceTimer = nil
        hideDebounceTimer?.invalidate()
        hideDebounceTimer = nil
    }

    deinit {
        stop()
    }
}
