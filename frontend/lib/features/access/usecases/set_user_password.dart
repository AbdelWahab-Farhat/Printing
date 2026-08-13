import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/access/repositories/access_repository.dart';
import 'package:printing/features/auth/models/auth_user.dart';

/// Sets a new password for a colleague who has forgotten theirs — administrators only.
///
/// **Not trimmed**, unlike every other field this app sends. A space is a character in a
/// password: trimming one would store something different from what was typed and confirmed,
/// and the employee would be locked out by their own manager's tidiness.
class SetUserPassword {
  const SetUserPassword(this._repository);

  final AccessRepository _repository;

  Future<Either<Failure, AuthUser>> call({required int userId, required String password}) {
    return _repository.setUserPassword(userId, password);
  }
}
