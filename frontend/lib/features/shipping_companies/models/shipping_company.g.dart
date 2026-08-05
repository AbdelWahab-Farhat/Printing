// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shipping_company.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ShippingCompany _$ShippingCompanyFromJson(Map<String, dynamic> json) =>
    _ShippingCompany(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      phone: json['phone'] as String?,
      notes: json['notes'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ShippingCompanyToJson(_ShippingCompany instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phone': instance.phone,
      'notes': instance.notes,
      'is_active': instance.isActive,
      'created_at': instance.createdAt?.toIso8601String(),
    };
