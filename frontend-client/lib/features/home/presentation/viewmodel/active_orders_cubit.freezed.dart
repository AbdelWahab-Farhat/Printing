// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'active_orders_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ActiveOrdersState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActiveOrdersState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ActiveOrdersState()';
}


}

/// @nodoc
class $ActiveOrdersStateCopyWith<$Res>  {
$ActiveOrdersStateCopyWith(ActiveOrdersState _, $Res Function(ActiveOrdersState) __);
}


/// Adds pattern-matching-related methods to [ActiveOrdersState].
extension ActiveOrdersStatePatterns on ActiveOrdersState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ActiveOrdersLoading value)?  loading,TResult Function( ActiveOrdersLoaded value)?  loaded,TResult Function( ActiveOrdersFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ActiveOrdersLoading() when loading != null:
return loading(_that);case ActiveOrdersLoaded() when loaded != null:
return loaded(_that);case ActiveOrdersFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ActiveOrdersLoading value)  loading,required TResult Function( ActiveOrdersLoaded value)  loaded,required TResult Function( ActiveOrdersFailure value)  failure,}){
final _that = this;
switch (_that) {
case ActiveOrdersLoading():
return loading(_that);case ActiveOrdersLoaded():
return loaded(_that);case ActiveOrdersFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ActiveOrdersLoading value)?  loading,TResult? Function( ActiveOrdersLoaded value)?  loaded,TResult? Function( ActiveOrdersFailure value)?  failure,}){
final _that = this;
switch (_that) {
case ActiveOrdersLoading() when loading != null:
return loading(_that);case ActiveOrdersLoaded() when loaded != null:
return loaded(_that);case ActiveOrdersFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<CustomerOrder> orders)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ActiveOrdersLoading() when loading != null:
return loading();case ActiveOrdersLoaded() when loaded != null:
return loaded(_that.orders);case ActiveOrdersFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<CustomerOrder> orders)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case ActiveOrdersLoading():
return loading();case ActiveOrdersLoaded():
return loaded(_that.orders);case ActiveOrdersFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<CustomerOrder> orders)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case ActiveOrdersLoading() when loading != null:
return loading();case ActiveOrdersLoaded() when loaded != null:
return loaded(_that.orders);case ActiveOrdersFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class ActiveOrdersLoading implements ActiveOrdersState {
  const ActiveOrdersLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActiveOrdersLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ActiveOrdersState.loading()';
}


}




/// @nodoc


class ActiveOrdersLoaded implements ActiveOrdersState {
  const ActiveOrdersLoaded(final  List<CustomerOrder> orders): _orders = orders;
  

 final  List<CustomerOrder> _orders;
 List<CustomerOrder> get orders {
  if (_orders is EqualUnmodifiableListView) return _orders;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_orders);
}


/// Create a copy of ActiveOrdersState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActiveOrdersLoadedCopyWith<ActiveOrdersLoaded> get copyWith => _$ActiveOrdersLoadedCopyWithImpl<ActiveOrdersLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActiveOrdersLoaded&&const DeepCollectionEquality().equals(other._orders, _orders));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_orders));

@override
String toString() {
  return 'ActiveOrdersState.loaded(orders: $orders)';
}


}

/// @nodoc
abstract mixin class $ActiveOrdersLoadedCopyWith<$Res> implements $ActiveOrdersStateCopyWith<$Res> {
  factory $ActiveOrdersLoadedCopyWith(ActiveOrdersLoaded value, $Res Function(ActiveOrdersLoaded) _then) = _$ActiveOrdersLoadedCopyWithImpl;
@useResult
$Res call({
 List<CustomerOrder> orders
});




}
/// @nodoc
class _$ActiveOrdersLoadedCopyWithImpl<$Res>
    implements $ActiveOrdersLoadedCopyWith<$Res> {
  _$ActiveOrdersLoadedCopyWithImpl(this._self, this._then);

  final ActiveOrdersLoaded _self;
  final $Res Function(ActiveOrdersLoaded) _then;

/// Create a copy of ActiveOrdersState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? orders = null,}) {
  return _then(ActiveOrdersLoaded(
null == orders ? _self._orders : orders // ignore: cast_nullable_to_non_nullable
as List<CustomerOrder>,
  ));
}


}

/// @nodoc


class ActiveOrdersFailure implements ActiveOrdersState {
  const ActiveOrdersFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of ActiveOrdersState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ActiveOrdersFailureCopyWith<ActiveOrdersFailure> get copyWith => _$ActiveOrdersFailureCopyWithImpl<ActiveOrdersFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ActiveOrdersFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'ActiveOrdersState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $ActiveOrdersFailureCopyWith<$Res> implements $ActiveOrdersStateCopyWith<$Res> {
  factory $ActiveOrdersFailureCopyWith(ActiveOrdersFailure value, $Res Function(ActiveOrdersFailure) _then) = _$ActiveOrdersFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$ActiveOrdersFailureCopyWithImpl<$Res>
    implements $ActiveOrdersFailureCopyWith<$Res> {
  _$ActiveOrdersFailureCopyWithImpl(this._self, this._then);

  final ActiveOrdersFailure _self;
  final $Res Function(ActiveOrdersFailure) _then;

/// Create a copy of ActiveOrdersState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(ActiveOrdersFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of ActiveOrdersState
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
