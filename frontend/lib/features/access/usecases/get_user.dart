import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/access/repositories/access_repository.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';

/// One employee, with the roles they hold.
class GetUser {
  const GetUser(this._repository);

  final AccessRepository _repository;

  Future<Either<Failure, AuthUser>> call(int userId) => _repository.user(userId);
}
