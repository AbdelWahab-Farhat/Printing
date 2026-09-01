// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Order {

 int get id;/// Plain digits — `'7'`. Said out loud on the phone, so it carries no letter prefix the
/// way a customer's `C7` or a product's `P7` does.
 String get code;@JsonKey(unknownEnumValue: OrderStatus.unknown) OrderStatus get status;/// The Arabic the server chose. Rendered as-is, so a status this build does not know still
/// reads correctly — see [OrderStatus.unknown].
@JsonKey(name: 'status_label') String get statusLabel;/// The Arabic for the road this order walks — «المسار المعتاد» أو «بدون تصميم وطباعة».
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
@JsonKey(name: 'production_flow_label') String get productionFlowLabel;/// Whether the order is finished — no move of any kind is left.
///
/// **Not the same as [isClosed], and «تم الاستلام» is why.** The customer has the bags, so
/// nothing about the order may be edited; but the money it went out to collect has not been
/// agreed yet, so it still has one move to make.
@JsonKey(name: 'is_final') bool get isFinal;/// Whether the order itself is closed to editing.
@JsonKey(name: 'is_closed') bool get isClosed;/// The moves this order may make, **already narrowed to what the signed-in user may do.**
/// The screen draws exactly these buttons and no others, which is what stops it offering an
/// action the server would refuse.
@JsonKey(name: 'available_transitions') List<OrderTransition> get availableTransitions;@JsonKey(name: 'customer_id') int get customerId;@JsonKey(name: 'city_id') int get cityId;@JsonKey(name: 'design_source') String get designSource;@JsonKey(name: 'city_name') String get cityName;@JsonKey(name: 'fulfilment_type_label') String get fulfilmentTypeLabel;@JsonKey(name: 'is_office_pickup') bool get isOfficePickup;@JsonKey(name: 'design_source_label') String get designSourceLabel;@JsonKey(name: 'items_total') String get itemsTotal;@JsonKey(name: 'design_fee') String get designFee;@JsonKey(name: 'delivery_price') String get deliveryPrice; String get discount;/// A charge added to the order that no line on it describes — «تغليف خاص»، «نقل».
///
/// **Beside the discount and never folded into it.** A total is read as «هذا ما أُضيف وهذا
/// ما خُصم», and one net figure explains neither. `'0.00'` when nothing is charged, and
/// defaulted for the reason [paidAmount] is: an order from a server that predates the
/// column was never charged, and zero is exactly what such a server means.
@JsonKey(name: 'additional_cost') String get additionalCost;/// Which of the five categories it was booked under. Null on an order with no charge.
///
/// `unknownEnumValue` rather than a `String`, now that the sheet draws all five: a sixth
/// category added on the server after this build shipped parses as
/// [AdditionalCostReason.unknown] and the order still prints the label the server sent
/// beside it, instead of failing to parse at all.
@JsonKey(name: 'additional_cost_reason', unknownEnumValue: AdditionalCostReason.unknown) AdditionalCostReason? get additionalCostReason;/// The server's own Arabic for that category — «تغليف خاص». Rendered as-is, never mapped
/// from the code here: a second copy of that list is the one that drifts.
@JsonKey(name: 'additional_cost_reason_label') String? get additionalCostReasonLabel;/// What was actually done, in the clerk's words. The detail, never the classification.
@JsonKey(name: 'additional_cost_note') String? get additionalCostNote;@JsonKey(name: 'grand_total') String get grandTotal;/// **The numbers the screen puts side by side**, every one the server's arithmetic —
/// including the subtraction. `remainingAmount` is not `grandTotal - paidAmount` computed
/// here: that would be a second answer to one question, and this one is made of doubles.
///
/// `paidAmount` is the sum of the order's ledger. It is the *entries* that are the truth;
/// this is what they add up to, which is why nothing in the app ever writes it.
///
/// Defaulted so an order fetched from a build of the API that predates payments still
/// parses — the honest value for it is zero.
@JsonKey(name: 'paid_amount') String get paidAmount;/// What was closed without being collected — the difference somebody decided not to chase.
///
/// **Beside `paidAmount`, never inside it**, so that number goes on meaning cash. Defaulted
/// for the same reason its neighbour is: an order from a server that predates write-offs has
/// had nothing written off, and zero is exactly what such a server means.
@JsonKey(name: 'written_off_amount') String get writtenOffAmount;/// What is still owed — the invoice less what was collected **and** what was forgiven.
/// **Negative on an overpaid order**, so «زائد ٥٠» can be said rather than floored away.
@JsonKey(name: 'remaining_amount') String get remainingAmount;@JsonKey(name: 'payment_status', unknownEnumValue: PaymentStatus.unknown) PaymentStatus get paymentStatus;@JsonKey(name: 'payment_status_label') String get paymentStatusLabel;/// An order that finished without its money accounted for.
///
/// Settling writes no ledger entry — nothing records a payment except the person who took
/// it — so this is the gap being surfaced rather than papered over with an entry nobody
/// made. The screen warns; somebody records what was collected; the warning goes.
@JsonKey(name: 'has_unrecorded_money') bool get hasUnrecordedMoney;/// What actually came back for the order, when it was not what the invoice said.
///
/// Null on every settlement that went to plan, deliberately: a number here always means the
/// two disagreed.
@JsonKey(name: 'collected_amount') String? get collectedAmount; Customer? get customer;@JsonKey(name: 'region_id') int? get regionId;@JsonKey(name: 'customer_shop_id') int? get customerShopId;@JsonKey(name: 'region_name') String? get regionName;/// The branch, snapshotted like the city — a customer renaming one must not rewrite where
/// an old order said it was going.
@JsonKey(name: 'customer_shop_name') String? get customerShopName;@JsonKey(name: 'recipient_name') String? get recipientName;@JsonKey(name: 'recipient_phone') String? get recipientPhone;@JsonKey(name: 'address_details') String? get addressDetails; String? get notes;@JsonKey(name: 'shipping_company') String? get shippingCompany;@JsonKey(name: 'tracking_number') String? get trackingNumber;/// The number the man holding the parcel can be reached on — what «جاري التوصيل» asks for
/// and what `OrderResource` publishes. It was read from `courier_name`, a key the server has
/// never sent, so it parsed as null on every order ever fetched.
@JsonKey(name: 'courier_phone') String? get courierPhone;@JsonKey(name: 'cancellation_reason') String? get cancellationReason;/// The journey, in the domain's own order — see [OrderProgress].
 OrderProgress get progress;/// Whether the quantities may still be corrected. Open while the press is running — that is
/// exactly when a customer rings and asks for five hundred instead of three — and closed
/// from «جاهزة» onwards, when the bags exist and are counted.
@JsonKey(name: 'items_are_editable') bool get itemsAreEditable;/// Whether another version of the artwork may be attached.
///
/// **A different line from [itemsAreEditable], and the app keeps no copy of either.** The
/// press runs against an approved file, so the artwork settles when printing starts;
/// changing it means sending the order back to «قيد التصميم», which is a move somebody
/// makes on purpose.
@JsonKey(name: 'designs_are_editable') bool get designsAreEditable;/// Whether where it is going may still be changed.
///
/// **A third line, later than both of the others.** The lines close when the bags exist and
/// the artwork closes when the press starts, but an address stays correctable right up to
/// the moment somebody is driving to it — «جاري التوصيل» is the one open status that
/// refuses, because there the label has already left and only the label is real.
@JsonKey(name: 'destination_is_editable') bool get destinationIsEditable;/// Present on the list endpoint.
@JsonKey(name: 'items_count') int? get itemsCount;/// Present when one order was fetched.
 List<OrderItem>? get items; List<OrderDesign>? get designs; List<OrderTransitionRecord>? get transitions;/// What this order cost to produce, and what is left of the invoice after it.
///
/// **Both null until the order has reached «جاهزة»** — nothing is costed before stock
/// leaves a shelf, and «لم يُحتسب بعد» is not «صفر». [grossProfit] is derived by the server
/// from the two figures beside it and never stored, so the app reads it rather than
/// subtracting: which total the margin is taken against is a rule, and rules live in one
/// place.
@JsonKey(name: 'total_cogs') String? get totalCogs;@JsonKey(name: 'gross_profit') String? get grossProfit;/// Which shelf this run came off, and when — both null until the order reaches «جاهزة», and
/// never rewritten after. That is later than it used to be, and deliberately: an order's
/// lines are frozen by «جاهزة» but still editable through «قيد الطباعة», so stock now leaves
/// the warehouse against quantities nobody can still change underneath it.
@JsonKey(name: 'fulfillment_warehouse_id') int? get fulfillmentWarehouseId;@JsonKey(name: 'stock_deducted_at') DateTime? get stockDeductedAt;@JsonKey(name: 'placed_at') DateTime? get placedAt;@JsonKey(name: 'delivered_at') DateTime? get deliveredAt;@JsonKey(name: 'settled_at') DateTime? get settledAt;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderCopyWith<Order> get copyWith => _$OrderCopyWithImpl<Order>(this as Order, _$identity);

  /// Serializes this Order to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Order&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.productionFlowLabel, productionFlowLabel) || other.productionFlowLabel == productionFlowLabel)&&(identical(other.isFinal, isFinal) || other.isFinal == isFinal)&&(identical(other.isClosed, isClosed) || other.isClosed == isClosed)&&const DeepCollectionEquality().equals(other.availableTransitions, availableTransitions)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.cityId, cityId) || other.cityId == cityId)&&(identical(other.designSource, designSource) || other.designSource == designSource)&&(identical(other.cityName, cityName) || other.cityName == cityName)&&(identical(other.fulfilmentTypeLabel, fulfilmentTypeLabel) || other.fulfilmentTypeLabel == fulfilmentTypeLabel)&&(identical(other.isOfficePickup, isOfficePickup) || other.isOfficePickup == isOfficePickup)&&(identical(other.designSourceLabel, designSourceLabel) || other.designSourceLabel == designSourceLabel)&&(identical(other.itemsTotal, itemsTotal) || other.itemsTotal == itemsTotal)&&(identical(other.designFee, designFee) || other.designFee == designFee)&&(identical(other.deliveryPrice, deliveryPrice) || other.deliveryPrice == deliveryPrice)&&(identical(other.discount, discount) || other.discount == discount)&&(identical(other.additionalCost, additionalCost) || other.additionalCost == additionalCost)&&(identical(other.additionalCostReason, additionalCostReason) || other.additionalCostReason == additionalCostReason)&&(identical(other.additionalCostReasonLabel, additionalCostReasonLabel) || other.additionalCostReasonLabel == additionalCostReasonLabel)&&(identical(other.additionalCostNote, additionalCostNote) || other.additionalCostNote == additionalCostNote)&&(identical(other.grandTotal, grandTotal) || other.grandTotal == grandTotal)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount)&&(identical(other.writtenOffAmount, writtenOffAmount) || other.writtenOffAmount == writtenOffAmount)&&(identical(other.remainingAmount, remainingAmount) || other.remainingAmount == remainingAmount)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.paymentStatusLabel, paymentStatusLabel) || other.paymentStatusLabel == paymentStatusLabel)&&(identical(other.hasUnrecordedMoney, hasUnrecordedMoney) || other.hasUnrecordedMoney == hasUnrecordedMoney)&&(identical(other.collectedAmount, collectedAmount) || other.collectedAmount == collectedAmount)&&(identical(other.customer, customer) || other.customer == customer)&&(identical(other.regionId, regionId) || other.regionId == regionId)&&(identical(other.customerShopId, customerShopId) || other.customerShopId == customerShopId)&&(identical(other.regionName, regionName) || other.regionName == regionName)&&(identical(other.customerShopName, customerShopName) || other.customerShopName == customerShopName)&&(identical(other.recipientName, recipientName) || other.recipientName == recipientName)&&(identical(other.recipientPhone, recipientPhone) || other.recipientPhone == recipientPhone)&&(identical(other.addressDetails, addressDetails) || other.addressDetails == addressDetails)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.shippingCompany, shippingCompany) || other.shippingCompany == shippingCompany)&&(identical(other.trackingNumber, trackingNumber) || other.trackingNumber == trackingNumber)&&(identical(other.courierPhone, courierPhone) || other.courierPhone == courierPhone)&&(identical(other.cancellationReason, cancellationReason) || other.cancellationReason == cancellationReason)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.itemsAreEditable, itemsAreEditable) || other.itemsAreEditable == itemsAreEditable)&&(identical(other.designsAreEditable, designsAreEditable) || other.designsAreEditable == designsAreEditable)&&(identical(other.destinationIsEditable, destinationIsEditable) || other.destinationIsEditable == destinationIsEditable)&&(identical(other.itemsCount, itemsCount) || other.itemsCount == itemsCount)&&const DeepCollectionEquality().equals(other.items, items)&&const DeepCollectionEquality().equals(other.designs, designs)&&const DeepCollectionEquality().equals(other.transitions, transitions)&&(identical(other.totalCogs, totalCogs) || other.totalCogs == totalCogs)&&(identical(other.grossProfit, grossProfit) || other.grossProfit == grossProfit)&&(identical(other.fulfillmentWarehouseId, fulfillmentWarehouseId) || other.fulfillmentWarehouseId == fulfillmentWarehouseId)&&(identical(other.stockDeductedAt, stockDeductedAt) || other.stockDeductedAt == stockDeductedAt)&&(identical(other.placedAt, placedAt) || other.placedAt == placedAt)&&(identical(other.deliveredAt, deliveredAt) || other.deliveredAt == deliveredAt)&&(identical(other.settledAt, settledAt) || other.settledAt == settledAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,code,status,statusLabel,productionFlowLabel,isFinal,isClosed,const DeepCollectionEquality().hash(availableTransitions),customerId,cityId,designSource,cityName,fulfilmentTypeLabel,isOfficePickup,designSourceLabel,itemsTotal,designFee,deliveryPrice,discount,additionalCost,additionalCostReason,additionalCostReasonLabel,additionalCostNote,grandTotal,paidAmount,writtenOffAmount,remainingAmount,paymentStatus,paymentStatusLabel,hasUnrecordedMoney,collectedAmount,customer,regionId,customerShopId,regionName,customerShopName,recipientName,recipientPhone,addressDetails,notes,shippingCompany,trackingNumber,courierPhone,cancellationReason,progress,itemsAreEditable,designsAreEditable,destinationIsEditable,itemsCount,const DeepCollectionEquality().hash(items),const DeepCollectionEquality().hash(designs),const DeepCollectionEquality().hash(transitions),totalCogs,grossProfit,fulfillmentWarehouseId,stockDeductedAt,placedAt,deliveredAt,settledAt,createdAt]);

@override
String toString() {
  return 'Order(id: $id, code: $code, status: $status, statusLabel: $statusLabel, productionFlowLabel: $productionFlowLabel, isFinal: $isFinal, isClosed: $isClosed, availableTransitions: $availableTransitions, customerId: $customerId, cityId: $cityId, designSource: $designSource, cityName: $cityName, fulfilmentTypeLabel: $fulfilmentTypeLabel, isOfficePickup: $isOfficePickup, designSourceLabel: $designSourceLabel, itemsTotal: $itemsTotal, designFee: $designFee, deliveryPrice: $deliveryPrice, discount: $discount, additionalCost: $additionalCost, additionalCostReason: $additionalCostReason, additionalCostReasonLabel: $additionalCostReasonLabel, additionalCostNote: $additionalCostNote, grandTotal: $grandTotal, paidAmount: $paidAmount, writtenOffAmount: $writtenOffAmount, remainingAmount: $remainingAmount, paymentStatus: $paymentStatus, paymentStatusLabel: $paymentStatusLabel, hasUnrecordedMoney: $hasUnrecordedMoney, collectedAmount: $collectedAmount, customer: $customer, regionId: $regionId, customerShopId: $customerShopId, regionName: $regionName, customerShopName: $customerShopName, recipientName: $recipientName, recipientPhone: $recipientPhone, addressDetails: $addressDetails, notes: $notes, shippingCompany: $shippingCompany, trackingNumber: $trackingNumber, courierPhone: $courierPhone, cancellationReason: $cancellationReason, progress: $progress, itemsAreEditable: $itemsAreEditable, designsAreEditable: $designsAreEditable, destinationIsEditable: $destinationIsEditable, itemsCount: $itemsCount, items: $items, designs: $designs, transitions: $transitions, totalCogs: $totalCogs, grossProfit: $grossProfit, fulfillmentWarehouseId: $fulfillmentWarehouseId, stockDeductedAt: $stockDeductedAt, placedAt: $placedAt, deliveredAt: $deliveredAt, settledAt: $settledAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $OrderCopyWith<$Res>  {
  factory $OrderCopyWith(Order value, $Res Function(Order) _then) = _$OrderCopyWithImpl;
@useResult
$Res call({
 int id, String code,@JsonKey(unknownEnumValue: OrderStatus.unknown) OrderStatus status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'production_flow_label') String productionFlowLabel,@JsonKey(name: 'is_final') bool isFinal,@JsonKey(name: 'is_closed') bool isClosed,@JsonKey(name: 'available_transitions') List<OrderTransition> availableTransitions,@JsonKey(name: 'customer_id') int customerId,@JsonKey(name: 'city_id') int cityId,@JsonKey(name: 'design_source') String designSource,@JsonKey(name: 'city_name') String cityName,@JsonKey(name: 'fulfilment_type_label') String fulfilmentTypeLabel,@JsonKey(name: 'is_office_pickup') bool isOfficePickup,@JsonKey(name: 'design_source_label') String designSourceLabel,@JsonKey(name: 'items_total') String itemsTotal,@JsonKey(name: 'design_fee') String designFee,@JsonKey(name: 'delivery_price') String deliveryPrice, String discount,@JsonKey(name: 'additional_cost') String additionalCost,@JsonKey(name: 'additional_cost_reason', unknownEnumValue: AdditionalCostReason.unknown) AdditionalCostReason? additionalCostReason,@JsonKey(name: 'additional_cost_reason_label') String? additionalCostReasonLabel,@JsonKey(name: 'additional_cost_note') String? additionalCostNote,@JsonKey(name: 'grand_total') String grandTotal,@JsonKey(name: 'paid_amount') String paidAmount,@JsonKey(name: 'written_off_amount') String writtenOffAmount,@JsonKey(name: 'remaining_amount') String remainingAmount,@JsonKey(name: 'payment_status', unknownEnumValue: PaymentStatus.unknown) PaymentStatus paymentStatus,@JsonKey(name: 'payment_status_label') String paymentStatusLabel,@JsonKey(name: 'has_unrecorded_money') bool hasUnrecordedMoney,@JsonKey(name: 'collected_amount') String? collectedAmount, Customer? customer,@JsonKey(name: 'region_id') int? regionId,@JsonKey(name: 'customer_shop_id') int? customerShopId,@JsonKey(name: 'region_name') String? regionName,@JsonKey(name: 'customer_shop_name') String? customerShopName,@JsonKey(name: 'recipient_name') String? recipientName,@JsonKey(name: 'recipient_phone') String? recipientPhone,@JsonKey(name: 'address_details') String? addressDetails, String? notes,@JsonKey(name: 'shipping_company') String? shippingCompany,@JsonKey(name: 'tracking_number') String? trackingNumber,@JsonKey(name: 'courier_phone') String? courierPhone,@JsonKey(name: 'cancellation_reason') String? cancellationReason, OrderProgress progress,@JsonKey(name: 'items_are_editable') bool itemsAreEditable,@JsonKey(name: 'designs_are_editable') bool designsAreEditable,@JsonKey(name: 'destination_is_editable') bool destinationIsEditable,@JsonKey(name: 'items_count') int? itemsCount, List<OrderItem>? items, List<OrderDesign>? designs, List<OrderTransitionRecord>? transitions,@JsonKey(name: 'total_cogs') String? totalCogs,@JsonKey(name: 'gross_profit') String? grossProfit,@JsonKey(name: 'fulfillment_warehouse_id') int? fulfillmentWarehouseId,@JsonKey(name: 'stock_deducted_at') DateTime? stockDeductedAt,@JsonKey(name: 'placed_at') DateTime? placedAt,@JsonKey(name: 'delivered_at') DateTime? deliveredAt,@JsonKey(name: 'settled_at') DateTime? settledAt,@JsonKey(name: 'created_at') DateTime? createdAt
});


