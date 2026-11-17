// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'new_order.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NewOrder {

@JsonKey(name: 'customer_id') int get customerId;@JsonKey(name: 'city_id') int get cityId;/// `none` · `customer` · `in_house`. Whose work the artwork was, which is the one thing
/// about a design that may move money.
@JsonKey(name: 'design_source') String get designSource;/// At least one, or the server refuses the order — `OrderNeedsAtLeastOneItem`.
 List<NewOrderItem> get items;/// Which of the customer's shops this is for. Omitted from the body when absent, because
/// «this customer has no branch in it» is different from «null».
@JsonKey(name: 'customer_shop_id', includeIfNull: false) int? get customerShopId;/// Required by the *city*, not by this model: a city marked as needing one refuses an order
/// without it, and the server's sentence says so.
@JsonKey(name: 'region_id', includeIfNull: false) int? get regionId;/// Only counted when [designSource] is `in_house`. Sent as a decimal string, never a number.
@JsonKey(name: 'design_fee', includeIfNull: false) String? get designFee;/// The artwork, chosen from the customer's library — ids, never files. Attached inside the
/// same transaction that takes the order, so a design belonging to somebody else refuses
/// the order rather than leaving one behind without the file it was taken for.
///
/// Omitted when empty: «بدون تصميم» sends no key at all.
@JsonKey(name: 'design_ids', includeIfNull: false) List<int>? get designIds;/// Colours typed in the form for chosen designs: `{design_id, print_colors}` per design.
/// The server fills an uncoloured library design with them, or keeps them on this order's
/// copy only. See PRINT-COLORS.md §9.
@JsonKey(name: 'design_colors', includeIfNull: false) List<Map<String, dynamic>>? get designColors;/// Guarded by `orders.discount` on the server. The field is hidden in the app for staff
/// without the grant; that is the suggestion, and the refusal is the rule.
@JsonKey(includeIfNull: false) String? get discount;/// What the customer is being charged on top of the products — «تغليف خاص»، «نقل». Guarded
/// by `orders.additional_cost` on the server, its own grant rather than the discount's:
/// the two are money moving in opposite directions.
///
/// **Omitted when nobody typed one**, the same rule the discount follows and for the same
/// reason — the grant is enforced on the value being above zero, so a charge of nothing has
/// to be no key at all. Absent here means «لا تكلفة إضافية», which is what a new order says
/// when it is not charging; on an *edit* the same silence means «اتركها كما هي», which is
/// why [UpdateOrderInvoice] sends a cleared box as `'0.00'` and this does not.
@JsonKey(name: 'additional_cost', includeIfNull: false) String? get additionalCost;/// Which of the five categories the charge goes under. **Required by the server the moment
/// there is an amount**, because this is the axis the money is read along afterwards —
/// «كم حصّلنا مقابل التغليف هذا الربع؟». Travels as the code, never as the Arabic on the
/// chip.
@JsonKey(name: 'additional_cost_reason', includeIfNull: false) AdditionalCostReason? get additionalCostReason;/// What was actually done, in the clerk's words — and required under «أخرى», the one
/// category that carries no information on its own.
@JsonKey(name: 'additional_cost_note', includeIfNull: false) String? get additionalCostNote;/// Who will make it. **Required by the server for an order whose lines are all وسيط**, and
/// refused as a 422 on `vendor_id` when missing — the road is read off the lines, so the app
/// cannot be told by a field rule and has to look at the products itself. See
/// `vendorRequirementFor`. Accepted on any order the server takes.
@JsonKey(name: 'vendor_id', includeIfNull: false) int? get vendorId;/// `us` when we pay the courier — free delivery for the customer, and the fee becomes the
/// order's own cost. **Omitted otherwise**: absent is the recipient, the server's default.
@JsonKey(name: 'delivery_paid_by', includeIfNull: false) String? get deliveryPaidBy;/// «طلبية تعويض» — the customer pays nothing for these goods. **Omitted unless true**, with
/// its reason, its words (required under «أخرى») and, optionally, the order it makes good.
/// Needs `orders.compensation`. Docs/orders/ORDER-COMPENSATION.md.
@JsonKey(name: 'is_compensation', includeIfNull: false) bool? get isCompensation;@JsonKey(name: 'compensation_reason', includeIfNull: false) String? get compensationReason;@JsonKey(name: 'compensation_note', includeIfNull: false) String? get compensationNote;@JsonKey(name: 'compensates_order_id', includeIfNull: false) int? get compensatesOrderId;@JsonKey(name: 'recipient_name', includeIfNull: false) String? get recipientName;@JsonKey(name: 'recipient_phone', includeIfNull: false) String? get recipientPhone;@JsonKey(name: 'address_details', includeIfNull: false) String? get addressDetails;@JsonKey(includeIfNull: false) String? get notes;/// «مستعجلة» — said at the counter, when the order is agreed.
///
/// Omitted from the body when absent rather than sent as false, so this model follows the
/// same rule the server does: a key that never arrived means «لم يُذكر». On the way in the
/// server reads that as «ليست مستعجلة»; on an edit it means «اتركها كما هي».
@JsonKey(name: 'is_urgent', includeIfNull: false) bool? get isUrgent;
/// Create a copy of NewOrder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewOrderCopyWith<NewOrder> get copyWith => _$NewOrderCopyWithImpl<NewOrder>(this as NewOrder, _$identity);

  /// Serializes this NewOrder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as NewOrder;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewOrder&&(identical(other.customerId, _this.customerId) || other.customerId == _this.customerId)&&(identical(other.cityId, _this.cityId) || other.cityId == _this.cityId)&&(identical(other.designSource, _this.designSource) || other.designSource == _this.designSource)&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.customerShopId, _this.customerShopId) || other.customerShopId == _this.customerShopId)&&(identical(other.regionId, _this.regionId) || other.regionId == _this.regionId)&&(identical(other.designFee, _this.designFee) || other.designFee == _this.designFee)&&const DeepCollectionEquality().equals(other.designIds, _this.designIds)&&const DeepCollectionEquality().equals(other.designColors, _this.designColors)&&(identical(other.discount, _this.discount) || other.discount == _this.discount)&&(identical(other.additionalCost, _this.additionalCost) || other.additionalCost == _this.additionalCost)&&(identical(other.additionalCostReason, _this.additionalCostReason) || other.additionalCostReason == _this.additionalCostReason)&&(identical(other.additionalCostNote, _this.additionalCostNote) || other.additionalCostNote == _this.additionalCostNote)&&(identical(other.vendorId, _this.vendorId) || other.vendorId == _this.vendorId)&&(identical(other.deliveryPaidBy, _this.deliveryPaidBy) || other.deliveryPaidBy == _this.deliveryPaidBy)&&(identical(other.isCompensation, _this.isCompensation) || other.isCompensation == _this.isCompensation)&&(identical(other.compensationReason, _this.compensationReason) || other.compensationReason == _this.compensationReason)&&(identical(other.compensationNote, _this.compensationNote) || other.compensationNote == _this.compensationNote)&&(identical(other.compensatesOrderId, _this.compensatesOrderId) || other.compensatesOrderId == _this.compensatesOrderId)&&(identical(other.recipientName, _this.recipientName) || other.recipientName == _this.recipientName)&&(identical(other.recipientPhone, _this.recipientPhone) || other.recipientPhone == _this.recipientPhone)&&(identical(other.addressDetails, _this.addressDetails) || other.addressDetails == _this.addressDetails)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&(identical(other.isUrgent, _this.isUrgent) || other.isUrgent == _this.isUrgent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NewOrder;
  return Object.hashAll([runtimeType,_this.customerId,_this.cityId,_this.designSource,const DeepCollectionEquality().hash(_this.items),_this.customerShopId,_this.regionId,_this.designFee,const DeepCollectionEquality().hash(_this.designIds),const DeepCollectionEquality().hash(_this.designColors),_this.discount,_this.additionalCost,_this.additionalCostReason,_this.additionalCostNote,_this.vendorId,_this.deliveryPaidBy,_this.isCompensation,_this.compensationReason,_this.compensationNote,_this.compensatesOrderId,_this.recipientName,_this.recipientPhone,_this.addressDetails,_this.notes,_this.isUrgent]);
}

