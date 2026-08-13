import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/access/repositories/access_repository.dart';
import 'package:printing/features/auth/models/auth_user.dart';

/// One employee, with the roles they hold.
class GetUser {
  const GetUser(this._repository);

  final AccessRepository _repository;

  Future<Either<Failure, AuthUser>> call(int userId) => _repository.user(userId);
}
