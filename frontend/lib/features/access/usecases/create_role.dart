import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/access/models/role.dart';
import 'package:printing/features/access/repositories/access_repository.dart';

/// Creates a role from a machine name and a set of permissions.
class CreateRole {
  const CreateRole(this._repository);

  final AccessRepository _repository;

  Future<Either<Failure, Role>> call({
    required String name,
    List<String> permissions = const [],
  }) {
    return _repository.createRole(name: name, permissions: permissions);
  }
}
