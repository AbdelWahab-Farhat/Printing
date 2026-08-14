import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/features/customers/models/customer.dart';
import 'package:dayaa/features/customers/models/new_customer.dart';
import 'package:dayaa/features/customers/repositories/customer_repository.dart';

/// One shop exactly as it was typed — the boxes of text, nothing converted yet.
///
/// A record rather than a model: it never leaves this feature, it is never serialised, and it
/// exists only to carry a form row from the screen to the line below that normalises it.
typedef ShopInput = ({
  /// Null for a row the user just added; the existing row's id when it came from the server.
  int? id,
  String name,

  /// المدينة والمنطقة, already ids: they come from pickers reading the delivery map, so unlike
  /// the boxes above there is no text here to normalise. The city is required by the form; the
  /// region is null whenever the city has no neighbourhoods or none was chosen.
  int cityId,
  int? regionId,

  String? pageUrl,

  /// مجال العمل as picked from the list, or null for a shop left unclassified. Already an id
  /// rather than text: it comes from a picker, not from a box somebody typed into.
  int? businessFieldId,
});

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
        shops: shops.isEmpty ? null : shops.map(toShop).toList(),
      ),
    );
  }

  /// A form row → what the API accepts.
  ///
  /// Less work than it used to be, and that is the point of the change: the place is two ids
  /// picked off the delivery map rather than two numbers somebody read off a map and typed, so
  /// there is nothing left here to parse — no Arabic-Indic digits, no decimal comma, no shop
  /// quietly saved at latitude zero because a comma was a full stop.
  ///
  /// Coordinates are not sent at all. Omitting them is what tells the server to keep the pin a
  /// shop already had; see `SyncCustomerShops`.
  static NewCustomerShop toShop(ShopInput shop) {
    final pageUrl = shop.pageUrl?.trim();

    return NewCustomerShop(
      id: shop.id,
      name: shop.name.trim(),
      cityId: shop.cityId,
      regionId: shop.regionId,
      pageUrl: pageUrl == null || pageUrl.isEmpty ? null : pageUrl,
      businessFieldId: shop.businessFieldId,
    );
  }
}
