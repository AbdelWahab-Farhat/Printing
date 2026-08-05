// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'add_employee_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AddEmployeeState {

/// The roles there are to choose from. Empty while loading, and empty again if the list
/// could not be fetched — which does not block the form; see [AddEmployeeCubit.loadRoles].
 List<Role> get roles;/// Which of them the new account starts with. Machine names, because that is what the API
/// is given.
 Set<String> get selectedRoles; bool get isLoadingRoles; bool get isSubmitting;/// The account as the **server** stored it — including the `employee_code` it allocated,
/// which is the number colleagues will use to refer to this person.
 AuthUser? get created; Failure? get failure;
/// Create a copy of AddEmployeeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AddEmployeeStateCopyWith<AddEmployeeState> get copyWith => _$AddEmployeeStateCopyWithImpl<AddEmployeeState>(this as AddEmployeeState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AddEmployeeState&&const DeepCollectionEquality().equals(other.roles, roles)&&const DeepCollectionEquality().equals(other.selectedRoles, selectedRoles)&&(identical(other.isLoadingRoles, isLoadingRoles) || other.isLoadingRoles == isLoadingRoles)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&(identical(other.created, created) || other.created == created)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(roles),const DeepCollectionEquality().hash(selectedRoles),isLoadingRoles,isSubmitting,created,failure);

