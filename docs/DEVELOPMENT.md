# Development

## Local setup

The project expects a working Xcode or Command Line Tools installation. If `swift build` fails with:

```text
xcrun: error: invalid active developer path
```

then install Xcode or the Command Line Tools and select the active developer directory:

```sh
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

or, for Command Line Tools:

```sh
sudo xcode-select -s /Library/Developer/CommandLineTools
```

## Build and run

```sh
scripts/build_app.sh
open .build/app/PanePilot.app
```

## Build DMG

```sh
scripts/build_dmg.sh
open dist/PanePilot.dmg
```

The DMG is intended for local installation and contains `PanePilot.app` plus an `Applications` symlink. It is ad-hoc signed, not notarized.

After the first launch, grant Accessibility permission in System Settings and relaunch the app.

For the fuller repeatable release and publishing workflow, see `AGENTS.md` and `RELEASE.md`.

## Manual verification checklist

1. Launch the app and confirm the `HS` menu bar item appears.
2. Grant Accessibility permission.
3. Grant Screen Recording permission if previews are blank.
4. Open several windows across two or more apps.
5. Press `Command+Tab` and confirm the PanePilot overlay appears with window previews.
6. Press Tab repeatedly while holding Command and confirm the selection moves.
7. Release Command and confirm the selected window is focused.
8. Press `Command+Shift+Tab` and confirm reverse cycling.
9. Press Escape while the overlay is open and confirm the current window stays focused.
