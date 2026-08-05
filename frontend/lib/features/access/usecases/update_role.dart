import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/access/models/role.dart';
import 'package:printing/features/access/repositories/access_repository.dart';

/// Renames a role, and optionally replaces what it grants.
///
/// `permissions: null` is not "grant nothing" — it is "leave the set exactly as it is", which
/// is what the administrator's role needs: it can be looked at and never re-permissioned.
class UpdateRole {
  const UpdateRole(this._repository);

  final AccessRepository _repository;

  Future<Either<Failure, Role>> call({
    required int roleId,
    required String name,
    List<String>? permissions,
  }) {
    return _repository.updateRole(roleId: roleId, name: name, permissions: permissions);
  }
}