$CustomerCopyWith<$Res>? get customer;$OrderProgressCopyWith<$Res> get progress;

}
/// @nodoc
class _$OrderCopyWithImpl<$Res>
    implements $OrderCopyWith<$Res> {
  _$OrderCopyWithImpl(this._self, this._then);

  final Order _self;
  final $Res Function(Order) _then;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? status = null,Object? statusLabel = null,Object? productionFlowLabel = null,Object? isFinal = null,Object? isClosed = null,Object? availableTransitions = null,Object? customerId = null,Object? cityId = null,Object? designSource = null,Object? cityName = null,Object? fulfilmentTypeLabel = null,Object? isOfficePickup = null,Object? designSourceLabel = null,Object? itemsTotal = null,Object? designFee = null,Object? deliveryPrice = null,Object? discount = null,Object? additionalCost = null,Object? additionalCostReason = freezed,Object? additionalCostReasonLabel = freezed,Object? additionalCostNote = freezed,Object? grandTotal = null,Object? paidAmount = null,Object? writtenOffAmount = null,Object? remainingAmount = null,Object? paymentStatus = null,Object? paymentStatusLabel = null,Object? hasUnrecordedMoney = null,Object? collectedAmount = freezed,Object? customer = freezed,Object? regionId = freezed,Object? customerShopId = freezed,Object? regionName = freezed,Object? customerShopName = freezed,Object? recipientName = freezed,Object? recipientPhone = freezed,Object? addressDetails = freezed,Object? notes = freezed,Object? shippingCompany = freezed,Object? trackingNumber = freezed,Object? courierPhone = freezed,Object? cancellationReason = freezed,Object? progress = null,Object? itemsAreEditable = null,Object? designsAreEditable = null,Object? destinationIsEditable = null,Object? itemsCount = freezed,Object? items = freezed,Object? designs = freezed,Object? transitions = freezed,Object? totalCogs = freezed,Object? grossProfit = freezed,Object? fulfillmentWarehouseId = freezed,Object? stockDeductedAt = freezed,Object? placedAt = freezed,Object? deliveredAt = freezed,Object? settledAt = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,productionFlowLabel: null == productionFlowLabel ? _self.productionFlowLabel : productionFlowLabel // ignore: cast_nullable_to_non_nullable
as String,isFinal: null == isFinal ? _self.isFinal : isFinal // ignore: cast_nullable_to_non_nullable
as bool,isClosed: null == isClosed ? _self.isClosed : isClosed // ignore: cast_nullable_to_non_nullable
as bool,availableTransitions: null == availableTransitions ? _self.availableTransitions : availableTransitions // ignore: cast_nullable_to_non_nullable
as List<OrderTransition>,customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as int,cityId: null == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as int,designSource: null == designSource ? _self.designSource : designSource // ignore: cast_nullable_to_non_nullable
as String,cityName: null == cityName ? _self.cityName : cityName // ignore: cast_nullable_to_non_nullable
as String,fulfilmentTypeLabel: null == fulfilmentTypeLabel ? _self.fulfilmentTypeLabel : fulfilmentTypeLabel // ignore: cast_nullable_to_non_nullable
as String,isOfficePickup: null == isOfficePickup ? _self.isOfficePickup : isOfficePickup // ignore: cast_nullable_to_non_nullable
as bool,designSourceLabel: null == designSourceLabel ? _self.designSourceLabel : designSourceLabel // ignore: cast_nullable_to_non_nullable
as String,itemsTotal: null == itemsTotal ? _self.itemsTotal : itemsTotal // ignore: cast_nullable_to_non_nullable
as String,designFee: null == designFee ? _self.designFee : designFee // ignore: cast_nullable_to_non_nullable
as String,deliveryPrice: null == deliveryPrice ? _self.deliveryPrice : deliveryPrice // ignore: cast_nullable_to_non_nullable
as String,discount: null == discount ? _self.discount : discount // ignore: cast_nullable_to_non_nullable
as String,additionalCost: null == additionalCost ? _self.additionalCost : additionalCost // ignore: cast_nullable_to_non_nullable
as String,additionalCostReason: freezed == additionalCostReason ? _self.additionalCostReason : additionalCostReason // ignore: cast_nullable_to_non_nullable
as AdditionalCostReason?,additionalCostReasonLabel: freezed == additionalCostReasonLabel ? _self.additionalCostReasonLabel : additionalCostReasonLabel // ignore: cast_nullable_to_non_nullable
as String?,additionalCostNote: freezed == additionalCostNote ? _self.additionalCostNote : additionalCostNote // ignore: cast_nullable_to_non_nullable
as String?,grandTotal: null == grandTotal ? _self.grandTotal : grandTotal // ignore: cast_nullable_to_non_nullable
as String,paidAmount: null == paidAmount ? _self.paidAmount : paidAmount // ignore: cast_nullable_to_non_nullable
as String,writtenOffAmount: null == writtenOffAmount ? _self.writtenOffAmount : writtenOffAmount // ignore: cast_nullable_to_non_nullable
as String,remainingAmount: null == remainingAmount ? _self.remainingAmount : remainingAmount // ignore: cast_nullable_to_non_nullable
as String,paymentStatus: null == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as PaymentStatus,paymentStatusLabel: null == paymentStatusLabel ? _self.paymentStatusLabel : paymentStatusLabel // ignore: cast_nullable_to_non_nullable
as String,hasUnrecordedMoney: null == hasUnrecordedMoney ? _self.hasUnrecordedMoney : hasUnrecordedMoney // ignore: cast_nullable_to_non_nullable
as bool,collectedAmount: freezed == collectedAmount ? _self.collectedAmount : collectedAmount // ignore: cast_nullable_to_non_nullable
as String?,customer: freezed == customer ? _self.customer : customer // ignore: cast_nullable_to_non_nullable
as Customer?,regionId: freezed == regionId ? _self.regionId : regionId // ignore: cast_nullable_to_non_nullable
as int?,customerShopId: freezed == customerShopId ? _self.customerShopId : customerShopId // ignore: cast_nullable_to_non_nullable
as int?,regionName: freezed == regionName ? _self.regionName : regionName // ignore: cast_nullable_to_non_nullable
as String?,customerShopName: freezed == customerShopName ? _self.customerShopName : customerShopName // ignore: cast_nullable_to_non_nullable
as String?,recipientName: freezed == recipientName ? _self.recipientName : recipientName // ignore: cast_nullable_to_non_nullable
as String?,recipientPhone: freezed == recipientPhone ? _self.recipientPhone : recipientPhone // ignore: cast_nullable_to_non_nullable
as String?,addressDetails: freezed == addressDetails ? _self.addressDetails : addressDetails // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,shippingCompany: freezed == shippingCompany ? _self.shippingCompany : shippingCompany // ignore: cast_nullable_to_non_nullable
as String?,trackingNumber: freezed == trackingNumber ? _self.trackingNumber : trackingNumber // ignore: cast_nullable_to_non_nullable
as String?,courierPhone: freezed == courierPhone ? _self.courierPhone : courierPhone // ignore: cast_nullable_to_non_nullable
as String?,cancellationReason: freezed == cancellationReason ? _self.cancellationReason : cancellationReason // ignore: cast_nullable_to_non_nullable
as String?,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as OrderProgress,itemsAreEditable: null == itemsAreEditable ? _self.itemsAreEditable : itemsAreEditable // ignore: cast_nullable_to_non_nullable
as bool,designsAreEditable: null == designsAreEditable ? _self.designsAreEditable : designsAreEditable // ignore: cast_nullable_to_non_nullable
as bool,destinationIsEditable: null == destinationIsEditable ? _self.destinationIsEditable : destinationIsEditable // ignore: cast_nullable_to_non_nullable
as bool,itemsCount: freezed == itemsCount ? _self.itemsCount : itemsCount // ignore: cast_nullable_to_non_nullable
as int?,items: freezed == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<OrderItem>?,designs: freezed == designs ? _self.designs : designs // ignore: cast_nullable_to_non_nullable
as List<OrderDesign>?,transitions: freezed == transitions ? _self.transitions : transitions // ignore: cast_nullable_to_non_nullable
as List<OrderTransitionRecord>?,totalCogs: freezed == totalCogs ? _self.totalCogs : totalCogs // ignore: cast_nullable_to_non_nullable
as String?,grossProfit: freezed == grossProfit ? _self.grossProfit : grossProfit // ignore: cast_nullable_to_non_nullable
as String?,fulfillmentWarehouseId: freezed == fulfillmentWarehouseId ? _self.fulfillmentWarehouseId : fulfillmentWarehouseId // ignore: cast_nullable_to_non_nullable
as int?,stockDeductedAt: freezed == stockDeductedAt ? _self.stockDeductedAt : stockDeductedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,placedAt: freezed == placedAt ? _self.placedAt : placedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deliveredAt: freezed == deliveredAt ? _self.deliveredAt : deliveredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,settledAt: freezed == settledAt ? _self.settledAt : settledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CustomerCopyWith<$Res>? get customer {
    if (_self.customer == null) {
    return null;
  }

  return $CustomerCopyWith<$Res>(_self.customer!, (value) {
    return _then(_self.copyWith(customer: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderProgressCopyWith<$Res> get progress {
  
  return $OrderProgressCopyWith<$Res>(_self.progress, (value) {
    return _then(_self.copyWith(progress: value));
  });
}
}


/// Adds pattern-matching-related methods to [Order].
extension OrderPatterns on Order {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Order value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Order value)  $default,){
final _that = this;
switch (_that) {
case _Order():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Order value)?  $default,){
final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String code, @JsonKey(unknownEnumValue: OrderStatus.unknown)  OrderStatus status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'production_flow_label')  String productionFlowLabel, @JsonKey(name: 'is_final')  bool isFinal, @JsonKey(name: 'is_closed')  bool isClosed, @JsonKey(name: 'available_transitions')  List<OrderTransition> availableTransitions, @JsonKey(name: 'customer_id')  int customerId, @JsonKey(name: 'city_id')  int cityId, @JsonKey(name: 'design_source')  String designSource, @JsonKey(name: 'city_name')  String cityName, @JsonKey(name: 'fulfilment_type_label')  String fulfilmentTypeLabel, @JsonKey(name: 'is_office_pickup')  bool isOfficePickup, @JsonKey(name: 'design_source_label')  String designSourceLabel, @JsonKey(name: 'items_total')  String itemsTotal, @JsonKey(name: 'design_fee')  String designFee, @JsonKey(name: 'delivery_price')  String deliveryPrice,  String discount, @JsonKey(name: 'additional_cost')  String additionalCost, @JsonKey(name: 'additional_cost_reason', unknownEnumValue: AdditionalCostReason.unknown)  AdditionalCostReason? additionalCostReason, @JsonKey(name: 'additional_cost_reason_label')  String? additionalCostReasonLabel, @JsonKey(name: 'additional_cost_note')  String? additionalCostNote, @JsonKey(name: 'grand_total')  String grandTotal, @JsonKey(name: 'paid_amount')  String paidAmount, @JsonKey(name: 'written_off_amount')  String writtenOffAmount, @JsonKey(name: 'remaining_amount')  String remainingAmount, @JsonKey(name: 'payment_status', unknownEnumValue: PaymentStatus.unknown)  PaymentStatus paymentStatus, @JsonKey(name: 'payment_status_label')  String paymentStatusLabel, @JsonKey(name: 'has_unrecorded_money')  bool hasUnrecordedMoney, @JsonKey(name: 'collected_amount')  String? collectedAmount,  Customer? customer, @JsonKey(name: 'region_id')  int? regionId, @JsonKey(name: 'customer_shop_id')  int? customerShopId, @JsonKey(name: 'region_name')  String? regionName, @JsonKey(name: 'customer_shop_name')  String? customerShopName, @JsonKey(name: 'recipient_name')  String? recipientName, @JsonKey(name: 'recipient_phone')  String? recipientPhone, @JsonKey(name: 'address_details')  String? addressDetails,  String? notes, @JsonKey(name: 'shipping_company')  String? shippingCompany, @JsonKey(name: 'tracking_number')  String? trackingNumber, @JsonKey(name: 'courier_phone')  String? courierPhone, @JsonKey(name: 'cancellation_reason')  String? cancellationReason,  OrderProgress progress, @JsonKey(name: 'items_are_editable')  bool itemsAreEditable, @JsonKey(name: 'designs_are_editable')  bool designsAreEditable, @JsonKey(name: 'destination_is_editable')  bool destinationIsEditable, @JsonKey(name: 'items_count')  int? itemsCount,  List<OrderItem>? items,  List<OrderDesign>? designs,  List<OrderTransitionRecord>? transitions, @JsonKey(name: 'total_cogs')  String? totalCogs, @JsonKey(name: 'gross_profit')  String? grossProfit, @JsonKey(name: 'fulfillment_warehouse_id')  int? fulfillmentWarehouseId, @JsonKey(name: 'stock_deducted_at')  DateTime? stockDeductedAt, @JsonKey(name: 'placed_at')  DateTime? placedAt, @JsonKey(name: 'delivered_at')  DateTime? deliveredAt, @JsonKey(name: 'settled_at')  DateTime? settledAt, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that.id,_that.code,_that.status,_that.statusLabel,_that.productionFlowLabel,_that.isFinal,_that.isClosed,_that.availableTransitions,_that.customerId,_that.cityId,_that.designSource,_that.cityName,_that.fulfilmentTypeLabel,_that.isOfficePickup,_that.designSourceLabel,_that.itemsTotal,_that.designFee,_that.deliveryPrice,_that.discount,_that.additionalCost,_that.additionalCostReason,_that.additionalCostReasonLabel,_that.additionalCostNote,_that.grandTotal,_that.paidAmount,_that.writtenOffAmount,_that.remainingAmount,_that.paymentStatus,_that.paymentStatusLabel,_that.hasUnrecordedMoney,_that.collectedAmount,_that.customer,_that.regionId,_that.customerShopId,_that.regionName,_that.customerShopName,_that.recipientName,_that.recipientPhone,_that.addressDetails,_that.notes,_that.shippingCompany,_that.trackingNumber,_that.courierPhone,_that.cancellationReason,_that.progress,_that.itemsAreEditable,_that.designsAreEditable,_that.destinationIsEditable,_that.itemsCount,_that.items,_that.designs,_that.transitions,_that.totalCogs,_that.grossProfit,_that.fulfillmentWarehouseId,_that.stockDeductedAt,_that.placedAt,_that.deliveredAt,_that.settledAt,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String code, @JsonKey(unknownEnumValue: OrderStatus.unknown)  OrderStatus status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'production_flow_label')  String productionFlowLabel, @JsonKey(name: 'is_final')  bool isFinal, @JsonKey(name: 'is_closed')  bool isClosed, @JsonKey(name: 'available_transitions')  List<OrderTransition> availableTransitions, @JsonKey(name: 'customer_id')  int customerId, @JsonKey(name: 'city_id')  int cityId, @JsonKey(name: 'design_source')  String designSource, @JsonKey(name: 'city_name')  String cityName, @JsonKey(name: 'fulfilment_type_label')  String fulfilmentTypeLabel, @JsonKey(name: 'is_office_pickup')  bool isOfficePickup, @JsonKey(name: 'design_source_label')  String designSourceLabel, @JsonKey(name: 'items_total')  String itemsTotal, @JsonKey(name: 'design_fee')  String designFee, @JsonKey(name: 'delivery_price')  String deliveryPrice,  String discount, @JsonKey(name: 'additional_cost')  String additionalCost, @JsonKey(name: 'additional_cost_reason', unknownEnumValue: AdditionalCostReason.unknown)  AdditionalCostReason? additionalCostReason, @JsonKey(name: 'additional_cost_reason_label')  String? additionalCostReasonLabel, @JsonKey(name: 'additional_cost_note')  String? additionalCostNote, @JsonKey(name: 'grand_total')  String grandTotal, @JsonKey(name: 'paid_amount')  String paidAmount, @JsonKey(name: 'written_off_amount')  String writtenOffAmount, @JsonKey(name: 'remaining_amount')  String remainingAmount, @JsonKey(name: 'payment_status', unknownEnumValue: PaymentStatus.unknown)  PaymentStatus paymentStatus, @JsonKey(name: 'payment_status_label')  String paymentStatusLabel, @JsonKey(name: 'has_unrecorded_money')  bool hasUnrecordedMoney, @JsonKey(name: 'collected_amount')  String? collectedAmount,  Customer? customer, @JsonKey(name: 'region_id')  int? regionId, @JsonKey(name: 'customer_shop_id')  int? customerShopId, @JsonKey(name: 'region_name')  String? regionName, @JsonKey(name: 'customer_shop_name')  String? customerShopName, @JsonKey(name: 'recipient_name')  String? recipientName, @JsonKey(name: 'recipient_phone')  String? recipientPhone, @JsonKey(name: 'address_details')  String? addressDetails,  String? notes, @JsonKey(name: 'shipping_company')  String? shippingCompany, @JsonKey(name: 'tracking_number')  String? trackingNumber, @JsonKey(name: 'courier_phone')  String? courierPhone, @JsonKey(name: 'cancellation_reason')  String? cancellationReason,  OrderProgress progress, @JsonKey(name: 'items_are_editable')  bool itemsAreEditable, @JsonKey(name: 'designs_are_editable')  bool designsAreEditable, @JsonKey(name: 'destination_is_editable')  bool destinationIsEditable, @JsonKey(name: 'items_count')  int? itemsCount,  List<OrderItem>? items,  List<OrderDesign>? designs,  List<OrderTransitionRecord>? transitions, @JsonKey(name: 'total_cogs')  String? totalCogs, @JsonKey(name: 'gross_profit')  String? grossProfit, @JsonKey(name: 'fulfillment_warehouse_id')  int? fulfillmentWarehouseId, @JsonKey(name: 'stock_deducted_at')  DateTime? stockDeductedAt, @JsonKey(name: 'placed_at')  DateTime? placedAt, @JsonKey(name: 'delivered_at')  DateTime? deliveredAt, @JsonKey(name: 'settled_at')  DateTime? settledAt, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _Order():
return $default(_that.id,_that.code,_that.status,_that.statusLabel,_that.productionFlowLabel,_that.isFinal,_that.isClosed,_that.availableTransitions,_that.customerId,_that.cityId,_that.designSource,_that.cityName,_that.fulfilmentTypeLabel,_that.isOfficePickup,_that.designSourceLabel,_that.itemsTotal,_that.designFee,_that.deliveryPrice,_that.discount,_that.additionalCost,_that.additionalCostReason,_that.additionalCostReasonLabel,_that.additionalCostNote,_that.grandTotal,_that.paidAmount,_that.writtenOffAmount,_that.remainingAmount,_that.paymentStatus,_that.paymentStatusLabel,_that.hasUnrecordedMoney,_that.collectedAmount,_that.customer,_that.regionId,_that.customerShopId,_that.regionName,_that.customerShopName,_that.recipientName,_that.recipientPhone,_that.addressDetails,_that.notes,_that.shippingCompany,_that.trackingNumber,_that.courierPhone,_that.cancellationReason,_that.progress,_that.itemsAreEditable,_that.designsAreEditable,_that.destinationIsEditable,_that.itemsCount,_that.items,_that.designs,_that.transitions,_that.totalCogs,_that.grossProfit,_that.fulfillmentWarehouseId,_that.stockDeductedAt,_that.placedAt,_that.deliveredAt,_that.settledAt,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String code, @JsonKey(unknownEnumValue: OrderStatus.unknown)  OrderStatus status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'production_flow_label')  String productionFlowLabel, @JsonKey(name: 'is_final')  bool isFinal, @JsonKey(name: 'is_closed')  bool isClosed, @JsonKey(name: 'available_transitions')  List<OrderTransition> availableTransitions, @JsonKey(name: 'customer_id')  int customerId, @JsonKey(name: 'city_id')  int cityId, @JsonKey(name: 'design_source')  String designSource, @JsonKey(name: 'city_name')  String cityName, @JsonKey(name: 'fulfilment_type_label')  String fulfilmentTypeLabel, @JsonKey(name: 'is_office_pickup')  bool isOfficePickup, @JsonKey(name: 'design_source_label')  String designSourceLabel, @JsonKey(name: 'items_total')  String itemsTotal, @JsonKey(name: 'design_fee')  String designFee, @JsonKey(name: 'delivery_price')  String deliveryPrice,  String discount, @JsonKey(name: 'additional_cost')  String additionalCost, @JsonKey(name: 'additional_cost_reason', unknownEnumValue: AdditionalCostReason.unknown)  AdditionalCostReason? additionalCostReason, @JsonKey(name: 'additional_cost_reason_label')  String? additionalCostReasonLabel, @JsonKey(name: 'additional_cost_note')  String? additionalCostNote, @JsonKey(name: 'grand_total')  String grandTotal, @JsonKey(name: 'paid_amount')  String paidAmount, @JsonKey(name: 'written_off_amount')  String writtenOffAmount, @JsonKey(name: 'remaining_amount')  String remainingAmount, @JsonKey(name: 'payment_status', unknownEnumValue: PaymentStatus.unknown)  PaymentStatus paymentStatus, @JsonKey(name: 'payment_status_label')  String paymentStatusLabel, @JsonKey(name: 'has_unrecorded_money')  bool hasUnrecordedMoney, @JsonKey(name: 'collected_amount')  String? collectedAmount,  Customer? customer, @JsonKey(name: 'region_id')  int? regionId, @JsonKey(name: 'customer_shop_id')  int? customerShopId, @JsonKey(name: 'region_name')  String? regionName, @JsonKey(name: 'customer_shop_name')  String? customerShopName, @JsonKey(name: 'recipient_name')  String? recipientName, @JsonKey(name: 'recipient_phone')  String? recipientPhone, @JsonKey(name: 'address_details')  String? addressDetails,  String? notes, @JsonKey(name: 'shipping_company')  String? shippingCompany, @JsonKey(name: 'tracking_number')  String? trackingNumber, @JsonKey(name: 'courier_phone')  String? courierPhone, @JsonKey(name: 'cancellation_reason')  String? cancellationReason,  OrderProgress progress, @JsonKey(name: 'items_are_editable')  bool itemsAreEditable, @JsonKey(name: 'designs_are_editable')  bool designsAreEditable, @JsonKey(name: 'destination_is_editable')  bool destinationIsEditable, @JsonKey(name: 'items_count')  int? itemsCount,  List<OrderItem>? items,  List<OrderDesign>? designs,  List<OrderTransitionRecord>? transitions, @JsonKey(name: 'total_cogs')  String? totalCogs, @JsonKey(name: 'gross_profit')  String? grossProfit, @JsonKey(name: 'fulfillment_warehouse_id')  int? fulfillmentWarehouseId, @JsonKey(name: 'stock_deducted_at')  DateTime? stockDeductedAt, @JsonKey(name: 'placed_at')  DateTime? placedAt, @JsonKey(name: 'delivered_at')  DateTime? deliveredAt, @JsonKey(name: 'settled_at')  DateTime? settledAt, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that.id,_that.code,_that.status,_that.statusLabel,_that.productionFlowLabel,_that.isFinal,_that.isClosed,_that.availableTransitions,_that.customerId,_that.cityId,_that.designSource,_that.cityName,_that.fulfilmentTypeLabel,_that.isOfficePickup,_that.designSourceLabel,_that.itemsTotal,_that.designFee,_that.deliveryPrice,_that.discount,_that.additionalCost,_that.additionalCostReason,_that.additionalCostReasonLabel,_that.additionalCostNote,_that.grandTotal,_that.paidAmount,_that.writtenOffAmount,_that.remainingAmount,_that.paymentStatus,_that.paymentStatusLabel,_that.hasUnrecordedMoney,_that.collectedAmount,_that.customer,_that.regionId,_that.customerShopId,_that.regionName,_that.customerShopName,_that.recipientName,_that.recipientPhone,_that.addressDetails,_that.notes,_that.shippingCompany,_that.trackingNumber,_that.courierPhone,_that.cancellationReason,_that.progress,_that.itemsAreEditable,_that.designsAreEditable,_that.destinationIsEditable,_that.itemsCount,_that.items,_that.designs,_that.transitions,_that.totalCogs,_that.grossProfit,_that.fulfillmentWarehouseId,_that.stockDeductedAt,_that.placedAt,_that.deliveredAt,_that.settledAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Order extends Order {
  const _Order({required this.id, required this.code, @JsonKey(unknownEnumValue: OrderStatus.unknown) required this.status, @JsonKey(name: 'status_label') required this.statusLabel, @JsonKey(name: 'production_flow_label') this.productionFlowLabel = '', @JsonKey(name: 'is_final') required this.isFinal, @JsonKey(name: 'is_closed') this.isClosed = false, @JsonKey(name: 'available_transitions') final  List<OrderTransition> availableTransitions = const <OrderTransition>[], @JsonKey(name: 'customer_id') required this.customerId, @JsonKey(name: 'city_id') required this.cityId, @JsonKey(name: 'design_source') required this.designSource, @JsonKey(name: 'city_name') required this.cityName, @JsonKey(name: 'fulfilment_type_label') required this.fulfilmentTypeLabel, @JsonKey(name: 'is_office_pickup') required this.isOfficePickup, @JsonKey(name: 'design_source_label') required this.designSourceLabel, @JsonKey(name: 'items_total') required this.itemsTotal, @JsonKey(name: 'design_fee') required this.designFee, @JsonKey(name: 'delivery_price') required this.deliveryPrice, required this.discount, @JsonKey(name: 'additional_cost') this.additionalCost = '0.00', @JsonKey(name: 'additional_cost_reason', unknownEnumValue: AdditionalCostReason.unknown) this.additionalCostReason, @JsonKey(name: 'additional_cost_reason_label') this.additionalCostReasonLabel, @JsonKey(name: 'additional_cost_note') this.additionalCostNote, @JsonKey(name: 'grand_total') required this.grandTotal, @JsonKey(name: 'paid_amount') this.paidAmount = '0.00', @JsonKey(name: 'written_off_amount') this.writtenOffAmount = '0.00', @JsonKey(name: 'remaining_amount') this.remainingAmount = '0.00', @JsonKey(name: 'payment_status', unknownEnumValue: PaymentStatus.unknown) this.paymentStatus = PaymentStatus.unpaid, @JsonKey(name: 'payment_status_label') this.paymentStatusLabel = '', @JsonKey(name: 'has_unrecorded_money') this.hasUnrecordedMoney = false, @JsonKey(name: 'collected_amount') this.collectedAmount, this.customer, @JsonKey(name: 'region_id') this.regionId, @JsonKey(name: 'customer_shop_id') this.customerShopId, @JsonKey(name: 'region_name') this.regionName, @JsonKey(name: 'customer_shop_name') this.customerShopName, @JsonKey(name: 'recipient_name') this.recipientName, @JsonKey(name: 'recipient_phone') this.recipientPhone, @JsonKey(name: 'address_details') this.addressDetails, this.notes, @JsonKey(name: 'shipping_company') this.shippingCompany, @JsonKey(name: 'tracking_number') this.trackingNumber, @JsonKey(name: 'courier_phone') this.courierPhone, @JsonKey(name: 'cancellation_reason') this.cancellationReason, this.progress = OrderProgress.unknown, @JsonKey(name: 'items_are_editable') this.itemsAreEditable = false, @JsonKey(name: 'designs_are_editable') this.designsAreEditable = false, @JsonKey(name: 'destination_is_editable') this.destinationIsEditable = false, @JsonKey(name: 'items_count') this.itemsCount, final  List<OrderItem>? items, final  List<OrderDesign>? designs, final  List<OrderTransitionRecord>? transitions, @JsonKey(name: 'total_cogs') this.totalCogs, @JsonKey(name: 'gross_profit') this.grossProfit, @JsonKey(name: 'fulfillment_warehouse_id') this.fulfillmentWarehouseId, @JsonKey(name: 'stock_deducted_at') this.stockDeductedAt, @JsonKey(name: 'placed_at') this.placedAt, @JsonKey(name: 'delivered_at') this.deliveredAt, @JsonKey(name: 'settled_at') this.settledAt, @JsonKey(name: 'created_at') this.createdAt}): _availableTransitions = availableTransitions,_items = items,_designs = designs,_transitions = transitions,super._();
  factory _Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

@override final  int id;
/// Plain digits — `'7'`. Said out loud on the phone, so it carries no letter prefix the
/// way a customer's `C7` or a product's `P7` does.
@override final  String code;
@override@JsonKey(unknownEnumValue: OrderStatus.unknown) final  OrderStatus status;
/// The Arabic the server chose. Rendered as-is, so a status this build does not know still
/// reads correctly — see [OrderStatus.unknown].
@override@JsonKey(name: 'status_label') final  String statusLabel;
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
@override@JsonKey(name: 'production_flow_label') final  String productionFlowLabel;
/// Whether the order is finished — no move of any kind is left.
///
/// **Not the same as [isClosed], and «تم الاستلام» is why.** The customer has the bags, so
/// nothing about the order may be edited; but the money it went out to collect has not been
/// agreed yet, so it still has one move to make.
@override@JsonKey(name: 'is_final') final  bool isFinal;
/// Whether the order itself is closed to editing.
@override@JsonKey(name: 'is_closed') final  bool isClosed;
/// The moves this order may make, **already narrowed to what the signed-in user may do.**
/// The screen draws exactly these buttons and no others, which is what stops it offering an
/// action the server would refuse.
 final  List<OrderTransition> _availableTransitions;
/// The moves this order may make, **already narrowed to what the signed-in user may do.**
/// The screen draws exactly these buttons and no others, which is what stops it offering an
/// action the server would refuse.
@override@JsonKey(name: 'available_transitions') List<OrderTransition> get availableTransitions {
  if (_availableTransitions is EqualUnmodifiableListView) return _availableTransitions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_availableTransitions);
}

@override@JsonKey(name: 'customer_id') final  int customerId;
@override@JsonKey(name: 'city_id') final  int cityId;
@override@JsonKey(name: 'design_source') final  String designSource;
@override@JsonKey(name: 'city_name') final  String cityName;
@override@JsonKey(name: 'fulfilment_type_label') final  String fulfilmentTypeLabel;
@override@JsonKey(name: 'is_office_pickup') final  bool isOfficePickup;
@override@JsonKey(name: 'design_source_label') final  String designSourceLabel;
@override@JsonKey(name: 'items_total') final  String itemsTotal;
@override@JsonKey(name: 'design_fee') final  String designFee;
@override@JsonKey(name: 'delivery_price') final  String deliveryPrice;
@override final  String discount;
/// A charge added to the order that no line on it describes — «تغليف خاص»، «نقل».
///
/// **Beside the discount and never folded into it.** A total is read as «هذا ما أُضيف وهذا
/// ما خُصم», and one net figure explains neither. `'0.00'` when nothing is charged, and
/// defaulted for the reason [paidAmount] is: an order from a server that predates the
/// column was never charged, and zero is exactly what such a server means.
@override@JsonKey(name: 'additional_cost') final  String additionalCost;
/// Which of the five categories it was booked under. Null on an order with no charge.
///
/// `unknownEnumValue` rather than a `String`, now that the sheet draws all five: a sixth
/// category added on the server after this build shipped parses as
/// [AdditionalCostReason.unknown] and the order still prints the label the server sent
/// beside it, instead of failing to parse at all.
@override@JsonKey(name: 'additional_cost_reason', unknownEnumValue: AdditionalCostReason.unknown) final  AdditionalCostReason? additionalCostReason;
/// The server's own Arabic for that category — «تغليف خاص». Rendered as-is, never mapped
/// from the code here: a second copy of that list is the one that drifts.
@override@JsonKey(name: 'additional_cost_reason_label') final  String? additionalCostReasonLabel;
/// What was actually done, in the clerk's words. The detail, never the classification.
@override@JsonKey(name: 'additional_cost_note') final  String? additionalCostNote;
@override@JsonKey(name: 'grand_total') final  String grandTotal;
/// **The numbers the screen puts side by side**, every one the server's arithmetic —
/// including the subtraction. `remainingAmount` is not `grandTotal - paidAmount` computed
/// here: that would be a second answer to one question, and this one is made of doubles.
///
/// `paidAmount` is the sum of the order's ledger. It is the *entries* that are the truth;
/// this is what they add up to, which is why nothing in the app ever writes it.
///
/// Defaulted so an order fetched from a build of the API that predates payments still
/// parses — the honest value for it is zero.
@override@JsonKey(name: 'paid_amount') final  String paidAmount;
/// What was closed without being collected — the difference somebody decided not to chase.
///
/// **Beside `paidAmount`, never inside it**, so that number goes on meaning cash. Defaulted
/// for the same reason its neighbour is: an order from a server that predates write-offs has
/// had nothing written off, and zero is exactly what such a server means.
@override@JsonKey(name: 'written_off_amount') final  String writtenOffAmount;
/// What is still owed — the invoice less what was collected **and** what was forgiven.
/// **Negative on an overpaid order**, so «زائد ٥٠» can be said rather than floored away.
@override@JsonKey(name: 'remaining_amount') final  String remainingAmount;
@override@JsonKey(name: 'payment_status', unknownEnumValue: PaymentStatus.unknown) final  PaymentStatus paymentStatus;
@override@JsonKey(name: 'payment_status_label') final  String paymentStatusLabel;
/// An order that finished without its money accounted for.
///
/// Settling writes no ledger entry — nothing records a payment except the person who took
/// it — so this is the gap being surfaced rather than papered over with an entry nobody
/// made. The screen warns; somebody records what was collected; the warning goes.
@override@JsonKey(name: 'has_unrecorded_money') final  bool hasUnrecordedMoney;
/// What actually came back for the order, when it was not what the invoice said.
///
/// Null on every settlement that went to plan, deliberately: a number here always means the
/// two disagreed.
@override@JsonKey(name: 'collected_amount') final  String? collectedAmount;
@override final  Customer? customer;
@override@JsonKey(name: 'region_id') final  int? regionId;
@override@JsonKey(name: 'customer_shop_id') final  int? customerShopId;
@override@JsonKey(name: 'region_name') final  String? regionName;
/// The branch, snapshotted like the city — a customer renaming one must not rewrite where
/// an old order said it was going.
@override@JsonKey(name: 'customer_shop_name') final  String? customerShopName;
@override@JsonKey(name: 'recipient_name') final  String? recipientName;
@override@JsonKey(name: 'recipient_phone') final  String? recipientPhone;
@override@JsonKey(name: 'address_details') final  String? addressDetails;
@override final  String? notes;
@override@JsonKey(name: 'shipping_company') final  String? shippingCompany;
@override@JsonKey(name: 'tracking_number') final  String? trackingNumber;
/// The number the man holding the parcel can be reached on — what «جاري التوصيل» asks for
/// and what `OrderResource` publishes. It was read from `courier_name`, a key the server has
/// never sent, so it parsed as null on every order ever fetched.
@override@JsonKey(name: 'courier_phone') final  String? courierPhone;
@override@JsonKey(name: 'cancellation_reason') final  String? cancellationReason;
/// The journey, in the domain's own order — see [OrderProgress].
@override@JsonKey() final  OrderProgress progress;
/// Whether the quantities may still be corrected. Open while the press is running — that is
/// exactly when a customer rings and asks for five hundred instead of three — and closed
/// from «جاهزة» onwards, when the bags exist and are counted.
@override@JsonKey(name: 'items_are_editable') final  bool itemsAreEditable;
/// Whether another version of the artwork may be attached.
///
/// **A different line from [itemsAreEditable], and the app keeps no copy of either.** The
/// press runs against an approved file, so the artwork settles when printing starts;
/// changing it means sending the order back to «قيد التصميم», which is a move somebody
/// makes on purpose.
@override@JsonKey(name: 'designs_are_editable') final  bool designsAreEditable;
/// Whether where it is going may still be changed.
///
/// **A third line, later than both of the others.** The lines close when the bags exist and
/// the artwork closes when the press starts, but an address stays correctable right up to
/// the moment somebody is driving to it — «جاري التوصيل» is the one open status that
/// refuses, because there the label has already left and only the label is real.
@override@JsonKey(name: 'destination_is_editable') final  bool destinationIsEditable;
/// Present on the list endpoint.
@override@JsonKey(name: 'items_count') final  int? itemsCount;
/// Present when one order was fetched.
 final  List<OrderItem>? _items;
/// Present when one order was fetched.
@override List<OrderItem>? get items {
  final value = _items;
  if (value == null) return null;
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<OrderDesign>? _designs;
@override List<OrderDesign>? get designs {
  final value = _designs;
  if (value == null) return null;
  if (_designs is EqualUnmodifiableListView) return _designs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<OrderTransitionRecord>? _transitions;
@override List<OrderTransitionRecord>? get transitions {
  final value = _transitions;
  if (value == null) return null;
  if (_transitions is EqualUnmodifiableListView) return _transitions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// What this order cost to produce, and what is left of the invoice after it.
///
/// **Both null until the order has reached «جاهزة»** — nothing is costed before stock
/// leaves a shelf, and «لم يُحتسب بعد» is not «صفر». [grossProfit] is derived by the server
/// from the two figures beside it and never stored, so the app reads it rather than
/// subtracting: which total the margin is taken against is a rule, and rules live in one
/// place.
@override@JsonKey(name: 'total_cogs') final  String? totalCogs;
@override@JsonKey(name: 'gross_profit') final  String? grossProfit;
/// Which shelf this run came off, and when — both null until the order reaches «جاهزة», and
/// never rewritten after. That is later than it used to be, and deliberately: an order's
/// lines are frozen by «جاهزة» but still editable through «قيد الطباعة», so stock now leaves
/// the warehouse against quantities nobody can still change underneath it.
@override@JsonKey(name: 'fulfillment_warehouse_id') final  int? fulfillmentWarehouseId;
@override@JsonKey(name: 'stock_deducted_at') final  DateTime? stockDeductedAt;
@override@JsonKey(name: 'placed_at') final  DateTime? placedAt;
@override@JsonKey(name: 'delivered_at') final  DateTime? deliveredAt;
@override@JsonKey(name: 'settled_at') final  DateTime? settledAt;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderCopyWith<_Order> get copyWith => __$OrderCopyWithImpl<_Order>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Order&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.productionFlowLabel, productionFlowLabel) || other.productionFlowLabel == productionFlowLabel)&&(identical(other.isFinal, isFinal) || other.isFinal == isFinal)&&(identical(other.isClosed, isClosed) || other.isClosed == isClosed)&&const DeepCollectionEquality().equals(other._availableTransitions, _availableTransitions)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.cityId, cityId) || other.cityId == cityId)&&(identical(other.designSource, designSource) || other.designSource == designSource)&&(identical(other.cityName, cityName) || other.cityName == cityName)&&(identical(other.fulfilmentTypeLabel, fulfilmentTypeLabel) || other.fulfilmentTypeLabel == fulfilmentTypeLabel)&&(identical(other.isOfficePickup, isOfficePickup) || other.isOfficePickup == isOfficePickup)&&(identical(other.designSourceLabel, designSourceLabel) || other.designSourceLabel == designSourceLabel)&&(identical(other.itemsTotal, itemsTotal) || other.itemsTotal == itemsTotal)&&(identical(other.designFee, designFee) || other.designFee == designFee)&&(identical(other.deliveryPrice, deliveryPrice) || other.deliveryPrice == deliveryPrice)&&(identical(other.discount, discount) || other.discount == discount)&&(identical(other.additionalCost, additionalCost) || other.additionalCost == additionalCost)&&(identical(other.additionalCostReason, additionalCostReason) || other.additionalCostReason == additionalCostReason)&&(identical(other.additionalCostReasonLabel, additionalCostReasonLabel) || other.additionalCostReasonLabel == additionalCostReasonLabel)&&(identical(other.additionalCostNote, additionalCostNote) || other.additionalCostNote == additionalCostNote)&&(identical(other.grandTotal, grandTotal) || other.grandTotal == grandTotal)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount)&&(identical(other.writtenOffAmount, writtenOffAmount) || other.writtenOffAmount == writtenOffAmount)&&(identical(other.remainingAmount, remainingAmount) || other.remainingAmount == remainingAmount)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.paymentStatusLabel, paymentStatusLabel) || other.paymentStatusLabel == paymentStatusLabel)&&(identical(other.hasUnrecordedMoney, hasUnrecordedMoney) || other.hasUnrecordedMoney == hasUnrecordedMoney)&&(identical(other.collectedAmount, collectedAmount) || other.collectedAmount == collectedAmount)&&(identical(other.customer, customer) || other.customer == customer)&&(identical(other.regionId, regionId) || other.regionId == regionId)&&(identical(other.customerShopId, customerShopId) || other.customerShopId == customerShopId)&&(identical(other.regionName, regionName) || other.regionName == regionName)&&(identical(other.customerShopName, customerShopName) || other.customerShopName == customerShopName)&&(identical(other.recipientName, recipientName) || other.recipientName == recipientName)&&(identical(other.recipientPhone, recipientPhone) || other.recipientPhone == recipientPhone)&&(identical(other.addressDetails, addressDetails) || other.addressDetails == addressDetails)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.shippingCompany, shippingCompany) || other.shippingCompany == shippingCompany)&&(identical(other.trackingNumber, trackingNumber) || other.trackingNumber == trackingNumber)&&(identical(other.courierPhone, courierPhone) || other.courierPhone == courierPhone)&&(identical(other.cancellationReason, cancellationReason) || other.cancellationReason == cancellationReason)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.itemsAreEditable, itemsAreEditable) || other.itemsAreEditable == itemsAreEditable)&&(identical(other.designsAreEditable, designsAreEditable) || other.designsAreEditable == designsAreEditable)&&(identical(other.destinationIsEditable, destinationIsEditable) || other.destinationIsEditable == destinationIsEditable)&&(identical(other.itemsCount, itemsCount) || other.itemsCount == itemsCount)&&const DeepCollectionEquality().equals(other._items, _items)&&const DeepCollectionEquality().equals(other._designs, _designs)&&const DeepCollectionEquality().equals(other._transitions, _transitions)&&(identical(other.totalCogs, totalCogs) || other.totalCogs == totalCogs)&&(identical(other.grossProfit, grossProfit) || other.grossProfit == grossProfit)&&(identical(other.fulfillmentWarehouseId, fulfillmentWarehouseId) || other.fulfillmentWarehouseId == fulfillmentWarehouseId)&&(identical(other.stockDeductedAt, stockDeductedAt) || other.stockDeductedAt == stockDeductedAt)&&(identical(other.placedAt, placedAt) || other.placedAt == placedAt)&&(identical(other.deliveredAt, deliveredAt) || other.deliveredAt == deliveredAt)&&(identical(other.settledAt, settledAt) || other.settledAt == settledAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,code,status,statusLabel,productionFlowLabel,isFinal,isClosed,const DeepCollectionEquality().hash(_availableTransitions),customerId,cityId,designSource,cityName,fulfilmentTypeLabel,isOfficePickup,designSourceLabel,itemsTotal,designFee,deliveryPrice,discount,additionalCost,additionalCostReason,additionalCostReasonLabel,additionalCostNote,grandTotal,paidAmount,writtenOffAmount,remainingAmount,paymentStatus,paymentStatusLabel,hasUnrecordedMoney,collectedAmount,customer,regionId,customerShopId,regionName,customerShopName,recipientName,recipientPhone,addressDetails,notes,shippingCompany,trackingNumber,courierPhone,cancellationReason,progress,itemsAreEditable,designsAreEditable,destinationIsEditable,itemsCount,const DeepCollectionEquality().hash(_items),const DeepCollectionEquality().hash(_designs),const DeepCollectionEquality().hash(_transitions),totalCogs,grossProfit,fulfillmentWarehouseId,stockDeductedAt,placedAt,deliveredAt,settledAt,createdAt]);

