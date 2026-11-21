sealed class Failure implements Exception {
  const Failure(this.message, {this.code});
  final String message;
  final String? code;

  @override
  String toString() => '$runtimeType($code): $message';
}

final class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

final class TaskFailure extends Failure {
  const TaskFailure(super.message, {super.code});
}
