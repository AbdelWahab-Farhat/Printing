import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/access/repositories/access_repository.dart';

/// Removes a role the code does not reference and nobody currently holds.
///
/// Both refusals come back as the server's own Arabic, which says which of the two it was —
/// so the screen never has to guess why.
class DeleteRole {
  const DeleteRole(this._repository);

  final AccessRepository _repository;

  Future<Either<Failure, String>> call(int roleId) => _repository.deleteRole(roleId);
}
