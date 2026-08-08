import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/utils/validators.dart';
import 'package:printing/features/vendors/models/vendor.dart';
import 'package:printing/features/vendors/repositories/vendor_repository.dart';

/// Adds a supplier, or corrects one.
///
/// **One use case for both, because the form is one form.** The screen that adds a vendor and
/// the screen that edits one differ only in whether an id came with them.
///
/// **It does not carry `is_active`, and that is the contract rather than an omission.** The API
/// refuses to change it here — switching a supplier off is its own endpoint, so that "I edited
/// their phone number" and "I stopped dealing with them" can never be the same request. See
/// [SetVendorActive].
class SaveVendor {
  const SaveVendor(this._repository);

  final VendorRepository _repository;

  /// [id] null adds; anything else corrects that vendor.
  Future<Either<Failure, Vendor>> call({
    int? id,
    required String name,
    required String phone,
    String? contactPerson,
    String? email,
    String? address,
  }) {
    // The server's rule is `regex:/^\d{9,15}$/` — ASCII digits only. A Libyan keyboard produces
    // «٠٩١…», which is not a digit as far as that regex is concerned, and the 422 it earns
    // points at a field the user filled in correctly. Converted once, here.
    final digits = Validators.toWesternDigits(phone.trim());

    final name0 = name.trim();
    final contact = _blankToNull(contactPerson);
    final email0 = _blankToNull(email);
    final address0 = _blankToNull(address);

    if (id == null) {
      return _repository.create(
        name: name0,
        phone: digits,
        contactPerson: contact,
        email: email0,
        address: address0,
      );
    }

    return _repository.update(
      id,
      name: name0,
      phone: digits,
      contactPerson: contact,
      email: email0,
      address: address0,
    );
  }

  /// An empty box means "nothing recorded", which the API spells `null`. An empty string would
  /// be a value — a contact person whose name is blank.
  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();

    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}

/// Stops offering a supplier, or brings one back.
///
/// Its own class because it is its own endpoint, and its own decision: a vendor is never
/// deleted — the purchase orders and the shipments that name them have to keep resolving.
class SetVendorActive {
  const SetVendorActive(this._repository);

  final VendorRepository _repository;

  Future<Either<Failure, Vendor>> call(int vendorId, {required bool isActive}) =>
      _repository.setActive(vendorId, isActive);
}
