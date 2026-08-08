// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vendor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Vendor _$VendorFromJson(Map<String, dynamic> json) => _Vendor(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  contactPerson: json['contact_person'] as String?,
  phone: json['phone'] as String,
  email: json['email'] as String?,
  address: json['address'] as String?,
  isActive: json['is_active'] as bool,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$VendorToJson(_Vendor instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'contact_person': instance.contactPerson,
  'phone': instance.phone,
  'email': instance.email,
  'address': instance.address,
  'is_active': instance.isActive,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};
