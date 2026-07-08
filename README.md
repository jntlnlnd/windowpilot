# WindowPilot

**Download: [click here](https://raw.githubusercontent.com/jntlnlnd/windowpilot/main/release/WindowPilot.dmg)**

Windows-style window switcher for macOS. It replaces the usual application-level `Command+Tab` flow with a window-level switcher backed by macOS Accessibility APIs.

This project is not affiliated with Apple.

## Current behavior

- Intercepts `Command+Tab`.
- Shows a compact overlay of visible windows, ordered front-to-back.
- Repeated `Command+Tab` cycles forward.
- `Command+Shift+Tab` cycles backward.
- Releasing `Command` raises and focuses the selected window.
- Runs as a menu bar utility.
- Can add itself to Login Items so it opens when macOS starts.

## Required permissions

The app needs Accessibility permission because macOS only allows another app to inspect and focus windows through the Accessibility API. Window thumbnails may also require Screen Recording permission.

1. Build and launch the app.
2. Open `System Settings > Privacy & Security > Accessibility`.
3. Enable `WindowPilot`.
4. Open `System Settings > Privacy & Security > Screen & System Audio Recording`.
5. Enable `WindowPilot` if thumbnails are blank.
6. Relaunch the app if the event tap does not start immediately.

## Open at login

On first launch, WindowPilot asks whether it should open at login. You can also toggle this later from the menu bar item with `Open at Login`.

## Build

This repository is a Swift Package that can also be wrapped as a `.app` bundle:

```sh
scripts/build_app.sh
open .build/app/WindowPilot.app
```

To build a local installer DMG:

```sh
scripts/build_dmg.sh
open dist/WindowPilot.dmg
```

If `Sources/WindowPilot/Resources/Assets/AppIconSource.png` changes, regenerate the macOS icon first:

```sh
scripts/generate_icons.sh
```

## Download

The current DMG can be downloaded directly from [release/WindowPilot.dmg](https://raw.githubusercontent.com/jntlnlnd/windowpilot/main/release/WindowPilot.dmg). This build is ad-hoc signed and not notarized, so macOS may show a first-run warning.

### If macOS blocks the DMG

Because this build is not notarized with an Apple Developer ID, macOS may show a warning like this when you open the downloaded DMG:

![macOS warning that WindowPilot.dmg cannot be opened](docs/assets/gatekeeper-warning.png)

To allow it:

1. Click `Done`.
2. Open `System Settings > Privacy & Security`.
3. In the `Security` section, find the message that `WindowPilot.dmg` was blocked.
4. Click `Open Anyway`.

![Privacy & Security Open Anyway button for WindowPilot.dmg](docs/assets/gatekeeper-privacy-open-anyway.png)

After that, open `WindowPilot.dmg` again and drag `WindowPilot.app` into Applications. If macOS blocks `WindowPilot.app` on first launch as well, repeat the same `Privacy & Security > Open Anyway` flow for the app.

If you prefer Terminal, you can remove the quarantine attribute from the downloaded DMG:

```sh
xattr -d com.apple.quarantine ~/Downloads/WindowPilot.dmg
open ~/Downloads/WindowPilot.dmg
```

If the installed app is also blocked:

```sh
xattr -dr com.apple.quarantine /Applications/WindowPilot.app
open /Applications/WindowPilot.app
```

If `swift` or `xcodebuild` fails with an active developer path error, install or select Xcode first:

```sh
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

## Implementation notes

`Command+Tab` is normally owned by the system. This app uses a session-level `CGEventTap`, which requires Accessibility permission and may be blocked by secure input contexts. The switching itself uses `AXUIElement` windows rather than private APIs, so minimized windows and some non-standard app windows may not appear yet.

The app has no network integration or analytics. See [PRIVACY.md](PRIVACY.md) and [SECURITY.md](SECURITY.md) before publishing a release.

For repeatable maintenance and release procedures, see [AGENTS.md](AGENTS.md).
