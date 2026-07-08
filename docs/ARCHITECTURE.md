# Architecture

WindowPilot is a small macOS menu bar utility with three responsibilities:

1. Capture the switcher shortcut.
2. Build an ordered list of switchable windows.
3. Present an overlay and focus the selected window.

## Components

### `EventTapController`

Creates a session-level `CGEventTap` for keyboard events. It suppresses `Command+Tab` while the switcher is active, cycles selection on repeated Tab presses, commits when Command is released, and cancels on Escape.

This requires Accessibility permission. If macOS secure input is enabled by another app, the event tap can be temporarily disabled; the controller attempts to re-enable it when macOS reports that condition.

### `AccessibilityService`

Uses `AXUIElement` to enumerate windows for regular running applications and to focus the selected window. `CGWindowListCopyWindowInfo` provides the front-to-back window order, while AX provides the actionable window handles needed to raise/focus a window.

Current filtering excludes minimized windows, very small windows, non-window AX roles, and system dialogs.

### `SwitcherController`

Owns the switcher state machine:

- inactive -> first `Command+Tab` loads windows and shows the overlay
- active -> repeated Tab changes `selectedIndex`
- command released -> focus selected window and hide overlay
- escape -> hide overlay without focusing

### `SwitcherOverlay`

Shows a non-activating translucent `NSPanel` above all spaces. The overlay presents visible windows in a horizontal Windows-style switcher with window thumbnails, app icons, window titles, and a highlighted current selection.

## Known limitations

- Replacing the system `Command+Tab` depends on Accessibility permission and a working event tap.
- Minimized windows are intentionally omitted for the first version.
- Window preview thumbnails require Screen Recording permission.
- Some Electron, browser, or cross-platform apps may expose unusual Accessibility metadata.
- The app is ad-hoc signed for local builds, but not notarized.

## Next implementation milestones

1. Add preferences for shortcut customization and minimized-window behavior.
2. Add a signed app target or generated Xcode project for release builds.
3. Add UI tests or a small diagnostic mode that logs AX window discovery.
