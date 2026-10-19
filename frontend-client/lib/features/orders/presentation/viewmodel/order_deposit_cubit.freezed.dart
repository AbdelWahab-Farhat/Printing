// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_deposit_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OrderDepositState {

/// الحدّان كما أرسلهما الخادم مع الطلبية.
 DepositOffer get offer;/// العربون المختار، بالدينار الكامل — يبدأ بأقلّه.
 String? get amount;/// كيف يُدفع. **لا اختيارَ مسبقاً.**
 CheckoutPayment? get payment;/// الطريقة الإلكترونية حين [payment] إلكتروني.
 int? get onlineMethodId; List<TopUpMethod> get onlineMethods;/// `null` حين لم يصل — فلا يُعرض «من المحفظة» قابلاً للاختيار.
 String? get walletBalance; bool get isSubmitting; Failure? get lastFailure;
/// Create a copy of OrderDepositState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderDepositStateCopyWith<OrderDepositState> get copyWith => _$OrderDepositStateCopyWithImpl<OrderDepositState>(this as OrderDepositState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderDepositState&&(identical(other.offer, offer) || other.offer == offer)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.payment, payment) || other.payment == payment)&&(identical(other.onlineMethodId, onlineMethodId) || other.onlineMethodId == onlineMethodId)&&const DeepCollectionEquality().equals(other.onlineMethods, onlineMethods)&&(identical(other.walletBalance, walletBalance) || other.walletBalance == walletBalance)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&(identical(other.lastFailure, lastFailure) || other.lastFailure == lastFailure));
}


@override
int get hashCode => Object.hash(runtimeType,offer,amount,payment,onlineMethodId,const DeepCollectionEquality().hash(onlineMethods),walletBalance,isSubmitting,lastFailure);

@override
String toString() {
  return 'OrderDepositState(offer: $offer, amount: $amount, payment: $payment, onlineMethodId: $onlineMethodId, onlineMethods: $onlineMethods, walletBalance: $walletBalance, isSubmitting: $isSubmitting, lastFailure: $lastFailure)';
}


}

/// @nodoc
abstract mixin class $OrderDepositStateCopyWith<$Res>  {
  factory $OrderDepositStateCopyWith(OrderDepositState value, $Res Function(OrderDepositState) _then) = _$OrderDepositStateCopyWithImpl;
@useResult
$Res call({
 DepositOffer offer, String? amount, CheckoutPayment? payment, int? onlineMethodId, List<TopUpMethod> onlineMethods, String? walletBalance, bool isSubmitting, Failure? lastFailure
});


$DepositOfferCopyWith<$Res> get offer;$FailureCopyWith<$Res>? get lastFailure;

}
/// @nodoc
class _$OrderDepositStateCopyWithImpl<$Res>
    implements $OrderDepositStateCopyWith<$Res> {
  _$OrderDepositStateCopyWithImpl(this._self, this._then);

  final OrderDepositState _self;
  final $Res Function(OrderDepositState) _then;

/// Create a copy of OrderDepositState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? offer = null,Object? amount = freezed,Object? payment = freezed,Object? onlineMethodId = freezed,Object? onlineMethods = null,Object? walletBalance = freezed,Object? isSubmitting = null,Object? lastFailure = freezed,}) {
  return _then(_self.copyWith(
offer: null == offer ? _self.offer : offer // ignore: cast_nullable_to_non_nullable
as DepositOffer,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String?,payment: freezed == payment ? _self.payment : payment // ignore: cast_nullable_to_non_nullable
as CheckoutPayment?,onlineMethodId: freezed == onlineMethodId ? _self.onlineMethodId : onlineMethodId // ignore: cast_nullable_to_non_nullable
as int?,onlineMethods: null == onlineMethods ? _self.onlineMethods : onlineMethods // ignore: cast_nullable_to_non_nullable
as List<TopUpMethod>,walletBalance: freezed == walletBalance ? _self.walletBalance : walletBalance // ignore: cast_nullable_to_non_nullable
as String?,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,lastFailure: freezed == lastFailure ? _self.lastFailure : lastFailure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}
/// Create a copy of OrderDepositState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DepositOfferCopyWith<$Res> get offer {
  
  return $DepositOfferCopyWith<$Res>(_self.offer, (value) {
    return _then(_self.copyWith(offer: value));
  });
}/// Create a copy of OrderDepositState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res>? get lastFailure {
    if (_self.lastFailure == null) {
    return null;
  }

  return $FailureCopyWith<$Res>(_self.lastFailure!, (value) {
    return _then(_self.copyWith(lastFailure: value));
  });
}
}


