import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:printing/features/customers/models/customer.dart';
import 'package:printing/features/customers/models/customer_design.dart';
import 'package:printing/features/orders/models/order_status.dart';
import 'package:printing/features/orders/models/transition_field.dart';

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

    /// Whether the order is finished — no move of any kind is left.
    ///
    /// **Not the same as [isClosed], and «تم الاستلام» is why.** The customer has the bags, so
    /// nothing about the order may be edited; but the money it went out to collect has not been
    /// agreed yet, so it still has one move to make.
    @JsonKey(name: 'is_final') required bool isFinal,

    /// Whether the order itself is closed to editing.
    @JsonKey(name: 'is_closed') @Default(false) bool isClosed,

    /// The moves this order may make, **already narrowed to what the signed-in user may do.**
    /// The screen draws exactly these buttons and no others, which is what stops it offering an
    /// action the server would refuse.
    @JsonKey(name: 'available_transitions')
    @Default(<OrderTransition>[])
    List<OrderTransition> availableTransitions,

    @JsonKey(name: 'customer_id') required int customerId,
    @JsonKey(name: 'city_id') required int cityId,
    @JsonKey(name: 'design_source') required String designSource,
    @JsonKey(name: 'city_name') required String cityName,
    @JsonKey(name: 'fulfilment_type_label') required String fulfilmentTypeLabel,
    @JsonKey(name: 'is_office_pickup') required bool isOfficePickup,
    @JsonKey(name: 'design_source_label') required String designSourceLabel,

    @JsonKey(name: 'items_total') required String itemsTotal,
    @JsonKey(name: 'design_fee') required String designFee,
    @JsonKey(name: 'delivery_price') required String deliveryPrice,
    required String discount,
    @JsonKey(name: 'grand_total') required String grandTotal,

    /// What the parcel weighs, in kilograms, recorded on the way into «جاهزة».
    ///
    /// Null until it has been on a scale — «not weighed» and «weighs nothing» are different
    /// facts, and only one of them means somebody has done the work.
    @JsonKey(name: 'weight_kg') String? weightKg,

    /// What actually came back for the order, when it was not what the invoice said.
    ///
    /// Null on every settlement that went to plan, deliberately: a number here always means the
    /// two disagreed.
    @JsonKey(name: 'collected_amount') String? collectedAmount,

    Customer? customer,
    @JsonKey(name: 'region_id') int? regionId,
    @JsonKey(name: 'customer_shop_id') int? customerShopId,
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

    /// The journey, in the domain's own order — see [OrderProgress].
    @Default(OrderProgress.unknown) OrderProgress progress,

    /// Whether the quantities may still be corrected. Open while the press is running — that is
    /// exactly when a customer rings and asks for five hundred instead of three — and closed
    /// from «جاهزة» onwards, when the bags exist and are counted.
    @JsonKey(name: 'items_are_editable') @Default(false) bool itemsAreEditable,

    /// Whether another version of the artwork may be attached.
    ///
    /// **A different line from [itemsAreEditable], and the app keeps no copy of either.** The
    /// press runs against an approved file, so the artwork settles when printing starts;
    /// changing it means sending the order back to «قيد التصميم», which is a move somebody
    /// makes on purpose.
    @JsonKey(name: 'designs_are_editable') @Default(false) bool designsAreEditable,

    /// Present on the list endpoint.
    @JsonKey(name: 'items_count') int? itemsCount,

    /// Present when one order was fetched.
    List<OrderItem>? items,
    List<OrderDesign>? designs,
    List<OrderTransitionRecord>? transitions,

    @JsonKey(name: 'placed_at') DateTime? placedAt,
    @JsonKey(name: 'delivered_at') DateTime? deliveredAt,
    @JsonKey(name: 'settled_at') DateTime? settledAt,
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

  /// How long ago the order was taken, in words.
  ///
  /// **Coarse on purpose.** A work queue is read for "is this today's or last week's", and a
  /// card that said «منذ ٤٧ دقيقة» would be asking the reader to do arithmetic to answer that.
  /// Anything past a week gives the date instead, because "منذ ٢٣ يوماً" is a number nobody
  /// converts back into a day.
  ///
  /// Computed here rather than sent by the server: it changes every minute the screen is open,
  /// and a string baked at request time would be wrong before it was read.
  String get placedAgo {
    final at = (placedAt ?? createdAt)?.toLocal();
    if (at == null) return '';

    final elapsed = DateTime.now().difference(at);

    if (elapsed.isNegative || elapsed.inMinutes < 1) return 'الآن';
    if (elapsed.inMinutes < 60) return 'منذ ${elapsed.inMinutes} دقيقة';
    if (elapsed.inHours < 24) return 'منذ ${elapsed.inHours} ساعة';
    if (elapsed.inDays == 1) return 'أمس';
    if (elapsed.inDays < 7) return 'قبل ${elapsed.inDays} أيام';

    String two(int value) => value.toString().padLeft(2, '0');

    return '${at.year}-${two(at.month)}-${two(at.day)}';
  }
}

