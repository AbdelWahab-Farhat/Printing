import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/access/repositories/access_repository.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';

/// «راتب تلقائي» — whether the monthly run posts this employee's salary into their wallet.
/// EMPLOYEE-WALLET-DESIGN §١٤.
class SetUserAutoSalary {
  const SetUserAutoSalary(this._repository);

  final AccessRepository _repository;

  Future<Either<Failure, AuthUser>> call({required int userId, required bool on}) =>
      _repository.setUserAutoSalary(userId, on: on);
}
