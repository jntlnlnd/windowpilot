# WindowPilot Agent Notes

This file is for future Codex/agent work in this repository. Keep repeatable project workflows here. General user preferences belong outside this repo.

## Project Summary

WindowPilot is a macOS menu bar utility that intercepts `Command+Tab` and switches by window instead of by app.

Important implementation areas:

- `Sources/WindowPilot/EventTapController.swift`: keyboard event tap and shortcut handling.
- `Sources/WindowPilot/AccessibilityService.swift`: Accessibility API window discovery and focus.
- `Sources/WindowPilot/SwitcherOverlay.swift`: visual switcher UI and window thumbnails.
- `Sources/WindowPilot/AppDelegate.swift`: menu bar app wiring, permissions, diagnostics, Open at Login.
- `Sources/WindowPilot/Resources/Info.plist`: bundle ID, app name, icon metadata.
- `scripts/build_app.sh`: creates `.build/app/WindowPilot.app`.
- `scripts/build_dmg.sh`: creates `dist/WindowPilot.dmg`.
- `scripts/generate_icons.sh`: regenerates `AppIcon.icns` from `AppIconSource.png`.

## Build And Run

Use these commands after code changes:

```sh
scripts/build_app.sh
codesign --verify --deep --strict .build/app/WindowPilot.app
open .build/app/WindowPilot.app
```

On this Mac, Swift/Git tooling may need to create `xcrun` caches outside the sandbox. If a command fails with `/tmp/xcrun_db-*` permission errors, rerun the same command with escalated permissions.

## DMG Release Workflow

Use this when generating a local installer DMG:

```sh
scripts/generate_icons.sh
scripts/build_app.sh
scripts/build_dmg.sh
codesign --verify --deep --strict .build/app/WindowPilot.app
codesign --verify --deep --strict dist/WindowPilot.dmg
```

The DMG is ad-hoc signed and not notarized. It is suitable for local/manual installation, but public users may see Gatekeeper warnings.

The source repo ignores `dist/`. For the current simple public download path, copy the generated DMG into `release/WindowPilot.dmg`, update `release/README.md` with a fresh SHA-256, then commit it:

```sh
cp dist/WindowPilot.dmg release/WindowPilot.dmg
shasum -a 256 release/WindowPilot.dmg
```

Prefer GitHub Release assets instead of committing binaries once a release-upload workflow or `gh` CLI is available.

## Install Locally

To update the installed app on this Mac:

```sh
killall WindowPilot || true
ditto .build/app/WindowPilot.app /Applications/WindowPilot.app
open /Applications/WindowPilot.app
```

Because local builds are ad-hoc signed, Accessibility, Screen Recording, and Login Items permissions can reset after rebuilds or bundle ID changes. Re-grant permissions under `System Settings > Privacy & Security` as needed.

## Manual Verification

Before publishing or pushing a functional change, verify:

- WindowPilot launches and the menu bar icon appears.
- Accessibility permission can be granted.
- `Command+Tab` opens the switcher.
- Repeated `Command+Tab` moves forward.
- `Command+Shift+Tab` moves backward.
- Left/right arrow keys move selection horizontally while the switcher is open.
- Up/down arrow keys move selection vertically while the switcher is open.
- More than five windows are shown in a 5-column grid, with up to three visible rows.
- Releasing Command focuses the selected window.
- Escape cancels without switching.
- Window thumbnails appear after Screen Recording permission.
- Open at Login can be enabled and disabled from the menu.
- Diagnostic Logging is off by default.

## Security And Privacy Rules

- Do not add networking, analytics, telemetry, or update beacons without explicit user approval.
- Diagnostic logging must stay off by default.
- Do not log window titles, screenshots, thumbnails, paths, or other sensitive user content by default.
- Keep permission usage documented in `README.md`, `PRIVACY.md`, and `SECURITY.md`.
- Keep generated screenshots and release artwork free of private window contents.
- Do not imply affiliation with third-party apps, services, or Apple.
- Do not commit credentials, Apple Developer certificates, notarization profiles, API keys, or private keys.

## Naming And Bundle Identity

Current public identity:

- App name: `WindowPilot`
- Bundle ID: `com.jntlnlnd.windowpilot`
- Executable: `WindowPilot`
- App bundle: `WindowPilot.app`
- DMG: `WindowPilot.dmg`

Changing the bundle ID makes macOS treat the app as a new app and resets permissions. Update all scripts, docs, `Package.swift`, and `Info.plist` together if the app name changes.

## GitHub Publishing

Standard push flow:

```sh
git status --short
git add <changed files>
git commit -m "<message>"
git push
```

For tagged public snapshots:

```sh
git tag -a vX.Y.Z -m "WindowPilot vX.Y.Z"
git push origin vX.Y.Z
```

Current remote:

```text
https://github.com/jntlnlnd/windowpilot.git
```

## Notarization

Notarization is not currently configured because it requires the Apple Developer Program. If it becomes available later, use `RELEASE.md` as the starting checklist and avoid storing notarization credentials in the repository.