@override
String toString() {
  return 'Order(id: $id, code: $code, status: $status, statusLabel: $statusLabel, productionFlowLabel: $productionFlowLabel, isFinal: $isFinal, isClosed: $isClosed, availableTransitions: $availableTransitions, customerId: $customerId, cityId: $cityId, designSource: $designSource, cityName: $cityName, fulfilmentTypeLabel: $fulfilmentTypeLabel, isOfficePickup: $isOfficePickup, designSourceLabel: $designSourceLabel, itemsTotal: $itemsTotal, designFee: $designFee, deliveryPrice: $deliveryPrice, discount: $discount, additionalCost: $additionalCost, additionalCostReason: $additionalCostReason, additionalCostReasonLabel: $additionalCostReasonLabel, additionalCostNote: $additionalCostNote, grandTotal: $grandTotal, paidAmount: $paidAmount, writtenOffAmount: $writtenOffAmount, remainingAmount: $remainingAmount, paymentStatus: $paymentStatus, paymentStatusLabel: $paymentStatusLabel, hasUnrecordedMoney: $hasUnrecordedMoney, collectedAmount: $collectedAmount, customer: $customer, regionId: $regionId, customerShopId: $customerShopId, regionName: $regionName, customerShopName: $customerShopName, recipientName: $recipientName, recipientPhone: $recipientPhone, addressDetails: $addressDetails, notes: $notes, shippingCompany: $shippingCompany, trackingNumber: $trackingNumber, courierPhone: $courierPhone, cancellationReason: $cancellationReason, progress: $progress, itemsAreEditable: $itemsAreEditable, designsAreEditable: $designsAreEditable, destinationIsEditable: $destinationIsEditable, itemsCount: $itemsCount, items: $items, designs: $designs, transitions: $transitions, totalCogs: $totalCogs, grossProfit: $grossProfit, fulfillmentWarehouseId: $fulfillmentWarehouseId, stockDeductedAt: $stockDeductedAt, placedAt: $placedAt, deliveredAt: $deliveredAt, settledAt: $settledAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$OrderCopyWith<$Res> implements $OrderCopyWith<$Res> {
  factory _$OrderCopyWith(_Order value, $Res Function(_Order) _then) = __$OrderCopyWithImpl;
@override @useResult
$Res call({
 int id, String code,@JsonKey(unknownEnumValue: OrderStatus.unknown) OrderStatus status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'production_flow_label') String productionFlowLabel,@JsonKey(name: 'is_final') bool isFinal,@JsonKey(name: 'is_closed') bool isClosed,@JsonKey(name: 'available_transitions') List<OrderTransition> availableTransitions,@JsonKey(name: 'customer_id') int customerId,@JsonKey(name: 'city_id') int cityId,@JsonKey(name: 'design_source') String designSource,@JsonKey(name: 'city_name') String cityName,@JsonKey(name: 'fulfilment_type_label') String fulfilmentTypeLabel,@JsonKey(name: 'is_office_pickup') bool isOfficePickup,@JsonKey(name: 'design_source_label') String designSourceLabel,@JsonKey(name: 'items_total') String itemsTotal,@JsonKey(name: 'design_fee') String designFee,@JsonKey(name: 'delivery_price') String deliveryPrice, String discount,@JsonKey(name: 'additional_cost') String additionalCost,@JsonKey(name: 'additional_cost_reason', unknownEnumValue: AdditionalCostReason.unknown) AdditionalCostReason? additionalCostReason,@JsonKey(name: 'additional_cost_reason_label') String? additionalCostReasonLabel,@JsonKey(name: 'additional_cost_note') String? additionalCostNote,@JsonKey(name: 'grand_total') String grandTotal,@JsonKey(name: 'paid_amount') String paidAmount,@JsonKey(name: 'written_off_amount') String writtenOffAmount,@JsonKey(name: 'remaining_amount') String remainingAmount,@JsonKey(name: 'payment_status', unknownEnumValue: PaymentStatus.unknown) PaymentStatus paymentStatus,@JsonKey(name: 'payment_status_label') String paymentStatusLabel,@JsonKey(name: 'has_unrecorded_money') bool hasUnrecordedMoney,@JsonKey(name: 'collected_amount') String? collectedAmount, Customer? customer,@JsonKey(name: 'region_id') int? regionId,@JsonKey(name: 'customer_shop_id') int? customerShopId,@JsonKey(name: 'region_name') String? regionName,@JsonKey(name: 'customer_shop_name') String? customerShopName,@JsonKey(name: 'recipient_name') String? recipientName,@JsonKey(name: 'recipient_phone') String? recipientPhone,@JsonKey(name: 'address_details') String? addressDetails, String? notes,@JsonKey(name: 'shipping_company') String? shippingCompany,@JsonKey(name: 'tracking_number') String? trackingNumber,@JsonKey(name: 'courier_phone') String? courierPhone,@JsonKey(name: 'cancellation_reason') String? cancellationReason, OrderProgress progress,@JsonKey(name: 'items_are_editable') bool itemsAreEditable,@JsonKey(name: 'designs_are_editable') bool designsAreEditable,@JsonKey(name: 'destination_is_editable') bool destinationIsEditable,@JsonKey(name: 'items_count') int? itemsCount, List<OrderItem>? items, List<OrderDesign>? designs, List<OrderTransitionRecord>? transitions,@JsonKey(name: 'total_cogs') String? totalCogs,@JsonKey(name: 'gross_profit') String? grossProfit,@JsonKey(name: 'fulfillment_warehouse_id') int? fulfillmentWarehouseId,@JsonKey(name: 'stock_deducted_at') DateTime? stockDeductedAt,@JsonKey(name: 'placed_at') DateTime? placedAt,@JsonKey(name: 'delivered_at') DateTime? deliveredAt,@JsonKey(name: 'settled_at') DateTime? settledAt,@JsonKey(name: 'created_at') DateTime? createdAt
});


