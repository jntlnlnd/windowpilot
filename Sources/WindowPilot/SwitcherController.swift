import AppKit

final class SwitcherController {
    let accessibility: AccessibilityService

    private let overlay: SwitcherOverlay
    private var windows: [SwitchableWindow] = []
    private var selectedIndex = 0

    var isActive: Bool {
        overlay.isVisible
    }

    init(accessibility: AccessibilityService, overlay: SwitcherOverlay) {
        self.accessibility = accessibility
        self.overlay = overlay
    }

    func handleCommandTab(reverse: Bool) {
        if !accessibility.isTrusted {
            DiagnosticLog.write("Command+Tab ignored because Accessibility is not trusted")
            NSLog("WindowPilot: Accessibility is not trusted")
            accessibility.requestTrustIfNeeded(prompt: true)
            return
        }

        if !isActive {
            begin(reverse: reverse)
        } else {
            moveSelection(reverse: reverse)
        }
    }

    func commitSelection() {
        guard isActive else { return }
        let selected = windows.indices.contains(selectedIndex) ? windows[selectedIndex] : nil
        overlay.hide()
        windows.removeAll()

        if let selected {
            DiagnosticLog.write("focusing selected window")
            NSLog("WindowPilot: focusing \(selected.appName) - \(selected.title)")
            accessibility.focus(selected)
        }
    }

    func cancel() {
        overlay.hide()
        windows.removeAll()
    }

    func moveSelectionForward() {
        moveSelection(reverse: false)
    }

    func moveSelectionBackward() {
        moveSelection(reverse: true)
    }

    func moveSelectionUp() {
        moveSelectionVertically(offset: -SwitcherOverlay.columnCount)
    }

    func moveSelectionDown() {
        moveSelectionVertically(offset: SwitcherOverlay.columnCount)
    }

    private func begin(reverse: Bool) {
        windows = accessibility.visibleWindows()
        DiagnosticLog.write("discovered \(windows.count) switchable windows")
        NSLog("WindowPilot: discovered \(windows.count) switchable windows")
        guard !windows.isEmpty else { return }

        if windows.count == 1 {
            selectedIndex = 0
        } else {
            selectedIndex = reverse ? windows.count - 1 : 1
        }

        overlay.show(windows: windows, selectedIndex: selectedIndex)
    }

    func showForDiagnostics() {
        guard accessibility.isTrusted else {
            accessibility.requestTrustIfNeeded(prompt: true)
            return
        }

        windows = accessibility.visibleWindows()
        selectedIndex = windows.count > 1 ? 1 : 0
        guard !windows.isEmpty else { return }
        overlay.show(windows: windows, selectedIndex: selectedIndex)
    }

    func diagnostics(eventTapRunning: Bool, eventTapError: String?) -> String {
        let currentWindows = accessibility.visibleWindows()
        let windowLines = currentWindows.prefix(12).map { window in
            "- \(window.appName): \(window.title)"
        }.joined(separator: "\n")

        return """
        Accessibility trusted: \(accessibility.isTrusted)
        Screen capture allowed: \(CGPreflightScreenCaptureAccess())
        Event tap running: \(eventTapRunning)
        Event tap error: \(eventTapError ?? "none")
        Switchable windows: \(currentWindows.count)

        \(windowLines.isEmpty ? "No switchable windows found." : windowLines)
        """
    }

    private func moveSelection(reverse: Bool) {
        guard !windows.isEmpty else { return }

        if reverse {
            selectedIndex = (selectedIndex - 1 + windows.count) % windows.count
        } else {
            selectedIndex = (selectedIndex + 1) % windows.count
        }

        overlay.update(windows: windows, selectedIndex: selectedIndex)
    }

    private func moveSelectionVertically(offset: Int) {
        guard !windows.isEmpty else { return }

        let targetIndex = selectedIndex + offset
        selectedIndex = min(max(targetIndex, 0), windows.count - 1)
        overlay.update(windows: windows, selectedIndex: selectedIndex)
    }
}
