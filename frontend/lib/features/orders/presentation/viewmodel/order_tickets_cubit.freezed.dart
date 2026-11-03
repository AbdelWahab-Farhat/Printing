// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_tickets_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OrderTicketsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderTicketsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OrderTicketsState()';
}


}

/// @nodoc
class $OrderTicketsStateCopyWith<$Res>  {
$OrderTicketsStateCopyWith(OrderTicketsState _, $Res Function(OrderTicketsState) __);
}


/// Adds pattern-matching-related methods to [OrderTicketsState].
extension OrderTicketsStatePatterns on OrderTicketsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( OrderTicketsLoading value)?  loading,TResult Function( OrderTicketsLoaded value)?  loaded,TResult Function( OrderTicketsFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case OrderTicketsLoading() when loading != null:
return loading(_that);case OrderTicketsLoaded() when loaded != null:
return loaded(_that);case OrderTicketsFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( OrderTicketsLoading value)  loading,required TResult Function( OrderTicketsLoaded value)  loaded,required TResult Function( OrderTicketsFailure value)  failure,}){
final _that = this;
switch (_that) {
case OrderTicketsLoading():
return loading(_that);case OrderTicketsLoaded():
return loaded(_that);case OrderTicketsFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( OrderTicketsLoading value)?  loading,TResult? Function( OrderTicketsLoaded value)?  loaded,TResult? Function( OrderTicketsFailure value)?  failure,}){
final _that = this;
switch (_that) {
case OrderTicketsLoading() when loading != null:
return loading(_that);case OrderTicketsLoaded() when loaded != null:
return loaded(_that);case OrderTicketsFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<OrderTicket> tickets)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case OrderTicketsLoading() when loading != null:
return loading();case OrderTicketsLoaded() when loaded != null:
return loaded(_that.tickets);case OrderTicketsFailure() when failure != null:
return failure(_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<OrderTicket> tickets)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case OrderTicketsLoading():
return loading();case OrderTicketsLoaded():
return loaded(_that.tickets);case OrderTicketsFailure():
return failure(_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<OrderTicket> tickets)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case OrderTicketsLoading() when loading != null:
return loading();case OrderTicketsLoaded() when loaded != null:
return loaded(_that.tickets);case OrderTicketsFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class OrderTicketsLoading implements OrderTicketsState {
  const OrderTicketsLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderTicketsLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OrderTicketsState.loading()';
}


}




/// @nodoc


class OrderTicketsLoaded implements OrderTicketsState {
  const OrderTicketsLoaded(final  List<OrderTicket> tickets): _tickets = tickets;
  

 final  List<OrderTicket> _tickets;
 List<OrderTicket> get tickets {
  if (_tickets is EqualUnmodifiableListView) return _tickets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tickets);
}


/// Create a copy of OrderTicketsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderTicketsLoadedCopyWith<OrderTicketsLoaded> get copyWith => _$OrderTicketsLoadedCopyWithImpl<OrderTicketsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderTicketsLoaded&&const DeepCollectionEquality().equals(other._tickets, _tickets));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_tickets));

@override
String toString() {
  return 'OrderTicketsState.loaded(tickets: $tickets)';
}


}

/// @nodoc
abstract mixin class $OrderTicketsLoadedCopyWith<$Res> implements $OrderTicketsStateCopyWith<$Res> {
  factory $OrderTicketsLoadedCopyWith(OrderTicketsLoaded value, $Res Function(OrderTicketsLoaded) _then) = _$OrderTicketsLoadedCopyWithImpl;
@useResult
$Res call({
 List<OrderTicket> tickets
});




}
/// @nodoc
class _$OrderTicketsLoadedCopyWithImpl<$Res>
    implements $OrderTicketsLoadedCopyWith<$Res> {
  _$OrderTicketsLoadedCopyWithImpl(this._self, this._then);

  final OrderTicketsLoaded _self;
  final $Res Function(OrderTicketsLoaded) _then;

/// Create a copy of OrderTicketsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? tickets = null,}) {
  return _then(OrderTicketsLoaded(
null == tickets ? _self._tickets : tickets // ignore: cast_nullable_to_non_nullable
as List<OrderTicket>,
  ));
}


}

/// @nodoc


class OrderTicketsFailure implements OrderTicketsState {
  const OrderTicketsFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of OrderTicketsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderTicketsFailureCopyWith<OrderTicketsFailure> get copyWith => _$OrderTicketsFailureCopyWithImpl<OrderTicketsFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderTicketsFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'OrderTicketsState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $OrderTicketsFailureCopyWith<$Res> implements $OrderTicketsStateCopyWith<$Res> {
  factory $OrderTicketsFailureCopyWith(OrderTicketsFailure value, $Res Function(OrderTicketsFailure) _then) = _$OrderTicketsFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$OrderTicketsFailureCopyWithImpl<$Res>
    implements $OrderTicketsFailureCopyWith<$Res> {
  _$OrderTicketsFailureCopyWithImpl(this._self, this._then);

  final OrderTicketsFailure _self;
  final $Res Function(OrderTicketsFailure) _then;

/// Create a copy of OrderTicketsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(OrderTicketsFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of OrderTicketsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res> get failure {
  
  return $FailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

// dart format on
