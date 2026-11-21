import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:gigflow/app/theme/theme_cubit.dart';
import 'package:gigflow/core/services/connectivity_cubit.dart';
import 'package:gigflow/core/services/sync_status.dart';
import 'package:gigflow/dev/demo_seeder.dart';
import 'package:gigflow/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:gigflow/features/tasks/domain/entities/task_entity.dart';
import 'package:gigflow/features/tasks/domain/repositories/task_repository.dart';
import 'package:gigflow/features/tasks/domain/utils/date_grouping.dart';
import 'package:gigflow/features/tasks/domain/utils/shift_stats.dart';
import 'package:gigflow/features/tasks/domain/utils/task_query_engine.dart';
import 'package:gigflow/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:gigflow/features/tasks/presentation/bloc/task_event.dart';
import 'package:gigflow/features/tasks/presentation/bloc/task_state.dart';
import 'package:gigflow/features/tasks/presentation/cubit/task_filter_cubit.dart';
import 'package:gigflow/features/tasks/presentation/cubit/task_filter_state.dart';
import 'package:gigflow/features/tasks/presentation/screens/task_editor_sheet.dart';
import 'package:gigflow/features/tasks/presentation/widgets/dashboard_header_delegate.dart';
import 'package:gigflow/features/tasks/presentation/widgets/empty_tasks_view.dart';
import 'package:gigflow/features/tasks/presentation/widgets/new_task_fab.dart';
import 'package:gigflow/features/tasks/presentation/widgets/sync_status_pill.dart';
import 'package:gigflow/features/tasks/presentation/widgets/task_section_header.dart';
import 'package:gigflow/features/tasks/presentation/widgets/task_tile.dart';

class TaskDashboardScreen extends StatefulWidget {
  const TaskDashboardScreen({super.key, this.clock = DateTime.now});

  /// Injectable for deterministic widget tests.
  final DateTime Function() clock;

  @override
  State<TaskDashboardScreen> createState() => _TaskDashboardScreenState();
}

