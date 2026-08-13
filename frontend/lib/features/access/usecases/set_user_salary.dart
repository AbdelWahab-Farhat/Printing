import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/access/repositories/access_repository.dart';
import 'package:printing/features/auth/models/auth_user.dart';

/// Sets what an employee is paid a month, or clears it back to «لم يُحدَّد».
///
/// An empty box means *cleared*, not «send an empty string»: the endpoint takes a number or a
/// null, and `''` would come back as a 422 about a field the user left deliberately blank.
class SetUserSalary {
  const SetUserSalary(this._repository);

  final AccessRepository _repository;

  Future<Either<Failure, AuthUser>> call({required int userId, required String? salary}) {
    final trimmed = salary?.trim();

    return _repository.setUserSalary(
      userId,
      trimmed == null || trimmed.isEmpty ? null : trimmed,
    );
  }
}
