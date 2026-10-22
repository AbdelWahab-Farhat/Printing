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

@JsonKey(name: 'investor_id') int get investorId; String get name; String get amount;/// في سجلّ الفترة وحده: كم من [amount] أُفرج عنه إلى محفظته، وكم ينتظر — §١١.
 String get released; String get pending;/// ربحُ طلبياتٍ في الطريق، لم يدخل [amount] بعد لأن لا صفَّ له في الدفتر.
 String get expected;
/// Create a copy of PeriodInvestorShare
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeriodInvestorShareCopyWith<PeriodInvestorShare> get copyWith => _$PeriodInvestorShareCopyWithImpl<PeriodInvestorShare>(this as PeriodInvestorShare, _$identity);

  /// Serializes this PeriodInvestorShare to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodInvestorShare&&(identical(other.investorId, investorId) || other.investorId == investorId)&&(identical(other.name, name) || other.name == name)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.released, released) || other.released == released)&&(identical(other.pending, pending) || other.pending == pending)&&(identical(other.expected, expected) || other.expected == expected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,investorId,name,amount,released,pending,expected);

@override
String toString() {
  return 'PeriodInvestorShare(investorId: $investorId, name: $name, amount: $amount, released: $released, pending: $pending, expected: $expected)';
}


}

/// @nodoc
abstract mixin class $PeriodInvestorShareCopyWith<$Res>  {
  factory $PeriodInvestorShareCopyWith(PeriodInvestorShare value, $Res Function(PeriodInvestorShare) _then) = _$PeriodInvestorShareCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'investor_id') int investorId, String name, String amount, String released, String pending, String expected
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
@pragma('vm:prefer-inline') @override $Res call({Object? investorId = null,Object? name = null,Object? amount = null,Object? released = null,Object? pending = null,Object? expected = null,}) {
  return _then(_self.copyWith(
investorId: null == investorId ? _self.investorId : investorId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,released: null == released ? _self.released : released // ignore: cast_nullable_to_non_nullable
as String,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as String,expected: null == expected ? _self.expected : expected // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'investor_id')  int investorId,  String name,  String amount,  String released,  String pending,  String expected)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PeriodInvestorShare() when $default != null:
return $default(_that.investorId,_that.name,_that.amount,_that.released,_that.pending,_that.expected);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'investor_id')  int investorId,  String name,  String amount,  String released,  String pending,  String expected)  $default,) {final _that = this;
switch (_that) {
case _PeriodInvestorShare():
return $default(_that.investorId,_that.name,_that.amount,_that.released,_that.pending,_that.expected);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'investor_id')  int investorId,  String name,  String amount,  String released,  String pending,  String expected)?  $default,) {final _that = this;
switch (_that) {
case _PeriodInvestorShare() when $default != null:
return $default(_that.investorId,_that.name,_that.amount,_that.released,_that.pending,_that.expected);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PeriodInvestorShare implements PeriodInvestorShare {
  const _PeriodInvestorShare({@JsonKey(name: 'investor_id') required this.investorId, required this.name, required this.amount, this.released = '0.00', this.pending = '0.00', this.expected = '0.00'});
  factory _PeriodInvestorShare.fromJson(Map<String, dynamic> json) => _$PeriodInvestorShareFromJson(json);

@override@JsonKey(name: 'investor_id') final  int investorId;
@override final  String name;
@override final  String amount;
/// في سجلّ الفترة وحده: كم من [amount] أُفرج عنه إلى محفظته، وكم ينتظر — §١١.
@override@JsonKey() final  String released;
@override@JsonKey() final  String pending;
/// ربحُ طلبياتٍ في الطريق، لم يدخل [amount] بعد لأن لا صفَّ له في الدفتر.
@override@JsonKey() final  String expected;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PeriodInvestorShare&&(identical(other.investorId, investorId) || other.investorId == investorId)&&(identical(other.name, name) || other.name == name)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.released, released) || other.released == released)&&(identical(other.pending, pending) || other.pending == pending)&&(identical(other.expected, expected) || other.expected == expected));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,investorId,name,amount,released,pending,expected);

@override
String toString() {
  return 'PeriodInvestorShare(investorId: $investorId, name: $name, amount: $amount, released: $released, pending: $pending, expected: $expected)';
}


}

