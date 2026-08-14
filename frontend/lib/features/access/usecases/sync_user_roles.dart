import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/access/repositories/access_repository.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';

/// Sets which jobs somebody holds — the only thing this app changes about an account.
///
/// The whole set goes at once, so what the screen sends is what the person ends up with.
class SyncUserRoles {
  const SyncUserRoles(this._repository);

  final AccessRepository _repository;

  Future<Either<Failure, AuthUser>> call({
    required int userId,
    required List<String> roleNames,
  }) {
    return _repository.syncUserRoles(userId, roleNames);
  }
}
