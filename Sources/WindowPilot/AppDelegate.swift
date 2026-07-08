import AppKit
import ApplicationServices
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var loginItemMenuItem: NSMenuItem?
    private var diagnosticLoggingMenuItem: NSMenuItem?
    private let loginItemService = LoginItemService()
    private var eventTapController: EventTapController?
    private var switcherController: SwitcherController?
    private var permissionTimer: Timer?
    private var statusTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let accessibility = AccessibilityService()
        let overlay = SwitcherOverlay()
        let switcher = SwitcherController(accessibility: accessibility, overlay: overlay)
        let eventTap = EventTapController(switcher: switcher)

        self.switcherController = switcher
        self.eventTapController = eventTap

        configureMenu(accessibility: accessibility)
        accessibility.requestTrustIfNeeded()
        startEventTapWhenTrusted()
        startStatusUpdates()
        promptForOpenAtLoginIfNeeded()
    }

    private func configureMenu(accessibility: AccessibilityService) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = StatusIconFactory.make(active: false)
        item.button?.imagePosition = .imageOnly
        item.button?.toolTip = "WindowPilot is starting"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Switcher Now", action: #selector(showSwitcherNow), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Show Diagnostics", action: #selector(showDiagnostics), keyEquivalent: ""))
        let diagnosticLogging = NSMenuItem(title: "Diagnostic Logging", action: #selector(toggleDiagnosticLogging), keyEquivalent: "")
        diagnosticLoggingMenuItem = diagnosticLogging
        menu.addItem(diagnosticLogging)
        menu.addItem(NSMenuItem.separator())
        let loginItem = NSMenuItem(title: "Open at Login", action: #selector(toggleOpenAtLogin), keyEquivalent: "")
        loginItemMenuItem = loginItem
        menu.addItem(loginItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Request Accessibility Permission", action: #selector(requestAccessibilityPermission), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Request Screen Recording Permission", action: #selector(requestScreenRecordingPermission), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit WindowPilot", action: #selector(quit), keyEquivalent: "q"))
        item.menu = menu

        statusItem = item
        updateLoginItemMenu()
        updateDiagnosticLoggingMenu()
    }

    @objc private func requestAccessibilityPermission() {
        switcherController?.accessibility.requestTrustIfNeeded(prompt: true)
        startEventTapWhenTrusted()
    }

    @objc private func requestScreenRecordingPermission() {
        _ = CGRequestScreenCaptureAccess()
    }

    @objc private func showSwitcherNow() {
        switcherController?.showForDiagnostics()
    }

    @objc private func showDiagnostics() {
        guard let switcherController else { return }
        let diagnostics = switcherController.diagnostics(
            eventTapRunning: eventTapController?.isRunning ?? false,
            eventTapError: eventTapController?.lastError
        )

        let alert = NSAlert()
        alert.messageText = "WindowPilot Diagnostics"
        alert.informativeText = diagnostics
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    @objc private func toggleOpenAtLogin() {
        do {
            if loginItemService.isEnabled {
                try loginItemService.unregister()
            } else {
                try loginItemService.register()
            }
            updateLoginItemMenu()
        } catch {
            showLoginItemError(error)
        }
    }

    @objc private func toggleDiagnosticLogging() {
        DiagnosticLog.setEnabled(!DiagnosticLog.isEnabled)
        updateDiagnosticLoggingMenu()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func startEventTapWhenTrusted() {
        guard let accessibility = switcherController?.accessibility else { return }

        if accessibility.isTrusted {
            permissionTimer?.invalidate()
            permissionTimer = nil
            _ = eventTapController?.start()
            updateStatusItem()
            return
        }

        permissionTimer?.invalidate()
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self, let accessibility = self.switcherController?.accessibility else {
                timer.invalidate()
                return
            }

            if accessibility.isTrusted {
                timer.invalidate()
                self.permissionTimer = nil
                _ = self.eventTapController?.start(showFailureAlert: false)
                self.updateStatusItem()
            }
        }
    }

    private func startStatusUpdates() {
        statusTimer?.invalidate()
        statusTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateStatusItem()
        }
        updateStatusItem()
    }

    private func updateStatusItem() {
        let trusted = switcherController?.accessibility.isTrusted ?? false
        let running = eventTapController?.isRunning ?? false
        statusItem?.button?.image = StatusIconFactory.make(active: trusted && running)
        statusItem?.button?.toolTip = trusted && running ? "WindowPilot is active" : "WindowPilot needs attention"
        updateLoginItemMenu()
        updateDiagnosticLoggingMenu()
        DiagnosticLog.write("status trusted=\(trusted) eventTapRunning=\(running)")
    }

    private func promptForOpenAtLoginIfNeeded() {
        guard loginItemService.shouldPrompt else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self, self.loginItemService.shouldPrompt else { return }

            let alert = NSAlert()
            alert.messageText = "Open WindowPilot at login?"
            alert.informativeText = "WindowPilot works best as a background utility. Add it to Login Items so window switching is available after you start your Mac."
            alert.addButton(withTitle: "Enable")
            alert.addButton(withTitle: "Not Now")
            alert.addButton(withTitle: "Don't Ask Again")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                do {
                    try self.loginItemService.register()
                    self.loginItemService.markPrompted()
                    self.updateLoginItemMenu()
                } catch {
                    self.showLoginItemError(error)
                }
            } else if response == .alertThirdButtonReturn {
                self.loginItemService.markPrompted()
            }
        }
    }

    private func updateLoginItemMenu() {
        guard let loginItemMenuItem else { return }

        switch loginItemService.status {
        case .enabled:
            loginItemMenuItem.title = "Open at Login: On"
            loginItemMenuItem.state = .on
        case .requiresApproval:
            loginItemMenuItem.title = "Open at Login: Needs Approval"
            loginItemMenuItem.state = .mixed
        default:
            loginItemMenuItem.title = "Open at Login: Off"
            loginItemMenuItem.state = .off
        }
    }

    private func updateDiagnosticLoggingMenu() {
        guard let diagnosticLoggingMenuItem else { return }
        diagnosticLoggingMenuItem.title = DiagnosticLog.isEnabled ? "Diagnostic Logging: On" : "Diagnostic Logging: Off"
        diagnosticLoggingMenuItem.state = DiagnosticLog.isEnabled ? .on : .off
    }

    private func showLoginItemError(_ error: Error) {
        updateLoginItemMenu()

        let alert = NSAlert()
        alert.messageText = "Could not update Login Items"
        alert.informativeText = "Status: \(loginItemService.statusDescription())\n\n\(error.localizedDescription)"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
