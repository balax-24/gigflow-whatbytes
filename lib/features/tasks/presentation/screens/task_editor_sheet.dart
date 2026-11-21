import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gigflow/core/utils/validators.dart';
import 'package:gigflow/core/widgets/liquid_glass_button.dart';
import 'package:gigflow/core/widgets/liquid_glass_chrome.dart';
import 'package:gigflow/core/widgets/liquid_glass_text_field.dart';
import 'package:gigflow/features/tasks/domain/entities/task_entity.dart';
import 'package:gigflow/features/tasks/domain/enums/task_category.dart';
import 'package:gigflow/features/tasks/domain/enums/task_priority.dart';
import 'package:gigflow/features/tasks/domain/utils/quick_due_presets.dart';
import 'package:gigflow/features/tasks/domain/utils/task_query_engine.dart';
import 'package:gigflow/features/tasks/presentation/bloc/task_bloc.dart';
import 'package:gigflow/features/tasks/presentation/bloc/task_event.dart';
import 'package:gigflow/features/tasks/presentation/widgets/priority_style.dart';
import 'package:gigflow/features/tasks/presentation/widgets/undo_delete.dart';
import 'package:intl/intl.dart';

Future<void> showTaskEditorSheet(BuildContext context, {TaskEntity? task}) {
  final bloc = context.read<TaskBloc>();
  final messenger = ScaffoldMessenger.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (sheetContext) => BlocProvider.value(
      value: bloc,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: TaskEditorSheet(initialTask: task, messenger: messenger),
      ),
    ),
  );
}

class TaskEditorSheet extends StatefulWidget {
  const TaskEditorSheet({super.key, this.initialTask, this.messenger});

  final TaskEntity? initialTask;
  final ScaffoldMessengerState? messenger;

  static const titleKey = ValueKey('editor-title');
  static const saveKey = ValueKey('editor-save');

  @override
  State<TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<TaskEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late DateTime _due;
  late TaskPriority _priority;
  late TaskCategory _category;

  /// Preset the user picked; null after a custom pick or for existing tasks.
  DuePreset? _preset;

  bool get _isEdit => widget.initialTask != null;

  @override
  void initState() {
    super.initState();
    final t = widget.initialTask;
    _title = TextEditingController(text: t?.title ?? '')
      ..addListener(_onTitleChanged);
    _description = TextEditingController(text: t?.description ?? '');
    _preset = t == null ? DuePreset.inOneHour : null;
    _due =
        t?.dueDate ??
        QuickDuePresets.resolve(DuePreset.inOneHour, DateTime.now());
    _priority = t?.priority ?? TaskPriority.medium;
    _category = t?.category ?? TaskCategory.general;
  }

  void _onTitleChanged() => setState(() {});

  @override
  void dispose() {
    _title
      ..removeListener(_onTitleChanged)
      ..dispose();
    _description.dispose();
    super.dispose();
  }

  bool get _canSave => Validators.taskTitle(_title.text) == null;

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final bloc = context.read<TaskBloc>();
    final initial = widget.initialTask;
    if (initial == null) {
      bloc.add(
        TaskCreated(
          title: _title.text,
          description: _description.text,
          dueDate: _due,
          priority: _priority,
          category: _category,
        ),
      );
    } else {
      bloc.add(
        TaskUpdated(
          initial.copyWith(
            title: _title.text,
            description: _description.text,
            dueDate: _due,
            priority: _priority,
            category: _category,
          ),
        ),
      );
    }
    HapticFeedback.lightImpact();
    Navigator.of(context).pop(); // never await the write (offline-safe)
  }

  void _delete() {
    final task = widget.initialTask;
    final messenger = widget.messenger;
    if (task == null) return;
    final bloc = context.read<TaskBloc>();
    Navigator.of(context).pop();
    if (messenger != null) {
      deleteWithUndo(bloc: bloc, messenger: messenger, task: task);
    } else {
      bloc.add(TaskDeleted(task));
    }
  }

  Future<void> _pickCustom() async {
    final platform = Theme.of(context).platform;
    final picked = platform == TargetPlatform.iOS
        ? await _pickCupertino()
        : await _pickMaterial();
    if (picked != null && mounted) {
      setState(() {
        _due = normalizeToMinute(picked);
        _preset = null;
      });
    }
  }

  Future<DateTime?> _pickMaterial() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_due),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<DateTime?> _pickCupertino() async {
    var value = _due;
    final use24h = MediaQuery.alwaysUse24HourFormatOf(context);
    final confirmed = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (popupContext) => Container(
        height: 320,
        color: CupertinoColors.systemBackground.resolveFrom(popupContext),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: CupertinoButton(
                  child: const Text('Done'),
                  onPressed: () => Navigator.of(popupContext).pop(true),
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  initialDateTime: _due,
                  use24hFormat: use24h,
                  onDateTimeChanged: (v) => value = v,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return confirmed == true ? value : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final presets = [
      for (final p in DuePreset.values)
        if (QuickDuePresets.isAvailable(p, now)) p,
    ];
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      child: LiquidGlassChrome(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        // Android 15+ is edge-to-edge: keep actions above the system nav
        // bar (paddingOf is 0 while the keyboard is open).
        padding: EdgeInsets.fromLTRB(
          20,
          10,
          20,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.25,
                      ),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: const SizedBox(width: 40, height: 4),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _isEdit ? 'Edit task' : 'New task',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                LiquidGlassTextField(
                  key: TaskEditorSheet.titleKey,
                  controller: _title,
                  label: 'Title',
                  autofocus: !_isEdit,
                  maxLength: 100,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.sentences,
                  validator: Validators.taskTitle,
                ),
                const SizedBox(height: 6),
                LiquidGlassTextField(
                  controller: _description,
                  label: 'Description (optional)',
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 500,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  validator: Validators.taskDescription,
                ),
                const SizedBox(height: 10),
                Text('Due', style: theme.textTheme.labelMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final p in presets)
                      SelectableChip(
                        key: ValueKey('preset-${p.name}'),
                        label: QuickDuePresets.label(p),
                        selected: _preset == p,
                        onSelected: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _preset = p;
                            _due = QuickDuePresets.resolve(p, now);
                          });
                        },
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.event_rounded, size: 18),
                      label: const Text('Custom…'),
                      onPressed: _pickCustom,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        DateFormat('EEEE, d MMM yyyy · h:mm a').format(_due),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Category', style: theme.textTheme.labelMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final c in TaskCategory.values)
                      SelectableChip(
                        key: ValueKey('editor-category-${c.name}'),
                        label: '${c.emoji} ${c.label}',
                        selected: _category == c,
                        onSelected: () {
                          HapticFeedback.selectionClick();
                          setState(() => _category = c);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Priority', style: theme.textTheme.labelMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final p in TaskPriority.values.reversed)
                      SelectableChip(
                        key: ValueKey('editor-priority-${p.name}'),
                        label: p.label,
                        dotColor: p.colorOf(context),
                        fill: p.colorOf(context),
                        selected: _priority == p,
                        onSelected: () {
                          HapticFeedback.selectionClick();
                          setState(() => _priority = p);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                LiquidGlassButton(
                  key: TaskEditorSheet.saveKey,
                  label: _isEdit ? 'Update Task' : 'Save Task',
                  icon: Icons.check_rounded,
                  onPressed: _canSave ? _save : null,
                ),
                if (_isEdit) ...[
                  const SizedBox(height: 6),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Delete task'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
