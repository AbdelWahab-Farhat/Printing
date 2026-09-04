// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_user.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AuthUser {

 int get id; String get name; String get phone; String? get email;/// The short number this employee is known by — what the home screen shows under their
/// name. Nullable because the column was added after the first accounts existed; a server
/// that predates it simply omits the key.
@JsonKey(name: 'employee_code') String? get employeeCode;/// The jobs this account holds. Empty is meaningful — a brand-new employee has none yet.
 List<UserRole> get roles;/// What the server says this account may do — the raw permission names, already expanded
/// for an administrator.
///
/// **Nullable, with no `@Default([])`, and do not "tidy that up".** `null` means "this
/// response did not say" and `[]` means "this account may do nothing"; collapsing them
/// would turn a missing eager load on the backend into something that looks like a
/// permissions problem, with every control hidden from everybody and no way to tell why.
/// RULES §3: `null` ≠ صفر.
///
/// Read through [Session], never directly — the string is compared against
/// [AppPermission.wire] there and nowhere else.
 List<String>? get permissions;/// Whether this account can still sign in.
///
/// A stopped employee stays in the list rather than disappearing, because the screen that
/// puts them back is the one that lists them. Defaulted to `true` for the responses that
/// predate the column — an account nobody stopped is an account in use.
@JsonKey(name: 'is_active') bool get isActive;/// What this employee is paid a month, as a decimal string — `'2500.00'`.
///
/// **A string, never a double**: money round-tripped through a float is how `2500.10`
/// becomes `2500.099999`. The same rule as every other amount in this app.
///
/// **Null is two different facts, and the screen tells them apart by permission.** The
/// server omits the key entirely from a reader without `users.salary` — so `null` there
/// means «you may not know», and the section is not drawn at all. For a reader who does
/// hold it, `null` means «لم يُحدَّد»: a real state for an account created before a wage
/// was agreed, and different from a wage of zero.
 String? get salary;/// Comes from the server rather than being derived from [roles] here.
///
/// An administrator's access is granted by a rule on the backend, not by permission rows,
/// so "is this person an admin" is the backend's answer to give. Re-deriving it in the app
/// would mean two places to change the day that rule moves.
@JsonKey(name: 'is_admin') bool get isAdmin;/// Whether this account belongs to an investor rather than to an employee.
///
/// **A fact about a row, not the name of a role.** The server answers it from the
/// `investors.user_id` link, so renaming the «مستثمر» role — which is ordinary data the
/// business may edit — cannot strand somebody on a screen built for staff.
///
/// It decides where the app lands after sign-in and nothing else. The boundary is
/// `can:investor_portal.view` on the route and the query behind it, which resolves the
/// account from the signed-in user and never from anything the app sends.
@JsonKey(name: 'is_investor') bool get isInvestor;
/// Create a copy of AuthUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthUserCopyWith<AuthUser> get copyWith => _$AuthUserCopyWithImpl<AuthUser>(this as AuthUser, _$identity);

  /// Serializes this AuthUser to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthUser&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.employeeCode, employeeCode) || other.employeeCode == employeeCode)&&const DeepCollectionEquality().equals(other.roles, roles)&&const DeepCollectionEquality().equals(other.permissions, permissions)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.salary, salary) || other.salary == salary)&&(identical(other.isAdmin, isAdmin) || other.isAdmin == isAdmin)&&(identical(other.isInvestor, isInvestor) || other.isInvestor == isInvestor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,phone,email,employeeCode,const DeepCollectionEquality().hash(roles),const DeepCollectionEquality().hash(permissions),isActive,salary,isAdmin,isInvestor);

@override
String toString() {
  return 'AuthUser(id: $id, name: $name, phone: $phone, email: $email, employeeCode: $employeeCode, roles: $roles, permissions: $permissions, isActive: $isActive, salary: $salary, isAdmin: $isAdmin, isInvestor: $isInvestor)';
}


}

