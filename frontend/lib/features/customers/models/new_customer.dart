import 'package:freezed_annotation/freezed_annotation.dart';

part 'new_customer.freezed.dart';
part 'new_customer.g.dart';

/// A customer about to be created — what the form collected, in the shape the API accepts.
///
/// Separate from [Customer] because the two are genuinely different things: a `Customer` has an
/// id, the `code` the server allocated and timestamps, none of which exist yet. Filling a
/// half-empty `Customer` would leave every reader downstream wondering which of its fields are
/// real.
///
/// **`toJson` and no `fromJson`.** The app never parses one back — the server answers a create
/// with a real `Customer` — so a generated `fromJson` would be dead code. The body is generated
/// rather than assembled in the repository because `shops[]` as a hand-written `Map` literal is
/// only reachable through Dio, where here it is a pure function a test can assert on directly.
@Freezed(toJson: true, fromJson: false)
abstract class NewCustomer with _$NewCustomer {
  const factory NewCustomer({
    required String name,
    required String phone,

    /// The places this customer sells from.
    ///
    /// Omitted from the body entirely when empty rather than sent as `[]`: to this API an empty
    /// array is a *statement* ("this customer has no shops"), and on the update endpoint the
    /// same key means "delete the ones they had". Saying nothing is the honest thing for a form
    /// where the user simply did not add any.
    @JsonKey(includeIfNull: false) List<NewCustomerShop>? shops,
  }) = _NewCustomer;
}

/// One place a customer sells from.
///
/// All three of name, latitude and longitude are required by the API — a shop the delivery
/// driver cannot find is not worth recording — so they are non-nullable here and the form
/// refuses to submit an incomplete row.
@Freezed(toJson: true, fromJson: false)
abstract class NewCustomerShop with _$NewCustomerShop {
  const factory NewCustomerShop({
    /// The row this is, when it already exists.
    ///
    /// `SyncCustomerShops` on the server reads this: a shop carrying an id is **updated**, one
    /// without is **created**, and one the payload leaves out is **deleted**. So the form's
    /// add-and-remove behaviour already is the update semantics, with no second endpoint.
    ///
    /// `includeIfNull: false`, which is what makes one model serve both verbs: a create body is
    /// byte-identical to what it was before this field existed.
    @JsonKey(includeIfNull: false) int? id,

    required String name,

    /// Real numbers, not the text that was typed. `'٣٢٫٨'` from an Arabic keyboard is turned
    /// into `32.8` in [CreateCustomer] — the one place in this feature that converts anything —
    /// so the JSON carries `32.8` and not a string the API would have to coerce.
    required double latitude,
    required double longitude,

    /// A Facebook page, usually. Absent rather than null when the user left it blank: the API's
    /// rule is `nullable|url`, and an empty string is neither.
    @JsonKey(name: 'page_url', includeIfNull: false) String? pageUrl,
  }) = _NewCustomerShop;
}