@override $CustomerCopyWith<$Res>? get customer;@override $OrderProgressCopyWith<$Res> get progress;

}
/// @nodoc
class __$OrderCopyWithImpl<$Res>
    implements _$OrderCopyWith<$Res> {
  __$OrderCopyWithImpl(this._self, this._then);

  final _Order _self;
  final $Res Function(_Order) _then;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? status = null,Object? statusLabel = null,Object? productionFlowLabel = null,Object? isFinal = null,Object? isClosed = null,Object? availableTransitions = null,Object? customerId = null,Object? cityId = null,Object? designSource = null,Object? cityName = null,Object? fulfilmentTypeLabel = null,Object? isOfficePickup = null,Object? designSourceLabel = null,Object? itemsTotal = null,Object? designFee = null,Object? deliveryPrice = null,Object? discount = null,Object? additionalCost = null,Object? additionalCostReason = freezed,Object? additionalCostReasonLabel = freezed,Object? additionalCostNote = freezed,Object? grandTotal = null,Object? paidAmount = null,Object? writtenOffAmount = null,Object? remainingAmount = null,Object? paymentStatus = null,Object? paymentStatusLabel = null,Object? hasUnrecordedMoney = null,Object? collectedAmount = freezed,Object? customer = freezed,Object? regionId = freezed,Object? customerShopId = freezed,Object? regionName = freezed,Object? customerShopName = freezed,Object? recipientName = freezed,Object? recipientPhone = freezed,Object? addressDetails = freezed,Object? notes = freezed,Object? shippingCompany = freezed,Object? trackingNumber = freezed,Object? courierPhone = freezed,Object? cancellationReason = freezed,Object? progress = null,Object? itemsAreEditable = null,Object? designsAreEditable = null,Object? destinationIsEditable = null,Object? itemsCount = freezed,Object? items = freezed,Object? designs = freezed,Object? transitions = freezed,Object? totalCogs = freezed,Object? grossProfit = freezed,Object? fulfillmentWarehouseId = freezed,Object? stockDeductedAt = freezed,Object? placedAt = freezed,Object? deliveredAt = freezed,Object? settledAt = freezed,Object? createdAt = freezed,}) {
  return _then(_Order(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,productionFlowLabel: null == productionFlowLabel ? _self.productionFlowLabel : productionFlowLabel // ignore: cast_nullable_to_non_nullable
as String,isFinal: null == isFinal ? _self.isFinal : isFinal // ignore: cast_nullable_to_non_nullable
as bool,isClosed: null == isClosed ? _self.isClosed : isClosed // ignore: cast_nullable_to_non_nullable
as bool,availableTransitions: null == availableTransitions ? _self._availableTransitions : availableTransitions // ignore: cast_nullable_to_non_nullable
as List<OrderTransition>,customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as int,cityId: null == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as int,designSource: null == designSource ? _self.designSource : designSource // ignore: cast_nullable_to_non_nullable
as String,cityName: null == cityName ? _self.cityName : cityName // ignore: cast_nullable_to_non_nullable
as String,fulfilmentTypeLabel: null == fulfilmentTypeLabel ? _self.fulfilmentTypeLabel : fulfilmentTypeLabel // ignore: cast_nullable_to_non_nullable
as String,isOfficePickup: null == isOfficePickup ? _self.isOfficePickup : isOfficePickup // ignore: cast_nullable_to_non_nullable
as bool,designSourceLabel: null == designSourceLabel ? _self.designSourceLabel : designSourceLabel // ignore: cast_nullable_to_non_nullable
as String,itemsTotal: null == itemsTotal ? _self.itemsTotal : itemsTotal // ignore: cast_nullable_to_non_nullable
as String,designFee: null == designFee ? _self.designFee : designFee // ignore: cast_nullable_to_non_nullable
as String,deliveryPrice: null == deliveryPrice ? _self.deliveryPrice : deliveryPrice // ignore: cast_nullable_to_non_nullable
as String,discount: null == discount ? _self.discount : discount // ignore: cast_nullable_to_non_nullable
as String,additionalCost: null == additionalCost ? _self.additionalCost : additionalCost // ignore: cast_nullable_to_non_nullable
as String,additionalCostReason: freezed == additionalCostReason ? _self.additionalCostReason : additionalCostReason // ignore: cast_nullable_to_non_nullable
as AdditionalCostReason?,additionalCostReasonLabel: freezed == additionalCostReasonLabel ? _self.additionalCostReasonLabel : additionalCostReasonLabel // ignore: cast_nullable_to_non_nullable
as String?,additionalCostNote: freezed == additionalCostNote ? _self.additionalCostNote : additionalCostNote // ignore: cast_nullable_to_non_nullable
as String?,grandTotal: null == grandTotal ? _self.grandTotal : grandTotal // ignore: cast_nullable_to_non_nullable
as String,paidAmount: null == paidAmount ? _self.paidAmount : paidAmount // ignore: cast_nullable_to_non_nullable
as String,writtenOffAmount: null == writtenOffAmount ? _self.writtenOffAmount : writtenOffAmount // ignore: cast_nullable_to_non_nullable
as String,remainingAmount: null == remainingAmount ? _self.remainingAmount : remainingAmount // ignore: cast_nullable_to_non_nullable
as String,paymentStatus: null == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as PaymentStatus,paymentStatusLabel: null == paymentStatusLabel ? _self.paymentStatusLabel : paymentStatusLabel // ignore: cast_nullable_to_non_nullable
as String,hasUnrecordedMoney: null == hasUnrecordedMoney ? _self.hasUnrecordedMoney : hasUnrecordedMoney // ignore: cast_nullable_to_non_nullable
as bool,collectedAmount: freezed == collectedAmount ? _self.collectedAmount : collectedAmount // ignore: cast_nullable_to_non_nullable
as String?,customer: freezed == customer ? _self.customer : customer // ignore: cast_nullable_to_non_nullable
as Customer?,regionId: freezed == regionId ? _self.regionId : regionId // ignore: cast_nullable_to_non_nullable
as int?,customerShopId: freezed == customerShopId ? _self.customerShopId : customerShopId // ignore: cast_nullable_to_non_nullable
as int?,regionName: freezed == regionName ? _self.regionName : regionName // ignore: cast_nullable_to_non_nullable
as String?,customerShopName: freezed == customerShopName ? _self.customerShopName : customerShopName // ignore: cast_nullable_to_non_nullable
as String?,recipientName: freezed == recipientName ? _self.recipientName : recipientName // ignore: cast_nullable_to_non_nullable
as String?,recipientPhone: freezed == recipientPhone ? _self.recipientPhone : recipientPhone // ignore: cast_nullable_to_non_nullable
as String?,addressDetails: freezed == addressDetails ? _self.addressDetails : addressDetails // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,shippingCompany: freezed == shippingCompany ? _self.shippingCompany : shippingCompany // ignore: cast_nullable_to_non_nullable
as String?,trackingNumber: freezed == trackingNumber ? _self.trackingNumber : trackingNumber // ignore: cast_nullable_to_non_nullable
as String?,courierPhone: freezed == courierPhone ? _self.courierPhone : courierPhone // ignore: cast_nullable_to_non_nullable
as String?,cancellationReason: freezed == cancellationReason ? _self.cancellationReason : cancellationReason // ignore: cast_nullable_to_non_nullable
as String?,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as OrderProgress,itemsAreEditable: null == itemsAreEditable ? _self.itemsAreEditable : itemsAreEditable // ignore: cast_nullable_to_non_nullable
as bool,designsAreEditable: null == designsAreEditable ? _self.designsAreEditable : designsAreEditable // ignore: cast_nullable_to_non_nullable
as bool,destinationIsEditable: null == destinationIsEditable ? _self.destinationIsEditable : destinationIsEditable // ignore: cast_nullable_to_non_nullable
as bool,itemsCount: freezed == itemsCount ? _self.itemsCount : itemsCount // ignore: cast_nullable_to_non_nullable
as int?,items: freezed == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<OrderItem>?,designs: freezed == designs ? _self._designs : designs // ignore: cast_nullable_to_non_nullable
as List<OrderDesign>?,transitions: freezed == transitions ? _self._transitions : transitions // ignore: cast_nullable_to_non_nullable
as List<OrderTransitionRecord>?,totalCogs: freezed == totalCogs ? _self.totalCogs : totalCogs // ignore: cast_nullable_to_non_nullable
as String?,grossProfit: freezed == grossProfit ? _self.grossProfit : grossProfit // ignore: cast_nullable_to_non_nullable
as String?,fulfillmentWarehouseId: freezed == fulfillmentWarehouseId ? _self.fulfillmentWarehouseId : fulfillmentWarehouseId // ignore: cast_nullable_to_non_nullable
as int?,stockDeductedAt: freezed == stockDeductedAt ? _self.stockDeductedAt : stockDeductedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,placedAt: freezed == placedAt ? _self.placedAt : placedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,deliveredAt: freezed == deliveredAt ? _self.deliveredAt : deliveredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,settledAt: freezed == settledAt ? _self.settledAt : settledAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CustomerCopyWith<$Res>? get customer {
    if (_self.customer == null) {
    return null;
  }

  return $CustomerCopyWith<$Res>(_self.customer!, (value) {
    return _then(_self.copyWith(customer: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderProgressCopyWith<$Res> get progress {
  
  return $OrderProgressCopyWith<$Res>(_self.progress, (value) {
    return _then(_self.copyWith(progress: value));
  });
}
}


/// @nodoc
mixin _$OrderProgress {

 List<OrderStep> get steps;/// The order is somewhere real that is not on the route — a shortage, a return, a
/// cancellation. The bar shows how far it got and stops claiming it is *on* the line.
@JsonKey(name: 'is_detour') bool get isDetour;
/// Create a copy of OrderProgress
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderProgressCopyWith<OrderProgress> get copyWith => _$OrderProgressCopyWithImpl<OrderProgress>(this as OrderProgress, _$identity);

  /// Serializes this OrderProgress to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderProgress&&const DeepCollectionEquality().equals(other.steps, steps)&&(identical(other.isDetour, isDetour) || other.isDetour == isDetour));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(steps),isDetour);

@override
String toString() {
  return 'OrderProgress(steps: $steps, isDetour: $isDetour)';
}


}

/// @nodoc
abstract mixin class $OrderProgressCopyWith<$Res>  {
  factory $OrderProgressCopyWith(OrderProgress value, $Res Function(OrderProgress) _then) = _$OrderProgressCopyWithImpl;
@useResult
$Res call({
 List<OrderStep> steps,@JsonKey(name: 'is_detour') bool isDetour
});




}
/// @nodoc
class _$OrderProgressCopyWithImpl<$Res>
    implements $OrderProgressCopyWith<$Res> {
  _$OrderProgressCopyWithImpl(this._self, this._then);

  final OrderProgress _self;
  final $Res Function(OrderProgress) _then;

/// Create a copy of OrderProgress
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? steps = null,Object? isDetour = null,}) {
  return _then(_self.copyWith(
steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as List<OrderStep>,isDetour: null == isDetour ? _self.isDetour : isDetour // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderProgress].
extension OrderProgressPatterns on OrderProgress {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderProgress value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderProgress() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderProgress value)  $default,){
final _that = this;
switch (_that) {
case _OrderProgress():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderProgress value)?  $default,){
final _that = this;
switch (_that) {
case _OrderProgress() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<OrderStep> steps, @JsonKey(name: 'is_detour')  bool isDetour)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderProgress() when $default != null:
return $default(_that.steps,_that.isDetour);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<OrderStep> steps, @JsonKey(name: 'is_detour')  bool isDetour)  $default,) {final _that = this;
switch (_that) {
case _OrderProgress():
return $default(_that.steps,_that.isDetour);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<OrderStep> steps, @JsonKey(name: 'is_detour')  bool isDetour)?  $default,) {final _that = this;
switch (_that) {
case _OrderProgress() when $default != null:
return $default(_that.steps,_that.isDetour);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderProgress extends OrderProgress {
  const _OrderProgress({final  List<OrderStep> steps = const <OrderStep>[], @JsonKey(name: 'is_detour') this.isDetour = false}): _steps = steps,super._();
  factory _OrderProgress.fromJson(Map<String, dynamic> json) => _$OrderProgressFromJson(json);

 final  List<OrderStep> _steps;
@override@JsonKey() List<OrderStep> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}

/// The order is somewhere real that is not on the route — a shortage, a return, a
/// cancellation. The bar shows how far it got and stops claiming it is *on* the line.
@override@JsonKey(name: 'is_detour') final  bool isDetour;

/// Create a copy of OrderProgress
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderProgressCopyWith<_OrderProgress> get copyWith => __$OrderProgressCopyWithImpl<_OrderProgress>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderProgressToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderProgress&&const DeepCollectionEquality().equals(other._steps, _steps)&&(identical(other.isDetour, isDetour) || other.isDetour == isDetour));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_steps),isDetour);

@override
String toString() {
  return 'OrderProgress(steps: $steps, isDetour: $isDetour)';
}


}

/// @nodoc
abstract mixin class _$OrderProgressCopyWith<$Res> implements $OrderProgressCopyWith<$Res> {
  factory _$OrderProgressCopyWith(_OrderProgress value, $Res Function(_OrderProgress) _then) = __$OrderProgressCopyWithImpl;
@override @useResult
$Res call({
 List<OrderStep> steps,@JsonKey(name: 'is_detour') bool isDetour
});




}
/// @nodoc
class __$OrderProgressCopyWithImpl<$Res>
    implements _$OrderProgressCopyWith<$Res> {
  __$OrderProgressCopyWithImpl(this._self, this._then);

  final _OrderProgress _self;
  final $Res Function(_OrderProgress) _then;

/// Create a copy of OrderProgress
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? steps = null,Object? isDetour = null,}) {
  return _then(_OrderProgress(
steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<OrderStep>,isDetour: null == isDetour ? _self.isDetour : isDetour // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$OrderStep {

 String get status; String get label;/// `done`, `current` or `upcoming`. A string rather than an enum: it is drawn, never
/// branched on for business meaning, and a fourth state added on the server should render
/// as neutral rather than fail to parse the order.
 String get state;
/// Create a copy of OrderStep
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderStepCopyWith<OrderStep> get copyWith => _$OrderStepCopyWithImpl<OrderStep>(this as OrderStep, _$identity);

  /// Serializes this OrderStep to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderStep&&(identical(other.status, status) || other.status == status)&&(identical(other.label, label) || other.label == label)&&(identical(other.state, state) || other.state == state));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,label,state);

@override
String toString() {
  return 'OrderStep(status: $status, label: $label, state: $state)';
}


}

/// @nodoc
abstract mixin class $OrderStepCopyWith<$Res>  {
  factory $OrderStepCopyWith(OrderStep value, $Res Function(OrderStep) _then) = _$OrderStepCopyWithImpl;
@useResult
$Res call({
 String status, String label, String state
});




}
/// @nodoc
class _$OrderStepCopyWithImpl<$Res>
    implements $OrderStepCopyWith<$Res> {
  _$OrderStepCopyWithImpl(this._self, this._then);

  final OrderStep _self;
  final $Res Function(OrderStep) _then;

/// Create a copy of OrderStep
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? label = null,Object? state = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderStep].
extension OrderStepPatterns on OrderStep {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderStep value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderStep() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderStep value)  $default,){
final _that = this;
switch (_that) {
case _OrderStep():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderStep value)?  $default,){
final _that = this;
switch (_that) {
case _OrderStep() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String status,  String label,  String state)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderStep() when $default != null:
return $default(_that.status,_that.label,_that.state);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String status,  String label,  String state)  $default,) {final _that = this;
switch (_that) {
case _OrderStep():
return $default(_that.status,_that.label,_that.state);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String status,  String label,  String state)?  $default,) {final _that = this;
switch (_that) {
case _OrderStep() when $default != null:
return $default(_that.status,_that.label,_that.state);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderStep extends OrderStep {
  const _OrderStep({required this.status, required this.label, required this.state}): super._();
  factory _OrderStep.fromJson(Map<String, dynamic> json) => _$OrderStepFromJson(json);

@override final  String status;
@override final  String label;
/// `done`, `current` or `upcoming`. A string rather than an enum: it is drawn, never
/// branched on for business meaning, and a fourth state added on the server should render
/// as neutral rather than fail to parse the order.
@override final  String state;

/// Create a copy of OrderStep
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderStepCopyWith<_OrderStep> get copyWith => __$OrderStepCopyWithImpl<_OrderStep>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderStepToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderStep&&(identical(other.status, status) || other.status == status)&&(identical(other.label, label) || other.label == label)&&(identical(other.state, state) || other.state == state));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,label,state);

@override
String toString() {
  return 'OrderStep(status: $status, label: $label, state: $state)';
}


}

/// @nodoc
abstract mixin class _$OrderStepCopyWith<$Res> implements $OrderStepCopyWith<$Res> {
  factory _$OrderStepCopyWith(_OrderStep value, $Res Function(_OrderStep) _then) = __$OrderStepCopyWithImpl;
@override @useResult
$Res call({
 String status, String label, String state
});




}
/// @nodoc
class __$OrderStepCopyWithImpl<$Res>
    implements _$OrderStepCopyWith<$Res> {
  __$OrderStepCopyWithImpl(this._self, this._then);

  final _OrderStep _self;
  final $Res Function(_OrderStep) _then;

/// Create a copy of OrderStep
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? label = null,Object? state = null,}) {
  return _then(_OrderStep(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,state: null == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$OrderTransition {

@JsonKey(unknownEnumValue: OrderStatus.unknown) OrderStatus get status; String get label;/// Cancelling is the only one today. Kept beside [fields], which now carries the reason as
/// a field of its own — this stays for the clients written before that existed.
@JsonKey(name: 'requires_reason') bool get requiresReason;/// What this move asks for, written by the server for *this* order.
///
/// An order with no design step is asked for no artwork; one that already carries a version
/// is offered another rather than made to supply one. The screen renders these and keeps no
/// list of its own — see [TransitionField].
 List<TransitionField> get fields;
/// Create a copy of OrderTransition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderTransitionCopyWith<OrderTransition> get copyWith => _$OrderTransitionCopyWithImpl<OrderTransition>(this as OrderTransition, _$identity);

  /// Serializes this OrderTransition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderTransition&&(identical(other.status, status) || other.status == status)&&(identical(other.label, label) || other.label == label)&&(identical(other.requiresReason, requiresReason) || other.requiresReason == requiresReason)&&const DeepCollectionEquality().equals(other.fields, fields));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,label,requiresReason,const DeepCollectionEquality().hash(fields));

@override
String toString() {
  return 'OrderTransition(status: $status, label: $label, requiresReason: $requiresReason, fields: $fields)';
}


}

/// @nodoc
abstract mixin class $OrderTransitionCopyWith<$Res>  {
  factory $OrderTransitionCopyWith(OrderTransition value, $Res Function(OrderTransition) _then) = _$OrderTransitionCopyWithImpl;
@useResult
$Res call({
@JsonKey(unknownEnumValue: OrderStatus.unknown) OrderStatus status, String label,@JsonKey(name: 'requires_reason') bool requiresReason, List<TransitionField> fields
});




}
/// @nodoc
class _$OrderTransitionCopyWithImpl<$Res>
    implements $OrderTransitionCopyWith<$Res> {
  _$OrderTransitionCopyWithImpl(this._self, this._then);

  final OrderTransition _self;
  final $Res Function(OrderTransition) _then;

/// Create a copy of OrderTransition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? label = null,Object? requiresReason = null,Object? fields = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,requiresReason: null == requiresReason ? _self.requiresReason : requiresReason // ignore: cast_nullable_to_non_nullable
as bool,fields: null == fields ? _self.fields : fields // ignore: cast_nullable_to_non_nullable
as List<TransitionField>,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderTransition].
extension OrderTransitionPatterns on OrderTransition {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderTransition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderTransition() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderTransition value)  $default,){
final _that = this;
switch (_that) {
case _OrderTransition():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderTransition value)?  $default,){
final _that = this;
switch (_that) {
case _OrderTransition() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: OrderStatus.unknown)  OrderStatus status,  String label, @JsonKey(name: 'requires_reason')  bool requiresReason,  List<TransitionField> fields)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderTransition() when $default != null:
return $default(_that.status,_that.label,_that.requiresReason,_that.fields);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: OrderStatus.unknown)  OrderStatus status,  String label, @JsonKey(name: 'requires_reason')  bool requiresReason,  List<TransitionField> fields)  $default,) {final _that = this;
switch (_that) {
case _OrderTransition():
return $default(_that.status,_that.label,_that.requiresReason,_that.fields);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(unknownEnumValue: OrderStatus.unknown)  OrderStatus status,  String label, @JsonKey(name: 'requires_reason')  bool requiresReason,  List<TransitionField> fields)?  $default,) {final _that = this;
switch (_that) {
case _OrderTransition() when $default != null:
return $default(_that.status,_that.label,_that.requiresReason,_that.fields);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderTransition extends OrderTransition {
  const _OrderTransition({@JsonKey(unknownEnumValue: OrderStatus.unknown) required this.status, required this.label, @JsonKey(name: 'requires_reason') this.requiresReason = false, final  List<TransitionField> fields = const <TransitionField>[]}): _fields = fields,super._();
  factory _OrderTransition.fromJson(Map<String, dynamic> json) => _$OrderTransitionFromJson(json);

@override@JsonKey(unknownEnumValue: OrderStatus.unknown) final  OrderStatus status;
@override final  String label;
/// Cancelling is the only one today. Kept beside [fields], which now carries the reason as
/// a field of its own — this stays for the clients written before that existed.
@override@JsonKey(name: 'requires_reason') final  bool requiresReason;
/// What this move asks for, written by the server for *this* order.
///
/// An order with no design step is asked for no artwork; one that already carries a version
/// is offered another rather than made to supply one. The screen renders these and keeps no
/// list of its own — see [TransitionField].
 final  List<TransitionField> _fields;
/// What this move asks for, written by the server for *this* order.
///
/// An order with no design step is asked for no artwork; one that already carries a version
/// is offered another rather than made to supply one. The screen renders these and keeps no
/// list of its own — see [TransitionField].
@override@JsonKey() List<TransitionField> get fields {
  if (_fields is EqualUnmodifiableListView) return _fields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fields);
}


/// Create a copy of OrderTransition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderTransitionCopyWith<_OrderTransition> get copyWith => __$OrderTransitionCopyWithImpl<_OrderTransition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderTransitionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderTransition&&(identical(other.status, status) || other.status == status)&&(identical(other.label, label) || other.label == label)&&(identical(other.requiresReason, requiresReason) || other.requiresReason == requiresReason)&&const DeepCollectionEquality().equals(other._fields, _fields));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,label,requiresReason,const DeepCollectionEquality().hash(_fields));

@override
String toString() {
  return 'OrderTransition(status: $status, label: $label, requiresReason: $requiresReason, fields: $fields)';
}


}

/// @nodoc
abstract mixin class _$OrderTransitionCopyWith<$Res> implements $OrderTransitionCopyWith<$Res> {
  factory _$OrderTransitionCopyWith(_OrderTransition value, $Res Function(_OrderTransition) _then) = __$OrderTransitionCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(unknownEnumValue: OrderStatus.unknown) OrderStatus status, String label,@JsonKey(name: 'requires_reason') bool requiresReason, List<TransitionField> fields
});




}
/// @nodoc
class __$OrderTransitionCopyWithImpl<$Res>
    implements _$OrderTransitionCopyWith<$Res> {
  __$OrderTransitionCopyWithImpl(this._self, this._then);

  final _OrderTransition _self;
  final $Res Function(_OrderTransition) _then;

/// Create a copy of OrderTransition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? label = null,Object? requiresReason = null,Object? fields = null,}) {
  return _then(_OrderTransition(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,requiresReason: null == requiresReason ? _self.requiresReason : requiresReason // ignore: cast_nullable_to_non_nullable
as bool,fields: null == fields ? _self._fields : fields // ignore: cast_nullable_to_non_nullable
as List<TransitionField>,
  ));
}


}


