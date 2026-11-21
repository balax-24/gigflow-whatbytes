# 04 — Feature Specifications, State Machines & Edge Cases

---

## 1. Authentication Module (`features/auth`)

### Domain Entity (`AppUser`)
```dart
class AppUser extends Equatable {
  final String uid;
  final String email;
  const AppUser({required this.uid, required this.email});
  @override
  List<Object?> get props => [uid, email];
}
```

### Repository Contract (`AuthRepository`)
- `Stream<AppUser?> get authStateChanges`
- `AppUser? get currentUser`
- `Future<AppUser> signInWithEmail({required String email, required String password})`
- `Future<AppUser> registerWithEmail({required String email, required String password})`
- `Future<void> signOut()`

### Firebase Error Mapper (`lib/core/error/firebase_error_mapper.dart`)
Must be a pure static function `String mapAuthErrorCode(String code)` so it is 100% unit-testable.

| Firebase Error Code | User-Facing Message |
|---|---|
| `invalid-credential` | `"Incorrect email or password. Please check your credentials and try again."` |
| `wrong-password` | `"Incorrect email or password. Please check your credentials and try again."` |
| `user-not-found` | `"No account found with this email address."` |
| `invalid-email` | `"Please enter a valid email address."` |
| `email-already-in-use` | `"An account with this email already exists. Try signing in instead."` |
| `weak-password` | `"Password is too weak. Use at least 6 characters with letters and numbers."` |
| `user-disabled` | `"This account has been disabled. Please contact support."` |
| `too-many-requests` | `"Too many failed attempts. Please wait a moment and try again."` |
| `network-request-failed` | `"No internet connection. Check your network and try again."` |
| `operation-not-allowed` | `"Email/password sign-in is not enabled for this app."` |
| *(default / unknown)* | `"Authentication failed. Please try again."` |

> **Critical Detail:** Firebase Auth projects created after 2023 enable Email Enumeration Protection by default and return `invalid-credential` for BOTH wrong password and unknown email. Handling `invalid-credential` explicitly is mandatory.

### Client-Side Validation Rules (`lib/core/utils/validators.dart`)
- **Email:** Trimmed, non-empty, matches standard email regex.
- **Password:** Non-empty, minimum 6 characters.
- **Confirm Password (Register):** Must exactly match Password.
- Trim whitespace on email before sending to Firebase Auth.

### `AuthBloc` Events & States
- **Events:** `AuthSubscriptionRequested`, `AuthLoginSubmitted(email, password)`, `AuthRegisterSubmitted(email, password)`, `AuthLogoutRequested`, `AuthErrorCleared`.
- **States:** `AuthState(status: AuthStatus, user: AppUser?, errorMessage: String?)` where `AuthStatus` is `{unknown, authenticated, unauthenticated, loading}`.
- **Edge Case:** When `AuthLogoutRequested` completes, clear active Firestore stream subscriptions in `TaskBloc` so switching accounts never leaks the previous user's tasks.

---

## 2. Task Management Module (`features/tasks`)

### Domain Enums
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
}

