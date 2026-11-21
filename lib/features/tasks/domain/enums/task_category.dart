/// Gig-worker task categories, shown as emoji tags.
enum TaskCategory {
  delivery,
  ride,
  errand,
  work,
  personal,
  general;

  String get label => switch (this) {
    TaskCategory.delivery => 'Delivery',
    TaskCategory.ride => 'Ride',
    TaskCategory.errand => 'Errand',
    TaskCategory.work => 'Work',
    TaskCategory.personal => 'Personal',
    TaskCategory.general => 'General',
  };

  String get emoji => switch (this) {
    TaskCategory.delivery => '📦',
    TaskCategory.ride => '🚗',
    TaskCategory.errand => '🛒',
    TaskCategory.work => '💼',
    TaskCategory.personal => '🏠',
    TaskCategory.general => '✨',
  };

  /// Tasks created before categories existed parse as [general].
  static TaskCategory fromName(String? name) =>
      TaskCategory.values.asNameMap()[name] ?? TaskCategory.general;
}
