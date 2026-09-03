import 'package:freezed_annotation/freezed_annotation.dart';

part 'new_order.freezed.dart';
part 'new_order.g.dart';

/// An order about to be taken — what the form collected, in the shape the API accepts.
///
/// Separate from [Order] for the same reason [NewProduct] is separate from a product: an order
/// has a number, a status, a timeline and five computed totals, none of which exist yet. Making
/// the form fill a half-empty `Order` would leave every reader downstream guessing which of its
/// fields are real.
///
/// **No total is on it.** `items_total`, `delivery_price` and `grand_total` are derived by the
/// server — from the lines and from the destination city — and a client that could post them
/// could post any number it liked. The two money fields here are the two a *person* decides:
/// the design fee and the discount, and each is guarded on the server.
///
/// **The customer is set once and never changes.** `customer_id` is read on create and ignored
/// on update, because an order does not move between customers — which is exactly why this form
/// is opened from inside a customer rather than asking for one.
///
/// **`fromJson` is generated and never called — do not "tidy it away".** Without it the
/// generator stops treating the nested lines as serializable and emits Dart objects where the
/// wire needs maps; see the same note on [NewProduct].
@freezed
abstract class NewOrder with _$NewOrder {
  const factory NewOrder({
    @JsonKey(name: 'customer_id') required int customerId,
    @JsonKey(name: 'city_id') required int cityId,

    /// `none` · `customer` · `in_house`. Whose work the artwork was, which is the one thing
    /// about a design that may move money.
    @JsonKey(name: 'design_source') required String designSource,

    /// At least one, or the server refuses the order — `OrderNeedsAtLeastOneItem`.
    required List<NewOrderItem> items,

    /// Which of the customer's shops this is for. Omitted from the body when absent, because
    /// «this customer has no branch in it» is different from «null».
    @JsonKey(name: 'customer_shop_id', includeIfNull: false) int? customerShopId,

    /// Required by the *city*, not by this model: a city marked as needing one refuses an order
    /// without it, and the server's sentence says so.
    @JsonKey(name: 'region_id', includeIfNull: false) int? regionId,

    /// Only counted when [designSource] is `in_house`. Sent as a decimal string, never a number.
    @JsonKey(name: 'design_fee', includeIfNull: false) String? designFee,

    /// The artwork, chosen from the customer's library — ids, never files. Attached inside the
    /// same transaction that takes the order, so a design belonging to somebody else refuses
    /// the order rather than leaving one behind without the file it was taken for.
    ///
    /// Omitted when empty: «بدون تصميم» sends no key at all.
    @JsonKey(name: 'design_ids', includeIfNull: false) List<int>? designIds,

    /// Guarded by `orders.discount` on the server. The field is hidden in the app for staff
    /// without the grant; that is the suggestion, and the refusal is the rule.
    @JsonKey(includeIfNull: false) String? discount,

    /// Who will make it. **Required by the server for an order whose lines are all وسيط**, and
    /// refused as a 422 on `vendor_id` when missing — the road is read off the lines, so the app
    /// cannot be told by a field rule and has to look at the products itself. See
    /// `vendorRequirementFor`. Accepted on any order, so a mixed one may name one too.
    @JsonKey(name: 'vendor_id', includeIfNull: false) int? vendorId,

    @JsonKey(name: 'recipient_name', includeIfNull: false) String? recipientName,
    @JsonKey(name: 'recipient_phone', includeIfNull: false) String? recipientPhone,
    @JsonKey(name: 'address_details', includeIfNull: false) String? addressDetails,
    @JsonKey(includeIfNull: false) String? notes,
  }) = _NewOrder;

  factory NewOrder.fromJson(Map<String, dynamic> json) => _$NewOrderFromJson(json);
}

/// One line, before the server has priced it.
@freezed
abstract class NewOrderItem with _$NewOrderItem {
  const factory NewOrderItem({
    @JsonKey(name: 'product_id') required int productId,
    @JsonKey(name: 'product_variant_id') required int productVariantId,

    /// A decimal string, already in ASCII digits — `'300'`, not `'٣٠٠'`.
    required String quantity,

    /// **Honoured only for a product the catalogue prices «حسب الطلب»**, and ignored otherwise:
    /// for a listed product the catalogue's rate wins, which is what stops a posted number
    /// undercutting an agreed price. Omitted when the app has no business naming one.
    @JsonKey(name: 'unit_price', includeIfNull: false) String? unitPrice,

    @JsonKey(includeIfNull: false) String? notes,

    /// The order the clerk put the lines in, kept so the invoice reads the way it was written.
    @JsonKey(name: 'sort_order') @Default(0) int sortOrder,
  }) = _NewOrderItem;

  factory NewOrderItem.fromJson(Map<String, dynamic> json) => _$NewOrderItemFromJson(json);
}
