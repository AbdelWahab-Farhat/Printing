import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/access/repositories/access_repository.dart';
import 'package:printing/features/auth/models/auth_user.dart';

/// Stops an account or starts it again.
///
/// Its own use case rather than a flag on [UpdateUser], which is what makes it impossible for
/// saving an edit to let a stopped employee back in.
class SetUserActivation {
  const SetUserActivation(this._repository);

  final AccessRepository _repository;

  Future<Either<Failure, AuthUser>> call(int userId, {required bool isActive}) {
    return _repository.setUserActivation(userId, isActive: isActive);
  }
}