/// @nodoc
mixin _$OrderItem {

 int get id;@JsonKey(name: 'product_id') int get productId;@JsonKey(name: 'product_variant_id') int get productVariantId;/// The snapshot, not the catalogue. A product renamed since must not rewrite this invoice.
@JsonKey(name: 'product_name') String get productName;@JsonKey(name: 'variant_label') String get variantLabel;/// The live catalogue row behind the line, for the card that opens it.
///
/// **Both null on a list payload**, which carries the lines without their products, and on a
/// server too old to send them — so the card falls back to the snapshot above and stops
/// advertising a picture it does not have. Never mistaken for the snapshot: a product
/// renamed or rephotographed since shows its new face here while the invoice keeps saying
/// what was sold.
@JsonKey(name: 'product_code') String? get productCode;@JsonKey(name: 'product_image') ProductImage? get productImage;@JsonKey(name: 'pricing_unit_label') String get pricingUnitLabel; String get quantity;/// What is missing from this line, in this line's own unit. Null until somebody has counted
/// — which is not the same as nothing being missing.
@JsonKey(name: 'shortage_quantity') String? get shortageQuantity;/// What the line is actually charged for: [quantity] less [shortageQuantity].
///
/// Sent by the server rather than subtracted here, because which quantity an invoice is
/// built on is a rule and rules live in one place. Null only from a server too old to send
/// it — see [pricedQuantity].
@JsonKey(name: 'billable_quantity') String? get billableQuantity;/// How much of the warehouse's own unit this line takes off the shelf.
///
/// **Null is the ordinary case and means «نفس وحدة البيع»** — the press deducts [quantity]
/// unchanged. A value here is the exception the scale creates: forty bags sold by the piece
/// may weigh ten kilos together, and the shelf is counted in kilos. It is the total for the
/// whole line, read off a scale, not a per-piece factor — a batch is weighed together, not
/// counted.
@JsonKey(name: 'warehouse_quantity') String? get warehouseQuantity;@JsonKey(name: 'unit_price') String get unitPrice;@JsonKey(name: 'line_total') String get lineTotal;/// The accrual side of [lineTotal]: what this line cost to make, split three ways and
/// summed. **All four null until the line has reached «جاهزة»** — a line nobody has
/// finished has no cost, which is not a cost of zero.
@JsonKey(name: 'material_cost') String? get materialCost;@JsonKey(name: 'labor_cost') String? get laborCost;@JsonKey(name: 'overhead_cost') String? get overheadCost;/// The three above, added up by the server. Read rather than summed here for the same reason
/// [billableQuantity] is.
 String? get cogs;/// The rate behind [materialCost]: what one unit off the shelf cost us.
///
/// **Divided by the server, not here.** `1234.56 / 3` in Dart is `411.51999999999998`, and
/// every other figure on this screen is a string the server chose the decimals of. Null
/// whenever [materialCost] is.
@JsonKey(name: 'unit_material_cost') String? get unitMaterialCost;/// The unit [unitMaterialCost] is *per* — **the warehouse's, which need not be the one the
/// line was sold in.** 300 bags weighed 12.5 kilos onto the order cost what those kilos
/// cost, and «تكلفة القطعة» printed over a per-kilo rate is a wrong number, not a rounded
/// one. Null on a payload that carries no shelf — a list, or a server too old to send it —
/// in which case there is no per-unit figure to label either.
@JsonKey(name: 'stock_unit_label') String? get stockUnitLabel; String? get notes;
/// Create a copy of OrderItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderItemCopyWith<OrderItem> get copyWith => _$OrderItemCopyWithImpl<OrderItem>(this as OrderItem, _$identity);

  /// Serializes this OrderItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderItem&&(identical(other.id, id) || other.id == id)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productVariantId, productVariantId) || other.productVariantId == productVariantId)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.variantLabel, variantLabel) || other.variantLabel == variantLabel)&&(identical(other.productCode, productCode) || other.productCode == productCode)&&(identical(other.productImage, productImage) || other.productImage == productImage)&&(identical(other.pricingUnitLabel, pricingUnitLabel) || other.pricingUnitLabel == pricingUnitLabel)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.shortageQuantity, shortageQuantity) || other.shortageQuantity == shortageQuantity)&&(identical(other.billableQuantity, billableQuantity) || other.billableQuantity == billableQuantity)&&(identical(other.warehouseQuantity, warehouseQuantity) || other.warehouseQuantity == warehouseQuantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.lineTotal, lineTotal) || other.lineTotal == lineTotal)&&(identical(other.materialCost, materialCost) || other.materialCost == materialCost)&&(identical(other.laborCost, laborCost) || other.laborCost == laborCost)&&(identical(other.overheadCost, overheadCost) || other.overheadCost == overheadCost)&&(identical(other.cogs, cogs) || other.cogs == cogs)&&(identical(other.unitMaterialCost, unitMaterialCost) || other.unitMaterialCost == unitMaterialCost)&&(identical(other.stockUnitLabel, stockUnitLabel) || other.stockUnitLabel == stockUnitLabel)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,productId,productVariantId,productName,variantLabel,productCode,productImage,pricingUnitLabel,quantity,shortageQuantity,billableQuantity,warehouseQuantity,unitPrice,lineTotal,materialCost,laborCost,overheadCost,cogs,unitMaterialCost,stockUnitLabel,notes]);

@override
String toString() {
  return 'OrderItem(id: $id, productId: $productId, productVariantId: $productVariantId, productName: $productName, variantLabel: $variantLabel, productCode: $productCode, productImage: $productImage, pricingUnitLabel: $pricingUnitLabel, quantity: $quantity, shortageQuantity: $shortageQuantity, billableQuantity: $billableQuantity, warehouseQuantity: $warehouseQuantity, unitPrice: $unitPrice, lineTotal: $lineTotal, materialCost: $materialCost, laborCost: $laborCost, overheadCost: $overheadCost, cogs: $cogs, unitMaterialCost: $unitMaterialCost, stockUnitLabel: $stockUnitLabel, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $OrderItemCopyWith<$Res>  {
  factory $OrderItemCopyWith(OrderItem value, $Res Function(OrderItem) _then) = _$OrderItemCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'product_id') int productId,@JsonKey(name: 'product_variant_id') int productVariantId,@JsonKey(name: 'product_name') String productName,@JsonKey(name: 'variant_label') String variantLabel,@JsonKey(name: 'product_code') String? productCode,@JsonKey(name: 'product_image') ProductImage? productImage,@JsonKey(name: 'pricing_unit_label') String pricingUnitLabel, String quantity,@JsonKey(name: 'shortage_quantity') String? shortageQuantity,@JsonKey(name: 'billable_quantity') String? billableQuantity,@JsonKey(name: 'warehouse_quantity') String? warehouseQuantity,@JsonKey(name: 'unit_price') String unitPrice,@JsonKey(name: 'line_total') String lineTotal,@JsonKey(name: 'material_cost') String? materialCost,@JsonKey(name: 'labor_cost') String? laborCost,@JsonKey(name: 'overhead_cost') String? overheadCost, String? cogs,@JsonKey(name: 'unit_material_cost') String? unitMaterialCost,@JsonKey(name: 'stock_unit_label') String? stockUnitLabel, String? notes
});


