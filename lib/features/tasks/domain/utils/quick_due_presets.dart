enum DuePreset { inOneHour, today6pm, tomorrow9am }

abstract final class QuickDuePresets {
  static String label(DuePreset p) => switch (p) {
    DuePreset.inOneHour => '+1 hr',
    DuePreset.today6pm => 'Today 6 PM',
    DuePreset.tomorrow9am => 'Tomorrow 9 AM',
  };

  /// "Today 6 PM" is unavailable once it is 6 PM or later.
  static bool isAvailable(DuePreset p, DateTime now) =>
      p != DuePreset.today6pm ||
      now.isBefore(DateTime(now.year, now.month, now.day, 18));

  static DateTime resolve(DuePreset p, DateTime now) => switch (p) {
    DuePreset.inOneHour => DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    ).add(const Duration(hours: 1)),
    DuePreset.today6pm => DateTime(now.year, now.month, now.day, 18),
    DuePreset.tomorrow9am => DateTime(now.year, now.month, now.day + 1, 9),
  };
}
