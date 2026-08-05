// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'role.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Role _$RoleFromJson(Map<String, dynamic> json) => _Role(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  label: json['label'] as String,
  grantsEverything: json['grants_everything'] as bool? ?? false,
  isSystem: json['is_system'] as bool? ?? false,
  canBeRenamed: json['can_be_renamed'] as bool? ?? true,
  canBeDeleted: json['can_be_deleted'] as bool? ?? false,
  canEditPermissions: json['can_edit_permissions'] as bool? ?? true,
  permissions:
      (json['permissions'] as List<dynamic>?)
          ?.map((e) => PermissionOption.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <PermissionOption>[],
  usersCount: (json['users_count'] as num?)?.toInt(),
);

Map<String, dynamic> _$RoleToJson(_Role instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'label': instance.label,
  'grants_everything': instance.grantsEverything,
  'is_system': instance.isSystem,
  'can_be_renamed': instance.canBeRenamed,
  'can_be_deleted': instance.canBeDeleted,
  'can_edit_permissions': instance.canEditPermissions,
  'permissions': instance.permissions.map((e) => e.toJson()).toList(),
  'users_count': instance.usersCount,
};

_PermissionOption _$PermissionOptionFromJson(Map<String, dynamic> json) =>
    _PermissionOption(
      name: json['name'] as String,
      label: json['label'] as String,
    );

Map<String, dynamic> _$PermissionOptionToJson(_PermissionOption instance) =>
    <String, dynamic>{'name': instance.name, 'label': instance.label};

_PermissionGroup _$PermissionGroupFromJson(Map<String, dynamic> json) =>
    _PermissionGroup(
      title: json['group'] as String,
      permissions: (json['permissions'] as List<dynamic>)
          .map((e) => PermissionOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PermissionGroupToJson(_PermissionGroup instance) =>
    <String, dynamic>{
      'group': instance.title,
      'permissions': instance.permissions.map((e) => e.toJson()).toList(),
    };
