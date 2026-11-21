# GigFlow v1.1.0

A big UX update on top of v1.0.0, inspired by the reference designs and tested end-to-end on a real Android 16 phone.

## Install (Android 7.0+ / API 24+)
- **`gigflow-v1.1.0-universal.apk`**: works on every device. Recommended.
- `gigflow-v1.1.0-arm64-v8a.apk` / `gigflow-v1.1.0-armeabi-v7a.apk`: smaller, per-architecture builds.

This release is signed with GigFlow's permanent release key. If you installed v1.0.0 (debug-signed), uninstall it first. Your tasks are safe in the cloud.

## New
- **Onboarding**: 3 quick slides on first launch.
- **Continue with Google**: native account picker, straight into your tasks.
- **Forgot password**: a reset link by email, and a ✓ tick on valid emails.
- **Emoji categories**: 📦 Delivery · 🚗 Ride · 🛒 Errand · 💼 Work · 🏠 Personal · ✨ General, with a filter row.
- **Week strip**: tap a day to see only that day's tasks.
- **Smarter timeline**: THIS WEEK / LATER sections, plus "in 45m" and "2h overdue" labels.
- **Swipe right to complete** (swipe left still deletes, with Undo).
- **Shift cleared 🎉**: confetti when today's last task is done.
- **Profile sheet** ("⋯"): stats, appearance and sign out.
- **Lavender theme**, alongside Obsidian (dark) and Daylight (light).
- A greeting that matches the time of day, and friendlier empty states.

## Fixed
- Filter chips stay legible after switching themes.
- Clear messages when Google sign-in is attempted offline.

## Quality
- 95 automated tests; `flutter analyze --fatal-infos` is clean.
- Firestore rules are backward-compatible, so v1.0.0 clients keep working.
