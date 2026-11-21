abstract final class Validators {
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  static final _letter = RegExp('[A-Za-z]');
  static final _digit = RegExp('[0-9]');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required.';
    if (!_email.hasMatch(v)) return 'Please enter a valid email address.';
    return null;
  }

  /// Login: only non-empty (never block existing accounts).
  static String? loginPassword(String? value) =>
      (value == null || value.isEmpty) ? 'Password is required.' : null;

  /// Register: >= 6 chars (Firebase floor) + one letter and one digit.
  static String? newPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required.';
    if (v.length < 6) return 'Use at least 6 characters.';
    if (!_letter.hasMatch(v) || !_digit.hasMatch(v)) {
      return 'Include at least one letter and one number.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Please confirm your password.';
    return value != original ? 'Passwords do not match.' : null;
  }

  static String? taskTitle(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Title is required.';
    if (v.length > 100) return 'Keep the title under 100 characters.';
    return null;
  }

  static String? taskDescription(String? value) =>
      (value?.trim().length ?? 0) > 500
      ? 'Keep the description under 500 characters.'
      : null;
}
