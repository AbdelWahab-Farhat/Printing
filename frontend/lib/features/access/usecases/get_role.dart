import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/access/models/role.dart';
import 'package:dayaa/features/access/repositories/access_repository.dart';

/// One role, freshly read — what the screen after an edit shows.
class GetRole {
  const GetRole(this._repository);

  final AccessRepository _repository;

  Future<Either<Failure, Role>> call(int roleId) => _repository.role(roleId);
}
