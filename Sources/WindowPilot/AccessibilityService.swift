import AppKit
import ApplicationServices

struct SwitchableWindow {
    let pid: pid_t
    let appName: String
    let bundleIdentifier: String?
    let title: String
    let frame: CGRect
    let cgWindowID: CGWindowID?
    let appElement: AXUIElement
    let windowElement: AXUIElement
    let runningApplication: NSRunningApplication?

    func withCGWindowID(_ cgWindowID: CGWindowID) -> SwitchableWindow {
        SwitchableWindow(
            pid: pid,
            appName: appName,
            bundleIdentifier: bundleIdentifier,
            title: title,
            frame: frame,
            cgWindowID: cgWindowID,
            appElement: appElement,
            windowElement: windowElement,
            runningApplication: runningApplication
        )
    }
}

final class AccessibilityService {
    var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    func requestTrustIfNeeded(prompt: Bool = true) {
        guard !isTrusted else { return }
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [promptKey: prompt] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    func visibleWindows() -> [SwitchableWindow] {
        guard isTrusted else { return [] }

        let frontToBack = cgWindowOrder()
        let runningApps = NSWorkspace.shared.runningApplications.reduce(into: [pid_t: NSRunningApplication]()) { result, app in
            result[app.processIdentifier] = app
        }

        var windowsByPID: [pid_t: [SwitchableWindow]] = [:]
        let currentPID = ProcessInfo.processInfo.processIdentifier
        for app in runningApps.values where app.activationPolicy == .regular {
            guard app.processIdentifier != currentPID else { continue }
            let appElement = AXUIElementCreateApplication(app.processIdentifier)
            let axWindows: [AXUIElement] = copyAttribute(appElement, kAXWindowsAttribute) ?? []

            for window in axWindows {
                guard isWindowSwitchable(window) else { continue }
                let title: String = copyAttribute(window, kAXTitleAttribute) ?? ""
                let frame = windowFrame(window)
                guard frame.width > 20, frame.height > 20 else { continue }

                let item = SwitchableWindow(
                    pid: app.processIdentifier,
                    appName: app.localizedName ?? app.bundleIdentifier ?? "Unknown App",
                    bundleIdentifier: app.bundleIdentifier,
                    title: title.isEmpty ? "Untitled Window" : title,
                    frame: frame,
                    cgWindowID: nil,
                    appElement: appElement,
                    windowElement: window,
                    runningApplication: app
                )
                windowsByPID[app.processIdentifier, default: []].append(item)
            }
        }

        var ordered: [SwitchableWindow] = []

        for cgWindow in frontToBack {
            guard var candidates = windowsByPID[cgWindow.pid], !candidates.isEmpty else { continue }
            if let index = bestMatchIndex(in: candidates, for: cgWindow) {
                let match = candidates.remove(at: index)
                ordered.append(match.withCGWindowID(cgWindow.windowID))
                windowsByPID[cgWindow.pid] = candidates
            }
        }

        return ordered + windowsByPID.values.flatMap { $0 }
    }

    func focus(_ window: SwitchableWindow) {
        window.runningApplication?.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
        AXUIElementSetAttributeValue(window.appElement, kAXFocusedWindowAttribute as CFString, window.windowElement)
        AXUIElementPerformAction(window.windowElement, kAXRaiseAction as CFString)
    }

    private func isWindowSwitchable(_ window: AXUIElement) -> Bool {
        let minimized: Bool = copyAttribute(window, kAXMinimizedAttribute) ?? false
        guard !minimized else { return false }

        let role: String = copyAttribute(window, kAXRoleAttribute) ?? ""
        guard role == kAXWindowRole as String else { return false }

        let subrole: String = copyAttribute(window, kAXSubroleAttribute) ?? ""
        if subrole == kAXSystemDialogSubrole as String {
            return false
        }

        return true
    }

    private func windowFrame(_ window: AXUIElement) -> CGRect {
        let positionValue: AXValue? = copyAttribute(window, kAXPositionAttribute)
        let sizeValue: AXValue? = copyAttribute(window, kAXSizeAttribute)

        var point = CGPoint.zero
        var size = CGSize.zero
        if let positionValue {
            AXValueGetValue(positionValue, .cgPoint, &point)
        }
        if let sizeValue {
            AXValueGetValue(sizeValue, .cgSize, &size)
        }

        return CGRect(origin: point, size: size)
    }

    private func copyAttribute<T>(_ element: AXUIElement, _ attribute: String) -> T? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)
        guard result == .success, let value else { return nil }
        return value as? T
    }

    private func cgWindowOrder() -> [CGWindowSnapshot] {
        guard let rawWindows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return []
        }

        return rawWindows.compactMap { dictionary in
            guard
                let pid = dictionary[kCGWindowOwnerPID as String] as? pid_t,
                let layer = dictionary[kCGWindowLayer as String] as? Int,
                layer == 0
            else {
                return nil
            }

            let title = dictionary[kCGWindowName as String] as? String ?? ""
            let windowID = dictionary[kCGWindowNumber as String] as? CGWindowID ?? 0
            let boundsDictionary = dictionary[kCGWindowBounds as String] as? [String: CGFloat] ?? [:]
            let bounds = CGRect(
                x: boundsDictionary["X"] ?? 0,
                y: boundsDictionary["Y"] ?? 0,
                width: boundsDictionary["Width"] ?? 0,
                height: boundsDictionary["Height"] ?? 0
            )

            return CGWindowSnapshot(pid: pid, windowID: windowID, title: title, bounds: bounds)
        }
    }

    private func bestMatchIndex(in candidates: [SwitchableWindow], for snapshot: CGWindowSnapshot) -> Int? {
        if let exactTitle = candidates.firstIndex(where: { !$0.title.isEmpty && $0.title == snapshot.title }) {
            return exactTitle
        }

        return candidates.enumerated().min { left, right in
            frameDistance(left.element.frame, snapshot.bounds) < frameDistance(right.element.frame, snapshot.bounds)
        }?.offset
    }

    private func frameDistance(_ left: CGRect, _ right: CGRect) -> CGFloat {
        abs(left.minX - right.minX) +
        abs(left.minY - right.minY) +
        abs(left.width - right.width) +
        abs(left.height - right.height)
    }
}

private struct CGWindowSnapshot {
    let pid: pid_t
    let windowID: CGWindowID
    let title: String
    let bounds: CGRect
}