enum TaskStatusFilter { all, incomplete, completed }
```

### Domain Entity (`TaskEntity`)
Fields:
- `final String id;`
- `final String title;`
- `final String description;`
- `final DateTime dueDate;`
- `final TaskPriority priority;`
- `final bool isCompleted;`
- `final DateTime createdAt;`
- `final DateTime updatedAt;`

Include `copyWith(...)` and `Equatable` props.

### Data Model (`TaskModel` extends `TaskEntity`)
- `factory TaskModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc)`
  - Safely parses `Timestamp` (falls back to `DateTime.now()` if a pending local write has null server timestamp).
  - Safely parses `priority` string with fallback to `TaskPriority.medium`.
- `Map<String, dynamic> toFirestore()`
  - Serializes `dueDate`, `createdAt`, `updatedAt` as `Timestamp.fromDate(dt.toUtc())`.
  - Serializes `priority` as `.name` (`'low'`, `'medium'`, `'high'`).

### `FirestoreTaskRepository`
- `Stream<List<TaskEntity>> watchTasks(String userId)`:
  - Queries `firestore.collection('users').doc(userId).collection('tasks').orderBy('dueDate', descending: false).snapshots()`.
  - Maps docs to `List<TaskEntity>`.
- `Future<void> createTask(String userId, TaskEntity task)`:
  - Generates a document reference (`collection.doc()`) and calls `.set(model.toFirestore())`.
  - **Offline Resilience Note:** Do NOT block UI waiting indefinitely for server ACK when offline. Firestore writes immediately to local cache and emits via `snapshots()`. To avoid hanging `await` calls while offline, fire write operations with local-cache-friendly handling or catch timeouts cleanly without reverting the cached local write.
- `Future<void> updateTask(String userId, TaskEntity task)`
- `Future<void> deleteTask(String userId, String taskId)`
- `Future<void> toggleTaskCompletion(String userId, TaskEntity task)`

### Swipe-to-Delete + Undo Behavior
1. User swipes task left -> `TaskBloc` dispatches `TaskDeleted(task)`.
2. Store the deleted `TaskEntity` in memory on the event/callback.
3. Show a `SnackBar` ("Task deleted" + `UNDO` action button for 4 seconds).
4. If user taps `UNDO`, dispatch `TaskRestored(task)` which re-creates the task with its original fields (title, description, dueDate, priority, isCompleted).

---

## 3. Pure Filtering, Sorting & Grouping Engine (`TaskQueryEngine`)

Place in `lib/features/tasks/domain/utils/task_query_engine.dart`. Must have zero Flutter/Firebase imports.

```dart
class TaskQueryEngine {
  /// Filters by optional priority and status, then sorts strictly by dueDate (earliest -> latest).
  /// Tie-breaker: higher priority first, then alphabetical title.
  static List<TaskEntity> apply({
    required List<TaskEntity> tasks,
    TaskPriority? priorityFilter, // null means "All"
    TaskStatusFilter statusFilter = TaskStatusFilter.all,
  }) {
    final filtered = tasks.where((task) {
      final matchesPriority =
          priorityFilter == null || task.priority == priorityFilter;
      final matchesStatus = switch (statusFilter) {
        TaskStatusFilter.all => true,
        TaskStatusFilter.incomplete => !task.isCompleted,
        TaskStatusFilter.completed => task.isCompleted,
      };
      return matchesPriority && matchesStatus;
    }).toList();

    filtered.sort((a, b) {
      final dateCompare = a.dueDate.compareTo(b.dueDate);
      if (dateCompare != 0) return dateCompare;
      final priorityCompare =
          a.priority.sortWeight.compareTo(b.priority.sortWeight);
      if (priorityCompare != 0) return priorityCompare;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    return filtered;
  }
}
```

### Date Section Grouping (`lib/core/utils/date_grouping.dart`)
Given a reference `DateTime now` (injectable for deterministic tests!):
- **`Overdue`:** `!task.isCompleted && task.dueDate.isBefore(now)` (or due date strictly before start of today; keep completed past tasks out of alarming red Overdue styling by grouping completed past tasks cleanly or styling them calm/completed).
  - *Cleanest invariant that preserves global earliest-to-latest list order:* Group strictly by calendar day relative to `now`:
    - `Earlier / Overdue` (before today 00:00, OR today before `now` and incomplete)
    - `Today`
    - `Tomorrow`
    - `Upcoming`
  - **CRITICAL:** Never break the global earliest-to-latest due-date order across sections. Because `Earlier < Today < Tomorrow < Upcoming` is strictly monotonic in time, sorting by `dueDate` ascending first and then bucketizing preserves 100% strict earliest-to-latest order from top to bottom.

---

## 4. Local Preferences Persistence (`TaskFilterCubit` & `ThemeCubit`)

- Persist in `shared_preferences`:
  - `filter_priority`: `'all' | 'high' | 'medium' | 'low'`
  - `filter_status`: `'all' | 'incomplete' | 'completed'`
  - `theme_mode`: `'dark' | 'light'`
- When the user kills and reopens the app, their last selected filter and theme restore immediately without waiting for network.