enum TaskStatusFilter {
  all,
  incomplete,
  completed;

  String get label => switch (this) {
    TaskStatusFilter.all => 'All',
    TaskStatusFilter.incomplete => 'Incomplete',
    TaskStatusFilter.completed => 'Completed',
  };
}
