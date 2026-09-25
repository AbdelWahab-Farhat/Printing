import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/auth/models/customer_account.dart';
import 'package:dayaa_client/features/auth/repositories/auth_repository.dart';

/// Create an account.
///
/// **The verb the staff app has no equivalent of.** An employee is created for them by an
/// administrator; a customer signs themselves up, which is the whole reason this app has a
/// registration screen at all.
class Register {
  const Register(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, AuthSession>> call({
    required String name,
    required String phone,
    required String password,
  }) {
    return _repository.register(
      name: name.trim(),
      phone: phone.trim(),
      password: password,
    );
  }
}