$ProductImageCopyWith<$Res>? get productImage;

}
/// @nodoc
class _$OrderItemCopyWithImpl<$Res>
    implements $OrderItemCopyWith<$Res> {
  _$OrderItemCopyWithImpl(this._self, this._then);

  final OrderItem _self;
  final $Res Function(OrderItem) _then;

/// Create a copy of OrderItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? productId = null,Object? productVariantId = null,Object? productName = null,Object? variantLabel = null,Object? productCode = freezed,Object? productImage = freezed,Object? pricingUnitLabel = null,Object? quantity = null,Object? shortageQuantity = freezed,Object? billableQuantity = freezed,Object? warehouseQuantity = freezed,Object? unitPrice = null,Object? lineTotal = null,Object? materialCost = freezed,Object? laborCost = freezed,Object? overheadCost = freezed,Object? cogs = freezed,Object? unitMaterialCost = freezed,Object? stockUnitLabel = freezed,Object? notes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as int,productVariantId: null == productVariantId ? _self.productVariantId : productVariantId // ignore: cast_nullable_to_non_nullable
as int,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,variantLabel: null == variantLabel ? _self.variantLabel : variantLabel // ignore: cast_nullable_to_non_nullable
as String,productCode: freezed == productCode ? _self.productCode : productCode // ignore: cast_nullable_to_non_nullable
as String?,productImage: freezed == productImage ? _self.productImage : productImage // ignore: cast_nullable_to_non_nullable
as ProductImage?,pricingUnitLabel: null == pricingUnitLabel ? _self.pricingUnitLabel : pricingUnitLabel // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,shortageQuantity: freezed == shortageQuantity ? _self.shortageQuantity : shortageQuantity // ignore: cast_nullable_to_non_nullable
as String?,billableQuantity: freezed == billableQuantity ? _self.billableQuantity : billableQuantity // ignore: cast_nullable_to_non_nullable
as String?,warehouseQuantity: freezed == warehouseQuantity ? _self.warehouseQuantity : warehouseQuantity // ignore: cast_nullable_to_non_nullable
as String?,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,lineTotal: null == lineTotal ? _self.lineTotal : lineTotal // ignore: cast_nullable_to_non_nullable
as String,materialCost: freezed == materialCost ? _self.materialCost : materialCost // ignore: cast_nullable_to_non_nullable
as String?,laborCost: freezed == laborCost ? _self.laborCost : laborCost // ignore: cast_nullable_to_non_nullable
as String?,overheadCost: freezed == overheadCost ? _self.overheadCost : overheadCost // ignore: cast_nullable_to_non_nullable
as String?,cogs: freezed == cogs ? _self.cogs : cogs // ignore: cast_nullable_to_non_nullable
as String?,unitMaterialCost: freezed == unitMaterialCost ? _self.unitMaterialCost : unitMaterialCost // ignore: cast_nullable_to_non_nullable
as String?,stockUnitLabel: freezed == stockUnitLabel ? _self.stockUnitLabel : stockUnitLabel // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of OrderItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProductImageCopyWith<$Res>? get productImage {
    if (_self.productImage == null) {
    return null;
  }

  return $ProductImageCopyWith<$Res>(_self.productImage!, (value) {
    return _then(_self.copyWith(productImage: value));
  });
}
}


