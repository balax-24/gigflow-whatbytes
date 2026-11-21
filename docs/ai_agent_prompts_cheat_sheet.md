# 06 — Copy-Paste Prompt Playbook for Your AI Coding Agent

Use these sequential prompts with Cursor / Windsurf / Claude Code / Cline after placing files `01` through `05` in a `/specs` folder inside your Flutter project root.

---

## Prompt 1 — Scaffold, DI, Routing & Firebase Setup
> Read `specs/01_AGENT_MASTER_INSTRUCTIONS.md` and `specs/02_TECH_STACK_AND_ARCHITECTURE.md`.
> Initialize the dependencies in `pubspec.yaml`, create `firestore.rules`, configure `main.dart` with Firestore offline persistence (`CACHE_SIZE_UNLIMITED`), and scaffold the complete Clean Architecture folder tree along with `injection_container.dart`, `app_router.dart` (with `GoRouterRefreshStream`), and `core/error/` (`failures.dart` + `firebase_error_mapper.dart`).
> Run `flutter analyze` and fix any issues before stopping.

---

## Prompt 2 — Zero-Lag 2-Tier Liquid Glass Design System
> Read `specs/03_LIQUID_GLASS_DESIGN_SYSTEM.md`.
> Implement `app_colors.dart`, `app_typography.dart`, `app_theme.dart` (both Dark "Obsidian Glass" and Light "Daylight Frost" themes), `AmbientMeshBackground`, `LiquidGlassChrome` (Tier-1 with `TileMode.clamp`), `LiquidGlassCard` (Tier-2 zero-blur specular card inside `RepaintBoundary`), `LiquidGlassButton`, `LiquidGlassTextField`, and `OfflineStatusBanner`.
> Strictly verify that `LiquidGlassCard` contains ZERO `BackdropFilter` widgets. Run `flutter analyze`.

---

## Prompt 3 — Firebase Auth Feature (Domain, Data, BLoC & Screens)
> Read `specs/04_FEATURE_SPECS_AND_LOGIC.md` (Section 1) and `specs/03_LIQUID_GLASS_DESIGN_SYSTEM.md` (Screen A).
> Implement the full `features/auth` module: `AppUser`, `AuthRepository`, `FirebaseAuthRepository`, `AuthBloc`, `validators.dart`, `LoginScreen`, and `RegisterScreen`.
> Ensure `invalid-credential` and all listed Firebase error codes render inside an animated glass error banner, inputs handle keyboard overflow cleanly, and `go_router` redirects authenticated users to `/tasks` and unauthenticated users to `/login`. Run `flutter analyze`.

---

## Prompt 4 — Task CRUD, Offline Storage, Filtering & Dashboard UI
> Read `specs/04_FEATURE_SPECS_AND_LOGIC.md` (Sections 2–4) and `specs/03_LIQUID_GLASS_DESIGN_SYSTEM.md` (Screens B & C).
> Implement the full `features/tasks` module: `TaskEntity`, `TaskPriority`, `TaskStatusFilter`, `TaskModel`, `TaskQueryEngine`, `date_grouping.dart`, `LocalPreferencesDataSource`, `FirestoreTaskRepository`, `TaskBloc`, `TaskFilterCubit`, `ThemeCubit`, `ConnectivityCubit`, `TaskDashboardScreen`, `TaskEditorSheet`, `ShiftSummaryHeader`, `FilterDock`, `TaskSectionHeader`, `TaskTile` (with 48dp checkbox, haptic feedback, and swipe-to-delete + Undo SnackBar), and `EmptyTasksView`.
> Verify strict earliest-to-latest due-date sorting and confirm zero `BackdropFilter` widgets inside scrollable lists. Run `flutter analyze`.

---

## Prompt 5 — Automated Tests & Final Polish
> Read `specs/05_EXECUTION_ROADMAP_AND_QA.md` (Section 2).
> Write all 4 test files (`firebase_error_mapper_test.dart`, `task_query_engine_test.dart`, `task_bloc_test.dart`, and `login_screen_test.dart`) using `flutter_test`, `bloc_test`, and `mocktail`.
> Run `dart format .`, `flutter analyze`, and `flutter test`. Fix every warning or failing test until all checks exit with code `0`.