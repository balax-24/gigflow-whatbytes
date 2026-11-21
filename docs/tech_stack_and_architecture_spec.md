# 02 — Tech Stack, Architecture & Data Specification

---

## 1. Exact `pubspec.yaml` Dependencies

Target Flutter SDK `>=3.24.0` and Dart SDK `>=3.5.0`.

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8

  # State Management & Value Equality
  flutter_bloc: ^8.1.6
  equatable: ^2.0.5

  # Firebase Backend & Offline Persistence
  firebase_core: ^3.8.0
  firebase_auth: ^5.3.3
  cloud_firestore: ^5.5.0

  # Local Preferences & Connectivity
  shared_preferences: ^2.3.3
  connectivity_plus: ^6.1.0

  # Routing & Dependency Injection
  go_router: ^14.6.0
  get_it: ^8.0.2

  # Formatting & Typography
  intl: ^0.19.0
  google_fonts: ^6.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  bloc_test: ^9.1.7
  mocktail: ^1.0.4
```

> **Note for Agent:** Run `flutter pub add` for these packages if newer minor/patch versions are required to resolve cleanly with the installed Flutter SDK, while keeping the exact same package choices.

---

## 2. Feature-First Clean Architecture Directory Tree

```text
lib/
├── main.dart
├── firebase_options.dart                  # Generated via `flutterfire configure`
├── app/
│   ├── app.dart                           # MaterialApp.router + MultiBlocProvider
│   ├── di/
│   │   └── injection_container.dart       # get_it service locator
│   ├── router/
│   │   ├── app_router.dart                # go_router + auth state redirect
│   │   └── go_router_refresh_stream.dart  # Listenable bridge for auth stream
│   └── theme/
│       ├── app_colors.dart                # Dark Obsidian & Light Frost tokens
│       ├── app_theme.dart                 # Material 3 ThemeData (dark & light)
│       ├── app_typography.dart            # Plus Jakarta Sans / Inter scale
│       └── liquid_glass_theme.dart        # ThemeExtension for glass surfaces
├── core/
│   ├── error/
│   │   ├── failures.dart                  # AuthFailure, TaskFailure, CacheFailure
│   │   └── firebase_error_mapper.dart     # Pure error-code -> UI copy mapper
│   ├── services/
│   │   └── connectivity_cubit.dart        # Tracks online/offline state for banner
│   ├── utils/
│   │   ├── date_grouping.dart             # Overdue / Today / Tomorrow / Upcoming
│   │   └── validators.dart                # Email, password, task field validators
│   └── widgets/
│       ├── ambient_mesh_background.dart   # RepaintBoundary cached mesh orbs
│       ├── liquid_glass_chrome.dart       # Tier-1 real BackdropFilter (max 2-3)
│       ├── liquid_glass_card.dart         # Tier-2 zero-blur specular card
│       ├── liquid_glass_button.dart       # Specular pill button with haptics
│       ├── liquid_glass_text_field.dart   # Clean translucent form input
│       └── offline_status_banner.dart     # Subtle offline/local-sync indicator
└── features/
    ├── auth/
    │   ├── domain/
    │   │   ├── entities/
    │   │   │   └── app_user.dart
    │   │   └── repositories/
    │   │       └── auth_repository.dart
    │   ├── data/
    │   │   └── repositories/
    │   │       └── firebase_auth_repository.dart
    │   └── presentation/
    │       ├── bloc/
    │       │   ├── auth_bloc.dart
    │       │   ├── auth_event.dart
    │       │   └── auth_state.dart
    │       └── screens/
    │           ├── login_screen.dart
    │           └── register_screen.dart
    └── tasks/
        ├── domain/
        │   ├── entities/
        │   │   └── task_entity.dart
        │   ├── enums/
        │   │   ├── task_priority.dart         # low, medium, high
        │   │   └── task_status_filter.dart    # all, incomplete, completed
        │   ├── repositories/
        │   │   └── task_repository.dart
        │   └── utils/
        │       └── task_query_engine.dart     # Pure filter + earliest-due sort
        ├── data/
        │   ├── datasources/
        │   │   └── local_preferences_datasource.dart
        │   ├── models/
        │   │   └── task_model.dart
        │   └── repositories/
        │       └── firestore_task_repository.dart
        └── presentation/
            ├── bloc/
            │   ├── task_bloc.dart
            │   ├── task_event.dart
            │   └── task_state.dart
            ├── cubit/
            │   ├── task_filter_cubit.dart
            │   ├── task_filter_state.dart
            │   └── theme_cubit.dart
            ├── screens/
            │   ├── task_dashboard_screen.dart
            │   └── task_editor_sheet.dart
            └── widgets/
                ├── shift_summary_header.dart
                ├── filter_dock.dart
                ├── task_section_header.dart
                ├── task_tile.dart
                └── empty_tasks_view.dart
