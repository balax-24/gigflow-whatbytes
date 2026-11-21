# 07 — Audit Corrections & Production Roadmap (Single Source of Truth)

> **Precedence rule:** This file overrides `01`–`06` and the README template wherever they disagree. If a rule is not mentioned here, the original spec still applies. Agents must read this file **after** the original specs and apply every override below.
>
> **Audit date:** Saturday, 21 Nov 2026 · **Deadline:** Monday, 23 Nov 2026 EOD IST (internal target: submit by **20:00 IST**).
>
> **Spec file name mapping** (the originals refer to `specs/0X_*.md`, but the real files live in `docs/` under different names):
>
> | Referenced as | Actual file |
> |---|---|
> | `01_AGENT_MASTER_INSTRUCTIONS.md` | `docs/agent_master_instructions.md` |
> | `02_TECH_STACK_AND_ARCHITECTURE.md` | `docs/tech_stack_and_architecture_spec.md` |
> | `03_LIQUID_GLASS_DESIGN_SYSTEM.md` | `docs/liquid_glass_design_system_spec.md` |
> | `04_FEATURE_SPECS_AND_LOGIC.md` | `docs/feature_logic_and_edge_case_specs.md` |
> | `05_EXECUTION_ROADMAP_AND_QA.md` | `docs/execution_roadmap_and_qa_plan.md` |
> | `06_AGENT_PROMPT_PLAYBOOK.md` | `docs/ai_agent_prompts_cheat_sheet.md` |
> | `README.md` | `docs/repository_readme_template.md` |
> | **this file** | `docs/07_AUDIT_CORRECTIONS_AND_PRODUCTION_ROADMAP.md` |

---

## 0. Verified Local Environment (inspected 21 Nov 2026)

| Tool | Found | Consequence |
|---|---|---|
| Flutter | **3.47.5** stable (Dart **3.13.4**, DevTools 2.60.0) | Spec 02's `>=3.24 / >=3.5` constraint and every package version in it are stale. See C-01. |
| Flutter Android defaults (from `FlutterExtension.kt`) | `compileSdk 36`, `minSdk 24`, `targetSdk 36`, `ndkVersion 28.2.13676358`; template AGP **9.1.0**, Gradle **9.3.1**, Kotlin **2.4.0** | Matches the latest FlutterFire plugins (they need `minSdk 24`, Java 17+). NDK 28.2.13676358 is already installed. |
| JDK | OpenJDK 21.0.12 (`JAVA_HOME` set) | OK for AGP 9 (needs 17+). |
| Android SDK | `C:\Android\Sdk`; platforms 33–36; build-tools 34/35/36; NDK 28.0 & 28.2 | OK. `flutter doctor` reports **Android licenses not accepted**; the user must run `flutter doctor --android-licenses`. |
| Physical Android device | **None connected** (`adb devices` empty) | Phase 6/7 profiling and the release smoke test **need a physical phone with USB debugging**. |
| Firebase CLI / FlutterFire CLI | **Not installed** | Phase 0 installs them (`npm` 11.17 / Node 24.19 are available). |
| macOS / Xcode | Not available (Windows 11 host) | `flutter build ios` is impossible here, so iOS is checked statically (§5.2). |
| Git | 2.55.0; workspace is **not** a git repo yet | Phase 0 runs `git init`. |
| Project files | Only `docs/*.md` exist; no `pubspec.yaml`, `lib/`, `android/`, `ios/` | The Flutter project is created **in the workspace root** (`D:\Projects\Internship\Whatbytes`) so `docs/` stays alongside it. |

Package versions were checked against the pub.dev API on 21 Nov 2026, and APIs were confirmed by reading the published package sources:

| Package | Spec 02 | **Latest (pin this)** | Notes verified in source |
|---|---|---|---|
| firebase_core | ^3.8.0 | **^5.2.0** | Requires Dart ^3.12, Flutter ≥3.44; Android `minSdk 24`, Java 17; iOS deployment target **15.0** |
| firebase_auth | ^5.3.3 | **^7.1.0** | `invalid-credential` documented; deprecated APIs removed |
| cloud_firestore | ^5.5.0 | **^7.2.0** | `Settings(persistenceEnabled:, cacheSizeBytes:)` and `Settings.CACHE_SIZE_UNLIMITED = -1` still exist; `snapshots(includeMetadataChanges:, source:)` |
| flutter_bloc / bloc | ^8.1.6 | **^9.1.1 / ^9.2.1** | — |
| bloc_concurrency | *(missing)* | **^0.3.0** | `droppable()` / `restartable()` transformers |
| equatable | ^2.0.5 | **^3.0.0** | `Equatable` is now an `abstract mixin class`; `extends Equatable` still works; **equality no longer compares `runtimeType`** |
| go_router | ^14.6.0 | **^18.1.4** | URLs are case-sensitive (v15+); `redirect` is `FutureOr<String?> Function(BuildContext, GoRouterState)` |
| get_it | ^8.0.2 | **^9.3.0** | Disposal is now strictly LIFO |
| shared_preferences | ^2.3.3 | **^2.5.6** | Use `SharedPreferencesWithCache` (the legacy `getInstance()` API is slated for deprecation) |
| connectivity_plus | ^6.1.0 | **^7.3.2** | `onConnectivityChanged` → `Stream<List<ConnectivityResult>>` |
| intl | ^0.19.0 | **^0.20.3** | — |
| google_fonts | ^6.2.1 | **REMOVE** (see C-03) | v9 requires Flutter ≥3.47 and fetches fonts over HTTP at runtime |
| flutter_lints | ^5.0.0 | **^6.0.0** | — |
| bloc_test | ^9.1.7 | **^10.0.0** | — |
| mocktail | ^1.0.4 | **^1.0.5** | — |
| flutter_launcher_icons | *(missing)* | **^0.14.4** (dev) | — |
| flutter_native_splash | *(missing)* | **^2.4.8** (dev) | — |

---

## 1. Executive Audit Summary

| Spec file | Status | Critical issues found | Overrides applied |
|---|---|---|---|
| `01` agent_master_instructions.md | **Needs Correction** | Wrong file paths (`specs/0X…`); "RepaintBoundary on every scrollable card" is redundant (SliverList already adds one) and becomes a no-op raster cache under Impeller; "optimistic UI" left undefined; verification gate is missing `--fatal-infos` and tests-per-phase | C-05, C-17, C-30, §4 gates |
| `02` tech_stack_and_architecture_spec.md | **Needs Correction** | Every package is 1–4 majors behind; `bloc_concurrency` missing; `google_fonts` breaks offline first launch and widget tests; `flutter create --org com.whatbytes.gigflow gigflow` yields `com.whatbytes.gigflow.gigflow` in a subfolder; `GoRouterRefreshStream` has no dispose/distinct (leak plus redundant redirects); rules lack schema validation; `date_grouping.dart` in `core/` imports a feature entity (layer violation); `ThemeCubit` sits inside the tasks feature; Firebase iOS needs 15.0 | C-01 → C-04, C-08, C-09, C-12, C-13, C-27 |
| `03` liquid_glass_design_system_spec.md | **Needs Correction** | **WCAG AA fails**: light-mode priority/status colours have 1.6–2.7:1 contrast, dark `textMuted` 4.14:1, light `textMuted` 4.27:1; token table and reference code disagree (alphas and orb positions); 3 simultaneous scroll-time blurs (header, dock, FAB); "muted opacity" on completed tiles invites `Opacity` (saveLayer); `Platform.isIOS` (dart:io) in widgets; quick chips don't match the approved presets | C-18 → C-24 |
| `04` feature_logic_and_edge_case_specs.md | **Needs Correction** | **Date grouping breaks earliest-to-latest order** ("today before now and incomplete → Overdue" interleaves sections); `TaskModel` falls back to `DateTime.now()` for `dueDate` (tasks jump around, and Equatable never settles); awaited writes **hang forever offline**; `AuthStatus.loading` kills the auth status, so the router can bounce users mid-login; Undo "re-creates" with a new id; Dismissible removal race; **SnackBar with an action no longer auto-dismisses** (`persist` defaults to `true` when `action != null` in Flutter 3.47); weak-password copy contradicts the validator; no tie-breaker beyond title | C-06, C-07, C-10, C-11, C-14 → C-16, C-25, C-26 |
| `05` execution_roadmap_and_qa_plan.md | **Needs Correction** | Wrong `flutter create` command; no release signing, R8 or INTERNET-permission verification; profiling uses only 25 tasks; test list misses model, grouping, auth bloc, cubits and the no-blur-in-list contract; tests come only at the end (Phase 5) instead of per phase | §4 (Phases 0–7), §5 |
| `06` ai_agent_prompts_cheat_sheet.md | **Needs Correction** | Points to `specs/` paths that don't exist; Prompt 4 bundles ~20 files in one step (high failure risk); doesn't reference 07 | C-31 (replacement prompt pattern) |
| `README` repository_readme_template.md | **Needs Correction** | Claims "Verified sub-8 ms" before any measurement; prerequisites say Flutter ≥3.24; no reviewer install steps (APK + `adb install`); no Firebase project/rules setup steps; test list outdated | C-32 |

**Totals:** 7/7 files need correction · 32 corrections · 0 files pass unchanged. The architecture direction (Feature-First Clean Architecture, BLoC, 2-tier glass, in-memory filtering over an `orderBy('dueDate')` stream) is **sound and retained**.

---

## 2. Full Corrections & Technical Overrides

Each correction lists the **source**, **what was wrong** and the **exact fix**. Code blocks are drop-in. Paths are relative to the project root (`D:\Projects\Internship\Whatbytes`). The package name is `gigflow`.

### C-01 · `pubspec.yaml` version pinning (Spec 02 §1)
**Wrong:** Stale majors; `flutter pub add` "if needed" is non-deterministic; `bloc_concurrency` missing; SDK floor wrong.
**Fix:** Use exactly this file. Commit `pubspec.lock` so builds are reproducible.

```yaml
name: gigflow
description: "GigFlow — offline-first task manager for gig workers."
publish_to: "none"
version: 1.0.0+1

environment:
  sdk: ^3.12.0
  flutter: ">=3.44.0"

dependencies:
  flutter:
    sdk: flutter

  # State management
  flutter_bloc: ^9.1.1
  bloc: ^9.2.1
  bloc_concurrency: ^0.3.0
  equatable: ^3.0.0

  # Firebase
  firebase_core: ^5.2.0
  firebase_auth: ^7.1.0
  cloud_firestore: ^7.2.0

  # Local prefs & connectivity
  shared_preferences: ^2.5.6
  connectivity_plus: ^7.3.2

  # Routing & DI
  go_router: ^18.1.4
  get_it: ^9.3.0

  # Formatting
  intl: ^0.20.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  bloc_test: ^10.0.0
  mocktail: ^1.0.5
  flutter_launcher_icons: ^0.14.4
  flutter_native_splash: ^2.4.8

flutter:
  uses-material-design: true
  # Add this block ONLY after the 4 TTF files exist (see C-03), otherwise the build fails.
  fonts:
    - family: PlusJakartaSans
      fonts:
        - asset: assets/fonts/PlusJakartaSans-Regular.ttf
          weight: 400
        - asset: assets/fonts/PlusJakartaSans-Medium.ttf
          weight: 500
        - asset: assets/fonts/PlusJakartaSans-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/PlusJakartaSans-Bold.ttf
          weight: 700
```

`cupertino_icons` is dropped because only Material icons are used. Do not add packages beyond this list without updating this file.

### C-02 · Project scaffold command (Spec 05 Phase 1)
**Wrong:** `flutter create --org com.whatbytes.gigflow gigflow` creates a nested folder and the id `com.whatbytes.gigflow.gigflow`. It also uses a domain the candidate doesn't own.
**Fix:** Run this from the workspace root (it creates the project in place and leaves `docs/` untouched):

```powershell
flutter create --org dev.gigflow --project-name gigflow --platforms android,ios --empty .
```

Result: Android `applicationId` / `namespace` = `dev.gigflow.gigflow`, iOS bundle id = `dev.gigflow.gigflow`. Keep the generated `MainActivity` package so no manual refactor is needed.

### C-03 · Remove `google_fonts`; bundle the font (Spec 02 §1, Spec 03 §3)
**Wrong:** `google_fonts` downloads fonts over HTTP at first use. On an offline first launch (the exact Airplane-Mode scenario reviewers test) the app falls back to the system font and logs errors. In widget tests it attempts network I/O, which is flaky. v9 also forces Flutter ≥3.47.
**Fix:** Bundle static TTFs (SIL Open Font License).
1. **User action (download):** get "Plus Jakarta Sans" from fonts.google.com → *Download family*. From the zip's `static/` folder, copy `PlusJakartaSans-Regular.ttf`, `-Medium.ttf`, `-SemiBold.ttf` and `-Bold.ttf` into `assets/fonts/`. Also copy `OFL.txt` to `assets/fonts/OFL.txt`.
2. Add the `fonts:` block from C-01.
3. In `ThemeData`, set `fontFamily: 'PlusJakartaSans'` (C-20).
4. **Fallback if the fonts aren't available by Phase 1:** omit the `fonts:` block and `fontFamily`. The app then uses Roboto/SF Pro with no other change.

### C-04 · Android Gradle / SDK / R8 / permissions (Spec 02, Spec 05 Phase 6)
**Wrong:** No Android config is specified, so release builds can fail or crash.
**Fix:** In `android/app/build.gradle.kts`, **keep the generated `plugins {}` block** (including anything `flutterfire configure` adds) and the generated `compileOptions`/Kotlin settings. Replace or ensure the parts below:

```kotlin
import java.io.FileInputStream
import java.util.Properties

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // namespace = "dev.gigflow.gigflow"   <- keep the generated value
    compileSdk = flutter.compileSdkVersion   // 36 on Flutter 3.47.5
    ndkVersion = flutter.ndkVersion          // 28.2.13676358 (installed)

    defaultConfig {
        applicationId = "dev.gigflow.gigflow"
        minSdk = 24                          // FlutterFire 5.x/7.x floor
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode    // from pubspec "+1"
        versionName = flutter.versionName    // from pubspec "1.0.0"
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug") // reviewer-installable fallback
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}
```

`android/app/proguard-rules.pro` (a safety net; the Firebase AARs already ship their own consumer rules):

```proguard
-keepattributes Signature,*Annotation*,InnerClasses,EnclosingMethod,Exceptions
-keep class io.flutter.plugins.firebase.** { *; }
-dontwarn com.google.android.play.core.**
```

`android/app/src/main/AndroidManifest.xml`: the template adds `INTERNET` only to the **debug/profile** manifests, so declare it explicitly in main and set the display name:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <application
        android:label="GigFlow"
        ... keep the generated attributes and <activity> ... >
