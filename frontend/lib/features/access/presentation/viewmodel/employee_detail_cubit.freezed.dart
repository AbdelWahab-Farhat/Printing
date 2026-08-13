// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'employee_detail_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EmployeeDetailState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmployeeDetailState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EmployeeDetailState()';
}


}

/// @nodoc
class $EmployeeDetailStateCopyWith<$Res>  {
$EmployeeDetailStateCopyWith(EmployeeDetailState _, $Res Function(EmployeeDetailState) __);
}


/// Adds pattern-matching-related methods to [EmployeeDetailState].
extension EmployeeDetailStatePatterns on EmployeeDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( EmployeeDetailLoading value)?  loading,TResult Function( EmployeeDetailLoaded value)?  loaded,TResult Function( EmployeeDetailChanging value)?  changing,TResult Function( EmployeeDetailFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case EmployeeDetailLoading() when loading != null:
return loading(_that);case EmployeeDetailLoaded() when loaded != null:
return loaded(_that);case EmployeeDetailChanging() when changing != null:
return changing(_that);case EmployeeDetailFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( EmployeeDetailLoading value)  loading,required TResult Function( EmployeeDetailLoaded value)  loaded,required TResult Function( EmployeeDetailChanging value)  changing,required TResult Function( EmployeeDetailFailure value)  failure,}){
final _that = this;
switch (_that) {
case EmployeeDetailLoading():
return loading(_that);case EmployeeDetailLoaded():
return loaded(_that);case EmployeeDetailChanging():
return changing(_that);case EmployeeDetailFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( EmployeeDetailLoading value)?  loading,TResult? Function( EmployeeDetailLoaded value)?  loaded,TResult? Function( EmployeeDetailChanging value)?  changing,TResult? Function( EmployeeDetailFailure value)?  failure,}){
final _that = this;
switch (_that) {
case EmployeeDetailLoading() when loading != null:
return loading(_that);case EmployeeDetailLoaded() when loaded != null:
return loaded(_that);case EmployeeDetailChanging() when changing != null:
return changing(_that);case EmployeeDetailFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( AuthUser user,  Failure? failure)?  loaded,TResult Function( AuthUser user)?  changing,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case EmployeeDetailLoading() when loading != null:
return loading();case EmployeeDetailLoaded() when loaded != null:
return loaded(_that.user,_that.failure);case EmployeeDetailChanging() when changing != null:
return changing(_that.user);case EmployeeDetailFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( AuthUser user,  Failure? failure)  loaded,required TResult Function( AuthUser user)  changing,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case EmployeeDetailLoading():
return loading();case EmployeeDetailLoaded():
return loaded(_that.user,_that.failure);case EmployeeDetailChanging():
return changing(_that.user);case EmployeeDetailFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( AuthUser user,  Failure? failure)?  loaded,TResult? Function( AuthUser user)?  changing,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case EmployeeDetailLoading() when loading != null:
return loading();case EmployeeDetailLoaded() when loaded != null:
return loaded(_that.user,_that.failure);case EmployeeDetailChanging() when changing != null:
return changing(_that.user);case EmployeeDetailFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class EmployeeDetailLoading implements EmployeeDetailState {
  const EmployeeDetailLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmployeeDetailLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'EmployeeDetailState.loading()';
}


}




/// @nodoc


class EmployeeDetailLoaded implements EmployeeDetailState {
  const EmployeeDetailLoaded(this.user, {this.failure});
  

 final  AuthUser user;
 final  Failure? failure;

/// Create a copy of EmployeeDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmployeeDetailLoadedCopyWith<EmployeeDetailLoaded> get copyWith => _$EmployeeDetailLoadedCopyWithImpl<EmployeeDetailLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmployeeDetailLoaded&&(identical(other.user, user) || other.user == user)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,user,failure);

@override
String toString() {
  return 'EmployeeDetailState.loaded(user: $user, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $EmployeeDetailLoadedCopyWith<$Res> implements $EmployeeDetailStateCopyWith<$Res> {
  factory $EmployeeDetailLoadedCopyWith(EmployeeDetailLoaded value, $Res Function(EmployeeDetailLoaded) _then) = _$EmployeeDetailLoadedCopyWithImpl;
@useResult
$Res call({
 AuthUser user, Failure? failure
});


$AuthUserCopyWith<$Res> get user;$FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class _$EmployeeDetailLoadedCopyWithImpl<$Res>
    implements $EmployeeDetailLoadedCopyWith<$Res> {
  _$EmployeeDetailLoadedCopyWithImpl(this._self, this._then);

  final EmployeeDetailLoaded _self;
  final $Res Function(EmployeeDetailLoaded) _then;

/// Create a copy of EmployeeDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? user = null,Object? failure = freezed,}) {
  return _then(EmployeeDetailLoaded(
null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as AuthUser,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of EmployeeDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthUserCopyWith<$Res> get user {
  
  return $AuthUserCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}/// Create a copy of EmployeeDetailState
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

/// @nodoc


class EmployeeDetailChanging implements EmployeeDetailState {
  const EmployeeDetailChanging(this.user);
  

 final  AuthUser user;

/// Create a copy of EmployeeDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmployeeDetailChangingCopyWith<EmployeeDetailChanging> get copyWith => _$EmployeeDetailChangingCopyWithImpl<EmployeeDetailChanging>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmployeeDetailChanging&&(identical(other.user, user) || other.user == user));
}


@override
int get hashCode => Object.hash(runtimeType,user);

@override
String toString() {
  return 'EmployeeDetailState.changing(user: $user)';
}


}

/// @nodoc
abstract mixin class $EmployeeDetailChangingCopyWith<$Res> implements $EmployeeDetailStateCopyWith<$Res> {
  factory $EmployeeDetailChangingCopyWith(EmployeeDetailChanging value, $Res Function(EmployeeDetailChanging) _then) = _$EmployeeDetailChangingCopyWithImpl;
@useResult
$Res call({
 AuthUser user
});


$AuthUserCopyWith<$Res> get user;

}
/// @nodoc
class _$EmployeeDetailChangingCopyWithImpl<$Res>
    implements $EmployeeDetailChangingCopyWith<$Res> {
  _$EmployeeDetailChangingCopyWithImpl(this._self, this._then);

  final EmployeeDetailChanging _self;
  final $Res Function(EmployeeDetailChanging) _then;

/// Create a copy of EmployeeDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? user = null,}) {
  return _then(EmployeeDetailChanging(
null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as AuthUser,
  ));
}

/// Create a copy of EmployeeDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthUserCopyWith<$Res> get user {
  
  return $AuthUserCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

/// @nodoc


class EmployeeDetailFailure implements EmployeeDetailState {
  const EmployeeDetailFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of EmployeeDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmployeeDetailFailureCopyWith<EmployeeDetailFailure> get copyWith => _$EmployeeDetailFailureCopyWithImpl<EmployeeDetailFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmployeeDetailFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'EmployeeDetailState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $EmployeeDetailFailureCopyWith<$Res> implements $EmployeeDetailStateCopyWith<$Res> {
  factory $EmployeeDetailFailureCopyWith(EmployeeDetailFailure value, $Res Function(EmployeeDetailFailure) _then) = _$EmployeeDetailFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$EmployeeDetailFailureCopyWithImpl<$Res>
    implements $EmployeeDetailFailureCopyWith<$Res> {
  _$EmployeeDetailFailureCopyWithImpl(this._self, this._then);

  final EmployeeDetailFailure _self;
  final $Res Function(EmployeeDetailFailure) _then;

/// Create a copy of EmployeeDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(EmployeeDetailFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of EmployeeDetailState
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
