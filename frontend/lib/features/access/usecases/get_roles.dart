import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/access/models/role.dart';
import 'package:dayaa/features/access/repositories/access_repository.dart';

/// Every role, with its permissions and how many people hold it.
class GetRoles {
  const GetRoles(this._repository);

  final AccessRepository _repository;

  Future<Either<Failure, List<Role>>> call() => _repository.roles();
}
