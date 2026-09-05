// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'deal_order.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DealOrder {

@JsonKey(name: 'order_id') int get orderId; String get code; String get status;@JsonKey(name: 'status_label') String get statusLabel;@JsonKey(name: 'customer_name') String? get customerName;/// When it reached the customer, or when it was placed for one still on the road.
@JsonKey(name: 'occurred_at') DateTime? get occurredAt;/// The order's whole money, so the deal's slice of it can be read against something.
@JsonKey(name: 'grand_total') String get grandTotal;/// Units drawn off **this** deal's shelves — not the order's quantity, which may have come
/// off several people's stock at once.
 String get quantity;@JsonKey(name: 'material_cost') String get materialCost; String get revenue;@JsonKey(name: 'conversion_cost') String get conversionCost; String get profit;/// Null until the order reached «تم الاستلام» and the ledger was written. Zero is a
/// different answer: an order that broke exactly even.
@JsonKey(name: 'investors_share') String? get investorsShare;@JsonKey(name: 'company_share') String? get companyShare;@JsonKey(name: 'is_posted') bool get isPosted;
/// Create a copy of DealOrder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DealOrderCopyWith<DealOrder> get copyWith => _$DealOrderCopyWithImpl<DealOrder>(this as DealOrder, _$identity);

  /// Serializes this DealOrder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DealOrder&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.code, code) || other.code == code)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.customerName, customerName) || other.customerName == customerName)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.grandTotal, grandTotal) || other.grandTotal == grandTotal)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.materialCost, materialCost) || other.materialCost == materialCost)&&(identical(other.revenue, revenue) || other.revenue == revenue)&&(identical(other.conversionCost, conversionCost) || other.conversionCost == conversionCost)&&(identical(other.profit, profit) || other.profit == profit)&&(identical(other.investorsShare, investorsShare) || other.investorsShare == investorsShare)&&(identical(other.companyShare, companyShare) || other.companyShare == companyShare)&&(identical(other.isPosted, isPosted) || other.isPosted == isPosted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,orderId,code,status,statusLabel,customerName,occurredAt,grandTotal,quantity,materialCost,revenue,conversionCost,profit,investorsShare,companyShare,isPosted);

@override
String toString() {
  return 'DealOrder(orderId: $orderId, code: $code, status: $status, statusLabel: $statusLabel, customerName: $customerName, occurredAt: $occurredAt, grandTotal: $grandTotal, quantity: $quantity, materialCost: $materialCost, revenue: $revenue, conversionCost: $conversionCost, profit: $profit, investorsShare: $investorsShare, companyShare: $companyShare, isPosted: $isPosted)';
}


}

