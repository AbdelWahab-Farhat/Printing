import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/auth/models/customer_account.dart';
import 'package:dayaa_client/features/auth/repositories/auth_repository.dart';

/// Sign in with a phone number and password.
///
/// One verb, one `call`. It looks thin next to the repository today, and that is the point — it
/// is where a rule lands when one appears, in a single testable class rather than copied into
/// every Cubit that signs somebody in.
class Login {
  const Login(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, AuthSession>> call({
    required String phone,
    required String password,
  }) {
    // Trimmed here rather than in the Cubit: a trailing space pasted into the phone field is a
    // failed sign-in whose cause the customer cannot see, and every caller would otherwise have
    // to remember to do this.
    return _repository.login(phone: phone.trim(), password: password);
  }
}