/// Where the order is along the route it is meant to take.
///
/// **The order of [steps] is the server's, not this app's.** Which status follows which is the
/// one thing this app deliberately keeps no copy of — the same reason the action buttons are
/// drawn from `available_transitions`. A stepper built from a hard-coded list in Dart would be
/// the second copy that drifts.
@freezed
abstract class OrderProgress with _$OrderProgress {
  const factory OrderProgress({
    @Default(<OrderStep>[]) List<OrderStep> steps,

    /// The order is somewhere real that is not on the route — a shortage, a return, a
    /// cancellation. The bar shows how far it got and stops claiming it is *on* the line.
    @JsonKey(name: 'is_detour') @Default(false) bool isDetour,
  }) = _OrderProgress;

  const OrderProgress._();

  /// Before the order has loaded, and for the list endpoint where the bar is not drawn.
  static const OrderProgress unknown = OrderProgress();

  factory OrderProgress.fromJson(Map<String, dynamic> json) => _$OrderProgressFromJson(json);

  bool get isEmpty => steps.isEmpty;
}

/// One stop on the route.
@freezed
abstract class OrderStep with _$OrderStep {
  const factory OrderStep({
    required String status,
    required String label,

    /// `done`, `current` or `upcoming`. A string rather than an enum: it is drawn, never
    /// branched on for business meaning, and a fourth state added on the server should render
    /// as neutral rather than fail to parse the order.
    required String state,
  }) = _OrderStep;

  const OrderStep._();

  factory OrderStep.fromJson(Map<String, dynamic> json) => _$OrderStepFromJson(json);

  bool get isDone => state == 'done';

  bool get isCurrent => state == 'current';
}

/// One move the order may make next, as the server offers it.
@freezed
abstract class OrderTransition with _$OrderTransition {
  const factory OrderTransition({
    @JsonKey(unknownEnumValue: OrderStatus.unknown) required OrderStatus status,
    required String label,

    /// Cancelling is the only one today. Kept beside [fields], which now carries the reason as
    /// a field of its own — this stays for the clients written before that existed.
    @JsonKey(name: 'requires_reason') @Default(false) bool requiresReason,

    /// What this move asks for, written by the server for *this* order.
    ///
    /// An order with no design step is asked for no artwork; one that already carries a version
    /// is offered another rather than made to supply one. The screen renders these and keeps no
    /// list of its own — see [TransitionField].
    @Default(<TransitionField>[]) List<TransitionField> fields,
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

    @JsonKey(name: 'product_id') required int productId,
    @JsonKey(name: 'product_variant_id') required int productVariantId,

    /// The snapshot, not the catalogue. A product renamed since must not rewrite this invoice.
    @JsonKey(name: 'product_name') required String productName,
    @JsonKey(name: 'variant_label') required String variantLabel,
    @JsonKey(name: 'pricing_unit_label') required String pricingUnitLabel,
    required String quantity,

    /// What is missing from this line, in this line's own unit. Null until somebody has counted
    /// — which is not the same as nothing being missing.
    @JsonKey(name: 'shortage_quantity') String? shortageQuantity,

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

    /// The file this version points at, from the customer's library.
    ///
    /// Pointed at, never copied — so what is shown here is the same row the library shows, and
    /// `file_url` is the signed link the server minted for *this* request. Absent when the
    /// endpoint did not load the relation.
    CustomerDesign? design,

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
