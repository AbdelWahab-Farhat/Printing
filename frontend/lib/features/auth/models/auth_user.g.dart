// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuthUser _$AuthUserFromJson(Map<String, dynamic> json) => _AuthUser(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  phone: json['phone'] as String,
  email: json['email'] as String?,
  employeeCode: json['employee_code'] as String?,
  roles:
      (json['roles'] as List<dynamic>?)
          ?.map((e) => UserRole.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <UserRole>[],
  permissions: (json['permissions'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  isActive: json['is_active'] as bool? ?? true,
  salary: json['salary'] as String?,
  isAdmin: json['is_admin'] as bool? ?? false,
);

Map<String, dynamic> _$AuthUserToJson(_AuthUser instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'phone': instance.phone,
  'email': instance.email,
  'employee_code': instance.employeeCode,
  'roles': instance.roles.map((e) => e.toJson()).toList(),
  'permissions': instance.permissions,
  'is_active': instance.isActive,
  'salary': instance.salary,
  'is_admin': instance.isAdmin,
};

_UserRole _$UserRoleFromJson(Map<String, dynamic> json) =>
    _UserRole(name: json['name'] as String, label: json['label'] as String);

Map<String, dynamic> _$UserRoleToJson(_UserRole instance) => <String, dynamic>{
  'name': instance.name,
  'label': instance.label,
};

_AuthSession _$AuthSessionFromJson(Map<String, dynamic> json) => _AuthSession(
  user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
  token: json['token'] as String,
);

Map<String, dynamic> _$AuthSessionToJson(_AuthSession instance) =>
    <String, dynamic>{'user': instance.user.toJson(), 'token': instance.token};
