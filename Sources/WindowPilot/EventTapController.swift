import AppKit
import ApplicationServices
import Carbon

final class EventTapController {
    private let switcher: SwitcherController
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private(set) var lastError: String?

    var isRunning: Bool {
        guard let eventTap else { return false }
        return CGEvent.tapIsEnabled(tap: eventTap)
    }

    init(switcher: SwitcherController) {
        self.switcher = switcher
    }

    @discardableResult
    func start(showFailureAlert: Bool = true) -> Bool {
        if isRunning {
            return true
        }

        let mask =
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue) |
            (1 << CGEventType.tapDisabledByTimeout.rawValue) |
            (1 << CGEventType.tapDisabledByUserInput.rawValue)

        let userInfo = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: EventTapController.handleEvent,
            userInfo: userInfo
        ) else {
            lastError = "Could not create CGEventTap. Accessibility permission may not be active yet, or another secure input context is blocking keyboard monitoring."
            DiagnosticLog.write("event tap failed: \(lastError ?? "unknown")")
            if showFailureAlert {
                showEventTapFailure()
            }
            return false
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        if let runLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        }
        CGEvent.tapEnable(tap: tap, enable: true)
        lastError = nil
        DiagnosticLog.write("event tap started")
        NSLog("WindowPilot: event tap started")
        return true
    }

    private func handle(_ proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            DiagnosticLog.write("event tap disabled by system; re-enabling")
            NSLog("WindowPilot: event tap disabled by system; re-enabling")
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        let commandDown = flags.contains(.maskCommand)
        let shiftDown = flags.contains(.maskShift)
        let isTab = keyCode == Int64(kVK_Tab)
        let arrowDirection = arrowDirection(for: keyCode)

        if type == .keyDown, commandDown, isTab {
            DiagnosticLog.write("Command+Tab captured")
            NSLog("WindowPilot: Command+Tab captured")
            switcher.handleCommandTab(reverse: shiftDown)
            return nil
        }

        if type == .keyDown, switcher.isActive, let arrowDirection {
            DiagnosticLog.write("Arrow key captured: \(arrowDirection)")
            switch arrowDirection {
            case .left:
                switcher.moveSelectionBackward()
            case .right:
                switcher.moveSelectionForward()
            case .up:
                switcher.moveSelectionUp()
            case .down:
                switcher.moveSelectionDown()
            }
            return nil
        }

        if type == .keyUp, switcher.isActive, (isTab || arrowDirection != nil) {
            return nil
        }

        if type == .flagsChanged, switcher.isActive, !commandDown {
            switcher.commitSelection()
            return nil
        }

        if type == .keyDown, switcher.isActive, keyCode == Int64(kVK_Escape) {
            switcher.cancel()
            return nil
        }

        return Unmanaged.passUnretained(event)
    }

    private func arrowDirection(for keyCode: Int64) -> ArrowDirection? {
        switch keyCode {
        case Int64(kVK_LeftArrow):
            return .left
        case Int64(kVK_RightArrow):
            return .right
        case Int64(kVK_UpArrow):
            return .up
        case Int64(kVK_DownArrow):
            return .down
        default:
            return nil
        }
    }

    private func showEventTapFailure() {
        let alert = NSAlert()
        alert.messageText = "WindowPilot could not start keyboard monitoring."
        alert.informativeText = "Enable Accessibility permission for WindowPilot, then relaunch the app."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private static let handleEvent: CGEventTapCallBack = { proxy, type, event, userInfo in
        guard let userInfo else {
            return Unmanaged.passUnretained(event)
        }
        let controller = Unmanaged<EventTapController>.fromOpaque(userInfo).takeUnretainedValue()
        return controller.handle(proxy, type: type, event: event)
    }
}

private enum ArrowDirection: String {
    case left
    case right
    case up
    case down
}
