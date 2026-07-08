import AppKit
import ServiceManagement

final class LoginItemService {
    private let promptKey = "didPromptForOpenAtLogin"

    var status: SMAppService.Status {
        SMAppService.mainApp.status
    }

    var isEnabled: Bool {
        status == .enabled
    }

    var shouldPrompt: Bool {
        !UserDefaults.standard.bool(forKey: promptKey) && !isEnabled
    }

    func markPrompted() {
        UserDefaults.standard.set(true, forKey: promptKey)
    }

    func register() throws {
        try SMAppService.mainApp.register()
    }

    func unregister() throws {
        try SMAppService.mainApp.unregister()
    }

    func statusDescription() -> String {
        switch status {
        case .enabled:
            return "enabled"
        case .notRegistered:
            return "not registered"
        case .requiresApproval:
            return "requires approval in System Settings"
        case .notFound:
            return "not found"
        @unknown default:
            return "unknown"
        }
    }
}
