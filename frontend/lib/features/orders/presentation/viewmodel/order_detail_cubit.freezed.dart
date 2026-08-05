// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_detail_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OrderDetailState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderDetailState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OrderDetailState()';
}


}

/// @nodoc
class $OrderDetailStateCopyWith<$Res>  {
$OrderDetailStateCopyWith(OrderDetailState _, $Res Function(OrderDetailState) __);
}


/// Adds pattern-matching-related methods to [OrderDetailState].
extension OrderDetailStatePatterns on OrderDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( OrderDetailLoading value)?  loading,TResult Function( OrderDetailLoaded value)?  loaded,TResult Function( OrderDetailFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case OrderDetailLoading() when loading != null:
return loading(_that);case OrderDetailLoaded() when loaded != null:
return loaded(_that);case OrderDetailFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( OrderDetailLoading value)  loading,required TResult Function( OrderDetailLoaded value)  loaded,required TResult Function( OrderDetailFailure value)  failure,}){
final _that = this;
switch (_that) {
case OrderDetailLoading():
return loading(_that);case OrderDetailLoaded():
return loaded(_that);case OrderDetailFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( OrderDetailLoading value)?  loading,TResult? Function( OrderDetailLoaded value)?  loaded,TResult? Function( OrderDetailFailure value)?  failure,}){
final _that = this;
switch (_that) {
case OrderDetailLoading() when loading != null:
return loading(_that);case OrderDetailLoaded() when loaded != null:
return loaded(_that);case OrderDetailFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( Order order,  bool isWorking)?  loaded,TResult Function( Failure failure,  Order? order)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case OrderDetailLoading() when loading != null:
return loading();case OrderDetailLoaded() when loaded != null:
return loaded(_that.order,_that.isWorking);case OrderDetailFailure() when failure != null:
return failure(_that.failure,_that.order);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( Order order,  bool isWorking)  loaded,required TResult Function( Failure failure,  Order? order)  failure,}) {final _that = this;
switch (_that) {
case OrderDetailLoading():
return loading();case OrderDetailLoaded():
return loaded(_that.order,_that.isWorking);case OrderDetailFailure():
return failure(_that.failure,_that.order);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( Order order,  bool isWorking)?  loaded,TResult? Function( Failure failure,  Order? order)?  failure,}) {final _that = this;
switch (_that) {
case OrderDetailLoading() when loading != null:
return loading();case OrderDetailLoaded() when loaded != null:
return loaded(_that.order,_that.isWorking);case OrderDetailFailure() when failure != null:
return failure(_that.failure,_that.order);case _:
  return null;

}
}

}

/// @nodoc


class OrderDetailLoading extends OrderDetailState {
  const OrderDetailLoading(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderDetailLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OrderDetailState.loading()';
}


}




/// @nodoc


class OrderDetailLoaded extends OrderDetailState {
  const OrderDetailLoaded({required this.order, this.isWorking = false}): super._();
  

 final  Order order;
@JsonKey() final  bool isWorking;

/// Create a copy of OrderDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderDetailLoadedCopyWith<OrderDetailLoaded> get copyWith => _$OrderDetailLoadedCopyWithImpl<OrderDetailLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderDetailLoaded&&(identical(other.order, order) || other.order == order)&&(identical(other.isWorking, isWorking) || other.isWorking == isWorking));
}


@override
int get hashCode => Object.hash(runtimeType,order,isWorking);

@override
String toString() {
  return 'OrderDetailState.loaded(order: $order, isWorking: $isWorking)';
}


}

/// @nodoc
abstract mixin class $OrderDetailLoadedCopyWith<$Res> implements $OrderDetailStateCopyWith<$Res> {
  factory $OrderDetailLoadedCopyWith(OrderDetailLoaded value, $Res Function(OrderDetailLoaded) _then) = _$OrderDetailLoadedCopyWithImpl;
@useResult
$Res call({
 Order order, bool isWorking
});


$OrderCopyWith<$Res> get order;

}
/// @nodoc
class _$OrderDetailLoadedCopyWithImpl<$Res>
    implements $OrderDetailLoadedCopyWith<$Res> {
  _$OrderDetailLoadedCopyWithImpl(this._self, this._then);

  final OrderDetailLoaded _self;
  final $Res Function(OrderDetailLoaded) _then;

/// Create a copy of OrderDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? order = null,Object? isWorking = null,}) {
  return _then(OrderDetailLoaded(
order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as Order,isWorking: null == isWorking ? _self.isWorking : isWorking // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of OrderDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderCopyWith<$Res> get order {
  
  return $OrderCopyWith<$Res>(_self.order, (value) {
    return _then(_self.copyWith(order: value));
  });
}
}

/// @nodoc


class OrderDetailFailure extends OrderDetailState {
  const OrderDetailFailure({required this.failure, this.order}): super._();
  

 final  Failure failure;
 final  Order? order;

/// Create a copy of OrderDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderDetailFailureCopyWith<OrderDetailFailure> get copyWith => _$OrderDetailFailureCopyWithImpl<OrderDetailFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderDetailFailure&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.order, order) || other.order == order));
}


@override
int get hashCode => Object.hash(runtimeType,failure,order);

@override
String toString() {
  return 'OrderDetailState.failure(failure: $failure, order: $order)';
}


}

/// @nodoc
abstract mixin class $OrderDetailFailureCopyWith<$Res> implements $OrderDetailStateCopyWith<$Res> {
  factory $OrderDetailFailureCopyWith(OrderDetailFailure value, $Res Function(OrderDetailFailure) _then) = _$OrderDetailFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure, Order? order
});


$FailureCopyWith<$Res> get failure;$OrderCopyWith<$Res>? get order;

}
/// @nodoc
class _$OrderDetailFailureCopyWithImpl<$Res>
    implements $OrderDetailFailureCopyWith<$Res> {
  _$OrderDetailFailureCopyWithImpl(this._self, this._then);

  final OrderDetailFailure _self;
  final $Res Function(OrderDetailFailure) _then;

/// Create a copy of OrderDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,Object? order = freezed,}) {
  return _then(OrderDetailFailure(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as Order?,
  ));
}

/// Create a copy of OrderDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res> get failure {
  
  return $FailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}/// Create a copy of OrderDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderCopyWith<$Res>? get order {
    if (_self.order == null) {
    return null;
  }

  return $OrderCopyWith<$Res>(_self.order!, (value) {
    return _then(_self.copyWith(order: value));
  });
}
}

// dart format on