```

`android/key.properties` (gitignored, created by the user in Phase 7):

```properties
storePassword=<entered by user>
keyPassword=<entered by user>
keyAlias=upload
storeFile=C:/Users/<you>/keys/gigflow-upload.jks
```

**AGP 9 + google-services fallback:** `flutterfire configure` may add the `com.google.gms.google-services` Gradle plugin. If `flutter build apk` fails with an error from that plugin, remove its two lines (the `settings.gradle.kts` plugin entry and the `plugins {}` entry). Auth and Firestore initialise from `lib/firebase_options.dart` and do not need it.

### C-05 · iOS deployment target (Spec 02, Spec 03 R9)
**Wrong:** Not specified. FlutterFire core/firestore podspecs declare `s.ios.deployment_target = '15.0'`, so a pod install fails on lower targets.
**Fix:**
- `ios/Podfile`: first line `platform :ios, '15.0'` (uncomment or replace the generated line).
- `ios/Runner.xcodeproj/project.pbxproj`: set all three `IPHONEOS_DEPLOYMENT_TARGET = 15.0;` (Debug/Release/Profile). This is a plain text replacement and can be done on Windows.
- `ios/Runner/Info.plist`: `<key>CFBundleDisplayName</key><string>GigFlow</string>`.

### C-06 · Firestore pending `serverTimestamp()` nullability (Spec 02 §4, Spec 04 §2)
**Wrong:** FlutterFire's default `ServerTimestampBehavior` is `none`, so any pending `FieldValue.serverTimestamp()` reads back as **`null`** in local snapshots. The spec's fallback to `DateTime.now()` makes every snapshot produce different values: sort order jitters, Equatable never settles (extra rebuilds), and a null `dueDate` would make a task jump to "now".
**Fix (decision): never use `serverTimestamp()` in this app.** All timestamps are client-generated `Timestamp.fromDate(...)`, which are never null offline. Parsing stays defensive and deterministic: the fallback chain is `createdAt` → `dueDate`, and the clock is used only if every field is missing.

`lib/features/tasks/data/models/task_model.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:gigflow/features/tasks/domain/entities/task_entity.dart';
import 'package:gigflow/features/tasks/domain/enums/task_priority.dart';

/// Pure mapper between Firestore maps and [TaskEntity].
/// Takes a Map (not a DocumentSnapshot) so it is unit-testable without fakes.
abstract final class TaskModel {
  static TaskEntity fromMap(
    String id,
    Map<String, dynamic> data, {
    DateTime Function() clock = DateTime.now,
  }) {
    final createdAt = _readDate(data['createdAt']) ??
        _readDate(data['dueDate']) ??
        clock();
    final title = data['title'];
    final description = data['description'];
    final priority = data['priority'];
    return TaskEntity(
      id: id,
      title: title is String ? title.trim() : '',
      description: description is String ? description : '',
      dueDate: _readDate(data['dueDate']) ?? createdAt,
      priority: TaskPriority.fromName(priority is String ? priority : null),
      isCompleted: data['isCompleted'] == true,
      createdAt: createdAt,
      updatedAt: _readDate(data['updatedAt']) ?? createdAt,
    );
  }

  static Map<String, Object> toFirestore(TaskEntity task) => {
        'title': task.title.trim(),
        'description': task.description.trim(),
        'dueDate': Timestamp.fromDate(task.dueDate.toUtc()),
        'priority': task.priority.name,
        'isCompleted': task.isCompleted,
        'createdAt': Timestamp.fromDate(task.createdAt.toUtc()),
        'updatedAt': Timestamp.fromDate(task.updatedAt.toUtc()),
      };

  static DateTime? _readDate(Object? value) => switch (value) {
        Timestamp() => value.toDate(), // local time
        DateTime() => value.toLocal(),
        int() => DateTime.fromMillisecondsSinceEpoch(value),
        _ => null, // includes pending serverTimestamp (null)
      };
}
```

### C-07 · Offline writes must never be awaited by the UI (Spec 04 §2)
**Wrong:** "Fire write operations with local-cache-friendly handling" is vague. On mobile, `await docRef.set()` completes only on **server ACK**, so offline it never completes and the spinner hangs forever.
**Fix:** The repository future means "server acknowledged". The bloc **never awaits** it and only listens for failures. Firestore latency compensation updates the local cache and re-emits `snapshots()` immediately, and that *is* the optimistic UI.

`lib/features/tasks/domain/entities/task_feed.dart`:

```dart
import 'package:equatable/equatable.dart';

import 'package:gigflow/features/tasks/domain/entities/task_entity.dart';

class TaskFeed extends Equatable {
  const TaskFeed({
    required this.tasks,
    this.hasPendingWrites = false,
    this.isFromCache = false,
  });

  final List<TaskEntity> tasks;
  final bool hasPendingWrites;
  final bool isFromCache;

  @override
  List<Object?> get props => [tasks, hasPendingWrites, isFromCache];
}
```

`lib/features/tasks/domain/repositories/task_repository.dart`:

```dart
import 'package:gigflow/features/tasks/domain/entities/task_entity.dart';
import 'package:gigflow/features/tasks/domain/entities/task_feed.dart';

abstract interface class TaskRepository {
  /// Emits on every local or server change (including metadata changes).
  Stream<TaskFeed> watchTasks(String userId);

  /// Client-side id generation (works offline).
  String newTaskId(String userId);

  /// Writes to the local cache immediately. The returned future completes on
  /// SERVER acknowledgement. Callers must NOT await it for UI purposes.
  /// Throws [TaskFailure] if the server rejects the write.
  Future<void> upsertTask(String userId, TaskEntity task);

  Future<void> setCompletion(
    String userId,
    String taskId, {
    required bool isCompleted,
    required DateTime updatedAt,
  });

  Future<void> deleteTask(String userId, String taskId);
}
```

`lib/features/tasks/data/repositories/firestore_task_repository.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:gigflow/core/error/failures.dart';
import 'package:gigflow/features/tasks/data/models/task_model.dart';
import 'package:gigflow/features/tasks/domain/entities/task_entity.dart';
import 'package:gigflow/features/tasks/domain/entities/task_feed.dart';
import 'package:gigflow/features/tasks/domain/repositories/task_repository.dart';

class FirestoreTaskRepository implements TaskRepository {
  FirestoreTaskRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _tasks(String uid) =>
      _db.collection('users').doc(uid).collection('tasks');

  @override
  Stream<TaskFeed> watchTasks(String userId) => _tasks(userId)
      .orderBy('dueDate')
      .snapshots(includeMetadataChanges: true)
      .map(
        (snap) => TaskFeed(
          tasks: [
            for (final doc in snap.docs) TaskModel.fromMap(doc.id, doc.data()),
          ],
          hasPendingWrites: snap.metadata.hasPendingWrites,
          isFromCache: snap.metadata.isFromCache,
        ),
      )
      .distinct();

  @override
  String newTaskId(String userId) => _tasks(userId).doc().id;

  @override
  Future<void> upsertTask(String userId, TaskEntity task) =>
      _guard(_tasks(userId).doc(task.id).set(TaskModel.toFirestore(task)));

  @override
  Future<void> setCompletion(
    String userId,
    String taskId, {
    required bool isCompleted,
    required DateTime updatedAt,
  }) =>
      _guard(
        _tasks(userId).doc(taskId).update({
          'isCompleted': isCompleted,
          'updatedAt': Timestamp.fromDate(updatedAt.toUtc()),
        }),
      );

  @override
  Future<void> deleteTask(String userId, String taskId) =>
      _guard(_tasks(userId).doc(taskId).delete());

  Future<void> _guard(Future<void> write) async {
    try {
      await write;
    } on FirebaseException catch (e) {
      throw TaskFailure(_message(e.code), code: e.code);
    }
  }

  static String _message(String code) => switch (code) {
        'permission-denied' =>
          'A change was rejected by the server and has been reverted.',
        'unavailable' => 'Server unavailable. Your change will retry automatically.',
        _ => 'Could not sync a change. Please try again.',
      };
}
```

### C-08 · `GoRouterRefreshStream` leak + redundant redirects (Spec 02 §6)
**Wrong:** The bridge has no `dispose()`/`cancel`. If the router is created inside `build`, it leaks one subscription per rebuild. Listening to the raw repository stream also races `AuthBloc`: the router can redirect before the bloc's state has changed.
**Fix:** Drive the router from **`AuthBloc.stream`**, filtered to `(status, uid)` changes only. Create the router **once** in a DI-owned class with `dispose`.

`lib/app/router/go_router_refresh_stream.dart`:

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<Object?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
```

`lib/app/router/app_router.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:gigflow/app/di/injection_container.dart';
import 'package:gigflow/app/router/go_router_refresh_stream.dart';
import 'package:gigflow/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gigflow/features/auth/presentation/screens/login_screen.dart';
import 'package:gigflow/features/auth/presentation/screens/register_screen.dart';
import 'package:gigflow/features/auth/presentation/screens/splash_screen.dart';
import 'package:gigflow/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:gigflow/features/tasks/presentation/bloc/task_event.dart';
import 'package:gigflow/features/tasks/presentation/screens/task_dashboard_screen.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const tasks = '/tasks';
}

class AppRouter {
  AppRouter(this._authBloc)
      : _refresh = GoRouterRefreshStream(
          _authBloc.stream.map((s) => (s.status, s.user?.uid)).distinct(),
        ) {
    router = GoRouter(
      initialLocation: Routes.splash,
      refreshListenable: _refresh,
      redirect: _redirect,
      routes: [
        GoRoute(path: Routes.splash, builder: (_, __) => const SplashScreen()),
        GoRoute(path: Routes.login, builder: (_, __) => const LoginScreen()),
        GoRoute(path: Routes.register, builder: (_, __) => const RegisterScreen()),
        GoRoute(
          path: Routes.tasks,
          builder: (context, state) {
            final uid = _authBloc.state.user!.uid; // guaranteed by redirect
            return BlocProvider<TaskBloc>(
              key: ValueKey(uid),
              create: (_) => sl<TaskBloc>(param1: uid)
                ..add(const TaskSubscriptionRequested()),
              child: const TaskDashboardScreen(),
            );
          },
        ),
      ],
    );
  }

  final AuthBloc _authBloc;
  final GoRouterRefreshStream _refresh;
  late final GoRouter router;

  String? _redirect(BuildContext context, GoRouterState state) {
    final location = state.matchedLocation;
    final onAuthPage = location == Routes.login || location == Routes.register;
    return switch (_authBloc.state.status) {
      AuthStatus.unknown => location == Routes.splash ? null : Routes.splash,
      AuthStatus.unauthenticated => onAuthPage ? null : Routes.login,
      AuthStatus.authenticated =>
        (onAuthPage || location == Routes.splash) ? Routes.tasks : null,
    };
  }

  void dispose() {
    router.dispose();
    _refresh.dispose();
  }
}
```

