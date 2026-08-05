// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Product _$ProductFromJson(Map<String, dynamic> json) => _Product(
  id: (json['id'] as num).toInt(),
  code: json['code'] as String,
  slug: json['slug'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  features:
      (json['features'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  category: json['category'] as String,
  categoryLabel: json['category_label'] as String,
  pricingUnit: json['pricing_unit'] as String,
  pricingUnitLabel: json['pricing_unit_label'] as String,
  pricingMode: json['pricing_mode'] as String,
  pricingModeLabel: json['pricing_mode_label'] as String,
  hasListedPrices: json['has_listed_prices'] as bool? ?? false,
  minOrderQuantity: json['min_order_quantity'] as String,
  isActive: json['is_active'] as bool? ?? true,
  sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
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
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$ProductToJson(_Product instance) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'slug': instance.slug,
  'name': instance.name,
  'description': instance.description,
  'features': instance.features,
  'category': instance.category,
  'category_label': instance.categoryLabel,
  'pricing_unit': instance.pricingUnit,
  'pricing_unit_label': instance.pricingUnitLabel,
  'pricing_mode': instance.pricingMode,
  'pricing_mode_label': instance.pricingModeLabel,
  'has_listed_prices': instance.hasListedPrices,
  'min_order_quantity': instance.minOrderQuantity,
  'is_active': instance.isActive,
  'sort_order': instance.sortOrder,
  'variants': instance.variants.map((e) => e.toJson()).toList(),
  'images': instance.images.map((e) => e.toJson()).toList(),
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};

_ProductVariant _$ProductVariantFromJson(Map<String, dynamic> json) =>
    _ProductVariant(
      id: (json['id'] as num).toInt(),
      label: json['label'] as String,
      widthCm: (json['width_cm'] as num?)?.toInt(),
      heightCm: (json['height_cm'] as num?)?.toInt(),
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      priceTiers:
          (json['price_tiers'] as List<dynamic>?)
              ?.map((e) => ProductPriceTier.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ProductPriceTier>[],
    );

Map<String, dynamic> _$ProductVariantToJson(_ProductVariant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'width_cm': instance.widthCm,
      'height_cm': instance.heightCm,
      'is_active': instance.isActive,
      'sort_order': instance.sortOrder,
      'price_tiers': instance.priceTiers.map((e) => e.toJson()).toList(),
    };

_ProductPriceTier _$ProductPriceTierFromJson(Map<String, dynamic> json) =>
    _ProductPriceTier(
      id: (json['id'] as num).toInt(),
      minQuantity: json['min_quantity'] as String,
      unitPrice: json['unit_price'] as String,
    );

Map<String, dynamic> _$ProductPriceTierToJson(_ProductPriceTier instance) =>
    <String, dynamic>{
      'id': instance.id,
      'min_quantity': instance.minQuantity,
      'unit_price': instance.unitPrice,
    };

_ProductImage _$ProductImageFromJson(Map<String, dynamic> json) =>
    _ProductImage(
      id: (json['id'] as num).toInt(),
      url: json['url'] as String,
      altText: json['alt_text'] as String?,
      isPrimary: json['is_primary'] as bool? ?? false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      mimeType: json['mime_type'] as String?,
      sizeBytes: (json['size_bytes'] as num?)?.toInt(),
      widthPx: (json['width_px'] as num?)?.toInt(),
      heightPx: (json['height_px'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ProductImageToJson(_ProductImage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'alt_text': instance.altText,
      'is_primary': instance.isPrimary,
      'sort_order': instance.sortOrder,
      'mime_type': instance.mimeType,
      'size_bytes': instance.sizeBytes,
      'width_px': instance.widthPx,
      'height_px': instance.heightPx,
    };
