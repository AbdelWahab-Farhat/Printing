// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProductCategory _$ProductCategoryFromJson(Map<String, dynamic> json) =>
    _ProductCategory(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      parentId: (json['parent_id'] as num?)?.toInt(),
      imageUrl: json['image_url'] as String?,
    );

Map<String, dynamic> _$ProductCategoryToJson(_ProductCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'parent_id': instance.parentId,
      'image_url': instance.imageUrl,
    };

_PriceTier _$PriceTierFromJson(Map<String, dynamic> json) => _PriceTier(
  id: (json['id'] as num).toInt(),
  minQuantity: json['min_quantity'] as String,
  unitPrice: json['unit_price'] as String,
);

Map<String, dynamic> _$PriceTierToJson(_PriceTier instance) =>
    <String, dynamic>{
      'id': instance.id,
      'min_quantity': instance.minQuantity,
      'unit_price': instance.unitPrice,
    };

_ProductVariant _$ProductVariantFromJson(Map<String, dynamic> json) =>
    _ProductVariant(
      id: (json['id'] as num).toInt(),
      label: json['label'] as String,
      widthCm: json['width_cm'] as num?,
      heightCm: json['height_cm'] as num?,
      priceTiers:
          (json['price_tiers'] as List<dynamic>?)
              ?.map((e) => PriceTier.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <PriceTier>[],
    );

Map<String, dynamic> _$ProductVariantToJson(_ProductVariant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'width_cm': instance.widthCm,
      'height_cm': instance.heightCm,
      'price_tiers': instance.priceTiers.map((e) => e.toJson()).toList(),
    };

_ProductImage _$ProductImageFromJson(Map<String, dynamic> json) =>
    _ProductImage(
      id: (json['id'] as num).toInt(),
      url: json['url'] as String,
      isPrimary: json['is_primary'] as bool? ?? false,
      altText: json['alt_text'] as String?,
    );

Map<String, dynamic> _$ProductImageToJson(_ProductImage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'is_primary': instance.isPrimary,
      'alt_text': instance.altText,
    };

_Product _$ProductFromJson(Map<String, dynamic> json) => _Product(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  code: json['code'] as String?,
  slug: json['slug'] as String?,
  description: json['description'] as String?,
  features:
      (json['features'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  category: json['product_category'] == null
      ? null
      : ProductCategory.fromJson(
          json['product_category'] as Map<String, dynamic>,
        ),
  categoryId: (json['product_category_id'] as num?)?.toInt(),
  pricingUnit: json['pricing_unit'] as String?,
  pricingUnitLabel: json['pricing_unit_label'] as String?,
  orderGroup: json['order_group'] as String? ?? 'shared',
  hasListedPrices: json['has_listed_prices'] as bool? ?? true,
  minOrderQuantity: json['min_order_quantity'] as String?,
  variants:
      (json['variants'] as List<dynamic>?)
          ?.map((e) => ProductVariant.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ProductVariant>[],
  images:
      (json['images'] as List<dynamic>?)
          ?.map((e) => ProductImage.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ProductImage>[],
);

Map<String, dynamic> _$ProductToJson(_Product instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'code': instance.code,
  'slug': instance.slug,
  'description': instance.description,
  'features': instance.features,
  'product_category': instance.category?.toJson(),
  'product_category_id': instance.categoryId,
  'pricing_unit': instance.pricingUnit,
  'pricing_unit_label': instance.pricingUnitLabel,
  'order_group': instance.orderGroup,
  'has_listed_prices': instance.hasListedPrices,
  'min_order_quantity': instance.minOrderQuantity,
  'variants': instance.variants.map((e) => e.toJson()).toList(),
  'images': instance.images.map((e) => e.toJson()).toList(),
};

_PriceQuote _$PriceQuoteFromJson(Map<String, dynamic> json) => _PriceQuote(
  quantity: json['quantity'] as String,
  unitPrice: json['unit_price'] as String,
  total: json['total'] as String,
  unit: json['unit'] as String?,
  unitLabel: json['unit_label'] as String?,
  appliedTierMinQuantity: json['applied_tier_min_quantity'] as String?,
  nextTier: json['next_tier'] == null
      ? null
      : NextTier.fromJson(json['next_tier'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PriceQuoteToJson(_PriceQuote instance) =>
    <String, dynamic>{
      'quantity': instance.quantity,
      'unit_price': instance.unitPrice,
      'total': instance.total,
      'unit': instance.unit,
      'unit_label': instance.unitLabel,
      'applied_tier_min_quantity': instance.appliedTierMinQuantity,
      'next_tier': instance.nextTier?.toJson(),
    };

_NextTier _$NextTierFromJson(Map<String, dynamic> json) => _NextTier(
  minQuantity: json['min_quantity'] as String,
  unitPrice: json['unit_price'] as String,
  quantityToReach: json['quantity_to_reach'] as String?,
);

Map<String, dynamic> _$NextTierToJson(_NextTier instance) => <String, dynamic>{
  'min_quantity': instance.minQuantity,
  'unit_price': instance.unitPrice,
  'quantity_to_reach': instance.quantityToReach,
};
