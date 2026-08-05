// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_field.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BusinessField _$BusinessFieldFromJson(Map<String, dynamic> json) =>
    _BusinessField(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      shopsCount: (json['shops_count'] as num?)?.toInt(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$BusinessFieldToJson(_BusinessField instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'is_active': instance.isActive,
      'sort_order': instance.sortOrder,
      'shops_count': instance.shopsCount,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
