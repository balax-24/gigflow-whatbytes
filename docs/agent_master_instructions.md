# 01 — AI Coding Agent Master Instructions (Whatbytes Flutter Assignment)

> **Purpose:** Feed this file first to your AI coding agent (Cursor, Windsurf, Claude Code, Cline, Copilot, etc.) as the single source of truth for rules, constraints, and execution order.

---

## 1. Mission & Evaluation Context
Build **GigFlow**, a production-grade Flutter task management application tailored for **gig workers** (delivery riders, rideshare drivers, shift freelancers) for the **Whatbytes Flutter Developer Intern** assignment.

- **Submission Deadline:** November 23, 2026 EOD (IST).
- **Primary Evaluation Signals:**
  1. Clean Architecture, separation of concerns, and maintainable Dart/Flutter coding style.
  2. Rock-solid Firebase Authentication (email/password) with clear, user-friendly error handling.
  3. Reliable Task CRUD backed by Cloud Firestore with **local offline persistence**.
  4. Strict **earliest-to-latest due-date sorting** combined with **priority** and **status** filtering.
  5. Responsive, cross-platform Material 3 UI (Android & iOS) implementing a **zero-lag Liquid Glass / glassmorphism** aesthetic locked at 60/120 FPS.
  6. Automated unit/BLoC/widget tests and zero `flutter analyze` warnings.

---

## 2. Hard Requirements Checklist (Must Be 100% Satisfied)

| # | Requirement | Mandatory Implementation Detail |
|---|---|---|
| R1 | **Firebase Auth (Email/Password)** | Register, Login, persistent session across restarts (`go_router` auth redirect), Logout. |
| R2 | **Invalid Credential Errors** | Map Firebase codes (`invalid-credential`, `wrong-password`, `user-not-found`, `email-already-in-use`, `weak-password`, `invalid-email`, `too-many-requests`, `network-request-failed`) to clean human-readable banners. Never show raw Firebase exceptions. |
| R3 | **Task CRUD** | Create, View, Edit, Delete tasks (swipe-to-delete + Undo SnackBar + delete option in editor). |
| R4 | **Required Task Fields** | `title` (String), `description` (String), `dueDate` (DateTime), `priority` (`low`, `medium`, `high`), `isCompleted` (bool). |
| R5 | **Cloud + Local Storage** | Cloud Firestore at `users/{uid}/tasks/{taskId}` with Firestore native offline persistence explicitly enabled (`persistenceEnabled: true`) + `shared_preferences` for persisted filter/theme state. Must work seamlessly in Airplane Mode. |
| R6 | **Mark Complete / Incomplete** | One-tap toggle on every task card with optimistic UI responsiveness, animated visual state, and subtle haptic feedback. |
| R7 | **Filtering** | Filter simultaneously by **Priority** (`All`, `High`, `Medium`, `Low`) and **Status** (`All`, `Incomplete`, `Completed`). |
| R8 | **Sorting** | Displayed in a list strictly sorted by **due date (earliest to latest)**. |
| R9 | **Responsive Cross-Platform UI** | Material 3 design with proper `SafeArea`, adaptive padding/spacing, readable dark/light themes, and polished appearance on both Android and iOS. |
| R10 | **Zero-Lag Liquid Glass** | Strict 2-tier glass architecture. Zero `BackdropFilter` widgets inside scrollable lists. |

---

## 3. Non-Negotiable Engineering Guardrails (DO / DO NOT)

### DO
- Follow **Feature-First Clean Architecture** (`domain` -> `data` -> `presentation`).
- Use `flutter_bloc` (`Bloc` for Auth and Tasks, `Cubit` for Filters and Theme), `equatable`, `go_router`, and `get_it`.
- Keep all business logic (sorting, filtering, error mapping, date grouping) in pure, unit-testable Dart classes decoupled from `BuildContext`.
- Use `Color.withValues(alpha: ...)` instead of deprecated `withOpacity(...)` for modern Flutter compatibility.
- Use `ImageFilter.blur(..., tileMode: TileMode.clamp)` on Tier-1 glass surfaces to prevent Impeller edge bleeding.
- Wrap the ambient gradient background and scrollable glass cards in `RepaintBoundary`.
- Run `flutter analyze` and `flutter test` after every completed phase and fix all warnings immediately.

### DO NOT (Strict Anti-Patterns)
- **NEVER** place `BackdropFilter` inside `ListView.builder`, `SliverList`, or any repeating card widget. This destroys GPU frame times on mid-range Android devices.
- **NEVER** use `GetX` or dump Firebase calls directly inside `StatefulWidget` classes.
- **NEVER** rely on complex multi-field Firestore composite indexes for filtering (`where('priority')` + `where('isCompleted')` + `orderBy('dueDate')`). Fetch the user's tasks ordered by `dueDate` ascending and apply Priority/Status filters deterministically in memory so toggling filters is instantaneous and works 100% offline.
- **NEVER** hardcode secrets or service-account private keys.
- **NEVER** skip empty states, loading skeletons, or offline error handling.

---

## 4. Mandatory Agent Execution Sequence

Execute the accompanying specification files strictly in this order:
1. Read `02_TECH_STACK_AND_ARCHITECTURE.md` -> Scaffold project, `pubspec.yaml`, folder structure, `firestore.rules`, DI (`get_it`), and `go_router`.
2. Read `03_LIQUID_GLASS_DESIGN_SYSTEM.md` -> Implement color tokens, typography, theme extensions, `AmbientMeshBackground`, `LiquidGlassChrome`, and `LiquidGlassCard`.
3. Read `04_FEATURE_SPECS_AND_LOGIC.md` -> Implement Auth (`domain`/`data`/`presentation`), then Tasks CRUD (`domain`/`data`/`presentation`), then `TaskFilterCubit` and Dashboard UI.
4. Read `05_EXECUTION_ROADMAP_AND_QA.md` -> Implement full unit, BLoC, and widget test suites; verify `flutter analyze` and `flutter test` are 100% green.
5. Copy `README.md` into the project root and populate screenshots, APK link, and demo video link after building the release APK.

---

## 5. Verification Gates (Agent Must Pass Before Finishing)

Before declaring any phase complete, run and confirm:
```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```
All three commands must exit with code `0`.