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
