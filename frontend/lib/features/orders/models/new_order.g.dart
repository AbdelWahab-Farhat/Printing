// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'new_order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NewOrder _$NewOrderFromJson(Map<String, dynamic> json) => _NewOrder(
  customerId: (json['customer_id'] as num).toInt(),
  cityId: (json['city_id'] as num).toInt(),
  designSource: json['design_source'] as String,
  items: (json['items'] as List<dynamic>)
      .map((e) => NewOrderItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  customerShopId: (json['customer_shop_id'] as num?)?.toInt(),
  regionId: (json['region_id'] as num?)?.toInt(),
  designFee: json['design_fee'] as String?,
  designIds: (json['design_ids'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  discount: json['discount'] as String?,
  recipientName: json['recipient_name'] as String?,
  recipientPhone: json['recipient_phone'] as String?,
  addressDetails: json['address_details'] as String?,
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$NewOrderToJson(_NewOrder instance) => <String, dynamic>{
  'customer_id': instance.customerId,
  'city_id': instance.cityId,
  'design_source': instance.designSource,
  'items': instance.items.map((e) => e.toJson()).toList(),
  'customer_shop_id': ?instance.customerShopId,
  'region_id': ?instance.regionId,
  'design_fee': ?instance.designFee,
  'design_ids': ?instance.designIds,
  'discount': ?instance.discount,
  'recipient_name': ?instance.recipientName,
  'recipient_phone': ?instance.recipientPhone,
  'address_details': ?instance.addressDetails,
  'notes': ?instance.notes,
};

_NewOrderItem _$NewOrderItemFromJson(Map<String, dynamic> json) =>
    _NewOrderItem(
      productId: (json['product_id'] as num).toInt(),
      productVariantId: (json['product_variant_id'] as num).toInt(),
      quantity: json['quantity'] as String,
      unitPrice: json['unit_price'] as String?,
      notes: json['notes'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$NewOrderItemToJson(_NewOrderItem instance) =>
    <String, dynamic>{
      'product_id': instance.productId,
      'product_variant_id': instance.productVariantId,
      'quantity': instance.quantity,
      'unit_price': ?instance.unitPrice,
      'notes': ?instance.notes,
      'sort_order': instance.sortOrder,
    };
