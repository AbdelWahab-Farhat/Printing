// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_roles_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UserRolesState {

/// What is ticked right now — not what the server has. Nothing here is sent until [save].
 Set<String> get selected;/// The roles there are to choose from.
 List<Role> get roles; bool get isLoadingRoles; bool get isSaving;/// The account as the server returned it after a successful save. Carries the roles the
/// server actually stored, so the list behind the sheet is updated from the answer rather
/// than from what was asked for.
 AuthUser? get saved; Failure? get failure;
/// Create a copy of UserRolesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserRolesStateCopyWith<UserRolesState> get copyWith => _$UserRolesStateCopyWithImpl<UserRolesState>(this as UserRolesState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserRolesState&&const DeepCollectionEquality().equals(other.selected, selected)&&const DeepCollectionEquality().equals(other.roles, roles)&&(identical(other.isLoadingRoles, isLoadingRoles) || other.isLoadingRoles == isLoadingRoles)&&(identical(other.isSaving, isSaving) || other.isSaving == isSaving)&&(identical(other.saved, saved) || other.saved == saved)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(selected),const DeepCollectionEquality().hash(roles),isLoadingRoles,isSaving,saved,failure);

@override
String toString() {
  return 'UserRolesState(selected: $selected, roles: $roles, isLoadingRoles: $isLoadingRoles, isSaving: $isSaving, saved: $saved, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $UserRolesStateCopyWith<$Res>  {
  factory $UserRolesStateCopyWith(UserRolesState value, $Res Function(UserRolesState) _then) = _$UserRolesStateCopyWithImpl;
@useResult
$Res call({
 Set<String> selected, List<Role> roles, bool isLoadingRoles, bool isSaving, AuthUser? saved, Failure? failure
});


$AuthUserCopyWith<$Res>? get saved;$FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class _$UserRolesStateCopyWithImpl<$Res>
    implements $UserRolesStateCopyWith<$Res> {
  _$UserRolesStateCopyWithImpl(this._self, this._then);

  final UserRolesState _self;
  final $Res Function(UserRolesState) _then;

/// Create a copy of UserRolesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? selected = null,Object? roles = null,Object? isLoadingRoles = null,Object? isSaving = null,Object? saved = freezed,Object? failure = freezed,}) {
  return _then(_self.copyWith(
selected: null == selected ? _self.selected : selected // ignore: cast_nullable_to_non_nullable
as Set<String>,roles: null == roles ? _self.roles : roles // ignore: cast_nullable_to_non_nullable
as List<Role>,isLoadingRoles: null == isLoadingRoles ? _self.isLoadingRoles : isLoadingRoles // ignore: cast_nullable_to_non_nullable
as bool,isSaving: null == isSaving ? _self.isSaving : isSaving // ignore: cast_nullable_to_non_nullable
as bool,saved: freezed == saved ? _self.saved : saved // ignore: cast_nullable_to_non_nullable
as AuthUser?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}
/// Create a copy of UserRolesState
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
}/// Create a copy of UserRolesState
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


/// Adds pattern-matching-related methods to [UserRolesState].
extension UserRolesStatePatterns on UserRolesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserRolesState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserRolesState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserRolesState value)  $default,){
final _that = this;
switch (_that) {
case _UserRolesState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserRolesState value)?  $default,){
final _that = this;
switch (_that) {
case _UserRolesState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Set<String> selected,  List<Role> roles,  bool isLoadingRoles,  bool isSaving,  AuthUser? saved,  Failure? failure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UserRolesState() when $default != null:
return $default(_that.selected,_that.roles,_that.isLoadingRoles,_that.isSaving,_that.saved,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Set<String> selected,  List<Role> roles,  bool isLoadingRoles,  bool isSaving,  AuthUser? saved,  Failure? failure)  $default,) {final _that = this;
switch (_that) {
case _UserRolesState():
return $default(_that.selected,_that.roles,_that.isLoadingRoles,_that.isSaving,_that.saved,_that.failure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Set<String> selected,  List<Role> roles,  bool isLoadingRoles,  bool isSaving,  AuthUser? saved,  Failure? failure)?  $default,) {final _that = this;
switch (_that) {
case _UserRolesState() when $default != null:
return $default(_that.selected,_that.roles,_that.isLoadingRoles,_that.isSaving,_that.saved,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _UserRolesState extends UserRolesState {
  const _UserRolesState({final  Set<String> selected = const <String>{}, final  List<Role> roles = const <Role>[], this.isLoadingRoles = false, this.isSaving = false, this.saved, this.failure}): _selected = selected,_roles = roles,super._();
  

/// What is ticked right now — not what the server has. Nothing here is sent until [save].
 final  Set<String> _selected;
/// What is ticked right now — not what the server has. Nothing here is sent until [save].
@override@JsonKey() Set<String> get selected {
  if (_selected is EqualUnmodifiableSetView) return _selected;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_selected);
}

/// The roles there are to choose from.
 final  List<Role> _roles;
/// The roles there are to choose from.
@override@JsonKey() List<Role> get roles {
  if (_roles is EqualUnmodifiableListView) return _roles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_roles);
}

@override@JsonKey() final  bool isLoadingRoles;
@override@JsonKey() final  bool isSaving;
/// The account as the server returned it after a successful save. Carries the roles the
/// server actually stored, so the list behind the sheet is updated from the answer rather
/// than from what was asked for.
@override final  AuthUser? saved;
@override final  Failure? failure;

/// Create a copy of UserRolesState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserRolesStateCopyWith<_UserRolesState> get copyWith => __$UserRolesStateCopyWithImpl<_UserRolesState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserRolesState&&const DeepCollectionEquality().equals(other._selected, _selected)&&const DeepCollectionEquality().equals(other._roles, _roles)&&(identical(other.isLoadingRoles, isLoadingRoles) || other.isLoadingRoles == isLoadingRoles)&&(identical(other.isSaving, isSaving) || other.isSaving == isSaving)&&(identical(other.saved, saved) || other.saved == saved)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_selected),const DeepCollectionEquality().hash(_roles),isLoadingRoles,isSaving,saved,failure);

@override
String toString() {
  return 'UserRolesState(selected: $selected, roles: $roles, isLoadingRoles: $isLoadingRoles, isSaving: $isSaving, saved: $saved, failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$UserRolesStateCopyWith<$Res> implements $UserRolesStateCopyWith<$Res> {
  factory _$UserRolesStateCopyWith(_UserRolesState value, $Res Function(_UserRolesState) _then) = __$UserRolesStateCopyWithImpl;
@override @useResult
$Res call({
 Set<String> selected, List<Role> roles, bool isLoadingRoles, bool isSaving, AuthUser? saved, Failure? failure
});


@override $AuthUserCopyWith<$Res>? get saved;@override $FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class __$UserRolesStateCopyWithImpl<$Res>
    implements _$UserRolesStateCopyWith<$Res> {
  __$UserRolesStateCopyWithImpl(this._self, this._then);

  final _UserRolesState _self;
  final $Res Function(_UserRolesState) _then;

/// Create a copy of UserRolesState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? selected = null,Object? roles = null,Object? isLoadingRoles = null,Object? isSaving = null,Object? saved = freezed,Object? failure = freezed,}) {
  return _then(_UserRolesState(
selected: null == selected ? _self._selected : selected // ignore: cast_nullable_to_non_nullable
as Set<String>,roles: null == roles ? _self._roles : roles // ignore: cast_nullable_to_non_nullable
as List<Role>,isLoadingRoles: null == isLoadingRoles ? _self.isLoadingRoles : isLoadingRoles // ignore: cast_nullable_to_non_nullable
as bool,isSaving: null == isSaving ? _self.isSaving : isSaving // ignore: cast_nullable_to_non_nullable
as bool,saved: freezed == saved ? _self.saved : saved // ignore: cast_nullable_to_non_nullable
as AuthUser?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of UserRolesState
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
}/// Create a copy of UserRolesState
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