/// @nodoc
abstract mixin class _$PeriodInvestorShareCopyWith<$Res> implements $PeriodInvestorShareCopyWith<$Res> {
  factory _$PeriodInvestorShareCopyWith(_PeriodInvestorShare value, $Res Function(_PeriodInvestorShare) _then) = __$PeriodInvestorShareCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'investor_id') int investorId, String name, String amount, String released, String pending, String expected
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
@override @pragma('vm:prefer-inline') $Res call({Object? investorId = null,Object? name = null,Object? amount = null,Object? released = null,Object? pending = null,Object? expected = null,}) {
  return _then(_PeriodInvestorShare(
investorId: null == investorId ? _self.investorId : investorId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,released: null == released ? _self.released : released // ignore: cast_nullable_to_non_nullable
as String,pending: null == pending ? _self.pending : pending // ignore: cast_nullable_to_non_nullable
as String,expected: null == expected ? _self.expected : expected // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PeriodOrder {

@JsonKey(name: 'order_id') int get orderId; String get code; String get status;@JsonKey(name: 'status_label') String get statusLabel;@JsonKey(name: 'customer_name') String? get customerName;/// يومُ وصولها العميل، أو يومُ كتابتها لطلبيةٍ لم تصل بعد.
@JsonKey(name: 'occurred_at') DateTime? get occurredAt;/// مالُ الطلبية كلُّه — ليُقرأ نصيبُ المستثمرين في مقابل شيء.
@JsonKey(name: 'grand_total') String get grandTotal;/// مجموعُ ما أخذه المستثمرون منها، وهو جمعُ [investors] لا رقمٌ ثانٍ.
@JsonKey(name: 'investors_total') String get investorsTotal; List<PeriodInvestorShare> get investors;/// أين ربحُها من الجيوب — `null` حيث لا يُسأل، كـ«الأرباح المستحقّة» التي تشارك البطاقة.
@JsonKey(name: 'profit_state', unknownEnumValue: JsonKey.nullForUndefinedEnumValue) PeriodProfitState? get profitState;@JsonKey(name: 'profit_state_label') String? get profitStateLabel;/// كلُّ حالةٍ لها فيها شيء — ما تُصفّى به، فتقع تحت مرشّحين حين انقسم ربحُها.
 List<PeriodProfitState> get states;@JsonKey(name: 'by_state') PeriodOrderByState? get byState;/// سيحجز الإقفالُ ربحَها ما لم يدفع العميل — «غير محصّلة» تحت حالتها.
 bool get uncollected;/// ما سيصل كلَّ شريكٍ منها عند التسليم، لما بلغ «جاهزة».
@JsonKey(name: 'expected_investors') List<PeriodInvestorShare> get expectedInvestors;
/// Create a copy of PeriodOrder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeriodOrderCopyWith<PeriodOrder> get copyWith => _$PeriodOrderCopyWithImpl<PeriodOrder>(this as PeriodOrder, _$identity);

  /// Serializes this PeriodOrder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodOrder&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.code, code) || other.code == code)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.customerName, customerName) || other.customerName == customerName)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.grandTotal, grandTotal) || other.grandTotal == grandTotal)&&(identical(other.investorsTotal, investorsTotal) || other.investorsTotal == investorsTotal)&&const DeepCollectionEquality().equals(other.investors, investors)&&(identical(other.profitState, profitState) || other.profitState == profitState)&&(identical(other.profitStateLabel, profitStateLabel) || other.profitStateLabel == profitStateLabel)&&const DeepCollectionEquality().equals(other.states, states)&&(identical(other.byState, byState) || other.byState == byState)&&(identical(other.uncollected, uncollected) || other.uncollected == uncollected)&&const DeepCollectionEquality().equals(other.expectedInvestors, expectedInvestors));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,orderId,code,status,statusLabel,customerName,occurredAt,grandTotal,investorsTotal,const DeepCollectionEquality().hash(investors),profitState,profitStateLabel,const DeepCollectionEquality().hash(states),byState,uncollected,const DeepCollectionEquality().hash(expectedInvestors));

@override
String toString() {
  return 'PeriodOrder(orderId: $orderId, code: $code, status: $status, statusLabel: $statusLabel, customerName: $customerName, occurredAt: $occurredAt, grandTotal: $grandTotal, investorsTotal: $investorsTotal, investors: $investors, profitState: $profitState, profitStateLabel: $profitStateLabel, states: $states, byState: $byState, uncollected: $uncollected, expectedInvestors: $expectedInvestors)';
}


}

/// @nodoc
abstract mixin class $PeriodOrderCopyWith<$Res>  {
  factory $PeriodOrderCopyWith(PeriodOrder value, $Res Function(PeriodOrder) _then) = _$PeriodOrderCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'order_id') int orderId, String code, String status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'customer_name') String? customerName,@JsonKey(name: 'occurred_at') DateTime? occurredAt,@JsonKey(name: 'grand_total') String grandTotal,@JsonKey(name: 'investors_total') String investorsTotal, List<PeriodInvestorShare> investors,@JsonKey(name: 'profit_state', unknownEnumValue: JsonKey.nullForUndefinedEnumValue) PeriodProfitState? profitState,@JsonKey(name: 'profit_state_label') String? profitStateLabel, List<PeriodProfitState> states,@JsonKey(name: 'by_state') PeriodOrderByState? byState, bool uncollected,@JsonKey(name: 'expected_investors') List<PeriodInvestorShare> expectedInvestors
});


