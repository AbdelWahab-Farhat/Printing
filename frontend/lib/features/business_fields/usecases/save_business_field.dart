import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/business_fields/models/business_field.dart';
import 'package:printing/features/business_fields/repositories/business_field_repository.dart';

/// Adds a trade to the list, or edits one that is already on it.
///
/// One use case for both, because the rule they share is the one worth stating: the name is
/// trimmed before it travels. A trailing space makes «شحن» and «شحن » two rows the server would
/// accept and nobody could tell apart on screen.
class SaveBusinessField {
  const SaveBusinessField(this._repository);

  final BusinessFieldRepository _repository;

  Future<Either<Failure, BusinessField>> call({
    int? fieldId,
    required String name,
    int sortOrder = 0,
    bool isActive = true,
  }) {
    final trimmed = name.trim();

    return fieldId == null
        ? _repository.create(name: trimmed, sortOrder: sortOrder)
        : _repository.update(fieldId, name: trimmed, sortOrder: sortOrder, isActive: isActive);
  }
}
