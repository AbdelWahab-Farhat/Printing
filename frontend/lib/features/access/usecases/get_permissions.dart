import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/access/models/role.dart';
import 'package:dayaa/features/access/repositories/access_repository.dart';

/// The catalogue of everything the system can check for, in the server's own sections.
///
/// Fetched rather than read off `AppPermission`, even though that enum carries the same names
/// and labels: the *grouping* is the server's, and a build whose catalogue is behind the API
/// should show the new permission it cannot name rather than silently omit it.
class GetPermissions {
  const GetPermissions(this._repository);

  final AccessRepository _repository;

  Future<Either<Failure, List<PermissionGroup>>> call() => _repository.permissions();
}