$PeriodOrderByStateCopyWith<$Res>? get byState;

}
/// @nodoc
class _$PeriodOrderCopyWithImpl<$Res>
    implements $PeriodOrderCopyWith<$Res> {
  _$PeriodOrderCopyWithImpl(this._self, this._then);

  final PeriodOrder _self;
  final $Res Function(PeriodOrder) _then;

/// Create a copy of PeriodOrder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? orderId = null,Object? code = null,Object? status = null,Object? statusLabel = null,Object? customerName = freezed,Object? occurredAt = freezed,Object? grandTotal = null,Object? investorsTotal = null,Object? investors = null,Object? profitState = freezed,Object? profitStateLabel = freezed,Object? states = null,Object? byState = freezed,Object? uncollected = null,Object? expectedInvestors = null,}) {
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
as List<PeriodInvestorShare>,profitState: freezed == profitState ? _self.profitState : profitState // ignore: cast_nullable_to_non_nullable
as PeriodProfitState?,profitStateLabel: freezed == profitStateLabel ? _self.profitStateLabel : profitStateLabel // ignore: cast_nullable_to_non_nullable
as String?,states: null == states ? _self.states : states // ignore: cast_nullable_to_non_nullable
as List<PeriodProfitState>,byState: freezed == byState ? _self.byState : byState // ignore: cast_nullable_to_non_nullable
as PeriodOrderByState?,uncollected: null == uncollected ? _self.uncollected : uncollected // ignore: cast_nullable_to_non_nullable
as bool,expectedInvestors: null == expectedInvestors ? _self.expectedInvestors : expectedInvestors // ignore: cast_nullable_to_non_nullable
as List<PeriodInvestorShare>,
  ));
}
/// Create a copy of PeriodOrder
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodOrderByStateCopyWith<$Res>? get byState {
    if (_self.byState == null) {
    return null;
  }

  return $PeriodOrderByStateCopyWith<$Res>(_self.byState!, (value) {
    return _then(_self.copyWith(byState: value));
  });
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'order_id')  int orderId,  String code,  String status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'customer_name')  String? customerName, @JsonKey(name: 'occurred_at')  DateTime? occurredAt, @JsonKey(name: 'grand_total')  String grandTotal, @JsonKey(name: 'investors_total')  String investorsTotal,  List<PeriodInvestorShare> investors, @JsonKey(name: 'profit_state', unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  PeriodProfitState? profitState, @JsonKey(name: 'profit_state_label')  String? profitStateLabel,  List<PeriodProfitState> states, @JsonKey(name: 'by_state')  PeriodOrderByState? byState,  bool uncollected, @JsonKey(name: 'expected_investors')  List<PeriodInvestorShare> expectedInvestors)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PeriodOrder() when $default != null:
return $default(_that.orderId,_that.code,_that.status,_that.statusLabel,_that.customerName,_that.occurredAt,_that.grandTotal,_that.investorsTotal,_that.investors,_that.profitState,_that.profitStateLabel,_that.states,_that.byState,_that.uncollected,_that.expectedInvestors);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'order_id')  int orderId,  String code,  String status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'customer_name')  String? customerName, @JsonKey(name: 'occurred_at')  DateTime? occurredAt, @JsonKey(name: 'grand_total')  String grandTotal, @JsonKey(name: 'investors_total')  String investorsTotal,  List<PeriodInvestorShare> investors, @JsonKey(name: 'profit_state', unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  PeriodProfitState? profitState, @JsonKey(name: 'profit_state_label')  String? profitStateLabel,  List<PeriodProfitState> states, @JsonKey(name: 'by_state')  PeriodOrderByState? byState,  bool uncollected, @JsonKey(name: 'expected_investors')  List<PeriodInvestorShare> expectedInvestors)  $default,) {final _that = this;
switch (_that) {
case _PeriodOrder():
return $default(_that.orderId,_that.code,_that.status,_that.statusLabel,_that.customerName,_that.occurredAt,_that.grandTotal,_that.investorsTotal,_that.investors,_that.profitState,_that.profitStateLabel,_that.states,_that.byState,_that.uncollected,_that.expectedInvestors);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'order_id')  int orderId,  String code,  String status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'customer_name')  String? customerName, @JsonKey(name: 'occurred_at')  DateTime? occurredAt, @JsonKey(name: 'grand_total')  String grandTotal, @JsonKey(name: 'investors_total')  String investorsTotal,  List<PeriodInvestorShare> investors, @JsonKey(name: 'profit_state', unknownEnumValue: JsonKey.nullForUndefinedEnumValue)  PeriodProfitState? profitState, @JsonKey(name: 'profit_state_label')  String? profitStateLabel,  List<PeriodProfitState> states, @JsonKey(name: 'by_state')  PeriodOrderByState? byState,  bool uncollected, @JsonKey(name: 'expected_investors')  List<PeriodInvestorShare> expectedInvestors)?  $default,) {final _that = this;
switch (_that) {
case _PeriodOrder() when $default != null:
return $default(_that.orderId,_that.code,_that.status,_that.statusLabel,_that.customerName,_that.occurredAt,_that.grandTotal,_that.investorsTotal,_that.investors,_that.profitState,_that.profitStateLabel,_that.states,_that.byState,_that.uncollected,_that.expectedInvestors);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PeriodOrder implements PeriodOrder {
  const _PeriodOrder({@JsonKey(name: 'order_id') required this.orderId, required this.code, required this.status, @JsonKey(name: 'status_label') required this.statusLabel, @JsonKey(name: 'customer_name') this.customerName, @JsonKey(name: 'occurred_at') this.occurredAt, @JsonKey(name: 'grand_total') required this.grandTotal, @JsonKey(name: 'investors_total') required this.investorsTotal, final  List<PeriodInvestorShare> investors = const <PeriodInvestorShare>[], @JsonKey(name: 'profit_state', unknownEnumValue: JsonKey.nullForUndefinedEnumValue) this.profitState, @JsonKey(name: 'profit_state_label') this.profitStateLabel, final  List<PeriodProfitState> states = const <PeriodProfitState>[], @JsonKey(name: 'by_state') this.byState, this.uncollected = false, @JsonKey(name: 'expected_investors') final  List<PeriodInvestorShare> expectedInvestors = const <PeriodInvestorShare>[]}): _investors = investors,_states = states,_expectedInvestors = expectedInvestors;
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

/// أين ربحُها من الجيوب — `null` حيث لا يُسأل، كـ«الأرباح المستحقّة» التي تشارك البطاقة.
@override@JsonKey(name: 'profit_state', unknownEnumValue: JsonKey.nullForUndefinedEnumValue) final  PeriodProfitState? profitState;
@override@JsonKey(name: 'profit_state_label') final  String? profitStateLabel;
/// كلُّ حالةٍ لها فيها شيء — ما تُصفّى به، فتقع تحت مرشّحين حين انقسم ربحُها.
 final  List<PeriodProfitState> _states;
/// كلُّ حالةٍ لها فيها شيء — ما تُصفّى به، فتقع تحت مرشّحين حين انقسم ربحُها.
@override@JsonKey() List<PeriodProfitState> get states {
  if (_states is EqualUnmodifiableListView) return _states;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_states);
}

@override@JsonKey(name: 'by_state') final  PeriodOrderByState? byState;
/// سيحجز الإقفالُ ربحَها ما لم يدفع العميل — «غير محصّلة» تحت حالتها.
@override@JsonKey() final  bool uncollected;
/// ما سيصل كلَّ شريكٍ منها عند التسليم، لما بلغ «جاهزة».
 final  List<PeriodInvestorShare> _expectedInvestors;
/// ما سيصل كلَّ شريكٍ منها عند التسليم، لما بلغ «جاهزة».
@override@JsonKey(name: 'expected_investors') List<PeriodInvestorShare> get expectedInvestors {
  if (_expectedInvestors is EqualUnmodifiableListView) return _expectedInvestors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_expectedInvestors);
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PeriodOrder&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.code, code) || other.code == code)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.customerName, customerName) || other.customerName == customerName)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&(identical(other.grandTotal, grandTotal) || other.grandTotal == grandTotal)&&(identical(other.investorsTotal, investorsTotal) || other.investorsTotal == investorsTotal)&&const DeepCollectionEquality().equals(other._investors, _investors)&&(identical(other.profitState, profitState) || other.profitState == profitState)&&(identical(other.profitStateLabel, profitStateLabel) || other.profitStateLabel == profitStateLabel)&&const DeepCollectionEquality().equals(other._states, _states)&&(identical(other.byState, byState) || other.byState == byState)&&(identical(other.uncollected, uncollected) || other.uncollected == uncollected)&&const DeepCollectionEquality().equals(other._expectedInvestors, _expectedInvestors));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,orderId,code,status,statusLabel,customerName,occurredAt,grandTotal,investorsTotal,const DeepCollectionEquality().hash(_investors),profitState,profitStateLabel,const DeepCollectionEquality().hash(_states),byState,uncollected,const DeepCollectionEquality().hash(_expectedInvestors));

@override
String toString() {
  return 'PeriodOrder(orderId: $orderId, code: $code, status: $status, statusLabel: $statusLabel, customerName: $customerName, occurredAt: $occurredAt, grandTotal: $grandTotal, investorsTotal: $investorsTotal, investors: $investors, profitState: $profitState, profitStateLabel: $profitStateLabel, states: $states, byState: $byState, uncollected: $uncollected, expectedInvestors: $expectedInvestors)';
}


}

/// @nodoc
abstract mixin class _$PeriodOrderCopyWith<$Res> implements $PeriodOrderCopyWith<$Res> {
  factory _$PeriodOrderCopyWith(_PeriodOrder value, $Res Function(_PeriodOrder) _then) = __$PeriodOrderCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'order_id') int orderId, String code, String status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'customer_name') String? customerName,@JsonKey(name: 'occurred_at') DateTime? occurredAt,@JsonKey(name: 'grand_total') String grandTotal,@JsonKey(name: 'investors_total') String investorsTotal, List<PeriodInvestorShare> investors,@JsonKey(name: 'profit_state', unknownEnumValue: JsonKey.nullForUndefinedEnumValue) PeriodProfitState? profitState,@JsonKey(name: 'profit_state_label') String? profitStateLabel, List<PeriodProfitState> states,@JsonKey(name: 'by_state') PeriodOrderByState? byState, bool uncollected,@JsonKey(name: 'expected_investors') List<PeriodInvestorShare> expectedInvestors
});


