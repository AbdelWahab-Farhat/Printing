// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_status_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OrderStatusState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderStatusState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OrderStatusState()';
}


}

/// @nodoc
class $OrderStatusStateCopyWith<$Res>  {
$OrderStatusStateCopyWith(OrderStatusState _, $Res Function(OrderStatusState) __);
}


/// Adds pattern-matching-related methods to [OrderStatusState].
extension OrderStatusStatePatterns on OrderStatusState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( OrderStatusLoading value)?  loading,TResult Function( OrderStatusReady value)?  ready,TResult Function( OrderStatusFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case OrderStatusLoading() when loading != null:
return loading(_that);case OrderStatusReady() when ready != null:
return ready(_that);case OrderStatusFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( OrderStatusLoading value)  loading,required TResult Function( OrderStatusReady value)  ready,required TResult Function( OrderStatusFailure value)  failure,}){
final _that = this;
switch (_that) {
case OrderStatusLoading():
return loading(_that);case OrderStatusReady():
return ready(_that);case OrderStatusFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( OrderStatusLoading value)?  loading,TResult? Function( OrderStatusReady value)?  ready,TResult? Function( OrderStatusFailure value)?  failure,}){
final _that = this;
switch (_that) {
case OrderStatusLoading() when loading != null:
return loading(_that);case OrderStatusReady() when ready != null:
return ready(_that);case OrderStatusFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( Order order,  OrderTransition? selected,  Map<String, Object?> values,  bool isSubmitting)?  ready,TResult Function( Failure failure,  Order? order,  OrderTransition? selected,  Map<String, Object?> values)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case OrderStatusLoading() when loading != null:
return loading();case OrderStatusReady() when ready != null:
return ready(_that.order,_that.selected,_that.values,_that.isSubmitting);case OrderStatusFailure() when failure != null:
return failure(_that.failure,_that.order,_that.selected,_that.values);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( Order order,  OrderTransition? selected,  Map<String, Object?> values,  bool isSubmitting)  ready,required TResult Function( Failure failure,  Order? order,  OrderTransition? selected,  Map<String, Object?> values)  failure,}) {final _that = this;
switch (_that) {
case OrderStatusLoading():
return loading();case OrderStatusReady():
return ready(_that.order,_that.selected,_that.values,_that.isSubmitting);case OrderStatusFailure():
return failure(_that.failure,_that.order,_that.selected,_that.values);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( Order order,  OrderTransition? selected,  Map<String, Object?> values,  bool isSubmitting)?  ready,TResult? Function( Failure failure,  Order? order,  OrderTransition? selected,  Map<String, Object?> values)?  failure,}) {final _that = this;
switch (_that) {
case OrderStatusLoading() when loading != null:
return loading();case OrderStatusReady() when ready != null:
return ready(_that.order,_that.selected,_that.values,_that.isSubmitting);case OrderStatusFailure() when failure != null:
return failure(_that.failure,_that.order,_that.selected,_that.values);case _:
  return null;

}
}

}

/// @nodoc


class OrderStatusLoading extends OrderStatusState {
  const OrderStatusLoading(): super._();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderStatusLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OrderStatusState.loading()';
}


}




/// @nodoc


class OrderStatusReady extends OrderStatusState {
  const OrderStatusReady({required this.order, this.selected, final  Map<String, Object?> values = const <String, Object?>{}, this.isSubmitting = false}): _values = values,super._();
  

 final  Order order;
/// Null until a destination is picked — or again after a successful move, when the order
/// on screen is a different one with different moves.
 final  OrderTransition? selected;
/// Keyed by [TransitionField.key], holding whatever that kind of field holds: a `String`
/// for text, a `List<CustomerDesign>` for artwork.
 final  Map<String, Object?> _values;
/// Keyed by [TransitionField.key], holding whatever that kind of field holds: a `String`
/// for text, a `List<CustomerDesign>` for artwork.
@JsonKey() Map<String, Object?> get values {
  if (_values is EqualUnmodifiableMapView) return _values;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_values);
}

@JsonKey() final  bool isSubmitting;

/// Create a copy of OrderStatusState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderStatusReadyCopyWith<OrderStatusReady> get copyWith => _$OrderStatusReadyCopyWithImpl<OrderStatusReady>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderStatusReady&&(identical(other.order, order) || other.order == order)&&(identical(other.selected, selected) || other.selected == selected)&&const DeepCollectionEquality().equals(other._values, _values)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting));
}


@override
int get hashCode => Object.hash(runtimeType,order,selected,const DeepCollectionEquality().hash(_values),isSubmitting);