`TaskBloc` is scoped to the `/tasks` route. On logout the redirect leaves `/tasks`, the `BlocProvider` closes the bloc, and the Firestore listener is cancelled, so **no data leaks between accounts** (this resolves Spec 04's logout edge case). `SplashScreen` is a static `AmbientMeshBackground` with the app mark and no logic.

### C-09 · `AuthState` must not overload `status` with `loading` (Spec 04 §1)
**Wrong:** `AuthStatus.loading` overwrites `authenticated/unauthenticated`. During a login attempt the router's redirect sees an "unknown-like" status, and the banner/redirect logic becomes order-dependent.
**Fix:** Keep the session `status` separate from the form state `isSubmitting`. Use `droppable()` so double taps are ignored at the bloc level as well as in the UI.

`lib/features/auth/presentation/bloc/auth_state.dart`:

```dart
part of 'auth_bloc.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

final class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final AuthStatus status;
  final AppUser? user;
  final bool isSubmitting;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    bool clearUser = false,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: clearUser ? null : (user ?? this.user),
        isSubmitting: isSubmitting ?? this.isSubmitting,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props => [status, user, isSubmitting, errorMessage];
}
```

`lib/features/auth/presentation/bloc/auth_event.dart`:

```dart
part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

final class AuthSubscriptionRequested extends AuthEvent {
  const AuthSubscriptionRequested();
}

final class AuthLoginSubmitted extends AuthEvent {
  const AuthLoginSubmitted({required this.email, required this.password});
  final String email;
  final String password;
  @override
  List<Object?> get props => [email, password];
}

final class AuthRegisterSubmitted extends AuthEvent {
  const AuthRegisterSubmitted({required this.email, required this.password});
  final String email;
  final String password;
  @override
  List<Object?> get props => [email, password];
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

final class AuthErrorCleared extends AuthEvent {
  const AuthErrorCleared();
}
```

`lib/features/auth/presentation/bloc/auth_bloc.dart`:

```dart
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gigflow/core/error/failures.dart';
import 'package:gigflow/features/auth/domain/entities/app_user.dart';
import 'package:gigflow/features/auth/domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository)
      : super(
          _repository.currentUser == null
              ? const AuthState()
              : AuthState(
                  status: AuthStatus.authenticated,
                  user: _repository.currentUser,
                ),
        ) {
    on<AuthSubscriptionRequested>(_onSubscribe, transformer: restartable());
    on<AuthLoginSubmitted>(_onLogin, transformer: droppable());
    on<AuthRegisterSubmitted>(_onRegister, transformer: droppable());
    on<AuthLogoutRequested>(_onLogout, transformer: droppable());
    on<AuthErrorCleared>((_, emit) => emit(state.copyWith(clearError: true)));
  }

  final AuthRepository _repository;

  Future<void> _onSubscribe(
    AuthSubscriptionRequested event,
    Emitter<AuthState> emit,
  ) =>
      emit.forEach<AppUser?>(
        _repository.authStateChanges,
        onData: (user) => user == null
            ? state.copyWith(status: AuthStatus.unauthenticated, clearUser: true)
            : state.copyWith(status: AuthStatus.authenticated, user: user),
      );

  Future<void> _onLogin(AuthLoginSubmitted e, Emitter<AuthState> emit) =>
      _submit(emit, () => _repository.signInWithEmail(
            email: e.email.trim(),
            password: e.password,
          ));

  Future<void> _onRegister(AuthRegisterSubmitted e, Emitter<AuthState> emit) =>
      _submit(emit, () => _repository.registerWithEmail(
            email: e.email.trim(),
            password: e.password,
          ));

  Future<void> _submit(
    Emitter<AuthState> emit,
    Future<AppUser> Function() action,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      await action(); // status change arrives via authStateChanges
      emit(state.copyWith(isSubmitting: false));
    } on AuthFailure catch (failure) {
      emit(state.copyWith(isSubmitting: false, errorMessage: failure.message));
    }
  }

  Future<void> _onLogout(AuthLogoutRequested e, Emitter<AuthState> emit) async {
    await _repository.signOut();
  }
}
```

### C-10 · Complete Firebase Auth error mapping (Spec 04 §1)
**Wrong:** Missing `missing-password`, `missing-email`, `channel-error` (sent when a field is empty), `INVALID_LOGIN_CREDENTIALS` (legacy alias) and `password-does-not-meet-requirements` (password policy). The weak-password copy says "letters and numbers" but the validator only checks length.
**Fix:** `lib/core/error/firebase_error_mapper.dart`:

```dart
abstract final class FirebaseErrorMapper {
  static const genericAuth = 'Authentication failed. Please try again.';
  static const badCredentials =
      'Incorrect email or password. Please check your credentials and try again.';

  static String mapAuthErrorCode(String code) => switch (code) {
        'invalid-credential' ||
        'wrong-password' ||
        'invalid-login-credentials' ||
        'INVALID_LOGIN_CREDENTIALS' =>
          badCredentials,
        'user-not-found' => 'No account found with this email address.',
        'invalid-email' || 'missing-email' => 'Please enter a valid email address.',
        'missing-password' => 'Please enter your password.',
        'channel-error' => 'Please enter both your email and password.',
        'email-already-in-use' =>
          'An account with this email already exists. Try signing in instead.',
        'weak-password' || 'password-does-not-meet-requirements' =>
          'Password is too weak. Use at least 6 characters including a letter and a number.',
        'user-disabled' => 'This account has been disabled. Please contact support.',
        'too-many-requests' =>
          'Too many failed attempts. Please wait a moment and try again.',
        'network-request-failed' =>
          'No internet connection. Check your network and try again.',
        'operation-not-allowed' =>
          'Email/password sign-in is not enabled for this app.',
        _ => genericAuth,
      };
}
```

`lib/core/error/failures.dart`:

```dart
sealed class Failure implements Exception {
  const Failure(this.message, {this.code});
  final String message;
  final String? code;
  @override
  String toString() => '$runtimeType($code): $message';
}

final class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

final class TaskFailure extends Failure {
  const TaskFailure(super.message, {super.code});
}
```

`lib/features/auth/data/repositories/firebase_auth_repository.dart`:

```dart
import 'package:firebase_auth/firebase_auth.dart';

import 'package:gigflow/core/error/failures.dart';
import 'package:gigflow/core/error/firebase_error_mapper.dart';
import 'package:gigflow/features/auth/domain/entities/app_user.dart';
import 'package:gigflow/features/auth/domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);
  final FirebaseAuth _auth;

  @override
  Stream<AppUser?> get authStateChanges => _auth.authStateChanges().map(_toUser);

  @override
  AppUser? get currentUser => _toUser(_auth.currentUser);

  @override
  Future<AppUser> signInWithEmail({required String email, required String password}) =>
      _run(() => _auth.signInWithEmailAndPassword(email: email.trim(), password: password));

  @override
  Future<AppUser> registerWithEmail({required String email, required String password}) =>
      _run(() => _auth.createUserWithEmailAndPassword(email: email.trim(), password: password));

  @override
  Future<void> signOut() => _auth.signOut();

  Future<AppUser> _run(Future<UserCredential> Function() call) async {
    try {
      final user = _toUser((await call()).user);
      if (user == null) throw const AuthFailure(FirebaseErrorMapper.genericAuth);
      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(FirebaseErrorMapper.mapAuthErrorCode(e.code), code: e.code);
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure(FirebaseErrorMapper.genericAuth);
    }
  }

  static AppUser? _toUser(User? user) =>
      user == null ? null : AppUser(uid: user.uid, email: user.email ?? '');
}
```

### C-11 · Validators consistent with Firebase & copy (Spec 04 §1)
`lib/core/utils/validators.dart`:

```dart
abstract final class Validators {
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  static final _letter = RegExp('[A-Za-z]');
  static final _digit = RegExp('[0-9]');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required.';
    if (!_email.hasMatch(v)) return 'Please enter a valid email address.';
    return null;
  }

  /// Login: only non-empty (never block existing accounts with legacy passwords).
  static String? loginPassword(String? value) =>
      (value == null || value.isEmpty) ? 'Password is required.' : null;

  /// Register: ≥6 chars (Firebase floor) + at least one letter and one digit.
  static String? newPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required.';
    if (v.length < 6) return 'Use at least 6 characters.';
    if (!_letter.hasMatch(v) || !_digit.hasMatch(v)) {
      return 'Include at least one letter and one number.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) =>
      value != original ? 'Passwords do not match.' : null;

  static String? taskTitle(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Title is required.';
    if (v.length > 100) return 'Keep the title under 100 characters.';
    return null;
  }

  static String? taskDescription(String? value) =>
      (value?.trim().length ?? 0) > 500 ? 'Keep the description under 500 characters.' : null;
}
```

Auth form UX rules: wrap the fields in `AutofillGroup`; email uses `autofillHints: [AutofillHints.email]`, `keyboardType: TextInputType.emailAddress`, `autocorrect: false`, `textInputAction: TextInputAction.next`; password uses `AutofillHints.password` (login) or `AutofillHints.newPassword` (register), an `obscureText` toggle (`IconButton` with tooltip "Show password"/"Hide password", 48dp), and `onFieldSubmitted` that submits the form. The CTA is disabled while `state.isSubmitting` and shows an inline 18px `CircularProgressIndicator`. Any edit to a field after an error dispatches `AuthErrorCleared`.

### C-12 · Firestore rules: tenant isolation + schema validation (Spec 02 §4)
**Wrong:** Owner check only. A client could write arbitrary fields or types, and nothing denies other paths explicitly.
**Fix:** `firestore.rules`. Size limits are deliberately **looser** than the client validators (100/500) so offline writes queued by a valid client are never rejected on sync, which would silently revert them.

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isOwner(userId) {
      return request.auth != null && request.auth.uid == userId;
    }

    function isValidTask(data) {
      let keys = ['title', 'description', 'dueDate', 'priority',
                  'isCompleted', 'createdAt', 'updatedAt'];
      return data.keys().hasAll(keys)
          && data.keys().hasOnly(keys)
          && data.title is string && data.title.size() > 0 && data.title.size() <= 200
          && data.description is string && data.description.size() <= 1000
          && data.dueDate is timestamp
          && data.priority in ['low', 'medium', 'high']
          && data.isCompleted is bool
          && data.createdAt is timestamp
          && data.updatedAt is timestamp;
    }

    match /users/{userId}/tasks/{taskId} {
      allow read, delete: if isOwner(userId);
      allow create, update: if isOwner(userId) && isValidTask(request.resource.data);
    }

    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

`firebase.json`:

```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  }
}
```

`firestore.indexes.json` (only the automatic single-field index on `dueDate` is needed):

```json
{ "indexes": [], "fieldOverrides": [] }
```

### C-13 · Layering fixes in the directory tree (Spec 02 §2)
- **Move** `lib/core/utils/date_grouping.dart` → `lib/features/tasks/domain/utils/date_grouping.dart` (it depends on `TaskEntity`; `core` must not import features).
- **Move** `lib/features/tasks/presentation/cubit/theme_cubit.dart` → `lib/app/theme/theme_cubit.dart` (theme is app-wide).
- **Add** `lib/features/tasks/domain/entities/task_feed.dart` (C-07), `lib/features/tasks/domain/utils/quick_due_presets.dart`, `lib/features/tasks/domain/utils/shift_stats.dart` (§3), `lib/features/auth/presentation/screens/splash_screen.dart` (C-08), `lib/core/services/sync_status.dart` (§3 F4) and `lib/dev/demo_seeder.dart` (§5.3).
- **Replace** the "`TaskModel extends TaskEntity`" design with the static mapper in C-06. Under equatable 3 a subclass compares equal to its parent anyway, so inheritance adds nothing.

### C-14 · Deterministic sort + search in `TaskQueryEngine` (Spec 04 §3)
**Wrong:** The title tie-breaker isn't total (two identical titles at the same time can swap between frames), there's no search, and picker/preset times carry seconds, which makes priority ties almost impossible.
**Fix:** The order is `dueDate ↑ → priority (high→low) → createdAt ↑ → id ↑` (a total order). All due dates are **normalised to minute precision** at creation and edit time.

`lib/features/tasks/domain/utils/task_query_engine.dart`:

```dart
import 'package:gigflow/features/tasks/domain/entities/task_entity.dart';
import 'package:gigflow/features/tasks/domain/enums/task_priority.dart';
import 'package:gigflow/features/tasks/domain/enums/task_status_filter.dart';

abstract final class TaskQueryEngine {
  static List<TaskEntity> apply({
    required List<TaskEntity> tasks,
    TaskPriority? priorityFilter, // null == All
    TaskStatusFilter statusFilter = TaskStatusFilter.all,
    String searchQuery = '',
  }) {
    final query = searchQuery.trim().toLowerCase();
    final result = [
      for (final task in tasks)
        if (_matches(task, priorityFilter, statusFilter, query)) task,
    ]..sort(compare);
    return List.unmodifiable(result);
  }

  static int compare(TaskEntity a, TaskEntity b) {
    final byDue = a.dueDate.compareTo(b.dueDate);
    if (byDue != 0) return byDue;
    final byPriority = a.priority.sortWeight.compareTo(b.priority.sortWeight);
    if (byPriority != 0) return byPriority;
    final byCreated = a.createdAt.compareTo(b.createdAt);
    if (byCreated != 0) return byCreated;
    return a.id.compareTo(b.id);
  }

  static bool _matches(
    TaskEntity task,
    TaskPriority? priority,
    TaskStatusFilter status,
    String query,
  ) {
    if (priority != null && task.priority != priority) return false;
    final statusOk = switch (status) {
      TaskStatusFilter.all => true,
      TaskStatusFilter.incomplete => !task.isCompleted,
      TaskStatusFilter.completed => task.isCompleted,
    };
    if (!statusOk) return false;
    if (query.isEmpty) return true;
    return task.title.toLowerCase().contains(query) ||
        task.description.toLowerCase().contains(query);
  }
}

/// Use everywhere a due date is produced (pickers, presets, edits).
DateTime normalizeToMinute(DateTime d) =>
    DateTime(d.year, d.month, d.day, d.hour, d.minute);
```

`lib/features/tasks/domain/enums/task_priority.dart` (adds safe parsing):

```dart
enum TaskPriority {
  high,
  medium,
  low;

  String get label => switch (this) {
        TaskPriority.high => 'High',
        TaskPriority.medium => 'Medium',
        TaskPriority.low => 'Low',
      };

  int get sortWeight => switch (this) {
        TaskPriority.high => 0,
        TaskPriority.medium => 1,
        TaskPriority.low => 2,
      };

  static TaskPriority fromName(String? name) =>
      TaskPriority.values.asNameMap()[name] ?? TaskPriority.medium;
}
```

`lib/features/tasks/domain/entities/task_entity.dart`:

```dart
import 'package:equatable/equatable.dart';

import 'package:gigflow/features/tasks/domain/enums/task_priority.dart';

class TaskEntity extends Equatable {
  const TaskEntity({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.description = '',
    this.priority = TaskPriority.medium,
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final TaskPriority priority;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool isOverdueAt(DateTime now) => !isCompleted && dueDate.isBefore(now);

  TaskEntity copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    bool? isCompleted,
    DateTime? updatedAt,
  }) =>
      TaskEntity(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        dueDate: dueDate ?? this.dueDate,
        priority: priority ?? this.priority,
        isCompleted: isCompleted ?? this.isCompleted,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props =>
      [id, title, description, dueDate, priority, isCompleted, createdAt, updatedAt];
}
```

### C-15 · Date grouping breaks global order (Spec 04 §3) — **critical**
**Wrong:** "Overdue = before today 00:00, OR today before `now` and incomplete." Counter-example at `now = 10:00`: task A is due 07:00 and **completed**, task B is due 08:00 and **incomplete**. B goes to OVERDUE (rendered first) and A goes to TODAY (rendered second), so 08:00 appears **above** 07:00 and earliest-to-latest is violated (requirement R8).
**Fix:** Partition **purely by time thresholds**, which is monotonic by construction. Completion affects only the *styling* and *label*, never the bucket.

`lib/features/tasks/domain/utils/date_grouping.dart`:

```dart
import 'package:gigflow/features/tasks/domain/entities/task_entity.dart';

enum TaskSection { pastDue, today, tomorrow, upcoming }

final class TaskSectionGroup {
  const TaskSectionGroup(this.section, this.tasks);
  final TaskSection section;
  final List<TaskEntity> tasks;

  /// "OVERDUE" if any task in the past bucket is incomplete, otherwise "EARLIER".
  String label(DateTime now) => switch (section) {
        TaskSection.pastDue =>
          tasks.any((t) => t.isOverdueAt(now)) ? 'OVERDUE' : 'EARLIER',
        TaskSection.today => 'TODAY',
        TaskSection.tomorrow => 'TOMORROW',
        TaskSection.upcoming => 'UPCOMING',
      };
}

abstract final class DateGrouping {
  static TaskSection sectionFor(DateTime due, DateTime now) {
    final d = due.toLocal();
    final n = now.toLocal();
    final startOfTomorrow = DateTime(n.year, n.month, n.day + 1); // DST-safe
    final startOfDayAfter = DateTime(n.year, n.month, n.day + 2);
    if (d.isBefore(n)) return TaskSection.pastDue;
    if (d.isBefore(startOfTomorrow)) return TaskSection.today;
    if (d.isBefore(startOfDayAfter)) return TaskSection.tomorrow;
    return TaskSection.upcoming;
  }

  /// [sorted] MUST already be sorted by TaskQueryEngine. Preserves order.
  static List<TaskSectionGroup> group(List<TaskEntity> sorted, DateTime now) {
    final buckets = <TaskSection, List<TaskEntity>>{};
    for (final task in sorted) {
      (buckets[sectionFor(task.dueDate, now)] ??= []).add(task);
    }
    return [
      for (final section in TaskSection.values)
        if (buckets[section] case final tasks?) TaskSectionGroup(section, tasks),
    ];
  }
}
```

Overdue styling per tile: crimson due chip and an "Overdue" badge only when `task.isOverdueAt(now)`. Completed past tasks show a calm, muted chip.

**`now` freshness:** the dashboard holds `DateTime _now` in its `State`, refreshed by a `Timer.periodic(const Duration(minutes: 1))` and by `AppLifecycleListener(onResume: ...)`. Both are cancelled and disposed in `dispose()`. Never call `DateTime.now()` inside item builders.

### C-16 · `TaskBloc`: Dismissible race, Undo semantics, write-error surfacing (Spec 04 §2)
**Wrong:**
- Swipe-to-delete waits for the Firestore snapshot to remove the row. Any rebuild before that throws *"A dismissed Dismissible widget is still part of the tree"*.
- Undo "re-creates" the task, implying a new id and a new `createdAt`, which changes tie-break order.
- Write failures are never surfaced.

**Fix:** Hide deleted ids immediately in state, and restore using the **same id** with the original `createdAt`. Write futures are tracked, never awaited.

`lib/features/tasks/presentation/bloc/task_event.dart`:

```dart
import 'package:equatable/equatable.dart';

import 'package:gigflow/features/tasks/domain/entities/task_entity.dart';
import 'package:gigflow/features/tasks/domain/enums/task_priority.dart';

sealed class TaskEvent extends Equatable {
  const TaskEvent();
  @override
  List<Object?> get props => [];
}

final class TaskSubscriptionRequested extends TaskEvent {
  const TaskSubscriptionRequested();
}

final class TaskCreated extends TaskEvent {
  const TaskCreated({
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
  });
  final String title;
  final String description;
  final DateTime dueDate;
  final TaskPriority priority;
  @override
  List<Object?> get props => [title, description, dueDate, priority];
}

final class TaskUpdated extends TaskEvent {
  const TaskUpdated(this.task);
  final TaskEntity task;
  @override
  List<Object?> get props => [task];
}

final class TaskCompletionToggled extends TaskEvent {
  const TaskCompletionToggled(this.task);
  final TaskEntity task;
  @override
  List<Object?> get props => [task];
}

final class TaskDeleted extends TaskEvent {
  const TaskDeleted(this.task);
  final TaskEntity task;
  @override
  List<Object?> get props => [task];
}

final class TaskRestored extends TaskEvent {
  const TaskRestored(this.task);
  final TaskEntity task;
  @override
  List<Object?> get props => [task];
}

final class TaskWriteFailed extends TaskEvent {
  const TaskWriteFailed(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

final class TaskErrorDismissed extends TaskEvent {
  const TaskErrorDismissed();
}
```

`lib/features/tasks/presentation/bloc/task_state.dart`:

```dart
import 'package:equatable/equatable.dart';

import 'package:gigflow/features/tasks/domain/entities/task_entity.dart';

enum TaskLoadStatus { initial, loading, ready, failure }

final class TaskState extends Equatable {
  const TaskState({
    this.status = TaskLoadStatus.initial,
    this.tasks = const [],
    this.pendingDeleteIds = const {},
    this.hasPendingWrites = false,
    this.isFromCache = false,
    this.errorMessage,
  });

  final TaskLoadStatus status;
  final List<TaskEntity> tasks; // raw feed (already ordered by dueDate)
  final Set<String> pendingDeleteIds;
  final bool hasPendingWrites;
  final bool isFromCache;
  final String? errorMessage;

  List<TaskEntity> get visibleTasks => pendingDeleteIds.isEmpty
      ? tasks
      : [for (final t in tasks) if (!pendingDeleteIds.contains(t.id)) t];

  TaskState copyWith({
    TaskLoadStatus? status,
    List<TaskEntity>? tasks,
    Set<String>? pendingDeleteIds,
    bool? hasPendingWrites,
    bool? isFromCache,
    String? errorMessage,
    bool clearError = false,
  }) =>
      TaskState(
        status: status ?? this.status,
        tasks: tasks ?? this.tasks,
        pendingDeleteIds: pendingDeleteIds ?? this.pendingDeleteIds,
        hasPendingWrites: hasPendingWrites ?? this.hasPendingWrites,
        isFromCache: isFromCache ?? this.isFromCache,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  @override
  List<Object?> get props =>
      [status, tasks, pendingDeleteIds, hasPendingWrites, isFromCache, errorMessage];
}
```

`lib/features/tasks/presentation/bloc/task_bloc.dart`:

```dart
import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gigflow/core/error/failures.dart';
import 'package:gigflow/features/tasks/domain/entities/task_entity.dart';
import 'package:gigflow/features/tasks/domain/entities/task_feed.dart';
import 'package:gigflow/features/tasks/domain/repositories/task_repository.dart';
import 'package:gigflow/features/tasks/domain/utils/task_query_engine.dart';
import 'package:gigflow/features/tasks/presentation/bloc/task_event.dart';
import 'package:gigflow/features/tasks/presentation/bloc/task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  TaskBloc({
    required TaskRepository repository,
    required String userId,
    DateTime Function() clock = DateTime.now,
  })  : _repo = repository,
        _uid = userId,
        _clock = clock,
        super(const TaskState()) {
    on<TaskSubscriptionRequested>(_onSubscribe, transformer: restartable());
    on<TaskCreated>(_onCreated);
    on<TaskUpdated>(_onUpdated);
    on<TaskCompletionToggled>(_onToggled);
    on<TaskDeleted>(_onDeleted);
    on<TaskRestored>(_onRestored);
    on<TaskWriteFailed>((e, emit) => emit(state.copyWith(errorMessage: e.message)));
    on<TaskErrorDismissed>((_, emit) => emit(state.copyWith(clearError: true)));
  }

  final TaskRepository _repo;
  final String _uid;
  final DateTime Function() _clock;

  Future<void> _onSubscribe(
    TaskSubscriptionRequested event,
    Emitter<TaskState> emit,
  ) async {
    emit(state.copyWith(status: TaskLoadStatus.loading));
    await emit.forEach<TaskFeed>(
      _repo.watchTasks(_uid),
      onData: (feed) {
        final present = {for (final t in feed.tasks) t.id};
        return state.copyWith(
          status: TaskLoadStatus.ready,
          tasks: feed.tasks,
          hasPendingWrites: feed.hasPendingWrites,
          isFromCache: feed.isFromCache,
          pendingDeleteIds: state.pendingDeleteIds.intersection(present),
        );
      },
      onError: (_, __) => state.copyWith(
        status: state.tasks.isEmpty ? TaskLoadStatus.failure : TaskLoadStatus.ready,
        errorMessage: 'Could not refresh tasks. Showing saved data.',
      ),
    );
  }

  void _onCreated(TaskCreated e, Emitter<TaskState> emit) {
    final now = _clock();
    _track(_repo.upsertTask(
      _uid,
      TaskEntity(
        id: _repo.newTaskId(_uid),
        title: e.title.trim(),
        description: e.description.trim(),
        dueDate: normalizeToMinute(e.dueDate),
        priority: e.priority,
        createdAt: now,
        updatedAt: now,
      ),
    ));
  }

  void _onUpdated(TaskUpdated e, Emitter<TaskState> emit) => _track(_repo.upsertTask(
        _uid,
        e.task.copyWith(
          title: e.task.title.trim(),
          description: e.task.description.trim(),
          dueDate: normalizeToMinute(e.task.dueDate),
          updatedAt: _clock(),
        ),
      ));

  void _onToggled(TaskCompletionToggled e, Emitter<TaskState> emit) => _track(
        _repo.setCompletion(
          _uid,
          e.task.id,
          isCompleted: !e.task.isCompleted,
          updatedAt: _clock(),
        ),
      );

  void _onDeleted(TaskDeleted e, Emitter<TaskState> emit) {
    // Emit synchronously so the Dismissible leaves the tree on the next frame.
    emit(state.copyWith(pendingDeleteIds: {...state.pendingDeleteIds, e.task.id}));
    _track(_repo.deleteTask(_uid, e.task.id));
  }

  void _onRestored(TaskRestored e, Emitter<TaskState> emit) {
    emit(state.copyWith(
      pendingDeleteIds: {...state.pendingDeleteIds}..remove(e.task.id),
    ));
    // Same id + original createdAt => identical position in the list.
    _track(_repo.upsertTask(_uid, e.task.copyWith(updatedAt: _clock())));
  }

  void _track(Future<void> write) {
    unawaited(write.catchError((Object error) {
      if (isClosed) return;
      add(TaskWriteFailed(
        error is TaskFailure ? error.message : 'Could not sync a change. Please try again.',
      ));
    }));
  }
}
```

### C-17 · SnackBar Undo never auto-dismisses on Flutter 3.47 (Spec 03 Screen B, Spec 04 §2)
**Wrong:** In Flutter 3.47.5 `SnackBar.persist` defaults to `action != null` (verified in `material/snack_bar.dart`), so the Undo bar **stays on screen forever** and the spec's "4 seconds" is ignored.
**Fix:** Use this exact snippet in `TaskTile`'s `onDismissed`:

```dart
onDismissed: (_) {
  HapticFeedback.mediumImpact();
  final bloc = context.read<TaskBloc>()..add(TaskDeleted(task));
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('“${task.title}” deleted'),
        duration: const Duration(seconds: 4),
        persist: false, // required: actions persist by default in Flutter 3.47
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () => bloc.add(TaskRestored(task)),
        ),
      ),
    );
},
```

The bloc reference is captured before the SnackBar is shown so Undo still works after the tile has left the tree. The Dismissible uses `key: ValueKey('task-${task.id}')` and `direction: DismissDirection.endToStart`. Its `background` is a plain `DecoratedBox` (coral gradient, rounded) — **never a `BackdropFilter`**.

### C-18 · WCAG AA contrast failures (Spec 03 §2) — **critical for R9**
Measured contrast ratios (WCAG 2.x relative luminance):

| Token | Dark bg `#070B14` | Light bg `#EEF3FA` | Verdict |
|---|---|---|---|
| textMuted `#64748B` | 4.14 | 4.27 | **Fails both** (needs 4.5) |
| priorityHigh `#FF5C72` | 6.58 | **2.68** | Fails light |
| priorityMedium `#FFB020` | 10.76 | **1.64** | Fails light |
| priorityLow `#2DD4BF` | 10.57 | **1.67** | Fails light |
| statusComplete `#22C55E` | 8.64 | **2.04** | Fails light |
| overdueAlert `#EF4444` | 5.23 (4.38 on dark card) | **3.38** | Fails light, and on dark cards |
| accentPrimary `#38BDF8` | 9.19 | **1.92** | Fails light |

**Fix — theme-specific "on-surface" semantic colours.** Every replacement below was measured at ≥4.5:1 on its background *and* on the card surface (dark card ≈ `#1A1F2B`, light card ≈ `#F7F9FC`).

`lib/app/theme/app_colors.dart`:

```dart
import 'package:flutter/material.dart';

abstract final class AppColors {
  // Dark — Obsidian Glass
  static const darkBg = Color(0xFF070B14);
  static const darkTextPrimary = Color(0xFFF8FAFC);   // 18.8:1
  static const darkTextSecondary = Color(0xFF94A3B8); // 7.7:1 (6.4 on card)
  static const darkTextMuted = Color(0xFF8A97AB);     // 6.6:1 (5.6 on card)  <- was #64748B
  static const darkPriorityHigh = Color(0xFFFF5C72);  // 5.5 on card
  static const darkPriorityMedium = Color(0xFFFFB020);
  static const darkPriorityLow = Color(0xFF2DD4BF);
  static const darkComplete = Color(0xFF22C55E);
  static const darkOverdue = Color(0xFFF87171);       // 6.0 on card  <- was #EF4444
  static const darkAccent = Color(0xFF38BDF8);
  static const darkOnAccent = Color(0xFF070B14);      // text on accent pill 9.2:1

  // Light — Daylight Frost
  static const lightBg = Color(0xFFEEF3FA);
  static const lightTextPrimary = Color(0xFF0F172A);   // 16.0:1
  static const lightTextSecondary = Color(0xFF475569); // 6.8:1
  static const lightTextMuted = Color(0xFF566378);     // 5.5:1  <- was #64748B
  static const lightPriorityHigh = Color(0xFFBE123C);  // 5.6:1
  static const lightPriorityMedium = Color(0xFF92400E);// 6.4:1
  static const lightPriorityLow = Color(0xFF0F766E);   // 4.9:1 (5.2 on card)
  static const lightComplete = Color(0xFF166534);      // 6.4:1
  static const lightOverdue = Color(0xFFB91C1C);       // 5.8:1
  static const lightAccent = Color(0xFF0369A1);        // 5.3:1
  static const lightOnAccent = Color(0xFFFFFFFF);      // 5.9:1 on accent

  // Orbs (single source of truth — the painter must read these)
  static const darkOrbs = [
    Color(0x3D3B82F6), // cobalt 24%  top-left      (0.15w, 0.12h, r 0.75w)
    Color(0x296366F1), // indigo 16%  center-right  (0.90w, 0.45h, r 0.65w)
    Color(0x2E14B8A6), // teal 18%    bottom-left   (0.25w, 0.88h, r 0.70w)
  ];
  static const lightOrbs = [
    Color(0x6B93C5FD), // 42%
    Color(0x61C7D2FE), // 38%
    Color(0x5C99F6E4), // 36%
  ];
}
```

The orb alphas and positions in the painter now read from `AppColors.darkOrbs`/`lightOrbs`, which resolves the token-versus-code mismatch in Spec 03 §2 vs §4.1. Priority chips use a **tinted fill at 14% of the semantic colour plus the solid semantic colour for the label and dot**. Colour is never the only signal: the chip always shows the text "High/Medium/Low".

### C-19 · Theme-aware semantic tokens via `ThemeExtension` (Spec 03 §2, §4)
`lib/app/theme/liquid_glass_theme.dart`:

```dart
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'package:gigflow/app/theme/app_colors.dart';

@immutable
class LiquidGlassTheme extends ThemeExtension<LiquidGlassTheme> {
  const LiquidGlassTheme({
    required this.cardFill,
    required this.chromeFill,
    required this.rimHighlight,
    required this.rimShade,
    required this.shadow,
    required this.blurSigma,
    required this.priorityHigh,
    required this.priorityMedium,
    required this.priorityLow,
    required this.complete,
    required this.overdue,
    required this.textMuted,
    required this.orbs,
  });

  final List<Color> cardFill;   // 2-stop gradient
  final List<Color> chromeFill; // 2-stop gradient over blur
  final Color rimHighlight;
  final Color rimShade;
  final Color shadow;
  final double blurSigma;
  final Color priorityHigh, priorityMedium, priorityLow, complete, overdue, textMuted;
  final List<Color> orbs;

  static const dark = LiquidGlassTheme(
    cardFill: [Color(0x1FFFFFFF), Color(0x0DFFFFFF)],
    chromeFill: [Color(0x29FFFFFF), Color(0x14FFFFFF)],
    rimHighlight: Color(0x66FFFFFF),
    rimShade: Color(0x1A38BDF8),
    shadow: Color(0x40000000),
    blurSigma: 16,
    priorityHigh: AppColors.darkPriorityHigh,
    priorityMedium: AppColors.darkPriorityMedium,
    priorityLow: AppColors.darkPriorityLow,
    complete: AppColors.darkComplete,
    overdue: AppColors.darkOverdue,
    textMuted: AppColors.darkTextMuted,
    orbs: AppColors.darkOrbs,
  );

  static const light = LiquidGlassTheme(
    cardFill: [Color(0xD9FFFFFF), Color(0xB3FFFFFF)],
    chromeFill: [Color(0xB3FFFFFF), Color(0x8CFFFFFF)],
    rimHighlight: Color(0xFFFFFFFF),
    rimShade: Color(0x330369A1),
    shadow: Color(0x1A0F172A),
    blurSigma: 16,
    priorityHigh: AppColors.lightPriorityHigh,
    priorityMedium: AppColors.lightPriorityMedium,
    priorityLow: AppColors.lightPriorityLow,
    complete: AppColors.lightComplete,
    overdue: AppColors.lightOverdue,
    textMuted: AppColors.lightTextMuted,
    orbs: AppColors.lightOrbs,
  );

  @override
  LiquidGlassTheme copyWith() => this;

  @override
  LiquidGlassTheme lerp(covariant LiquidGlassTheme? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    List<Color> l(List<Color> a, List<Color> b) =>
        [for (var i = 0; i < a.length; i++) c(a[i], b[i])];
    return LiquidGlassTheme(
      cardFill: l(cardFill, other.cardFill),
      chromeFill: l(chromeFill, other.chromeFill),
      rimHighlight: c(rimHighlight, other.rimHighlight),
      rimShade: c(rimShade, other.rimShade),
      shadow: c(shadow, other.shadow),
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t)!,
      priorityHigh: c(priorityHigh, other.priorityHigh),
      priorityMedium: c(priorityMedium, other.priorityMedium),
      priorityLow: c(priorityLow, other.priorityLow),
      complete: c(complete, other.complete),
      overdue: c(overdue, other.overdue),
      textMuted: c(textMuted, other.textMuted),
      orbs: l(orbs, other.orbs),
    );
  }
}

extension LiquidGlassContext on BuildContext {
  LiquidGlassTheme get glass => Theme.of(this).extension<LiquidGlassTheme>()!;
}
```

### C-20 · Material 3 `ThemeData` with modern APIs (Spec 03, Spec 01)
Ban list (enforced in review and by `flutter analyze` deprecation infos): `withOpacity` → `withValues(alpha:)`; `Color.value` → `toARGB32()`; `MaterialStateProperty` → `WidgetStateProperty`; `ColorScheme.background/onBackground/surfaceVariant` → `surface/onSurface/surfaceContainerHighest`; `WillPopScope` → `PopScope`; `textScaleFactor` → `textScaler`; `DropdownButtonFormField(value:)` → `initialValue:`; `Radio(groupValue:)` → `RadioGroup`; `MediaQuery.of(context).x` → `MediaQuery.sizeOf/viewInsetsOf/paddingOf(context)` (rebuilds only on the aspect that changed).

`lib/app/theme/app_theme.dart`:

```dart
import 'package:flutter/material.dart';

import 'package:gigflow/app/theme/app_colors.dart';
import 'package:gigflow/app/theme/liquid_glass_theme.dart';

abstract final class AppTheme {
  static const _font = 'PlusJakartaSans'; // remove if C-03 fallback used

  static ThemeData dark() => _base(
        ColorScheme.fromSeed(
          seedColor: AppColors.darkAccent,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.darkAccent,
          onPrimary: AppColors.darkOnAccent,
          surface: AppColors.darkBg,
          onSurface: AppColors.darkTextPrimary,
          onSurfaceVariant: AppColors.darkTextSecondary,
          error: AppColors.darkOverdue,
        ),
        LiquidGlassTheme.dark,
      );

  static ThemeData light() => _base(
        ColorScheme.fromSeed(
          seedColor: AppColors.lightAccent,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.lightAccent,
          onPrimary: AppColors.lightOnAccent,
          surface: AppColors.lightBg,
          onSurface: AppColors.lightTextPrimary,
          onSurfaceVariant: AppColors.lightTextSecondary,
          error: AppColors.lightOverdue,
        ),
        LiquidGlassTheme.light,
      );

  static ThemeData _base(ColorScheme scheme, LiquidGlassTheme glass) => ThemeData(
        colorScheme: scheme,
        fontFamily: _font,
        scaffoldBackgroundColor: Colors.transparent,
        extensions: [glass],
        snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
        materialTapTargetSize: MaterialTapTargetSize.padded, // 48dp minimum
        visualDensity: VisualDensity.standard,
      );
}
```

Platform checks use `Theme.of(context).platform == TargetPlatform.iOS`, **not** `Platform.isIOS` (`dart:io` doesn't respect `debugDefaultTargetPlatformOverride` in tests). Remove the manual scroll-physics rule from Spec 03 §3: `ScrollConfiguration` already applies bouncing physics on iOS and clamping on Android.

### C-21 · Glass widgets: exact Tier-1 / Tier-2 implementations (Spec 03 §4.2)
**Wrong/risky in the spec:**
- An extra `RepaintBoundary` inside every list card duplicates the one `SliverList` already adds (`addRepaintBoundaries: true`), and Impeller (the default on Android API 29+ and on iOS) has no raster cache, so it buys nothing.
- Clipping cards with `ClipRRect` adds clip layers per card for no reason.
- "Muted opacity" for completed tasks invites `Opacity`/`AnimatedOpacity`, which forces `saveLayer`.

**Fix:**

`lib/core/widgets/specular_rim_painter.dart`:

```dart
import 'package:flutter/rendering.dart';

/// 1.2px diagonal specular rim: bright top-left -> clear centre -> tinted bottom-right.
class SpecularRimPainter extends CustomPainter {
  const SpecularRimPainter({
    required this.radius,
    required this.highlight,
    required this.shade,
    this.strokeWidth = 1.2,
  });

  final double radius;
  final Color highlight;
  final Color shade;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [highlight, highlight.withValues(alpha: 0), shade],
        stops: const [0, 0.55, 1],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(SpecularRimPainter old) =>
      old.radius != radius ||
      old.highlight != highlight ||
      old.shade != shade ||
      old.strokeWidth != strokeWidth;
}
```

`lib/core/widgets/liquid_glass_card.dart` (Tier 2 — **zero blur, zero clip, zero saveLayer**):

```dart
import 'package:flutter/material.dart';

import 'package:gigflow/app/theme/liquid_glass_theme.dart';
import 'package:gigflow/core/widgets/specular_rim_painter.dart';

class LiquidGlassCard extends StatelessWidget {
  const LiquidGlassCard({
    super.key,
    required this.child,
    this.accentTint,
    this.radius = 20,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final Color? accentTint;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final top = accentTint == null
        ? glass.cardFill.first
        : Color.alphaBlend(accentTint!.withValues(alpha: 0.10), glass.cardFill.first);
    return CustomPaint(
      foregroundPainter: SpecularRimPainter(
        radius: radius,
        highlight: glass.rimHighlight,
        shade: glass.rimShade,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [top, glass.cardFill.last],
          ),
          // RRect shadow => analytic fast path on Impeller. Keep it a rounded rect.
          boxShadow: [
            BoxShadow(color: glass.shadow, blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
```

`lib/core/widgets/liquid_glass_chrome.dart` (Tier 1 — the **only** widget allowed to contain `BackdropFilter`):

```dart
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'package:gigflow/app/theme/liquid_glass_theme.dart';
import 'package:gigflow/core/widgets/specular_rim_painter.dart';

class LiquidGlassChrome extends StatelessWidget {
  const LiquidGlassChrome({
    super.key,
    required this.child,
    this.radius = 24,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final borderRadius = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: glass.blurSigma,
          sigmaY: glass.blurSigma,
          tileMode: TileMode.clamp,
        ),
        child: CustomPaint(
          foregroundPainter: SpecularRimPainter(
            radius: radius,
            highlight: glass.rimHighlight,
            shade: glass.rimShade,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: glass.chromeFill,
              ),
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
```

Completed tile styling: `AnimatedDefaultTextStyle` with `decoration: TextDecoration.lineThrough` and `color: glass.textMuted`. **No `Opacity`, `AnimatedOpacity`, `ShaderMask` or `ColorFiltered` inside list items.**

### C-22 · Blur budget: max 2 live blurs while scrolling (Spec 03 §1, Screen B)
**Wrong:** The pinned header, the separate filter dock and the FAB pill make **3 BackdropFilters re-sampled every scroll frame**, and opening the sheet makes 4.
**Fix:** Merge `ShiftSummaryHeader`, the search field, `FilterDock` and `OfflineStatusBanner` into **one** `LiquidGlassChrome` inside a single pinned `SliverPersistentHeader` (`_DashboardHeaderDelegate`). The greeting/progress row collapses as you scroll (`maxExtent` → `minExtent`); the filters stay pinned.

| Moment | Live `BackdropFilter`s | Budget |
|---|---|---|
| Dashboard scrolling | Header dock + FAB pill = **2** | ≤ 2 ✅ |
| Editor sheet open | Sheet + (static) dock + FAB = 3, list not scrolling | ≤ 3 ✅ |
| Auth screens | Auth card = **1** | ✅ |

Header delegate rules:
- `minExtent`/`maxExtent` are multiplied by `MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.3)`.
- Header content is wrapped in `MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3)` so large accessibility text can't overflow a fixed extent.
- `shouldRebuild` returns true only when the delegate's inputs (stats, filter state, online/sync state, theme) differ.

Only if profiling shows raster time > 8 ms with the header over content: wrap the dashboard `Stack` in `BackdropGroup` and use `BackdropFilter.grouped` (available in Flutter 3.47) for the header and FAB so they share one backdrop read.

### C-23 · List rendering contract (Spec 03 Screen B)
- Use `CustomScrollView` → `SliverPersistentHeader(pinned: true)` → `SliverPadding` → `SliverList.builder` over a flat list of a sealed `DashboardRow` type (`SectionHeaderRow` | `TaskRow`).
- Pass `findChildIndexCallback` keyed by `task.id`. That way toggling completion, which moves no item, or the order shifting after an edit keeps element state (checkbox animation, Dismissible) attached to the right task.
- Bottom padding = `MediaQuery.paddingOf(context).bottom + 96` so the FAB never covers the last card.
- `Scaffold(resizeToAvoidBottomInset: false, backgroundColor: Colors.transparent)` on the dashboard, because the editor sheet handles its own insets. This prevents a full list relayout on every keyboard animation frame.
- Each rebuild source is scoped. Use `BlocSelector<ConnectivityCubit, bool, bool>` for the banner only, and wrap the list in `BlocBuilder<TaskBloc, TaskState>` with `buildWhen: (a, b) => a.visibleTasks != b.visibleTasks`. Filter changes come from `BlocBuilder<TaskFilterCubit, TaskFilterState>`. A connectivity flip never rebuilds the list.

### C-24 · Editor sheet: keyboard, safe area, presets (Spec 03 Screen C)
```dart
Future<void> showTaskEditorSheet(BuildContext context, {TaskEntity? task}) {
  final bloc = context.read<TaskBloc>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => BlocProvider.value(
      value: bloc,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
        child: TaskEditorSheet(initialTask: task),
      ),
    ),
  );
}
```
- The sheet body is a `SingleChildScrollView` inside `LiquidGlassChrome`, with `ConstrainedBox(maxHeight: MediaQuery.sizeOf(context).height * 0.9)`.
- The title field has `autofocus: true` only in create mode, `maxLength: 100` and `textCapitalization: TextCapitalization.sentences`. The description field has `maxLines: 4`, `minLines: 2` and `maxLength: 500`.
- Quick preset chips are `+1 hr`, `Today 6 PM` and `Tomorrow 9 AM`, followed by `Custom…` (§3 F6). This replaces the spec's `Today +2h`.
- `Custom…` follows the platform. On iOS (`Theme.of(context).platform == TargetPlatform.iOS`) it opens `showCupertinoModalPopup` with a `CupertinoDatePicker(mode: CupertinoDatePickerMode.dateAndTime, minuteInterval: 1, use24hFormat: MediaQuery.alwaysUse24HourFormatOf(context))`. Elsewhere it runs `showDatePicker` followed by `showTimePicker`. The result always goes through `normalizeToMinute`.
- Save is disabled until the title is valid. On save, dispatch `TaskCreated`/`TaskUpdated` and **pop immediately**: never await the repository (C-07).
- In edit mode, `Delete` pops the sheet, dispatches `TaskDeleted` and shows the same Undo SnackBar as C-17.

### C-25 · Dependency injection with correct lifetimes (Spec 02 §5)
**Wrong:** `TaskBloc` as "factory or reset" is ambiguous. If the singleton blocs were provided with `BlocProvider(create:)`, they would be **closed** when the provider unmounts.
**Fix:** `lib/app/di/injection_container.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gigflow/app/router/app_router.dart';
import 'package:gigflow/app/theme/theme_cubit.dart';
import 'package:gigflow/core/services/connectivity_cubit.dart';
import 'package:gigflow/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:gigflow/features/auth/domain/repositories/auth_repository.dart';
import 'package:gigflow/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gigflow/features/tasks/data/datasources/local_preferences_datasource.dart';
import 'package:gigflow/features/tasks/data/repositories/firestore_task_repository.dart';
import 'package:gigflow/features/tasks/domain/repositories/task_repository.dart';
import 'package:gigflow/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:gigflow/features/tasks/presentation/cubit/task_filter_cubit.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  final prefs = await SharedPreferencesWithCache.create(
    cacheOptions: const SharedPreferencesWithCacheOptions(
      allowList: LocalPreferencesDataSource.keys,
    ),
  );

  sl
    // External
    ..registerSingleton<FirebaseAuth>(FirebaseAuth.instance)
    ..registerSingleton<FirebaseFirestore>(FirebaseFirestore.instance)
    ..registerSingleton<Connectivity>(Connectivity())
    // Data
    ..registerLazySingleton<LocalPreferencesDataSource>(
        () => LocalPreferencesDataSource(prefs))
    ..registerLazySingleton<AuthRepository>(() => FirebaseAuthRepository(sl()))
    ..registerLazySingleton<TaskRepository>(() => FirestoreTaskRepository(sl()))
    // App-lifetime state
    ..registerLazySingleton<AuthBloc>(
        () => AuthBloc(sl())..add(const AuthSubscriptionRequested()),
        dispose: (b) => b.close())
    ..registerLazySingleton<ThemeCubit>(() => ThemeCubit(sl()), dispose: (c) => c.close())
    ..registerLazySingleton<TaskFilterCubit>(() => TaskFilterCubit(sl()),
        dispose: (c) => c.close())
    ..registerLazySingleton<ConnectivityCubit>(() => ConnectivityCubit(sl()),
        dispose: (c) => c.close())
    ..registerLazySingleton<AppRouter>(() => AppRouter(sl()), dispose: (r) => r.dispose())
    // Per-session (scoped to /tasks route, closed by BlocProvider)
    ..registerFactoryParam<TaskBloc, String, void>(
        (uid, _) => TaskBloc(repository: sl(), userId: uid));
}
```

`lib/app/app.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gigflow/app/di/injection_container.dart';
import 'package:gigflow/app/router/app_router.dart';
import 'package:gigflow/app/theme/app_theme.dart';
import 'package:gigflow/app/theme/theme_cubit.dart';
import 'package:gigflow/core/services/connectivity_cubit.dart';
import 'package:gigflow/core/widgets/ambient_mesh_background.dart';
import 'package:gigflow/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gigflow/features/tasks/presentation/cubit/task_filter_cubit.dart';

class GigFlowApp extends StatelessWidget {
  const GigFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // .value => providers never close DI-owned singletons.
        BlocProvider<AuthBloc>.value(value: sl<AuthBloc>()),
        BlocProvider<ThemeCubit>.value(value: sl<ThemeCubit>()),
        BlocProvider<TaskFilterCubit>.value(value: sl<TaskFilterCubit>()),
        BlocProvider<ConnectivityCubit>.value(value: sl<ConnectivityCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, mode) => MaterialApp.router(
          title: 'GigFlow',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          routerConfig: sl<AppRouter>().router,
          builder: (context, child) =>
              AmbientMeshBackground(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
  }
}
```

Putting `AmbientMeshBackground` in `MaterialApp.builder` paints it **once, behind all routes** (rasterised once per theme). Every `Scaffold` uses `backgroundColor: Colors.transparent`.

`lib/main.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:gigflow/app/app.dart';
import 'package:gigflow/app/di/injection_container.dart';
import 'package:gigflow/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Must run before any other Firestore call.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
  await initDependencies();
  runApp(const GigFlowApp());
}
```

### C-26 · Persisted preferences: exact keys & datasource (Spec 04 §4)
`lib/features/tasks/data/datasources/local_preferences_datasource.dart`:

```dart
import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gigflow/features/tasks/domain/enums/task_priority.dart';
import 'package:gigflow/features/tasks/domain/enums/task_status_filter.dart';

class LocalPreferencesDataSource {
  LocalPreferencesDataSource(this._prefs);
  final SharedPreferencesWithCache _prefs;

  static const kFilterPriority = 'filter_priority'; // 'all'|'high'|'medium'|'low'
  static const kFilterStatus = 'filter_status';     // 'all'|'incomplete'|'completed'
  static const kThemeMode = 'theme_mode';           // 'dark'|'light'
  static const keys = {kFilterPriority, kFilterStatus, kThemeMode};

  TaskPriority? readPriority() {
    final raw = _prefs.getString(kFilterPriority);
    return raw == null || raw == 'all' ? null : TaskPriority.fromName(raw);
  }

  Future<void> writePriority(TaskPriority? p) =>
      _prefs.setString(kFilterPriority, p?.name ?? 'all');

  TaskStatusFilter readStatus() =>
      TaskStatusFilter.values.asNameMap()[_prefs.getString(kFilterStatus)] ??
      TaskStatusFilter.all;

  Future<void> writeStatus(TaskStatusFilter s) => _prefs.setString(kFilterStatus, s.name);

  ThemeMode readThemeMode() =>
      _prefs.getString(kThemeMode) == 'light' ? ThemeMode.light : ThemeMode.dark;

  Future<void> writeThemeMode(ThemeMode m) =>
      _prefs.setString(kThemeMode, m == ThemeMode.light ? 'light' : 'dark');
}
```

`TaskFilterState(priority: TaskPriority?, status: TaskStatusFilter, query: String)` is Equatable. `query` is **not persisted**. The cubit methods are `setPriority`, `setStatus`, `setQuery`, `clearAll`, and each calls `HapticFeedback.selectionClick()` from the widget, not the cubit. `ThemeCubit extends Cubit<ThemeMode>` and has `toggle()`. Tests mock `LocalPreferencesDataSource` with mocktail, so no platform channel is needed.

### C-27 · Repository hygiene & Firebase client config (Spec 01, Spec 02)
- **Commit** `lib/firebase_options.dart`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, `firebase.json`, `.firebaserc`, `firestore.rules` and `firestore.indexes.json`. Firebase client API keys are *identifiers*, not secrets, and access is enforced by the rules (C-12). Committing them lets reviewers build without their own Firebase project.
- **Optional hardening (5 min, user action in Google Cloud Console → Credentials):** restrict the Android API key to package `dev.gigflow.gigflow` plus the SHA-1 of the signing key, and the iOS key to bundle id `dev.gigflow.gigflow`.
- **Never commit:** `android/key.properties`, `*.jks`, `*.keystore`, service-account JSON, `.env*`.
- Append to the generated `.gitignore`:

```gitignore
# --- GigFlow additions ---
/android/key.properties
*.jks
*.keystore
/coverage/
.firebase/
firebase-debug.log
firestore-debug.log
ui-debug.log
.env*
service-account*.json
/release/
```

### C-28 · Connectivity vs actual sync state (Spec 02 `ConnectivityCubit`)
**Wrong:** `connectivity_plus` reports whether a network *interface* exists, not whether Firestore has synced. A captive portal shows "online" with writes still pending.
**Fix:** The banner state comes from **both** signals (see §3 F4). `lib/core/services/connectivity_cubit.dart`:

```dart
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// State: true = has a network interface.
class ConnectivityCubit extends Cubit<bool> {
  ConnectivityCubit(this._connectivity) : super(true) {
    _sub = _connectivity.onConnectivityChanged.listen(_update);
    unawaited(_connectivity.checkConnectivity().then(_update));
  }

  final Connectivity _connectivity;
  late final StreamSubscription<List<ConnectivityResult>> _sub;

  void _update(List<ConnectivityResult> results) {
    if (isClosed) return;
    emit(results.isNotEmpty && results.any((r) => r != ConnectivityResult.none));
  }

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
```

### C-29 · `analysis_options.yaml` (Spec 01 §5)
```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-raw-types: true
  exclude:
    - lib/firebase_options.dart
    - build/**

linter:
  rules:
    always_declare_return_types: true
    always_use_package_imports: true
    avoid_print: true
    directives_ordering: true
    prefer_const_constructors: true
    prefer_const_declarations: true
    prefer_final_locals: true
    sort_child_properties_last: true
    unawaited_futures: true
    use_super_parameters: true
```

Run `dart format lib test` once right after `flutterfire configure` so the generated `firebase_options.dart` doesn't fail the format gate.

### C-30 · Verification gate (Spec 01 §5)
**Override:** Every phase must pass all of the following, each with exit code 0:

```powershell
dart format --output=none --set-exit-if-changed lib test
```
```powershell
flutter analyze --fatal-infos --fatal-warnings
```
```powershell
flutter test
```

If a phase adds no tests yet, `flutter test` must still pass (Phase 0 keeps the generated `test/widget_test.dart` deleted and adds `test/smoke_test.dart` with a trivial `expect(1 + 1, 2)` until real tests land in Phase 1).

### C-31 · Agent prompt pattern replaces Spec 06 (Spec 06)
**Wrong:** Wrong paths; Prompt 4 is too large for one reliable pass.
**Fix:** For each phase in §4, use this exact template:

> Read `docs/07_AUDIT_CORRECTIONS_AND_PRODUCTION_ROADMAP.md` §0–§3 and **Phase N** in §4. Where 07 is silent, also read the original spec sections it references. Implement **only** the files listed for Phase N, apply every correction it references, then run the Phase N verification commands. Fix everything until all exit 0, then report the results and the proposed commit message. Do not start Phase N+1.

### C-32 · README corrections (README template)
- Replace "Verified sub-8 ms raster frame times" with the **measured** numbers from §5.3 (device model, refresh rate, avg/p90/worst UI & raster ms), or remove the claim.
- Prerequisites: "Flutter 3.47.x stable (Dart 3.13), tested on Flutter 3.47.5". Android minSdk 24, iOS 15.0.
- Add a **"Reviewer quick install"** section: download `gigflow-v1.0.0-universal.apk` from Releases, then `adb install -r gigflow-v1.0.0-universal.apk` (or open it on the phone with "Install unknown apps" allowed).
- Add a **"Use your own Firebase project"** section: create the project, enable Email/Password, create the Firestore DB, `flutterfire configure`, `firebase deploy --only firestore:rules`.
- Replace the test list with the suite in §4 (Phase 6 table). Add an "Offline behaviour" subsection explaining latency compensation, non-awaited writes and the sync banner.
- Screenshot paths `docs/screenshots/*.png` are retained.

---

## 3. Approved High-Impact New Features (Deadline-Safe Scope)

All features are **pure-Dart-first** (unit-testable), add **no new packages** and **no new BackdropFilter surfaces**. Total estimated cost is about 3.5 hours, built in Phase 5.

| ID | Feature | Value to gig worker / reviewer | Est. |
|---|---|---|---|
| F1 | Instant local search | Find "order #4821" in a long shift list in one tap | 30 min |
| F2 | Overdue badge + Today shift progress bar | At-a-glance shift health | 45 min |
| F3 | Haptics on key actions | Tactile confirmation while riding/driving | 10 min |
| F4 | Connectivity + sync indicator | Proves offline-first behaviour on camera | 40 min |
| F5 | Persisted Light/Dark glass switch | Daylight readability | 15 min (cubit exists) |
| F6 | One-tap due-date presets | Create a task in < 5 s | 30 min |
| F7 | "No-blur-in-list" performance contract test + CI (analyze + test) | Engineering-rigour signal | 30 min |

### F1 — Instant local search
- **UI:** A compact `TextField` (search icon prefix, clear `IconButton` suffix when non-empty, `textInputAction: TextInputAction.search`) in the pinned dock, between the progress row and the filter pills. It is a translucent fill, *not* a separate blur.
- **Logic:** `TaskFilterCubit.setQuery(String)` feeds `TaskQueryEngine.apply(searchQuery:)` (C-14). Matching is a case-insensitive substring on title + description, with no debounce (in-memory, < 1 ms for 500 tasks). Search is not persisted.
- **Empty state:** "No tasks match “query”" plus a `Clear search & filters` button that calls `clearAll()`.
- **Acceptance:** typing filters on every keystroke, combined with priority/status and still sorted earliest→latest. Unit tests cover title match, description match, case-insensitivity, whitespace trimming, and query+filter combination.

### F2 — Overdue badge + Today shift progress
`lib/features/tasks/domain/utils/shift_stats.dart`:

```dart
import 'package:equatable/equatable.dart';

import 'package:gigflow/features/tasks/domain/entities/task_entity.dart';
import 'package:gigflow/features/tasks/domain/enums/task_priority.dart';

final class ShiftStats extends Equatable {
  const ShiftStats({
    required this.todayTotal,
    required this.todayDone,
    required this.overdue,
    required this.highOpen,
  });

  final int todayTotal;
  final int todayDone;
  final int overdue;  // incomplete & due before now (any day)
  final int highOpen; // incomplete high-priority (any day)

  double get progress => todayTotal == 0 ? 0 : todayDone / todayTotal;

  /// Computed from ALL visible tasks (ignores filters/search on purpose).
  static ShiftStats compute(List<TaskEntity> tasks, DateTime now) {
    final n = now.toLocal();
    final start = DateTime(n.year, n.month, n.day);
    final end = DateTime(n.year, n.month, n.day + 1);
    var total = 0, done = 0, overdue = 0, high = 0;
    for (final t in tasks) {
      final d = t.dueDate.toLocal();
      if (!d.isBefore(start) && d.isBefore(end)) {
        total++;
        if (t.isCompleted) done++;
      }
      if (t.isOverdueAt(now)) overdue++;
      if (!t.isCompleted && t.priority == TaskPriority.high) high++;
    }
    return ShiftStats(todayTotal: total, todayDone: done, overdue: overdue, highOpen: high);
  }

  @override
  List<Object?> get props => [todayTotal, todayDone, overdue, highOpen];
}
```

- **UI:** "3 of 7 done today" plus a 6px rounded `LinearProgressIndicator` animated with `TweenAnimationBuilder<double>` (300 ms). Next to it sit two pills: `⚠ 2 overdue` (overdue colour, hidden when 0) and `▲ 1 high` (hidden when 0). The pills have a `Semantics(label: '2 overdue tasks')`.
- **Tile:** an "Overdue" badge when `task.isOverdueAt(now)`.
- **Tests:** midnight boundaries, completed overdue not counted, empty list → progress 0.

### F3 — Haptics
| Action | Call |
|---|---|
| Toggle complete | `HapticFeedback.lightImpact()` |
| Swipe delete | `HapticFeedback.mediumImpact()` |
| Filter / preset chip tap | `HapticFeedback.selectionClick()` |
| Auth error banner appears | `HapticFeedback.heavyImpact()` (once per new error, in a `BlocListener` with `listenWhen: (a, b) => b.errorMessage != null && a.errorMessage != b.errorMessage`) |

No permission is needed (Android `performHapticFeedback`).

### F4 — Connectivity + sync indicator
`lib/core/services/sync_status.dart`:

```dart
enum SyncStatus { synced, syncing, offline }

SyncStatus resolveSyncStatus({required bool online, required bool hasPendingWrites}) {
  if (!online) return SyncStatus.offline;
  if (hasPendingWrites) return SyncStatus.syncing;
  return SyncStatus.synced;
}
```

- **Sources:** `ConnectivityCubit` (C-28) and `TaskState.hasPendingWrites` (from `snapshots(includeMetadataChanges: true)`).
- **UI:** a row inside the pinned dock, animated with `AnimatedSize` + `AnimatedSwitcher` (200 ms):
  - `offline` → cloud-off icon with "Offline — changes are saved on this device"
  - `syncing` → 12px spinner with "Syncing changes…"
  - `synced` → hidden (`SizedBox.shrink()`)
  - It's a solid translucent fill — never a new BackdropFilter. Wrap it in `Semantics(liveRegion: true)`.
- **Tests:** a truth table for `resolveSyncStatus`.

### F5 — Persisted theme switcher
A sun/moon `IconButton` in the header (48dp, tooltip "Switch to light mode"/"Switch to dark mode") calls `ThemeCubit.toggle()`. The theme is persisted via C-26 and restored synchronously at startup (`SharedPreferencesWithCache` is pre-loaded), so there's no flash. The default is dark.

### F6 — One-tap quick due-date presets
`lib/features/tasks/domain/utils/quick_due_presets.dart`:

```dart
enum DuePreset { inOneHour, today6pm, tomorrow9am }

abstract final class QuickDuePresets {
  static String label(DuePreset p) => switch (p) {
        DuePreset.inOneHour => '+1 hr',
        DuePreset.today6pm => 'Today 6 PM',
        DuePreset.tomorrow9am => 'Tomorrow 9 AM',
      };

  /// Today 6 PM is unavailable once it is 6 PM or later.
  static bool isAvailable(DuePreset p, DateTime now) =>
      p != DuePreset.today6pm || now.isBefore(DateTime(now.year, now.month, now.day, 18));

  static DateTime resolve(DuePreset p, DateTime now) => switch (p) {
        DuePreset.inOneHour => DateTime(
            now.year, now.month, now.day, now.hour, now.minute,
          ).add(const Duration(hours: 1)),
        DuePreset.today6pm => DateTime(now.year, now.month, now.day, 18),
        DuePreset.tomorrow9am => DateTime(now.year, now.month, now.day + 1, 9),
      };
}
```

- **UI:** `ChoiceChip`s in the editor; the selected chip reflects the current due date when it equals a preset. Unavailable presets are hidden, not disabled.
- **Default due date for a new task:** `+1 hr`.
- **Tests:** 17:59 vs 18:00 availability, month/year rollover for "tomorrow" (31 Dec → 1 Jan), minute normalisation.

### F7 — Performance contract test + CI
- `test/features/tasks/presentation/dashboard_blur_budget_test.dart` pumps `TaskDashboardScreen` with mocked blocs and 30 tasks, then asserts:
  - `find.descendant(of: find.byType(TaskTile), matching: find.byType(BackdropFilter))` → `findsNothing`
  - `find.byType(BackdropFilter)` → `findsAtMost(2)`
- `.github/workflows/ci.yml`:

```yaml
name: ci
on: [push, pull_request]
jobs:
  analyze-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: 3.47.5
          channel: stable
          cache: true
      - run: flutter pub get
      - run: dart format --output=none --set-exit-if-changed lib test
      - run: flutter analyze --fatal-infos --fatal-warnings
      - run: flutter test
```

### Out-of-Scope / Do-Not-Build List
Do **not** build any of the following before submission, even if time seems available. Polish and QA come first.
1. Push/local notifications and reminders (`flutter_local_notifications`)
2. Earnings or analytics dashboards and charts
3. Google/Apple/phone sign-in, password reset, email verification, account deletion
4. Recurring tasks, subtasks, tags, attachments, location/maps, shift templates
5. A second local database (Hive/Isar/Drift/sqflite), because Firestore's cache *is* the offline store
6. Migrating state management (Riverpod/Provider/GetX), or code generation (freezed/json_serializable/injectable)
7. Web, desktop or tablet-specific layouts beyond the 640px max-width centring
8. Crashlytics, Analytics, App Check, Remote Config, Cloud Functions
9. Localization/i18n beyond English
10. Lottie/Rive animations, custom shaders, animated mesh backgrounds, per-card `BackdropFilter`
11. Integration tests on device farms or the Firestore emulator test harness
12. Play Store/TestFlight publishing, CI release automation (CI runs analyze + test only)

---

## 4. Practical Step-by-Step Implementation Roadmap (Execution Blueprint)

**Timeline (IST):** Phases 0–3 on Sat 21 Nov (evening); Phases 4–5 on Sun 22 Nov; Phases 6–7 on Mon 23 Nov. **Submission target: 20:00 IST on Mon 23 Nov.** If you are behind schedule at the end of Sunday, drop F7's CI file first, then F1, but never the tests in Phase 6.

Every phase ends with the **C-30 gate** plus its own checks, then **one commit**. The branch is `main` and commits follow Conventional Commits.

### Phase 0 — Toolchain, scaffold, Firebase wiring (≈ 1.5 h)
**User actions required (Claude cannot do these):**
1. `flutter doctor --android-licenses` (accept the licenses).
2. Create a Firebase project in the console (e.g. `gigflow-<suffix>`). Enable **Authentication → Email/Password**. Create **Firestore Database** in production mode, region `asia-south1` (Mumbai).
3. `firebase login` (interactive browser sign-in).
4. Download the Plus Jakarta Sans static TTFs (C-03) into `assets/fonts/`, or choose the fallback.
5. Connect an Android phone with USB debugging (needed from Phase 2 onward for real-device runs; an emulator is OK until Phase 6).

**Agent commands (in order, from the workspace root):**

```powershell
npm install -g firebase-tools
```
```powershell
dart pub global activate flutterfire_cli
```
```powershell
flutter create --org dev.gigflow --project-name gigflow --platforms android,ios --empty .
```
```powershell
git init -b main
```
```powershell
flutterfire configure --project=<firebase-project-id> --platforms=android,ios --android-package-name=dev.gigflow.gigflow --ios-bundle-id=dev.gigflow.gigflow --yes
```
```powershell
flutter pub get
```
```powershell
dart format lib test
```
```powershell
firebase deploy --only firestore:rules --project <firebase-project-id>
```

**Files to create/modify:**
- `pubspec.yaml` (C-01), `analysis_options.yaml` (C-29), `.gitignore` additions (C-27)
- `android/app/build.gradle.kts`, `android/app/proguard-rules.pro`, `android/app/src/main/AndroidManifest.xml` (C-04)
- `ios/Podfile`, `ios/Runner.xcodeproj/project.pbxproj`, `ios/Runner/Info.plist` (C-05)
- `firestore.rules`, `firebase.json`, `firestore.indexes.json` (C-12)
- `lib/main.dart` (C-25; temporarily `runApp(const MaterialApp(home: SizedBox()))` until Phase 1 provides `GigFlowApp` and DI)
- `assets/fonts/*.ttf` + `assets/fonts/OFL.txt` (C-03)
- Delete `test/widget_test.dart` if generated; create `test/smoke_test.dart`

**Acceptance criteria:**
- `flutter pub get` resolves with exactly the C-01 versions. Check that the `firebase_core`, `go_router` and `equatable` lines in `pubspec.lock` show 5.2.x / 18.1.x / 3.0.x.
- `flutter build apk --debug` succeeds (proves the Gradle/AGP 9/google-services setup; apply the C-04 fallback if it fails).
- `flutter run` on the phone/emulator opens a blank app with no Firebase init exception in the logs.
- Rules are deployed: Firebase Console → Firestore → Rules shows the C-12 content.

**Verification:**
```powershell
flutter pub deps --style=compact | Select-String "firebase_core|cloud_firestore|firebase_auth|go_router|flutter_bloc|equatable"
```
```powershell
flutter build apk --debug
```
Then run the C-30 gate.

**Commit:** `chore(setup): scaffold flutter 3.47 project with firebase, pinned deps, lints, and release-ready android/ios config`

---

### Phase 1 — Core: theme, glass primitives, errors, validators, DI, router shell (≈ 2 h)
**Files:**
- `lib/app/theme/app_colors.dart` (C-18), `liquid_glass_theme.dart` (C-19), `app_theme.dart` (C-20), `app_typography.dart` (text styles from Spec 03 §3, `fontFamily` from C-03), `theme_cubit.dart` (C-26)
- `lib/core/widgets/ambient_mesh_background.dart` (Spec 03 §4.1 code, with orb colours read from `context.glass.orbs`), `specular_rim_painter.dart`, `liquid_glass_card.dart`, `liquid_glass_chrome.dart` (C-21), `liquid_glass_button.dart`, `liquid_glass_text_field.dart`
- `lib/core/error/failures.dart`, `firebase_error_mapper.dart` (C-10); `lib/core/utils/validators.dart` (C-11)
- `lib/core/services/connectivity_cubit.dart` (C-28), `sync_status.dart` (F4)
- `lib/features/tasks/data/datasources/local_preferences_datasource.dart` (C-26) and `lib/features/tasks/domain/enums/*` (needed by the datasource)
- `lib/app/di/injection_container.dart`, `lib/app/app.dart`, `lib/app/router/*` (C-08, C-25). Auth/task screens are stubbed as `Placeholder()` widgets in their final file paths.
- Tests: `test/core/error/firebase_error_mapper_test.dart`, `test/core/utils/validators_test.dart`, `test/core/services/sync_status_test.dart`, `test/core/widgets/liquid_glass_card_test.dart` (asserts no `BackdropFilter` descendant)

**Rules:**
- `liquid_glass_chrome.dart` is the only file in `lib/` containing the string `BackdropFilter`.
- `LiquidGlassButton` has a min size of 48×48, shows a pressed scale of 0.97 via `AnimatedScale` (transform only, no saveLayer), and takes `isLoading` and `onPressed: null` (disabled) states.
- The error mapper test covers **every** case in C-10 plus an unknown code.

**Verification:** run the C-30 gate, then:
```powershell
flutter test test/core
```
```powershell
Get-ChildItem -Recurse lib -Filter *.dart | Select-String -Pattern "BackdropFilter" | Select-Object Path -Unique
```
The second command must list only `lib\core\widgets\liquid_glass_chrome.dart`.

**Commit:** `feat(core): add liquid glass design system, wcag-aa theme tokens, error mapping, validators, di, and router shell`

---

### Phase 2 — Authentication (≈ 2.5 h)
**Files:**
- `lib/features/auth/domain/entities/app_user.dart`, `domain/repositories/auth_repository.dart`
- `lib/features/auth/data/repositories/firebase_auth_repository.dart` (C-10)
- `lib/features/auth/presentation/bloc/auth_bloc.dart`, `auth_event.dart`, `auth_state.dart` (C-09)
- `lib/features/auth/presentation/screens/splash_screen.dart`, `login_screen.dart`, `register_screen.dart`
- `lib/features/auth/presentation/widgets/auth_error_banner.dart`
- Tests: `test/features/auth/presentation/auth_bloc_test.dart`, `test/features/auth/presentation/login_screen_test.dart`, `test/features/auth/presentation/register_screen_test.dart`

**Rules & acceptance:**
- Screen layout follows Spec 03 Screen A: `SingleChildScrollView(keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag)` inside `SafeArea`, content capped at `ConstrainedBox(maxWidth: 440)` and centred, with one `LiquidGlassChrome` card. Form UX follows C-11. The error banner is an `AnimatedSize` coral pill with `Semantics(liveRegion: true)`.
- Navigation between login and register uses `context.go(Routes.register)` / `context.go(Routes.login)`. Auth success **never** navigates manually; the router redirect does it.
- `auth_bloc_test`:
  - (a) Subscription emits `unauthenticated` → `authenticated` from a mocked stream.
  - (b) Login success emits `[isSubmitting: true]` → `[isSubmitting: false]`.
  - (c) `AuthFailure` emits `errorMessage`.
  - (d) Two rapid `AuthLoginSubmitted` events cause the repository to be called **once** (droppable).
  - (e) Logout calls `signOut`.
- `login_screen_test`:
  - (a) An empty submit shows both validation errors and the bloc receives no event (`verifyNever`).
  - (b) Invalid email shows the inline error.
  - (c) `errorMessage` in state renders the banner text.
  - (d) The password visibility toggle flips `obscureText`.
  - (e) The CTA is disabled while `isSubmitting`.

**Manual test (debug, on device):**
1. Register a new email → lands on the `/tasks` placeholder.
2. Kill the app and reopen → still on `/tasks`, with no login flash (only splash).
3. Log out → `/login`.
4. Wrong password → "Incorrect email or password…".
5. `bad@` → inline "valid email" error.
6. Register an existing email → "already exists".
7. Airplane mode + login → "No internet connection…".

**Verification:** run the C-30 gate, then:
```powershell
flutter test test/features/auth
```

**Commit:** `feat(auth): implement firebase email/password auth with route guards, error mapping, and double-submit protection`

---

### Phase 3 — Task domain & data layer (≈ 2 h)
**Files:**
- `lib/features/tasks/domain/entities/task_entity.dart`, `task_feed.dart` (C-07, C-14)
- `lib/features/tasks/domain/enums/task_priority.dart`, `task_status_filter.dart`
- `lib/features/tasks/domain/repositories/task_repository.dart` (C-07)
- `lib/features/tasks/domain/utils/task_query_engine.dart` (C-14), `date_grouping.dart` (C-15), `shift_stats.dart` (F2), `quick_due_presets.dart` (F6)
- `lib/features/tasks/data/models/task_model.dart` (C-06), `data/repositories/firestore_task_repository.dart` (C-07)
- Tests:
  - `test/features/tasks/domain/task_query_engine_test.dart`
  - `test/features/tasks/domain/date_grouping_test.dart`
  - `test/features/tasks/domain/shift_stats_test.dart`
  - `test/features/tasks/domain/quick_due_presets_test.dart`
  - `test/features/tasks/data/task_model_test.dart`

**Required test cases:**
- **Query engine:**
  - Unsorted past/today/next-week input → earliest→latest.
  - Same `dueDate` → high, medium, low.
  - Same due and priority → `createdAt` then `id`.
  - Each priority alone; each status alone.
  - Priority+status combined stays sorted.
  - Search on title, on description, case-insensitive, trimmed, and combined with filters.
  - The input list is not mutated, and the output is unmodifiable.
- **Date grouping:**
  - The C-15 counter-example (07:00 completed + 08:00 incomplete at `now` 10:00) lands in **one** `pastDue` group, in order.
  - Boundary 23:59 → today and 00:00 → tomorrow; +2 days → upcoming.
  - Labels: OVERDUE vs EARLIER.
  - Flattening all groups equals the input order (property check over 200 randomly generated tasks with a fixed `Random(42)` seed).
- **Task model:**
  - Round-trip `toFirestore` → `fromMap` preserves every field (minute-normalised).
  - Null `createdAt`/`updatedAt` (pending server timestamp) → no throw; falls back to `dueDate`.
  - Unknown priority → medium; a non-bool `isCompleted` → false; a missing title → `''`.

**Verification:** run the C-30 gate, then:
```powershell
flutter test test/features/tasks/domain test/features/tasks/data
```
Domain purity check (must return nothing):
```powershell
Get-ChildItem -Recurse lib/features/*/domain -Filter *.dart | Select-String -Pattern "package:flutter/|cloud_firestore|firebase_auth"
```

**Commit:** `feat(tasks): add task domain, deterministic query engine, monotonic date grouping, and offline-safe firestore repository`

---

### Phase 4 — Task presentation: bloc, dashboard, tile, editor, undo (≈ 4 h)
**Files:**
- `lib/features/tasks/presentation/bloc/task_bloc.dart`, `task_event.dart`, `task_state.dart` (C-16)
- `lib/features/tasks/presentation/cubit/task_filter_cubit.dart`, `task_filter_state.dart` (C-26)
- `lib/features/tasks/presentation/screens/task_dashboard_screen.dart` (C-22, C-23, C-15 `now` timer)
- `lib/features/tasks/presentation/screens/task_editor_sheet.dart` (C-24)
- `lib/features/tasks/presentation/widgets/dashboard_header_delegate.dart`, `shift_summary_header.dart`, `filter_dock.dart`, `task_section_header.dart`, `task_tile.dart`, `empty_tasks_view.dart`, `new_task_fab.dart`
- Tests: `test/features/tasks/presentation/task_bloc_test.dart`, `test/features/tasks/presentation/task_filter_cubit_test.dart`

**Rules & acceptance:**
- **TaskTile:** a 48×48 checkbox hit area (`InkResponse` with radius 24) and `Semantics(checked:, label: 'Mark “title” complete')`; a title with ellipsis; a 2-line description; a due chip (`DateFormat('EEE, d MMM · h:mm a')`, crimson only when `isOverdueAt(now)`); a priority badge; tap → edit sheet; swipe → C-17. `const` constructors where possible.
- **Empty states:**
  - No tasks at all → "No tasks yet — tap + New Task to plan your shift".
  - Filters/search exclude everything → "No tasks match your filters" + `Clear filters`.
  - Initial loading → 4 skeleton `LiquidGlassCard`s with static placeholder bars (no shimmer animation).
  - Load `failure` with empty cache → a retry message.
- **`task_bloc_test`** (mocktail; `registerFallbackValue` for `TaskEntity`; injected `clock`):
  - (a) Subscription → `loading`, then `ready` with the feed.
  - (b) `TaskCreated` → `upsertTask` called with the generated id, trimmed fields, minute-normalised due date and `createdAt == updatedAt == clock()`.
  - (c) `TaskUpdated` → `upsertTask` with a new `updatedAt`.
  - (d) `TaskCompletionToggled` → `setCompletion(isCompleted: !old)`.
  - (e) `TaskDeleted` → immediately emits the id in `pendingDeleteIds`, so `visibleTasks` excludes it, and calls `deleteTask`.
  - (f) `TaskRestored` → removes the id from the pending set and calls `upsertTask` with the **same id and createdAt**.
  - (g) A stream error after data keeps the tasks and sets `errorMessage`.
  - (h) A write future that throws `TaskFailure` → state `errorMessage` equals the failure message.
  - (i) The pending set is pruned when the feed no longer contains the id.
- **`task_filter_cubit_test`:** loads persisted values; each setter emits and writes to the mocked datasource; `clearAll` resets priority, status and query.
- `TaskBloc` errors surface as a SnackBar via `BlocListener` (`listenWhen` on `errorMessage` change), then `TaskErrorDismissed` is dispatched.

**Manual tests (debug, on device):**
1. Create 3 tasks via presets → they appear instantly in the correct sections and order.
2. Edit a due date → the task moves to the correct position.
3. Toggle complete → strike-through + haptic.
4. Swipe delete → Undo within 4 s restores it at the same position. Wait 5 s → the SnackBar is gone (C-17).
5. Swipe delete two tasks quickly → no "dismissed Dismissible" exception.
6. **Airplane mode:** create 2, toggle 1, delete 1 + undo, kill the app, reopen → all changes present. Disable airplane mode → Firebase Console shows the documents within about 10 s.

**Verification:** run the C-30 gate, then:
```powershell
flutter test test/features/tasks/presentation
```

**Commit:** `feat(tasks): add task dashboard, glass task tiles, editor sheet with presets, and offline-safe crud with undo`

---

### Phase 5 — Approved features F1–F6 & dashboard polish (≈ 3 h)
**Files:**
- `filter_dock.dart` (search field — F1)
- `shift_summary_header.dart` (F2 progress + pills, F5 theme toggle, logout with confirm dialog)
- `lib/features/tasks/presentation/widgets/sync_status_row.dart` (F4)
- `task_tile.dart` (F2 overdue badge, F3 haptics)
- `task_editor_sheet.dart` (F6 chips)
- `lib/app/theme/theme_cubit.dart` (wiring)
- Tests: extend `task_query_engine_test.dart` (search), and add `test/features/tasks/presentation/sync_status_row_test.dart` (offline → text visible; synced → hidden).

**Rules & acceptance:**
- Logout opens an `AlertDialog` ("Sign out of GigFlow?" with Cancel/Sign out) → `AuthLogoutRequested`. If `TaskState.hasPendingWrites` is true, the dialog adds a warning: "Some changes haven't synced yet and will be lost if you sign out now."
- Responsive checks (no overflow stripes, no clipped text):
  - 360×640 dp at text scale 1.0 and 1.3
  - 412×915 dp
  - Landscape 915×412 dp (content capped at 640 wide and centred)
  - Dark and light themes
- Use the Device Preview–free method: `flutter run -d windows` is unavailable (no Visual Studio), so test on the phone with *Settings → Display → Font size* at max and *Display size* at max, plus an emulator profile `Small Phone (360dp)` (Android Studio AVD).

**Verification:** run the C-30 gate, then:
```powershell
flutter test
```

**Commit:** `feat(dashboard): add instant search, shift progress and overdue badges, sync indicator, theme switch, and quick due presets`

---

### Phase 6 — Test hardening, performance contract, accessibility, CI (≈ 3 h)
**Files:**
- `test/features/tasks/presentation/dashboard_blur_budget_test.dart` (F7)
- `test/features/auth/presentation/register_screen_test.dart` (if not already complete)
- `test/helpers/test_data.dart` (task factories with a fixed `DateTime(2026, 11, 22, 10)`)
- `test/helpers/pump_app.dart` (wraps widgets in `MaterialApp(theme: AppTheme.dark())` + `MultiBlocProvider` of mocks)
- `.github/workflows/ci.yml` (F7)
- `lib/dev/demo_seeder.dart` (§5.3)

**Final test suite (must all pass):**

| File | Covers |
|---|---|
| `test/core/error/firebase_error_mapper_test.dart` | All codes + fallback |
| `test/core/utils/validators_test.dart` | Email, login/new/confirm password, title, description |
| `test/core/services/sync_status_test.dart` | Truth table |
| `test/core/widgets/liquid_glass_card_test.dart` | No `BackdropFilter` in Tier 2 |
| `test/features/auth/presentation/auth_bloc_test.dart` | Stream, submit, droppable, failure, logout |
| `test/features/auth/presentation/login_screen_test.dart` | Validation, banner, toggle, disabled CTA |
| `test/features/auth/presentation/register_screen_test.dart` | Confirm mismatch, weak password |
| `test/features/tasks/domain/task_query_engine_test.dart` | Sort, ties, filters, search, immutability |
| `test/features/tasks/domain/date_grouping_test.dart` | Monotonic, boundaries, labels, property test |
| `test/features/tasks/domain/shift_stats_test.dart` | Today window, overdue, high |
| `test/features/tasks/domain/quick_due_presets_test.dart` | Availability, rollover |
| `test/features/tasks/data/task_model_test.dart` | Round-trip, null timestamps, bad data |
| `test/features/tasks/presentation/task_bloc_test.dart` | CRUD, undo, pending-delete, errors |
| `test/features/tasks/presentation/task_filter_cubit_test.dart` | Persistence + reset |
| `test/features/tasks/presentation/sync_status_row_test.dart` | Banner visibility |
| `test/features/tasks/presentation/dashboard_blur_budget_test.dart` | ≤ 2 blurs, none in tiles |

**Accessibility acceptance:**
- In widget tests, `expect(tester, meetsGuideline(androidTapTargetGuideline))`, `meetsGuideline(textContrastGuideline)` and `meetsGuideline(labeledTapTargetGuideline)` pass for the login screen and the dashboard with 5 tasks.
- On device, TalkBack reads each tile as "title, due …, priority …, not completed".

**Verification:**
```powershell
dart format --output=none --set-exit-if-changed lib test
```
```powershell
flutter analyze --fatal-infos --fatal-warnings
```
```powershell
flutter test --coverage
```
Line coverage from `lcov.info` (target ≥ 80% for `lib/features/*/domain` and `presentation/bloc`; informational overall):
```powershell
$lf=0;$lh=0; Get-Content coverage/lcov.info | ForEach-Object { if($_ -match '^LF:(\d+)'){$lf+=[int]$Matches[1]} elseif($_ -match '^LH:(\d+)'){$lh+=[int]$Matches[1]} }; "{0:N1}% ({1}/{2} lines)" -f (100*$lh/$lf),$lh,$lf
```
Then run the §5.3 benchmark protocol on the physical device and record the numbers.

**Commit:** `test: complete unit, bloc, widget, accessibility, and blur-budget suites; add ci workflow`

---

### Phase 7 — Release build, branding, README, GitHub release, demo video (≈ 3 h)
Everything is in §5. **Files:** `assets/branding/app_icon.png` (1024×1024), `assets/branding/app_icon_foreground.png` (1024×1024, glyph inside the central 66%), `flutter_launcher_icons.yaml`, `flutter_native_splash.yaml`, `android/key.properties` (local only), `README.md` (root, built from the template + C-32), `docs/screenshots/{login,dashboard,filters,editor}.png`, `docs/RELEASE_NOTES_v1.0.0.md`.

**Commit:** `chore(release): add app icon, native splash, release signing, readme, and v1.0.0 release notes`, then tag `v1.0.0`.

---

## 5. Production Build, Performance Profiling & Release Engineering

### 5.1 Android production build
**Identity**

| Item | Value | Where |
|---|---|---|
| applicationId / namespace | `dev.gigflow.gigflow` | `android/app/build.gradle.kts` |
| Display name | `GigFlow` | `AndroidManifest.xml` `android:label` |
| Version | `1.0.0+1` → versionName 1.0.0, versionCode 1 | `pubspec.yaml` |
| minSdk / targetSdk / compileSdk | 24 / 36 / 36 | C-04 |

**Adaptive icon + splash.** The icon PNGs are designed by the user (Figma/Canva): a cobalt→teal gradient tile with a white check-route glyph. `flutter_launcher_icons.yaml`:

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/branding/app_icon.png"
  remove_alpha_ios: true
  min_sdk_android: 24
  adaptive_icon_background: "#070B14"
  adaptive_icon_foreground: "assets/branding/app_icon_foreground.png"
```

`flutter_native_splash.yaml`:

```yaml
flutter_native_splash:
  color: "#070B14"
  image: "assets/branding/app_icon_foreground.png"
  android_12:
    color: "#070B14"
    image: "assets/branding/app_icon_foreground.png"
  ios: true
  android: true
  fullscreen: false
```

```powershell
dart run flutter_launcher_icons
```
```powershell
dart run flutter_native_splash:create
```

**Release signing (user action, since it involves passwords).** Run this and enter the passwords yourself when prompted:

```powershell
keytool -genkey -v -keystore "$env:USERPROFILE\keys\gigflow-upload.jks" -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Then create `android/key.properties` (C-04). If skipped, the release build falls back to debug signing. That still installs fine for reviewers, but future updates would need an uninstall first.

**Build commands**

```powershell
flutter clean
```
```powershell
flutter pub get
```
Universal APK (for reviewers):
```powershell
flutter build apk --release --build-name=1.0.0 --build-number=1
```
Per-ABI APKs (smaller, optional):
```powershell
flutter build apk --release --split-per-abi --build-name=1.0.0 --build-number=1
```

Outputs:
- `build/app/outputs/flutter-apk/app-release.apk` (universal)
- `app-arm64-v8a-release.apk`, `app-armeabi-v7a-release.apk`, `app-x86_64-release.apk`

**Packaging for release:**
```powershell
New-Item -ItemType Directory -Force release | Out-Null; Copy-Item build/app/outputs/flutter-apk/app-release.apk release/gigflow-v1.0.0-universal.apk; Copy-Item build/app/outputs/flutter-apk/app-arm64-v8a-release.apk release/gigflow-v1.0.0-arm64-v8a.apk
```
```powershell
Get-FileHash release/*.apk -Algorithm SHA256 | Format-Table -AutoSize
```

**R8/ProGuard and manifest verification**
1. Confirm the release APK declares `INTERNET`:
   ```powershell
   & "$env:ANDROID_HOME\build-tools\36.0.0\aapt2.exe" dump permissions release/gigflow-v1.0.0-universal.apk
   ```
   The output must include `android.permission.INTERNET`.
2. Confirm minification ran: `build/app/outputs/mapping/release/mapping.txt` exists. Keep it, because it's needed to de-obfuscate stack traces.
3. Install and watch for R8 crashes during the smoke test (§5.4):
   ```powershell
   adb install -r release/gigflow-v1.0.0-universal.apk
   ```
   ```powershell
   adb logcat -c; adb logcat | Select-String -Pattern "FATAL EXCEPTION|ClassNotFoundException|NoSuchMethodError|NoSuchFieldException|MissingPluginException|FirebaseException"
   ```
   It must stay silent through register, login, create, toggle, delete and logout.
4. **If R8 strips something,** add a targeted `-keep` for the class named in the logcat line to `proguard-rules.pro` and rebuild. Never disable minify as a "fix" without recording why in the README.

### 5.2 iOS compatibility & build verification
This host is Windows, so `flutter build ios` **cannot run here**. With a Mac: `cd ios; pod install --repo-update; cd ..; flutter build ios --release --no-codesign`.

**Static checklist (do these on Windows):**
- [ ] `ios/Podfile` has `platform :ios, '15.0'`, and all three `IPHONEOS_DEPLOYMENT_TARGET = 15.0;` (C-05).
  ```powershell
  Select-String -Path ios/Runner.xcodeproj/project.pbxproj -Pattern "IPHONEOS_DEPLOYMENT_TARGET"
  ```
- [ ] `ios/Runner/GoogleService-Info.plist` exists, and its `BUNDLE_ID` is `dev.gigflow.gigflow` (`Select-String ios/Runner/GoogleService-Info.plist -Pattern "dev.gigflow.gigflow"`).
- [ ] `Info.plist` has `CFBundleDisplayName = GigFlow`. No usage-description keys are needed (no camera, location or notifications).
- [ ] No `dart:io` `Platform` usage in `lib/` (C-20):
  ```powershell
  Get-ChildItem -Recurse lib -Filter *.dart | Select-String "Platform\.is"
  ```
  This must return nothing.
- [ ] All screens wrap content in `SafeArea` (or `useSafeArea: true` for sheets). The FAB respects `MediaQuery.paddingOf(context).bottom` (home indicator).
- [ ] The `Custom…` date picker uses `CupertinoDatePicker` when `TargetPlatform.iOS` (C-24). Verify on Android by running a widget test with `debugDefaultTargetPlatformOverride = TargetPlatform.iOS`: it finds `CupertinoDatePicker` after tapping `Custom…`, then resets the override in `tearDown`.
- [ ] Bouncing physics come from the platform default. No hardcoded `ClampingScrollPhysics`.
- [ ] README states "iOS: code-complete and statically verified; not device-tested (no macOS available)". Be honest with the reviewer.

### 5.3 Zero-Lag Liquid Glass benchmark protocol
**Preconditions:** a **physical** mid-range Android phone (emulators are not representative), USB debugging on, battery saver off, brightness fixed, and `flutter run` *not* in debug mode.

**Seeder** (`lib/dev/demo_seeder.dart`, compiled into non-release builds only):

```dart
import 'package:flutter/foundation.dart';

import 'package:gigflow/features/tasks/domain/entities/task_entity.dart';
import 'package:gigflow/features/tasks/domain/enums/task_priority.dart';
import 'package:gigflow/features/tasks/domain/repositories/task_repository.dart';
import 'package:gigflow/features/tasks/domain/utils/task_query_engine.dart';

/// Seeds [count] tasks spread from -2 days to +5 days. Non-release builds only.
void seedDemoTasks(TaskRepository repo, String uid, {int count = 60}) {
  if (kReleaseMode) return;
  final now = DateTime.now();
  const titles = ['Deliver order', 'Pick up parcel', 'Airport drop', 'Restock bag', 'Shift check-in'];
  for (var i = 0; i < count; i++) {
    final due = normalizeToMinute(now.add(Duration(minutes: -2880 + i * 167)));
    final created = now.subtract(Duration(minutes: count - i));
    repo.upsertTask(
      uid,
      TaskEntity(
        id: repo.newTaskId(uid),
        title: '${titles[i % titles.length]} #${4800 + i}',
        description: 'Gate code ${1000 + i}. Call customer on arrival; fragile items.',
        dueDate: due,
        priority: TaskPriority.values[i % 3],
        isCompleted: i % 4 == 0,
        createdAt: created,
        updatedAt: created,
      ),
    ).ignore();
  }
}
```

Trigger it with a **long-press on the header greeting**, wired only when `!kReleaseMode`. It uses `.ignore()` so writes are not awaited (C-07).

**Steps:**
1. Find the device id with `flutter devices`, then run `flutter run --profile -d <device-id>`.
2. In the log, confirm `Using the Impeller rendering backend (Vulkan)` (or `(OpenGLES)`). If it says Skia, note it in the README because the first-run shader jank expectations differ.
3. Log in, long-press the greeting to seed 60 tasks, and wait for "Syncing…" to disappear.
4. Press `P` in the terminal to toggle the performance overlay, then open DevTools (the URL is printed by `flutter run`) → **Performance**.
5. Record these scenarios, each three times, in **dark and light** themes:
   - S1: fling-scroll top→bottom→top continuously for 10 s.
   - S2: slow drag-scroll for 10 s with the header collapsing and expanding.
   - S3: toggle 5 checkboxes while the list is settled, then scroll.
   - S4: open the editor sheet, type 20 characters (keyboard animating), close it.
   - S5: change filters 10× rapidly, then type a search query.
6. In DevTools, export or read the frame chart. Record avg, p90 and worst **UI** and **Raster** ms per scenario.

**Acceptance (all must hold):**

| Device refresh | Avg UI | Avg Raster | p90 Raster | Worst frame | Jank frames |
|---|---|---|---|---|---|
| 60 Hz | < 8 ms | < 8 ms | < 12 ms | < 16.7 ms | 0 in S1–S3 |
| 90/120 Hz | < 6 ms | < 6 ms | < 8.3 ms | < 16.7 ms | ≤ 1% in S1–S3 |

S4 may show 1–2 frames over budget during keyboard open (route/sheet build); anything more than that fails.

**If it fails, try these in order:**
1. Confirm no `BackdropFilter` sits inside a list (Phase 1 grep, F7 test).
2. Reduce `blurSigma` 16 → 12.
3. Use `BackdropGroup` + `BackdropFilter.grouped` for the header + FAB (C-22).
4. Drop the card `BoxShadow` `blurRadius` from 12 to 8.
5. Check DevTools "Rebuild stats" for list rebuilds on connectivity or timer ticks (C-23).

**Cold start (informational, put it in the README):**
```powershell
flutter run --profile --trace-startup -d <device-id>
```
Then read `timeToFirstFrameMicros` from `build/start_up_info.json`. The target is < 2.0 s on a mid-range device.

Record the results in the README as a table, with a DevTools screenshot at `docs/screenshots/devtools_profile.png`.

### 5.4 Final pre-submission QA gate
**Automated (all must exit 0):**
```powershell
dart format --output=none --set-exit-if-changed lib test
```
```powershell
flutter analyze --fatal-infos --fatal-warnings
```
```powershell
flutter test --coverage
```

**Manual, on the INSTALLED RELEASE APK.** Uninstall any debug build first with `adb uninstall dev.gigflow.gigflow`, then `adb install release/gigflow-v1.0.0-universal.apk`.

| # | Scenario | Expected |
|---|---|---|
| 1 | Cold start (fresh install) | Native splash → splash route → Login. No white flash; correct font |
| 2 | Register new account | Lands on dashboard with the empty state |
| 3 | Wrong password | "Incorrect email or password…" banner + heavy haptic; CTA re-enabled |
| 4 | Invalid email format | Inline validation; no network call |
| 5 | Double-tap Sign In | One request (no duplicate errors or flicker) |
| 6 | Kill & reopen | Still signed in; filters & theme restored |
| 7 | Create 5 tasks with mixed presets/priorities | Earliest→latest order; correct sections; high before medium on equal time |
| 8 | Filter High + Incomplete, then search | Only matching tasks, still sorted; empty state + Clear when none |
| 9 | Toggle complete | Instant strike-through; progress bar updates |
| 10 | Swipe delete → Undo | Restored at the same position; SnackBar auto-hides after 4 s |
| 11 | **Airplane Mode ON:** create 2, edit 1, toggle 1, delete 1 | Instant UI; banner shows "Offline — changes are saved on this device" |
| 12 | Kill app while offline → reopen offline | All offline changes present |
| 13 | **Airplane Mode OFF** | "Syncing changes…" then hidden; Firebase Console shows the exact state |
| 14 | Logout → login as a different user | No tasks from user A visible |
| 15 | Theme toggle | Smooth switch, persisted; both themes readable outdoors |
| 16 | 360dp phone / max font size | No overflow stripes or clipped CTAs |
| 17 | `adb logcat` filter (§5.1) during 1–16 | Silent |

**Demo video shot list (60–90 s, portrait, screen recording + optional voice-over)**

| Time | Shot |
|---|---|
| 0–8 s | Cold start → splash → Login (glass card over mesh). Title card: "GigFlow — offline-first tasks for gig workers" |
| 8–18 s | Wrong password → error banner; then successful login |
| 18–35 s | Create a task with `Tomorrow 9 AM` + High; create one with `+1 hr`; edit a due date and watch it re-sort |
| 35–45 s | Toggle complete (progress bar moves); swipe delete → Undo |
| 45–58 s | Filter High + Incomplete; search "airport"; Clear filters |
| 58–72 s | Airplane mode: create + toggle → offline banner; disable → "Syncing…" → gone |
| 72–82 s | Fast scroll of 60 seeded tasks with the performance overlay visible; dark ↔ light toggle |
| 82–90 s | Logout. End card: repo URL + "Flutter 3.47 · BLoC · Firestore offline · 16 test suites" |

Upload the video as **Unlisted YouTube** or a public Google Drive link, and check it in a private browser window.

**GitHub release packaging (needs your OK, because it publishes publicly)**
```powershell
git tag -a v1.0.0 -m "GigFlow v1.0.0"
```
```powershell
git push origin main --tags
```
```powershell
gh release create v1.0.0 release/gigflow-v1.0.0-universal.apk release/gigflow-v1.0.0-arm64-v8a.apk --title "GigFlow v1.0.0" --notes-file docs/RELEASE_NOTES_v1.0.0.md
```

`docs/RELEASE_NOTES_v1.0.0.md` must contain: features, a test summary (suite count + pass), benchmark table, SHA-256 hashes, install instructions, and known limitations (iOS not device-tested; debug-signed if no keystore).

Then update the README's APK and video links, commit `docs: add release links, benchmarks, and screenshots`, push, and confirm that the repo page renders (images load, links work while logged out).

**Submission checklist**
- [ ] Public repo URL opens logged-out; README renders with screenshots
- [ ] Release `v1.0.0` has the universal APK attached; the download link works logged-out
- [ ] Demo video link works logged-out
- [ ] `git log --oneline` shows the 8 phase commits + docs commit (Conventional Commits)
- [ ] CI badge green (if F7 CI shipped)
- [ ] Submission sent before **Mon 23 Nov 2026, 20:00 IST** (hard deadline EOD)