@override $PeriodOrderByStateCopyWith<$Res>? get byState;

}
/// @nodoc
class __$PeriodOrderCopyWithImpl<$Res>
    implements _$PeriodOrderCopyWith<$Res> {
  __$PeriodOrderCopyWithImpl(this._self, this._then);

  final _PeriodOrder _self;
  final $Res Function(_PeriodOrder) _then;

/// Create a copy of PeriodOrder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? orderId = null,Object? code = null,Object? status = null,Object? statusLabel = null,Object? customerName = freezed,Object? occurredAt = freezed,Object? grandTotal = null,Object? investorsTotal = null,Object? investors = null,Object? profitState = freezed,Object? profitStateLabel = freezed,Object? states = null,Object? byState = freezed,Object? uncollected = null,Object? expectedInvestors = null,}) {
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
as List<PeriodInvestorShare>,profitState: freezed == profitState ? _self.profitState : profitState // ignore: cast_nullable_to_non_nullable
as PeriodProfitState?,profitStateLabel: freezed == profitStateLabel ? _self.profitStateLabel : profitStateLabel // ignore: cast_nullable_to_non_nullable
as String?,states: null == states ? _self._states : states // ignore: cast_nullable_to_non_nullable
as List<PeriodProfitState>,byState: freezed == byState ? _self.byState : byState // ignore: cast_nullable_to_non_nullable
as PeriodOrderByState?,uncollected: null == uncollected ? _self.uncollected : uncollected // ignore: cast_nullable_to_non_nullable
as bool,expectedInvestors: null == expectedInvestors ? _self._expectedInvestors : expectedInvestors // ignore: cast_nullable_to_non_nullable
as List<PeriodInvestorShare>,
  ));
}

/// Create a copy of PeriodOrder
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodOrderByStateCopyWith<$Res>? get byState {
    if (_self.byState == null) {
    return null;
  }

  return $PeriodOrderByStateCopyWith<$Res>(_self.byState!, (value) {
    return _then(_self.copyWith(byState: value));
  });
}
}


/// @nodoc
mixin _$PeriodOrderByState {

 String get released;@JsonKey(name: 'awaiting_payment') String get awaitingPayment;@JsonKey(name: 'awaiting_period_end') String get awaitingPeriodEnd;@JsonKey(name: 'awaiting_delivery') String? get awaitingDelivery;
/// Create a copy of PeriodOrderByState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeriodOrderByStateCopyWith<PeriodOrderByState> get copyWith => _$PeriodOrderByStateCopyWithImpl<PeriodOrderByState>(this as PeriodOrderByState, _$identity);

  /// Serializes this PeriodOrderByState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodOrderByState&&(identical(other.released, released) || other.released == released)&&(identical(other.awaitingPayment, awaitingPayment) || other.awaitingPayment == awaitingPayment)&&(identical(other.awaitingPeriodEnd, awaitingPeriodEnd) || other.awaitingPeriodEnd == awaitingPeriodEnd)&&(identical(other.awaitingDelivery, awaitingDelivery) || other.awaitingDelivery == awaitingDelivery));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,released,awaitingPayment,awaitingPeriodEnd,awaitingDelivery);

@override
String toString() {
  return 'PeriodOrderByState(released: $released, awaitingPayment: $awaitingPayment, awaitingPeriodEnd: $awaitingPeriodEnd, awaitingDelivery: $awaitingDelivery)';
}


}

