// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'vendor_purchase_order_counts_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$VendorPurchaseOrderCountsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VendorPurchaseOrderCountsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'VendorPurchaseOrderCountsState()';
}


}

/// @nodoc
class $VendorPurchaseOrderCountsStateCopyWith<$Res>  {
$VendorPurchaseOrderCountsStateCopyWith(VendorPurchaseOrderCountsState _, $Res Function(VendorPurchaseOrderCountsState) __);
}


/// Adds pattern-matching-related methods to [VendorPurchaseOrderCountsState].
extension VendorPurchaseOrderCountsStatePatterns on VendorPurchaseOrderCountsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( VendorPurchaseOrderCountsLoading value)?  loading,TResult Function( VendorPurchaseOrderCountsLoaded value)?  loaded,TResult Function( VendorPurchaseOrderCountsFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case VendorPurchaseOrderCountsLoading() when loading != null:
return loading(_that);case VendorPurchaseOrderCountsLoaded() when loaded != null:
return loaded(_that);case VendorPurchaseOrderCountsFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( VendorPurchaseOrderCountsLoading value)  loading,required TResult Function( VendorPurchaseOrderCountsLoaded value)  loaded,required TResult Function( VendorPurchaseOrderCountsFailure value)  failure,}){
final _that = this;
switch (_that) {
case VendorPurchaseOrderCountsLoading():
return loading(_that);case VendorPurchaseOrderCountsLoaded():
return loaded(_that);case VendorPurchaseOrderCountsFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( VendorPurchaseOrderCountsLoading value)?  loading,TResult? Function( VendorPurchaseOrderCountsLoaded value)?  loaded,TResult? Function( VendorPurchaseOrderCountsFailure value)?  failure,}){
final _that = this;
switch (_that) {
case VendorPurchaseOrderCountsLoading() when loading != null:
return loading(_that);case VendorPurchaseOrderCountsLoaded() when loaded != null:
return loaded(_that);case VendorPurchaseOrderCountsFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( PurchaseOrderCounts counts)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case VendorPurchaseOrderCountsLoading() when loading != null:
return loading();case VendorPurchaseOrderCountsLoaded() when loaded != null:
return loaded(_that.counts);case VendorPurchaseOrderCountsFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( PurchaseOrderCounts counts)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case VendorPurchaseOrderCountsLoading():
return loading();case VendorPurchaseOrderCountsLoaded():
return loaded(_that.counts);case VendorPurchaseOrderCountsFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( PurchaseOrderCounts counts)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case VendorPurchaseOrderCountsLoading() when loading != null:
return loading();case VendorPurchaseOrderCountsLoaded() when loaded != null:
return loaded(_that.counts);case VendorPurchaseOrderCountsFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class VendorPurchaseOrderCountsLoading implements VendorPurchaseOrderCountsState {
  const VendorPurchaseOrderCountsLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VendorPurchaseOrderCountsLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'VendorPurchaseOrderCountsState.loading()';
}


}




/// @nodoc


class VendorPurchaseOrderCountsLoaded implements VendorPurchaseOrderCountsState {
  const VendorPurchaseOrderCountsLoaded(this.counts);
  

 final  PurchaseOrderCounts counts;

/// Create a copy of VendorPurchaseOrderCountsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VendorPurchaseOrderCountsLoadedCopyWith<VendorPurchaseOrderCountsLoaded> get copyWith => _$VendorPurchaseOrderCountsLoadedCopyWithImpl<VendorPurchaseOrderCountsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VendorPurchaseOrderCountsLoaded&&(identical(other.counts, counts) || other.counts == counts));
}


@override
int get hashCode => Object.hash(runtimeType,counts);

@override
String toString() {
  return 'VendorPurchaseOrderCountsState.loaded(counts: $counts)';
}


}

/// @nodoc
abstract mixin class $VendorPurchaseOrderCountsLoadedCopyWith<$Res> implements $VendorPurchaseOrderCountsStateCopyWith<$Res> {
  factory $VendorPurchaseOrderCountsLoadedCopyWith(VendorPurchaseOrderCountsLoaded value, $Res Function(VendorPurchaseOrderCountsLoaded) _then) = _$VendorPurchaseOrderCountsLoadedCopyWithImpl;
@useResult
$Res call({
 PurchaseOrderCounts counts
});




}
/// @nodoc
class _$VendorPurchaseOrderCountsLoadedCopyWithImpl<$Res>
    implements $VendorPurchaseOrderCountsLoadedCopyWith<$Res> {
  _$VendorPurchaseOrderCountsLoadedCopyWithImpl(this._self, this._then);

  final VendorPurchaseOrderCountsLoaded _self;
  final $Res Function(VendorPurchaseOrderCountsLoaded) _then;

/// Create a copy of VendorPurchaseOrderCountsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? counts = null,}) {
  return _then(VendorPurchaseOrderCountsLoaded(
null == counts ? _self.counts : counts // ignore: cast_nullable_to_non_nullable
as PurchaseOrderCounts,
  ));
}


}

/// @nodoc


class VendorPurchaseOrderCountsFailure implements VendorPurchaseOrderCountsState {
  const VendorPurchaseOrderCountsFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of VendorPurchaseOrderCountsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VendorPurchaseOrderCountsFailureCopyWith<VendorPurchaseOrderCountsFailure> get copyWith => _$VendorPurchaseOrderCountsFailureCopyWithImpl<VendorPurchaseOrderCountsFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VendorPurchaseOrderCountsFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'VendorPurchaseOrderCountsState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $VendorPurchaseOrderCountsFailureCopyWith<$Res> implements $VendorPurchaseOrderCountsStateCopyWith<$Res> {
  factory $VendorPurchaseOrderCountsFailureCopyWith(VendorPurchaseOrderCountsFailure value, $Res Function(VendorPurchaseOrderCountsFailure) _then) = _$VendorPurchaseOrderCountsFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$VendorPurchaseOrderCountsFailureCopyWithImpl<$Res>
    implements $VendorPurchaseOrderCountsFailureCopyWith<$Res> {
  _$VendorPurchaseOrderCountsFailureCopyWithImpl(this._self, this._then);

  final VendorPurchaseOrderCountsFailure _self;
  final $Res Function(VendorPurchaseOrderCountsFailure) _then;

/// Create a copy of VendorPurchaseOrderCountsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(VendorPurchaseOrderCountsFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of VendorPurchaseOrderCountsState
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
