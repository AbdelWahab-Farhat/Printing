// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'splash_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SplashState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SplashState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SplashState()';
}


}

/// @nodoc
class $SplashStateCopyWith<$Res>  {
$SplashStateCopyWith(SplashState _, $Res Function(SplashState) __);
}


/// Adds pattern-matching-related methods to [SplashState].
extension SplashStatePatterns on SplashState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SplashChecking value)?  checking,TResult Function( SplashSignedIn value)?  signedIn,TResult Function( SplashSignedOut value)?  signedOut,TResult Function( SplashUnreachable value)?  unreachable,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SplashChecking() when checking != null:
return checking(_that);case SplashSignedIn() when signedIn != null:
return signedIn(_that);case SplashSignedOut() when signedOut != null:
return signedOut(_that);case SplashUnreachable() when unreachable != null:
return unreachable(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SplashChecking value)  checking,required TResult Function( SplashSignedIn value)  signedIn,required TResult Function( SplashSignedOut value)  signedOut,required TResult Function( SplashUnreachable value)  unreachable,}){
final _that = this;
switch (_that) {
case SplashChecking():
return checking(_that);case SplashSignedIn():
return signedIn(_that);case SplashSignedOut():
return signedOut(_that);case SplashUnreachable():
return unreachable(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SplashChecking value)?  checking,TResult? Function( SplashSignedIn value)?  signedIn,TResult? Function( SplashSignedOut value)?  signedOut,TResult? Function( SplashUnreachable value)?  unreachable,}){
final _that = this;
switch (_that) {
case SplashChecking() when checking != null:
return checking(_that);case SplashSignedIn() when signedIn != null:
return signedIn(_that);case SplashSignedOut() when signedOut != null:
return signedOut(_that);case SplashUnreachable() when unreachable != null:
return unreachable(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  checking,TResult Function()?  signedIn,TResult Function()?  signedOut,TResult Function( Failure failure)?  unreachable,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SplashChecking() when checking != null:
return checking();case SplashSignedIn() when signedIn != null:
return signedIn();case SplashSignedOut() when signedOut != null:
return signedOut();case SplashUnreachable() when unreachable != null:
return unreachable(_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  checking,required TResult Function()  signedIn,required TResult Function()  signedOut,required TResult Function( Failure failure)  unreachable,}) {final _that = this;
switch (_that) {
case SplashChecking():
return checking();case SplashSignedIn():
return signedIn();case SplashSignedOut():
return signedOut();case SplashUnreachable():
return unreachable(_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  checking,TResult? Function()?  signedIn,TResult? Function()?  signedOut,TResult? Function( Failure failure)?  unreachable,}) {final _that = this;
switch (_that) {
case SplashChecking() when checking != null:
return checking();case SplashSignedIn() when signedIn != null:
return signedIn();case SplashSignedOut() when signedOut != null:
return signedOut();case SplashUnreachable() when unreachable != null:
return unreachable(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class SplashChecking implements SplashState {
  const SplashChecking();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SplashChecking);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SplashState.checking()';
}


}




/// @nodoc


class SplashSignedIn implements SplashState {
  const SplashSignedIn();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SplashSignedIn);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SplashState.signedIn()';
}


}




/// @nodoc


class SplashSignedOut implements SplashState {
  const SplashSignedOut();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SplashSignedOut);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SplashState.signedOut()';
}


}




/// @nodoc


class SplashUnreachable implements SplashState {
  const SplashUnreachable(this.failure);
  

 final  Failure failure;

/// Create a copy of SplashState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SplashUnreachableCopyWith<SplashUnreachable> get copyWith => _$SplashUnreachableCopyWithImpl<SplashUnreachable>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SplashUnreachable&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'SplashState.unreachable(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $SplashUnreachableCopyWith<$Res> implements $SplashStateCopyWith<$Res> {
  factory $SplashUnreachableCopyWith(SplashUnreachable value, $Res Function(SplashUnreachable) _then) = _$SplashUnreachableCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$SplashUnreachableCopyWithImpl<$Res>
    implements $SplashUnreachableCopyWith<$Res> {
  _$SplashUnreachableCopyWithImpl(this._self, this._then);

  final SplashUnreachable _self;
  final $Res Function(SplashUnreachable) _then;

/// Create a copy of SplashState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(SplashUnreachable(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of SplashState
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
