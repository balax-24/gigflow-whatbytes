# GigFlow — Task Management App for Gig Workers

A Clean Architecture Flutter task management application designed for gig workers (delivery partners, rideshare drivers, and shift freelancers) to manage time-sensitive jobs with Firebase Authentication, offline-first persistence, strict due-date sorting, and a **zero-lag 60/120 FPS Liquid Glass UI**.

---

## Screenshots & Demo

| Login (Liquid Glass) | Task Dashboard | Priority & Status Filters | Create / Edit Task |
| :---: | :---: | :---: | :---: |
| ![Login](docs/screenshots/login.png) | ![Dashboard](docs/screenshots/dashboard.png) | ![Filters](docs/screenshots/filters.png) | ![Editor](docs/screenshots/editor.png) |

- **Walkthrough Video (90s):** [Watch Demo](ADD_DEMO_VIDEO_LINK_HERE)
- **Android Release APK:** [Download v1.0.0 APK](ADD_GITHUB_RELEASE_APK_LINK_HERE)

---

## Key Features

- **Firebase Authentication (Email & Password)**
  - Registration, login, persistent sessions via `go_router` auth guards, and logout.
  - Comprehensive error mapping covering `invalid-credential`, `wrong-password`, `user-not-found`, `email-already-in-use`, `weak-password`, `too-many-requests`, and offline network errors.
- **Complete Task CRUD with Cloud Sync & Local Persistence**
  - Create, view, edit, delete (swipe-to-delete with Undo), and one-tap completion toggling with haptic feedback.
  - Fields: `title`, `description`, `dueDate`, `priority` (`low`, `medium`, `high`), and `isCompleted`.
  - **Offline-First Resilience:** Explicitly configured Cloud Firestore disk persistence (`CACHE_SIZE_UNLIMITED`) enables seamless offline reads, creates, edits, and completion toggles with automatic sync on reconnect, paired with `shared_preferences` for persisting filters and theme settings.
- **Instant Filtering & Earliest-to-Latest Sorting**
  - Simultaneous filtering by **Priority** (`All`, `High`, `Medium`, `Low`) and **Status** (`All`, `Incomplete`, `Completed`).
  - Strictly ordered by due date (**earliest to latest**) with gig-worker urgency headers (`Overdue`, `Today`, `Tomorrow`, `Upcoming`).
- **Performance-Engineered Liquid Glass UI (iOS & Android)**
  - Responsive Material 3 layout respecting platform safe areas, 48dp one-handed touch targets, and high-contrast **Obsidian Glass (Dark)** and **Daylight Frost (Light)** themes for outdoor readability.

---

## Architecture

Structured using **Feature-First Clean Architecture**:

```text
lib/
├── app/          # MaterialApp.router, DI (get_it), go_router guards, Theme
├── core/         # Error mapping, validators, connectivity, Liquid Glass widgets
└── features/
    ├── auth/     # domain -> data (FirebaseAuth) -> presentation (AuthBloc + UI)
    └── tasks/    # domain (Entity, QueryEngine) -> data (Firestore + Prefs) -> presentation (TaskBloc, FilterCubit + UI)
```

### Engineering Decisions

1. **Why 2-Tier Liquid Glass (Zero Lag):**
   Placing `BackdropFilter` inside every card of a scrolling `ListView` triggers multiple per-frame offscreen GPU blur passes, causing dropped frames on mid-range Android devices. GigFlow solves this with a two-tier rendering pipeline:
   - **Tier 1 (`LiquidGlassChrome`):** True optical Gaussian blur (`ImageFilter.blur` with `TileMode.clamp`) strictly scoped to 2–3 static/floating chrome layers (header/filter dock, floating action pill, modal editor sheet).
   - **Tier 2 (`LiquidGlassCard`):** Zero-blur specular glass material (translucent gradient fills + custom-painted diagonal refractive rim borders inside `RepaintBoundary`) for all scrolling task cards over a cached `AmbientMeshBackground`.
   - **Verified Performance:** Sub-8 ms raster frame times in Flutter DevTools Profile mode during rapid list scrolling.
2. **State Management (`flutter_bloc`):**
   Event-driven `AuthBloc` and `TaskBloc` manage asynchronous Firebase streams with predictable, testable transitions, while `TaskFilterCubit` and `ThemeCubit` handle synchronous UI preferences.
3. **Tenant-Isolated Firestore Schema:**
   Tasks are stored under `users/{uid}/tasks/{taskId}` and locked down via `firestore.rules` (`request.auth.uid == userId`). Base ordering (`orderBy('dueDate')`) executes in Firestore while priority/status filters run deterministically in memory via `TaskQueryEngine` for instant offline filtering with zero composite-index failures.

---

## Tech Stack

| Category | Packages |
|---|---|
| **Framework** | Flutter (Material 3, Impeller-optimized) |
| **State Management** | `flutter_bloc`, `equatable` |
| **Backend & Local Storage** | `firebase_core`, `firebase_auth`, `cloud_firestore`, `shared_preferences` |
| **Navigation & DI** | `go_router`, `get_it` |
| **Utilities & UI** | `intl`, `google_fonts`, `connectivity_plus` |
| **Testing** | `flutter_test`, `bloc_test`, `mocktail` |

---

## Setup & Run Locally

### Prerequisites
- Flutter SDK `>=3.24.0` (Dart `>=3.5.0`)
- Firebase CLI & FlutterFire CLI (if attaching your own Firebase project)

### Run Instructions
```bash
# 1. Clone the repository
git clone https://github.com/<your-username>/<repo-name>.git
cd <repo-name>

# 2. Install dependencies
flutter pub get

# 3. Configure Firebase (only needed if connecting a new Firebase project)
flutterfire configure

# 4. Run static analysis and tests
flutter analyze
flutter test

# 5. Launch the app
flutter run
```

---

## Automated Testing

Run the full test suite with:
```bash
flutter test
```

Coverage includes:
- Firebase Authentication error code mapping (including `invalid-credential`)
- Earliest-to-latest due-date sorting and tie-breaking
- Combined Priority + Status filtering (`TaskQueryEngine`)
- `TaskBloc` stream loading, CRUD operations, and non-crashing error states
- Login screen form validation and error-banner widget tests

---

## Future Enhancements
- Local scheduled shift reminders via `flutter_local_notifications` before task due times.
- Gig earnings & shift completion analytics dashboard.
- GitHub Actions CI pipeline running `flutter analyze`, `flutter test`, and automated APK builds.