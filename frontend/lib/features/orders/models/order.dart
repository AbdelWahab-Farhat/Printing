import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/customers/models/customer.dart';
import 'package:dayaa/features/customers/models/customer_design.dart';
import 'package:dayaa/features/orders/models/additional_cost_reason.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/models/transition_field.dart';
import 'package:dayaa/features/products/models/product.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

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

    /// The Arabic for the road this order walks — «المسار المعتاد» أو «بدون تصميم وطباعة».
    ///
    /// **Carried so a short progress bar can be explained rather than look truncated.** An order
    /// made entirely of ready-made goods has five steps where every other order has seven, and a
    /// bar that simply drew two fewer boxes would read as a rendering fault. The rules
    /// themselves are not here and never should be: `availableTransitions` and `progress` arrive
    /// already resolved, and which orders take the short road is read off their lines by the
    /// server — see `ResolveOrderFlow`.
    ///
    /// The label rather than the wire value, for the reason [statusLabel] gives: a road this
    /// build has never heard of still reads correctly.
    @JsonKey(name: 'production_flow_label') @Default('') String productionFlowLabel,

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

    /// A charge added to the order that no line on it describes — «تغليف خاص»، «نقل».
    ///
    /// **Beside the discount and never folded into it.** A total is read as «هذا ما أُضيف وهذا
    /// ما خُصم», and one net figure explains neither. `'0.00'` when nothing is charged, and
    /// defaulted for the reason [paidAmount] is: an order from a server that predates the
    /// column was never charged, and zero is exactly what such a server means.
    @JsonKey(name: 'additional_cost') @Default('0.00') String additionalCost,

    /// Which of the five categories it was booked under. Null on an order with no charge.
    ///
    /// `unknownEnumValue` rather than a `String`, now that the sheet draws all five: a sixth
    /// category added on the server after this build shipped parses as
    /// [AdditionalCostReason.unknown] and the order still prints the label the server sent
    /// beside it, instead of failing to parse at all.
    @JsonKey(name: 'additional_cost_reason', unknownEnumValue: AdditionalCostReason.unknown)
    AdditionalCostReason? additionalCostReason,

    /// The server's own Arabic for that category — «تغليف خاص». Rendered as-is, never mapped
    /// from the code here: a second copy of that list is the one that drifts.
    @JsonKey(name: 'additional_cost_reason_label') String? additionalCostReasonLabel,

    /// What was actually done, in the clerk's words. The detail, never the classification.
    @JsonKey(name: 'additional_cost_note') String? additionalCostNote,

    @JsonKey(name: 'grand_total') required String grandTotal,

    /// **The numbers the screen puts side by side**, every one the server's arithmetic —
    /// including the subtraction. `remainingAmount` is not `grandTotal - paidAmount` computed
    /// here: that would be a second answer to one question, and this one is made of doubles.
    ///
    /// `paidAmount` is the sum of the order's ledger. It is the *entries* that are the truth;
    /// this is what they add up to, which is why nothing in the app ever writes it.
    ///
    /// Defaulted so an order fetched from a build of the API that predates payments still
    /// parses — the honest value for it is zero.
    @JsonKey(name: 'paid_amount') @Default('0.00') String paidAmount,

    /// What was closed without being collected — the difference somebody decided not to chase.
    ///
    /// **Beside `paidAmount`, never inside it**, so that number goes on meaning cash. Defaulted
    /// for the same reason its neighbour is: an order from a server that predates write-offs has
    /// had nothing written off, and zero is exactly what such a server means.
    @JsonKey(name: 'written_off_amount') @Default('0.00') String writtenOffAmount,

    /// What the customer paid **to the courier** for delivery, remitted to the carrier rather
    /// than to us.
    ///
    /// **Never part of any cash total, and that is the whole reason it is its own column.** It
    /// never reached the drawer, so adding it to `paidAmount` would put money in «كم قبضنا
    /// اليوم؟» that went into a courier's pocket. It is here because without it the payments
    /// card is arithmetic that does not add up: an order of 120 showing 100 paid and nothing
    /// outstanding reads as a bug.
    ///
    /// Defaulted like its two neighbours: an order from a server that predates the carrier
    /// integration had nothing settled at one, and zero is what such a server means.
    @JsonKey(name: 'carrier_settled_amount') @Default('0.00') String carrierSettledAmount,

    /// What is still owed — the invoice less what was collected **and** what was forgiven.
    /// **Negative on an overpaid order**, so «زائد ٥٠» can be said rather than floored away.
    @JsonKey(name: 'remaining_amount') @Default('0.00') String remainingAmount,

    @JsonKey(name: 'payment_status', unknownEnumValue: PaymentStatus.unknown)
    @Default(PaymentStatus.unpaid)
    PaymentStatus paymentStatus,

    @JsonKey(name: 'payment_status_label') @Default('') String paymentStatusLabel,

    /// An order that finished without its money accounted for.
    ///
    /// Settling writes no ledger entry — nothing records a payment except the person who took
    /// it — so this is the gap being surfaced rather than papered over with an entry nobody
    /// made. The screen warns; somebody records what was collected; the warning goes.
    @JsonKey(name: 'has_unrecorded_money') @Default(false) bool hasUnrecordedMoney,

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

    /// The carrier's own code for the parcel this order went out in — «كود النورس».
    ///
    /// **Not [trackingNumber], and never a substitute for it.** That one is a box somebody types
    /// into; this one is what Nawris called the parcel, and it is the number said out loud when
    /// a customer rings about a delivery. Null on every order that never went to a carrier, and
    /// on one whose parcel is still waiting for its code — the server omits the key rather than
    /// sending an empty one, so null here means «no code», never «code unknown».
    @JsonKey(name: 'nawris_parcel') NawrisParcelRef? nawrisParcel,
    /// The number the man holding the parcel can be reached on — what «جاري التوصيل» asks for
    /// and what `OrderResource` publishes. It was read from `courier_name`, a key the server has
    /// never sent, so it parsed as null on every order ever fetched.
    @JsonKey(name: 'courier_phone') String? courierPhone,

    @JsonKey(name: 'cancellation_reason') String? cancellationReason,

    /// Where «تراجع عن الإلغاء» would put this order back, or null when the undo is not on
    /// offer at all — the order is not cancelled, this user lacks the grant, or the server
    /// cannot tell what it was cancelled from.
    ///
    /// **A status rather than a flag, because the button names its destination.** The undo has
    /// nothing to choose: the server reads the order's own timeline and puts it back exactly
    /// where the cancellation took it from, so the screen's job is to say where that is before
    /// somebody taps rather than after. Sent only with a single order, never on a list — see
    /// `OrderResource` for why the list does not pay for the timeline read.
    @JsonKey(name: 'reinstate_to', unknownEnumValue: OrderStatus.unknown)
    OrderStatus? reinstateTo,

    /// The Arabic the server chose for [reinstateTo]. Rendered as-is, for the reason
    /// [statusLabel] gives: a status this build has never heard of still reads correctly.
    @JsonKey(name: 'reinstate_to_label') String? reinstateToLabel,

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

    /// Whether where it is going may still be changed.
    ///
    /// **A third line, later than both of the others.** The lines close when the bags exist and
    /// the artwork closes when the press starts, but an address stays correctable right up to
    /// the moment somebody is driving to it — «جاري التوصيل» is the one open status that
    /// refuses, because there the label has already left and only the label is real.
    @JsonKey(name: 'destination_is_editable') @Default(false) bool destinationIsEditable,

    /// Present on the list endpoint.
    @JsonKey(name: 'items_count') int? itemsCount,

    /// Present when one order was fetched.
    List<OrderItem>? items,
    List<OrderDesign>? designs,
    List<OrderTransitionRecord>? transitions,

    /// What this order cost to produce, and what is left of the invoice after it.
    ///
    /// **Both null until the order has reached «جاهزة»** — nothing is costed before stock
    /// leaves a shelf, and «لم يُحتسب بعد» is not «صفر». [grossProfit] is derived by the server
    /// from the two figures beside it and never stored, so the app reads it rather than
    /// subtracting: which total the margin is taken against is a rule, and rules live in one
    /// place.
    @JsonKey(name: 'total_cogs') String? totalCogs,
    @JsonKey(name: 'gross_profit') String? grossProfit,

    /// Which shelf this run came off, and when — both null until the order reaches «جاهزة», and
    /// never rewritten after. That is later than it used to be, and deliberately: an order's
    /// lines are frozen by «جاهزة» but still editable through «قيد الطباعة», so stock now leaves
    /// the warehouse against quantities nobody can still change underneath it.
    @JsonKey(name: 'fulfillment_warehouse_id') int? fulfillmentWarehouseId,
    @JsonKey(name: 'stock_deducted_at') DateTime? stockDeductedAt,

    /// Who is making it, for an order a vendor executes. Null on everything we make ourselves.
    @JsonKey(name: 'vendor_id') int? vendorId,

    /// The vendor's name **as this order said it**, snapshotted the way [cityName] is. A vendor
    /// renamed since keeps its new name everywhere except here, which is the point of storing
    /// it — show this, never a lookup.
    @JsonKey(name: 'vendor_name') String? vendorName,

    /// When the job went out to the vendor. Null until it does, and forever on an order that
    /// never walks the وسيط road.
    @JsonKey(name: 'manufacturing_started_at') DateTime? manufacturingStartedAt,

    /// What the parcel weighs, in kilograms — the lines' own scale readings added up by the
    /// server.
    ///
    /// **The order has no weight of its own any more.** It once carried a `weight_kg` somebody
    /// typed on the way into «جاهزة»; nothing was computed from it and it could disagree with the
    /// lines under it, so it went. This is built back out of what the warehouse actually
    /// recorded per line.
    ///
    /// **Null is «لا يوجد وزن», never «صفر»** — and it covers two cases the screen does not need
    /// to tell apart: nothing on the order comes off a shelf counted by the kilo, or something
    /// does and it has not been weighed yet. Either way there is no weight to print, and a
    /// half-summed one under «الوزن» would be read as the whole parcel's.
    ///
    /// **Sent on the list as well as the detail**, so [OrderCard] states it beside the money
    /// without opening the order. It was absent from the list once, when weighing a page meant
    /// fetching the lines an order at a time; the list eager-loads the shelf behind each line
    /// now and the figure costs it nothing.
    @JsonKey(name: 'total_weight') String? totalWeight,

    @JsonKey(name: 'placed_at') DateTime? placedAt,
    @JsonKey(name: 'delivered_at') DateTime? deliveredAt,
    @JsonKey(name: 'settled_at') DateTime? settledAt,
    @JsonKey(name: 'created_at') DateTime? createdAt,

    /// Who took the order. Null on the list — the server sends it with the full order only —
    /// and for an order raised by a seeder or a console command.
    ///
    /// Read by «ملاحظات الطلبية»: the order's own note is the one note with no transition
    /// behind it, and this is the closest thing anybody recorded about who wrote it.
    @JsonKey(name: 'created_by') OrderActor? createdBy,
  }) = _Order;

  const Order._();

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

  /// Whether anything at all can be done to this order right now.
  ///
  /// Read from the server's own list rather than from [isFinal]: a user may be looking at an
  /// open order and hold none of its permissions, and «لا توجد إجراءات» is the honest thing to
  /// say to them.
  bool get hasActions => availableTransitions.isNotEmpty;

  /// Whether this screen may offer to undo the cancellation.
  ///
  /// Read from the server's own answer rather than from [isFinal] and a permission check here,
  /// exactly as [hasActions] is: the three conditions — cancelled, granted, and a timeline that
  /// records where it was cancelled from — are the server's, and a copy of them in Dart is the
  /// copy that drifts.
  bool get canReinstate => reinstateTo != null;

  /// Whether «تعديل النواقص» has anything to do on this order right now.
  ///
  /// **Only while the order is standing in «نواقص»**, which is the status the sheet exists for:
  /// the job is parked because the stock is not there, and the number is argued about until it
  /// is. Every other status has its own way of asking — leaving «نواقص» asks what arrived, and
  /// entering it asks what is short — so an arm on the dial elsewhere would be a third door to
  /// a room with two.
  bool get shortagesAreEditable => status == OrderStatus.shortage;

  /// Whether anything is still owed on this order.
  ///
  /// Read from [paymentStatus] rather than by comparing the two money strings: they are decimal
  /// text on purpose, and a `double.parse` here to answer a yes/no question would be the one
  /// place in the app that turned money into floating point.
  bool get isOutstanding =>
      paymentStatus == PaymentStatus.unpaid || paymentStatus == PaymentStatus.partiallyPaid;

  /// A discount worth showing a line for. `'0.00'` is not one.
  bool get hasDiscount => discount != '0.00';

  /// A charge worth showing a line for. `'0.00'` is not one.
  bool get hasAdditionalCost => additionalCost != '0.00';

  /// What the charge was for, as one line — «تغليف خاص — علبة كرتون مزدوجة».
  ///
  /// **Assembled here rather than at each of the three places that show it.** The order screen,
  /// the PDF and the WhatsApp message all print this charge; each one deciding for itself how a
  /// category and a note go together is how «تغليف خاص» ends up on the invoice and «علبة كرتون
  /// مزدوجة» in the message for the same order.
  ///
  /// **Under «أخرى» the note stands alone**, because the word names no category to anybody
  /// reading it — and the server guarantees the note is there, since that is the one reason it
  /// refuses without one.
  String? get additionalCostCaption {
    if (!hasAdditionalCost) return null;

    final note = additionalCostNote?.trim();
    final hasNote = note != null && note.isNotEmpty;
    final label = additionalCostReasonLabel;

    if (additionalCostReason?.needsNote ?? false) return hasNote ? note : label;
    if (label == null) return hasNote ? note : null;

    return hasNote ? '$label — $note' : label;
  }

  /// The weight as one line — «12.5 كيلوغرام» — or null on an order with none to state.
  ///
  /// Trimmed like every other quantity the app draws: the three decimals are the column's
  /// padding, not a precision anybody weighed to. See [totalWeight] for what null means.
  String? get weightLabel =>
      totalWeight == null ? null : '${groupedDecimal(totalWeight!)} كيلوغرام';

  /// Only charged when we did the design, so the server sends `'0.00'` otherwise.
  bool get hasDesignFee => designFee != '0.00';

  /// A delivery that was actually charged for. An office pickup is `'0.00'`, and so is a
  /// delivery we did not bill — neither is a line on the customer's copy.
  bool get hasDeliveryPrice => deliveryPrice != '0.00';

  /// The name to put on the delivery line — the recipient when there is one, else the customer.
  String? get recipient => recipientName ?? customer?.name;

  /// Where it goes, as one line: «طرابلس — سوق الجمعة».
  String get destination => regionName == null ? cityName : '$cityName — $regionName';

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

    // Past a week «منذ» stops helping — nobody counts in twelfths of a month — so the date
    // itself takes over, in the one shape this app writes dates in.
    return at.dayLabel;
  }
}

