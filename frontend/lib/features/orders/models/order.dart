import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:printing/features/customers/models/customer.dart';
import 'package:printing/features/orders/models/order_status.dart';

part 'order.freezed.dart';
part 'order.g.dart';

/// A job of work: bags printed for a customer and got to them.
///
/// **Every money field is a `String`.** `'330.00'` as the server sent it — a `double` stops
/// being the number the catalogue printed the moment it is parsed, and these are added together.
///
/// **The address fields are the order's own snapshot, not the live map.** `cityName` is what the
/// order said on the day; renaming the city later must not rewrite it. That is why this model
/// has a `cityName` at all instead of a nested `City`.
@freezed
abstract class Order with _$Order {
  const factory Order({
    required int id,

    /// Plain digits — `'7'`. Said out loud on the phone, so it carries no letter prefix the
    /// way a customer's `C7` or a product's `P7` does.
    required String code,

    @JsonKey(unknownEnumValue: OrderStatus.unknown) required OrderStatus status,

    /// The Arabic the server chose. Rendered as-is, so a status this build does not know still
    /// reads correctly — see [OrderStatus.unknown].
    @JsonKey(name: 'status_label') required String statusLabel,
    @JsonKey(name: 'is_final') required bool isFinal,

    /// The moves this order may make, **already narrowed to what the signed-in user may do.**
    /// The screen draws exactly these buttons and no others, which is what stops it offering an
    /// action the server would refuse.
    @JsonKey(name: 'available_transitions')
    @Default(<OrderTransition>[])
    List<OrderTransition> availableTransitions,

    @JsonKey(name: 'customer_id') required int customerId,
    @JsonKey(name: 'city_name') required String cityName,
    @JsonKey(name: 'fulfilment_type_label') required String fulfilmentTypeLabel,
    @JsonKey(name: 'is_office_pickup') required bool isOfficePickup,
    @JsonKey(name: 'design_source_label') required String designSourceLabel,

    @JsonKey(name: 'items_total') required String itemsTotal,
    @JsonKey(name: 'design_fee') required String designFee,
    @JsonKey(name: 'delivery_price') required String deliveryPrice,
    required String discount,
    @JsonKey(name: 'grand_total') required String grandTotal,

    Customer? customer,
    @JsonKey(name: 'region_name') String? regionName,

    /// The branch, snapshotted like the city — a customer renaming one must not rewrite where
    /// an old order said it was going.
    @JsonKey(name: 'customer_shop_name') String? customerShopName,
    @JsonKey(name: 'recipient_name') String? recipientName,
    @JsonKey(name: 'recipient_phone') String? recipientPhone,
    @JsonKey(name: 'address_details') String? addressDetails,
    String? notes,

    @JsonKey(name: 'shipping_company') String? shippingCompany,
    @JsonKey(name: 'tracking_number') String? trackingNumber,
    @JsonKey(name: 'courier_name') String? courierName,

    @JsonKey(name: 'cancellation_reason') String? cancellationReason,

    @JsonKey(name: 'items_are_editable') @Default(false) bool itemsAreEditable,

    /// Present on the list endpoint.
    @JsonKey(name: 'items_count') int? itemsCount,

    /// Present when one order was fetched.
    List<OrderItem>? items,
    List<OrderDesign>? designs,
    List<OrderTransitionRecord>? transitions,

    @JsonKey(name: 'placed_at') DateTime? placedAt,
    @JsonKey(name: 'delivered_at') DateTime? deliveredAt,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Order;

  const Order._();

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

  /// Whether anything at all can be done to this order right now.
  ///
  /// Read from the server's own list rather than from [isFinal]: a user may be looking at an
  /// open order and hold none of its permissions, and «لا توجد إجراءات» is the honest thing to
  /// say to them.
  bool get hasActions => availableTransitions.isNotEmpty;

  /// A discount worth showing a line for. `'0.00'` is not one.
  bool get hasDiscount => discount != '0.00';

  /// Only charged when we did the design, so the server sends `'0.00'` otherwise.
  bool get hasDesignFee => designFee != '0.00';

  /// The name to put on the delivery line — the recipient when there is one, else the customer.
  String? get recipient => recipientName ?? customer?.name;

  /// Where it goes, as one line: «طرابلس — سوق الجمعة».
  String get destination =>
      regionName == null ? cityName : '$cityName — $regionName';
}

/// One move the order may make next, as the server offers it.
@freezed
abstract class OrderTransition with _$OrderTransition {
  const factory OrderTransition({
    @JsonKey(unknownEnumValue: OrderStatus.unknown) required OrderStatus status,
    required String label,

    /// Cancelling is the only one today. The screen asks for the sentence *before* sending, so
    /// the server's 422 for a missing reason is a case the user never reaches.
    @JsonKey(name: 'requires_reason') @Default(false) bool requiresReason,
  }) = _OrderTransition;

  const OrderTransition._();

  factory OrderTransition.fromJson(Map<String, dynamic> json) =>
      _$OrderTransitionFromJson(json);
}

/// One line of an order, priced at what it cost on the day.
@freezed
abstract class OrderItem with _$OrderItem {
  const factory OrderItem({
    required int id,

    /// The snapshot, not the catalogue. A product renamed since must not rewrite this invoice.
    @JsonKey(name: 'product_name') required String productName,
    @JsonKey(name: 'variant_label') required String variantLabel,
    @JsonKey(name: 'pricing_unit_label') required String pricingUnitLabel,
    required String quantity,
    @JsonKey(name: 'unit_price') required String unitPrice,
    @JsonKey(name: 'line_total') required String lineTotal,
    String? notes,
  }) = _OrderItem;

  const OrderItem._();

  factory OrderItem.fromJson(Map<String, dynamic> json) => _$OrderItemFromJson(json);
}

/// One version of the artwork, and what the customer said about it.
@freezed
abstract class OrderDesign with _$OrderDesign {
  const factory OrderDesign({
    required int id,
    required int version,
    required String status,
    @JsonKey(name: 'status_label') required String statusLabel,
    @JsonKey(name: 'is_reviewed') @Default(false) bool isReviewed,
    @JsonKey(name: 'rejection_reason') String? rejectionReason,
    String? notes,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _OrderDesign;

  const OrderDesign._();

  factory OrderDesign.fromJson(Map<String, dynamic> json) => _$OrderDesignFromJson(json);

  bool get isApproved => status == 'approved';

  bool get isRejected => status == 'rejected';
}

/// One move the order actually made — a row on its timeline.
@freezed
abstract class OrderTransitionRecord with _$OrderTransitionRecord {
  const factory OrderTransitionRecord({
    required int id,

    /// Null exactly once per order: the row that records it being taken.
    @JsonKey(name: 'from_status_label') String? fromStatusLabel,
    @JsonKey(name: 'to_status_label') required String toStatusLabel,
    String? reason,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _OrderTransitionRecord;

  const OrderTransitionRecord._();

  factory OrderTransitionRecord.fromJson(Map<String, dynamic> json) =>
      _$OrderTransitionRecordFromJson(json);

  bool get isOpening => fromStatusLabel == null;
}
