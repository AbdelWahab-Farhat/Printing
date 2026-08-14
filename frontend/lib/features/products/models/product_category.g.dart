// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProductCategory _$ProductCategoryFromJson(Map<String, dynamic> json) =>
    _ProductCategory(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      parentId: (json['parent_id'] as num?)?.toInt(),
      productsCount: (json['products_count'] as num?)?.toInt(),
      childrenCount: (json['children_count'] as num?)?.toInt(),
      totalProductsCount: (json['total_products_count'] as num?)?.toInt(),
      imageUrl: json['image_url'] as String?,
      imageWidthPx: (json['image_width_px'] as num?)?.toInt(),
      imageHeightPx: (json['image_height_px'] as num?)?.toInt(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$ProductCategoryToJson(_ProductCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'is_active': instance.isActive,
      'sort_order': instance.sortOrder,
      'parent_id': instance.parentId,
      'products_count': instance.productsCount,
      'children_count': instance.childrenCount,
      'total_products_count': instance.totalProductsCount,
      'image_url': instance.imageUrl,
      'image_width_px': instance.imageWidthPx,
      'image_height_px': instance.imageHeightPx,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