/// Adds pattern-matching-related methods to [OrderItem].
extension OrderItemPatterns on OrderItem {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderItem() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderItem value)  $default,){
final _that = this;
switch (_that) {
case _OrderItem():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderItem value)?  $default,){
final _that = this;
switch (_that) {
case _OrderItem() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'product_id')  int productId, @JsonKey(name: 'product_variant_id')  int productVariantId, @JsonKey(name: 'product_name')  String productName, @JsonKey(name: 'variant_label')  String variantLabel, @JsonKey(name: 'product_code')  String? productCode, @JsonKey(name: 'product_image')  ProductImage? productImage, @JsonKey(name: 'pricing_unit_label')  String pricingUnitLabel,  String quantity, @JsonKey(name: 'shortage_quantity')  String? shortageQuantity, @JsonKey(name: 'billable_quantity')  String? billableQuantity, @JsonKey(name: 'warehouse_quantity')  String? warehouseQuantity, @JsonKey(name: 'unit_price')  String unitPrice, @JsonKey(name: 'line_total')  String lineTotal, @JsonKey(name: 'material_cost')  String? materialCost, @JsonKey(name: 'labor_cost')  String? laborCost, @JsonKey(name: 'overhead_cost')  String? overheadCost,  String? cogs, @JsonKey(name: 'unit_material_cost')  String? unitMaterialCost, @JsonKey(name: 'stock_unit_label')  String? stockUnitLabel,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderItem() when $default != null:
return $default(_that.id,_that.productId,_that.productVariantId,_that.productName,_that.variantLabel,_that.productCode,_that.productImage,_that.pricingUnitLabel,_that.quantity,_that.shortageQuantity,_that.billableQuantity,_that.warehouseQuantity,_that.unitPrice,_that.lineTotal,_that.materialCost,_that.laborCost,_that.overheadCost,_that.cogs,_that.unitMaterialCost,_that.stockUnitLabel,_that.notes);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'product_id')  int productId, @JsonKey(name: 'product_variant_id')  int productVariantId, @JsonKey(name: 'product_name')  String productName, @JsonKey(name: 'variant_label')  String variantLabel, @JsonKey(name: 'product_code')  String? productCode, @JsonKey(name: 'product_image')  ProductImage? productImage, @JsonKey(name: 'pricing_unit_label')  String pricingUnitLabel,  String quantity, @JsonKey(name: 'shortage_quantity')  String? shortageQuantity, @JsonKey(name: 'billable_quantity')  String? billableQuantity, @JsonKey(name: 'warehouse_quantity')  String? warehouseQuantity, @JsonKey(name: 'unit_price')  String unitPrice, @JsonKey(name: 'line_total')  String lineTotal, @JsonKey(name: 'material_cost')  String? materialCost, @JsonKey(name: 'labor_cost')  String? laborCost, @JsonKey(name: 'overhead_cost')  String? overheadCost,  String? cogs, @JsonKey(name: 'unit_material_cost')  String? unitMaterialCost, @JsonKey(name: 'stock_unit_label')  String? stockUnitLabel,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _OrderItem():
return $default(_that.id,_that.productId,_that.productVariantId,_that.productName,_that.variantLabel,_that.productCode,_that.productImage,_that.pricingUnitLabel,_that.quantity,_that.shortageQuantity,_that.billableQuantity,_that.warehouseQuantity,_that.unitPrice,_that.lineTotal,_that.materialCost,_that.laborCost,_that.overheadCost,_that.cogs,_that.unitMaterialCost,_that.stockUnitLabel,_that.notes);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'product_id')  int productId, @JsonKey(name: 'product_variant_id')  int productVariantId, @JsonKey(name: 'product_name')  String productName, @JsonKey(name: 'variant_label')  String variantLabel, @JsonKey(name: 'product_code')  String? productCode, @JsonKey(name: 'product_image')  ProductImage? productImage, @JsonKey(name: 'pricing_unit_label')  String pricingUnitLabel,  String quantity, @JsonKey(name: 'shortage_quantity')  String? shortageQuantity, @JsonKey(name: 'billable_quantity')  String? billableQuantity, @JsonKey(name: 'warehouse_quantity')  String? warehouseQuantity, @JsonKey(name: 'unit_price')  String unitPrice, @JsonKey(name: 'line_total')  String lineTotal, @JsonKey(name: 'material_cost')  String? materialCost, @JsonKey(name: 'labor_cost')  String? laborCost, @JsonKey(name: 'overhead_cost')  String? overheadCost,  String? cogs, @JsonKey(name: 'unit_material_cost')  String? unitMaterialCost, @JsonKey(name: 'stock_unit_label')  String? stockUnitLabel,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _OrderItem() when $default != null:
return $default(_that.id,_that.productId,_that.productVariantId,_that.productName,_that.variantLabel,_that.productCode,_that.productImage,_that.pricingUnitLabel,_that.quantity,_that.shortageQuantity,_that.billableQuantity,_that.warehouseQuantity,_that.unitPrice,_that.lineTotal,_that.materialCost,_that.laborCost,_that.overheadCost,_that.cogs,_that.unitMaterialCost,_that.stockUnitLabel,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderItem extends OrderItem {
  const _OrderItem({required this.id, @JsonKey(name: 'product_id') required this.productId, @JsonKey(name: 'product_variant_id') required this.productVariantId, @JsonKey(name: 'product_name') required this.productName, @JsonKey(name: 'variant_label') required this.variantLabel, @JsonKey(name: 'product_code') this.productCode, @JsonKey(name: 'product_image') this.productImage, @JsonKey(name: 'pricing_unit_label') required this.pricingUnitLabel, required this.quantity, @JsonKey(name: 'shortage_quantity') this.shortageQuantity, @JsonKey(name: 'billable_quantity') this.billableQuantity, @JsonKey(name: 'warehouse_quantity') this.warehouseQuantity, @JsonKey(name: 'unit_price') required this.unitPrice, @JsonKey(name: 'line_total') required this.lineTotal, @JsonKey(name: 'material_cost') this.materialCost, @JsonKey(name: 'labor_cost') this.laborCost, @JsonKey(name: 'overhead_cost') this.overheadCost, this.cogs, @JsonKey(name: 'unit_material_cost') this.unitMaterialCost, @JsonKey(name: 'stock_unit_label') this.stockUnitLabel, this.notes}): super._();
  factory _OrderItem.fromJson(Map<String, dynamic> json) => _$OrderItemFromJson(json);

@override final  int id;
@override@JsonKey(name: 'product_id') final  int productId;
@override@JsonKey(name: 'product_variant_id') final  int productVariantId;
/// The snapshot, not the catalogue. A product renamed since must not rewrite this invoice.
@override@JsonKey(name: 'product_name') final  String productName;
@override@JsonKey(name: 'variant_label') final  String variantLabel;
/// The live catalogue row behind the line, for the card that opens it.
///
/// **Both null on a list payload**, which carries the lines without their products, and on a
/// server too old to send them — so the card falls back to the snapshot above and stops
/// advertising a picture it does not have. Never mistaken for the snapshot: a product
/// renamed or rephotographed since shows its new face here while the invoice keeps saying
/// what was sold.
@override@JsonKey(name: 'product_code') final  String? productCode;
@override@JsonKey(name: 'product_image') final  ProductImage? productImage;
@override@JsonKey(name: 'pricing_unit_label') final  String pricingUnitLabel;
@override final  String quantity;
/// What is missing from this line, in this line's own unit. Null until somebody has counted
/// — which is not the same as nothing being missing.
@override@JsonKey(name: 'shortage_quantity') final  String? shortageQuantity;
/// What the line is actually charged for: [quantity] less [shortageQuantity].
///
/// Sent by the server rather than subtracted here, because which quantity an invoice is
/// built on is a rule and rules live in one place. Null only from a server too old to send
/// it — see [pricedQuantity].
@override@JsonKey(name: 'billable_quantity') final  String? billableQuantity;
/// How much of the warehouse's own unit this line takes off the shelf.
///
/// **Null is the ordinary case and means «نفس وحدة البيع»** — the press deducts [quantity]
/// unchanged. A value here is the exception the scale creates: forty bags sold by the piece
/// may weigh ten kilos together, and the shelf is counted in kilos. It is the total for the
/// whole line, read off a scale, not a per-piece factor — a batch is weighed together, not
/// counted.
@override@JsonKey(name: 'warehouse_quantity') final  String? warehouseQuantity;
@override@JsonKey(name: 'unit_price') final  String unitPrice;
@override@JsonKey(name: 'line_total') final  String lineTotal;
/// The accrual side of [lineTotal]: what this line cost to make, split three ways and
/// summed. **All four null until the line has reached «جاهزة»** — a line nobody has
/// finished has no cost, which is not a cost of zero.
@override@JsonKey(name: 'material_cost') final  String? materialCost;
@override@JsonKey(name: 'labor_cost') final  String? laborCost;
@override@JsonKey(name: 'overhead_cost') final  String? overheadCost;
/// The three above, added up by the server. Read rather than summed here for the same reason
/// [billableQuantity] is.
@override final  String? cogs;
/// The rate behind [materialCost]: what one unit off the shelf cost us.
///
/// **Divided by the server, not here.** `1234.56 / 3` in Dart is `411.51999999999998`, and
/// every other figure on this screen is a string the server chose the decimals of. Null
/// whenever [materialCost] is.
@override@JsonKey(name: 'unit_material_cost') final  String? unitMaterialCost;
/// The unit [unitMaterialCost] is *per* — **the warehouse's, which need not be the one the
/// line was sold in.** 300 bags weighed 12.5 kilos onto the order cost what those kilos
/// cost, and «تكلفة القطعة» printed over a per-kilo rate is a wrong number, not a rounded
/// one. Null on a payload that carries no shelf — a list, or a server too old to send it —
/// in which case there is no per-unit figure to label either.
@override@JsonKey(name: 'stock_unit_label') final  String? stockUnitLabel;
@override final  String? notes;

/// Create a copy of OrderItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderItemCopyWith<_OrderItem> get copyWith => __$OrderItemCopyWithImpl<_OrderItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderItem&&(identical(other.id, id) || other.id == id)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productVariantId, productVariantId) || other.productVariantId == productVariantId)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.variantLabel, variantLabel) || other.variantLabel == variantLabel)&&(identical(other.productCode, productCode) || other.productCode == productCode)&&(identical(other.productImage, productImage) || other.productImage == productImage)&&(identical(other.pricingUnitLabel, pricingUnitLabel) || other.pricingUnitLabel == pricingUnitLabel)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.shortageQuantity, shortageQuantity) || other.shortageQuantity == shortageQuantity)&&(identical(other.billableQuantity, billableQuantity) || other.billableQuantity == billableQuantity)&&(identical(other.warehouseQuantity, warehouseQuantity) || other.warehouseQuantity == warehouseQuantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.lineTotal, lineTotal) || other.lineTotal == lineTotal)&&(identical(other.materialCost, materialCost) || other.materialCost == materialCost)&&(identical(other.laborCost, laborCost) || other.laborCost == laborCost)&&(identical(other.overheadCost, overheadCost) || other.overheadCost == overheadCost)&&(identical(other.cogs, cogs) || other.cogs == cogs)&&(identical(other.unitMaterialCost, unitMaterialCost) || other.unitMaterialCost == unitMaterialCost)&&(identical(other.stockUnitLabel, stockUnitLabel) || other.stockUnitLabel == stockUnitLabel)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,productId,productVariantId,productName,variantLabel,productCode,productImage,pricingUnitLabel,quantity,shortageQuantity,billableQuantity,warehouseQuantity,unitPrice,lineTotal,materialCost,laborCost,overheadCost,cogs,unitMaterialCost,stockUnitLabel,notes]);

@override
String toString() {
  return 'OrderItem(id: $id, productId: $productId, productVariantId: $productVariantId, productName: $productName, variantLabel: $variantLabel, productCode: $productCode, productImage: $productImage, pricingUnitLabel: $pricingUnitLabel, quantity: $quantity, shortageQuantity: $shortageQuantity, billableQuantity: $billableQuantity, warehouseQuantity: $warehouseQuantity, unitPrice: $unitPrice, lineTotal: $lineTotal, materialCost: $materialCost, laborCost: $laborCost, overheadCost: $overheadCost, cogs: $cogs, unitMaterialCost: $unitMaterialCost, stockUnitLabel: $stockUnitLabel, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$OrderItemCopyWith<$Res> implements $OrderItemCopyWith<$Res> {
  factory _$OrderItemCopyWith(_OrderItem value, $Res Function(_OrderItem) _then) = __$OrderItemCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'product_id') int productId,@JsonKey(name: 'product_variant_id') int productVariantId,@JsonKey(name: 'product_name') String productName,@JsonKey(name: 'variant_label') String variantLabel,@JsonKey(name: 'product_code') String? productCode,@JsonKey(name: 'product_image') ProductImage? productImage,@JsonKey(name: 'pricing_unit_label') String pricingUnitLabel, String quantity,@JsonKey(name: 'shortage_quantity') String? shortageQuantity,@JsonKey(name: 'billable_quantity') String? billableQuantity,@JsonKey(name: 'warehouse_quantity') String? warehouseQuantity,@JsonKey(name: 'unit_price') String unitPrice,@JsonKey(name: 'line_total') String lineTotal,@JsonKey(name: 'material_cost') String? materialCost,@JsonKey(name: 'labor_cost') String? laborCost,@JsonKey(name: 'overhead_cost') String? overheadCost, String? cogs,@JsonKey(name: 'unit_material_cost') String? unitMaterialCost,@JsonKey(name: 'stock_unit_label') String? stockUnitLabel, String? notes
});


@override $ProductImageCopyWith<$Res>? get productImage;

}
/// @nodoc
class __$OrderItemCopyWithImpl<$Res>
    implements _$OrderItemCopyWith<$Res> {
  __$OrderItemCopyWithImpl(this._self, this._then);

  final _OrderItem _self;
  final $Res Function(_OrderItem) _then;

/// Create a copy of OrderItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? productId = null,Object? productVariantId = null,Object? productName = null,Object? variantLabel = null,Object? productCode = freezed,Object? productImage = freezed,Object? pricingUnitLabel = null,Object? quantity = null,Object? shortageQuantity = freezed,Object? billableQuantity = freezed,Object? warehouseQuantity = freezed,Object? unitPrice = null,Object? lineTotal = null,Object? materialCost = freezed,Object? laborCost = freezed,Object? overheadCost = freezed,Object? cogs = freezed,Object? unitMaterialCost = freezed,Object? stockUnitLabel = freezed,Object? notes = freezed,}) {
  return _then(_OrderItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as int,productVariantId: null == productVariantId ? _self.productVariantId : productVariantId // ignore: cast_nullable_to_non_nullable
as int,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,variantLabel: null == variantLabel ? _self.variantLabel : variantLabel // ignore: cast_nullable_to_non_nullable
as String,productCode: freezed == productCode ? _self.productCode : productCode // ignore: cast_nullable_to_non_nullable
as String?,productImage: freezed == productImage ? _self.productImage : productImage // ignore: cast_nullable_to_non_nullable
as ProductImage?,pricingUnitLabel: null == pricingUnitLabel ? _self.pricingUnitLabel : pricingUnitLabel // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,shortageQuantity: freezed == shortageQuantity ? _self.shortageQuantity : shortageQuantity // ignore: cast_nullable_to_non_nullable
as String?,billableQuantity: freezed == billableQuantity ? _self.billableQuantity : billableQuantity // ignore: cast_nullable_to_non_nullable
as String?,warehouseQuantity: freezed == warehouseQuantity ? _self.warehouseQuantity : warehouseQuantity // ignore: cast_nullable_to_non_nullable
as String?,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,lineTotal: null == lineTotal ? _self.lineTotal : lineTotal // ignore: cast_nullable_to_non_nullable
as String,materialCost: freezed == materialCost ? _self.materialCost : materialCost // ignore: cast_nullable_to_non_nullable
as String?,laborCost: freezed == laborCost ? _self.laborCost : laborCost // ignore: cast_nullable_to_non_nullable
as String?,overheadCost: freezed == overheadCost ? _self.overheadCost : overheadCost // ignore: cast_nullable_to_non_nullable
as String?,cogs: freezed == cogs ? _self.cogs : cogs // ignore: cast_nullable_to_non_nullable
as String?,unitMaterialCost: freezed == unitMaterialCost ? _self.unitMaterialCost : unitMaterialCost // ignore: cast_nullable_to_non_nullable
as String?,stockUnitLabel: freezed == stockUnitLabel ? _self.stockUnitLabel : stockUnitLabel // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of OrderItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProductImageCopyWith<$Res>? get productImage {
    if (_self.productImage == null) {
    return null;
  }

  return $ProductImageCopyWith<$Res>(_self.productImage!, (value) {
    return _then(_self.copyWith(productImage: value));
  });
}
}


/// @nodoc
mixin _$OrderDesign {

 int get id; int get version; String get status;@JsonKey(name: 'status_label') String get statusLabel;@JsonKey(name: 'is_reviewed') bool get isReviewed;/// The file this version points at, from the customer's library.
///
/// Pointed at, never copied — so what is shown here is the same row the library shows, and
/// `file_url` is the signed link the server minted for *this* request. Absent when the
/// endpoint did not load the relation.
 CustomerDesign? get design;@JsonKey(name: 'rejection_reason') String? get rejectionReason; String? get notes;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of OrderDesign
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderDesignCopyWith<OrderDesign> get copyWith => _$OrderDesignCopyWithImpl<OrderDesign>(this as OrderDesign, _$identity);

  /// Serializes this OrderDesign to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderDesign&&(identical(other.id, id) || other.id == id)&&(identical(other.version, version) || other.version == version)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.isReviewed, isReviewed) || other.isReviewed == isReviewed)&&(identical(other.design, design) || other.design == design)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,version,status,statusLabel,isReviewed,design,rejectionReason,notes,createdAt);

@override
String toString() {
  return 'OrderDesign(id: $id, version: $version, status: $status, statusLabel: $statusLabel, isReviewed: $isReviewed, design: $design, rejectionReason: $rejectionReason, notes: $notes, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $OrderDesignCopyWith<$Res>  {
  factory $OrderDesignCopyWith(OrderDesign value, $Res Function(OrderDesign) _then) = _$OrderDesignCopyWithImpl;
@useResult
$Res call({
 int id, int version, String status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'is_reviewed') bool isReviewed, CustomerDesign? design,@JsonKey(name: 'rejection_reason') String? rejectionReason, String? notes,@JsonKey(name: 'created_at') DateTime? createdAt
});


$CustomerDesignCopyWith<$Res>? get design;

}
/// @nodoc
class _$OrderDesignCopyWithImpl<$Res>
    implements $OrderDesignCopyWith<$Res> {
  _$OrderDesignCopyWithImpl(this._self, this._then);

  final OrderDesign _self;
  final $Res Function(OrderDesign) _then;

/// Create a copy of OrderDesign
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? version = null,Object? status = null,Object? statusLabel = null,Object? isReviewed = null,Object? design = freezed,Object? rejectionReason = freezed,Object? notes = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,isReviewed: null == isReviewed ? _self.isReviewed : isReviewed // ignore: cast_nullable_to_non_nullable
as bool,design: freezed == design ? _self.design : design // ignore: cast_nullable_to_non_nullable
as CustomerDesign?,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of OrderDesign
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CustomerDesignCopyWith<$Res>? get design {
    if (_self.design == null) {
    return null;
  }

  return $CustomerDesignCopyWith<$Res>(_self.design!, (value) {
    return _then(_self.copyWith(design: value));
  });
}
}