/// Adds pattern-matching-related methods to [OrderDepositState].
extension OrderDepositStatePatterns on OrderDepositState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderDepositState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderDepositState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderDepositState value)  $default,){
final _that = this;
switch (_that) {
case _OrderDepositState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderDepositState value)?  $default,){
final _that = this;
switch (_that) {
case _OrderDepositState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DepositOffer offer,  String? amount,  CheckoutPayment? payment,  int? onlineMethodId,  List<TopUpMethod> onlineMethods,  String? walletBalance,  bool isSubmitting,  Failure? lastFailure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderDepositState() when $default != null:
return $default(_that.offer,_that.amount,_that.payment,_that.onlineMethodId,_that.onlineMethods,_that.walletBalance,_that.isSubmitting,_that.lastFailure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DepositOffer offer,  String? amount,  CheckoutPayment? payment,  int? onlineMethodId,  List<TopUpMethod> onlineMethods,  String? walletBalance,  bool isSubmitting,  Failure? lastFailure)  $default,) {final _that = this;
switch (_that) {
case _OrderDepositState():
return $default(_that.offer,_that.amount,_that.payment,_that.onlineMethodId,_that.onlineMethods,_that.walletBalance,_that.isSubmitting,_that.lastFailure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DepositOffer offer,  String? amount,  CheckoutPayment? payment,  int? onlineMethodId,  List<TopUpMethod> onlineMethods,  String? walletBalance,  bool isSubmitting,  Failure? lastFailure)?  $default,) {final _that = this;
switch (_that) {
case _OrderDepositState() when $default != null:
return $default(_that.offer,_that.amount,_that.payment,_that.onlineMethodId,_that.onlineMethods,_that.walletBalance,_that.isSubmitting,_that.lastFailure);case _:
  return null;

}
}

}

/// @nodoc


class _OrderDepositState implements OrderDepositState {
  const _OrderDepositState({required this.offer, this.amount, this.payment, this.onlineMethodId, final  List<TopUpMethod> onlineMethods = const <TopUpMethod>[], this.walletBalance, this.isSubmitting = false, this.lastFailure}): _onlineMethods = onlineMethods;
  

/// الحدّان كما أرسلهما الخادم مع الطلبية.
@override final  DepositOffer offer;
/// العربون المختار، بالدينار الكامل — يبدأ بأقلّه.
@override final  String? amount;
/// كيف يُدفع. **لا اختيارَ مسبقاً.**
@override final  CheckoutPayment? payment;
/// الطريقة الإلكترونية حين [payment] إلكتروني.
@override final  int? onlineMethodId;
 final  List<TopUpMethod> _onlineMethods;
@override@JsonKey() List<TopUpMethod> get onlineMethods {
  if (_onlineMethods is EqualUnmodifiableListView) return _onlineMethods;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_onlineMethods);
}

/// `null` حين لم يصل — فلا يُعرض «من المحفظة» قابلاً للاختيار.
@override final  String? walletBalance;
@override@JsonKey() final  bool isSubmitting;
@override final  Failure? lastFailure;

/// Create a copy of OrderDepositState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderDepositStateCopyWith<_OrderDepositState> get copyWith => __$OrderDepositStateCopyWithImpl<_OrderDepositState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderDepositState&&(identical(other.offer, offer) || other.offer == offer)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.payment, payment) || other.payment == payment)&&(identical(other.onlineMethodId, onlineMethodId) || other.onlineMethodId == onlineMethodId)&&const DeepCollectionEquality().equals(other._onlineMethods, _onlineMethods)&&(identical(other.walletBalance, walletBalance) || other.walletBalance == walletBalance)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&(identical(other.lastFailure, lastFailure) || other.lastFailure == lastFailure));
}


@override
int get hashCode => Object.hash(runtimeType,offer,amount,payment,onlineMethodId,const DeepCollectionEquality().hash(_onlineMethods),walletBalance,isSubmitting,lastFailure);

@override
String toString() {
  return 'OrderDepositState(offer: $offer, amount: $amount, payment: $payment, onlineMethodId: $onlineMethodId, onlineMethods: $onlineMethods, walletBalance: $walletBalance, isSubmitting: $isSubmitting, lastFailure: $lastFailure)';
}


}

/// @nodoc
abstract mixin class _$OrderDepositStateCopyWith<$Res> implements $OrderDepositStateCopyWith<$Res> {
  factory _$OrderDepositStateCopyWith(_OrderDepositState value, $Res Function(_OrderDepositState) _then) = __$OrderDepositStateCopyWithImpl;
@override @useResult
$Res call({
 DepositOffer offer, String? amount, CheckoutPayment? payment, int? onlineMethodId, List<TopUpMethod> onlineMethods, String? walletBalance, bool isSubmitting, Failure? lastFailure
});


@override $DepositOfferCopyWith<$Res> get offer;@override $FailureCopyWith<$Res>? get lastFailure;

}
/// @nodoc
class __$OrderDepositStateCopyWithImpl<$Res>
    implements _$OrderDepositStateCopyWith<$Res> {
  __$OrderDepositStateCopyWithImpl(this._self, this._then);

  final _OrderDepositState _self;
  final $Res Function(_OrderDepositState) _then;

/// Create a copy of OrderDepositState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? offer = null,Object? amount = freezed,Object? payment = freezed,Object? onlineMethodId = freezed,Object? onlineMethods = null,Object? walletBalance = freezed,Object? isSubmitting = null,Object? lastFailure = freezed,}) {
  return _then(_OrderDepositState(
offer: null == offer ? _self.offer : offer // ignore: cast_nullable_to_non_nullable
as DepositOffer,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String?,payment: freezed == payment ? _self.payment : payment // ignore: cast_nullable_to_non_nullable
as CheckoutPayment?,onlineMethodId: freezed == onlineMethodId ? _self.onlineMethodId : onlineMethodId // ignore: cast_nullable_to_non_nullable
as int?,onlineMethods: null == onlineMethods ? _self._onlineMethods : onlineMethods // ignore: cast_nullable_to_non_nullable
as List<TopUpMethod>,walletBalance: freezed == walletBalance ? _self.walletBalance : walletBalance // ignore: cast_nullable_to_non_nullable
as String?,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,lastFailure: freezed == lastFailure ? _self.lastFailure : lastFailure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of OrderDepositState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DepositOfferCopyWith<$Res> get offer {
  
  return $DepositOfferCopyWith<$Res>(_self.offer, (value) {
    return _then(_self.copyWith(offer: value));
  });
}/// Create a copy of OrderDepositState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res>? get lastFailure {
    if (_self.lastFailure == null) {
    return null;
  }

  return $FailureCopyWith<$Res>(_self.lastFailure!, (value) {
    return _then(_self.copyWith(lastFailure: value));
  });
}
}

// dart format on
