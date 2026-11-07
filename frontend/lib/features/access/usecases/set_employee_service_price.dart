import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/access/repositories/access_repository.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';

/// السعر المقترح لموظف في «خدمات الموظفين»، أو يمحوه.
class SetEmployeeServicePrice {
  const SetEmployeeServicePrice(this._repository);

  final AccessRepository _repository;

  Future<Either<Failure, AuthUser>> call({
    required int userId,
    required String service,
    required String? price,
  }) => _repository.setServicePrice(userId, service, price);
}
