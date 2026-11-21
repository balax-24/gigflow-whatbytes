# GigFlow v1.0.0

An offline-first task manager for gig workers: Flutter 3.47, BLoC, Firebase Auth and Cloud Firestore with local persistence.

## Install (Android 7.0+ / API 24+)
- **`gigflow-v1.0.0-universal.apk`**: works on every device. Recommended for reviewers.
- `gigflow-v1.0.0-arm64-v8a.apk`: smaller build for modern 64-bit phones.
- `gigflow-v1.0.0-armeabi-v7a.apk`: older 32-bit phones.

Open the APK on the phone (allow "Install unknown apps"), or run `adb install -r gigflow-v1.0.0-universal.apk`. Register with any email and a password of at least 6 characters that includes a letter and a number.

SHA-256 checksums are in `SHA256SUMS.txt`.

## Features
- Email/password sign-up and sign-in, a persistent session, and friendly error messages for every Firebase error code
- Task create/edit/delete with 4-second Undo, plus one-tap complete with haptics
- Works fully offline (Airplane Mode) and syncs automatically, with a live Offline/Syncing indicator
- Priority × status filters, instant search, strict earliest-to-latest due-date order, and Overdue/Today/Tomorrow/Upcoming sections
- A shift progress bar, overdue badges, and quick due presets (+1 hr, Today 6 PM, Tomorrow 9 AM)
- A Liquid Glass UI with dark and light themes that meet WCAG AA contrast, and at most 2 live blurs while scrolling

## Quality
- 81 automated tests (unit, BLoC and widget, including a blur-budget performance contract and accessibility guidelines)
- `flutter analyze --fatal-infos` is clean
- Release build has R8 minification and resource shrinking, and the INTERNET permission is verified in CI

## Known limitations
- iOS is code-complete but not device-tested (no macOS build host).
- The APK is signed with the CI debug key, so uninstall it before installing a future differently-signed build.
