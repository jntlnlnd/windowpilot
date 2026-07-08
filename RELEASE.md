# Release Checklist

Use this checklist before publishing a GitHub release.

## Local checks

```sh
scripts/generate_icons.sh
scripts/build_app.sh
scripts/build_dmg.sh
codesign --verify --deep --strict .build/app/WindowPilot.app
codesign --verify --deep --strict dist/WindowPilot.dmg
```

Open the app from `/Applications` and verify:

- The menu bar icon appears.
- Accessibility permission can be granted.
- `Command+Tab` opens the switcher.
- Arrow keys move selection while the switcher is open.
- Window thumbnails appear after Screen Recording permission.
- Open at Login can be enabled and disabled from the menu.
- Diagnostic Logging is off by default.

## Public release notes

Mention clearly:

- The app requires Accessibility permission.
- Window thumbnails require Screen Recording permission.
- The app has no network/analytics behavior.
- Ad-hoc or unsigned builds may show Gatekeeper warnings unless notarized.

For this initial public repository, `release/WindowPilot.dmg` is committed so the app can be downloaded directly. For future releases, prefer uploading `dist/WindowPilot.dmg` as a GitHub Release asset instead of committing generated binaries.

## Legal and branding review

- Do not imply affiliation with third-party apps, services, or Apple.
- Avoid Apple logos or third-party brand assets in release artwork.
- Keep the generated icon and screenshots free of private window contents.
- Confirm the chosen license and include it in the release repository.

## Future public distribution

For broad distribution, sign and notarize:

```sh
# Example only; requires Apple Developer Program credentials.
codesign --force --options runtime --timestamp --sign "Developer ID Application: YOUR NAME (TEAMID)" .build/app/WindowPilot.app
ditto -c -k --keepParent .build/app/WindowPilot.app .build/WindowPilot.zip
xcrun notarytool submit .build/WindowPilot.zip --keychain-profile YOUR_PROFILE --wait
xcrun stapler staple .build/app/WindowPilot.app
scripts/build_dmg.sh
```