@override
String toString() {
  final _this = this as NewOrder;
  return 'NewOrder(customerId: ${_this.customerId}, cityId: ${_this.cityId}, designSource: ${_this.designSource}, items: ${_this.items}, customerShopId: ${_this.customerShopId}, regionId: ${_this.regionId}, designFee: ${_this.designFee}, designIds: ${_this.designIds}, designColors: ${_this.designColors}, discount: ${_this.discount}, additionalCost: ${_this.additionalCost}, additionalCostReason: ${_this.additionalCostReason}, additionalCostNote: ${_this.additionalCostNote}, vendorId: ${_this.vendorId}, deliveryPaidBy: ${_this.deliveryPaidBy}, isCompensation: ${_this.isCompensation}, compensationReason: ${_this.compensationReason}, compensationNote: ${_this.compensationNote}, compensatesOrderId: ${_this.compensatesOrderId}, recipientName: ${_this.recipientName}, recipientPhone: ${_this.recipientPhone}, addressDetails: ${_this.addressDetails}, notes: ${_this.notes}, isUrgent: ${_this.isUrgent})';
}


}

/// @nodoc
abstract mixin class $NewOrderCopyWith<$Res>  {
  factory $NewOrderCopyWith(NewOrder value, $Res Function(NewOrder) _then) = _$NewOrderCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'customer_id') int customerId,@JsonKey(name: 'city_id') int cityId,@JsonKey(name: 'design_source') String designSource, List<NewOrderItem> items,@JsonKey(name: 'customer_shop_id', includeIfNull: false) int? customerShopId,@JsonKey(name: 'region_id', includeIfNull: false) int? regionId,@JsonKey(name: 'design_fee', includeIfNull: false) String? designFee,@JsonKey(name: 'design_ids', includeIfNull: false) List<int>? designIds,@JsonKey(name: 'design_colors', includeIfNull: false) List<Map<String, dynamic>>? designColors,@JsonKey(includeIfNull: false) String? discount,@JsonKey(name: 'additional_cost', includeIfNull: false) String? additionalCost,@JsonKey(name: 'additional_cost_reason', includeIfNull: false) AdditionalCostReason? additionalCostReason,@JsonKey(name: 'additional_cost_note', includeIfNull: false) String? additionalCostNote,@JsonKey(name: 'vendor_id', includeIfNull: false) int? vendorId,@JsonKey(name: 'delivery_paid_by', includeIfNull: false) String? deliveryPaidBy,@JsonKey(name: 'is_compensation', includeIfNull: false) bool? isCompensation,@JsonKey(name: 'compensation_reason', includeIfNull: false) String? compensationReason,@JsonKey(name: 'compensation_note', includeIfNull: false) String? compensationNote,@JsonKey(name: 'compensates_order_id', includeIfNull: false) int? compensatesOrderId,@JsonKey(name: 'recipient_name', includeIfNull: false) String? recipientName,@JsonKey(name: 'recipient_phone', includeIfNull: false) String? recipientPhone,@JsonKey(name: 'address_details', includeIfNull: false) String? addressDetails,@JsonKey(includeIfNull: false) String? notes,@JsonKey(name: 'is_urgent', includeIfNull: false) bool? isUrgent
});




}
/// @nodoc
class _$NewOrderCopyWithImpl<$Res>
    implements $NewOrderCopyWith<$Res> {
  _$NewOrderCopyWithImpl(this._self, this._then);

  final NewOrder _self;
  final $Res Function(NewOrder) _then;

/// Create a copy of NewOrder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? customerId = null,Object? cityId = null,Object? designSource = null,Object? items = null,Object? customerShopId = freezed,Object? regionId = freezed,Object? designFee = freezed,Object? designIds = freezed,Object? designColors = freezed,Object? discount = freezed,Object? additionalCost = freezed,Object? additionalCostReason = freezed,Object? additionalCostNote = freezed,Object? vendorId = freezed,Object? deliveryPaidBy = freezed,Object? isCompensation = freezed,Object? compensationReason = freezed,Object? compensationNote = freezed,Object? compensatesOrderId = freezed,Object? recipientName = freezed,Object? recipientPhone = freezed,Object? addressDetails = freezed,Object? notes = freezed,Object? isUrgent = freezed,}) {
  return _then(NewOrder(
customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as int,cityId: null == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as int,designSource: null == designSource ? _self.designSource : designSource // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<NewOrderItem>,customerShopId: freezed == customerShopId ? _self.customerShopId : customerShopId // ignore: cast_nullable_to_non_nullable
as int?,regionId: freezed == regionId ? _self.regionId : regionId // ignore: cast_nullable_to_non_nullable
as int?,designFee: freezed == designFee ? _self.designFee : designFee // ignore: cast_nullable_to_non_nullable
as String?,designIds: freezed == designIds ? _self.designIds : designIds // ignore: cast_nullable_to_non_nullable
as List<int>?,designColors: freezed == designColors ? _self.designColors : designColors // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>?,discount: freezed == discount ? _self.discount : discount // ignore: cast_nullable_to_non_nullable
as String?,additionalCost: freezed == additionalCost ? _self.additionalCost : additionalCost // ignore: cast_nullable_to_non_nullable
as String?,additionalCostReason: freezed == additionalCostReason ? _self.additionalCostReason : additionalCostReason // ignore: cast_nullable_to_non_nullable
as AdditionalCostReason?,additionalCostNote: freezed == additionalCostNote ? _self.additionalCostNote : additionalCostNote // ignore: cast_nullable_to_non_nullable
as String?,vendorId: freezed == vendorId ? _self.vendorId : vendorId // ignore: cast_nullable_to_non_nullable
as int?,deliveryPaidBy: freezed == deliveryPaidBy ? _self.deliveryPaidBy : deliveryPaidBy // ignore: cast_nullable_to_non_nullable
as String?,isCompensation: freezed == isCompensation ? _self.isCompensation : isCompensation // ignore: cast_nullable_to_non_nullable
as bool?,compensationReason: freezed == compensationReason ? _self.compensationReason : compensationReason // ignore: cast_nullable_to_non_nullable
as String?,compensationNote: freezed == compensationNote ? _self.compensationNote : compensationNote // ignore: cast_nullable_to_non_nullable
as String?,compensatesOrderId: freezed == compensatesOrderId ? _self.compensatesOrderId : compensatesOrderId // ignore: cast_nullable_to_non_nullable
as int?,recipientName: freezed == recipientName ? _self.recipientName : recipientName // ignore: cast_nullable_to_non_nullable
as String?,recipientPhone: freezed == recipientPhone ? _self.recipientPhone : recipientPhone // ignore: cast_nullable_to_non_nullable
as String?,addressDetails: freezed == addressDetails ? _self.addressDetails : addressDetails // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isUrgent: freezed == isUrgent ? _self.isUrgent : isUrgent // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [NewOrder].
extension NewOrderPatterns on NewOrder {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewOrder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewOrder() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewOrder value)  $default,){
final _that = this;
switch (_that) {
case _NewOrder():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewOrder value)?  $default,){
final _that = this;
switch (_that) {
case _NewOrder() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'customer_id')  int customerId, @JsonKey(name: 'city_id')  int cityId, @JsonKey(name: 'design_source')  String designSource,  List<NewOrderItem> items, @JsonKey(name: 'customer_shop_id', includeIfNull: false)  int? customerShopId, @JsonKey(name: 'region_id', includeIfNull: false)  int? regionId, @JsonKey(name: 'design_fee', includeIfNull: false)  String? designFee, @JsonKey(name: 'design_ids', includeIfNull: false)  List<int>? designIds, @JsonKey(name: 'design_colors', includeIfNull: false)  List<Map<String, dynamic>>? designColors, @JsonKey(includeIfNull: false)  String? discount, @JsonKey(name: 'additional_cost', includeIfNull: false)  String? additionalCost, @JsonKey(name: 'additional_cost_reason', includeIfNull: false)  AdditionalCostReason? additionalCostReason, @JsonKey(name: 'additional_cost_note', includeIfNull: false)  String? additionalCostNote, @JsonKey(name: 'vendor_id', includeIfNull: false)  int? vendorId, @JsonKey(name: 'delivery_paid_by', includeIfNull: false)  String? deliveryPaidBy, @JsonKey(name: 'is_compensation', includeIfNull: false)  bool? isCompensation, @JsonKey(name: 'compensation_reason', includeIfNull: false)  String? compensationReason, @JsonKey(name: 'compensation_note', includeIfNull: false)  String? compensationNote, @JsonKey(name: 'compensates_order_id', includeIfNull: false)  int? compensatesOrderId, @JsonKey(name: 'recipient_name', includeIfNull: false)  String? recipientName, @JsonKey(name: 'recipient_phone', includeIfNull: false)  String? recipientPhone, @JsonKey(name: 'address_details', includeIfNull: false)  String? addressDetails, @JsonKey(includeIfNull: false)  String? notes, @JsonKey(name: 'is_urgent', includeIfNull: false)  bool? isUrgent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewOrder() when $default != null:
return $default(_that.customerId,_that.cityId,_that.designSource,_that.items,_that.customerShopId,_that.regionId,_that.designFee,_that.designIds,_that.designColors,_that.discount,_that.additionalCost,_that.additionalCostReason,_that.additionalCostNote,_that.vendorId,_that.deliveryPaidBy,_that.isCompensation,_that.compensationReason,_that.compensationNote,_that.compensatesOrderId,_that.recipientName,_that.recipientPhone,_that.addressDetails,_that.notes,_that.isUrgent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'customer_id')  int customerId, @JsonKey(name: 'city_id')  int cityId, @JsonKey(name: 'design_source')  String designSource,  List<NewOrderItem> items, @JsonKey(name: 'customer_shop_id', includeIfNull: false)  int? customerShopId, @JsonKey(name: 'region_id', includeIfNull: false)  int? regionId, @JsonKey(name: 'design_fee', includeIfNull: false)  String? designFee, @JsonKey(name: 'design_ids', includeIfNull: false)  List<int>? designIds, @JsonKey(name: 'design_colors', includeIfNull: false)  List<Map<String, dynamic>>? designColors, @JsonKey(includeIfNull: false)  String? discount, @JsonKey(name: 'additional_cost', includeIfNull: false)  String? additionalCost, @JsonKey(name: 'additional_cost_reason', includeIfNull: false)  AdditionalCostReason? additionalCostReason, @JsonKey(name: 'additional_cost_note', includeIfNull: false)  String? additionalCostNote, @JsonKey(name: 'vendor_id', includeIfNull: false)  int? vendorId, @JsonKey(name: 'delivery_paid_by', includeIfNull: false)  String? deliveryPaidBy, @JsonKey(name: 'is_compensation', includeIfNull: false)  bool? isCompensation, @JsonKey(name: 'compensation_reason', includeIfNull: false)  String? compensationReason, @JsonKey(name: 'compensation_note', includeIfNull: false)  String? compensationNote, @JsonKey(name: 'compensates_order_id', includeIfNull: false)  int? compensatesOrderId, @JsonKey(name: 'recipient_name', includeIfNull: false)  String? recipientName, @JsonKey(name: 'recipient_phone', includeIfNull: false)  String? recipientPhone, @JsonKey(name: 'address_details', includeIfNull: false)  String? addressDetails, @JsonKey(includeIfNull: false)  String? notes, @JsonKey(name: 'is_urgent', includeIfNull: false)  bool? isUrgent)  $default,) {final _that = this;
switch (_that) {
case _NewOrder():
return $default(_that.customerId,_that.cityId,_that.designSource,_that.items,_that.customerShopId,_that.regionId,_that.designFee,_that.designIds,_that.designColors,_that.discount,_that.additionalCost,_that.additionalCostReason,_that.additionalCostNote,_that.vendorId,_that.deliveryPaidBy,_that.isCompensation,_that.compensationReason,_that.compensationNote,_that.compensatesOrderId,_that.recipientName,_that.recipientPhone,_that.addressDetails,_that.notes,_that.isUrgent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'customer_id')  int customerId, @JsonKey(name: 'city_id')  int cityId, @JsonKey(name: 'design_source')  String designSource,  List<NewOrderItem> items, @JsonKey(name: 'customer_shop_id', includeIfNull: false)  int? customerShopId, @JsonKey(name: 'region_id', includeIfNull: false)  int? regionId, @JsonKey(name: 'design_fee', includeIfNull: false)  String? designFee, @JsonKey(name: 'design_ids', includeIfNull: false)  List<int>? designIds, @JsonKey(name: 'design_colors', includeIfNull: false)  List<Map<String, dynamic>>? designColors, @JsonKey(includeIfNull: false)  String? discount, @JsonKey(name: 'additional_cost', includeIfNull: false)  String? additionalCost, @JsonKey(name: 'additional_cost_reason', includeIfNull: false)  AdditionalCostReason? additionalCostReason, @JsonKey(name: 'additional_cost_note', includeIfNull: false)  String? additionalCostNote, @JsonKey(name: 'vendor_id', includeIfNull: false)  int? vendorId, @JsonKey(name: 'delivery_paid_by', includeIfNull: false)  String? deliveryPaidBy, @JsonKey(name: 'is_compensation', includeIfNull: false)  bool? isCompensation, @JsonKey(name: 'compensation_reason', includeIfNull: false)  String? compensationReason, @JsonKey(name: 'compensation_note', includeIfNull: false)  String? compensationNote, @JsonKey(name: 'compensates_order_id', includeIfNull: false)  int? compensatesOrderId, @JsonKey(name: 'recipient_name', includeIfNull: false)  String? recipientName, @JsonKey(name: 'recipient_phone', includeIfNull: false)  String? recipientPhone, @JsonKey(name: 'address_details', includeIfNull: false)  String? addressDetails, @JsonKey(includeIfNull: false)  String? notes, @JsonKey(name: 'is_urgent', includeIfNull: false)  bool? isUrgent)?  $default,) {final _that = this;
switch (_that) {
case _NewOrder() when $default != null:
return $default(_that.customerId,_that.cityId,_that.designSource,_that.items,_that.customerShopId,_that.regionId,_that.designFee,_that.designIds,_that.designColors,_that.discount,_that.additionalCost,_that.additionalCostReason,_that.additionalCostNote,_that.vendorId,_that.deliveryPaidBy,_that.isCompensation,_that.compensationReason,_that.compensationNote,_that.compensatesOrderId,_that.recipientName,_that.recipientPhone,_that.addressDetails,_that.notes,_that.isUrgent);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NewOrder implements NewOrder {
  const _NewOrder({@JsonKey(name: 'customer_id') required this.customerId, @JsonKey(name: 'city_id') required this.cityId, @JsonKey(name: 'design_source') required this.designSource, required  List<NewOrderItem> items, @JsonKey(name: 'customer_shop_id', includeIfNull: false) this.customerShopId, @JsonKey(name: 'region_id', includeIfNull: false) this.regionId, @JsonKey(name: 'design_fee', includeIfNull: false) this.designFee, @JsonKey(name: 'design_ids', includeIfNull: false)  List<int>? designIds, @JsonKey(name: 'design_colors', includeIfNull: false)  List<Map<String, dynamic>>? designColors, @JsonKey(includeIfNull: false) this.discount, @JsonKey(name: 'additional_cost', includeIfNull: false) this.additionalCost, @JsonKey(name: 'additional_cost_reason', includeIfNull: false) this.additionalCostReason, @JsonKey(name: 'additional_cost_note', includeIfNull: false) this.additionalCostNote, @JsonKey(name: 'vendor_id', includeIfNull: false) this.vendorId, @JsonKey(name: 'delivery_paid_by', includeIfNull: false) this.deliveryPaidBy, @JsonKey(name: 'is_compensation', includeIfNull: false) this.isCompensation, @JsonKey(name: 'compensation_reason', includeIfNull: false) this.compensationReason, @JsonKey(name: 'compensation_note', includeIfNull: false) this.compensationNote, @JsonKey(name: 'compensates_order_id', includeIfNull: false) this.compensatesOrderId, @JsonKey(name: 'recipient_name', includeIfNull: false) this.recipientName, @JsonKey(name: 'recipient_phone', includeIfNull: false) this.recipientPhone, @JsonKey(name: 'address_details', includeIfNull: false) this.addressDetails, @JsonKey(includeIfNull: false) this.notes, @JsonKey(name: 'is_urgent', includeIfNull: false) this.isUrgent}): _items = items,_designIds = designIds,_designColors = designColors;
  factory _NewOrder.fromJson(Map<String, dynamic> json) => _$NewOrderFromJson(json);

@override@JsonKey(name: 'customer_id') final  int customerId;
@override@JsonKey(name: 'city_id') final  int cityId;
/// `none` · `customer` · `in_house`. Whose work the artwork was, which is the one thing
/// about a design that may move money.
@override@JsonKey(name: 'design_source') final  String designSource;
/// At least one, or the server refuses the order — `OrderNeedsAtLeastOneItem`.
 final  List<NewOrderItem> _items;
/// At least one, or the server refuses the order — `OrderNeedsAtLeastOneItem`.
@override List<NewOrderItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

/// Which of the customer's shops this is for. Omitted from the body when absent, because
/// «this customer has no branch in it» is different from «null».
@override@JsonKey(name: 'customer_shop_id', includeIfNull: false) final  int? customerShopId;
/// Required by the *city*, not by this model: a city marked as needing one refuses an order
/// without it, and the server's sentence says so.
@override@JsonKey(name: 'region_id', includeIfNull: false) final  int? regionId;
/// Only counted when [designSource] is `in_house`. Sent as a decimal string, never a number.
@override@JsonKey(name: 'design_fee', includeIfNull: false) final  String? designFee;
/// The artwork, chosen from the customer's library — ids, never files. Attached inside the
/// same transaction that takes the order, so a design belonging to somebody else refuses
/// the order rather than leaving one behind without the file it was taken for.
///
/// Omitted when empty: «بدون تصميم» sends no key at all.
 final  List<int>? _designIds;
/// The artwork, chosen from the customer's library — ids, never files. Attached inside the
/// same transaction that takes the order, so a design belonging to somebody else refuses
/// the order rather than leaving one behind without the file it was taken for.
///
/// Omitted when empty: «بدون تصميم» sends no key at all.
@override@JsonKey(name: 'design_ids', includeIfNull: false) List<int>? get designIds {
  final value = _designIds;
  if (value == null) return null;
  if (_designIds is EqualUnmodifiableListView) return _designIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Colours typed in the form for chosen designs: `{design_id, print_colors}` per design.
/// The server fills an uncoloured library design with them, or keeps them on this order's
/// copy only. See PRINT-COLORS.md §9.
 final  List<Map<String, dynamic>>? _designColors;
/// Colours typed in the form for chosen designs: `{design_id, print_colors}` per design.
/// The server fills an uncoloured library design with them, or keeps them on this order's
/// copy only. See PRINT-COLORS.md §9.
@override@JsonKey(name: 'design_colors', includeIfNull: false) List<Map<String, dynamic>>? get designColors {
  final value = _designColors;
  if (value == null) return null;
  if (_designColors is EqualUnmodifiableListView) return _designColors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Guarded by `orders.discount` on the server. The field is hidden in the app for staff
/// without the grant; that is the suggestion, and the refusal is the rule.
@override@JsonKey(includeIfNull: false) final  String? discount;
/// What the customer is being charged on top of the products — «تغليف خاص»، «نقل». Guarded
/// by `orders.additional_cost` on the server, its own grant rather than the discount's:
/// the two are money moving in opposite directions.
///
/// **Omitted when nobody typed one**, the same rule the discount follows and for the same
/// reason — the grant is enforced on the value being above zero, so a charge of nothing has
/// to be no key at all. Absent here means «لا تكلفة إضافية», which is what a new order says
/// when it is not charging; on an *edit* the same silence means «اتركها كما هي», which is
/// why [UpdateOrderInvoice] sends a cleared box as `'0.00'` and this does not.
@override@JsonKey(name: 'additional_cost', includeIfNull: false) final  String? additionalCost;
/// Which of the five categories the charge goes under. **Required by the server the moment
/// there is an amount**, because this is the axis the money is read along afterwards —
/// «كم حصّلنا مقابل التغليف هذا الربع؟». Travels as the code, never as the Arabic on the
/// chip.
@override@JsonKey(name: 'additional_cost_reason', includeIfNull: false) final  AdditionalCostReason? additionalCostReason;
/// What was actually done, in the clerk's words — and required under «أخرى», the one
/// category that carries no information on its own.
@override@JsonKey(name: 'additional_cost_note', includeIfNull: false) final  String? additionalCostNote;
/// Who will make it. **Required by the server for an order whose lines are all وسيط**, and
/// refused as a 422 on `vendor_id` when missing — the road is read off the lines, so the app
/// cannot be told by a field rule and has to look at the products itself. See
/// `vendorRequirementFor`. Accepted on any order the server takes.
@override@JsonKey(name: 'vendor_id', includeIfNull: false) final  int? vendorId;
/// `us` when we pay the courier — free delivery for the customer, and the fee becomes the
/// order's own cost. **Omitted otherwise**: absent is the recipient, the server's default.
@override@JsonKey(name: 'delivery_paid_by', includeIfNull: false) final  String? deliveryPaidBy;
/// «طلبية تعويض» — the customer pays nothing for these goods. **Omitted unless true**, with
/// its reason, its words (required under «أخرى») and, optionally, the order it makes good.
/// Needs `orders.compensation`. Docs/orders/ORDER-COMPENSATION.md.
@override@JsonKey(name: 'is_compensation', includeIfNull: false) final  bool? isCompensation;
@override@JsonKey(name: 'compensation_reason', includeIfNull: false) final  String? compensationReason;
@override@JsonKey(name: 'compensation_note', includeIfNull: false) final  String? compensationNote;
@override@JsonKey(name: 'compensates_order_id', includeIfNull: false) final  int? compensatesOrderId;
@override@JsonKey(name: 'recipient_name', includeIfNull: false) final  String? recipientName;
@override@JsonKey(name: 'recipient_phone', includeIfNull: false) final  String? recipientPhone;
@override@JsonKey(name: 'address_details', includeIfNull: false) final  String? addressDetails;
@override@JsonKey(includeIfNull: false) final  String? notes;
/// «مستعجلة» — said at the counter, when the order is agreed.
///
/// Omitted from the body when absent rather than sent as false, so this model follows the
/// same rule the server does: a key that never arrived means «لم يُذكر». On the way in the
/// server reads that as «ليست مستعجلة»; on an edit it means «اتركها كما هي».
@override@JsonKey(name: 'is_urgent', includeIfNull: false) final  bool? isUrgent;

/// Create a copy of NewOrder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewOrderCopyWith<_NewOrder> get copyWith => __$NewOrderCopyWithImpl<_NewOrder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NewOrderToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewOrder&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.cityId, cityId) || other.cityId == cityId)&&(identical(other.designSource, designSource) || other.designSource == designSource)&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.customerShopId, customerShopId) || other.customerShopId == customerShopId)&&(identical(other.regionId, regionId) || other.regionId == regionId)&&(identical(other.designFee, designFee) || other.designFee == designFee)&&const DeepCollectionEquality().equals(other.designIds, _designIds)&&const DeepCollectionEquality().equals(other.designColors, _designColors)&&(identical(other.discount, discount) || other.discount == discount)&&(identical(other.additionalCost, additionalCost) || other.additionalCost == additionalCost)&&(identical(other.additionalCostReason, additionalCostReason) || other.additionalCostReason == additionalCostReason)&&(identical(other.additionalCostNote, additionalCostNote) || other.additionalCostNote == additionalCostNote)&&(identical(other.vendorId, vendorId) || other.vendorId == vendorId)&&(identical(other.deliveryPaidBy, deliveryPaidBy) || other.deliveryPaidBy == deliveryPaidBy)&&(identical(other.isCompensation, isCompensation) || other.isCompensation == isCompensation)&&(identical(other.compensationReason, compensationReason) || other.compensationReason == compensationReason)&&(identical(other.compensationNote, compensationNote) || other.compensationNote == compensationNote)&&(identical(other.compensatesOrderId, compensatesOrderId) || other.compensatesOrderId == compensatesOrderId)&&(identical(other.recipientName, recipientName) || other.recipientName == recipientName)&&(identical(other.recipientPhone, recipientPhone) || other.recipientPhone == recipientPhone)&&(identical(other.addressDetails, addressDetails) || other.addressDetails == addressDetails)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.isUrgent, isUrgent) || other.isUrgent == isUrgent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hashAll([runtimeType,customerId,cityId,designSource,const DeepCollectionEquality().hash(_items),customerShopId,regionId,designFee,const DeepCollectionEquality().hash(_designIds),const DeepCollectionEquality().hash(_designColors),discount,additionalCost,additionalCostReason,additionalCostNote,vendorId,deliveryPaidBy,isCompensation,compensationReason,compensationNote,compensatesOrderId,recipientName,recipientPhone,addressDetails,notes,isUrgent]);
}

@override
String toString() {
    return 'NewOrder(customerId: $customerId, cityId: $cityId, designSource: $designSource, items: $items, customerShopId: $customerShopId, regionId: $regionId, designFee: $designFee, designIds: $designIds, designColors: $designColors, discount: $discount, additionalCost: $additionalCost, additionalCostReason: $additionalCostReason, additionalCostNote: $additionalCostNote, vendorId: $vendorId, deliveryPaidBy: $deliveryPaidBy, isCompensation: $isCompensation, compensationReason: $compensationReason, compensationNote: $compensationNote, compensatesOrderId: $compensatesOrderId, recipientName: $recipientName, recipientPhone: $recipientPhone, addressDetails: $addressDetails, notes: $notes, isUrgent: $isUrgent)';
}


}

/// @nodoc
abstract mixin class _$NewOrderCopyWith<$Res> implements $NewOrderCopyWith<$Res> {
  factory _$NewOrderCopyWith(_NewOrder value, $Res Function(_NewOrder) _then) = __$NewOrderCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'customer_id') int customerId,@JsonKey(name: 'city_id') int cityId,@JsonKey(name: 'design_source') String designSource, List<NewOrderItem> items,@JsonKey(name: 'customer_shop_id', includeIfNull: false) int? customerShopId,@JsonKey(name: 'region_id', includeIfNull: false) int? regionId,@JsonKey(name: 'design_fee', includeIfNull: false) String? designFee,@JsonKey(name: 'design_ids', includeIfNull: false) List<int>? designIds,@JsonKey(name: 'design_colors', includeIfNull: false) List<Map<String, dynamic>>? designColors,@JsonKey(includeIfNull: false) String? discount,@JsonKey(name: 'additional_cost', includeIfNull: false) String? additionalCost,@JsonKey(name: 'additional_cost_reason', includeIfNull: false) AdditionalCostReason? additionalCostReason,@JsonKey(name: 'additional_cost_note', includeIfNull: false) String? additionalCostNote,@JsonKey(name: 'vendor_id', includeIfNull: false) int? vendorId,@JsonKey(name: 'delivery_paid_by', includeIfNull: false) String? deliveryPaidBy,@JsonKey(name: 'is_compensation', includeIfNull: false) bool? isCompensation,@JsonKey(name: 'compensation_reason', includeIfNull: false) String? compensationReason,@JsonKey(name: 'compensation_note', includeIfNull: false) String? compensationNote,@JsonKey(name: 'compensates_order_id', includeIfNull: false) int? compensatesOrderId,@JsonKey(name: 'recipient_name', includeIfNull: false) String? recipientName,@JsonKey(name: 'recipient_phone', includeIfNull: false) String? recipientPhone,@JsonKey(name: 'address_details', includeIfNull: false) String? addressDetails,@JsonKey(includeIfNull: false) String? notes,@JsonKey(name: 'is_urgent', includeIfNull: false) bool? isUrgent
});




}
/// @nodoc
class __$NewOrderCopyWithImpl<$Res>
    implements _$NewOrderCopyWith<$Res> {
  __$NewOrderCopyWithImpl(this._self, this._then);

  final _NewOrder _self;
  final $Res Function(_NewOrder) _then;

/// Create a copy of NewOrder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? customerId = null,Object? cityId = null,Object? designSource = null,Object? items = null,Object? customerShopId = freezed,Object? regionId = freezed,Object? designFee = freezed,Object? designIds = freezed,Object? designColors = freezed,Object? discount = freezed,Object? additionalCost = freezed,Object? additionalCostReason = freezed,Object? additionalCostNote = freezed,Object? vendorId = freezed,Object? deliveryPaidBy = freezed,Object? isCompensation = freezed,Object? compensationReason = freezed,Object? compensationNote = freezed,Object? compensatesOrderId = freezed,Object? recipientName = freezed,Object? recipientPhone = freezed,Object? addressDetails = freezed,Object? notes = freezed,Object? isUrgent = freezed,}) {
  return _then(_NewOrder(
customerId: null == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as int,cityId: null == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as int,designSource: null == designSource ? _self.designSource : designSource // ignore: cast_nullable_to_non_nullable
as String,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<NewOrderItem>,customerShopId: freezed == customerShopId ? _self.customerShopId : customerShopId // ignore: cast_nullable_to_non_nullable
as int?,regionId: freezed == regionId ? _self.regionId : regionId // ignore: cast_nullable_to_non_nullable
as int?,designFee: freezed == designFee ? _self.designFee : designFee // ignore: cast_nullable_to_non_nullable
as String?,designIds: freezed == designIds ? _self._designIds : designIds // ignore: cast_nullable_to_non_nullable
as List<int>?,designColors: freezed == designColors ? _self._designColors : designColors // ignore: cast_nullable_to_non_nullable
as List<Map<String, dynamic>>?,discount: freezed == discount ? _self.discount : discount // ignore: cast_nullable_to_non_nullable
as String?,additionalCost: freezed == additionalCost ? _self.additionalCost : additionalCost // ignore: cast_nullable_to_non_nullable
as String?,additionalCostReason: freezed == additionalCostReason ? _self.additionalCostReason : additionalCostReason // ignore: cast_nullable_to_non_nullable
as AdditionalCostReason?,additionalCostNote: freezed == additionalCostNote ? _self.additionalCostNote : additionalCostNote // ignore: cast_nullable_to_non_nullable
as String?,vendorId: freezed == vendorId ? _self.vendorId : vendorId // ignore: cast_nullable_to_non_nullable
as int?,deliveryPaidBy: freezed == deliveryPaidBy ? _self.deliveryPaidBy : deliveryPaidBy // ignore: cast_nullable_to_non_nullable
as String?,isCompensation: freezed == isCompensation ? _self.isCompensation : isCompensation // ignore: cast_nullable_to_non_nullable
as bool?,compensationReason: freezed == compensationReason ? _self.compensationReason : compensationReason // ignore: cast_nullable_to_non_nullable
as String?,compensationNote: freezed == compensationNote ? _self.compensationNote : compensationNote // ignore: cast_nullable_to_non_nullable
as String?,compensatesOrderId: freezed == compensatesOrderId ? _self.compensatesOrderId : compensatesOrderId // ignore: cast_nullable_to_non_nullable
as int?,recipientName: freezed == recipientName ? _self.recipientName : recipientName // ignore: cast_nullable_to_non_nullable
as String?,recipientPhone: freezed == recipientPhone ? _self.recipientPhone : recipientPhone // ignore: cast_nullable_to_non_nullable
as String?,addressDetails: freezed == addressDetails ? _self.addressDetails : addressDetails // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,isUrgent: freezed == isUrgent ? _self.isUrgent : isUrgent // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}


/// @nodoc
mixin _$NewOrderItem {

@JsonKey(name: 'product_id') int get productId;@JsonKey(name: 'product_variant_id') int get productVariantId;/// A decimal string, already in ASCII digits — `'300'`, not `'٣٠٠'`.
 String get quantity;/// **Honoured only for a product the catalogue prices «حسب الطلب»**, and ignored otherwise:
/// for a listed product the catalogue's rate wins, which is what stops a posted number
/// undercutting an agreed price. Omitted when the app has no business naming one.
@JsonKey(name: 'unit_price', includeIfNull: false) String? get unitPrice;/// What the vendor charges for one unit of a وسيط line, typed for this order. **Honoured
/// only on such a line**, and refused by the server from anybody without
/// `products.view_cost` — so it is omitted unless the form drew the box.
@JsonKey(name: 'unit_cost', includeIfNull: false) String? get unitCost;@JsonKey(includeIfNull: false) String? get notes;/// The order the clerk put the lines in, kept so the invoice reads the way it was written.
@JsonKey(name: 'sort_order') int get sortOrder;
/// Create a copy of NewOrderItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewOrderItemCopyWith<NewOrderItem> get copyWith => _$NewOrderItemCopyWithImpl<NewOrderItem>(this as NewOrderItem, _$identity);

  /// Serializes this NewOrderItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as NewOrderItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewOrderItem&&(identical(other.productId, _this.productId) || other.productId == _this.productId)&&(identical(other.productVariantId, _this.productVariantId) || other.productVariantId == _this.productVariantId)&&(identical(other.quantity, _this.quantity) || other.quantity == _this.quantity)&&(identical(other.unitPrice, _this.unitPrice) || other.unitPrice == _this.unitPrice)&&(identical(other.unitCost, _this.unitCost) || other.unitCost == _this.unitCost)&&(identical(other.notes, _this.notes) || other.notes == _this.notes)&&(identical(other.sortOrder, _this.sortOrder) || other.sortOrder == _this.sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as NewOrderItem;
  return Object.hash(runtimeType,_this.productId,_this.productVariantId,_this.quantity,_this.unitPrice,_this.unitCost,_this.notes,_this.sortOrder);
}

@override
String toString() {
  final _this = this as NewOrderItem;
  return 'NewOrderItem(productId: ${_this.productId}, productVariantId: ${_this.productVariantId}, quantity: ${_this.quantity}, unitPrice: ${_this.unitPrice}, unitCost: ${_this.unitCost}, notes: ${_this.notes}, sortOrder: ${_this.sortOrder})';
}


}

/// @nodoc
abstract mixin class $NewOrderItemCopyWith<$Res>  {
  factory $NewOrderItemCopyWith(NewOrderItem value, $Res Function(NewOrderItem) _then) = _$NewOrderItemCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'product_id') int productId,@JsonKey(name: 'product_variant_id') int productVariantId, String quantity,@JsonKey(name: 'unit_price', includeIfNull: false) String? unitPrice,@JsonKey(name: 'unit_cost', includeIfNull: false) String? unitCost,@JsonKey(includeIfNull: false) String? notes,@JsonKey(name: 'sort_order') int sortOrder
});




}
/// @nodoc
class _$NewOrderItemCopyWithImpl<$Res>
    implements $NewOrderItemCopyWith<$Res> {
  _$NewOrderItemCopyWithImpl(this._self, this._then);

  final NewOrderItem _self;
  final $Res Function(NewOrderItem) _then;

/// Create a copy of NewOrderItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productId = null,Object? productVariantId = null,Object? quantity = null,Object? unitPrice = freezed,Object? unitCost = freezed,Object? notes = freezed,Object? sortOrder = null,}) {
  return _then(NewOrderItem(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as int,productVariantId: null == productVariantId ? _self.productVariantId : productVariantId // ignore: cast_nullable_to_non_nullable
as int,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,unitPrice: freezed == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String?,unitCost: freezed == unitCost ? _self.unitCost : unitCost // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [NewOrderItem].
extension NewOrderItemPatterns on NewOrderItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewOrderItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewOrderItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewOrderItem value)  $default,){
final _that = this;
switch (_that) {
case _NewOrderItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewOrderItem value)?  $default,){
final _that = this;
switch (_that) {
case _NewOrderItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'product_id')  int productId, @JsonKey(name: 'product_variant_id')  int productVariantId,  String quantity, @JsonKey(name: 'unit_price', includeIfNull: false)  String? unitPrice, @JsonKey(name: 'unit_cost', includeIfNull: false)  String? unitCost, @JsonKey(includeIfNull: false)  String? notes, @JsonKey(name: 'sort_order')  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewOrderItem() when $default != null:
return $default(_that.productId,_that.productVariantId,_that.quantity,_that.unitPrice,_that.unitCost,_that.notes,_that.sortOrder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'product_id')  int productId, @JsonKey(name: 'product_variant_id')  int productVariantId,  String quantity, @JsonKey(name: 'unit_price', includeIfNull: false)  String? unitPrice, @JsonKey(name: 'unit_cost', includeIfNull: false)  String? unitCost, @JsonKey(includeIfNull: false)  String? notes, @JsonKey(name: 'sort_order')  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _NewOrderItem():
return $default(_that.productId,_that.productVariantId,_that.quantity,_that.unitPrice,_that.unitCost,_that.notes,_that.sortOrder);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'product_id')  int productId, @JsonKey(name: 'product_variant_id')  int productVariantId,  String quantity, @JsonKey(name: 'unit_price', includeIfNull: false)  String? unitPrice, @JsonKey(name: 'unit_cost', includeIfNull: false)  String? unitCost, @JsonKey(includeIfNull: false)  String? notes, @JsonKey(name: 'sort_order')  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _NewOrderItem() when $default != null:
return $default(_that.productId,_that.productVariantId,_that.quantity,_that.unitPrice,_that.unitCost,_that.notes,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NewOrderItem implements NewOrderItem {
  const _NewOrderItem({@JsonKey(name: 'product_id') required this.productId, @JsonKey(name: 'product_variant_id') required this.productVariantId, required this.quantity, @JsonKey(name: 'unit_price', includeIfNull: false) this.unitPrice, @JsonKey(name: 'unit_cost', includeIfNull: false) this.unitCost, @JsonKey(includeIfNull: false) this.notes, @JsonKey(name: 'sort_order') this.sortOrder = 0});
  factory _NewOrderItem.fromJson(Map<String, dynamic> json) => _$NewOrderItemFromJson(json);

@override@JsonKey(name: 'product_id') final  int productId;
@override@JsonKey(name: 'product_variant_id') final  int productVariantId;
/// A decimal string, already in ASCII digits — `'300'`, not `'٣٠٠'`.
@override final  String quantity;
/// **Honoured only for a product the catalogue prices «حسب الطلب»**, and ignored otherwise:
/// for a listed product the catalogue's rate wins, which is what stops a posted number
/// undercutting an agreed price. Omitted when the app has no business naming one.
@override@JsonKey(name: 'unit_price', includeIfNull: false) final  String? unitPrice;
/// What the vendor charges for one unit of a وسيط line, typed for this order. **Honoured
/// only on such a line**, and refused by the server from anybody without
/// `products.view_cost` — so it is omitted unless the form drew the box.
@override@JsonKey(name: 'unit_cost', includeIfNull: false) final  String? unitCost;
@override@JsonKey(includeIfNull: false) final  String? notes;
/// The order the clerk put the lines in, kept so the invoice reads the way it was written.
@override@JsonKey(name: 'sort_order') final  int sortOrder;

/// Create a copy of NewOrderItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewOrderItemCopyWith<_NewOrderItem> get copyWith => __$NewOrderItemCopyWithImpl<_NewOrderItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NewOrderItemToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewOrderItem&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productVariantId, productVariantId) || other.productVariantId == productVariantId)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.unitCost, unitCost) || other.unitCost == unitCost)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,productId,productVariantId,quantity,unitPrice,unitCost,notes,sortOrder);
}

@override
String toString() {
    return 'NewOrderItem(productId: $productId, productVariantId: $productVariantId, quantity: $quantity, unitPrice: $unitPrice, unitCost: $unitCost, notes: $notes, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$NewOrderItemCopyWith<$Res> implements $NewOrderItemCopyWith<$Res> {
  factory _$NewOrderItemCopyWith(_NewOrderItem value, $Res Function(_NewOrderItem) _then) = __$NewOrderItemCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'product_id') int productId,@JsonKey(name: 'product_variant_id') int productVariantId, String quantity,@JsonKey(name: 'unit_price', includeIfNull: false) String? unitPrice,@JsonKey(name: 'unit_cost', includeIfNull: false) String? unitCost,@JsonKey(includeIfNull: false) String? notes,@JsonKey(name: 'sort_order') int sortOrder
});




}
/// @nodoc
class __$NewOrderItemCopyWithImpl<$Res>
    implements _$NewOrderItemCopyWith<$Res> {
  __$NewOrderItemCopyWithImpl(this._self, this._then);

  final _NewOrderItem _self;
  final $Res Function(_NewOrderItem) _then;

/// Create a copy of NewOrderItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productId = null,Object? productVariantId = null,Object? quantity = null,Object? unitPrice = freezed,Object? unitCost = freezed,Object? notes = freezed,Object? sortOrder = null,}) {
  return _then(_NewOrderItem(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as int,productVariantId: null == productVariantId ? _self.productVariantId : productVariantId // ignore: cast_nullable_to_non_nullable
as int,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,unitPrice: freezed == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String?,unitCost: freezed == unitCost ? _self.unitCost : unitCost // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
