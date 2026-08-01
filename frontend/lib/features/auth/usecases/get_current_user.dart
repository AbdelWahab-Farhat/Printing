import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/auth/models/auth_user.dart';
import 'package:printing/features/auth/repositories/auth_repository.dart';

/// Who is signed in, according to the server.
///
/// Asked rather than remembered from the login response: a name, a role or an employee code can
/// change between one launch and the next, and a card showing the identity from three weeks ago
/// is a card nobody can trust.
class GetCurrentUser {
  const GetCurrentUser(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, AuthUser>> call() => _repository.currentUser();
}
