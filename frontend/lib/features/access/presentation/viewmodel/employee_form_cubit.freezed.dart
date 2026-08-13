// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'employee_form_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EmployeeFormState {

 bool get isSubmitting;/// The account as the server stored it, once saved. The screen pops with it, so the detail
/// page behind knows the save happened without asking again.
 AuthUser? get saved; Failure? get failure;
/// Create a copy of EmployeeFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EmployeeFormStateCopyWith<EmployeeFormState> get copyWith => _$EmployeeFormStateCopyWithImpl<EmployeeFormState>(this as EmployeeFormState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EmployeeFormState&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&(identical(other.saved, saved) || other.saved == saved)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,isSubmitting,saved,failure);

@override
String toString() {
  return 'EmployeeFormState(isSubmitting: $isSubmitting, saved: $saved, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $EmployeeFormStateCopyWith<$Res>  {
  factory $EmployeeFormStateCopyWith(EmployeeFormState value, $Res Function(EmployeeFormState) _then) = _$EmployeeFormStateCopyWithImpl;
@useResult
$Res call({
 bool isSubmitting, AuthUser? saved, Failure? failure
});


$AuthUserCopyWith<$Res>? get saved;$FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class _$EmployeeFormStateCopyWithImpl<$Res>
    implements $EmployeeFormStateCopyWith<$Res> {
  _$EmployeeFormStateCopyWithImpl(this._self, this._then);

  final EmployeeFormState _self;
  final $Res Function(EmployeeFormState) _then;

/// Create a copy of EmployeeFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isSubmitting = null,Object? saved = freezed,Object? failure = freezed,}) {
  return _then(_self.copyWith(
isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,saved: freezed == saved ? _self.saved : saved // ignore: cast_nullable_to_non_nullable
as AuthUser?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}
/// Create a copy of EmployeeFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthUserCopyWith<$Res>? get saved {
    if (_self.saved == null) {
    return null;
  }

  return $AuthUserCopyWith<$Res>(_self.saved!, (value) {
    return _then(_self.copyWith(saved: value));
  });
}/// Create a copy of EmployeeFormState
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


/// Adds pattern-matching-related methods to [EmployeeFormState].
extension EmployeeFormStatePatterns on EmployeeFormState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EmployeeFormState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EmployeeFormState() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EmployeeFormState value)  $default,){
final _that = this;
switch (_that) {
case _EmployeeFormState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EmployeeFormState value)?  $default,){
final _that = this;
switch (_that) {
case _EmployeeFormState() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isSubmitting,  AuthUser? saved,  Failure? failure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EmployeeFormState() when $default != null:
return $default(_that.isSubmitting,_that.saved,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isSubmitting,  AuthUser? saved,  Failure? failure)  $default,) {final _that = this;
switch (_that) {
case _EmployeeFormState():
return $default(_that.isSubmitting,_that.saved,_that.failure);case _:
  throw StateError('Unexpected subclass');

}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isSubmitting,  AuthUser? saved,  Failure? failure)?  $default,) {final _that = this;
switch (_that) {
case _EmployeeFormState() when $default != null:
return $default(_that.isSubmitting,_that.saved,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _EmployeeFormState extends EmployeeFormState {
  const _EmployeeFormState({this.isSubmitting = false, this.saved, this.failure}): super._();
  

@override@JsonKey() final  bool isSubmitting;
/// The account as the server stored it, once saved. The screen pops with it, so the detail
/// page behind knows the save happened without asking again.
@override final  AuthUser? saved;
@override final  Failure? failure;

/// Create a copy of EmployeeFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EmployeeFormStateCopyWith<_EmployeeFormState> get copyWith => __$EmployeeFormStateCopyWithImpl<_EmployeeFormState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EmployeeFormState&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&(identical(other.saved, saved) || other.saved == saved)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,isSubmitting,saved,failure);

@override
String toString() {
  return 'EmployeeFormState(isSubmitting: $isSubmitting, saved: $saved, failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$EmployeeFormStateCopyWith<$Res> implements $EmployeeFormStateCopyWith<$Res> {
  factory _$EmployeeFormStateCopyWith(_EmployeeFormState value, $Res Function(_EmployeeFormState) _then) = __$EmployeeFormStateCopyWithImpl;
@override @useResult
$Res call({
 bool isSubmitting, AuthUser? saved, Failure? failure
});


@override $AuthUserCopyWith<$Res>? get saved;@override $FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class __$EmployeeFormStateCopyWithImpl<$Res>
    implements _$EmployeeFormStateCopyWith<$Res> {
  __$EmployeeFormStateCopyWithImpl(this._self, this._then);

  final _EmployeeFormState _self;
  final $Res Function(_EmployeeFormState) _then;

/// Create a copy of EmployeeFormState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isSubmitting = null,Object? saved = freezed,Object? failure = freezed,}) {
  return _then(_EmployeeFormState(
isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,saved: freezed == saved ? _self.saved : saved // ignore: cast_nullable_to_non_nullable
as AuthUser?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of EmployeeFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthUserCopyWith<$Res>? get saved {
    if (_self.saved == null) {
    return null;
  }

  return $AuthUserCopyWith<$Res>(_self.saved!, (value) {
    return _then(_self.copyWith(saved: value));
  });
}/// Create a copy of EmployeeFormState
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
