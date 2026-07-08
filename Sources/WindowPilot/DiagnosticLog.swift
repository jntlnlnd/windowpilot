import Foundation

enum DiagnosticLog {
    private static let enabledKey = "diagnosticLoggingEnabled"
    private static let logURL = URL(fileURLWithPath: "/tmp/windowpilot.log")

    static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: enabledKey) ||
        ProcessInfo.processInfo.environment["WINDOWPILOT_DEBUG_LOG"] == "1"
    }

    static func setEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: enabledKey)
    }

    static func write(_ message: String) {
        guard isEnabled else { return }

        let formatter = ISO8601DateFormatter()
        let line = "\(formatter.string(from: Date())) \(message)\n"
        guard let data = line.data(using: .utf8) else { return }

        if FileManager.default.fileExists(atPath: logURL.path),
           let handle = try? FileHandle(forWritingTo: logURL) {
            defer { try? handle.close() }
            _ = try? handle.seekToEnd()
            try? handle.write(contentsOf: data)
        } else {
            try? data.write(to: logURL)
        }
    }
}
