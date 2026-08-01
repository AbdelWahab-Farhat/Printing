import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/utils/validators.dart';
import 'package:printing/features/customers/models/customer.dart';
import 'package:printing/features/customers/models/new_customer.dart';
import 'package:printing/features/customers/repositories/customer_repository.dart';
import 'package:printing/features/customers/usecases/create_customer.dart';

/// Save changes to a customer.
///
/// It shares [CreateCustomer]'s mapper, because what the user typed has to be turned into what
/// the API accepts in exactly the same way on both verbs — Arabic-Indic digits, the Arabic
/// decimal mark, trimmed whitespace. Two copies of that would drift, and the drift would show
/// up as a shop saved at latitude zero on one screen and not the other.
///
/// **One rule differs, and getting it wrong loses data.** Creating with no shops sends no
/// `shops` key at all, because silence honestly means "the user added none". On an update the
/// same silence means "leave the shops alone" — so a customer whose three shops were all
/// deleted in the form would have them quietly kept. Here the list is *always* sent, and an
/// empty one genuinely means remove them all.
class UpdateCustomer {
  const UpdateCustomer(this._repository);

  final CustomerRepository _repository;

  Future<Either<Failure, Customer>> call({
    required int customerId,
    required String name,
    required String phone,
    List<ShopInput> shops = const [],
  }) {
    return _repository.update(
      customerId,
      NewCustomer(
        name: name.trim(),
        phone: Validators.toWesternDigits(phone.trim()),
        // Always present, even when empty — see the note above. This is the single line that
        // separates "the user removed every shop" from "the user did not mention shops".
        shops: shops.map(CreateCustomer.toShop).toList(),
      ),
    );
  }
}