class _TaskDashboardScreenState extends State<TaskDashboardScreen> {
  late DateTime _now = widget.clock();
  Timer? _ticker;
  late final AppLifecycleListener _lifecycle;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _search.text = context.read<TaskFilterCubit>().state.query;
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => _tick());
    _lifecycle = AppLifecycleListener(onResume: _tick);
  }

  void _tick() {
    if (mounted) setState(() => _now = widget.clock());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _lifecycle.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _confirmLogout() async {
    final hasPending = context.read<TaskBloc>().state.hasPendingWrites;
    final authBloc = context.read<AuthBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out of GigFlow?'),
        content: Text(
          hasPending
              ? "Some changes haven't synced yet and will be lost if you sign out now."
              : 'Your tasks stay safely synced to your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const ValueKey('confirm-logout'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true) authBloc.add(const AuthLogoutRequested());
  }

  void _clearFilters() {
    _search.clear();
    context.read<TaskFilterCubit>().clearAll();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final horizontal = math.max(16.0, (size.width - 640) / 2);
    final scale = (MediaQuery.textScalerOf(context).scale(10) / 10).clamp(
      1.0,
      1.3,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: BlocListener<TaskBloc, TaskState>(
        listenWhen: (a, b) =>
            b.errorMessage != null && a.errorMessage != b.errorMessage,
        listener: (context, state) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          context.read<TaskBloc>().add(const TaskErrorDismissed());
        },
        child: Stack(
          children: [
            BlocBuilder<TaskBloc, TaskState>(
              buildWhen: (a, b) =>
                  a.status != b.status || a.visibleTasks != b.visibleTasks,
              builder: (context, taskState) =>
                  BlocBuilder<TaskFilterCubit, TaskFilterState>(
                    builder: (context, filter) => _buildScrollView(
                      context,
                      taskState: taskState,
                      filter: filter,
                      topPadding: padding.top,
                      bottomPadding: padding.bottom,
                      horizontal: horizontal,
                      scale: scale,
                    ),
                  ),
            ),
            Positioned(
              left: horizontal,
              right: horizontal + 150,
              bottom: padding.bottom + 20,
              child: const Align(
                alignment: Alignment.bottomLeft,
                child: _SyncIndicator(),
              ),
            ),
            Positioned(
              right: horizontal,
              bottom: padding.bottom + 16,
              child: NewTaskFab(onPressed: () => showTaskEditorSheet(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScrollView(
    BuildContext context, {
    required TaskState taskState,
    required TaskFilterState filter,
    required double topPadding,
    required double bottomPadding,
    required double horizontal,
    required double scale,
  }) {
    final all = taskState.visibleTasks;
    final visible = TaskQueryEngine.apply(
      tasks: all,
      priorityFilter: filter.priority,
      statusFilter: filter.status,
      searchQuery: filter.query,
    );
    final groups = DateGrouping.group(visible, _now);
    final rows = <_Row>[
      for (final g in groups) ...[
        _HeaderRow(g, g.label(_now)),
        for (final t in g.tasks) _TaskRow(t),
      ],
    ];
    final indexByKey = <String, int>{
      for (var i = 0; i < rows.length; i++) rows[i].key: i,
    };
    final filterCubit = context.read<TaskFilterCubit>();
    final user = context.select<AuthBloc, String>(
      (b) => b.state.user?.email ?? '',
    );
    final isDark = context.select<ThemeCubit, bool>(
      (c) => c.state != ThemeMode.light,
    );

    final Widget content;
    if (taskState.status == TaskLoadStatus.initial ||
        taskState.status == TaskLoadStatus.loading) {
      content = const SliverToBoxAdapter(child: TaskSkeletonList());
    } else if (taskState.status == TaskLoadStatus.failure && all.isEmpty) {
      content = SliverToBoxAdapter(
        child: EmptyTasksView(
          isFiltering: false,
          onClearFilters: _clearFilters,
        ),
      );
    } else if (rows.isEmpty) {
      content = SliverToBoxAdapter(
        child: EmptyTasksView(
          isFiltering: all.isNotEmpty && filter.isFiltering,
          query: filter.query,
          onClearFilters: _clearFilters,
        ),
      );
    } else {
      content = SliverList.builder(
        itemCount: rows.length,
        findChildIndexCallback: (key) =>
            key is ValueKey<String> ? indexByKey[key.value] : null,
        itemBuilder: (context, i) => switch (rows[i]) {
          final _HeaderRow h => TaskSectionHeader(
            key: ValueKey(h.key),
            label: h.label,
            count: h.group.tasks.length,
            alert: h.label == 'OVERDUE',
          ),
          final _TaskRow r => TaskTile(
            key: ValueKey(r.key),
            task: r.task,
            now: _now,
            onTap: () => showTaskEditorSheet(context, task: r.task),
          ),
        },
      );
    }

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPersistentHeader(
          pinned: true,
          delegate: DashboardHeaderDelegate(
            topPadding: topPadding,
            horizontalPadding: horizontal,
            scale: scale,
            now: _now,
            email: user,
            isDark: isDark,
            stats: ShiftStats.compute(all, _now),
            filter: filter,
            searchController: _search,
            onThemeToggle: () => context.read<ThemeCubit>().toggle(),
            onLogout: _confirmLogout,
            onPriority: filterCubit.setPriority,
            onStatus: filterCubit.setStatus,
            onQuery: filterCubit.setQuery,
            onClearQuery: () {
              _search.clear();
              filterCubit.setQuery('');
            },
            onSeed: kReleaseMode
                ? null
                : () {
                    final bloc = context.read<TaskBloc>();
                    seedDemoTasks(context.read<TaskRepository>(), bloc.userId);
                  },
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontal,
            8,
            horizontal,
            bottomPadding + 104,
          ),
          sliver: content,
        ),
      ],
    );
  }
}

class _SyncIndicator extends StatelessWidget {
  const _SyncIndicator();

  @override
  Widget build(BuildContext context) {
    final online = context.select<ConnectivityCubit, bool>((c) => c.state);
    final pending = context.select<TaskBloc, bool>(
      (b) => b.state.hasPendingWrites,
    );
    return SyncStatusPill(
      status: resolveSyncStatus(online: online, hasPendingWrites: pending),
    );
  }
}

sealed class _Row {
  const _Row();
  String get key;
}

final class _HeaderRow extends _Row {
  const _HeaderRow(this.group, this.label);
  final TaskSectionGroup group;
  final String label;

  @override
  String get key => 'h-${group.section.name}';
}

final class _TaskRow extends _Row {
  const _TaskRow(this.task);
  final TaskEntity task;

  @override
  String get key => 't-${task.id}';
}
