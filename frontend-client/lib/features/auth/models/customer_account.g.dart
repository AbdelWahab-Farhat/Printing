// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CustomerAccount _$CustomerAccountFromJson(Map<String, dynamic> json) =>
    _CustomerAccount(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      phone: json['phone'] as String,
      code: json['code'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      shop: json['shop'] == null
          ? null
          : CustomerShop.fromJson(json['shop'] as Map<String, dynamic>),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$CustomerAccountToJson(_CustomerAccount instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phone': instance.phone,
      'code': instance.code,
      'is_active': instance.isActive,
      'shop': instance.shop?.toJson(),
      'created_at': instance.createdAt?.toIso8601String(),
    };

_CustomerShop _$CustomerShopFromJson(Map<String, dynamic> json) =>
    _CustomerShop(
      name: json['name'] as String?,
      cityName: json['city_name'] as String?,
      businessField: json['business_field'] as String?,
    );

Map<String, dynamic> _$CustomerShopToJson(_CustomerShop instance) =>
    <String, dynamic>{
      'name': instance.name,
      'city_name': instance.cityName,
      'business_field': instance.businessField,
    };

_AuthSession _$AuthSessionFromJson(Map<String, dynamic> json) => _AuthSession(
  customer: CustomerAccount.fromJson(json['customer'] as Map<String, dynamic>),
  token: json['token'] as String,
);

Map<String, dynamic> _$AuthSessionToJson(_AuthSession instance) =>
    <String, dynamic>{
      'customer': instance.customer.toJson(),
      'token': instance.token,
    };