/// @nodoc
abstract mixin class $DealOrderCopyWith<$Res>  {
  factory $DealOrderCopyWith(DealOrder value, $Res Function(DealOrder) _then) = _$DealOrderCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'order_id') int orderId, String code, String status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'customer_name') String? customerName,@JsonKey(name: 'occurred_at') DateTime? occurredAt,@JsonKey(name: 'grand_total') String grandTotal, String quantity,@JsonKey(name: 'material_cost') String materialCost, String revenue,@JsonKey(name: 'conversion_cost') String conversionCost, String profit,@JsonKey(name: 'investors_share') String? investorsShare,@JsonKey(name: 'company_share') String? companyShare,@JsonKey(name: 'is_posted') bool isPosted
});




}
/// @nodoc
class _$DealOrderCopyWithImpl<$Res>
    implements $DealOrderCopyWith<$Res> {
  _$DealOrderCopyWithImpl(this._self, this._then);

  final DealOrder _self;
  final $Res Function(DealOrder) _then;

/// Create a copy of DealOrder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? orderId = null,Object? code = null,Object? status = null,Object? statusLabel = null,Object? customerName = freezed,Object? occurredAt = freezed,Object? grandTotal = null,Object? quantity = null,Object? materialCost = null,Object? revenue = null,Object? conversionCost = null,Object? profit = null,Object? investorsShare = freezed,Object? companyShare = freezed,Object? isPosted = null,}) {
  return _then(_self.copyWith(
orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,customerName: freezed == customerName ? _self.customerName : customerName // ignore: cast_nullable_to_non_nullable
as String?,occurredAt: freezed == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,grandTotal: null == grandTotal ? _self.grandTotal : grandTotal // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,materialCost: null == materialCost ? _self.materialCost : materialCost // ignore: cast_nullable_to_non_nullable
as String,revenue: null == revenue ? _self.revenue : revenue // ignore: cast_nullable_to_non_nullable
as String,conversionCost: null == conversionCost ? _self.conversionCost : conversionCost // ignore: cast_nullable_to_non_nullable
as String,profit: null == profit ? _self.profit : profit // ignore: cast_nullable_to_non_nullable
as String,investorsShare: freezed == investorsShare ? _self.investorsShare : investorsShare // ignore: cast_nullable_to_non_nullable
as String?,companyShare: freezed == companyShare ? _self.companyShare : companyShare // ignore: cast_nullable_to_non_nullable
as String?,isPosted: null == isPosted ? _self.isPosted : isPosted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [DealOrder].
extension DealOrderPatterns on DealOrder {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DealOrder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DealOrder() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DealOrder value)  $default,){
final _that = this;
switch (_that) {
case _DealOrder():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DealOrder value)?  $default,){
final _that = this;
switch (_that) {
case _DealOrder() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'order_id')  int orderId,  String code,  String status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'customer_name')  String? customerName, @JsonKey(name: 'occurred_at')  DateTime? occurredAt, @JsonKey(name: 'grand_total')  String grandTotal,  String quantity, @JsonKey(name: 'material_cost')  String materialCost,  String revenue, @JsonKey(name: 'conversion_cost')  String conversionCost,  String profit, @JsonKey(name: 'investors_share')  String? investorsShare, @JsonKey(name: 'company_share')  String? companyShare, @JsonKey(name: 'is_posted')  bool isPosted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DealOrder() when $default != null:
return $default(_that.orderId,_that.code,_that.status,_that.statusLabel,_that.customerName,_that.occurredAt,_that.grandTotal,_that.quantity,_that.materialCost,_that.revenue,_that.conversionCost,_that.profit,_that.investorsShare,_that.companyShare,_that.isPosted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'order_id')  int orderId,  String code,  String status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'customer_name')  String? customerName, @JsonKey(name: 'occurred_at')  DateTime? occurredAt, @JsonKey(name: 'grand_total')  String grandTotal,  String quantity, @JsonKey(name: 'material_cost')  String materialCost,  String revenue, @JsonKey(name: 'conversion_cost')  String conversionCost,  String profit, @JsonKey(name: 'investors_share')  String? investorsShare, @JsonKey(name: 'company_share')  String? companyShare, @JsonKey(name: 'is_posted')  bool isPosted)  $default,) {final _that = this;
switch (_that) {
case _DealOrder():
return $default(_that.orderId,_that.code,_that.status,_that.statusLabel,_that.customerName,_that.occurredAt,_that.grandTotal,_that.quantity,_that.materialCost,_that.revenue,_that.conversionCost,_that.profit,_that.investorsShare,_that.companyShare,_that.isPosted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'order_id')  int orderId,  String code,  String status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'customer_name')  String? customerName, @JsonKey(name: 'occurred_at')  DateTime? occurredAt, @JsonKey(name: 'grand_total')  String grandTotal,  String quantity, @JsonKey(name: 'material_cost')  String materialCost,  String revenue, @JsonKey(name: 'conversion_cost')  String conversionCost,  String profit, @JsonKey(name: 'investors_share')  String? investorsShare, @JsonKey(name: 'company_share')  String? companyShare, @JsonKey(name: 'is_posted')  bool isPosted)?  $default,) {final _that = this;
switch (_that) {
case _DealOrder() when $default != null:
return $default(_that.orderId,_that.code,_that.status,_that.statusLabel,_that.customerName,_that.occurredAt,_that.grandTotal,_that.quantity,_that.materialCost,_that.revenue,_that.conversionCost,_that.profit,_that.investorsShare,_that.companyShare,_that.isPosted);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DealOrder implements DealOrder {
  const _DealOrder({@JsonKey(name: 'order_id') required this.orderId, required this.code, required this.status, @JsonKey(name: 'status_label') required this.statusLabel, @JsonKey(name: 'customer_name') this.customerName, @JsonKey(name: 'occurred_at') this.occurredAt, @JsonKey(name: 'grand_total') required this.grandTotal, required this.quantity, @JsonKey(name: 'material_cost') required this.materialCost, required this.revenue, @JsonKey(name: 'conversion_cost') required this.conversionCost, required this.profit, @JsonKey(name: 'investors_share') this.investorsShare, @JsonKey(name: 'company_share') this.companyShare, @JsonKey(name: 'is_posted') this.isPosted = false});
  factory _DealOrder.fromJson(Map<String, dynamic> json) => _$DealOrderFromJson(json);

@override@JsonKey(name: 'order_id') final  int orderId;
@override final  String code;
@override final  String status;
@override@JsonKey(name: 'status_label') final  String statusLabel;
@override@JsonKey(name: 'customer_name') final  String? customerName;
/// When it reached the customer, or when it was placed for one still on the road.
@override@JsonKey(name: 'occurred_at') final  DateTime? occurredAt;
/// The order's whole money, so the deal's slice of it can be read against something.
@override@JsonKey(name: 'grand_total') final  String grandTotal;
/// Units drawn off **this** deal's shelves — not the order's quantity, which may have come
/// off several people's stock at once.
@override final  String quantity;
@override@JsonKey(name: 'material_cost') final  String materialCost;
@override final  String revenue;
@override@JsonKey(name: 'conversion_cost') final  String conversionCost;
@override final  String profit;
/// Null until the order reached «تم الاستلام» and the ledger was written. Zero is a
/// different answer: an order that broke exactly even.
@override@JsonKey(name: 'investors_share') final  String? investorsShare;
@override@JsonKey(name: 'company_share') final  String? companyShare;
@override@JsonKey(name: 'is_posted') final  bool isPosted;

/// Create a copy of DealOrder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DealOrderCopyWith<_DealOrder> get copyWith => __$DealOrderCopyWithImpl<_DealOrder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DealOrderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DealOrder&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.code, code) || other.code == code)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.customerName, customerName) || other.customerName == customerName)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.grandTotal, grandTotal) || other.grandTotal == grandTotal)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.materialCost, materialCost) || other.materialCost == materialCost)&&(identical(other.revenue, revenue) || other.revenue == revenue)&&(identical(other.conversionCost, conversionCost) || other.conversionCost == conversionCost)&&(identical(other.profit, profit) || other.profit == profit)&&(identical(other.investorsShare, investorsShare) || other.investorsShare == investorsShare)&&(identical(other.companyShare, companyShare) || other.companyShare == companyShare)&&(identical(other.isPosted, isPosted) || other.isPosted == isPosted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,orderId,code,status,statusLabel,customerName,occurredAt,grandTotal,quantity,materialCost,revenue,conversionCost,profit,investorsShare,companyShare,isPosted);

@override
String toString() {
  return 'DealOrder(orderId: $orderId, code: $code, status: $status, statusLabel: $statusLabel, customerName: $customerName, occurredAt: $occurredAt, grandTotal: $grandTotal, quantity: $quantity, materialCost: $materialCost, revenue: $revenue, conversionCost: $conversionCost, profit: $profit, investorsShare: $investorsShare, companyShare: $companyShare, isPosted: $isPosted)';
}


}

/// @nodoc
abstract mixin class _$DealOrderCopyWith<$Res> implements $DealOrderCopyWith<$Res> {
  factory _$DealOrderCopyWith(_DealOrder value, $Res Function(_DealOrder) _then) = __$DealOrderCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'order_id') int orderId, String code, String status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'customer_name') String? customerName,@JsonKey(name: 'occurred_at') DateTime? occurredAt,@JsonKey(name: 'grand_total') String grandTotal, String quantity,@JsonKey(name: 'material_cost') String materialCost, String revenue,@JsonKey(name: 'conversion_cost') String conversionCost, String profit,@JsonKey(name: 'investors_share') String? investorsShare,@JsonKey(name: 'company_share') String? companyShare,@JsonKey(name: 'is_posted') bool isPosted
});




}
/// @nodoc
class __$DealOrderCopyWithImpl<$Res>
    implements _$DealOrderCopyWith<$Res> {
  __$DealOrderCopyWithImpl(this._self, this._then);

  final _DealOrder _self;
  final $Res Function(_DealOrder) _then;

/// Create a copy of DealOrder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? orderId = null,Object? code = null,Object? status = null,Object? statusLabel = null,Object? customerName = freezed,Object? occurredAt = freezed,Object? grandTotal = null,Object? quantity = null,Object? materialCost = null,Object? revenue = null,Object? conversionCost = null,Object? profit = null,Object? investorsShare = freezed,Object? companyShare = freezed,Object? isPosted = null,}) {
  return _then(_DealOrder(
orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,customerName: freezed == customerName ? _self.customerName : customerName // ignore: cast_nullable_to_non_nullable
as String?,occurredAt: freezed == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,grandTotal: null == grandTotal ? _self.grandTotal : grandTotal // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,materialCost: null == materialCost ? _self.materialCost : materialCost // ignore: cast_nullable_to_non_nullable
as String,revenue: null == revenue ? _self.revenue : revenue // ignore: cast_nullable_to_non_nullable
as String,conversionCost: null == conversionCost ? _self.conversionCost : conversionCost // ignore: cast_nullable_to_non_nullable
as String,profit: null == profit ? _self.profit : profit // ignore: cast_nullable_to_non_nullable
as String,investorsShare: freezed == investorsShare ? _self.investorsShare : investorsShare // ignore: cast_nullable_to_non_nullable
as String?,companyShare: freezed == companyShare ? _self.companyShare : companyShare // ignore: cast_nullable_to_non_nullable
as String?,isPosted: null == isPosted ? _self.isPosted : isPosted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
