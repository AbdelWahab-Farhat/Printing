// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_payments_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OrderPaymentsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderPaymentsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OrderPaymentsState()';
}


}

/// @nodoc
class $OrderPaymentsStateCopyWith<$Res>  {
$OrderPaymentsStateCopyWith(OrderPaymentsState _, $Res Function(OrderPaymentsState) __);
}


/// Adds pattern-matching-related methods to [OrderPaymentsState].
extension OrderPaymentsStatePatterns on OrderPaymentsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( OrderPaymentsLoading value)?  loading,TResult Function( OrderPaymentsLoaded value)?  loaded,TResult Function( OrderPaymentsFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case OrderPaymentsLoading() when loading != null:
return loading(_that);case OrderPaymentsLoaded() when loaded != null:
return loaded(_that);case OrderPaymentsFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( OrderPaymentsLoading value)  loading,required TResult Function( OrderPaymentsLoaded value)  loaded,required TResult Function( OrderPaymentsFailure value)  failure,}){
final _that = this;
switch (_that) {
case OrderPaymentsLoading():
return loading(_that);case OrderPaymentsLoaded():
return loaded(_that);case OrderPaymentsFailure():
return failure(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( OrderPaymentsLoading value)?  loading,TResult? Function( OrderPaymentsLoaded value)?  loaded,TResult? Function( OrderPaymentsFailure value)?  failure,}){
final _that = this;
switch (_that) {
case OrderPaymentsLoading() when loading != null:
return loading(_that);case OrderPaymentsLoaded() when loaded != null:
return loaded(_that);case OrderPaymentsFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( OrderLedger ledger,  bool isWorking)?  loaded,TResult Function( Failure failure,  OrderLedger? ledger)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case OrderPaymentsLoading() when loading != null:
return loading();case OrderPaymentsLoaded() when loaded != null:
return loaded(_that.ledger,_that.isWorking);case OrderPaymentsFailure() when failure != null:
return failure(_that.failure,_that.ledger);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( OrderLedger ledger,  bool isWorking)  loaded,required TResult Function( Failure failure,  OrderLedger? ledger)  failure,}) {final _that = this;
switch (_that) {
case OrderPaymentsLoading():
return loading();case OrderPaymentsLoaded():
return loaded(_that.ledger,_that.isWorking);case OrderPaymentsFailure():
return failure(_that.failure,_that.ledger);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( OrderLedger ledger,  bool isWorking)?  loaded,TResult? Function( Failure failure,  OrderLedger? ledger)?  failure,}) {final _that = this;
switch (_that) {
case OrderPaymentsLoading() when loading != null:
return loading();case OrderPaymentsLoaded() when loaded != null:
return loaded(_that.ledger,_that.isWorking);case OrderPaymentsFailure() when failure != null:
return failure(_that.failure,_that.ledger);case _:
  return null;

}
}

}

/// @nodoc


class OrderPaymentsLoading extends OrderPaymentsState {
  const OrderPaymentsLoading(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderPaymentsLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OrderPaymentsState.loading()';
}


}




/// @nodoc


class OrderPaymentsLoaded extends OrderPaymentsState {
  const OrderPaymentsLoaded({required this.ledger, this.isWorking = false}): super._();
  

 final  OrderLedger ledger;
@JsonKey() final  bool isWorking;

/// Create a copy of OrderPaymentsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderPaymentsLoadedCopyWith<OrderPaymentsLoaded> get copyWith => _$OrderPaymentsLoadedCopyWithImpl<OrderPaymentsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderPaymentsLoaded&&(identical(other.ledger, ledger) || other.ledger == ledger)&&(identical(other.isWorking, isWorking) || other.isWorking == isWorking));
}


@override
int get hashCode => Object.hash(runtimeType,ledger,isWorking);

@override
String toString() {
  return 'OrderPaymentsState.loaded(ledger: $ledger, isWorking: $isWorking)';
}


}

/// @nodoc
abstract mixin class $OrderPaymentsLoadedCopyWith<$Res> implements $OrderPaymentsStateCopyWith<$Res> {
  factory $OrderPaymentsLoadedCopyWith(OrderPaymentsLoaded value, $Res Function(OrderPaymentsLoaded) _then) = _$OrderPaymentsLoadedCopyWithImpl;
@useResult
$Res call({
 OrderLedger ledger, bool isWorking
});


$OrderLedgerCopyWith<$Res> get ledger;

}
/// @nodoc
class _$OrderPaymentsLoadedCopyWithImpl<$Res>
    implements $OrderPaymentsLoadedCopyWith<$Res> {
  _$OrderPaymentsLoadedCopyWithImpl(this._self, this._then);

  final OrderPaymentsLoaded _self;
  final $Res Function(OrderPaymentsLoaded) _then;

/// Create a copy of OrderPaymentsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? ledger = null,Object? isWorking = null,}) {
  return _then(OrderPaymentsLoaded(
ledger: null == ledger ? _self.ledger : ledger // ignore: cast_nullable_to_non_nullable
as OrderLedger,isWorking: null == isWorking ? _self.isWorking : isWorking // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of OrderPaymentsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderLedgerCopyWith<$Res> get ledger {
  
  return $OrderLedgerCopyWith<$Res>(_self.ledger, (value) {
    return _then(_self.copyWith(ledger: value));
  });
}
}

/// @nodoc


class OrderPaymentsFailure extends OrderPaymentsState {
  const OrderPaymentsFailure({required this.failure, this.ledger}): super._();
  

 final  Failure failure;
 final  OrderLedger? ledger;

/// Create a copy of OrderPaymentsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderPaymentsFailureCopyWith<OrderPaymentsFailure> get copyWith => _$OrderPaymentsFailureCopyWithImpl<OrderPaymentsFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderPaymentsFailure&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.ledger, ledger) || other.ledger == ledger));
}


@override
int get hashCode => Object.hash(runtimeType,failure,ledger);

@override
String toString() {
  return 'OrderPaymentsState.failure(failure: $failure, ledger: $ledger)';
}


}

/// @nodoc
abstract mixin class $OrderPaymentsFailureCopyWith<$Res> implements $OrderPaymentsStateCopyWith<$Res> {
  factory $OrderPaymentsFailureCopyWith(OrderPaymentsFailure value, $Res Function(OrderPaymentsFailure) _then) = _$OrderPaymentsFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure, OrderLedger? ledger
});


$FailureCopyWith<$Res> get failure;$OrderLedgerCopyWith<$Res>? get ledger;

}
/// @nodoc
class _$OrderPaymentsFailureCopyWithImpl<$Res>
    implements $OrderPaymentsFailureCopyWith<$Res> {
  _$OrderPaymentsFailureCopyWithImpl(this._self, this._then);

  final OrderPaymentsFailure _self;
  final $Res Function(OrderPaymentsFailure) _then;

/// Create a copy of OrderPaymentsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,Object? ledger = freezed,}) {
  return _then(OrderPaymentsFailure(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,ledger: freezed == ledger ? _self.ledger : ledger // ignore: cast_nullable_to_non_nullable
as OrderLedger?,
  ));
}

/// Create a copy of OrderPaymentsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res> get failure {
  
  return $FailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}/// Create a copy of OrderPaymentsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderLedgerCopyWith<$Res>? get ledger {
    if (_self.ledger == null) {
    return null;
  }

  return $OrderLedgerCopyWith<$Res>(_self.ledger!, (value) {
    return _then(_self.copyWith(ledger: value));
  });
}
}

// dart format on
