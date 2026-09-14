// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'save_shortage_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SaveShortageState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveShortageState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SaveShortageState()';
}


}

/// @nodoc
class $SaveShortageStateCopyWith<$Res>  {
$SaveShortageStateCopyWith(SaveShortageState _, $Res Function(SaveShortageState) __);
}


/// Adds pattern-matching-related methods to [SaveShortageState].
extension SaveShortageStatePatterns on SaveShortageState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SaveShortageInitial value)?  initial,TResult Function( SaveShortageSubmitting value)?  submitting,TResult Function( SaveShortageSuccess value)?  success,TResult Function( SaveShortageFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SaveShortageInitial() when initial != null:
return initial(_that);case SaveShortageSubmitting() when submitting != null:
return submitting(_that);case SaveShortageSuccess() when success != null:
return success(_that);case SaveShortageFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SaveShortageInitial value)  initial,required TResult Function( SaveShortageSubmitting value)  submitting,required TResult Function( SaveShortageSuccess value)  success,required TResult Function( SaveShortageFailure value)  failure,}){
final _that = this;
switch (_that) {
case SaveShortageInitial():
return initial(_that);case SaveShortageSubmitting():
return submitting(_that);case SaveShortageSuccess():
return success(_that);case SaveShortageFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SaveShortageInitial value)?  initial,TResult? Function( SaveShortageSubmitting value)?  submitting,TResult? Function( SaveShortageSuccess value)?  success,TResult? Function( SaveShortageFailure value)?  failure,}){
final _that = this;
switch (_that) {
case SaveShortageInitial() when initial != null:
return initial(_that);case SaveShortageSubmitting() when submitting != null:
return submitting(_that);case SaveShortageSuccess() when success != null:
return success(_that);case SaveShortageFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  submitting,TResult Function( Shortage shortage)?  success,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SaveShortageInitial() when initial != null:
return initial();case SaveShortageSubmitting() when submitting != null:
return submitting();case SaveShortageSuccess() when success != null:
return success(_that.shortage);case SaveShortageFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  submitting,required TResult Function( Shortage shortage)  success,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case SaveShortageInitial():
return initial();case SaveShortageSubmitting():
return submitting();case SaveShortageSuccess():
return success(_that.shortage);case SaveShortageFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  submitting,TResult? Function( Shortage shortage)?  success,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case SaveShortageInitial() when initial != null:
return initial();case SaveShortageSubmitting() when submitting != null:
return submitting();case SaveShortageSuccess() when success != null:
return success(_that.shortage);case SaveShortageFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class SaveShortageInitial implements SaveShortageState {
  const SaveShortageInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveShortageInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SaveShortageState.initial()';
}


}




/// @nodoc


class SaveShortageSubmitting implements SaveShortageState {
  const SaveShortageSubmitting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveShortageSubmitting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SaveShortageState.submitting()';
}


}




/// @nodoc


class SaveShortageSuccess implements SaveShortageState {
  const SaveShortageSuccess(this.shortage);
  

 final  Shortage shortage;

/// Create a copy of SaveShortageState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SaveShortageSuccessCopyWith<SaveShortageSuccess> get copyWith => _$SaveShortageSuccessCopyWithImpl<SaveShortageSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveShortageSuccess&&(identical(other.shortage, shortage) || other.shortage == shortage));
}


@override
int get hashCode => Object.hash(runtimeType,shortage);

@override
String toString() {
  return 'SaveShortageState.success(shortage: $shortage)';
}


}

/// @nodoc
abstract mixin class $SaveShortageSuccessCopyWith<$Res> implements $SaveShortageStateCopyWith<$Res> {
  factory $SaveShortageSuccessCopyWith(SaveShortageSuccess value, $Res Function(SaveShortageSuccess) _then) = _$SaveShortageSuccessCopyWithImpl;
@useResult
$Res call({
 Shortage shortage
});


$ShortageCopyWith<$Res> get shortage;

}
/// @nodoc
class _$SaveShortageSuccessCopyWithImpl<$Res>
    implements $SaveShortageSuccessCopyWith<$Res> {
  _$SaveShortageSuccessCopyWithImpl(this._self, this._then);

  final SaveShortageSuccess _self;
  final $Res Function(SaveShortageSuccess) _then;

/// Create a copy of SaveShortageState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? shortage = null,}) {
  return _then(SaveShortageSuccess(
null == shortage ? _self.shortage : shortage // ignore: cast_nullable_to_non_nullable
as Shortage,
  ));
}

/// Create a copy of SaveShortageState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShortageCopyWith<$Res> get shortage {
  
  return $ShortageCopyWith<$Res>(_self.shortage, (value) {
    return _then(_self.copyWith(shortage: value));
  });
}
}

/// @nodoc


class SaveShortageFailure implements SaveShortageState {
  const SaveShortageFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of SaveShortageState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SaveShortageFailureCopyWith<SaveShortageFailure> get copyWith => _$SaveShortageFailureCopyWithImpl<SaveShortageFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveShortageFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'SaveShortageState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $SaveShortageFailureCopyWith<$Res> implements $SaveShortageStateCopyWith<$Res> {
  factory $SaveShortageFailureCopyWith(SaveShortageFailure value, $Res Function(SaveShortageFailure) _then) = _$SaveShortageFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$SaveShortageFailureCopyWithImpl<$Res>
    implements $SaveShortageFailureCopyWith<$Res> {
  _$SaveShortageFailureCopyWithImpl(this._self, this._then);

  final SaveShortageFailure _self;
  final $Res Function(SaveShortageFailure) _then;

/// Create a copy of SaveShortageState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(SaveShortageFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of SaveShortageState
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
