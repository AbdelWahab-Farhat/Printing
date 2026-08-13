// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profit_and_loss_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProfitAndLossState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfitAndLossState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProfitAndLossState()';
}


}

/// @nodoc
class $ProfitAndLossStateCopyWith<$Res>  {
$ProfitAndLossStateCopyWith(ProfitAndLossState _, $Res Function(ProfitAndLossState) __);
}


/// Adds pattern-matching-related methods to [ProfitAndLossState].
extension ProfitAndLossStatePatterns on ProfitAndLossState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ProfitAndLossInitial value)?  initial,TResult Function( ProfitAndLossLoading value)?  loading,TResult Function( ProfitAndLossLoaded value)?  loaded,TResult Function( ProfitAndLossFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ProfitAndLossInitial() when initial != null:
return initial(_that);case ProfitAndLossLoading() when loading != null:
return loading(_that);case ProfitAndLossLoaded() when loaded != null:
return loaded(_that);case ProfitAndLossFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ProfitAndLossInitial value)  initial,required TResult Function( ProfitAndLossLoading value)  loading,required TResult Function( ProfitAndLossLoaded value)  loaded,required TResult Function( ProfitAndLossFailure value)  failure,}){
final _that = this;
switch (_that) {
case ProfitAndLossInitial():
return initial(_that);case ProfitAndLossLoading():
return loading(_that);case ProfitAndLossLoaded():
return loaded(_that);case ProfitAndLossFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ProfitAndLossInitial value)?  initial,TResult? Function( ProfitAndLossLoading value)?  loading,TResult? Function( ProfitAndLossLoaded value)?  loaded,TResult? Function( ProfitAndLossFailure value)?  failure,}){
final _that = this;
switch (_that) {
case ProfitAndLossInitial() when initial != null:
return initial(_that);case ProfitAndLossLoading() when loading != null:
return loading(_that);case ProfitAndLossLoaded() when loaded != null:
return loaded(_that);case ProfitAndLossFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( ProfitAndLossSummary summary)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ProfitAndLossInitial() when initial != null:
return initial();case ProfitAndLossLoading() when loading != null:
return loading();case ProfitAndLossLoaded() when loaded != null:
return loaded(_that.summary);case ProfitAndLossFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( ProfitAndLossSummary summary)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case ProfitAndLossInitial():
return initial();case ProfitAndLossLoading():
return loading();case ProfitAndLossLoaded():
return loaded(_that.summary);case ProfitAndLossFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( ProfitAndLossSummary summary)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case ProfitAndLossInitial() when initial != null:
return initial();case ProfitAndLossLoading() when loading != null:
return loading();case ProfitAndLossLoaded() when loaded != null:
return loaded(_that.summary);case ProfitAndLossFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class ProfitAndLossInitial implements ProfitAndLossState {
  const ProfitAndLossInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfitAndLossInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProfitAndLossState.initial()';
}


}




/// @nodoc


class ProfitAndLossLoading implements ProfitAndLossState {
  const ProfitAndLossLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfitAndLossLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProfitAndLossState.loading()';
}


}




/// @nodoc


class ProfitAndLossLoaded implements ProfitAndLossState {
  const ProfitAndLossLoaded(this.summary);
  

 final  ProfitAndLossSummary summary;

/// Create a copy of ProfitAndLossState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfitAndLossLoadedCopyWith<ProfitAndLossLoaded> get copyWith => _$ProfitAndLossLoadedCopyWithImpl<ProfitAndLossLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfitAndLossLoaded&&(identical(other.summary, summary) || other.summary == summary));
}


@override
int get hashCode => Object.hash(runtimeType,summary);

@override
String toString() {
  return 'ProfitAndLossState.loaded(summary: $summary)';
}


}

/// @nodoc
abstract mixin class $ProfitAndLossLoadedCopyWith<$Res> implements $ProfitAndLossStateCopyWith<$Res> {
  factory $ProfitAndLossLoadedCopyWith(ProfitAndLossLoaded value, $Res Function(ProfitAndLossLoaded) _then) = _$ProfitAndLossLoadedCopyWithImpl;
@useResult
$Res call({
 ProfitAndLossSummary summary
});


$ProfitAndLossSummaryCopyWith<$Res> get summary;

}
/// @nodoc
class _$ProfitAndLossLoadedCopyWithImpl<$Res>
    implements $ProfitAndLossLoadedCopyWith<$Res> {
  _$ProfitAndLossLoadedCopyWithImpl(this._self, this._then);

  final ProfitAndLossLoaded _self;
  final $Res Function(ProfitAndLossLoaded) _then;

/// Create a copy of ProfitAndLossState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? summary = null,}) {
  return _then(ProfitAndLossLoaded(
null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as ProfitAndLossSummary,
  ));
}

/// Create a copy of ProfitAndLossState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfitAndLossSummaryCopyWith<$Res> get summary {
  
  return $ProfitAndLossSummaryCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}

/// @nodoc


class ProfitAndLossFailure implements ProfitAndLossState {
  const ProfitAndLossFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of ProfitAndLossState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfitAndLossFailureCopyWith<ProfitAndLossFailure> get copyWith => _$ProfitAndLossFailureCopyWithImpl<ProfitAndLossFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfitAndLossFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'ProfitAndLossState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $ProfitAndLossFailureCopyWith<$Res> implements $ProfitAndLossStateCopyWith<$Res> {
  factory $ProfitAndLossFailureCopyWith(ProfitAndLossFailure value, $Res Function(ProfitAndLossFailure) _then) = _$ProfitAndLossFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$ProfitAndLossFailureCopyWithImpl<$Res>
    implements $ProfitAndLossFailureCopyWith<$Res> {
  _$ProfitAndLossFailureCopyWithImpl(this._self, this._then);

  final ProfitAndLossFailure _self;
  final $Res Function(ProfitAndLossFailure) _then;

/// Create a copy of ProfitAndLossState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(ProfitAndLossFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of ProfitAndLossState
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
