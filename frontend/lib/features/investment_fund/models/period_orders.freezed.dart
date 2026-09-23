// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'period_orders.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PeriodInvestorShare {

@JsonKey(name: 'investor_id') int get investorId; String get name; String get amount;
/// Create a copy of PeriodInvestorShare
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeriodInvestorShareCopyWith<PeriodInvestorShare> get copyWith => _$PeriodInvestorShareCopyWithImpl<PeriodInvestorShare>(this as PeriodInvestorShare, _$identity);

  /// Serializes this PeriodInvestorShare to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodInvestorShare&&(identical(other.investorId, investorId) || other.investorId == investorId)&&(identical(other.name, name) || other.name == name)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,investorId,name,amount);

@override
String toString() {
  return 'PeriodInvestorShare(investorId: $investorId, name: $name, amount: $amount)';
}


}

/// @nodoc
abstract mixin class $PeriodInvestorShareCopyWith<$Res>  {
  factory $PeriodInvestorShareCopyWith(PeriodInvestorShare value, $Res Function(PeriodInvestorShare) _then) = _$PeriodInvestorShareCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'investor_id') int investorId, String name, String amount
});




}
/// @nodoc
class _$PeriodInvestorShareCopyWithImpl<$Res>
    implements $PeriodInvestorShareCopyWith<$Res> {
  _$PeriodInvestorShareCopyWithImpl(this._self, this._then);

  final PeriodInvestorShare _self;
  final $Res Function(PeriodInvestorShare) _then;

/// Create a copy of PeriodInvestorShare
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? investorId = null,Object? name = null,Object? amount = null,}) {
  return _then(_self.copyWith(
investorId: null == investorId ? _self.investorId : investorId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PeriodInvestorShare].
extension PeriodInvestorSharePatterns on PeriodInvestorShare {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PeriodInvestorShare value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PeriodInvestorShare() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PeriodInvestorShare value)  $default,){
final _that = this;
switch (_that) {
case _PeriodInvestorShare():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PeriodInvestorShare value)?  $default,){
final _that = this;
switch (_that) {
case _PeriodInvestorShare() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'investor_id')  int investorId,  String name,  String amount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PeriodInvestorShare() when $default != null:
return $default(_that.investorId,_that.name,_that.amount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'investor_id')  int investorId,  String name,  String amount)  $default,) {final _that = this;
switch (_that) {
case _PeriodInvestorShare():
return $default(_that.investorId,_that.name,_that.amount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'investor_id')  int investorId,  String name,  String amount)?  $default,) {final _that = this;
switch (_that) {
case _PeriodInvestorShare() when $default != null:
return $default(_that.investorId,_that.name,_that.amount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PeriodInvestorShare implements PeriodInvestorShare {
  const _PeriodInvestorShare({@JsonKey(name: 'investor_id') required this.investorId, required this.name, required this.amount});
  factory _PeriodInvestorShare.fromJson(Map<String, dynamic> json) => _$PeriodInvestorShareFromJson(json);

@override@JsonKey(name: 'investor_id') final  int investorId;
@override final  String name;
@override final  String amount;

/// Create a copy of PeriodInvestorShare
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PeriodInvestorShareCopyWith<_PeriodInvestorShare> get copyWith => __$PeriodInvestorShareCopyWithImpl<_PeriodInvestorShare>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PeriodInvestorShareToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PeriodInvestorShare&&(identical(other.investorId, investorId) || other.investorId == investorId)&&(identical(other.name, name) || other.name == name)&&(identical(other.amount, amount) || other.amount == amount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,investorId,name,amount);

@override
String toString() {
  return 'PeriodInvestorShare(investorId: $investorId, name: $name, amount: $amount)';
}


}

/// @nodoc
abstract mixin class _$PeriodInvestorShareCopyWith<$Res> implements $PeriodInvestorShareCopyWith<$Res> {
  factory _$PeriodInvestorShareCopyWith(_PeriodInvestorShare value, $Res Function(_PeriodInvestorShare) _then) = __$PeriodInvestorShareCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'investor_id') int investorId, String name, String amount
});




}
/// @nodoc
class __$PeriodInvestorShareCopyWithImpl<$Res>
    implements _$PeriodInvestorShareCopyWith<$Res> {
  __$PeriodInvestorShareCopyWithImpl(this._self, this._then);

  final _PeriodInvestorShare _self;
  final $Res Function(_PeriodInvestorShare) _then;

/// Create a copy of PeriodInvestorShare
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? investorId = null,Object? name = null,Object? amount = null,}) {
  return _then(_PeriodInvestorShare(
investorId: null == investorId ? _self.investorId : investorId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PeriodOrder {

@JsonKey(name: 'order_id') int get orderId; String get code; String get status;@JsonKey(name: 'status_label') String get statusLabel;@JsonKey(name: 'customer_name') String? get customerName;/// يومُ وصولها العميل، أو يومُ كتابتها لطلبيةٍ لم تصل بعد.
@JsonKey(name: 'occurred_at') DateTime? get occurredAt;/// مالُ الطلبية كلُّه — ليُقرأ نصيبُ المستثمرين في مقابل شيء.
@JsonKey(name: 'grand_total') String get grandTotal;/// مجموعُ ما أخذه المستثمرون منها، وهو جمعُ [investors] لا رقمٌ ثانٍ.
@JsonKey(name: 'investors_total') String get investorsTotal; List<PeriodInvestorShare> get investors;
/// Create a copy of PeriodOrder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeriodOrderCopyWith<PeriodOrder> get copyWith => _$PeriodOrderCopyWithImpl<PeriodOrder>(this as PeriodOrder, _$identity);

  /// Serializes this PeriodOrder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodOrder&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.code, code) || other.code == code)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.customerName, customerName) || other.customerName == customerName)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.grandTotal, grandTotal) || other.grandTotal == grandTotal)&&(identical(other.investorsTotal, investorsTotal) || other.investorsTotal == investorsTotal)&&const DeepCollectionEquality().equals(other.investors, investors));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,orderId,code,status,statusLabel,customerName,occurredAt,grandTotal,investorsTotal,const DeepCollectionEquality().hash(investors));

@override
String toString() {
  return 'PeriodOrder(orderId: $orderId, code: $code, status: $status, statusLabel: $statusLabel, customerName: $customerName, occurredAt: $occurredAt, grandTotal: $grandTotal, investorsTotal: $investorsTotal, investors: $investors)';
}


}

/// @nodoc
abstract mixin class $PeriodOrderCopyWith<$Res>  {
  factory $PeriodOrderCopyWith(PeriodOrder value, $Res Function(PeriodOrder) _then) = _$PeriodOrderCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'order_id') int orderId, String code, String status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'customer_name') String? customerName,@JsonKey(name: 'occurred_at') DateTime? occurredAt,@JsonKey(name: 'grand_total') String grandTotal,@JsonKey(name: 'investors_total') String investorsTotal, List<PeriodInvestorShare> investors
});




}
/// @nodoc
class _$PeriodOrderCopyWithImpl<$Res>
    implements $PeriodOrderCopyWith<$Res> {
  _$PeriodOrderCopyWithImpl(this._self, this._then);

  final PeriodOrder _self;
  final $Res Function(PeriodOrder) _then;

/// Create a copy of PeriodOrder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? orderId = null,Object? code = null,Object? status = null,Object? statusLabel = null,Object? customerName = freezed,Object? occurredAt = freezed,Object? grandTotal = null,Object? investorsTotal = null,Object? investors = null,}) {
  return _then(_self.copyWith(
orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,customerName: freezed == customerName ? _self.customerName : customerName // ignore: cast_nullable_to_non_nullable
as String?,occurredAt: freezed == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,grandTotal: null == grandTotal ? _self.grandTotal : grandTotal // ignore: cast_nullable_to_non_nullable
as String,investorsTotal: null == investorsTotal ? _self.investorsTotal : investorsTotal // ignore: cast_nullable_to_non_nullable
as String,investors: null == investors ? _self.investors : investors // ignore: cast_nullable_to_non_nullable
as List<PeriodInvestorShare>,
  ));
}

}


