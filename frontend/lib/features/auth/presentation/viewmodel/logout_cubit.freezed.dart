// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'logout_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LogoutState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LogoutState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LogoutState()';
}


}

/// @nodoc
class $LogoutStateCopyWith<$Res>  {
$LogoutStateCopyWith(LogoutState _, $Res Function(LogoutState) __);
}


/// Adds pattern-matching-related methods to [LogoutState].
extension LogoutStatePatterns on LogoutState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LogoutInitial value)?  initial,TResult Function( LogoutSubmitting value)?  submitting,TResult Function( LogoutSignedOut value)?  signedOut,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LogoutInitial() when initial != null:
return initial(_that);case LogoutSubmitting() when submitting != null:
return submitting(_that);case LogoutSignedOut() when signedOut != null:
return signedOut(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LogoutInitial value)  initial,required TResult Function( LogoutSubmitting value)  submitting,required TResult Function( LogoutSignedOut value)  signedOut,}){
final _that = this;
switch (_that) {
case LogoutInitial():
return initial(_that);case LogoutSubmitting():
return submitting(_that);case LogoutSignedOut():
return signedOut(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LogoutInitial value)?  initial,TResult? Function( LogoutSubmitting value)?  submitting,TResult? Function( LogoutSignedOut value)?  signedOut,}){
final _that = this;
switch (_that) {
case LogoutInitial() when initial != null:
return initial(_that);case LogoutSubmitting() when submitting != null:
return submitting(_that);case LogoutSignedOut() when signedOut != null:
return signedOut(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  submitting,TResult Function( Failure? failure)?  signedOut,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LogoutInitial() when initial != null:
return initial();case LogoutSubmitting() when submitting != null:
return submitting();case LogoutSignedOut() when signedOut != null:
return signedOut(_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  submitting,required TResult Function( Failure? failure)  signedOut,}) {final _that = this;
switch (_that) {
case LogoutInitial():
return initial();case LogoutSubmitting():
return submitting();case LogoutSignedOut():
return signedOut(_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  submitting,TResult? Function( Failure? failure)?  signedOut,}) {final _that = this;
switch (_that) {
case LogoutInitial() when initial != null:
return initial();case LogoutSubmitting() when submitting != null:
return submitting();case LogoutSignedOut() when signedOut != null:
return signedOut(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class LogoutInitial implements LogoutState {
  const LogoutInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LogoutInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LogoutState.initial()';
}


}




/// @nodoc


class LogoutSubmitting implements LogoutState {
  const LogoutSubmitting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LogoutSubmitting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LogoutState.submitting()';
}


}




/// @nodoc


class LogoutSignedOut implements LogoutState {
  const LogoutSignedOut({this.failure});
  

 final  Failure? failure;

/// Create a copy of LogoutState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LogoutSignedOutCopyWith<LogoutSignedOut> get copyWith => _$LogoutSignedOutCopyWithImpl<LogoutSignedOut>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LogoutSignedOut&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'LogoutState.signedOut(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $LogoutSignedOutCopyWith<$Res> implements $LogoutStateCopyWith<$Res> {
  factory $LogoutSignedOutCopyWith(LogoutSignedOut value, $Res Function(LogoutSignedOut) _then) = _$LogoutSignedOutCopyWithImpl;
@useResult
$Res call({
 Failure? failure
});


$FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class _$LogoutSignedOutCopyWithImpl<$Res>
    implements $LogoutSignedOutCopyWith<$Res> {
  _$LogoutSignedOutCopyWithImpl(this._self, this._then);

  final LogoutSignedOut _self;
  final $Res Function(LogoutSignedOut) _then;

/// Create a copy of LogoutState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = freezed,}) {
  return _then(LogoutSignedOut(
failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of LogoutState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res>? get failure {
    if (_self.failure == null) {
    return null;
  }

  return $FailureCopyWith<$Res>(_self.failure!, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

// dart format on
