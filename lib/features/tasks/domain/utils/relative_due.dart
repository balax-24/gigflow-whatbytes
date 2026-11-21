/// Human, glanceable due labels for gig workers ("in 45m", "2h overdue").
enum DueUrgency { overdue, soon, later }

final class RelativeDue {
  const RelativeDue(this.label, this.urgency);

  final String label;
  final DueUrgency urgency;

  /// Returns null for completed tasks or anything more than 7 days away
  /// (the absolute date chip already covers those).
  static RelativeDue? of(DateTime due, DateTime now, {bool completed = false}) {
    if (completed) return null;
    final diff = due.difference(now);
    if (diff.isNegative) {
      return RelativeDue('${_span(-diff)} overdue', DueUrgency.overdue);
    }
    if (diff.inMinutes < 1) {
      return const RelativeDue('Due now', DueUrgency.soon);
    }
    if (diff.inDays >= 7) return null;
    return RelativeDue(
      'in ${_span(diff)}',
      diff.inHours < 2 ? DueUrgency.soon : DueUrgency.later,
    );
  }

  static String _span(Duration d) {
    if (d.inMinutes < 60) return '${d.inMinutes < 1 ? 1 : d.inMinutes}m';
    if (d.inHours < 24) {
      final m = d.inMinutes % 60;
      return m == 0 || d.inHours >= 6 ? '${d.inHours}h' : '${d.inHours}h ${m}m';
    }
    return '${d.inDays}d';
  }
}

/// Time-of-day greeting with a light emoji touch.
String greetingFor(DateTime now) {
  final h = now.hour;
  if (h >= 5 && h < 12) return 'Good morning ☀️';
  if (h >= 12 && h < 17) return 'Good afternoon 🌤️';
  if (h >= 17 && h < 22) return 'Good evening 🌆';
  return 'Late shift 🌙';
}
