# PanePilot Agent Notes

This file is for future Codex/agent work in this repository. Keep repeatable project workflows here. General user preferences belong outside this repo.

## Project Summary

PanePilot is a macOS menu bar utility that intercepts `Command+Tab` and switches by window instead of by app.

Important implementation areas:

- `Sources/PanePilot/EventTapController.swift`: keyboard event tap and shortcut handling.
- `Sources/PanePilot/AccessibilityService.swift`: Accessibility API window discovery and focus.
- `Sources/PanePilot/SwitcherOverlay.swift`: visual switcher UI and window thumbnails.
- `Sources/PanePilot/AppDelegate.swift`: menu bar app wiring, permissions, diagnostics, Open at Login.
- `Sources/PanePilot/Resources/Info.plist`: bundle ID, app name, icon metadata.
- `scripts/build_app.sh`: creates `.build/app/PanePilot.app`.
- `scripts/build_dmg.sh`: creates `dist/PanePilot.dmg`.
- `scripts/generate_icons.sh`: regenerates `AppIcon.icns` from `AppIconSource.png`.

## Build And Run

Use these commands after code changes:

```sh
scripts/build_app.sh
codesign --verify --deep --strict .build/app/PanePilot.app
open .build/app/PanePilot.app
```

On this Mac, Swift/Git tooling may need to create `xcrun` caches outside the sandbox. If a command fails with `/tmp/xcrun_db-*` permission errors, rerun the same command with escalated permissions.

## DMG Release Workflow

Use this when generating a local installer DMG:

```sh
scripts/generate_icons.sh
scripts/build_app.sh
scripts/build_dmg.sh
codesign --verify --deep --strict .build/app/PanePilot.app
codesign --verify --deep --strict dist/PanePilot.dmg
```

The DMG is ad-hoc signed and not notarized. It is suitable for local/manual installation, but public users may see Gatekeeper warnings.

The source repo ignores `dist/`. For the current simple public download path, copy the generated DMG into `release/PanePilot.dmg`, update `release/README.md` with a fresh SHA-256, then commit it:

```sh
cp dist/PanePilot.dmg release/PanePilot.dmg
shasum -a 256 release/PanePilot.dmg
```

Prefer GitHub Release assets instead of committing binaries once a release-upload workflow or `gh` CLI is available.

## Install Locally

To update the installed app on this Mac:

```sh
killall PanePilot || true
ditto .build/app/PanePilot.app /Applications/PanePilot.app
open /Applications/PanePilot.app
```

Because local builds are ad-hoc signed, Accessibility, Screen Recording, and Login Items permissions can reset after rebuilds or bundle ID changes. Re-grant permissions under `System Settings > Privacy & Security` as needed.

## Manual Verification

Before publishing or pushing a functional change, verify:

- PanePilot launches and the menu bar icon appears.
- Accessibility permission can be granted.
- `Command+Tab` opens the switcher.
- Repeated `Command+Tab` moves forward.
- `Command+Shift+Tab` moves backward.
- Arrow keys move selection while the switcher is open.
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
- Do not imply affiliation with HyperSwitch, bahoom, or Apple.
- Do not commit credentials, Apple Developer certificates, notarization profiles, API keys, or private keys.

## Naming And Bundle Identity

Current public identity:

- App name: `PanePilot`
- Bundle ID: `com.masamichiimaseki.panepilot`
- Executable: `PanePilot`
- App bundle: `PanePilot.app`
- DMG: `PanePilot.dmg`

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
git tag -a vX.Y.Z -m "PanePilot vX.Y.Z"
git push origin vX.Y.Z
```

Current remote:

```text
https://github.com/jntlnlnd/panepilot.git
```

## Notarization

Notarization is not currently configured because it requires the Apple Developer Program. If it becomes available later, use `RELEASE.md` as the starting checklist and avoid storing notarization credentials in the repository.