/// Adds pattern-matching-related methods to [PeriodOrder].
extension PeriodOrderPatterns on PeriodOrder {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PeriodOrder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PeriodOrder() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PeriodOrder value)  $default,){
final _that = this;
switch (_that) {
case _PeriodOrder():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PeriodOrder value)?  $default,){
final _that = this;
switch (_that) {
case _PeriodOrder() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'order_id')  int orderId,  String code,  String status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'customer_name')  String? customerName, @JsonKey(name: 'occurred_at')  DateTime? occurredAt, @JsonKey(name: 'grand_total')  String grandTotal, @JsonKey(name: 'investors_total')  String investorsTotal,  List<PeriodInvestorShare> investors)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PeriodOrder() when $default != null:
return $default(_that.orderId,_that.code,_that.status,_that.statusLabel,_that.customerName,_that.occurredAt,_that.grandTotal,_that.investorsTotal,_that.investors);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'order_id')  int orderId,  String code,  String status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'customer_name')  String? customerName, @JsonKey(name: 'occurred_at')  DateTime? occurredAt, @JsonKey(name: 'grand_total')  String grandTotal, @JsonKey(name: 'investors_total')  String investorsTotal,  List<PeriodInvestorShare> investors)  $default,) {final _that = this;
switch (_that) {
case _PeriodOrder():
return $default(_that.orderId,_that.code,_that.status,_that.statusLabel,_that.customerName,_that.occurredAt,_that.grandTotal,_that.investorsTotal,_that.investors);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'order_id')  int orderId,  String code,  String status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'customer_name')  String? customerName, @JsonKey(name: 'occurred_at')  DateTime? occurredAt, @JsonKey(name: 'grand_total')  String grandTotal, @JsonKey(name: 'investors_total')  String investorsTotal,  List<PeriodInvestorShare> investors)?  $default,) {final _that = this;
switch (_that) {
case _PeriodOrder() when $default != null:
return $default(_that.orderId,_that.code,_that.status,_that.statusLabel,_that.customerName,_that.occurredAt,_that.grandTotal,_that.investorsTotal,_that.investors);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PeriodOrder implements PeriodOrder {
  const _PeriodOrder({@JsonKey(name: 'order_id') required this.orderId, required this.code, required this.status, @JsonKey(name: 'status_label') required this.statusLabel, @JsonKey(name: 'customer_name') this.customerName, @JsonKey(name: 'occurred_at') this.occurredAt, @JsonKey(name: 'grand_total') required this.grandTotal, @JsonKey(name: 'investors_total') required this.investorsTotal, final  List<PeriodInvestorShare> investors = const <PeriodInvestorShare>[]}): _investors = investors;
  factory _PeriodOrder.fromJson(Map<String, dynamic> json) => _$PeriodOrderFromJson(json);

@override@JsonKey(name: 'order_id') final  int orderId;
@override final  String code;
@override final  String status;
@override@JsonKey(name: 'status_label') final  String statusLabel;
@override@JsonKey(name: 'customer_name') final  String? customerName;
/// يومُ وصولها العميل، أو يومُ كتابتها لطلبيةٍ لم تصل بعد.
@override@JsonKey(name: 'occurred_at') final  DateTime? occurredAt;
/// مالُ الطلبية كلُّه — ليُقرأ نصيبُ المستثمرين في مقابل شيء.
@override@JsonKey(name: 'grand_total') final  String grandTotal;
/// مجموعُ ما أخذه المستثمرون منها، وهو جمعُ [investors] لا رقمٌ ثانٍ.
@override@JsonKey(name: 'investors_total') final  String investorsTotal;
 final  List<PeriodInvestorShare> _investors;
@override@JsonKey() List<PeriodInvestorShare> get investors {
  if (_investors is EqualUnmodifiableListView) return _investors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_investors);
}


/// Create a copy of PeriodOrder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PeriodOrderCopyWith<_PeriodOrder> get copyWith => __$PeriodOrderCopyWithImpl<_PeriodOrder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PeriodOrderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PeriodOrder&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.code, code) || other.code == code)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.customerName, customerName) || other.customerName == customerName)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.grandTotal, grandTotal) || other.grandTotal == grandTotal)&&(identical(other.investorsTotal, investorsTotal) || other.investorsTotal == investorsTotal)&&const DeepCollectionEquality().equals(other._investors, _investors));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,orderId,code,status,statusLabel,customerName,occurredAt,grandTotal,investorsTotal,const DeepCollectionEquality().hash(_investors));

@override
String toString() {
  return 'PeriodOrder(orderId: $orderId, code: $code, status: $status, statusLabel: $statusLabel, customerName: $customerName, occurredAt: $occurredAt, grandTotal: $grandTotal, investorsTotal: $investorsTotal, investors: $investors)';
}


}

/// @nodoc
abstract mixin class _$PeriodOrderCopyWith<$Res> implements $PeriodOrderCopyWith<$Res> {
  factory _$PeriodOrderCopyWith(_PeriodOrder value, $Res Function(_PeriodOrder) _then) = __$PeriodOrderCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'order_id') int orderId, String code, String status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'customer_name') String? customerName,@JsonKey(name: 'occurred_at') DateTime? occurredAt,@JsonKey(name: 'grand_total') String grandTotal,@JsonKey(name: 'investors_total') String investorsTotal, List<PeriodInvestorShare> investors
});




}
/// @nodoc
class __$PeriodOrderCopyWithImpl<$Res>
    implements _$PeriodOrderCopyWith<$Res> {
  __$PeriodOrderCopyWithImpl(this._self, this._then);

  final _PeriodOrder _self;
  final $Res Function(_PeriodOrder) _then;

/// Create a copy of PeriodOrder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? orderId = null,Object? code = null,Object? status = null,Object? statusLabel = null,Object? customerName = freezed,Object? occurredAt = freezed,Object? grandTotal = null,Object? investorsTotal = null,Object? investors = null,}) {
  return _then(_PeriodOrder(
orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,customerName: freezed == customerName ? _self.customerName : customerName // ignore: cast_nullable_to_non_nullable
as String?,occurredAt: freezed == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as DateTime?,grandTotal: null == grandTotal ? _self.grandTotal : grandTotal // ignore: cast_nullable_to_non_nullable
as String,investorsTotal: null == investorsTotal ? _self.investorsTotal : investorsTotal // ignore: cast_nullable_to_non_nullable
as String,investors: null == investors ? _self._investors : investors // ignore: cast_nullable_to_non_nullable
as List<PeriodInvestorShare>,
  ));
}


}


