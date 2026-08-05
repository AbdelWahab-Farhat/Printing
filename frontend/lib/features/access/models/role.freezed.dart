// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'role.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Role {

 int get id;/// The machine name the gate compares against — `admin`, `accountant`. Lowercase Latin,
/// and what `PATCH /users/{id}/roles` is given.
 String get name;/// Arabic, for a person. Falls back to [name] on the server for roles the code knows
/// nothing about, so this is always safe to print.
 String get label;/// The administrator: its access comes from a gate rule, not from permission rows, so its
/// [permissions] list is **empty while its actual access is total**. Saying so explicitly is
/// what stops that reading as a bug on a permissions screen.
@JsonKey(name: 'grants_everything') bool get grantsEverything;/// The code references this role by name, so it cannot be deleted.
@JsonKey(name: 'is_system') bool get isSystem;@JsonKey(name: 'can_be_renamed') bool get canBeRenamed;@JsonKey(name: 'can_be_deleted') bool get canBeDeleted;@JsonKey(name: 'can_edit_permissions') bool get canEditPermissions;/// What this role grants, as `{name, label}` pairs. Empty is meaningful: a role created a
/// minute ago grants nothing, and so does the administrator — see [grantsEverything].
 List<PermissionOption> get permissions;/// How many people hold it. The reason a role cannot be deleted, when it cannot.
@JsonKey(name: 'users_count') int? get usersCount;
/// Create a copy of Role
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoleCopyWith<Role> get copyWith => _$RoleCopyWithImpl<Role>(this as Role, _$identity);

  /// Serializes this Role to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Role&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.label, label) || other.label == label)&&(identical(other.grantsEverything, grantsEverything) || other.grantsEverything == grantsEverything)&&(identical(other.isSystem, isSystem) || other.isSystem == isSystem)&&(identical(other.canBeRenamed, canBeRenamed) || other.canBeRenamed == canBeRenamed)&&(identical(other.canBeDeleted, canBeDeleted) || other.canBeDeleted == canBeDeleted)&&(identical(other.canEditPermissions, canEditPermissions) || other.canEditPermissions == canEditPermissions)&&const DeepCollectionEquality().equals(other.permissions, permissions)&&(identical(other.usersCount, usersCount) || other.usersCount == usersCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,label,grantsEverything,isSystem,canBeRenamed,canBeDeleted,canEditPermissions,const DeepCollectionEquality().hash(permissions),usersCount);

@override
String toString() {
  return 'Role(id: $id, name: $name, label: $label, grantsEverything: $grantsEverything, isSystem: $isSystem, canBeRenamed: $canBeRenamed, canBeDeleted: $canBeDeleted, canEditPermissions: $canEditPermissions, permissions: $permissions, usersCount: $usersCount)';
}


}