/// @nodoc
abstract mixin class $AuthUserCopyWith<$Res>  {
  factory $AuthUserCopyWith(AuthUser value, $Res Function(AuthUser) _then) = _$AuthUserCopyWithImpl;
@useResult
$Res call({
 int id, String name, String phone, String? email,@JsonKey(name: 'employee_code') String? employeeCode, List<UserRole> roles, List<String>? permissions,@JsonKey(name: 'is_active') bool isActive, String? salary,@JsonKey(name: 'is_admin') bool isAdmin,@JsonKey(name: 'is_investor') bool isInvestor
});




}
/// @nodoc
class _$AuthUserCopyWithImpl<$Res>
    implements $AuthUserCopyWith<$Res> {
  _$AuthUserCopyWithImpl(this._self, this._then);

  final AuthUser _self;
  final $Res Function(AuthUser) _then;

/// Create a copy of AuthUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? phone = null,Object? email = freezed,Object? employeeCode = freezed,Object? roles = null,Object? permissions = freezed,Object? isActive = null,Object? salary = freezed,Object? isAdmin = null,Object? isInvestor = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,employeeCode: freezed == employeeCode ? _self.employeeCode : employeeCode // ignore: cast_nullable_to_non_nullable
as String?,roles: null == roles ? _self.roles : roles // ignore: cast_nullable_to_non_nullable
as List<UserRole>,permissions: freezed == permissions ? _self.permissions : permissions // ignore: cast_nullable_to_non_nullable
as List<String>?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,salary: freezed == salary ? _self.salary : salary // ignore: cast_nullable_to_non_nullable
as String?,isAdmin: null == isAdmin ? _self.isAdmin : isAdmin // ignore: cast_nullable_to_non_nullable
as bool,isInvestor: null == isInvestor ? _self.isInvestor : isInvestor // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthUser].
extension AuthUserPatterns on AuthUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthUser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthUser value)  $default,){
final _that = this;
switch (_that) {
case _AuthUser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthUser value)?  $default,){
final _that = this;
switch (_that) {
case _AuthUser() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String phone,  String? email, @JsonKey(name: 'employee_code')  String? employeeCode,  List<UserRole> roles,  List<String>? permissions, @JsonKey(name: 'is_active')  bool isActive,  String? salary, @JsonKey(name: 'is_admin')  bool isAdmin, @JsonKey(name: 'is_investor')  bool isInvestor)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthUser() when $default != null:
return $default(_that.id,_that.name,_that.phone,_that.email,_that.employeeCode,_that.roles,_that.permissions,_that.isActive,_that.salary,_that.isAdmin,_that.isInvestor);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String phone,  String? email, @JsonKey(name: 'employee_code')  String? employeeCode,  List<UserRole> roles,  List<String>? permissions, @JsonKey(name: 'is_active')  bool isActive,  String? salary, @JsonKey(name: 'is_admin')  bool isAdmin, @JsonKey(name: 'is_investor')  bool isInvestor)  $default,) {final _that = this;
switch (_that) {
case _AuthUser():
return $default(_that.id,_that.name,_that.phone,_that.email,_that.employeeCode,_that.roles,_that.permissions,_that.isActive,_that.salary,_that.isAdmin,_that.isInvestor);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String phone,  String? email, @JsonKey(name: 'employee_code')  String? employeeCode,  List<UserRole> roles,  List<String>? permissions, @JsonKey(name: 'is_active')  bool isActive,  String? salary, @JsonKey(name: 'is_admin')  bool isAdmin, @JsonKey(name: 'is_investor')  bool isInvestor)?  $default,) {final _that = this;
switch (_that) {
case _AuthUser() when $default != null:
return $default(_that.id,_that.name,_that.phone,_that.email,_that.employeeCode,_that.roles,_that.permissions,_that.isActive,_that.salary,_that.isAdmin,_that.isInvestor);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuthUser extends AuthUser {
  const _AuthUser({required this.id, required this.name, required this.phone, this.email, @JsonKey(name: 'employee_code') this.employeeCode, final  List<UserRole> roles = const <UserRole>[], final  List<String>? permissions, @JsonKey(name: 'is_active') this.isActive = true, this.salary, @JsonKey(name: 'is_admin') this.isAdmin = false, @JsonKey(name: 'is_investor') this.isInvestor = false}): _roles = roles,_permissions = permissions,super._();
  factory _AuthUser.fromJson(Map<String, dynamic> json) => _$AuthUserFromJson(json);

@override final  int id;
@override final  String name;
@override final  String phone;
@override final  String? email;
/// The short number this employee is known by — what the home screen shows under their
/// name. Nullable because the column was added after the first accounts existed; a server
/// that predates it simply omits the key.
@override@JsonKey(name: 'employee_code') final  String? employeeCode;
/// The jobs this account holds. Empty is meaningful — a brand-new employee has none yet.
 final  List<UserRole> _roles;
/// The jobs this account holds. Empty is meaningful — a brand-new employee has none yet.
@override@JsonKey() List<UserRole> get roles {
  if (_roles is EqualUnmodifiableListView) return _roles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_roles);
}

/// What the server says this account may do — the raw permission names, already expanded
/// for an administrator.
///
/// **Nullable, with no `@Default([])`, and do not "tidy that up".** `null` means "this
/// response did not say" and `[]` means "this account may do nothing"; collapsing them
/// would turn a missing eager load on the backend into something that looks like a
/// permissions problem, with every control hidden from everybody and no way to tell why.
/// RULES §3: `null` ≠ صفر.
///
/// Read through [Session], never directly — the string is compared against
/// [AppPermission.wire] there and nowhere else.
 final  List<String>? _permissions;
/// What the server says this account may do — the raw permission names, already expanded
/// for an administrator.
///
/// **Nullable, with no `@Default([])`, and do not "tidy that up".** `null` means "this
/// response did not say" and `[]` means "this account may do nothing"; collapsing them
/// would turn a missing eager load on the backend into something that looks like a
/// permissions problem, with every control hidden from everybody and no way to tell why.
/// RULES §3: `null` ≠ صفر.
///
/// Read through [Session], never directly — the string is compared against
/// [AppPermission.wire] there and nowhere else.
@override List<String>? get permissions {
  final value = _permissions;
  if (value == null) return null;
  if (_permissions is EqualUnmodifiableListView) return _permissions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Whether this account can still sign in.
///
/// A stopped employee stays in the list rather than disappearing, because the screen that
/// puts them back is the one that lists them. Defaulted to `true` for the responses that
/// predate the column — an account nobody stopped is an account in use.
@override@JsonKey(name: 'is_active') final  bool isActive;
/// What this employee is paid a month, as a decimal string — `'2500.00'`.
///
/// **A string, never a double**: money round-tripped through a float is how `2500.10`
/// becomes `2500.099999`. The same rule as every other amount in this app.
///
/// **Null is two different facts, and the screen tells them apart by permission.** The
/// server omits the key entirely from a reader without `users.salary` — so `null` there
/// means «you may not know», and the section is not drawn at all. For a reader who does
/// hold it, `null` means «لم يُحدَّد»: a real state for an account created before a wage
/// was agreed, and different from a wage of zero.
@override final  String? salary;
/// Comes from the server rather than being derived from [roles] here.
///
/// An administrator's access is granted by a rule on the backend, not by permission rows,
/// so "is this person an admin" is the backend's answer to give. Re-deriving it in the app
/// would mean two places to change the day that rule moves.
@override@JsonKey(name: 'is_admin') final  bool isAdmin;
/// Whether this account belongs to an investor rather than to an employee.
///
/// **A fact about a row, not the name of a role.** The server answers it from the
/// `investors.user_id` link, so renaming the «مستثمر» role — which is ordinary data the
/// business may edit — cannot strand somebody on a screen built for staff.
///
/// It decides where the app lands after sign-in and nothing else. The boundary is
/// `can:investor_portal.view` on the route and the query behind it, which resolves the
/// account from the signed-in user and never from anything the app sends.
@override@JsonKey(name: 'is_investor') final  bool isInvestor;

/// Create a copy of AuthUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthUserCopyWith<_AuthUser> get copyWith => __$AuthUserCopyWithImpl<_AuthUser>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuthUserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthUser&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.email, email) || other.email == email)&&(identical(other.employeeCode, employeeCode) || other.employeeCode == employeeCode)&&const DeepCollectionEquality().equals(other._roles, _roles)&&const DeepCollectionEquality().equals(other._permissions, _permissions)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.salary, salary) || other.salary == salary)&&(identical(other.isAdmin, isAdmin) || other.isAdmin == isAdmin)&&(identical(other.isInvestor, isInvestor) || other.isInvestor == isInvestor));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,phone,email,employeeCode,const DeepCollectionEquality().hash(_roles),const DeepCollectionEquality().hash(_permissions),isActive,salary,isAdmin,isInvestor);

@override
String toString() {
  return 'AuthUser(id: $id, name: $name, phone: $phone, email: $email, employeeCode: $employeeCode, roles: $roles, permissions: $permissions, isActive: $isActive, salary: $salary, isAdmin: $isAdmin, isInvestor: $isInvestor)';
}


}

/// @nodoc
abstract mixin class _$AuthUserCopyWith<$Res> implements $AuthUserCopyWith<$Res> {
  factory _$AuthUserCopyWith(_AuthUser value, $Res Function(_AuthUser) _then) = __$AuthUserCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String phone, String? email,@JsonKey(name: 'employee_code') String? employeeCode, List<UserRole> roles, List<String>? permissions,@JsonKey(name: 'is_active') bool isActive, String? salary,@JsonKey(name: 'is_admin') bool isAdmin,@JsonKey(name: 'is_investor') bool isInvestor
});




}
/// @nodoc
class __$AuthUserCopyWithImpl<$Res>
    implements _$AuthUserCopyWith<$Res> {
  __$AuthUserCopyWithImpl(this._self, this._then);

  final _AuthUser _self;
  final $Res Function(_AuthUser) _then;

/// Create a copy of AuthUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? phone = null,Object? email = freezed,Object? employeeCode = freezed,Object? roles = null,Object? permissions = freezed,Object? isActive = null,Object? salary = freezed,Object? isAdmin = null,Object? isInvestor = null,}) {
  return _then(_AuthUser(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,email: freezed == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String?,employeeCode: freezed == employeeCode ? _self.employeeCode : employeeCode // ignore: cast_nullable_to_non_nullable
as String?,roles: null == roles ? _self._roles : roles // ignore: cast_nullable_to_non_nullable
as List<UserRole>,permissions: freezed == permissions ? _self._permissions : permissions // ignore: cast_nullable_to_non_nullable
as List<String>?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,salary: freezed == salary ? _self.salary : salary // ignore: cast_nullable_to_non_nullable
as String?,isAdmin: null == isAdmin ? _self.isAdmin : isAdmin // ignore: cast_nullable_to_non_nullable
as bool,isInvestor: null == isInvestor ? _self.isInvestor : isInvestor // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$UserRole {

/// The machine name the backend compares against — `admin`, `accountant`.
 String get name;/// The Arabic label to show. Sent by the server so the app never keeps its own
/// translation table in step with a list the business can add to at runtime.
 String get label;
/// Create a copy of UserRole
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UserRoleCopyWith<UserRole> get copyWith => _$UserRoleCopyWithImpl<UserRole>(this as UserRole, _$identity);

  /// Serializes this UserRole to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UserRole&&(identical(other.name, name) || other.name == name)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,label);

@override
String toString() {
  return 'UserRole(name: $name, label: $label)';
}


}

/// @nodoc
abstract mixin class $UserRoleCopyWith<$Res>  {
  factory $UserRoleCopyWith(UserRole value, $Res Function(UserRole) _then) = _$UserRoleCopyWithImpl;
@useResult
$Res call({
 String name, String label
});




}
/// @nodoc
class _$UserRoleCopyWithImpl<$Res>
    implements $UserRoleCopyWith<$Res> {
  _$UserRoleCopyWithImpl(this._self, this._then);

  final UserRole _self;
  final $Res Function(UserRole) _then;

/// Create a copy of UserRole
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? label = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [UserRole].
extension UserRolePatterns on UserRole {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UserRole value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UserRole() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UserRole value)  $default,){
final _that = this;
switch (_that) {
case _UserRole():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UserRole value)?  $default,){
final _that = this;
switch (_that) {
case _UserRole() when $default != null:
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
case _UserRole() when $default != null:
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
case _UserRole():
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
case _UserRole() when $default != null:
return $default(_that.name,_that.label);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _UserRole implements UserRole {
  const _UserRole({required this.name, required this.label});
  factory _UserRole.fromJson(Map<String, dynamic> json) => _$UserRoleFromJson(json);

/// The machine name the backend compares against — `admin`, `accountant`.
@override final  String name;
/// The Arabic label to show. Sent by the server so the app never keeps its own
/// translation table in step with a list the business can add to at runtime.
@override final  String label;

/// Create a copy of UserRole
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UserRoleCopyWith<_UserRole> get copyWith => __$UserRoleCopyWithImpl<_UserRole>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UserRoleToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UserRole&&(identical(other.name, name) || other.name == name)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,name,label);

@override
String toString() {
  return 'UserRole(name: $name, label: $label)';
}


}

/// @nodoc
abstract mixin class _$UserRoleCopyWith<$Res> implements $UserRoleCopyWith<$Res> {
  factory _$UserRoleCopyWith(_UserRole value, $Res Function(_UserRole) _then) = __$UserRoleCopyWithImpl;
@override @useResult
$Res call({
 String name, String label
});




}
/// @nodoc
class __$UserRoleCopyWithImpl<$Res>
    implements _$UserRoleCopyWith<$Res> {
  __$UserRoleCopyWithImpl(this._self, this._then);

  final _UserRole _self;
  final $Res Function(_UserRole) _then;

/// Create a copy of UserRole
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? label = null,}) {
  return _then(_UserRole(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$AuthSession {

 AuthUser get user; String get token;
/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthSessionCopyWith<AuthSession> get copyWith => _$AuthSessionCopyWithImpl<AuthSession>(this as AuthSession, _$identity);

  /// Serializes this AuthSession to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthSession&&(identical(other.user, user) || other.user == user)&&(identical(other.token, token) || other.token == token));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,user,token);

@override
String toString() {
  return 'AuthSession(user: $user, token: $token)';
}


}

/// @nodoc
abstract mixin class $AuthSessionCopyWith<$Res>  {
  factory $AuthSessionCopyWith(AuthSession value, $Res Function(AuthSession) _then) = _$AuthSessionCopyWithImpl;
@useResult
$Res call({
 AuthUser user, String token
});


$AuthUserCopyWith<$Res> get user;

}
/// @nodoc
class _$AuthSessionCopyWithImpl<$Res>
    implements $AuthSessionCopyWith<$Res> {
  _$AuthSessionCopyWithImpl(this._self, this._then);

  final AuthSession _self;
  final $Res Function(AuthSession) _then;

/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? user = null,Object? token = null,}) {
  return _then(_self.copyWith(
user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as AuthUser,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthUserCopyWith<$Res> get user {
  
  return $AuthUserCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// Adds pattern-matching-related methods to [AuthSession].
extension AuthSessionPatterns on AuthSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthSession value)  $default,){
final _that = this;
switch (_that) {
case _AuthSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthSession value)?  $default,){
final _that = this;
switch (_that) {
case _AuthSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AuthUser user,  String token)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthSession() when $default != null:
return $default(_that.user,_that.token);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AuthUser user,  String token)  $default,) {final _that = this;
switch (_that) {
case _AuthSession():
return $default(_that.user,_that.token);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AuthUser user,  String token)?  $default,) {final _that = this;
switch (_that) {
case _AuthSession() when $default != null:
return $default(_that.user,_that.token);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuthSession implements AuthSession {
  const _AuthSession({required this.user, required this.token});
  factory _AuthSession.fromJson(Map<String, dynamic> json) => _$AuthSessionFromJson(json);

@override final  AuthUser user;
@override final  String token;

/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthSessionCopyWith<_AuthSession> get copyWith => __$AuthSessionCopyWithImpl<_AuthSession>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuthSessionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthSession&&(identical(other.user, user) || other.user == user)&&(identical(other.token, token) || other.token == token));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,user,token);

@override
String toString() {
  return 'AuthSession(user: $user, token: $token)';
}


}

/// @nodoc
abstract mixin class _$AuthSessionCopyWith<$Res> implements $AuthSessionCopyWith<$Res> {
  factory _$AuthSessionCopyWith(_AuthSession value, $Res Function(_AuthSession) _then) = __$AuthSessionCopyWithImpl;
@override @useResult
$Res call({
 AuthUser user, String token
});


@override $AuthUserCopyWith<$Res> get user;

}
/// @nodoc
class __$AuthSessionCopyWithImpl<$Res>
    implements _$AuthSessionCopyWith<$Res> {
  __$AuthSessionCopyWithImpl(this._self, this._then);

  final _AuthSession _self;
  final $Res Function(_AuthSession) _then;

/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? user = null,Object? token = null,}) {
  return _then(_AuthSession(
user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as AuthUser,token: null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of AuthSession
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AuthUserCopyWith<$Res> get user {
  
  return $AuthUserCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

// dart format on