/// @nodoc
abstract mixin class $PeriodOrderByStateCopyWith<$Res>  {
  factory $PeriodOrderByStateCopyWith(PeriodOrderByState value, $Res Function(PeriodOrderByState) _then) = _$PeriodOrderByStateCopyWithImpl;
@useResult
$Res call({
 String released,@JsonKey(name: 'awaiting_payment') String awaitingPayment,@JsonKey(name: 'awaiting_period_end') String awaitingPeriodEnd,@JsonKey(name: 'awaiting_delivery') String? awaitingDelivery
});




}
/// @nodoc
class _$PeriodOrderByStateCopyWithImpl<$Res>
    implements $PeriodOrderByStateCopyWith<$Res> {
  _$PeriodOrderByStateCopyWithImpl(this._self, this._then);

  final PeriodOrderByState _self;
  final $Res Function(PeriodOrderByState) _then;

/// Create a copy of PeriodOrderByState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? released = null,Object? awaitingPayment = null,Object? awaitingPeriodEnd = null,Object? awaitingDelivery = freezed,}) {
  return _then(_self.copyWith(
released: null == released ? _self.released : released // ignore: cast_nullable_to_non_nullable
as String,awaitingPayment: null == awaitingPayment ? _self.awaitingPayment : awaitingPayment // ignore: cast_nullable_to_non_nullable
as String,awaitingPeriodEnd: null == awaitingPeriodEnd ? _self.awaitingPeriodEnd : awaitingPeriodEnd // ignore: cast_nullable_to_non_nullable
as String,awaitingDelivery: freezed == awaitingDelivery ? _self.awaitingDelivery : awaitingDelivery // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PeriodOrderByState].
extension PeriodOrderByStatePatterns on PeriodOrderByState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PeriodOrderByState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PeriodOrderByState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PeriodOrderByState value)  $default,){
final _that = this;
switch (_that) {
case _PeriodOrderByState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PeriodOrderByState value)?  $default,){
final _that = this;
switch (_that) {
case _PeriodOrderByState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String released, @JsonKey(name: 'awaiting_payment')  String awaitingPayment, @JsonKey(name: 'awaiting_period_end')  String awaitingPeriodEnd, @JsonKey(name: 'awaiting_delivery')  String? awaitingDelivery)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PeriodOrderByState() when $default != null:
return $default(_that.released,_that.awaitingPayment,_that.awaitingPeriodEnd,_that.awaitingDelivery);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String released, @JsonKey(name: 'awaiting_payment')  String awaitingPayment, @JsonKey(name: 'awaiting_period_end')  String awaitingPeriodEnd, @JsonKey(name: 'awaiting_delivery')  String? awaitingDelivery)  $default,) {final _that = this;
switch (_that) {
case _PeriodOrderByState():
return $default(_that.released,_that.awaitingPayment,_that.awaitingPeriodEnd,_that.awaitingDelivery);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String released, @JsonKey(name: 'awaiting_payment')  String awaitingPayment, @JsonKey(name: 'awaiting_period_end')  String awaitingPeriodEnd, @JsonKey(name: 'awaiting_delivery')  String? awaitingDelivery)?  $default,) {final _that = this;
switch (_that) {
case _PeriodOrderByState() when $default != null:
return $default(_that.released,_that.awaitingPayment,_that.awaitingPeriodEnd,_that.awaitingDelivery);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PeriodOrderByState extends PeriodOrderByState {
  const _PeriodOrderByState({this.released = '0.00', @JsonKey(name: 'awaiting_payment') this.awaitingPayment = '0.00', @JsonKey(name: 'awaiting_period_end') this.awaitingPeriodEnd = '0.00', @JsonKey(name: 'awaiting_delivery') this.awaitingDelivery}): super._();
  factory _PeriodOrderByState.fromJson(Map<String, dynamic> json) => _$PeriodOrderByStateFromJson(json);

@override@JsonKey() final  String released;
@override@JsonKey(name: 'awaiting_payment') final  String awaitingPayment;
@override@JsonKey(name: 'awaiting_period_end') final  String awaitingPeriodEnd;
@override@JsonKey(name: 'awaiting_delivery') final  String? awaitingDelivery;

/// Create a copy of PeriodOrderByState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PeriodOrderByStateCopyWith<_PeriodOrderByState> get copyWith => __$PeriodOrderByStateCopyWithImpl<_PeriodOrderByState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PeriodOrderByStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PeriodOrderByState&&(identical(other.released, released) || other.released == released)&&(identical(other.awaitingPayment, awaitingPayment) || other.awaitingPayment == awaitingPayment)&&(identical(other.awaitingPeriodEnd, awaitingPeriodEnd) || other.awaitingPeriodEnd == awaitingPeriodEnd)&&(identical(other.awaitingDelivery, awaitingDelivery) || other.awaitingDelivery == awaitingDelivery));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,released,awaitingPayment,awaitingPeriodEnd,awaitingDelivery);

@override
String toString() {
  return 'PeriodOrderByState(released: $released, awaitingPayment: $awaitingPayment, awaitingPeriodEnd: $awaitingPeriodEnd, awaitingDelivery: $awaitingDelivery)';
}


}

/// @nodoc
abstract mixin class _$PeriodOrderByStateCopyWith<$Res> implements $PeriodOrderByStateCopyWith<$Res> {
  factory _$PeriodOrderByStateCopyWith(_PeriodOrderByState value, $Res Function(_PeriodOrderByState) _then) = __$PeriodOrderByStateCopyWithImpl;
@override @useResult
$Res call({
 String released,@JsonKey(name: 'awaiting_payment') String awaitingPayment,@JsonKey(name: 'awaiting_period_end') String awaitingPeriodEnd,@JsonKey(name: 'awaiting_delivery') String? awaitingDelivery
});




}
/// @nodoc
class __$PeriodOrderByStateCopyWithImpl<$Res>
    implements _$PeriodOrderByStateCopyWith<$Res> {
  __$PeriodOrderByStateCopyWithImpl(this._self, this._then);

  final _PeriodOrderByState _self;
  final $Res Function(_PeriodOrderByState) _then;

/// Create a copy of PeriodOrderByState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? released = null,Object? awaitingPayment = null,Object? awaitingPeriodEnd = null,Object? awaitingDelivery = freezed,}) {
  return _then(_PeriodOrderByState(
released: null == released ? _self.released : released // ignore: cast_nullable_to_non_nullable
as String,awaitingPayment: null == awaitingPayment ? _self.awaitingPayment : awaitingPayment // ignore: cast_nullable_to_non_nullable
as String,awaitingPeriodEnd: null == awaitingPeriodEnd ? _self.awaitingPeriodEnd : awaitingPeriodEnd // ignore: cast_nullable_to_non_nullable
as String,awaitingDelivery: freezed == awaitingDelivery ? _self.awaitingDelivery : awaitingDelivery // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$PeriodStateTotal {

 int get orders; String get amount; int get unpriced;
/// Create a copy of PeriodStateTotal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeriodStateTotalCopyWith<PeriodStateTotal> get copyWith => _$PeriodStateTotalCopyWithImpl<PeriodStateTotal>(this as PeriodStateTotal, _$identity);

  /// Serializes this PeriodStateTotal to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodStateTotal&&(identical(other.orders, orders) || other.orders == orders)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.unpriced, unpriced) || other.unpriced == unpriced));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,orders,amount,unpriced);

@override
String toString() {
  return 'PeriodStateTotal(orders: $orders, amount: $amount, unpriced: $unpriced)';
}


}

/// @nodoc
abstract mixin class $PeriodStateTotalCopyWith<$Res>  {
  factory $PeriodStateTotalCopyWith(PeriodStateTotal value, $Res Function(PeriodStateTotal) _then) = _$PeriodStateTotalCopyWithImpl;
@useResult
$Res call({
 int orders, String amount, int unpriced
});




}
/// @nodoc
class _$PeriodStateTotalCopyWithImpl<$Res>
    implements $PeriodStateTotalCopyWith<$Res> {
  _$PeriodStateTotalCopyWithImpl(this._self, this._then);

  final PeriodStateTotal _self;
  final $Res Function(PeriodStateTotal) _then;

/// Create a copy of PeriodStateTotal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? orders = null,Object? amount = null,Object? unpriced = null,}) {
  return _then(_self.copyWith(
orders: null == orders ? _self.orders : orders // ignore: cast_nullable_to_non_nullable
as int,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,unpriced: null == unpriced ? _self.unpriced : unpriced // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PeriodStateTotal].
extension PeriodStateTotalPatterns on PeriodStateTotal {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PeriodStateTotal value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PeriodStateTotal() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PeriodStateTotal value)  $default,){
final _that = this;
switch (_that) {
case _PeriodStateTotal():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PeriodStateTotal value)?  $default,){
final _that = this;
switch (_that) {
case _PeriodStateTotal() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int orders,  String amount,  int unpriced)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PeriodStateTotal() when $default != null:
return $default(_that.orders,_that.amount,_that.unpriced);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int orders,  String amount,  int unpriced)  $default,) {final _that = this;
switch (_that) {
case _PeriodStateTotal():
return $default(_that.orders,_that.amount,_that.unpriced);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int orders,  String amount,  int unpriced)?  $default,) {final _that = this;
switch (_that) {
case _PeriodStateTotal() when $default != null:
return $default(_that.orders,_that.amount,_that.unpriced);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PeriodStateTotal implements PeriodStateTotal {
  const _PeriodStateTotal({this.orders = 0, this.amount = '0.00', this.unpriced = 0});
  factory _PeriodStateTotal.fromJson(Map<String, dynamic> json) => _$PeriodStateTotalFromJson(json);

@override@JsonKey() final  int orders;
@override@JsonKey() final  String amount;
@override@JsonKey() final  int unpriced;

/// Create a copy of PeriodStateTotal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PeriodStateTotalCopyWith<_PeriodStateTotal> get copyWith => __$PeriodStateTotalCopyWithImpl<_PeriodStateTotal>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PeriodStateTotalToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PeriodStateTotal&&(identical(other.orders, orders) || other.orders == orders)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.unpriced, unpriced) || other.unpriced == unpriced));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,orders,amount,unpriced);

@override
String toString() {
  return 'PeriodStateTotal(orders: $orders, amount: $amount, unpriced: $unpriced)';
}


}

/// @nodoc
abstract mixin class _$PeriodStateTotalCopyWith<$Res> implements $PeriodStateTotalCopyWith<$Res> {
  factory _$PeriodStateTotalCopyWith(_PeriodStateTotal value, $Res Function(_PeriodStateTotal) _then) = __$PeriodStateTotalCopyWithImpl;
@override @useResult
$Res call({
 int orders, String amount, int unpriced
});




}
/// @nodoc
class __$PeriodStateTotalCopyWithImpl<$Res>
    implements _$PeriodStateTotalCopyWith<$Res> {
  __$PeriodStateTotalCopyWithImpl(this._self, this._then);

  final _PeriodStateTotal _self;
  final $Res Function(_PeriodStateTotal) _then;

/// Create a copy of PeriodStateTotal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? orders = null,Object? amount = null,Object? unpriced = null,}) {
  return _then(_PeriodStateTotal(
orders: null == orders ? _self.orders : orders // ignore: cast_nullable_to_non_nullable
as int,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,unpriced: null == unpriced ? _self.unpriced : unpriced // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$PeriodStatesTotals {

 PeriodStateTotal get released;@JsonKey(name: 'awaiting_payment') PeriodStateTotal get awaitingPayment;@JsonKey(name: 'awaiting_period_end') PeriodStateTotal get awaitingPeriodEnd;@JsonKey(name: 'awaiting_delivery') PeriodStateTotal get awaitingDelivery;
/// Create a copy of PeriodStatesTotals
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeriodStatesTotalsCopyWith<PeriodStatesTotals> get copyWith => _$PeriodStatesTotalsCopyWithImpl<PeriodStatesTotals>(this as PeriodStatesTotals, _$identity);

  /// Serializes this PeriodStatesTotals to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodStatesTotals&&(identical(other.released, released) || other.released == released)&&(identical(other.awaitingPayment, awaitingPayment) || other.awaitingPayment == awaitingPayment)&&(identical(other.awaitingPeriodEnd, awaitingPeriodEnd) || other.awaitingPeriodEnd == awaitingPeriodEnd)&&(identical(other.awaitingDelivery, awaitingDelivery) || other.awaitingDelivery == awaitingDelivery));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,released,awaitingPayment,awaitingPeriodEnd,awaitingDelivery);

@override
String toString() {
  return 'PeriodStatesTotals(released: $released, awaitingPayment: $awaitingPayment, awaitingPeriodEnd: $awaitingPeriodEnd, awaitingDelivery: $awaitingDelivery)';
}


}

/// @nodoc
abstract mixin class $PeriodStatesTotalsCopyWith<$Res>  {
  factory $PeriodStatesTotalsCopyWith(PeriodStatesTotals value, $Res Function(PeriodStatesTotals) _then) = _$PeriodStatesTotalsCopyWithImpl;
@useResult
$Res call({
 PeriodStateTotal released,@JsonKey(name: 'awaiting_payment') PeriodStateTotal awaitingPayment,@JsonKey(name: 'awaiting_period_end') PeriodStateTotal awaitingPeriodEnd,@JsonKey(name: 'awaiting_delivery') PeriodStateTotal awaitingDelivery
});


$PeriodStateTotalCopyWith<$Res> get released;$PeriodStateTotalCopyWith<$Res> get awaitingPayment;$PeriodStateTotalCopyWith<$Res> get awaitingPeriodEnd;$PeriodStateTotalCopyWith<$Res> get awaitingDelivery;

}
/// @nodoc
class _$PeriodStatesTotalsCopyWithImpl<$Res>
    implements $PeriodStatesTotalsCopyWith<$Res> {
  _$PeriodStatesTotalsCopyWithImpl(this._self, this._then);

  final PeriodStatesTotals _self;
  final $Res Function(PeriodStatesTotals) _then;

/// Create a copy of PeriodStatesTotals
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? released = null,Object? awaitingPayment = null,Object? awaitingPeriodEnd = null,Object? awaitingDelivery = null,}) {
  return _then(_self.copyWith(
released: null == released ? _self.released : released // ignore: cast_nullable_to_non_nullable
as PeriodStateTotal,awaitingPayment: null == awaitingPayment ? _self.awaitingPayment : awaitingPayment // ignore: cast_nullable_to_non_nullable
as PeriodStateTotal,awaitingPeriodEnd: null == awaitingPeriodEnd ? _self.awaitingPeriodEnd : awaitingPeriodEnd // ignore: cast_nullable_to_non_nullable
as PeriodStateTotal,awaitingDelivery: null == awaitingDelivery ? _self.awaitingDelivery : awaitingDelivery // ignore: cast_nullable_to_non_nullable
as PeriodStateTotal,
  ));
}
/// Create a copy of PeriodStatesTotals
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodStateTotalCopyWith<$Res> get released {
  
  return $PeriodStateTotalCopyWith<$Res>(_self.released, (value) {
    return _then(_self.copyWith(released: value));
  });
}/// Create a copy of PeriodStatesTotals
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodStateTotalCopyWith<$Res> get awaitingPayment {
  
  return $PeriodStateTotalCopyWith<$Res>(_self.awaitingPayment, (value) {
    return _then(_self.copyWith(awaitingPayment: value));
  });
}/// Create a copy of PeriodStatesTotals
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodStateTotalCopyWith<$Res> get awaitingPeriodEnd {
  
  return $PeriodStateTotalCopyWith<$Res>(_self.awaitingPeriodEnd, (value) {
    return _then(_self.copyWith(awaitingPeriodEnd: value));
  });
}/// Create a copy of PeriodStatesTotals
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodStateTotalCopyWith<$Res> get awaitingDelivery {
  
  return $PeriodStateTotalCopyWith<$Res>(_self.awaitingDelivery, (value) {
    return _then(_self.copyWith(awaitingDelivery: value));
  });
}
}


/// Adds pattern-matching-related methods to [PeriodStatesTotals].
extension PeriodStatesTotalsPatterns on PeriodStatesTotals {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PeriodStatesTotals value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PeriodStatesTotals() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PeriodStatesTotals value)  $default,){
final _that = this;
switch (_that) {
case _PeriodStatesTotals():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PeriodStatesTotals value)?  $default,){
final _that = this;
switch (_that) {
case _PeriodStatesTotals() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PeriodStateTotal released, @JsonKey(name: 'awaiting_payment')  PeriodStateTotal awaitingPayment, @JsonKey(name: 'awaiting_period_end')  PeriodStateTotal awaitingPeriodEnd, @JsonKey(name: 'awaiting_delivery')  PeriodStateTotal awaitingDelivery)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PeriodStatesTotals() when $default != null:
return $default(_that.released,_that.awaitingPayment,_that.awaitingPeriodEnd,_that.awaitingDelivery);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PeriodStateTotal released, @JsonKey(name: 'awaiting_payment')  PeriodStateTotal awaitingPayment, @JsonKey(name: 'awaiting_period_end')  PeriodStateTotal awaitingPeriodEnd, @JsonKey(name: 'awaiting_delivery')  PeriodStateTotal awaitingDelivery)  $default,) {final _that = this;
switch (_that) {
case _PeriodStatesTotals():
return $default(_that.released,_that.awaitingPayment,_that.awaitingPeriodEnd,_that.awaitingDelivery);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PeriodStateTotal released, @JsonKey(name: 'awaiting_payment')  PeriodStateTotal awaitingPayment, @JsonKey(name: 'awaiting_period_end')  PeriodStateTotal awaitingPeriodEnd, @JsonKey(name: 'awaiting_delivery')  PeriodStateTotal awaitingDelivery)?  $default,) {final _that = this;
switch (_that) {
case _PeriodStatesTotals() when $default != null:
return $default(_that.released,_that.awaitingPayment,_that.awaitingPeriodEnd,_that.awaitingDelivery);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PeriodStatesTotals extends PeriodStatesTotals {
  const _PeriodStatesTotals({this.released = const PeriodStateTotal(), @JsonKey(name: 'awaiting_payment') this.awaitingPayment = const PeriodStateTotal(), @JsonKey(name: 'awaiting_period_end') this.awaitingPeriodEnd = const PeriodStateTotal(), @JsonKey(name: 'awaiting_delivery') this.awaitingDelivery = const PeriodStateTotal()}): super._();
  factory _PeriodStatesTotals.fromJson(Map<String, dynamic> json) => _$PeriodStatesTotalsFromJson(json);

@override@JsonKey() final  PeriodStateTotal released;
@override@JsonKey(name: 'awaiting_payment') final  PeriodStateTotal awaitingPayment;
@override@JsonKey(name: 'awaiting_period_end') final  PeriodStateTotal awaitingPeriodEnd;
@override@JsonKey(name: 'awaiting_delivery') final  PeriodStateTotal awaitingDelivery;

/// Create a copy of PeriodStatesTotals
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PeriodStatesTotalsCopyWith<_PeriodStatesTotals> get copyWith => __$PeriodStatesTotalsCopyWithImpl<_PeriodStatesTotals>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PeriodStatesTotalsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PeriodStatesTotals&&(identical(other.released, released) || other.released == released)&&(identical(other.awaitingPayment, awaitingPayment) || other.awaitingPayment == awaitingPayment)&&(identical(other.awaitingPeriodEnd, awaitingPeriodEnd) || other.awaitingPeriodEnd == awaitingPeriodEnd)&&(identical(other.awaitingDelivery, awaitingDelivery) || other.awaitingDelivery == awaitingDelivery));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,released,awaitingPayment,awaitingPeriodEnd,awaitingDelivery);

@override
String toString() {
  return 'PeriodStatesTotals(released: $released, awaitingPayment: $awaitingPayment, awaitingPeriodEnd: $awaitingPeriodEnd, awaitingDelivery: $awaitingDelivery)';
}


}

/// @nodoc
abstract mixin class _$PeriodStatesTotalsCopyWith<$Res> implements $PeriodStatesTotalsCopyWith<$Res> {
  factory _$PeriodStatesTotalsCopyWith(_PeriodStatesTotals value, $Res Function(_PeriodStatesTotals) _then) = __$PeriodStatesTotalsCopyWithImpl;
@override @useResult
$Res call({
 PeriodStateTotal released,@JsonKey(name: 'awaiting_payment') PeriodStateTotal awaitingPayment,@JsonKey(name: 'awaiting_period_end') PeriodStateTotal awaitingPeriodEnd,@JsonKey(name: 'awaiting_delivery') PeriodStateTotal awaitingDelivery
});


@override $PeriodStateTotalCopyWith<$Res> get released;@override $PeriodStateTotalCopyWith<$Res> get awaitingPayment;@override $PeriodStateTotalCopyWith<$Res> get awaitingPeriodEnd;@override $PeriodStateTotalCopyWith<$Res> get awaitingDelivery;

}
/// @nodoc
class __$PeriodStatesTotalsCopyWithImpl<$Res>
    implements _$PeriodStatesTotalsCopyWith<$Res> {
  __$PeriodStatesTotalsCopyWithImpl(this._self, this._then);

  final _PeriodStatesTotals _self;
  final $Res Function(_PeriodStatesTotals) _then;

/// Create a copy of PeriodStatesTotals
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? released = null,Object? awaitingPayment = null,Object? awaitingPeriodEnd = null,Object? awaitingDelivery = null,}) {
  return _then(_PeriodStatesTotals(
released: null == released ? _self.released : released // ignore: cast_nullable_to_non_nullable
as PeriodStateTotal,awaitingPayment: null == awaitingPayment ? _self.awaitingPayment : awaitingPayment // ignore: cast_nullable_to_non_nullable
as PeriodStateTotal,awaitingPeriodEnd: null == awaitingPeriodEnd ? _self.awaitingPeriodEnd : awaitingPeriodEnd // ignore: cast_nullable_to_non_nullable
as PeriodStateTotal,awaitingDelivery: null == awaitingDelivery ? _self.awaitingDelivery : awaitingDelivery // ignore: cast_nullable_to_non_nullable
as PeriodStateTotal,
  ));
}

/// Create a copy of PeriodStatesTotals
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodStateTotalCopyWith<$Res> get released {
  
  return $PeriodStateTotalCopyWith<$Res>(_self.released, (value) {
    return _then(_self.copyWith(released: value));
  });
}/// Create a copy of PeriodStatesTotals
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodStateTotalCopyWith<$Res> get awaitingPayment {
  
  return $PeriodStateTotalCopyWith<$Res>(_self.awaitingPayment, (value) {
    return _then(_self.copyWith(awaitingPayment: value));
  });
}/// Create a copy of PeriodStatesTotals
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodStateTotalCopyWith<$Res> get awaitingPeriodEnd {
  
  return $PeriodStateTotalCopyWith<$Res>(_self.awaitingPeriodEnd, (value) {
    return _then(_self.copyWith(awaitingPeriodEnd: value));
  });
}/// Create a copy of PeriodStatesTotals
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodStateTotalCopyWith<$Res> get awaitingDelivery {
  
  return $PeriodStateTotalCopyWith<$Res>(_self.awaitingDelivery, (value) {
    return _then(_self.copyWith(awaitingDelivery: value));
  });
}
}


/// @nodoc
mixin _$PeriodOrdersTotals {

 int get orders;@JsonKey(name: 'investors_total') String get investorsTotal;@JsonKey(name: 'by_state') PeriodStatesTotals get byState;
/// Create a copy of PeriodOrdersTotals
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeriodOrdersTotalsCopyWith<PeriodOrdersTotals> get copyWith => _$PeriodOrdersTotalsCopyWithImpl<PeriodOrdersTotals>(this as PeriodOrdersTotals, _$identity);

  /// Serializes this PeriodOrdersTotals to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodOrdersTotals&&(identical(other.orders, orders) || other.orders == orders)&&(identical(other.investorsTotal, investorsTotal) || other.investorsTotal == investorsTotal)&&(identical(other.byState, byState) || other.byState == byState));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,orders,investorsTotal,byState);

@override
String toString() {
  return 'PeriodOrdersTotals(orders: $orders, investorsTotal: $investorsTotal, byState: $byState)';
}


}

/// @nodoc
abstract mixin class $PeriodOrdersTotalsCopyWith<$Res>  {
  factory $PeriodOrdersTotalsCopyWith(PeriodOrdersTotals value, $Res Function(PeriodOrdersTotals) _then) = _$PeriodOrdersTotalsCopyWithImpl;
@useResult
$Res call({
 int orders,@JsonKey(name: 'investors_total') String investorsTotal,@JsonKey(name: 'by_state') PeriodStatesTotals byState
});


$PeriodStatesTotalsCopyWith<$Res> get byState;

}
/// @nodoc
class _$PeriodOrdersTotalsCopyWithImpl<$Res>
    implements $PeriodOrdersTotalsCopyWith<$Res> {
  _$PeriodOrdersTotalsCopyWithImpl(this._self, this._then);

  final PeriodOrdersTotals _self;
  final $Res Function(PeriodOrdersTotals) _then;

/// Create a copy of PeriodOrdersTotals
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? orders = null,Object? investorsTotal = null,Object? byState = null,}) {
  return _then(_self.copyWith(
orders: null == orders ? _self.orders : orders // ignore: cast_nullable_to_non_nullable
as int,investorsTotal: null == investorsTotal ? _self.investorsTotal : investorsTotal // ignore: cast_nullable_to_non_nullable
as String,byState: null == byState ? _self.byState : byState // ignore: cast_nullable_to_non_nullable
as PeriodStatesTotals,
  ));
}
/// Create a copy of PeriodOrdersTotals
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodStatesTotalsCopyWith<$Res> get byState {
  
  return $PeriodStatesTotalsCopyWith<$Res>(_self.byState, (value) {
    return _then(_self.copyWith(byState: value));
  });
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int orders, @JsonKey(name: 'investors_total')  String investorsTotal, @JsonKey(name: 'by_state')  PeriodStatesTotals byState)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PeriodOrdersTotals() when $default != null:
return $default(_that.orders,_that.investorsTotal,_that.byState);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int orders, @JsonKey(name: 'investors_total')  String investorsTotal, @JsonKey(name: 'by_state')  PeriodStatesTotals byState)  $default,) {final _that = this;
switch (_that) {
case _PeriodOrdersTotals():
return $default(_that.orders,_that.investorsTotal,_that.byState);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int orders, @JsonKey(name: 'investors_total')  String investorsTotal, @JsonKey(name: 'by_state')  PeriodStatesTotals byState)?  $default,) {final _that = this;
switch (_that) {
case _PeriodOrdersTotals() when $default != null:
return $default(_that.orders,_that.investorsTotal,_that.byState);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PeriodOrdersTotals implements PeriodOrdersTotals {
  const _PeriodOrdersTotals({this.orders = 0, @JsonKey(name: 'investors_total') this.investorsTotal = '0.00', @JsonKey(name: 'by_state') this.byState = const PeriodStatesTotals()});
  factory _PeriodOrdersTotals.fromJson(Map<String, dynamic> json) => _$PeriodOrdersTotalsFromJson(json);

@override@JsonKey() final  int orders;
@override@JsonKey(name: 'investors_total') final  String investorsTotal;
@override@JsonKey(name: 'by_state') final  PeriodStatesTotals byState;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PeriodOrdersTotals&&(identical(other.orders, orders) || other.orders == orders)&&(identical(other.investorsTotal, investorsTotal) || other.investorsTotal == investorsTotal)&&(identical(other.byState, byState) || other.byState == byState));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,orders,investorsTotal,byState);

@override
String toString() {
  return 'PeriodOrdersTotals(orders: $orders, investorsTotal: $investorsTotal, byState: $byState)';
}


}

