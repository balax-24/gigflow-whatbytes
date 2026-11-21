# 05 — 52-Hour Execution Roadmap, Testing Suite & Submission Checklist

> **Deadline:** Monday, November 23, 2026 EOD (IST). Aim to finish and submit by **8:00 PM IST** on Nov 23 to keep a 4-hour safety buffer.

---

## 1. Phased Implementation Plan

### Phase 1 — Scaffold, Firebase & Architecture (Sat Nov 21 · 7:30 PM – 11:30 PM)
- [ ] Run `flutter create --org com.whatbytes.gigflow gigflow`.
- [ ] Initialize Git (`git init`, create `main` and `dev` branches).
- [ ] Add dependencies from `02_TECH_STACK_AND_ARCHITECTURE.md`.
- [ ] Run `flutterfire configure` and enable **Email/Password Auth** + **Cloud Firestore** in Firebase Console.
- [ ] Deploy `firestore.rules` restricting read/write to `request.auth.uid == userId`.
- [ ] Enable Firestore offline persistence in `main.dart`.
- [ ] Set up `get_it`, `go_router`, `AppColors`, `AppTheme`, `AmbientMeshBackground`, `LiquidGlassChrome`, and `LiquidGlassCard`.
- **Commit:** `feat(setup): scaffold clean architecture, firebase config, and liquid glass primitives`

### Phase 2 — Authentication Flow (Sun Nov 22 · 9:00 AM – 1:00 PM)
- [ ] Implement `AppUser`, `AuthRepository`, `FirebaseAuthRepository`, and `FirebaseErrorMapper`.
- [ ] Implement `AuthBloc` and connect `go_router` auth redirect stream.
- [ ] Build `LoginScreen` and `RegisterScreen` with inline validation, password visibility toggle, loading states, and animated error banners.
- [ ] Manually test: Register new user -> auto-redirect to `/tasks` -> kill app & reopen (stays logged in) -> Sign out -> test wrong password (`invalid-credential`) & invalid email.
- **Commit:** `feat(auth): implement firebase email/password auth with error mapping and route guards`

### Phase 3 — Task CRUD & Offline Persistence (Sun Nov 22 · 2:00 PM – 7:00 PM)
- [ ] Implement `TaskEntity`, `TaskPriority`, `TaskModel`, `TaskRepository`, and `FirestoreTaskRepository`.
- [ ] Implement `TaskBloc` subscribing to `watchTasks(uid)` with create, edit, delete, restore (Undo), and toggle-completion events.
- [ ] Build `TaskEditorSheet` (Liquid Glass bottom sheet) with title, description, date/time picker + quick time chips, and priority selector.
- [ ] Build `TaskTile` (Tier-2 zero-blur glass card) with 48dp checkbox, haptic feedback, tap-to-edit, and swipe-to-delete + Undo SnackBar.
- [ ] **Airplane Mode Test:** Turn on Airplane Mode -> create 2 tasks -> toggle 1 complete -> kill and reopen app -> confirm tasks persist locally -> reconnect internet -> verify sync in Firebase Console.
- **Commit:** `feat(tasks): add firestore task crud with offline persistence and undo delete`

### Phase 4 — Filtering, Sorting & Dashboard Polish (Sun Nov 22 · 8:00 PM – 11:30 PM)
- [ ] Implement `TaskQueryEngine` and `date_grouping.dart`.
- [ ] Implement `TaskFilterCubit` and `ThemeCubit` backed by `shared_preferences`.
- [ ] Build `ShiftSummaryHeader`, `FilterDock`, `OfflineStatusBanner`, `TaskSectionHeader`, and `EmptyTasksView` (distinguishing "No tasks yet" vs "No tasks match your filters" with a one-tap `Clear Filters` button).
- [ ] Test responsive layout on narrow phone width (360dp), tall notched phone, and landscape/tablet width; verify zero overflow warnings.
- [ ] Test Dark Mode ("Obsidian Glass") and Light Mode ("Daylight Frost") contrast.
- **Commit:** `feat(filters): add priority and status filtering, due-date grouping, and dashboard polish`