/// @nodoc
mixin _$PeriodOrdersTotals {

 int get orders;@JsonKey(name: 'investors_total') String get investorsTotal;
/// Create a copy of PeriodOrdersTotals
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeriodOrdersTotalsCopyWith<PeriodOrdersTotals> get copyWith => _$PeriodOrdersTotalsCopyWithImpl<PeriodOrdersTotals>(this as PeriodOrdersTotals, _$identity);

  /// Serializes this PeriodOrdersTotals to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodOrdersTotals&&(identical(other.orders, orders) || other.orders == orders)&&(identical(other.investorsTotal, investorsTotal) || other.investorsTotal == investorsTotal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,orders,investorsTotal);

@override
String toString() {
  return 'PeriodOrdersTotals(orders: $orders, investorsTotal: $investorsTotal)';
}


}

/// @nodoc
abstract mixin class $PeriodOrdersTotalsCopyWith<$Res>  {
  factory $PeriodOrdersTotalsCopyWith(PeriodOrdersTotals value, $Res Function(PeriodOrdersTotals) _then) = _$PeriodOrdersTotalsCopyWithImpl;
@useResult
$Res call({
 int orders,@JsonKey(name: 'investors_total') String investorsTotal
});




}
/// @nodoc
class _$PeriodOrdersTotalsCopyWithImpl<$Res>
    implements $PeriodOrdersTotalsCopyWith<$Res> {
  _$PeriodOrdersTotalsCopyWithImpl(this._self, this._then);

  final PeriodOrdersTotals _self;
  final $Res Function(PeriodOrdersTotals) _then;

/// Create a copy of PeriodOrdersTotals
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? orders = null,Object? investorsTotal = null,}) {
  return _then(_self.copyWith(
orders: null == orders ? _self.orders : orders // ignore: cast_nullable_to_non_nullable
as int,investorsTotal: null == investorsTotal ? _self.investorsTotal : investorsTotal // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PeriodOrdersTotals].
extension PeriodOrdersTotalsPatterns on PeriodOrdersTotals {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PeriodOrdersTotals value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PeriodOrdersTotals() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PeriodOrdersTotals value)  $default,){
final _that = this;
switch (_that) {
case _PeriodOrdersTotals():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PeriodOrdersTotals value)?  $default,){
final _that = this;
switch (_that) {
case _PeriodOrdersTotals() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int orders, @JsonKey(name: 'investors_total')  String investorsTotal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PeriodOrdersTotals() when $default != null:
return $default(_that.orders,_that.investorsTotal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int orders, @JsonKey(name: 'investors_total')  String investorsTotal)  $default,) {final _that = this;
switch (_that) {
case _PeriodOrdersTotals():
return $default(_that.orders,_that.investorsTotal);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int orders, @JsonKey(name: 'investors_total')  String investorsTotal)?  $default,) {final _that = this;
switch (_that) {
case _PeriodOrdersTotals() when $default != null:
return $default(_that.orders,_that.investorsTotal);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PeriodOrdersTotals implements PeriodOrdersTotals {
  const _PeriodOrdersTotals({this.orders = 0, @JsonKey(name: 'investors_total') this.investorsTotal = '0.00'});
  factory _PeriodOrdersTotals.fromJson(Map<String, dynamic> json) => _$PeriodOrdersTotalsFromJson(json);

@override@JsonKey() final  int orders;
@override@JsonKey(name: 'investors_total') final  String investorsTotal;

/// Create a copy of PeriodOrdersTotals
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PeriodOrdersTotalsCopyWith<_PeriodOrdersTotals> get copyWith => __$PeriodOrdersTotalsCopyWithImpl<_PeriodOrdersTotals>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PeriodOrdersTotalsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PeriodOrdersTotals&&(identical(other.orders, orders) || other.orders == orders)&&(identical(other.investorsTotal, investorsTotal) || other.investorsTotal == investorsTotal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,orders,investorsTotal);

@override
String toString() {
  return 'PeriodOrdersTotals(orders: $orders, investorsTotal: $investorsTotal)';
}


}

/// @nodoc
abstract mixin class _$PeriodOrdersTotalsCopyWith<$Res> implements $PeriodOrdersTotalsCopyWith<$Res> {
  factory _$PeriodOrdersTotalsCopyWith(_PeriodOrdersTotals value, $Res Function(_PeriodOrdersTotals) _then) = __$PeriodOrdersTotalsCopyWithImpl;
@override @useResult
$Res call({
 int orders,@JsonKey(name: 'investors_total') String investorsTotal
});




}
/// @nodoc
class __$PeriodOrdersTotalsCopyWithImpl<$Res>
    implements _$PeriodOrdersTotalsCopyWith<$Res> {
  __$PeriodOrdersTotalsCopyWithImpl(this._self, this._then);

  final _PeriodOrdersTotals _self;
  final $Res Function(_PeriodOrdersTotals) _then;

/// Create a copy of PeriodOrdersTotals
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? orders = null,Object? investorsTotal = null,}) {
  return _then(_PeriodOrdersTotals(
orders: null == orders ? _self.orders : orders // ignore: cast_nullable_to_non_nullable
as int,investorsTotal: null == investorsTotal ? _self.investorsTotal : investorsTotal // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PeriodOrders {

 FundPeriod get period; List<PeriodOrder> get orders;/// مجموعُ كلِّ مستثمرٍ في الفترة كلِّها — «سجل ربح المستثمرين» مختصراً فوق تفصيله.
 List<PeriodInvestorShare> get investors; PeriodOrdersTotals get totals;
/// Create a copy of PeriodOrders
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeriodOrdersCopyWith<PeriodOrders> get copyWith => _$PeriodOrdersCopyWithImpl<PeriodOrders>(this as PeriodOrders, _$identity);

  /// Serializes this PeriodOrders to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodOrders&&(identical(other.period, period) || other.period == period)&&const DeepCollectionEquality().equals(other.orders, orders)&&const DeepCollectionEquality().equals(other.investors, investors)&&(identical(other.totals, totals) || other.totals == totals));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,period,const DeepCollectionEquality().hash(orders),const DeepCollectionEquality().hash(investors),totals);

@override
String toString() {
  return 'PeriodOrders(period: $period, orders: $orders, investors: $investors, totals: $totals)';
}


}

/// @nodoc
abstract mixin class $PeriodOrdersCopyWith<$Res>  {
  factory $PeriodOrdersCopyWith(PeriodOrders value, $Res Function(PeriodOrders) _then) = _$PeriodOrdersCopyWithImpl;
@useResult
$Res call({
 FundPeriod period, List<PeriodOrder> orders, List<PeriodInvestorShare> investors, PeriodOrdersTotals totals
});


$FundPeriodCopyWith<$Res> get period;$PeriodOrdersTotalsCopyWith<$Res> get totals;

}
/// @nodoc
class _$PeriodOrdersCopyWithImpl<$Res>
    implements $PeriodOrdersCopyWith<$Res> {
  _$PeriodOrdersCopyWithImpl(this._self, this._then);

  final PeriodOrders _self;
  final $Res Function(PeriodOrders) _then;

/// Create a copy of PeriodOrders
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? period = null,Object? orders = null,Object? investors = null,Object? totals = null,}) {
  return _then(_self.copyWith(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as FundPeriod,orders: null == orders ? _self.orders : orders // ignore: cast_nullable_to_non_nullable
as List<PeriodOrder>,investors: null == investors ? _self.investors : investors // ignore: cast_nullable_to_non_nullable
as List<PeriodInvestorShare>,totals: null == totals ? _self.totals : totals // ignore: cast_nullable_to_non_nullable
as PeriodOrdersTotals,
  ));
}
/// Create a copy of PeriodOrders
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FundPeriodCopyWith<$Res> get period {
  
  return $FundPeriodCopyWith<$Res>(_self.period, (value) {
    return _then(_self.copyWith(period: value));
  });
}/// Create a copy of PeriodOrders
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodOrdersTotalsCopyWith<$Res> get totals {
  
  return $PeriodOrdersTotalsCopyWith<$Res>(_self.totals, (value) {
    return _then(_self.copyWith(totals: value));
  });
}
}


/// Adds pattern-matching-related methods to [PeriodOrders].
extension PeriodOrdersPatterns on PeriodOrders {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PeriodOrders value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PeriodOrders() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PeriodOrders value)  $default,){
final _that = this;
switch (_that) {
case _PeriodOrders():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PeriodOrders value)?  $default,){
final _that = this;
switch (_that) {
case _PeriodOrders() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( FundPeriod period,  List<PeriodOrder> orders,  List<PeriodInvestorShare> investors,  PeriodOrdersTotals totals)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PeriodOrders() when $default != null:
return $default(_that.period,_that.orders,_that.investors,_that.totals);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( FundPeriod period,  List<PeriodOrder> orders,  List<PeriodInvestorShare> investors,  PeriodOrdersTotals totals)  $default,) {final _that = this;
switch (_that) {
case _PeriodOrders():
return $default(_that.period,_that.orders,_that.investors,_that.totals);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( FundPeriod period,  List<PeriodOrder> orders,  List<PeriodInvestorShare> investors,  PeriodOrdersTotals totals)?  $default,) {final _that = this;
switch (_that) {
case _PeriodOrders() when $default != null:
return $default(_that.period,_that.orders,_that.investors,_that.totals);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PeriodOrders implements PeriodOrders {
  const _PeriodOrders({required this.period, final  List<PeriodOrder> orders = const <PeriodOrder>[], final  List<PeriodInvestorShare> investors = const <PeriodInvestorShare>[], this.totals = const PeriodOrdersTotals()}): _orders = orders,_investors = investors;
  factory _PeriodOrders.fromJson(Map<String, dynamic> json) => _$PeriodOrdersFromJson(json);

@override final  FundPeriod period;
 final  List<PeriodOrder> _orders;
@override@JsonKey() List<PeriodOrder> get orders {
  if (_orders is EqualUnmodifiableListView) return _orders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_orders);
}

/// مجموعُ كلِّ مستثمرٍ في الفترة كلِّها — «سجل ربح المستثمرين» مختصراً فوق تفصيله.
 final  List<PeriodInvestorShare> _investors;
/// مجموعُ كلِّ مستثمرٍ في الفترة كلِّها — «سجل ربح المستثمرين» مختصراً فوق تفصيله.
@override@JsonKey() List<PeriodInvestorShare> get investors {
  if (_investors is EqualUnmodifiableListView) return _investors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_investors);
}

@override@JsonKey() final  PeriodOrdersTotals totals;

/// Create a copy of PeriodOrders
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PeriodOrdersCopyWith<_PeriodOrders> get copyWith => __$PeriodOrdersCopyWithImpl<_PeriodOrders>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PeriodOrdersToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PeriodOrders&&(identical(other.period, period) || other.period == period)&&const DeepCollectionEquality().equals(other._orders, _orders)&&const DeepCollectionEquality().equals(other._investors, _investors)&&(identical(other.totals, totals) || other.totals == totals));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,period,const DeepCollectionEquality().hash(_orders),const DeepCollectionEquality().hash(_investors),totals);

@override
String toString() {
  return 'PeriodOrders(period: $period, orders: $orders, investors: $investors, totals: $totals)';
}


}

/// @nodoc
abstract mixin class _$PeriodOrdersCopyWith<$Res> implements $PeriodOrdersCopyWith<$Res> {
  factory _$PeriodOrdersCopyWith(_PeriodOrders value, $Res Function(_PeriodOrders) _then) = __$PeriodOrdersCopyWithImpl;
@override @useResult
$Res call({
 FundPeriod period, List<PeriodOrder> orders, List<PeriodInvestorShare> investors, PeriodOrdersTotals totals
});


@override $FundPeriodCopyWith<$Res> get period;@override $PeriodOrdersTotalsCopyWith<$Res> get totals;

}
/// @nodoc
class __$PeriodOrdersCopyWithImpl<$Res>
    implements _$PeriodOrdersCopyWith<$Res> {
  __$PeriodOrdersCopyWithImpl(this._self, this._then);

  final _PeriodOrders _self;
  final $Res Function(_PeriodOrders) _then;

/// Create a copy of PeriodOrders
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? period = null,Object? orders = null,Object? investors = null,Object? totals = null,}) {
  return _then(_PeriodOrders(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as FundPeriod,orders: null == orders ? _self._orders : orders // ignore: cast_nullable_to_non_nullable
as List<PeriodOrder>,investors: null == investors ? _self._investors : investors // ignore: cast_nullable_to_non_nullable
as List<PeriodInvestorShare>,totals: null == totals ? _self.totals : totals // ignore: cast_nullable_to_non_nullable
as PeriodOrdersTotals,
  ));
}

/// Create a copy of PeriodOrders
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FundPeriodCopyWith<$Res> get period {
  
  return $FundPeriodCopyWith<$Res>(_self.period, (value) {
    return _then(_self.copyWith(period: value));
  });
}/// Create a copy of PeriodOrders
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodOrdersTotalsCopyWith<$Res> get totals {
  
  return $PeriodOrdersTotalsCopyWith<$Res>(_self.totals, (value) {
    return _then(_self.copyWith(totals: value));
  });
}
}

// dart format on
