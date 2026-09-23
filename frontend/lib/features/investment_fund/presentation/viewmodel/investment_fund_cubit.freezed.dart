// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'investment_fund_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InvestmentFundState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestmentFundState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'InvestmentFundState()';
}


}

/// @nodoc
class $InvestmentFundStateCopyWith<$Res>  {
$InvestmentFundStateCopyWith(InvestmentFundState _, $Res Function(InvestmentFundState) __);
}


/// Adds pattern-matching-related methods to [InvestmentFundState].
extension InvestmentFundStatePatterns on InvestmentFundState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( InvestmentFundLoading value)?  loading,TResult Function( InvestmentFundLoaded value)?  loaded,TResult Function( InvestmentFundFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case InvestmentFundLoading() when loading != null:
return loading(_that);case InvestmentFundLoaded() when loaded != null:
return loaded(_that);case InvestmentFundFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( InvestmentFundLoading value)  loading,required TResult Function( InvestmentFundLoaded value)  loaded,required TResult Function( InvestmentFundFailure value)  failure,}){
final _that = this;
switch (_that) {
case InvestmentFundLoading():
return loading(_that);case InvestmentFundLoaded():
return loaded(_that);case InvestmentFundFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( InvestmentFundLoading value)?  loading,TResult? Function( InvestmentFundLoaded value)?  loaded,TResult? Function( InvestmentFundFailure value)?  failure,}){
final _that = this;
switch (_that) {
case InvestmentFundLoading() when loading != null:
return loading(_that);case InvestmentFundLoaded() when loaded != null:
return loaded(_that);case InvestmentFundFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( FundStanding standing)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case InvestmentFundLoading() when loading != null:
return loading();case InvestmentFundLoaded() when loaded != null:
return loaded(_that.standing);case InvestmentFundFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( FundStanding standing)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case InvestmentFundLoading():
return loading();case InvestmentFundLoaded():
return loaded(_that.standing);case InvestmentFundFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( FundStanding standing)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case InvestmentFundLoading() when loading != null:
return loading();case InvestmentFundLoaded() when loaded != null:
return loaded(_that.standing);case InvestmentFundFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class InvestmentFundLoading implements InvestmentFundState {
  const InvestmentFundLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestmentFundLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'InvestmentFundState.loading()';
}


}




/// @nodoc


class InvestmentFundLoaded implements InvestmentFundState {
  const InvestmentFundLoaded({required this.standing});
  

 final  FundStanding standing;

/// Create a copy of InvestmentFundState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvestmentFundLoadedCopyWith<InvestmentFundLoaded> get copyWith => _$InvestmentFundLoadedCopyWithImpl<InvestmentFundLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestmentFundLoaded&&(identical(other.standing, standing) || other.standing == standing));
}


@override
int get hashCode => Object.hash(runtimeType,standing);

@override
String toString() {
  return 'InvestmentFundState.loaded(standing: $standing)';
}


}

/// @nodoc
abstract mixin class $InvestmentFundLoadedCopyWith<$Res> implements $InvestmentFundStateCopyWith<$Res> {
  factory $InvestmentFundLoadedCopyWith(InvestmentFundLoaded value, $Res Function(InvestmentFundLoaded) _then) = _$InvestmentFundLoadedCopyWithImpl;
@useResult
$Res call({
 FundStanding standing
});


$FundStandingCopyWith<$Res> get standing;

}
/// @nodoc
class _$InvestmentFundLoadedCopyWithImpl<$Res>
    implements $InvestmentFundLoadedCopyWith<$Res> {
  _$InvestmentFundLoadedCopyWithImpl(this._self, this._then);

  final InvestmentFundLoaded _self;
  final $Res Function(InvestmentFundLoaded) _then;

/// Create a copy of InvestmentFundState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? standing = null,}) {
  return _then(InvestmentFundLoaded(
standing: null == standing ? _self.standing : standing // ignore: cast_nullable_to_non_nullable
as FundStanding,
  ));
}

/// Create a copy of InvestmentFundState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FundStandingCopyWith<$Res> get standing {
  
  return $FundStandingCopyWith<$Res>(_self.standing, (value) {
    return _then(_self.copyWith(standing: value));
  });
}
}

/// @nodoc


class InvestmentFundFailure implements InvestmentFundState {
  const InvestmentFundFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of InvestmentFundState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvestmentFundFailureCopyWith<InvestmentFundFailure> get copyWith => _$InvestmentFundFailureCopyWithImpl<InvestmentFundFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestmentFundFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'InvestmentFundState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $InvestmentFundFailureCopyWith<$Res> implements $InvestmentFundStateCopyWith<$Res> {
  factory $InvestmentFundFailureCopyWith(InvestmentFundFailure value, $Res Function(InvestmentFundFailure) _then) = _$InvestmentFundFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$InvestmentFundFailureCopyWithImpl<$Res>
    implements $InvestmentFundFailureCopyWith<$Res> {
  _$InvestmentFundFailureCopyWithImpl(this._self, this._then);

  final InvestmentFundFailure _self;
  final $Res Function(InvestmentFundFailure) _then;

/// Create a copy of InvestmentFundState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(InvestmentFundFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of InvestmentFundState
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
