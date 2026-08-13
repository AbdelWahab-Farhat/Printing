// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'customer_order_counts_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CustomerOrderCountsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerOrderCountsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CustomerOrderCountsState()';
}


}

/// @nodoc
class $CustomerOrderCountsStateCopyWith<$Res>  {
$CustomerOrderCountsStateCopyWith(CustomerOrderCountsState _, $Res Function(CustomerOrderCountsState) __);
}


/// Adds pattern-matching-related methods to [CustomerOrderCountsState].
extension CustomerOrderCountsStatePatterns on CustomerOrderCountsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CustomerOrderCountsLoading value)?  loading,TResult Function( CustomerOrderCountsLoaded value)?  loaded,TResult Function( CustomerOrderCountsFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CustomerOrderCountsLoading() when loading != null:
return loading(_that);case CustomerOrderCountsLoaded() when loaded != null:
return loaded(_that);case CustomerOrderCountsFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CustomerOrderCountsLoading value)  loading,required TResult Function( CustomerOrderCountsLoaded value)  loaded,required TResult Function( CustomerOrderCountsFailure value)  failure,}){
final _that = this;
switch (_that) {
case CustomerOrderCountsLoading():
return loading(_that);case CustomerOrderCountsLoaded():
return loaded(_that);case CustomerOrderCountsFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CustomerOrderCountsLoading value)?  loading,TResult? Function( CustomerOrderCountsLoaded value)?  loaded,TResult? Function( CustomerOrderCountsFailure value)?  failure,}){
final _that = this;
switch (_that) {
case CustomerOrderCountsLoading() when loading != null:
return loading(_that);case CustomerOrderCountsLoaded() when loaded != null:
return loaded(_that);case CustomerOrderCountsFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( OrderCounts counts)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CustomerOrderCountsLoading() when loading != null:
return loading();case CustomerOrderCountsLoaded() when loaded != null:
return loaded(_that.counts);case CustomerOrderCountsFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( OrderCounts counts)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case CustomerOrderCountsLoading():
return loading();case CustomerOrderCountsLoaded():
return loaded(_that.counts);case CustomerOrderCountsFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( OrderCounts counts)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case CustomerOrderCountsLoading() when loading != null:
return loading();case CustomerOrderCountsLoaded() when loaded != null:
return loaded(_that.counts);case CustomerOrderCountsFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class CustomerOrderCountsLoading implements CustomerOrderCountsState {
  const CustomerOrderCountsLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerOrderCountsLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CustomerOrderCountsState.loading()';
}


}




/// @nodoc


class CustomerOrderCountsLoaded implements CustomerOrderCountsState {
  const CustomerOrderCountsLoaded(this.counts);
  

 final  OrderCounts counts;

/// Create a copy of CustomerOrderCountsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerOrderCountsLoadedCopyWith<CustomerOrderCountsLoaded> get copyWith => _$CustomerOrderCountsLoadedCopyWithImpl<CustomerOrderCountsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerOrderCountsLoaded&&(identical(other.counts, counts) || other.counts == counts));
}


@override
int get hashCode => Object.hash(runtimeType,counts);

@override
String toString() {
  return 'CustomerOrderCountsState.loaded(counts: $counts)';
}


}

/// @nodoc
abstract mixin class $CustomerOrderCountsLoadedCopyWith<$Res> implements $CustomerOrderCountsStateCopyWith<$Res> {
  factory $CustomerOrderCountsLoadedCopyWith(CustomerOrderCountsLoaded value, $Res Function(CustomerOrderCountsLoaded) _then) = _$CustomerOrderCountsLoadedCopyWithImpl;
@useResult
$Res call({
 OrderCounts counts
});




}
/// @nodoc
class _$CustomerOrderCountsLoadedCopyWithImpl<$Res>
    implements $CustomerOrderCountsLoadedCopyWith<$Res> {
  _$CustomerOrderCountsLoadedCopyWithImpl(this._self, this._then);

  final CustomerOrderCountsLoaded _self;
  final $Res Function(CustomerOrderCountsLoaded) _then;

/// Create a copy of CustomerOrderCountsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? counts = null,}) {
  return _then(CustomerOrderCountsLoaded(
null == counts ? _self.counts : counts // ignore: cast_nullable_to_non_nullable
as OrderCounts,
  ));
}


}

/// @nodoc


class CustomerOrderCountsFailure implements CustomerOrderCountsState {
  const CustomerOrderCountsFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of CustomerOrderCountsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerOrderCountsFailureCopyWith<CustomerOrderCountsFailure> get copyWith => _$CustomerOrderCountsFailureCopyWithImpl<CustomerOrderCountsFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerOrderCountsFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'CustomerOrderCountsState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $CustomerOrderCountsFailureCopyWith<$Res> implements $CustomerOrderCountsStateCopyWith<$Res> {
  factory $CustomerOrderCountsFailureCopyWith(CustomerOrderCountsFailure value, $Res Function(CustomerOrderCountsFailure) _then) = _$CustomerOrderCountsFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$CustomerOrderCountsFailureCopyWithImpl<$Res>
    implements $CustomerOrderCountsFailureCopyWith<$Res> {
  _$CustomerOrderCountsFailureCopyWithImpl(this._self, this._then);

  final CustomerOrderCountsFailure _self;
  final $Res Function(CustomerOrderCountsFailure) _then;

/// Create a copy of CustomerOrderCountsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(CustomerOrderCountsFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of CustomerOrderCountsState
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
