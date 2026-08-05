import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/business_fields/repositories/business_field_repository.dart';

/// Removes a trade from the list for good.
///
/// **Only for a row that should never have existed** — a typo, a duplicate. The server refuses
/// with 422 the moment any shop is recorded under it, and says so in Arabic; the screen shows
/// that message rather than deciding for itself what may be deleted.
class DeleteBusinessField {
  const DeleteBusinessField(this._repository);

  final BusinessFieldRepository _repository;

  Future<Either<Failure, String>> call(int fieldId) => _repository.delete(fieldId);
}
