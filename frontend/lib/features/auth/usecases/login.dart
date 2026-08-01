import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/auth/models/auth_user.dart';
import 'package:printing/features/auth/repositories/auth_repository.dart';

/// Sign in with a phone number and password.
///
/// One verb, one `call`. It looks thin next to the repository today, and that is the point —
/// it is where a rule lands when one appears ("a deactivated account may not sign in"), in a
/// single testable class rather than copied into every Cubit that logs somebody in.
class Login {
  const Login(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, AuthSession>> call({
    required String phone,
    required String password,
  }) {
    // Trimmed here rather than in the Cubit: a trailing space pasted into the phone field is
    // a failed login the user cannot see the cause of, and every caller would otherwise have
    // to remember to do this.
    return _repository.login(phone: phone.trim(), password: password);
  }
}
