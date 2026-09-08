import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/shipping_companies/models/shipping_company.dart';
import 'package:dayaa/features/shipping_companies/repositories/shipping_company_repository.dart';

/// Adds a carrier, or corrects one.
///
/// **One use case for both, because the form is one form.** The screen that adds a company and
/// the screen that edits one differ only in whether an id came with them, and splitting this in
/// two would mean trimming the same three fields in two places.
class SaveShippingCompany {
  const SaveShippingCompany(this._repository);

  final ShippingCompanyRepository _repository;

  /// [id] null adds; anything else corrects that company. [isDefault] null says nothing about
  /// which company a dispatch opens on, and the server leaves that where it is.
  Future<Either<Failure, ShippingCompany>> call({
    int? id,
    required String name,
    String? phone,
    String? notes,
    bool isActive = true,
    bool? isDefault,
  }) {
    final trimmedName = name.trim();
    final trimmedPhone = _blankToNull(phone);
    final trimmedNotes = _blankToNull(notes);

    if (id == null) {
      return _repository.create(
        name: trimmedName,
        phone: trimmedPhone,
        notes: trimmedNotes,
        isActive: isActive,
        isDefault: isDefault,
      );
    }

    return _repository.update(
      id,
      name: trimmedName,
      phone: trimmedPhone,
      notes: trimmedNotes,
      isActive: isActive,
      isDefault: isDefault,
    );
  }

  /// An empty box means "there is no number", not "the number is an empty string".
  static String? _blankToNull(String? input) {
    final trimmed = input?.trim();

    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