@override
String toString() {
  return 'OrderStatusState.ready(order: $order, selected: $selected, values: $values, isSubmitting: $isSubmitting)';
}


}

/// @nodoc
abstract mixin class $OrderStatusReadyCopyWith<$Res> implements $OrderStatusStateCopyWith<$Res> {
  factory $OrderStatusReadyCopyWith(OrderStatusReady value, $Res Function(OrderStatusReady) _then) = _$OrderStatusReadyCopyWithImpl;
@useResult
$Res call({
 Order order, OrderTransition? selected, Map<String, Object?> values, bool isSubmitting
});


$OrderCopyWith<$Res> get order;$OrderTransitionCopyWith<$Res>? get selected;

}
/// @nodoc
class _$OrderStatusReadyCopyWithImpl<$Res>
    implements $OrderStatusReadyCopyWith<$Res> {
  _$OrderStatusReadyCopyWithImpl(this._self, this._then);

  final OrderStatusReady _self;
  final $Res Function(OrderStatusReady) _then;

/// Create a copy of OrderStatusState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? order = null,Object? selected = freezed,Object? values = null,Object? isSubmitting = null,}) {
  return _then(OrderStatusReady(
order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as Order,selected: freezed == selected ? _self.selected : selected // ignore: cast_nullable_to_non_nullable
as OrderTransition?,values: null == values ? _self._values : values // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of OrderStatusState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderCopyWith<$Res> get order {
  
  return $OrderCopyWith<$Res>(_self.order, (value) {
    return _then(_self.copyWith(order: value));
  });
}/// Create a copy of OrderStatusState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderTransitionCopyWith<$Res>? get selected {
    if (_self.selected == null) {
    return null;
  }

  return $OrderTransitionCopyWith<$Res>(_self.selected!, (value) {
    return _then(_self.copyWith(selected: value));
  });
}
}

/// @nodoc


class OrderStatusFailure extends OrderStatusState {
  const OrderStatusFailure({required this.failure, this.order, this.selected, final  Map<String, Object?> values = const <String, Object?>{}}): _values = values,super._();
  

 final  Failure failure;
 final  Order? order;
 final  OrderTransition? selected;
 final  Map<String, Object?> _values;
@JsonKey() Map<String, Object?> get values {
  if (_values is EqualUnmodifiableMapView) return _values;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_values);
}


/// Create a copy of OrderStatusState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderStatusFailureCopyWith<OrderStatusFailure> get copyWith => _$OrderStatusFailureCopyWithImpl<OrderStatusFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderStatusFailure&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.order, order) || other.order == order)&&(identical(other.selected, selected) || other.selected == selected)&&const DeepCollectionEquality().equals(other._values, _values));
}


@override
int get hashCode => Object.hash(runtimeType,failure,order,selected,const DeepCollectionEquality().hash(_values));

@override
String toString() {
  return 'OrderStatusState.failure(failure: $failure, order: $order, selected: $selected, values: $values)';
}


}

/// @nodoc
abstract mixin class $OrderStatusFailureCopyWith<$Res> implements $OrderStatusStateCopyWith<$Res> {
  factory $OrderStatusFailureCopyWith(OrderStatusFailure value, $Res Function(OrderStatusFailure) _then) = _$OrderStatusFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure, Order? order, OrderTransition? selected, Map<String, Object?> values
});


$FailureCopyWith<$Res> get failure;$OrderCopyWith<$Res>? get order;$OrderTransitionCopyWith<$Res>? get selected;

}
/// @nodoc
class _$OrderStatusFailureCopyWithImpl<$Res>
    implements $OrderStatusFailureCopyWith<$Res> {
  _$OrderStatusFailureCopyWithImpl(this._self, this._then);

  final OrderStatusFailure _self;
  final $Res Function(OrderStatusFailure) _then;

/// Create a copy of OrderStatusState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,Object? order = freezed,Object? selected = freezed,Object? values = null,}) {
  return _then(OrderStatusFailure(
failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as Order?,selected: freezed == selected ? _self.selected : selected // ignore: cast_nullable_to_non_nullable
as OrderTransition?,values: null == values ? _self._values : values // ignore: cast_nullable_to_non_nullable
as Map<String, Object?>,
  ));
}

/// Create a copy of OrderStatusState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res> get failure {
  
  return $FailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}/// Create a copy of OrderStatusState
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
}/// Create a copy of OrderStatusState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderTransitionCopyWith<$Res>? get selected {
    if (_self.selected == null) {
    return null;
  }

  return $OrderTransitionCopyWith<$Res>(_self.selected!, (value) {
    return _then(_self.copyWith(selected: value));
  });
}
}

// dart format on
