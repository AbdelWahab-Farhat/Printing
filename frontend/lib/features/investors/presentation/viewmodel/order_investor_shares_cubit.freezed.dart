// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_investor_shares_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OrderInvestorSharesState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderInvestorSharesState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OrderInvestorSharesState()';
}


}

/// @nodoc
class $OrderInvestorSharesStateCopyWith<$Res>  {
$OrderInvestorSharesStateCopyWith(OrderInvestorSharesState _, $Res Function(OrderInvestorSharesState) __);
}


/// Adds pattern-matching-related methods to [OrderInvestorSharesState].
extension OrderInvestorSharesStatePatterns on OrderInvestorSharesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( OrderInvestorSharesLoading value)?  loading,TResult Function( OrderInvestorSharesLoaded value)?  loaded,TResult Function( OrderInvestorSharesFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case OrderInvestorSharesLoading() when loading != null:
return loading(_that);case OrderInvestorSharesLoaded() when loaded != null:
return loaded(_that);case OrderInvestorSharesFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( OrderInvestorSharesLoading value)  loading,required TResult Function( OrderInvestorSharesLoaded value)  loaded,required TResult Function( OrderInvestorSharesFailure value)  failure,}){
final _that = this;
switch (_that) {
case OrderInvestorSharesLoading():
return loading(_that);case OrderInvestorSharesLoaded():
return loaded(_that);case OrderInvestorSharesFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( OrderInvestorSharesLoading value)?  loading,TResult? Function( OrderInvestorSharesLoaded value)?  loaded,TResult? Function( OrderInvestorSharesFailure value)?  failure,}){
final _that = this;
switch (_that) {
case OrderInvestorSharesLoading() when loading != null:
return loading(_that);case OrderInvestorSharesLoaded() when loaded != null:
return loaded(_that);case OrderInvestorSharesFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<OrderInvestorShare> shares)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case OrderInvestorSharesLoading() when loading != null:
return loading();case OrderInvestorSharesLoaded() when loaded != null:
return loaded(_that.shares);case OrderInvestorSharesFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<OrderInvestorShare> shares)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case OrderInvestorSharesLoading():
return loading();case OrderInvestorSharesLoaded():
return loaded(_that.shares);case OrderInvestorSharesFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<OrderInvestorShare> shares)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case OrderInvestorSharesLoading() when loading != null:
return loading();case OrderInvestorSharesLoaded() when loaded != null:
return loaded(_that.shares);case OrderInvestorSharesFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class OrderInvestorSharesLoading implements OrderInvestorSharesState {
  const OrderInvestorSharesLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderInvestorSharesLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OrderInvestorSharesState.loading()';
}


}




/// @nodoc


class OrderInvestorSharesLoaded implements OrderInvestorSharesState {
  const OrderInvestorSharesLoaded(final  List<OrderInvestorShare> shares): _shares = shares;
  

 final  List<OrderInvestorShare> _shares;
 List<OrderInvestorShare> get shares {
  if (_shares is EqualUnmodifiableListView) return _shares;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_shares);
}


/// Create a copy of OrderInvestorSharesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderInvestorSharesLoadedCopyWith<OrderInvestorSharesLoaded> get copyWith => _$OrderInvestorSharesLoadedCopyWithImpl<OrderInvestorSharesLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderInvestorSharesLoaded&&const DeepCollectionEquality().equals(other._shares, _shares));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_shares));

@override
String toString() {
  return 'OrderInvestorSharesState.loaded(shares: $shares)';
}


}

/// @nodoc
abstract mixin class $OrderInvestorSharesLoadedCopyWith<$Res> implements $OrderInvestorSharesStateCopyWith<$Res> {
  factory $OrderInvestorSharesLoadedCopyWith(OrderInvestorSharesLoaded value, $Res Function(OrderInvestorSharesLoaded) _then) = _$OrderInvestorSharesLoadedCopyWithImpl;
@useResult
$Res call({
 List<OrderInvestorShare> shares
});




}
/// @nodoc
class _$OrderInvestorSharesLoadedCopyWithImpl<$Res>
    implements $OrderInvestorSharesLoadedCopyWith<$Res> {
  _$OrderInvestorSharesLoadedCopyWithImpl(this._self, this._then);

  final OrderInvestorSharesLoaded _self;
  final $Res Function(OrderInvestorSharesLoaded) _then;

/// Create a copy of OrderInvestorSharesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? shares = null,}) {
  return _then(OrderInvestorSharesLoaded(
null == shares ? _self._shares : shares // ignore: cast_nullable_to_non_nullable
as List<OrderInvestorShare>,
  ));
}


}

/// @nodoc


class OrderInvestorSharesFailure implements OrderInvestorSharesState {
  const OrderInvestorSharesFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of OrderInvestorSharesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderInvestorSharesFailureCopyWith<OrderInvestorSharesFailure> get copyWith => _$OrderInvestorSharesFailureCopyWithImpl<OrderInvestorSharesFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderInvestorSharesFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'OrderInvestorSharesState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $OrderInvestorSharesFailureCopyWith<$Res> implements $OrderInvestorSharesStateCopyWith<$Res> {
  factory $OrderInvestorSharesFailureCopyWith(OrderInvestorSharesFailure value, $Res Function(OrderInvestorSharesFailure) _then) = _$OrderInvestorSharesFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$OrderInvestorSharesFailureCopyWithImpl<$Res>
    implements $OrderInvestorSharesFailureCopyWith<$Res> {
  _$OrderInvestorSharesFailureCopyWithImpl(this._self, this._then);

  final OrderInvestorSharesFailure _self;
  final $Res Function(OrderInvestorSharesFailure) _then;

/// Create a copy of OrderInvestorSharesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(OrderInvestorSharesFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of OrderInvestorSharesState
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
