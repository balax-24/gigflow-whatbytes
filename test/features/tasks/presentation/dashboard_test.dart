import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gigflow/core/services/sync_status.dart';
import 'package:gigflow/core/widgets/liquid_glass_card.dart';
import 'package:gigflow/features/auth/domain/entities/app_user.dart';
import 'package:gigflow/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gigflow/features/tasks/domain/enums/task_priority.dart';
import 'package:gigflow/features/tasks/presentation/bloc/task_event.dart';
import 'package:gigflow/features/tasks/presentation/bloc/task_state.dart';
import 'package:gigflow/features/tasks/presentation/cubit/task_filter_state.dart';
import 'package:gigflow/features/tasks/presentation/screens/task_dashboard_screen.dart';
import 'package:gigflow/features/tasks/presentation/widgets/sync_status_pill.dart';
import 'package:gigflow/features/tasks/presentation/widgets/task_tile.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';
import '../../../helpers/pump_app.dart';
import '../../../helpers/test_data.dart';

void main() {
  late MockAuthBloc auth;
  late MockTaskBloc tasks;
  late MockTaskFilterCubit filter;

  setUpAll(() => registerFallbackValue(const TaskErrorDismissed()));

  setUp(() {
    auth = MockAuthBloc();
    tasks = MockTaskBloc();
    filter = MockTaskFilterCubit();
    when(() => auth.state).thenReturn(
      const AuthState(
        status: AuthStatus.authenticated,
        user: AppUser(uid: 'u1', email: 'rider@gig.dev'),
      ),
    );
    when(() => filter.state).thenReturn(const TaskFilterState());
  });

  Future<void> pump(
    WidgetTester t,
    TaskState state, {
    MockConnectivityCubit? conn,
  }) {
    when(() => tasks.state).thenReturn(state);
    return t.pumpApp(
      TaskDashboardScreen(clock: () => testNow),
      authBloc: auth,
      taskBloc: tasks,
      filterCubit: filter,
      connectivityCubit: conn,
    );
  }

  final many = [
    for (var i = 0; i < 30; i++)
      makeTask(
        id: 'id$i',
        title: 'Deliver order #$i',
        due: testNow.add(Duration(hours: i * 3 - 12)),
        priority: TaskPriority.values[i % 3],
        done: i % 4 == 0,
      ),
  ];

  testWidgets('blur budget: no BackdropFilter in tiles, at most 2 total', (
    t,
  ) async {
    await pump(t, TaskState(status: TaskLoadStatus.ready, tasks: many));
    await t.pump();
    expect(find.byType(TaskTile), findsWidgets);
    expect(
      find.descendant(
        of: find.byType(TaskTile),
        matching: find.byType(BackdropFilter),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(LiquidGlassCard),
        matching: find.byType(BackdropFilter),
      ),
      findsNothing,
    );
    final blurs = t
        .widgetList<BackdropFilter>(find.byType(BackdropFilter))
        .where((b) => b.filter is ImageFilter)
        .length;
    expect(blurs, lessThanOrEqualTo(2));
  });

  testWidgets('renders sections in earliest-to-latest order', (t) async {
    final few = [
      makeTask(id: 'later', due: testNow.add(const Duration(hours: 3))),
      makeTask(id: 'past', due: testNow.subtract(const Duration(hours: 1))),
    ];
    await pump(t, TaskState(status: TaskLoadStatus.ready, tasks: few));
    await t.pump();
    expect(find.text('OVERDUE'), findsOneWidget);
    final overdueY = t.getTopLeft(find.text('OVERDUE')).dy;
    final todayY = t.getTopLeft(find.text('TODAY')).dy;
    expect(overdueY, lessThan(todayY));
  });

  testWidgets('empty state when no tasks', (t) async {
    await pump(t, const TaskState(status: TaskLoadStatus.ready));
    await t.pump();
    expect(find.text('No tasks yet'), findsOneWidget);
  });

  testWidgets('filtered-empty state offers clear', (t) async {
    when(() => filter.state).thenReturn(
      const TaskFilterState(priority: TaskPriority.high, query: 'zzz'),
    );
    await pump(t, TaskState(status: TaskLoadStatus.ready, tasks: many));
    await t.pump();
    expect(find.text('No tasks match “zzz”'), findsOneWidget);
    expect(find.text('Clear search & filters'), findsOneWidget);
  });

  testWidgets('offline pill shows when connectivity is lost', (t) async {
    final conn = MockConnectivityCubit();
    when(() => conn.state).thenReturn(false);
    await pump(t, const TaskState(status: TaskLoadStatus.ready), conn: conn);
    await t.pump();
    expect(find.text(SyncStatusPill.offlineText), findsOneWidget);
  });

  testWidgets('synced state hides the pill', (t) async {
    await pump(t, const TaskState(status: TaskLoadStatus.ready));
    await t.pump();
    expect(find.text(SyncStatusPill.offlineText), findsNothing);
    expect(find.text(SyncStatusPill.syncingText), findsNothing);
    expect(
      resolveSyncStatus(online: true, hasPendingWrites: false),
      SyncStatus.synced,
    );
  });

  testWidgets('tapping a checkbox dispatches toggle', (t) async {
    final task = makeTask(id: 'x', title: 'Toggle me');
    await pump(t, TaskState(status: TaskLoadStatus.ready, tasks: [task]));
    await t.pump();
    await t.tap(find.byKey(const ValueKey('toggle-x')));
    verify(() => tasks.add(TaskCompletionToggled(task))).called(1);
  });
}
