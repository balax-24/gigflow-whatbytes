import 'package:flutter_test/flutter_test.dart';
import 'package:gigflow/features/tasks/domain/enums/task_priority.dart';
import 'package:gigflow/features/tasks/domain/utils/quick_due_presets.dart';
import 'package:gigflow/features/tasks/domain/utils/shift_stats.dart';

import '../../../helpers/test_data.dart';

void main() {
  group('ShiftStats', () {
    test('empty list -> zero progress', () {
      final s = ShiftStats.compute([], testNow);
      expect(s, ShiftStats.empty);
      expect(s.progress, 0);
    });

    test('counts today window, overdue and open high', () {
      final s = ShiftStats.compute([
        makeTask(
          id: '1',
          due: DateTime(2026, 11, 22),
          done: true,
        ), // today 00:00
        makeTask(id: '2', due: DateTime(2026, 11, 22, 23, 59)), // today
        makeTask(id: '3', due: DateTime(2026, 11, 23)), // tomorrow
        makeTask(id: '4', due: DateTime(2026, 11, 21, 9)), // overdue
        makeTask(
          id: '5',
          due: DateTime(2026, 11, 21, 8),
          done: true,
          priority: TaskPriority.high,
        ), // completed overdue -> not counted
        makeTask(id: '6', priority: TaskPriority.high), // open high
      ], testNow);
      expect(s.todayTotal, 3); // 1, 2, 6 (testNow+2h)
      expect(s.todayDone, 1);
      expect(s.overdue, 1); // only #4 (open & past); #1/#5 are completed
      expect(s.highOpen, 1);
    });
  });

  group('QuickDuePresets', () {
    test('Today 6 PM availability boundary', () {
      expect(
        QuickDuePresets.isAvailable(
          DuePreset.today6pm,
          DateTime(2026, 11, 22, 17, 59),
        ),
        isTrue,
      );
      expect(
        QuickDuePresets.isAvailable(
          DuePreset.today6pm,
          DateTime(2026, 11, 22, 18),
        ),
        isFalse,
      );
      expect(
        QuickDuePresets.isAvailable(
          DuePreset.inOneHour,
          DateTime(2026, 11, 22, 23),
        ),
        isTrue,
      );
    });

    test('tomorrow 9 AM rolls over year end', () {
      expect(
        QuickDuePresets.resolve(
          DuePreset.tomorrow9am,
          DateTime(2026, 12, 31, 22),
        ),
        DateTime(2027, 1, 1, 9),
      );
    });

    test('+1 hr is minute-normalised', () {
      expect(
        QuickDuePresets.resolve(
          DuePreset.inOneHour,
          DateTime(2026, 11, 22, 10, 15, 42),
        ),
        DateTime(2026, 11, 22, 11, 15),
      );
    });
  });
}
