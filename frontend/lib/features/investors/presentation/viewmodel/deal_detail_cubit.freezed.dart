// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'deal_detail_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DealDetailState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DealDetailState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DealDetailState()';
}


}

/// @nodoc
class $DealDetailStateCopyWith<$Res>  {
$DealDetailStateCopyWith(DealDetailState _, $Res Function(DealDetailState) __);
}


/// Adds pattern-matching-related methods to [DealDetailState].
extension DealDetailStatePatterns on DealDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DealDetailLoading value)?  loading,TResult Function( DealDetailLoaded value)?  loaded,TResult Function( DealDetailFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DealDetailLoading() when loading != null:
return loading(_that);case DealDetailLoaded() when loaded != null:
return loaded(_that);case DealDetailFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DealDetailLoading value)  loading,required TResult Function( DealDetailLoaded value)  loaded,required TResult Function( DealDetailFailure value)  failure,}){
final _that = this;
switch (_that) {
case DealDetailLoading():
return loading(_that);case DealDetailLoaded():
return loaded(_that);case DealDetailFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DealDetailLoading value)?  loading,TResult? Function( DealDetailLoaded value)?  loaded,TResult? Function( DealDetailFailure value)?  failure,}){
final _that = this;
switch (_that) {
case DealDetailLoading() when loading != null:
return loading(_that);case DealDetailLoaded() when loaded != null:
return loaded(_that);case DealDetailFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( InvestorDeal deal)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DealDetailLoading() when loading != null:
return loading();case DealDetailLoaded() when loaded != null:
return loaded(_that.deal);case DealDetailFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( InvestorDeal deal)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case DealDetailLoading():
return loading();case DealDetailLoaded():
return loaded(_that.deal);case DealDetailFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( InvestorDeal deal)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case DealDetailLoading() when loading != null:
return loading();case DealDetailLoaded() when loaded != null:
return loaded(_that.deal);case DealDetailFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class DealDetailLoading implements DealDetailState {
  const DealDetailLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DealDetailLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DealDetailState.loading()';
}


}




/// @nodoc


class DealDetailLoaded implements DealDetailState {
  const DealDetailLoaded({required this.deal});
  

 final  InvestorDeal deal;

/// Create a copy of DealDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DealDetailLoadedCopyWith<DealDetailLoaded> get copyWith => _$DealDetailLoadedCopyWithImpl<DealDetailLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DealDetailLoaded&&(identical(other.deal, deal) || other.deal == deal));
}


@override
int get hashCode => Object.hash(runtimeType,deal);

@override
String toString() {
  return 'DealDetailState.loaded(deal: $deal)';
}


}

/// @nodoc
abstract mixin class $DealDetailLoadedCopyWith<$Res> implements $DealDetailStateCopyWith<$Res> {
  factory $DealDetailLoadedCopyWith(DealDetailLoaded value, $Res Function(DealDetailLoaded) _then) = _$DealDetailLoadedCopyWithImpl;
@useResult
$Res call({
 InvestorDeal deal
});


$InvestorDealCopyWith<$Res> get deal;

}
/// @nodoc
class _$DealDetailLoadedCopyWithImpl<$Res>
    implements $DealDetailLoadedCopyWith<$Res> {
  _$DealDetailLoadedCopyWithImpl(this._self, this._then);

  final DealDetailLoaded _self;
  final $Res Function(DealDetailLoaded) _then;

/// Create a copy of DealDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? deal = null,}) {
  return _then(DealDetailLoaded(
deal: null == deal ? _self.deal : deal // ignore: cast_nullable_to_non_nullable
as InvestorDeal,
  ));
}

/// Create a copy of DealDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InvestorDealCopyWith<$Res> get deal {
  
  return $InvestorDealCopyWith<$Res>(_self.deal, (value) {
    return _then(_self.copyWith(deal: value));
  });
}
}

/// @nodoc


class DealDetailFailure implements DealDetailState {
  const DealDetailFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of DealDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DealDetailFailureCopyWith<DealDetailFailure> get copyWith => _$DealDetailFailureCopyWithImpl<DealDetailFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DealDetailFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'DealDetailState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $DealDetailFailureCopyWith<$Res> implements $DealDetailStateCopyWith<$Res> {
  factory $DealDetailFailureCopyWith(DealDetailFailure value, $Res Function(DealDetailFailure) _then) = _$DealDetailFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$DealDetailFailureCopyWithImpl<$Res>
    implements $DealDetailFailureCopyWith<$Res> {
  _$DealDetailFailureCopyWithImpl(this._self, this._then);

  final DealDetailFailure _self;
  final $Res Function(DealDetailFailure) _then;

/// Create a copy of DealDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(DealDetailFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of DealDetailState
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
