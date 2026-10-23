// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'new_customer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$NewCustomerToJson(_NewCustomer instance) =>
    <String, dynamic>{
      'name': instance.name,
      'phone': instance.phone,
      'city_id': instance.cityId,
      'region_id': instance.regionId,
      'shops': ?instance.shops?.map((e) => e.toJson()).toList(),
      'social_links': ?instance.socialLinks?.map((e) => e.toJson()).toList(),
    };

Map<String, dynamic> _$NewCustomerSocialLinkToJson(
  _NewCustomerSocialLink instance,
) => <String, dynamic>{'id': ?instance.id, 'url': instance.url};

Map<String, dynamic> _$NewCustomerShopToJson(_NewCustomerShop instance) =>
    <String, dynamic>{
      'id': ?instance.id,
      'name': instance.name,
      'city_id': instance.cityId,
      'region_id': instance.regionId,
      'page_url': ?instance.pageUrl,
      'business_field_id': instance.businessFieldId,
    };