/// @nodoc
abstract mixin class _$PeriodOrdersTotalsCopyWith<$Res> implements $PeriodOrdersTotalsCopyWith<$Res> {
  factory _$PeriodOrdersTotalsCopyWith(_PeriodOrdersTotals value, $Res Function(_PeriodOrdersTotals) _then) = __$PeriodOrdersTotalsCopyWithImpl;
@override @useResult
$Res call({
 int orders,@JsonKey(name: 'investors_total') String investorsTotal,@JsonKey(name: 'by_state') PeriodStatesTotals byState
});


@override $PeriodStatesTotalsCopyWith<$Res> get byState;

}
/// @nodoc
class __$PeriodOrdersTotalsCopyWithImpl<$Res>
    implements _$PeriodOrdersTotalsCopyWith<$Res> {
  __$PeriodOrdersTotalsCopyWithImpl(this._self, this._then);

  final _PeriodOrdersTotals _self;
  final $Res Function(_PeriodOrdersTotals) _then;

/// Create a copy of PeriodOrdersTotals
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? orders = null,Object? investorsTotal = null,Object? byState = null,}) {
  return _then(_PeriodOrdersTotals(
orders: null == orders ? _self.orders : orders // ignore: cast_nullable_to_non_nullable
as int,investorsTotal: null == investorsTotal ? _self.investorsTotal : investorsTotal // ignore: cast_nullable_to_non_nullable
as String,byState: null == byState ? _self.byState : byState // ignore: cast_nullable_to_non_nullable
as PeriodStatesTotals,
  ));
}

/// Create a copy of PeriodOrdersTotals
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodStatesTotalsCopyWith<$Res> get byState {
  
  return $PeriodStatesTotalsCopyWith<$Res>(_self.byState, (value) {
    return _then(_self.copyWith(byState: value));
  });
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
