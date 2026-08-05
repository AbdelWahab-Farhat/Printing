import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/business_fields/models/business_field.dart';
import 'package:printing/features/business_fields/repositories/business_field_repository.dart';

/// Stops offering a trade, or offers it again.
///
/// The ordinary way to retire one. It leaves the pickers; every shop already recorded under it
/// keeps saying so, which is why this and not a delete is what the list's switch does.
class SetBusinessFieldActivation {
  const SetBusinessFieldActivation(this._repository);

  final BusinessFieldRepository _repository;

  Future<Either<Failure, BusinessField>> call(int fieldId, {required bool isActive}) =>
      _repository.setActivation(fieldId, isActive: isActive);
}
