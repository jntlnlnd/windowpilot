# Privacy

WindowPilot is a local macOS utility.

## What the app accesses

- Window titles and app names, to show the switcher list.
- Window thumbnails, when Screen Recording permission is granted.
- Keyboard events needed to intercept the switcher shortcut.

WindowPilot does not continuously record the screen. It captures still window thumbnails only when those windows are shown in the switcher overlay, caches them while that overlay is open, and discards the cache when the overlay closes.

## What the app stores

- User preferences in macOS `UserDefaults`, such as whether Open at Login was prompted.
- Optional diagnostic logs only when the user enables Diagnostic Logging.
- In-memory window thumbnail cache while the switcher overlay is open.

## What the app sends

Nothing. WindowPilot has no network integration and does not send analytics, telemetry, screenshots, window titles, or usage data.

## Permissions can be revoked

Permissions can be revoked in `System Settings > Privacy & Security`.