/// Adds pattern-matching-related methods to [OrderDesign].
extension OrderDesignPatterns on OrderDesign {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderDesign value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderDesign() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderDesign value)  $default,){
final _that = this;
switch (_that) {
case _OrderDesign():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderDesign value)?  $default,){
final _that = this;
switch (_that) {
case _OrderDesign() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int version,  String status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'is_reviewed')  bool isReviewed,  CustomerDesign? design, @JsonKey(name: 'rejection_reason')  String? rejectionReason,  String? notes, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderDesign() when $default != null:
return $default(_that.id,_that.version,_that.status,_that.statusLabel,_that.isReviewed,_that.design,_that.rejectionReason,_that.notes,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int version,  String status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'is_reviewed')  bool isReviewed,  CustomerDesign? design, @JsonKey(name: 'rejection_reason')  String? rejectionReason,  String? notes, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _OrderDesign():
return $default(_that.id,_that.version,_that.status,_that.statusLabel,_that.isReviewed,_that.design,_that.rejectionReason,_that.notes,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int version,  String status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'is_reviewed')  bool isReviewed,  CustomerDesign? design, @JsonKey(name: 'rejection_reason')  String? rejectionReason,  String? notes, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _OrderDesign() when $default != null:
return $default(_that.id,_that.version,_that.status,_that.statusLabel,_that.isReviewed,_that.design,_that.rejectionReason,_that.notes,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderDesign extends OrderDesign {
  const _OrderDesign({required this.id, required this.version, required this.status, @JsonKey(name: 'status_label') required this.statusLabel, @JsonKey(name: 'is_reviewed') this.isReviewed = false, this.design, @JsonKey(name: 'rejection_reason') this.rejectionReason, this.notes, @JsonKey(name: 'created_at') this.createdAt}): super._();
  factory _OrderDesign.fromJson(Map<String, dynamic> json) => _$OrderDesignFromJson(json);

@override final  int id;
@override final  int version;
@override final  String status;
@override@JsonKey(name: 'status_label') final  String statusLabel;
@override@JsonKey(name: 'is_reviewed') final  bool isReviewed;
/// The file this version points at, from the customer's library.
///
/// Pointed at, never copied — so what is shown here is the same row the library shows, and
/// `file_url` is the signed link the server minted for *this* request. Absent when the
/// endpoint did not load the relation.
@override final  CustomerDesign? design;
@override@JsonKey(name: 'rejection_reason') final  String? rejectionReason;
@override final  String? notes;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of OrderDesign
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderDesignCopyWith<_OrderDesign> get copyWith => __$OrderDesignCopyWithImpl<_OrderDesign>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderDesignToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderDesign&&(identical(other.id, id) || other.id == id)&&(identical(other.version, version) || other.version == version)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.isReviewed, isReviewed) || other.isReviewed == isReviewed)&&(identical(other.design, design) || other.design == design)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,version,status,statusLabel,isReviewed,design,rejectionReason,notes,createdAt);

@override
String toString() {
  return 'OrderDesign(id: $id, version: $version, status: $status, statusLabel: $statusLabel, isReviewed: $isReviewed, design: $design, rejectionReason: $rejectionReason, notes: $notes, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$OrderDesignCopyWith<$Res> implements $OrderDesignCopyWith<$Res> {
  factory _$OrderDesignCopyWith(_OrderDesign value, $Res Function(_OrderDesign) _then) = __$OrderDesignCopyWithImpl;
@override @useResult
$Res call({
 int id, int version, String status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'is_reviewed') bool isReviewed, CustomerDesign? design,@JsonKey(name: 'rejection_reason') String? rejectionReason, String? notes,@JsonKey(name: 'created_at') DateTime? createdAt
});


@override $CustomerDesignCopyWith<$Res>? get design;

}
/// @nodoc
class __$OrderDesignCopyWithImpl<$Res>
    implements _$OrderDesignCopyWith<$Res> {
  __$OrderDesignCopyWithImpl(this._self, this._then);

  final _OrderDesign _self;
  final $Res Function(_OrderDesign) _then;

/// Create a copy of OrderDesign
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? version = null,Object? status = null,Object? statusLabel = null,Object? isReviewed = null,Object? design = freezed,Object? rejectionReason = freezed,Object? notes = freezed,Object? createdAt = freezed,}) {
  return _then(_OrderDesign(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,isReviewed: null == isReviewed ? _self.isReviewed : isReviewed // ignore: cast_nullable_to_non_nullable
as bool,design: freezed == design ? _self.design : design // ignore: cast_nullable_to_non_nullable
as CustomerDesign?,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of OrderDesign
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CustomerDesignCopyWith<$Res>? get design {
    if (_self.design == null) {
    return null;
  }

  return $CustomerDesignCopyWith<$Res>(_self.design!, (value) {
    return _then(_self.copyWith(design: value));
  });
}
}


/// @nodoc
mixin _$OrderActor {

 int get id; String get name;
/// Create a copy of OrderActor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderActorCopyWith<OrderActor> get copyWith => _$OrderActorCopyWithImpl<OrderActor>(this as OrderActor, _$identity);

  /// Serializes this OrderActor to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderActor&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'OrderActor(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $OrderActorCopyWith<$Res>  {
  factory $OrderActorCopyWith(OrderActor value, $Res Function(OrderActor) _then) = _$OrderActorCopyWithImpl;
@useResult
$Res call({
 int id, String name
});




}
/// @nodoc
class _$OrderActorCopyWithImpl<$Res>
    implements $OrderActorCopyWith<$Res> {
  _$OrderActorCopyWithImpl(this._self, this._then);

  final OrderActor _self;
  final $Res Function(OrderActor) _then;

/// Create a copy of OrderActor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderActor].
extension OrderActorPatterns on OrderActor {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderActor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderActor() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderActor value)  $default,){
final _that = this;
switch (_that) {
case _OrderActor():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderActor value)?  $default,){
final _that = this;
switch (_that) {
case _OrderActor() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderActor() when $default != null:
return $default(_that.id,_that.name);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name)  $default,) {final _that = this;
switch (_that) {
case _OrderActor():
return $default(_that.id,_that.name);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name)?  $default,) {final _that = this;
switch (_that) {
case _OrderActor() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderActor implements OrderActor {
  const _OrderActor({required this.id, required this.name});
  factory _OrderActor.fromJson(Map<String, dynamic> json) => _$OrderActorFromJson(json);

@override final  int id;
@override final  String name;

/// Create a copy of OrderActor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderActorCopyWith<_OrderActor> get copyWith => __$OrderActorCopyWithImpl<_OrderActor>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderActorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderActor&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'OrderActor(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$OrderActorCopyWith<$Res> implements $OrderActorCopyWith<$Res> {
  factory _$OrderActorCopyWith(_OrderActor value, $Res Function(_OrderActor) _then) = __$OrderActorCopyWithImpl;
@override @useResult
$Res call({
 int id, String name
});




}
/// @nodoc
class __$OrderActorCopyWithImpl<$Res>
    implements _$OrderActorCopyWith<$Res> {
  __$OrderActorCopyWithImpl(this._self, this._then);

  final _OrderActor _self;
  final $Res Function(_OrderActor) _then;

/// Create a copy of OrderActor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_OrderActor(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$OrderTransitionRecord {

 int get id;/// Null exactly once per order: the row that records it being taken.
@JsonKey(name: 'from_status_label') String? get fromStatusLabel;/// Where the order landed, as a code — so a row can wear the status's own colour and glyph.
///
/// The label beside it is what gets *printed*; this is only ever asked for the legend, and
/// it falls back to [OrderStatus.unknown] — a status added on the server after this build
/// shipped still reads correctly in neutral rather than failing to parse the whole order.
@JsonKey(name: 'to_status', unknownEnumValue: OrderStatus.unknown) OrderStatus get toStatus;@JsonKey(name: 'to_status_label') String get toStatusLabel;/// What was typed when the order was moved — «العميل غيّر رأيه», «ناقص ٤٠ كيس».
///
/// This is the note of a *status*, which is what «ملاحظات الطلبية» is a page of: the order's
/// own note says what the job is, and each of these says what happened at one step of it.
 String? get reason;/// Who moved it. Null for a move made by a console command or a seeder — the column is
/// nullable for exactly that — and for a build of the API that did not load the relation.
///
/// It is the other half of [reason]: «تم الإلغاء — العميل غيّر رأيه» is a different fact
/// from the same sentence with a name against it, and the name is what makes the timeline
/// answerable rather than merely readable.
 OrderActor? get user;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of OrderTransitionRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderTransitionRecordCopyWith<OrderTransitionRecord> get copyWith => _$OrderTransitionRecordCopyWithImpl<OrderTransitionRecord>(this as OrderTransitionRecord, _$identity);

  /// Serializes this OrderTransitionRecord to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderTransitionRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.fromStatusLabel, fromStatusLabel) || other.fromStatusLabel == fromStatusLabel)&&(identical(other.toStatus, toStatus) || other.toStatus == toStatus)&&(identical(other.toStatusLabel, toStatusLabel) || other.toStatusLabel == toStatusLabel)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.user, user) || other.user == user)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fromStatusLabel,toStatus,toStatusLabel,reason,user,createdAt);

@override
String toString() {
  return 'OrderTransitionRecord(id: $id, fromStatusLabel: $fromStatusLabel, toStatus: $toStatus, toStatusLabel: $toStatusLabel, reason: $reason, user: $user, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $OrderTransitionRecordCopyWith<$Res>  {
  factory $OrderTransitionRecordCopyWith(OrderTransitionRecord value, $Res Function(OrderTransitionRecord) _then) = _$OrderTransitionRecordCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'from_status_label') String? fromStatusLabel,@JsonKey(name: 'to_status', unknownEnumValue: OrderStatus.unknown) OrderStatus toStatus,@JsonKey(name: 'to_status_label') String toStatusLabel, String? reason, OrderActor? user,@JsonKey(name: 'created_at') DateTime? createdAt
});


$OrderActorCopyWith<$Res>? get user;

}
/// @nodoc
class _$OrderTransitionRecordCopyWithImpl<$Res>
    implements $OrderTransitionRecordCopyWith<$Res> {
  _$OrderTransitionRecordCopyWithImpl(this._self, this._then);

  final OrderTransitionRecord _self;
  final $Res Function(OrderTransitionRecord) _then;

/// Create a copy of OrderTransitionRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fromStatusLabel = freezed,Object? toStatus = null,Object? toStatusLabel = null,Object? reason = freezed,Object? user = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,fromStatusLabel: freezed == fromStatusLabel ? _self.fromStatusLabel : fromStatusLabel // ignore: cast_nullable_to_non_nullable
as String?,toStatus: null == toStatus ? _self.toStatus : toStatus // ignore: cast_nullable_to_non_nullable
as OrderStatus,toStatusLabel: null == toStatusLabel ? _self.toStatusLabel : toStatusLabel // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as OrderActor?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of OrderTransitionRecord
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderActorCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $OrderActorCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// Adds pattern-matching-related methods to [OrderTransitionRecord].
extension OrderTransitionRecordPatterns on OrderTransitionRecord {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderTransitionRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderTransitionRecord() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderTransitionRecord value)  $default,){
final _that = this;
switch (_that) {
case _OrderTransitionRecord():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderTransitionRecord value)?  $default,){
final _that = this;
switch (_that) {
case _OrderTransitionRecord() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'from_status_label')  String? fromStatusLabel, @JsonKey(name: 'to_status', unknownEnumValue: OrderStatus.unknown)  OrderStatus toStatus, @JsonKey(name: 'to_status_label')  String toStatusLabel,  String? reason,  OrderActor? user, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderTransitionRecord() when $default != null:
return $default(_that.id,_that.fromStatusLabel,_that.toStatus,_that.toStatusLabel,_that.reason,_that.user,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'from_status_label')  String? fromStatusLabel, @JsonKey(name: 'to_status', unknownEnumValue: OrderStatus.unknown)  OrderStatus toStatus, @JsonKey(name: 'to_status_label')  String toStatusLabel,  String? reason,  OrderActor? user, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _OrderTransitionRecord():
return $default(_that.id,_that.fromStatusLabel,_that.toStatus,_that.toStatusLabel,_that.reason,_that.user,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'from_status_label')  String? fromStatusLabel, @JsonKey(name: 'to_status', unknownEnumValue: OrderStatus.unknown)  OrderStatus toStatus, @JsonKey(name: 'to_status_label')  String toStatusLabel,  String? reason,  OrderActor? user, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _OrderTransitionRecord() when $default != null:
return $default(_that.id,_that.fromStatusLabel,_that.toStatus,_that.toStatusLabel,_that.reason,_that.user,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderTransitionRecord extends OrderTransitionRecord {
  const _OrderTransitionRecord({required this.id, @JsonKey(name: 'from_status_label') this.fromStatusLabel, @JsonKey(name: 'to_status', unknownEnumValue: OrderStatus.unknown) this.toStatus = OrderStatus.unknown, @JsonKey(name: 'to_status_label') required this.toStatusLabel, this.reason, this.user, @JsonKey(name: 'created_at') this.createdAt}): super._();
  factory _OrderTransitionRecord.fromJson(Map<String, dynamic> json) => _$OrderTransitionRecordFromJson(json);

@override final  int id;
/// Null exactly once per order: the row that records it being taken.
@override@JsonKey(name: 'from_status_label') final  String? fromStatusLabel;
/// Where the order landed, as a code — so a row can wear the status's own colour and glyph.
///
/// The label beside it is what gets *printed*; this is only ever asked for the legend, and
/// it falls back to [OrderStatus.unknown] — a status added on the server after this build
/// shipped still reads correctly in neutral rather than failing to parse the whole order.
@override@JsonKey(name: 'to_status', unknownEnumValue: OrderStatus.unknown) final  OrderStatus toStatus;
@override@JsonKey(name: 'to_status_label') final  String toStatusLabel;
/// What was typed when the order was moved — «العميل غيّر رأيه», «ناقص ٤٠ كيس».
///
/// This is the note of a *status*, which is what «ملاحظات الطلبية» is a page of: the order's
/// own note says what the job is, and each of these says what happened at one step of it.
@override final  String? reason;
/// Who moved it. Null for a move made by a console command or a seeder — the column is
/// nullable for exactly that — and for a build of the API that did not load the relation.
///
/// It is the other half of [reason]: «تم الإلغاء — العميل غيّر رأيه» is a different fact
/// from the same sentence with a name against it, and the name is what makes the timeline
/// answerable rather than merely readable.
@override final  OrderActor? user;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of OrderTransitionRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderTransitionRecordCopyWith<_OrderTransitionRecord> get copyWith => __$OrderTransitionRecordCopyWithImpl<_OrderTransitionRecord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderTransitionRecordToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderTransitionRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.fromStatusLabel, fromStatusLabel) || other.fromStatusLabel == fromStatusLabel)&&(identical(other.toStatus, toStatus) || other.toStatus == toStatus)&&(identical(other.toStatusLabel, toStatusLabel) || other.toStatusLabel == toStatusLabel)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.user, user) || other.user == user)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fromStatusLabel,toStatus,toStatusLabel,reason,user,createdAt);

@override
String toString() {
  return 'OrderTransitionRecord(id: $id, fromStatusLabel: $fromStatusLabel, toStatus: $toStatus, toStatusLabel: $toStatusLabel, reason: $reason, user: $user, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$OrderTransitionRecordCopyWith<$Res> implements $OrderTransitionRecordCopyWith<$Res> {
  factory _$OrderTransitionRecordCopyWith(_OrderTransitionRecord value, $Res Function(_OrderTransitionRecord) _then) = __$OrderTransitionRecordCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'from_status_label') String? fromStatusLabel,@JsonKey(name: 'to_status', unknownEnumValue: OrderStatus.unknown) OrderStatus toStatus,@JsonKey(name: 'to_status_label') String toStatusLabel, String? reason, OrderActor? user,@JsonKey(name: 'created_at') DateTime? createdAt
});


@override $OrderActorCopyWith<$Res>? get user;

}
/// @nodoc
class __$OrderTransitionRecordCopyWithImpl<$Res>
    implements _$OrderTransitionRecordCopyWith<$Res> {
  __$OrderTransitionRecordCopyWithImpl(this._self, this._then);

  final _OrderTransitionRecord _self;
  final $Res Function(_OrderTransitionRecord) _then;

/// Create a copy of OrderTransitionRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fromStatusLabel = freezed,Object? toStatus = null,Object? toStatusLabel = null,Object? reason = freezed,Object? user = freezed,Object? createdAt = freezed,}) {
  return _then(_OrderTransitionRecord(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,fromStatusLabel: freezed == fromStatusLabel ? _self.fromStatusLabel : fromStatusLabel // ignore: cast_nullable_to_non_nullable
as String?,toStatus: null == toStatus ? _self.toStatus : toStatus // ignore: cast_nullable_to_non_nullable
as OrderStatus,toStatusLabel: null == toStatusLabel ? _self.toStatusLabel : toStatusLabel // ignore: cast_nullable_to_non_nullable
as String,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as OrderActor?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of OrderTransitionRecord
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderActorCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $OrderActorCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

// dart format on
