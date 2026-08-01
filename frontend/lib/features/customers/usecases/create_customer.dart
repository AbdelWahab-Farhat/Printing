import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/utils/validators.dart';
import 'package:printing/features/customers/models/customer.dart';
import 'package:printing/features/customers/models/new_customer.dart';
import 'package:printing/features/customers/repositories/customer_repository.dart';

/// One shop exactly as it was typed — four boxes of text, nothing converted yet.
///
/// A record rather than a model: it never leaves this feature, it is never serialised, and it
/// exists only to carry a form row from the screen to the line below that normalises it.
typedef ShopInput = ({String name, String latitude, String longitude, String? pageUrl});

/// Register a new customer.
///
/// One verb, one `call` — and this one already earns its keep: it is where what the user typed
/// is turned into what the API accepts, once, instead of in every screen that ever creates a
/// customer. Nothing above it parses a number or trims a string.
class CreateCustomer {
  const CreateCustomer(this._repository);

  final CustomerRepository _repository;

  Future<Either<Failure, Customer>> call({
    required String name,
    required String phone,
    List<ShopInput> shops = const [],
  }) {
    return _repository.create(
      NewCustomer(
        // A name pasted out of a message carries whitespace, and the customer it creates is one
        // nobody finds again by searching for it.
        name: name.trim(),
        // ٠٩١٣٣٣٤٤٤٤ is what a Libyan keyboard produces. The API validates `^\d{9,15}$`, which
        // in PCRE without `/u` matches ASCII digits only — sending the Arabic-Indic form
        // untouched is a 422 the user has no way to diagnose from the field in front of them.
        phone: Validators.toWesternDigits(phone.trim()),
        // Absent, not `[]`, when the user added none: to this API an empty array is a statement
        // about the customer's shops rather than silence about them.
        shops: shops.isEmpty ? null : shops.map(_toShop).toList(),
      ),
    );
  }

  /// Text → the numbers the API wants.
  ///
  /// The same digit normalisation as the phone, plus the decimal comma an Arabic keyboard
  /// offers first: `'٣٢٫٨٨'` and `'32,88'` both have to reach the server as `32.88`, or the
  /// shop lands in the Gulf of Guinea — or, worse, is rejected with a message about a field the
  /// user filled in correctly as far as they can tell.
  ///
  /// `double.parse` and not `tryParse`: the form's validators have already refused anything
  /// unparseable, so a failure here is a bug in this app, and it should be loud rather than a
  /// shop quietly saved at latitude zero.
  NewCustomerShop _toShop(ShopInput shop) {
    final pageUrl = shop.pageUrl?.trim();

    return NewCustomerShop(
      name: shop.name.trim(),
      latitude: double.parse(_toDecimal(shop.latitude)),
      longitude: double.parse(_toDecimal(shop.longitude)),
      pageUrl: pageUrl == null || pageUrl.isEmpty ? null : pageUrl,
    );
  }

  String _toDecimal(String input) =>
      Validators.toWesternDigits(input.trim()).replaceAll(',', '.');
}
