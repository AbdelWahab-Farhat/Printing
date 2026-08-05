import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/access/repositories/access_repository.dart';
import 'package:printing/features/auth/models/auth_user.dart';

/// Registers a colleague: the account, and the jobs it starts with.
///
/// The roles ride along with the create rather than following it, so there is no window in which
/// an account exists that can sign in and do nothing — and no second request to fail on its own
/// and leave somebody to notice.
class CreateUser {
  const CreateUser(this._repository);

  final AccessRepository _repository;

  Future<Either<Failure, AuthUser>> call({
    required String name,
    required String email,
    required String phone,
    required String password,
    List<String> roleNames = const [],
  }) {
    return _repository.createUser(
      name: name,
      email: email,
      phone: phone,
      password: password,
      roleNames: roleNames,
    );
  }
}