/// @nodoc
abstract mixin class $RoleCopyWith<$Res>  {
  factory $RoleCopyWith(Role value, $Res Function(Role) _then) = _$RoleCopyWithImpl;
@useResult
$Res call({
 int id, String name, String label,@JsonKey(name: 'grants_everything') bool grantsEverything,@JsonKey(name: 'is_system') bool isSystem,@JsonKey(name: 'can_be_renamed') bool canBeRenamed,@JsonKey(name: 'can_be_deleted') bool canBeDeleted,@JsonKey(name: 'can_edit_permissions') bool canEditPermissions, List<PermissionOption> permissions,@JsonKey(name: 'users_count') int? usersCount
});




}
/// @nodoc
class _$RoleCopyWithImpl<$Res>
    implements $RoleCopyWith<$Res> {
  _$RoleCopyWithImpl(this._self, this._then);

  final Role _self;
  final $Res Function(Role) _then;

/// Create a copy of Role
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? label = null,Object? grantsEverything = null,Object? isSystem = null,Object? canBeRenamed = null,Object? canBeDeleted = null,Object? canEditPermissions = null,Object? permissions = null,Object? usersCount = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,grantsEverything: null == grantsEverything ? _self.grantsEverything : grantsEverything // ignore: cast_nullable_to_non_nullable
as bool,isSystem: null == isSystem ? _self.isSystem : isSystem // ignore: cast_nullable_to_non_nullable
as bool,canBeRenamed: null == canBeRenamed ? _self.canBeRenamed : canBeRenamed // ignore: cast_nullable_to_non_nullable
as bool,canBeDeleted: null == canBeDeleted ? _self.canBeDeleted : canBeDeleted // ignore: cast_nullable_to_non_nullable
as bool,canEditPermissions: null == canEditPermissions ? _self.canEditPermissions : canEditPermissions // ignore: cast_nullable_to_non_nullable
as bool,permissions: null == permissions ? _self.permissions : permissions // ignore: cast_nullable_to_non_nullable
as List<PermissionOption>,usersCount: freezed == usersCount ? _self.usersCount : usersCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [Role].
extension RolePatterns on Role {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Role value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Role() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Role value)  $default,){
final _that = this;
switch (_that) {
case _Role():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Role value)?  $default,){
final _that = this;
switch (_that) {
case _Role() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String label, @JsonKey(name: 'grants_everything')  bool grantsEverything, @JsonKey(name: 'is_system')  bool isSystem, @JsonKey(name: 'can_be_renamed')  bool canBeRenamed, @JsonKey(name: 'can_be_deleted')  bool canBeDeleted, @JsonKey(name: 'can_edit_permissions')  bool canEditPermissions,  List<PermissionOption> permissions, @JsonKey(name: 'users_count')  int? usersCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Role() when $default != null:
return $default(_that.id,_that.name,_that.label,_that.grantsEverything,_that.isSystem,_that.canBeRenamed,_that.canBeDeleted,_that.canEditPermissions,_that.permissions,_that.usersCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String label, @JsonKey(name: 'grants_everything')  bool grantsEverything, @JsonKey(name: 'is_system')  bool isSystem, @JsonKey(name: 'can_be_renamed')  bool canBeRenamed, @JsonKey(name: 'can_be_deleted')  bool canBeDeleted, @JsonKey(name: 'can_edit_permissions')  bool canEditPermissions,  List<PermissionOption> permissions, @JsonKey(name: 'users_count')  int? usersCount)  $default,) {final _that = this;
switch (_that) {
case _Role():
return $default(_that.id,_that.name,_that.label,_that.grantsEverything,_that.isSystem,_that.canBeRenamed,_that.canBeDeleted,_that.canEditPermissions,_that.permissions,_that.usersCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String label, @JsonKey(name: 'grants_everything')  bool grantsEverything, @JsonKey(name: 'is_system')  bool isSystem, @JsonKey(name: 'can_be_renamed')  bool canBeRenamed, @JsonKey(name: 'can_be_deleted')  bool canBeDeleted, @JsonKey(name: 'can_edit_permissions')  bool canEditPermissions,  List<PermissionOption> permissions, @JsonKey(name: 'users_count')  int? usersCount)?  $default,) {final _that = this;
switch (_that) {
case _Role() when $default != null:
return $default(_that.id,_that.name,_that.label,_that.grantsEverything,_that.isSystem,_that.canBeRenamed,_that.canBeDeleted,_that.canEditPermissions,_that.permissions,_that.usersCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Role extends Role {
  const _Role({required this.id, required this.name, required this.label, @JsonKey(name: 'grants_everything') this.grantsEverything = false, @JsonKey(name: 'is_system') this.isSystem = false, @JsonKey(name: 'can_be_renamed') this.canBeRenamed = true, @JsonKey(name: 'can_be_deleted') this.canBeDeleted = false, @JsonKey(name: 'can_edit_permissions') this.canEditPermissions = true, final  List<PermissionOption> permissions = const <PermissionOption>[], @JsonKey(name: 'users_count') this.usersCount}): _permissions = permissions,super._();
  factory _Role.fromJson(Map<String, dynamic> json) => _$RoleFromJson(json);

@override final  int id;
/// The machine name the gate compares against — `admin`, `accountant`. Lowercase Latin,
/// and what `PATCH /users/{id}/roles` is given.
@override final  String name;
/// Arabic, for a person. Falls back to [name] on the server for roles the code knows
/// nothing about, so this is always safe to print.
@override final  String label;
/// The administrator: its access comes from a gate rule, not from permission rows, so its
/// [permissions] list is **empty while its actual access is total**. Saying so explicitly is
/// what stops that reading as a bug on a permissions screen.
@override@JsonKey(name: 'grants_everything') final  bool grantsEverything;
/// The code references this role by name, so it cannot be deleted.
@override@JsonKey(name: 'is_system') final  bool isSystem;
@override@JsonKey(name: 'can_be_renamed') final  bool canBeRenamed;
@override@JsonKey(name: 'can_be_deleted') final  bool canBeDeleted;
@override@JsonKey(name: 'can_edit_permissions') final  bool canEditPermissions;
/// What this role grants, as `{name, label}` pairs. Empty is meaningful: a role created a
/// minute ago grants nothing, and so does the administrator — see [grantsEverything].
 final  List<PermissionOption> _permissions;
/// What this role grants, as `{name, label}` pairs. Empty is meaningful: a role created a
/// minute ago grants nothing, and so does the administrator — see [grantsEverything].
@override@JsonKey() List<PermissionOption> get permissions {
  if (_permissions is EqualUnmodifiableListView) return _permissions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_permissions);
}

/// How many people hold it. The reason a role cannot be deleted, when it cannot.
@override@JsonKey(name: 'users_count') final  int? usersCount;

/// Create a copy of Role
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoleCopyWith<_Role> get copyWith => __$RoleCopyWithImpl<_Role>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RoleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Role&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.label, label) || other.label == label)&&(identical(other.grantsEverything, grantsEverything) || other.grantsEverything == grantsEverything)&&(identical(other.isSystem, isSystem) || other.isSystem == isSystem)&&(identical(other.canBeRenamed, canBeRenamed) || other.canBeRenamed == canBeRenamed)&&(identical(other.canBeDeleted, canBeDeleted) || other.canBeDeleted == canBeDeleted)&&(identical(other.canEditPermissions, canEditPermissions) || other.canEditPermissions == canEditPermissions)&&const DeepCollectionEquality().equals(other._permissions, _permissions)&&(identical(other.usersCount, usersCount) || other.usersCount == usersCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,label,grantsEverything,isSystem,canBeRenamed,canBeDeleted,canEditPermissions,const DeepCollectionEquality().hash(_permissions),usersCount);

@override
String toString() {
  return 'Role(id: $id, name: $name, label: $label, grantsEverything: $grantsEverything, isSystem: $isSystem, canBeRenamed: $canBeRenamed, canBeDeleted: $canBeDeleted, canEditPermissions: $canEditPermissions, permissions: $permissions, usersCount: $usersCount)';
}


}

/// @nodoc
abstract mixin class _$RoleCopyWith<$Res> implements $RoleCopyWith<$Res> {
  factory _$RoleCopyWith(_Role value, $Res Function(_Role) _then) = __$RoleCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String label,@JsonKey(name: 'grants_everything') bool grantsEverything,@JsonKey(name: 'is_system') bool isSystem,@JsonKey(name: 'can_be_renamed') bool canBeRenamed,@JsonKey(name: 'can_be_deleted') bool canBeDeleted,@JsonKey(name: 'can_edit_permissions') bool canEditPermissions, List<PermissionOption> permissions,@JsonKey(name: 'users_count') int? usersCount
});




}
/// @nodoc
class __$RoleCopyWithImpl<$Res>
    implements _$RoleCopyWith<$Res> {
  __$RoleCopyWithImpl(this._self, this._then);

  final _Role _self;
  final $Res Function(_Role) _then;

/// Create a copy of Role
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? label = null,Object? grantsEverything = null,Object? isSystem = null,Object? canBeRenamed = null,Object? canBeDeleted = null,Object? canEditPermissions = null,Object? permissions = null,Object? usersCount = freezed,}) {
  return _then(_Role(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,grantsEverything: null == grantsEverything ? _self.grantsEverything : grantsEverything // ignore: cast_nullable_to_non_nullable
as bool,isSystem: null == isSystem ? _self.isSystem : isSystem // ignore: cast_nullable_to_non_nullable
as bool,canBeRenamed: null == canBeRenamed ? _self.canBeRenamed : canBeRenamed // ignore: cast_nullable_to_non_nullable
as bool,canBeDeleted: null == canBeDeleted ? _self.canBeDeleted : canBeDeleted // ignore: cast_nullable_to_non_nullable
as bool,canEditPermissions: null == canEditPermissions ? _self.canEditPermissions : canEditPermissions // ignore: cast_nullable_to_non_nullable
as bool,permissions: null == permissions ? _self._permissions : permissions // ignore: cast_nullable_to_non_nullable
as List<PermissionOption>,usersCount: freezed == usersCount ? _self.usersCount : usersCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$PermissionOption {

/// Exactly the string a route's `can:` middleware names.
 String get name;/// Sent by the server so the app keeps no translation table of its own.
 String get label;
/// Create a copy of PermissionOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PermissionOptionCopyWith<PermissionOption> get copyWith => _$PermissionOptionCopyWithImpl<PermissionOption>(this as PermissionOption, _$identity);

  /// Serializes this PermissionOption to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PermissionOption&&(identical(other.name, name) || other.name == name)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,label);

@override
String toString() {
  return 'PermissionOption(name: $name, label: $label)';
}


}

/// @nodoc
abstract mixin class $PermissionOptionCopyWith<$Res>  {
  factory $PermissionOptionCopyWith(PermissionOption value, $Res Function(PermissionOption) _then) = _$PermissionOptionCopyWithImpl;
@useResult
$Res call({
 String name, String label
});




}
/// @nodoc
class _$PermissionOptionCopyWithImpl<$Res>
    implements $PermissionOptionCopyWith<$Res> {
  _$PermissionOptionCopyWithImpl(this._self, this._then);

  final PermissionOption _self;
  final $Res Function(PermissionOption) _then;

/// Create a copy of PermissionOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? label = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PermissionOption].
extension PermissionOptionPatterns on PermissionOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PermissionOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PermissionOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PermissionOption value)  $default,){
final _that = this;
switch (_that) {
case _PermissionOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PermissionOption value)?  $default,){
final _that = this;
switch (_that) {
case _PermissionOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String label)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PermissionOption() when $default != null:
return $default(_that.name,_that.label);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String label)  $default,) {final _that = this;
switch (_that) {
case _PermissionOption():
return $default(_that.name,_that.label);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String label)?  $default,) {final _that = this;
switch (_that) {
case _PermissionOption() when $default != null:
return $default(_that.name,_that.label);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PermissionOption implements PermissionOption {
  const _PermissionOption({required this.name, required this.label});
  factory _PermissionOption.fromJson(Map<String, dynamic> json) => _$PermissionOptionFromJson(json);

/// Exactly the string a route's `can:` middleware names.
@override final  String name;
/// Sent by the server so the app keeps no translation table of its own.
@override final  String label;

/// Create a copy of PermissionOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PermissionOptionCopyWith<_PermissionOption> get copyWith => __$PermissionOptionCopyWithImpl<_PermissionOption>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PermissionOptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PermissionOption&&(identical(other.name, name) || other.name == name)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,label);

@override
String toString() {
  return 'PermissionOption(name: $name, label: $label)';
}


}

/// @nodoc
abstract mixin class _$PermissionOptionCopyWith<$Res> implements $PermissionOptionCopyWith<$Res> {
  factory _$PermissionOptionCopyWith(_PermissionOption value, $Res Function(_PermissionOption) _then) = __$PermissionOptionCopyWithImpl;
@override @useResult
$Res call({
 String name, String label
});




}
/// @nodoc
class __$PermissionOptionCopyWithImpl<$Res>
    implements _$PermissionOptionCopyWith<$Res> {
  __$PermissionOptionCopyWithImpl(this._self, this._then);

  final _PermissionOption _self;
  final $Res Function(_PermissionOption) _then;

/// Create a copy of PermissionOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? label = null,}) {
  return _then(_PermissionOption(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PermissionGroup {

/// The section heading, in Arabic.
@JsonKey(name: 'group') String get title; List<PermissionOption> get permissions;
/// Create a copy of PermissionGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PermissionGroupCopyWith<PermissionGroup> get copyWith => _$PermissionGroupCopyWithImpl<PermissionGroup>(this as PermissionGroup, _$identity);

  /// Serializes this PermissionGroup to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PermissionGroup&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other.permissions, permissions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,const DeepCollectionEquality().hash(permissions));

@override
String toString() {
  return 'PermissionGroup(title: $title, permissions: $permissions)';
}


}

/// @nodoc
abstract mixin class $PermissionGroupCopyWith<$Res>  {
  factory $PermissionGroupCopyWith(PermissionGroup value, $Res Function(PermissionGroup) _then) = _$PermissionGroupCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'group') String title, List<PermissionOption> permissions
});




}
/// @nodoc
class _$PermissionGroupCopyWithImpl<$Res>
    implements $PermissionGroupCopyWith<$Res> {
  _$PermissionGroupCopyWithImpl(this._self, this._then);

  final PermissionGroup _self;
  final $Res Function(PermissionGroup) _then;

/// Create a copy of PermissionGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? permissions = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,permissions: null == permissions ? _self.permissions : permissions // ignore: cast_nullable_to_non_nullable
as List<PermissionOption>,
  ));
}

}