### Phase 5 — Automated Testing & FPS Profiling (Mon Nov 23 · 9:00 AM – 2:00 PM)
- [ ] Implement all unit, BLoC, and widget tests listed in Section 2 below.
- [ ] Run `flutter analyze` (must return **0 issues**).
- [ ] Run `flutter test` (must be **100% passing**).
- [ ] Run `flutter run --profile` on a physical Android device with 25+ seeded tasks; scroll rapidly in Flutter DevTools Performance tab and confirm UI + Raster frame times stay **under 8–16 ms** (zero jank). Capture a DevTools screenshot for `docs/screenshots/`.
- **Commit:** `test: add unit, bloc, and widget test suites for auth, filtering, and crud`

### Phase 6 — Release APK, Demo Video & Submission (Mon Nov 23 · 3:00 PM – 8:00 PM)
- [ ] Build release APK: `flutter build apk --release`.
- [ ] Install `build/app/outputs/flutter-apk/app-release.apk` on a real phone and do a full smoke test.
- [ ] Capture 4 clean screenshots (`login.png`, `dashboard.png`, `filters.png`, `editor.png`) into `docs/screenshots/`.
- [ ] Record a 60–90 second walkthrough video showing:
  1. Invalid login error message + successful login.
  2. Creating, editing, completing, and swipe-deleting (with Undo) a task.
  3. Filtering by Priority + Status and verifying earliest-to-latest due date order.
  4. Smooth 60 FPS scrolling of the Liquid Glass UI + Dark/Light toggle.
  5. Airplane Mode offline persistence.
- [ ] Upload the release APK to **GitHub Releases (`v1.0.0`)** and paste the APK + demo video links into `README.md`.
- [ ] Push final commits and verify the public GitHub repository renders cleanly.
- **Commit:** `docs: finalize README with screenshots, performance benchmark, and release links`

---

## 2. Mandatory Automated Test Suite (`test/`)

Create the following test files so reviewers see real engineering rigor:

1. **`test/core/error/firebase_error_mapper_test.dart`**
   - Verifies `invalid-credential`, `wrong-password`, `user-not-found`, `email-already-in-use`, `weak-password`, `invalid-email`, `too-many-requests`, `network-request-failed`, and unknown fallback codes return exact user-friendly messages.

2. **`test/features/tasks/domain/task_query_engine_test.dart`**
   - Verifies unsorted tasks (past, today, next week) always sort strictly **earliest to latest**.
   - Verifies tie-breaking by priority (`high` -> `medium` -> `low`) when two tasks share the exact same `dueDate`.
   - Verifies filtering by Priority alone (`high`, `medium`, `low`).
   - Verifies filtering by Status alone (`incomplete`, `completed`).
   - Verifies combined Priority + Status filtering preserves earliest-to-latest sorting.

3. **`test/features/tasks/presentation/task_bloc_test.dart`** (using `bloc_test` + `mocktail`)
   - Verifies `TaskSubscriptionRequested` emits loading then loaded tasks from mocked `TaskRepository.watchTasks`.
   - Verifies `TaskCreated`, `TaskUpdated`, `TaskDeleted`, and `TaskCompletionToggled` invoke the repository with exact arguments.
   - Verifies repository error emits a non-crashing error message state while preserving previously loaded tasks.

4. **`test/features/auth/presentation/login_screen_test.dart`** (Widget Test)
   - Verifies submitting empty form shows email and password validation errors without calling `AuthBloc`.
   - Verifies invalid email format triggers inline validation error.
   - Verifies `AuthState` with `errorMessage` renders the error banner visibly.

---

## 3. Pre-Submission Final Audit

- [ ] `flutter analyze` -> 0 errors, 0 warnings, 0 lints.
- [ ] `flutter test` -> All tests pass.
- [ ] `git log --oneline` -> Clean, meaningful Conventional Commits.
- [ ] Release APK installs and logs in cleanly on a physical device.
- [ ] Demo video link is accessible without login restrictions (Unlisted YouTube / public Drive / Loom).
- [ ] Submission email/form sent before **Nov 23, 2026 EOD**.