@override
String toString() {
  return 'AddEmployeeState(roles: $roles, selectedRoles: $selectedRoles, isLoadingRoles: $isLoadingRoles, isSubmitting: $isSubmitting, created: $created, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $AddEmployeeStateCopyWith<$Res>  {
  factory $AddEmployeeStateCopyWith(AddEmployeeState value, $Res Function(AddEmployeeState) _then) = _$AddEmployeeStateCopyWithImpl;
@useResult
$Res call({
 List<Role> roles, Set<String> selectedRoles, bool isLoadingRoles, bool isSubmitting, AuthUser? created, Failure? failure
});


$AuthUserCopyWith<$Res>? get created;$FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class _$AddEmployeeStateCopyWithImpl<$Res>
    implements $AddEmployeeStateCopyWith<$Res> {
  _$AddEmployeeStateCopyWithImpl(this._self, this._then);

  final AddEmployeeState _self;
  final $Res Function(AddEmployeeState) _then;

/// Create a copy of AddEmployeeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? roles = null,Object? selectedRoles = null,Object? isLoadingRoles = null,Object? isSubmitting = null,Object? created = freezed,Object? failure = freezed,}) {
  return _then(_self.copyWith(
roles: null == roles ? _self.roles : roles // ignore: cast_nullable_to_non_nullable
as List<Role>,selectedRoles: null == selectedRoles ? _self.selectedRoles : selectedRoles // ignore: cast_nullable_to_non_nullable
as Set<String>,isLoadingRoles: null == isLoadingRoles ? _self.isLoadingRoles : isLoadingRoles // ignore: cast_nullable_to_non_nullable
as bool,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,created: freezed == created ? _self.created : created // ignore: cast_nullable_to_non_nullable
as AuthUser?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}
/// Create a copy of AddEmployeeState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthUserCopyWith<$Res>? get created {
    if (_self.created == null) {
    return null;
  }

  return $AuthUserCopyWith<$Res>(_self.created!, (value) {
    return _then(_self.copyWith(created: value));
  });
}/// Create a copy of AddEmployeeState
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


/// Adds pattern-matching-related methods to [AddEmployeeState].
extension AddEmployeeStatePatterns on AddEmployeeState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AddEmployeeState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AddEmployeeState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AddEmployeeState value)  $default,){
final _that = this;
switch (_that) {
case _AddEmployeeState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AddEmployeeState value)?  $default,){
final _that = this;
switch (_that) {
case _AddEmployeeState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Role> roles,  Set<String> selectedRoles,  bool isLoadingRoles,  bool isSubmitting,  AuthUser? created,  Failure? failure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AddEmployeeState() when $default != null:
return $default(_that.roles,_that.selectedRoles,_that.isLoadingRoles,_that.isSubmitting,_that.created,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Role> roles,  Set<String> selectedRoles,  bool isLoadingRoles,  bool isSubmitting,  AuthUser? created,  Failure? failure)  $default,) {final _that = this;
switch (_that) {
case _AddEmployeeState():
return $default(_that.roles,_that.selectedRoles,_that.isLoadingRoles,_that.isSubmitting,_that.created,_that.failure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Role> roles,  Set<String> selectedRoles,  bool isLoadingRoles,  bool isSubmitting,  AuthUser? created,  Failure? failure)?  $default,) {final _that = this;
switch (_that) {
case _AddEmployeeState() when $default != null:
return $default(_that.roles,_that.selectedRoles,_that.isLoadingRoles,_that.isSubmitting,_that.created,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _AddEmployeeState extends AddEmployeeState {
  const _AddEmployeeState({final  List<Role> roles = const <Role>[], final  Set<String> selectedRoles = const <String>{}, this.isLoadingRoles = false, this.isSubmitting = false, this.created, this.failure}): _roles = roles,_selectedRoles = selectedRoles,super._();
  

/// The roles there are to choose from. Empty while loading, and empty again if the list
/// could not be fetched — which does not block the form; see [AddEmployeeCubit.loadRoles].
 final  List<Role> _roles;
/// The roles there are to choose from. Empty while loading, and empty again if the list
/// could not be fetched — which does not block the form; see [AddEmployeeCubit.loadRoles].
@override@JsonKey() List<Role> get roles {
  if (_roles is EqualUnmodifiableListView) return _roles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_roles);
}

/// Which of them the new account starts with. Machine names, because that is what the API
/// is given.
 final  Set<String> _selectedRoles;
/// Which of them the new account starts with. Machine names, because that is what the API
/// is given.
@override@JsonKey() Set<String> get selectedRoles {
  if (_selectedRoles is EqualUnmodifiableSetView) return _selectedRoles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_selectedRoles);
}

@override@JsonKey() final  bool isLoadingRoles;
@override@JsonKey() final  bool isSubmitting;
/// The account as the **server** stored it — including the `employee_code` it allocated,
/// which is the number colleagues will use to refer to this person.
@override final  AuthUser? created;
@override final  Failure? failure;

/// Create a copy of AddEmployeeState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AddEmployeeStateCopyWith<_AddEmployeeState> get copyWith => __$AddEmployeeStateCopyWithImpl<_AddEmployeeState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AddEmployeeState&&const DeepCollectionEquality().equals(other._roles, _roles)&&const DeepCollectionEquality().equals(other._selectedRoles, _selectedRoles)&&(identical(other.isLoadingRoles, isLoadingRoles) || other.isLoadingRoles == isLoadingRoles)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&(identical(other.created, created) || other.created == created)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_roles),const DeepCollectionEquality().hash(_selectedRoles),isLoadingRoles,isSubmitting,created,failure);

@override
String toString() {
  return 'AddEmployeeState(roles: $roles, selectedRoles: $selectedRoles, isLoadingRoles: $isLoadingRoles, isSubmitting: $isSubmitting, created: $created, failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$AddEmployeeStateCopyWith<$Res> implements $AddEmployeeStateCopyWith<$Res> {
  factory _$AddEmployeeStateCopyWith(_AddEmployeeState value, $Res Function(_AddEmployeeState) _then) = __$AddEmployeeStateCopyWithImpl;
@override @useResult
$Res call({
 List<Role> roles, Set<String> selectedRoles, bool isLoadingRoles, bool isSubmitting, AuthUser? created, Failure? failure
});


@override $AuthUserCopyWith<$Res>? get created;@override $FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class __$AddEmployeeStateCopyWithImpl<$Res>
    implements _$AddEmployeeStateCopyWith<$Res> {
  __$AddEmployeeStateCopyWithImpl(this._self, this._then);

  final _AddEmployeeState _self;
  final $Res Function(_AddEmployeeState) _then;

/// Create a copy of AddEmployeeState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? roles = null,Object? selectedRoles = null,Object? isLoadingRoles = null,Object? isSubmitting = null,Object? created = freezed,Object? failure = freezed,}) {
  return _then(_AddEmployeeState(
roles: null == roles ? _self._roles : roles // ignore: cast_nullable_to_non_nullable
as List<Role>,selectedRoles: null == selectedRoles ? _self._selectedRoles : selectedRoles // ignore: cast_nullable_to_non_nullable
as Set<String>,isLoadingRoles: null == isLoadingRoles ? _self.isLoadingRoles : isLoadingRoles // ignore: cast_nullable_to_non_nullable
as bool,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,created: freezed == created ? _self.created : created // ignore: cast_nullable_to_non_nullable
as AuthUser?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of AddEmployeeState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthUserCopyWith<$Res>? get created {
    if (_self.created == null) {
    return null;
  }

  return $AuthUserCopyWith<$Res>(_self.created!, (value) {
    return _then(_self.copyWith(created: value));
  });
}/// Create a copy of AddEmployeeState
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