/// Where the order is along the route it is meant to take.
///
/// **The order of [steps] is the server's, not this app's.** Which status follows which is the
/// one thing this app deliberately keeps no copy of — the same reason the action buttons are
/// drawn from `available_transitions`. A stepper built from a hard-coded list in Dart would be
/// the second copy that drifts.
/// What the carrier calls this order's parcel.
@freezed
abstract class NawrisParcelRef with _$NawrisParcelRef {
  const factory NawrisParcelRef({
    /// Their handle on the parcel, and what a customer is read over the phone.
    required String code,

    /// What is physically scanned at handover. Rarely shown; kept because it is the one
    /// identifier that survives a resend announced under a code nobody has seen.
    @JsonKey(name: 'bar_code') String? barCode,

    /// Whether it is still out there — read off `closed_at`, not off a status list.
    @JsonKey(name: 'is_open') @Default(false) bool isOpen,
  }) = _NawrisParcelRef;

  factory NawrisParcelRef.fromJson(Map<String, dynamic> json) => _$NawrisParcelRefFromJson(json);
}

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

  factory OrderTransition.fromJson(Map<String, dynamic> json) => _$OrderTransitionFromJson(json);
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

    /// The live catalogue row behind the line, for the card that opens it.
    ///
    /// **Both null on a list payload**, which carries the lines without their products, and on a
    /// server too old to send them — so the card falls back to the snapshot above and stops
    /// advertising a picture it does not have. Never mistaken for the snapshot: a product
    /// renamed or rephotographed since shows its new face here while the invoice keeps saying
    /// what was sold.
    @JsonKey(name: 'product_code') String? productCode,
    @JsonKey(name: 'product_image') ProductImage? productImage,
    @JsonKey(name: 'pricing_unit_label') required String pricingUnitLabel,
    required String quantity,

    /// What is missing from this line, in this line's own unit. Null until somebody has counted
    /// — which is not the same as nothing being missing.
    @JsonKey(name: 'shortage_quantity') String? shortageQuantity,

    /// What the line is actually charged for: [quantity] less [shortageQuantity].
    ///
    /// Sent by the server rather than subtracted here, because which quantity an invoice is
    /// built on is a rule and rules live in one place. Null only from a server too old to send
    /// it — see [pricedQuantity].
    @JsonKey(name: 'billable_quantity') String? billableQuantity,

    /// How much of the warehouse's own unit this line takes off the shelf.
    ///
    /// **Null is the ordinary case and means «نفس وحدة البيع»** — the press deducts [quantity]
    /// unchanged. A value here is the exception the scale creates: forty bags sold by the piece
    /// may weigh ten kilos together, and the shelf is counted in kilos. It is the total for the
    /// whole line, read off a scale, not a per-piece factor — a batch is weighed together, not
    /// counted.
    @JsonKey(name: 'warehouse_quantity') String? warehouseQuantity,

    @JsonKey(name: 'unit_price') required String unitPrice,
    @JsonKey(name: 'line_total') required String lineTotal,

    /// The accrual side of [lineTotal]: what this line cost to make, split three ways and
    /// summed. **All four null until the line has reached «جاهزة»** — a line nobody has
    /// finished has no cost, which is not a cost of zero.
    @JsonKey(name: 'material_cost') String? materialCost,
    @JsonKey(name: 'labor_cost') String? laborCost,
    @JsonKey(name: 'overhead_cost') String? overheadCost,

    /// The three above, added up by the server. Read rather than summed here for the same reason
    /// [billableQuantity] is.
    String? cogs,

    /// The rate behind [materialCost]: what one unit off the shelf cost us.
    ///
    /// **Divided by the server, not here.** `1234.56 / 3` in Dart is `411.51999999999998`, and
    /// every other figure on this screen is a string the server chose the decimals of. Null
    /// whenever [materialCost] is.
    @JsonKey(name: 'unit_material_cost') String? unitMaterialCost,

    /// The unit [unitMaterialCost] is *per* — **the warehouse's, which need not be the one the
    /// line was sold in.** 300 bags weighed 12.5 kilos onto the order cost what those kilos
    /// cost, and «تكلفة القطعة» printed over a per-kilo rate is a wrong number, not a rounded
    /// one. Null on a payload that carries no shelf — a list, or a server too old to send it —
    /// in which case there is no per-unit figure to label either.
    @JsonKey(name: 'stock_unit_label') String? stockUnitLabel,

    /// The copy of the size's «سعر التكلفة» taken the day this order was made — what makes a
    /// later change to the catalogue leave this order alone. Null on every line we make
    /// ourselves, and **absent** for anybody without `products.view_cost`, so the screen gates
    /// on the grant rather than on the null.
    @JsonKey(name: 'unit_cost') String? unitCost,

    /// What the line cost in total, written when the vendor handed the job over («جاهزة»). Null
    /// before that: a price agreed with a vendor is not a cost incurred. Folded into [cogs] by
    /// the server, so it is read here and never added in again.
    @JsonKey(name: 'outsourcing_cost') String? outsourcingCost,

    String? notes,
  }) = _OrderItem;

  const OrderItem._();

  factory OrderItem.fromJson(Map<String, dynamic> json) => _$OrderItemFromJson(json);

  /// Whether part of this line failed to turn up.
  ///
  /// A recorded zero is not a shortage. The server clears one to null, but a zero typed into the
  /// sheet is on screen before the round trip is — and a red «ناقص ٠» is a warning about nothing,
  /// which teaches people to stop reading warnings.
  bool get hasShortage {
    final missing = double.tryParse(shortageQuantity ?? '') ?? 0;

    return missing > 0;
  }

  /// The number the line is priced on, which is what an invoice is read for.
  ///
  /// Falls back to [quantity] rather than to zero when the server did not send a billable
  /// figure: that is a server that was charging for the whole line, and guessing otherwise would
  /// draw a free order.
  String get pricedQuantity => billableQuantity ?? quantity;
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

