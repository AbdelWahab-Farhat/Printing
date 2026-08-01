import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/utils/validators.dart';
import 'package:printing/features/customers/models/customer.dart';
import 'package:printing/features/customers/repositories/customer_repository.dart';

/// Register a new customer.
///
/// One verb, one `call` — and this one already earns its keep: it is where what the user typed
/// is turned into what the API accepts, once, instead of in every screen that ever creates a
/// customer.
class CreateCustomer {
  const CreateCustomer(this._repository);

  final CustomerRepository _repository;

  Future<Either<Failure, Customer>> call({
    required String name,
    required String phone,
  }) {
    return _repository.create(
      // A name pasted out of a message carries whitespace, and the customer it creates is one
      // nobody finds again by searching for it.
      name: name.trim(),
      // ٠٩١٣٣٣٤٤٤٤ is what a Libyan keyboard produces. The API validates `^\d{9,15}$`, which
      // in PCRE without `/u` matches ASCII digits only — sending the Arabic-Indic form
      // untouched is a 422 the user has no way to diagnose from the field in front of them.
      phone: Validators.toWesternDigits(phone.trim()),
    );
  }
}
