// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'new_product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NewProduct _$NewProductFromJson(Map<String, dynamic> json) => _NewProduct(
  slug: json['slug'] as String?,
  name: json['name'] as String,
  description: json['description'] as String?,
  features: (json['features'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  category: json['category'] as String,
  productCategoryId: (json['product_category_id'] as num).toInt(),
  pricingUnit: json['pricing_unit'] as String,
  pricingMode: json['pricing_mode'] as String,
  minOrderQuantity: json['min_order_quantity'] as String,
  variants:
      (json['variants'] as List<dynamic>?)
          ?.map((e) => NewProductVariant.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <NewProductVariant>[],
);

Map<String, dynamic> _$NewProductToJson(_NewProduct instance) =>
    <String, dynamic>{
      'slug': ?instance.slug,
      'name': instance.name,
      'description': ?instance.description,
      'features': ?instance.features,
      'category': instance.category,
      'product_category_id': instance.productCategoryId,
      'pricing_unit': instance.pricingUnit,
      'pricing_mode': instance.pricingMode,
      'min_order_quantity': instance.minOrderQuantity,
      'variants': instance.variants.map((e) => e.toJson()).toList(),
    };

_NewProductVariant _$NewProductVariantFromJson(Map<String, dynamic> json) =>
    _NewProductVariant(
      id: (json['id'] as num?)?.toInt(),
      label: json['label'] as String,
      widthCm: (json['width_cm'] as num?)?.toInt(),
      heightCm: (json['height_cm'] as num?)?.toInt(),
      priceTiers:
          (json['price_tiers'] as List<dynamic>?)
              ?.map((e) => NewPriceTier.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <NewPriceTier>[],
    );

Map<String, dynamic> _$NewProductVariantToJson(_NewProductVariant instance) =>
    <String, dynamic>{
      'id': ?instance.id,
      'label': instance.label,
      'width_cm': ?instance.widthCm,
      'height_cm': ?instance.heightCm,
      'price_tiers': instance.priceTiers.map((e) => e.toJson()).toList(),
    };

_NewPriceTier _$NewPriceTierFromJson(Map<String, dynamic> json) =>
    _NewPriceTier(
      minQuantity: json['min_quantity'] as String,
      unitPrice: json['unit_price'] as String,
    );

Map<String, dynamic> _$NewPriceTierToJson(_NewPriceTier instance) =>
    <String, dynamic>{
      'min_quantity': instance.minQuantity,
      'unit_price': instance.unitPrice,
    };
