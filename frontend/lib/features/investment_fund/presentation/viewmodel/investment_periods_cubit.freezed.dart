// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'investment_periods_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InvestmentPeriodsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestmentPeriodsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'InvestmentPeriodsState()';
}


}

/// @nodoc
class $InvestmentPeriodsStateCopyWith<$Res>  {
$InvestmentPeriodsStateCopyWith(InvestmentPeriodsState _, $Res Function(InvestmentPeriodsState) __);
}


/// Adds pattern-matching-related methods to [InvestmentPeriodsState].
extension InvestmentPeriodsStatePatterns on InvestmentPeriodsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( InvestmentPeriodsLoading value)?  loading,TResult Function( InvestmentPeriodsLoaded value)?  loaded,TResult Function( InvestmentPeriodsFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case InvestmentPeriodsLoading() when loading != null:
return loading(_that);case InvestmentPeriodsLoaded() when loaded != null:
return loaded(_that);case InvestmentPeriodsFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( InvestmentPeriodsLoading value)  loading,required TResult Function( InvestmentPeriodsLoaded value)  loaded,required TResult Function( InvestmentPeriodsFailure value)  failure,}){
final _that = this;
switch (_that) {
case InvestmentPeriodsLoading():
return loading(_that);case InvestmentPeriodsLoaded():
return loaded(_that);case InvestmentPeriodsFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( InvestmentPeriodsLoading value)?  loading,TResult? Function( InvestmentPeriodsLoaded value)?  loaded,TResult? Function( InvestmentPeriodsFailure value)?  failure,}){
final _that = this;
switch (_that) {
case InvestmentPeriodsLoading() when loading != null:
return loading(_that);case InvestmentPeriodsLoaded() when loaded != null:
return loaded(_that);case InvestmentPeriodsFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<FundPeriod> periods)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case InvestmentPeriodsLoading() when loading != null:
return loading();case InvestmentPeriodsLoaded() when loaded != null:
return loaded(_that.periods);case InvestmentPeriodsFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<FundPeriod> periods)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case InvestmentPeriodsLoading():
return loading();case InvestmentPeriodsLoaded():
return loaded(_that.periods);case InvestmentPeriodsFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<FundPeriod> periods)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case InvestmentPeriodsLoading() when loading != null:
return loading();case InvestmentPeriodsLoaded() when loaded != null:
return loaded(_that.periods);case InvestmentPeriodsFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class InvestmentPeriodsLoading implements InvestmentPeriodsState {
  const InvestmentPeriodsLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestmentPeriodsLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'InvestmentPeriodsState.loading()';
}


}




/// @nodoc


class InvestmentPeriodsLoaded implements InvestmentPeriodsState {
  const InvestmentPeriodsLoaded({required final  List<FundPeriod> periods}): _periods = periods;
  

 final  List<FundPeriod> _periods;
 List<FundPeriod> get periods {
  if (_periods is EqualUnmodifiableListView) return _periods;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_periods);
}


/// Create a copy of InvestmentPeriodsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvestmentPeriodsLoadedCopyWith<InvestmentPeriodsLoaded> get copyWith => _$InvestmentPeriodsLoadedCopyWithImpl<InvestmentPeriodsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestmentPeriodsLoaded&&const DeepCollectionEquality().equals(other._periods, _periods));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_periods));

@override
String toString() {
  return 'InvestmentPeriodsState.loaded(periods: $periods)';
}


}

/// @nodoc
abstract mixin class $InvestmentPeriodsLoadedCopyWith<$Res> implements $InvestmentPeriodsStateCopyWith<$Res> {
  factory $InvestmentPeriodsLoadedCopyWith(InvestmentPeriodsLoaded value, $Res Function(InvestmentPeriodsLoaded) _then) = _$InvestmentPeriodsLoadedCopyWithImpl;
@useResult
$Res call({
 List<FundPeriod> periods
});




}
/// @nodoc
class _$InvestmentPeriodsLoadedCopyWithImpl<$Res>
    implements $InvestmentPeriodsLoadedCopyWith<$Res> {
  _$InvestmentPeriodsLoadedCopyWithImpl(this._self, this._then);

  final InvestmentPeriodsLoaded _self;
  final $Res Function(InvestmentPeriodsLoaded) _then;

/// Create a copy of InvestmentPeriodsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? periods = null,}) {
  return _then(InvestmentPeriodsLoaded(
periods: null == periods ? _self._periods : periods // ignore: cast_nullable_to_non_nullable
as List<FundPeriod>,
  ));
}


}

/// @nodoc


class InvestmentPeriodsFailure implements InvestmentPeriodsState {
  const InvestmentPeriodsFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of InvestmentPeriodsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvestmentPeriodsFailureCopyWith<InvestmentPeriodsFailure> get copyWith => _$InvestmentPeriodsFailureCopyWithImpl<InvestmentPeriodsFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestmentPeriodsFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'InvestmentPeriodsState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $InvestmentPeriodsFailureCopyWith<$Res> implements $InvestmentPeriodsStateCopyWith<$Res> {
  factory $InvestmentPeriodsFailureCopyWith(InvestmentPeriodsFailure value, $Res Function(InvestmentPeriodsFailure) _then) = _$InvestmentPeriodsFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$InvestmentPeriodsFailureCopyWithImpl<$Res>
    implements $InvestmentPeriodsFailureCopyWith<$Res> {
  _$InvestmentPeriodsFailureCopyWithImpl(this._self, this._then);

  final InvestmentPeriodsFailure _self;
  final $Res Function(InvestmentPeriodsFailure) _then;

/// Create a copy of InvestmentPeriodsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(InvestmentPeriodsFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of InvestmentPeriodsState
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