/// Adds pattern-matching-related methods to [PermissionGroup].
extension PermissionGroupPatterns on PermissionGroup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PermissionGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PermissionGroup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PermissionGroup value)  $default,){
final _that = this;
switch (_that) {
case _PermissionGroup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PermissionGroup value)?  $default,){
final _that = this;
switch (_that) {
case _PermissionGroup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'group')  String title,  List<PermissionOption> permissions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PermissionGroup() when $default != null:
return $default(_that.title,_that.permissions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'group')  String title,  List<PermissionOption> permissions)  $default,) {final _that = this;
switch (_that) {
case _PermissionGroup():
return $default(_that.title,_that.permissions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'group')  String title,  List<PermissionOption> permissions)?  $default,) {final _that = this;
switch (_that) {
case _PermissionGroup() when $default != null:
return $default(_that.title,_that.permissions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PermissionGroup extends PermissionGroup {
  const _PermissionGroup({@JsonKey(name: 'group') required this.title, required final  List<PermissionOption> permissions}): _permissions = permissions,super._();
  factory _PermissionGroup.fromJson(Map<String, dynamic> json) => _$PermissionGroupFromJson(json);

/// The section heading, in Arabic.
@override@JsonKey(name: 'group') final  String title;
 final  List<PermissionOption> _permissions;
@override List<PermissionOption> get permissions {
  if (_permissions is EqualUnmodifiableListView) return _permissions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_permissions);
}


/// Create a copy of PermissionGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PermissionGroupCopyWith<_PermissionGroup> get copyWith => __$PermissionGroupCopyWithImpl<_PermissionGroup>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PermissionGroupToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PermissionGroup&&(identical(other.title, title) || other.title == title)&&const DeepCollectionEquality().equals(other._permissions, _permissions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,const DeepCollectionEquality().hash(_permissions));

@override
String toString() {
  return 'PermissionGroup(title: $title, permissions: $permissions)';
}


}

/// @nodoc
abstract mixin class _$PermissionGroupCopyWith<$Res> implements $PermissionGroupCopyWith<$Res> {
  factory _$PermissionGroupCopyWith(_PermissionGroup value, $Res Function(_PermissionGroup) _then) = __$PermissionGroupCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'group') String title, List<PermissionOption> permissions
});




}
/// @nodoc
class __$PermissionGroupCopyWithImpl<$Res>
    implements _$PermissionGroupCopyWith<$Res> {
  __$PermissionGroupCopyWithImpl(this._self, this._then);

  final _PermissionGroup _self;
  final $Res Function(_PermissionGroup) _then;

/// Create a copy of PermissionGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? permissions = null,}) {
  return _then(_PermissionGroup(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,permissions: null == permissions ? _self._permissions : permissions // ignore: cast_nullable_to_non_nullable
as List<PermissionOption>,
  ));
}


}

// dart format on