/// The member of staff behind a move.
///
/// Two fields, because two is what the timeline shows and what the API sends beside each
/// transition. Deliberately not the app's full user model: this is a name on a log line, not an
/// account somebody is about to edit, and pulling in the larger model would make the timeline
/// depend on the access feature to render a word.
@freezed
abstract class OrderActor with _$OrderActor {
  const factory OrderActor({required int id, required String name}) = _OrderActor;

  factory OrderActor.fromJson(Map<String, dynamic> json) => _$OrderActorFromJson(json);
}

/// One move the order actually made — a row on its timeline.
@freezed
abstract class OrderTransitionRecord with _$OrderTransitionRecord {
  const factory OrderTransitionRecord({
    required int id,

    /// Null exactly once per order: the row that records it being taken.
    @JsonKey(name: 'from_status_label') String? fromStatusLabel,

    /// Where the order landed, as a code — so a row can wear the status's own colour and glyph.
    ///
    /// The label beside it is what gets *printed*; this is only ever asked for the legend, and
    /// it falls back to [OrderStatus.unknown] — a status added on the server after this build
    /// shipped still reads correctly in neutral rather than failing to parse the whole order.
    @JsonKey(name: 'to_status', unknownEnumValue: OrderStatus.unknown)
    @Default(OrderStatus.unknown)
    OrderStatus toStatus,

    @JsonKey(name: 'to_status_label') required String toStatusLabel,

    /// What was typed when the order was moved — «العميل غيّر رأيه», «ناقص ٤٠ كيس».
    ///
    /// This is the note of a *status*, which is what «ملاحظات الطلبية» is a page of: the order's
    /// own note says what the job is, and each of these says what happened at one step of it.
    String? reason,

    /// Who moved it. Null for a move made by a console command or a seeder — the column is
    /// nullable for exactly that — and for a build of the API that did not load the relation.
    ///
    /// It is the other half of [reason]: «تم الإلغاء — العميل غيّر رأيه» is a different fact
    /// from the same sentence with a name against it, and the name is what makes the timeline
    /// answerable rather than merely readable.
    OrderActor? user,

    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _OrderTransitionRecord;

  const OrderTransitionRecord._();

  factory OrderTransitionRecord.fromJson(Map<String, dynamic> json) =>
      _$OrderTransitionRecordFromJson(json);

  bool get isOpening => fromStatusLabel == null;
}
