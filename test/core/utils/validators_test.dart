import 'package:flutter_test/flutter_test.dart';
import 'package:gigflow/core/utils/validators.dart';

void main() {
  group('email', () {
    test('rejects empty and malformed', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('   '), isNotNull);
      expect(Validators.email('bad@'), isNotNull);
      expect(Validators.email('a@b'), isNotNull);
    });
    test('accepts trimmed valid email', () {
      expect(Validators.email('  rider@gig.dev '), isNull);
    });
  });

  group('passwords', () {
    test('login only requires non-empty', () {
      expect(Validators.loginPassword(''), isNotNull);
      expect(Validators.loginPassword('x'), isNull);
    });
    test('new password needs 6 chars, letter and digit', () {
      expect(Validators.newPassword('abc1'), isNotNull);
      expect(Validators.newPassword('abcdef'), isNotNull);
      expect(Validators.newPassword('123456'), isNotNull);
      expect(Validators.newPassword('abc123'), isNull);
    });
    test('confirm must match', () {
      expect(Validators.confirmPassword('', 'abc123'), isNotNull);
      expect(Validators.confirmPassword('abc124', 'abc123'), isNotNull);
      expect(Validators.confirmPassword('abc123', 'abc123'), isNull);
    });
  });

  group('task fields', () {
    test('title required and max 100', () {
      expect(Validators.taskTitle('  '), isNotNull);
      expect(Validators.taskTitle('a' * 101), isNotNull);
      expect(Validators.taskTitle('Deliver #1'), isNull);
    });
    test('description max 500', () {
      expect(Validators.taskDescription('a' * 501), isNotNull);
      expect(Validators.taskDescription(''), isNull);
    });
  });
}