```

---

## 3. Layer Dependency Rules

1. **Domain Layer (`domain/`):** Pure Dart ONLY. Zero imports from `flutter/material.dart`, `cloud_firestore`, or `firebase_auth`. Contains entities, enums, abstract repository contracts, and `TaskQueryEngine`.
2. **Data Layer (`data/`):** Implements domain contracts using `firebase_auth`, `cloud_firestore`, and `shared_preferences`. Handles serialization (`TaskModel`) and maps SDK exceptions into typed `Failure` objects.
3. **Presentation Layer (`presentation/`):** Consumes repositories via `Bloc` / `Cubit` injected through `get_it`. Never imports `cloud_firestore` or `firebase_auth` directly.

---

## 4. Cloud Firestore Schema & Offline Persistence

### Collection Path
```text
users/{uid}/tasks/{taskId}
```

### Document Fields
```json
{
  "title": "Deliver order #4821 to Adyar",
  "description": "Call customer at gate; fragile package",
  "dueDate": "Timestamp (UTC)",
  "priority": "high",
  "isCompleted": false,
  "createdAt": "Timestamp (UTC)",
  "updatedAt": "Timestamp (UTC)"
}
```

> **Offline Persistence Rule:** When creating/updating a document locally while offline, store `Timestamp.fromDate(DateTime.now().toUtc())` for `createdAt`/`updatedAt` (or handle null `Timestamp` safely when `FieldValue.serverTimestamp()` is pending in local cache) so local snapshots never throw null-cast errors before server confirmation.

### Explicit Offline Initialization (`main.dart`)
```dart
WidgetsFlutterBinding.ensureInitialized();
await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);

await initDependencies();
runApp(const GigFlowApp());
```

### Firestore Security Rules (`firestore.rules` in repo root)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/tasks/{taskId} {
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;
    }
  }
}
```

---

## 5. Dependency Injection (`lib/app/di/injection_container.dart`)

Register with `get_it`:
- **External Singletons:** `FirebaseAuth.instance`, `FirebaseFirestore.instance`, `SharedPreferences` (`await SharedPreferences.getInstance()`), `Connectivity()`.
- **Data Sources:** `LocalPreferencesDataSource` (lazy singleton).
- **Repositories:** `AuthRepository -> FirebaseAuthRepository`, `TaskRepository -> FirestoreTaskRepository` (lazy singletons).
- **Blocs / Cubits:**
  - `AuthBloc` (lazy singleton so `go_router` and `MultiBlocProvider` share the exact auth state).
  - `TaskBloc` (factory or reset cleanly on sign-out).
  - `TaskFilterCubit` (lazy singleton, loads saved filter state from `LocalPreferencesDataSource`).
  - `ThemeCubit` (lazy singleton, loads saved dark/light preference).
  - `ConnectivityCubit` (lazy singleton).

---

## 6. Declarative Auth-Guarded Routing (`lib/app/router/app_router.dart`)

Use `go_router` with `refreshListenable: GoRouterRefreshStream(authRepository.authStateChanges)`:
- Routes:
  - `/login` -> `LoginScreen`
  - `/register` -> `RegisterScreen`
  - `/tasks` -> `TaskDashboardScreen`
- Redirect logic:
  - If user is **not authenticated** and route is not `/login` or `/register` -> redirect to `/login`.
  - If user **is authenticated** and route is `/login` or `/register` -> redirect to `/tasks`.
  - Otherwise return `null`.