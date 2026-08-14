import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/auth/repositories/auth_repository.dart';

/// Ends this device's session.
///
/// The token is cleared from the device whatever the server answers — see the implementation.
/// A `Left` here therefore means "the server was not told", never "you are still signed in".
class Logout {
  const Logout(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, Unit>> call() => _repository.logout();
}
