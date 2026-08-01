// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'new_customer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$NewCustomerToJson(_NewCustomer instance) =>
    <String, dynamic>{
      'name': instance.name,
      'phone': instance.phone,
      'shops': ?instance.shops?.map((e) => e.toJson()).toList(),
    };

Map<String, dynamic> _$NewCustomerShopToJson(_NewCustomerShop instance) =>
    <String, dynamic>{
      'id': ?instance.id,
      'name': instance.name,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'page_url': ?instance.pageUrl,
    };
