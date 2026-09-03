// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Product {

 int get id;/// What a person says out loud — `P7`. The server allocates it and it never changes, so it
/// is the one thing on the card safe to read down a phone line.
 String get code; String get slug; String get name; String? get description; List<String> get features;/// «التصنيف» — the catalogue heading this product sits under. Null only for a product
/// recorded before categories existed and not edited since; the form refuses to save one.
///
/// The API sends `{id, name}` here rather than the whole row — every other field on
/// [ProductCategory] has a default, so the same model parses both shapes and the app keeps
/// one type for one idea.
@JsonKey(name: 'product_category') ProductCategory? get productCategory;@JsonKey(name: 'product_category_id') int? get productCategoryId;/// «المادة» — what this product is cut from, and **the one field that files every size of it
/// onto a shelf**.
///
/// Naming the material once is the whole feature: on every save the server walks the sizes
/// and, for each one without a shelf of its own, finds this material's «صنف مخزني» at that
/// size — creating it if the material has not reached that size yet, with the material's own
/// name and default unit. Before it existed each size had to be pointed at a pile by hand,
/// and one wrong tap split «كيس شحن 25*35» into two heaps nobody could reconcile.
///
/// Null for a product whose material nobody has named — a quote-only bag, or one whose sizes
/// come from several materials and are linked one by one. **It cannot be cleared through
/// `PUT /products`**: omitting the key leaves the current material alone, and there is
/// deliberately no way to say «none», because doing so would detach every size from its
/// shelf on that very save.
@JsonKey(name: 'stock_item_group_id') int? get stockItemGroupId;/// The material itself. `whenLoaded` on the resource, but eager-loaded on every product path
/// the API has — index, show, store, update, activation — so `null` here really does mean
/// «بلا مادة» rather than «لم يُطلب». [stockItemGroupId] is the field to trust when in doubt.
@JsonKey(name: 'stock_item_group') ProductMaterial? get stockItemGroup;@JsonKey(name: 'pricing_unit') String get pricingUnit;@JsonKey(name: 'pricing_unit_label') String get pricingUnitLabel;@JsonKey(name: 'pricing_mode') String get pricingMode;@JsonKey(name: 'pricing_mode_label') String get pricingModeLabel;/// Whether to render a price or "السعر حسب الطلب" — the server's answer, not a rule the app
/// re-derives from [pricingMode].
@JsonKey(name: 'has_listed_prices') bool get hasListedPrices;/// A decimal string like `'100.000'`: a quantity in [pricingUnit], not a count of rows.
@JsonKey(name: 'min_order_quantity') String get minOrderQuantity;@JsonKey(name: 'is_active') bool get isActive;@JsonKey(name: 'sort_order') int get sortOrder; List<ProductVariant> get variants; List<ProductImage> get images;/// When the bag entered the catalogue, and when it was last touched. Absent from nothing —
/// the API sends both on every product — but nullable because a `DateTime` this app failed
/// to parse should leave a line off a screen rather than take the whole screen down.
@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductCopyWith<Product> get copyWith => _$ProductCopyWithImpl<Product>(this as Product, _$identity);

  /// Serializes this Product to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Product&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.features, features)&&(identical(other.productCategory, productCategory) || other.productCategory == productCategory)&&(identical(other.productCategoryId, productCategoryId) || other.productCategoryId == productCategoryId)&&(identical(other.stockItemGroupId, stockItemGroupId) || other.stockItemGroupId == stockItemGroupId)&&(identical(other.stockItemGroup, stockItemGroup) || other.stockItemGroup == stockItemGroup)&&(identical(other.pricingUnit, pricingUnit) || other.pricingUnit == pricingUnit)&&(identical(other.pricingUnitLabel, pricingUnitLabel) || other.pricingUnitLabel == pricingUnitLabel)&&(identical(other.pricingMode, pricingMode) || other.pricingMode == pricingMode)&&(identical(other.pricingModeLabel, pricingModeLabel) || other.pricingModeLabel == pricingModeLabel)&&(identical(other.hasListedPrices, hasListedPrices) || other.hasListedPrices == hasListedPrices)&&(identical(other.minOrderQuantity, minOrderQuantity) || other.minOrderQuantity == minOrderQuantity)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&const DeepCollectionEquality().equals(other.variants, variants)&&const DeepCollectionEquality().equals(other.images, images)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,code,slug,name,description,const DeepCollectionEquality().hash(features),productCategory,productCategoryId,stockItemGroupId,stockItemGroup,pricingUnit,pricingUnitLabel,pricingMode,pricingModeLabel,hasListedPrices,minOrderQuantity,isActive,sortOrder,const DeepCollectionEquality().hash(variants),const DeepCollectionEquality().hash(images),createdAt,updatedAt]);

@override
String toString() {
  return 'Product(id: $id, code: $code, slug: $slug, name: $name, description: $description, features: $features, productCategory: $productCategory, productCategoryId: $productCategoryId, stockItemGroupId: $stockItemGroupId, stockItemGroup: $stockItemGroup, pricingUnit: $pricingUnit, pricingUnitLabel: $pricingUnitLabel, pricingMode: $pricingMode, pricingModeLabel: $pricingModeLabel, hasListedPrices: $hasListedPrices, minOrderQuantity: $minOrderQuantity, isActive: $isActive, sortOrder: $sortOrder, variants: $variants, images: $images, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ProductCopyWith<$Res>  {
  factory $ProductCopyWith(Product value, $Res Function(Product) _then) = _$ProductCopyWithImpl;
@useResult
$Res call({
 int id, String code, String slug, String name, String? description, List<String> features,@JsonKey(name: 'product_category') ProductCategory? productCategory,@JsonKey(name: 'product_category_id') int? productCategoryId,@JsonKey(name: 'stock_item_group_id') int? stockItemGroupId,@JsonKey(name: 'stock_item_group') ProductMaterial? stockItemGroup,@JsonKey(name: 'pricing_unit') String pricingUnit,@JsonKey(name: 'pricing_unit_label') String pricingUnitLabel,@JsonKey(name: 'pricing_mode') String pricingMode,@JsonKey(name: 'pricing_mode_label') String pricingModeLabel,@JsonKey(name: 'has_listed_prices') bool hasListedPrices,@JsonKey(name: 'min_order_quantity') String minOrderQuantity,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'sort_order') int sortOrder, List<ProductVariant> variants, List<ProductImage> images,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});


$ProductCategoryCopyWith<$Res>? get productCategory;$ProductMaterialCopyWith<$Res>? get stockItemGroup;

}
/// @nodoc
class _$ProductCopyWithImpl<$Res>
    implements $ProductCopyWith<$Res> {
  _$ProductCopyWithImpl(this._self, this._then);

  final Product _self;
  final $Res Function(Product) _then;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? slug = null,Object? name = null,Object? description = freezed,Object? features = null,Object? productCategory = freezed,Object? productCategoryId = freezed,Object? stockItemGroupId = freezed,Object? stockItemGroup = freezed,Object? pricingUnit = null,Object? pricingUnitLabel = null,Object? pricingMode = null,Object? pricingModeLabel = null,Object? hasListedPrices = null,Object? minOrderQuantity = null,Object? isActive = null,Object? sortOrder = null,Object? variants = null,Object? images = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,features: null == features ? _self.features : features // ignore: cast_nullable_to_non_nullable
as List<String>,productCategory: freezed == productCategory ? _self.productCategory : productCategory // ignore: cast_nullable_to_non_nullable
as ProductCategory?,productCategoryId: freezed == productCategoryId ? _self.productCategoryId : productCategoryId // ignore: cast_nullable_to_non_nullable
as int?,stockItemGroupId: freezed == stockItemGroupId ? _self.stockItemGroupId : stockItemGroupId // ignore: cast_nullable_to_non_nullable
as int?,stockItemGroup: freezed == stockItemGroup ? _self.stockItemGroup : stockItemGroup // ignore: cast_nullable_to_non_nullable
as ProductMaterial?,pricingUnit: null == pricingUnit ? _self.pricingUnit : pricingUnit // ignore: cast_nullable_to_non_nullable
as String,pricingUnitLabel: null == pricingUnitLabel ? _self.pricingUnitLabel : pricingUnitLabel // ignore: cast_nullable_to_non_nullable
as String,pricingMode: null == pricingMode ? _self.pricingMode : pricingMode // ignore: cast_nullable_to_non_nullable
as String,pricingModeLabel: null == pricingModeLabel ? _self.pricingModeLabel : pricingModeLabel // ignore: cast_nullable_to_non_nullable
as String,hasListedPrices: null == hasListedPrices ? _self.hasListedPrices : hasListedPrices // ignore: cast_nullable_to_non_nullable
as bool,minOrderQuantity: null == minOrderQuantity ? _self.minOrderQuantity : minOrderQuantity // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,variants: null == variants ? _self.variants : variants // ignore: cast_nullable_to_non_nullable
as List<ProductVariant>,images: null == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as List<ProductImage>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProductCategoryCopyWith<$Res>? get productCategory {
    if (_self.productCategory == null) {
    return null;
  }

  return $ProductCategoryCopyWith<$Res>(_self.productCategory!, (value) {
    return _then(_self.copyWith(productCategory: value));
  });
}/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProductMaterialCopyWith<$Res>? get stockItemGroup {
    if (_self.stockItemGroup == null) {
    return null;
  }

  return $ProductMaterialCopyWith<$Res>(_self.stockItemGroup!, (value) {
    return _then(_self.copyWith(stockItemGroup: value));
  });
}
}


/// Adds pattern-matching-related methods to [Product].
extension ProductPatterns on Product {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Product value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Product value)  $default,){
final _that = this;
switch (_that) {
case _Product():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Product value)?  $default,){
final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String code,  String slug,  String name,  String? description,  List<String> features, @JsonKey(name: 'product_category')  ProductCategory? productCategory, @JsonKey(name: 'product_category_id')  int? productCategoryId, @JsonKey(name: 'stock_item_group_id')  int? stockItemGroupId, @JsonKey(name: 'stock_item_group')  ProductMaterial? stockItemGroup, @JsonKey(name: 'pricing_unit')  String pricingUnit, @JsonKey(name: 'pricing_unit_label')  String pricingUnitLabel, @JsonKey(name: 'pricing_mode')  String pricingMode, @JsonKey(name: 'pricing_mode_label')  String pricingModeLabel, @JsonKey(name: 'has_listed_prices')  bool hasListedPrices, @JsonKey(name: 'min_order_quantity')  String minOrderQuantity, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'sort_order')  int sortOrder,  List<ProductVariant> variants,  List<ProductImage> images, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that.id,_that.code,_that.slug,_that.name,_that.description,_that.features,_that.productCategory,_that.productCategoryId,_that.stockItemGroupId,_that.stockItemGroup,_that.pricingUnit,_that.pricingUnitLabel,_that.pricingMode,_that.pricingModeLabel,_that.hasListedPrices,_that.minOrderQuantity,_that.isActive,_that.sortOrder,_that.variants,_that.images,_that.createdAt,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String code,  String slug,  String name,  String? description,  List<String> features, @JsonKey(name: 'product_category')  ProductCategory? productCategory, @JsonKey(name: 'product_category_id')  int? productCategoryId, @JsonKey(name: 'stock_item_group_id')  int? stockItemGroupId, @JsonKey(name: 'stock_item_group')  ProductMaterial? stockItemGroup, @JsonKey(name: 'pricing_unit')  String pricingUnit, @JsonKey(name: 'pricing_unit_label')  String pricingUnitLabel, @JsonKey(name: 'pricing_mode')  String pricingMode, @JsonKey(name: 'pricing_mode_label')  String pricingModeLabel, @JsonKey(name: 'has_listed_prices')  bool hasListedPrices, @JsonKey(name: 'min_order_quantity')  String minOrderQuantity, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'sort_order')  int sortOrder,  List<ProductVariant> variants,  List<ProductImage> images, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Product():
return $default(_that.id,_that.code,_that.slug,_that.name,_that.description,_that.features,_that.productCategory,_that.productCategoryId,_that.stockItemGroupId,_that.stockItemGroup,_that.pricingUnit,_that.pricingUnitLabel,_that.pricingMode,_that.pricingModeLabel,_that.hasListedPrices,_that.minOrderQuantity,_that.isActive,_that.sortOrder,_that.variants,_that.images,_that.createdAt,_that.updatedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String code,  String slug,  String name,  String? description,  List<String> features, @JsonKey(name: 'product_category')  ProductCategory? productCategory, @JsonKey(name: 'product_category_id')  int? productCategoryId, @JsonKey(name: 'stock_item_group_id')  int? stockItemGroupId, @JsonKey(name: 'stock_item_group')  ProductMaterial? stockItemGroup, @JsonKey(name: 'pricing_unit')  String pricingUnit, @JsonKey(name: 'pricing_unit_label')  String pricingUnitLabel, @JsonKey(name: 'pricing_mode')  String pricingMode, @JsonKey(name: 'pricing_mode_label')  String pricingModeLabel, @JsonKey(name: 'has_listed_prices')  bool hasListedPrices, @JsonKey(name: 'min_order_quantity')  String minOrderQuantity, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'sort_order')  int sortOrder,  List<ProductVariant> variants,  List<ProductImage> images, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that.id,_that.code,_that.slug,_that.name,_that.description,_that.features,_that.productCategory,_that.productCategoryId,_that.stockItemGroupId,_that.stockItemGroup,_that.pricingUnit,_that.pricingUnitLabel,_that.pricingMode,_that.pricingModeLabel,_that.hasListedPrices,_that.minOrderQuantity,_that.isActive,_that.sortOrder,_that.variants,_that.images,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Product extends Product {
  const _Product({required this.id, required this.code, required this.slug, required this.name, this.description, final  List<String> features = const <String>[], @JsonKey(name: 'product_category') this.productCategory, @JsonKey(name: 'product_category_id') this.productCategoryId, @JsonKey(name: 'stock_item_group_id') this.stockItemGroupId, @JsonKey(name: 'stock_item_group') this.stockItemGroup, @JsonKey(name: 'pricing_unit') required this.pricingUnit, @JsonKey(name: 'pricing_unit_label') required this.pricingUnitLabel, @JsonKey(name: 'pricing_mode') required this.pricingMode, @JsonKey(name: 'pricing_mode_label') required this.pricingModeLabel, @JsonKey(name: 'has_listed_prices') this.hasListedPrices = false, @JsonKey(name: 'min_order_quantity') required this.minOrderQuantity, @JsonKey(name: 'is_active') this.isActive = true, @JsonKey(name: 'sort_order') this.sortOrder = 0, final  List<ProductVariant> variants = const <ProductVariant>[], final  List<ProductImage> images = const <ProductImage>[], @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt}): _features = features,_variants = variants,_images = images,super._();
  factory _Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);

@override final  int id;
/// What a person says out loud — `P7`. The server allocates it and it never changes, so it
/// is the one thing on the card safe to read down a phone line.
@override final  String code;
@override final  String slug;
@override final  String name;
@override final  String? description;
 final  List<String> _features;
@override@JsonKey() List<String> get features {
  if (_features is EqualUnmodifiableListView) return _features;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_features);
}

/// «التصنيف» — the catalogue heading this product sits under. Null only for a product
/// recorded before categories existed and not edited since; the form refuses to save one.
///
/// The API sends `{id, name}` here rather than the whole row — every other field on
/// [ProductCategory] has a default, so the same model parses both shapes and the app keeps
/// one type for one idea.
@override@JsonKey(name: 'product_category') final  ProductCategory? productCategory;
@override@JsonKey(name: 'product_category_id') final  int? productCategoryId;
/// «المادة» — what this product is cut from, and **the one field that files every size of it
/// onto a shelf**.
///
/// Naming the material once is the whole feature: on every save the server walks the sizes
/// and, for each one without a shelf of its own, finds this material's «صنف مخزني» at that
/// size — creating it if the material has not reached that size yet, with the material's own
/// name and default unit. Before it existed each size had to be pointed at a pile by hand,
/// and one wrong tap split «كيس شحن 25*35» into two heaps nobody could reconcile.
///
/// Null for a product whose material nobody has named — a quote-only bag, or one whose sizes
/// come from several materials and are linked one by one. **It cannot be cleared through
/// `PUT /products`**: omitting the key leaves the current material alone, and there is
/// deliberately no way to say «none», because doing so would detach every size from its
/// shelf on that very save.
@override@JsonKey(name: 'stock_item_group_id') final  int? stockItemGroupId;
/// The material itself. `whenLoaded` on the resource, but eager-loaded on every product path
/// the API has — index, show, store, update, activation — so `null` here really does mean
/// «بلا مادة» rather than «لم يُطلب». [stockItemGroupId] is the field to trust when in doubt.
@override@JsonKey(name: 'stock_item_group') final  ProductMaterial? stockItemGroup;
@override@JsonKey(name: 'pricing_unit') final  String pricingUnit;
@override@JsonKey(name: 'pricing_unit_label') final  String pricingUnitLabel;
@override@JsonKey(name: 'pricing_mode') final  String pricingMode;
@override@JsonKey(name: 'pricing_mode_label') final  String pricingModeLabel;
/// Whether to render a price or "السعر حسب الطلب" — the server's answer, not a rule the app
/// re-derives from [pricingMode].
@override@JsonKey(name: 'has_listed_prices') final  bool hasListedPrices;
/// A decimal string like `'100.000'`: a quantity in [pricingUnit], not a count of rows.
@override@JsonKey(name: 'min_order_quantity') final  String minOrderQuantity;
@override@JsonKey(name: 'is_active') final  bool isActive;
@override@JsonKey(name: 'sort_order') final  int sortOrder;
 final  List<ProductVariant> _variants;
@override@JsonKey() List<ProductVariant> get variants {
  if (_variants is EqualUnmodifiableListView) return _variants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_variants);
}

 final  List<ProductImage> _images;
@override@JsonKey() List<ProductImage> get images {
  if (_images is EqualUnmodifiableListView) return _images;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_images);
}

/// When the bag entered the catalogue, and when it was last touched. Absent from nothing —
/// the API sends both on every product — but nullable because a `DateTime` this app failed
/// to parse should leave a line off a screen rather than take the whole screen down.
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductCopyWith<_Product> get copyWith => __$ProductCopyWithImpl<_Product>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Product&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._features, _features)&&(identical(other.productCategory, productCategory) || other.productCategory == productCategory)&&(identical(other.productCategoryId, productCategoryId) || other.productCategoryId == productCategoryId)&&(identical(other.stockItemGroupId, stockItemGroupId) || other.stockItemGroupId == stockItemGroupId)&&(identical(other.stockItemGroup, stockItemGroup) || other.stockItemGroup == stockItemGroup)&&(identical(other.pricingUnit, pricingUnit) || other.pricingUnit == pricingUnit)&&(identical(other.pricingUnitLabel, pricingUnitLabel) || other.pricingUnitLabel == pricingUnitLabel)&&(identical(other.pricingMode, pricingMode) || other.pricingMode == pricingMode)&&(identical(other.pricingModeLabel, pricingModeLabel) || other.pricingModeLabel == pricingModeLabel)&&(identical(other.hasListedPrices, hasListedPrices) || other.hasListedPrices == hasListedPrices)&&(identical(other.minOrderQuantity, minOrderQuantity) || other.minOrderQuantity == minOrderQuantity)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&const DeepCollectionEquality().equals(other._variants, _variants)&&const DeepCollectionEquality().equals(other._images, _images)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,code,slug,name,description,const DeepCollectionEquality().hash(_features),productCategory,productCategoryId,stockItemGroupId,stockItemGroup,pricingUnit,pricingUnitLabel,pricingMode,pricingModeLabel,hasListedPrices,minOrderQuantity,isActive,sortOrder,const DeepCollectionEquality().hash(_variants),const DeepCollectionEquality().hash(_images),createdAt,updatedAt]);

@override
String toString() {
  return 'Product(id: $id, code: $code, slug: $slug, name: $name, description: $description, features: $features, productCategory: $productCategory, productCategoryId: $productCategoryId, stockItemGroupId: $stockItemGroupId, stockItemGroup: $stockItemGroup, pricingUnit: $pricingUnit, pricingUnitLabel: $pricingUnitLabel, pricingMode: $pricingMode, pricingModeLabel: $pricingModeLabel, hasListedPrices: $hasListedPrices, minOrderQuantity: $minOrderQuantity, isActive: $isActive, sortOrder: $sortOrder, variants: $variants, images: $images, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ProductCopyWith<$Res> implements $ProductCopyWith<$Res> {
  factory _$ProductCopyWith(_Product value, $Res Function(_Product) _then) = __$ProductCopyWithImpl;
@override @useResult
$Res call({
 int id, String code, String slug, String name, String? description, List<String> features,@JsonKey(name: 'product_category') ProductCategory? productCategory,@JsonKey(name: 'product_category_id') int? productCategoryId,@JsonKey(name: 'stock_item_group_id') int? stockItemGroupId,@JsonKey(name: 'stock_item_group') ProductMaterial? stockItemGroup,@JsonKey(name: 'pricing_unit') String pricingUnit,@JsonKey(name: 'pricing_unit_label') String pricingUnitLabel,@JsonKey(name: 'pricing_mode') String pricingMode,@JsonKey(name: 'pricing_mode_label') String pricingModeLabel,@JsonKey(name: 'has_listed_prices') bool hasListedPrices,@JsonKey(name: 'min_order_quantity') String minOrderQuantity,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'sort_order') int sortOrder, List<ProductVariant> variants, List<ProductImage> images,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});


@override $ProductCategoryCopyWith<$Res>? get productCategory;@override $ProductMaterialCopyWith<$Res>? get stockItemGroup;

}
/// @nodoc
class __$ProductCopyWithImpl<$Res>
    implements _$ProductCopyWith<$Res> {
  __$ProductCopyWithImpl(this._self, this._then);

  final _Product _self;
  final $Res Function(_Product) _then;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? slug = null,Object? name = null,Object? description = freezed,Object? features = null,Object? productCategory = freezed,Object? productCategoryId = freezed,Object? stockItemGroupId = freezed,Object? stockItemGroup = freezed,Object? pricingUnit = null,Object? pricingUnitLabel = null,Object? pricingMode = null,Object? pricingModeLabel = null,Object? hasListedPrices = null,Object? minOrderQuantity = null,Object? isActive = null,Object? sortOrder = null,Object? variants = null,Object? images = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Product(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,features: null == features ? _self._features : features // ignore: cast_nullable_to_non_nullable
as List<String>,productCategory: freezed == productCategory ? _self.productCategory : productCategory // ignore: cast_nullable_to_non_nullable
as ProductCategory?,productCategoryId: freezed == productCategoryId ? _self.productCategoryId : productCategoryId // ignore: cast_nullable_to_non_nullable
as int?,stockItemGroupId: freezed == stockItemGroupId ? _self.stockItemGroupId : stockItemGroupId // ignore: cast_nullable_to_non_nullable
as int?,stockItemGroup: freezed == stockItemGroup ? _self.stockItemGroup : stockItemGroup // ignore: cast_nullable_to_non_nullable
as ProductMaterial?,pricingUnit: null == pricingUnit ? _self.pricingUnit : pricingUnit // ignore: cast_nullable_to_non_nullable
as String,pricingUnitLabel: null == pricingUnitLabel ? _self.pricingUnitLabel : pricingUnitLabel // ignore: cast_nullable_to_non_nullable
as String,pricingMode: null == pricingMode ? _self.pricingMode : pricingMode // ignore: cast_nullable_to_non_nullable
as String,pricingModeLabel: null == pricingModeLabel ? _self.pricingModeLabel : pricingModeLabel // ignore: cast_nullable_to_non_nullable
as String,hasListedPrices: null == hasListedPrices ? _self.hasListedPrices : hasListedPrices // ignore: cast_nullable_to_non_nullable
as bool,minOrderQuantity: null == minOrderQuantity ? _self.minOrderQuantity : minOrderQuantity // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,variants: null == variants ? _self._variants : variants // ignore: cast_nullable_to_non_nullable
as List<ProductVariant>,images: null == images ? _self._images : images // ignore: cast_nullable_to_non_nullable
as List<ProductImage>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProductCategoryCopyWith<$Res>? get productCategory {
    if (_self.productCategory == null) {
    return null;
  }

  return $ProductCategoryCopyWith<$Res>(_self.productCategory!, (value) {
    return _then(_self.copyWith(productCategory: value));
  });
}/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProductMaterialCopyWith<$Res>? get stockItemGroup {
    if (_self.stockItemGroup == null) {
    return null;
  }

  return $ProductMaterialCopyWith<$Res>(_self.stockItemGroup!, (value) {
    return _then(_self.copyWith(stockItemGroup: value));
  });
}
}


/// @nodoc
mixin _$ProductVariant {

 int get id;/// What the shop calls this size — `'25*35'`. Shown as sent, never rebuilt from the
/// dimensions, because the two are not always the same thing.
 String get label;@JsonKey(name: 'width_cm') int? get widthCm;@JsonKey(name: 'height_cm') int? get heightCm;@JsonKey(name: 'is_active') bool get isActive;@JsonKey(name: 'sort_order') int get sortOrder;/// «الصنف المخزني» this size draws from — the pile, not the size.
///
/// **Two products at one size share one of these**, and that is the point: «كيس شحن سادة
/// 25*35» and «كيس شحن مطبوع 25*35» are two catalogue rows and one heap of bags. What
/// separates them is the printing, which is a manufacturing cost rate keyed per variant, not
/// a different material.
///
/// Null for a size that is never stocked. Set by hand only as an escape hatch — a 25*35 bag
/// deliberately cut from a wider sheet — because with the product's material named the server
/// resolves it on every save.
///
/// ⚠️ **On `PUT /products` the whole variant set is replaced, so a size sent without this key
/// loses whatever it was pointed at.** See `NewProductVariant.stockItemId` for what this app
/// does about that.
@JsonKey(name: 'stock_item_id') int? get stockItemId;/// The shelf itself, for showing what a size draws on without a second request. Loaded on
/// every product-returning path, so `null` alongside a non-null [stockItemId] does not happen
/// in practice.
@JsonKey(name: 'stock_item') VariantStockItem? get stockItem;/// What this size costs us when a vendor makes it — «سعر التكلفة».
///
/// **Absent from the payload, not null, for anybody without `products.view_cost`** — so
/// `null` here means one of two things and the screen must not claim it means «بلا تكلفة».
/// Gate the row on the permission, not on the value.
///
/// A decimal string, never a `double`: it is multiplied by a quantity on the server and
/// compared against a price that is also a string.
///
/// ⚠️ **Replaced along with the rest of the size on `PUT /products`** — a size sent without
/// it is saved with none. See `NewProductVariant.costPrice`.
@JsonKey(name: 'cost_price') String? get costPrice;@JsonKey(name: 'price_tiers') List<ProductPriceTier> get priceTiers;
/// Create a copy of ProductVariant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductVariantCopyWith<ProductVariant> get copyWith => _$ProductVariantCopyWithImpl<ProductVariant>(this as ProductVariant, _$identity);

  /// Serializes this ProductVariant to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductVariant&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.widthCm, widthCm) || other.widthCm == widthCm)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.stockItemId, stockItemId) || other.stockItemId == stockItemId)&&(identical(other.stockItem, stockItem) || other.stockItem == stockItem)&&(identical(other.costPrice, costPrice) || other.costPrice == costPrice)&&const DeepCollectionEquality().equals(other.priceTiers, priceTiers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,widthCm,heightCm,isActive,sortOrder,stockItemId,stockItem,costPrice,const DeepCollectionEquality().hash(priceTiers));

@override
String toString() {
  return 'ProductVariant(id: $id, label: $label, widthCm: $widthCm, heightCm: $heightCm, isActive: $isActive, sortOrder: $sortOrder, stockItemId: $stockItemId, stockItem: $stockItem, costPrice: $costPrice, priceTiers: $priceTiers)';
}


}

/// @nodoc
abstract mixin class $ProductVariantCopyWith<$Res>  {
  factory $ProductVariantCopyWith(ProductVariant value, $Res Function(ProductVariant) _then) = _$ProductVariantCopyWithImpl;
@useResult
$Res call({
 int id, String label,@JsonKey(name: 'width_cm') int? widthCm,@JsonKey(name: 'height_cm') int? heightCm,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'sort_order') int sortOrder,@JsonKey(name: 'stock_item_id') int? stockItemId,@JsonKey(name: 'stock_item') VariantStockItem? stockItem,@JsonKey(name: 'cost_price') String? costPrice,@JsonKey(name: 'price_tiers') List<ProductPriceTier> priceTiers
});


$VariantStockItemCopyWith<$Res>? get stockItem;

}
/// @nodoc
class _$ProductVariantCopyWithImpl<$Res>
    implements $ProductVariantCopyWith<$Res> {
  _$ProductVariantCopyWithImpl(this._self, this._then);

  final ProductVariant _self;
  final $Res Function(ProductVariant) _then;

/// Create a copy of ProductVariant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? widthCm = freezed,Object? heightCm = freezed,Object? isActive = null,Object? sortOrder = null,Object? stockItemId = freezed,Object? stockItem = freezed,Object? costPrice = freezed,Object? priceTiers = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,widthCm: freezed == widthCm ? _self.widthCm : widthCm // ignore: cast_nullable_to_non_nullable
as int?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as int?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,stockItemId: freezed == stockItemId ? _self.stockItemId : stockItemId // ignore: cast_nullable_to_non_nullable
as int?,stockItem: freezed == stockItem ? _self.stockItem : stockItem // ignore: cast_nullable_to_non_nullable
as VariantStockItem?,costPrice: freezed == costPrice ? _self.costPrice : costPrice // ignore: cast_nullable_to_non_nullable
as String?,priceTiers: null == priceTiers ? _self.priceTiers : priceTiers // ignore: cast_nullable_to_non_nullable
as List<ProductPriceTier>,
  ));
}
/// Create a copy of ProductVariant
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VariantStockItemCopyWith<$Res>? get stockItem {
    if (_self.stockItem == null) {
    return null;
  }

  return $VariantStockItemCopyWith<$Res>(_self.stockItem!, (value) {
    return _then(_self.copyWith(stockItem: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProductVariant].
extension ProductVariantPatterns on ProductVariant {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductVariant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductVariant() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductVariant value)  $default,){
final _that = this;
switch (_that) {
case _ProductVariant():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductVariant value)?  $default,){
final _that = this;
switch (_that) {
case _ProductVariant() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String label, @JsonKey(name: 'width_cm')  int? widthCm, @JsonKey(name: 'height_cm')  int? heightCm, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'sort_order')  int sortOrder, @JsonKey(name: 'stock_item_id')  int? stockItemId, @JsonKey(name: 'stock_item')  VariantStockItem? stockItem, @JsonKey(name: 'cost_price')  String? costPrice, @JsonKey(name: 'price_tiers')  List<ProductPriceTier> priceTiers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductVariant() when $default != null:
return $default(_that.id,_that.label,_that.widthCm,_that.heightCm,_that.isActive,_that.sortOrder,_that.stockItemId,_that.stockItem,_that.costPrice,_that.priceTiers);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String label, @JsonKey(name: 'width_cm')  int? widthCm, @JsonKey(name: 'height_cm')  int? heightCm, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'sort_order')  int sortOrder, @JsonKey(name: 'stock_item_id')  int? stockItemId, @JsonKey(name: 'stock_item')  VariantStockItem? stockItem, @JsonKey(name: 'cost_price')  String? costPrice, @JsonKey(name: 'price_tiers')  List<ProductPriceTier> priceTiers)  $default,) {final _that = this;
switch (_that) {
case _ProductVariant():
return $default(_that.id,_that.label,_that.widthCm,_that.heightCm,_that.isActive,_that.sortOrder,_that.stockItemId,_that.stockItem,_that.costPrice,_that.priceTiers);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String label, @JsonKey(name: 'width_cm')  int? widthCm, @JsonKey(name: 'height_cm')  int? heightCm, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'sort_order')  int sortOrder, @JsonKey(name: 'stock_item_id')  int? stockItemId, @JsonKey(name: 'stock_item')  VariantStockItem? stockItem, @JsonKey(name: 'cost_price')  String? costPrice, @JsonKey(name: 'price_tiers')  List<ProductPriceTier> priceTiers)?  $default,) {final _that = this;
switch (_that) {
case _ProductVariant() when $default != null:
return $default(_that.id,_that.label,_that.widthCm,_that.heightCm,_that.isActive,_that.sortOrder,_that.stockItemId,_that.stockItem,_that.costPrice,_that.priceTiers);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductVariant extends ProductVariant {
  const _ProductVariant({required this.id, required this.label, @JsonKey(name: 'width_cm') this.widthCm, @JsonKey(name: 'height_cm') this.heightCm, @JsonKey(name: 'is_active') this.isActive = true, @JsonKey(name: 'sort_order') this.sortOrder = 0, @JsonKey(name: 'stock_item_id') this.stockItemId, @JsonKey(name: 'stock_item') this.stockItem, @JsonKey(name: 'cost_price') this.costPrice, @JsonKey(name: 'price_tiers') final  List<ProductPriceTier> priceTiers = const <ProductPriceTier>[]}): _priceTiers = priceTiers,super._();
  factory _ProductVariant.fromJson(Map<String, dynamic> json) => _$ProductVariantFromJson(json);

@override final  int id;
/// What the shop calls this size — `'25*35'`. Shown as sent, never rebuilt from the
/// dimensions, because the two are not always the same thing.
@override final  String label;
@override@JsonKey(name: 'width_cm') final  int? widthCm;
@override@JsonKey(name: 'height_cm') final  int? heightCm;
@override@JsonKey(name: 'is_active') final  bool isActive;
@override@JsonKey(name: 'sort_order') final  int sortOrder;
/// «الصنف المخزني» this size draws from — the pile, not the size.
///
/// **Two products at one size share one of these**, and that is the point: «كيس شحن سادة
/// 25*35» and «كيس شحن مطبوع 25*35» are two catalogue rows and one heap of bags. What
/// separates them is the printing, which is a manufacturing cost rate keyed per variant, not
/// a different material.
///
/// Null for a size that is never stocked. Set by hand only as an escape hatch — a 25*35 bag
/// deliberately cut from a wider sheet — because with the product's material named the server
/// resolves it on every save.
///
/// ⚠️ **On `PUT /products` the whole variant set is replaced, so a size sent without this key
/// loses whatever it was pointed at.** See `NewProductVariant.stockItemId` for what this app
/// does about that.
@override@JsonKey(name: 'stock_item_id') final  int? stockItemId;
/// The shelf itself, for showing what a size draws on without a second request. Loaded on
/// every product-returning path, so `null` alongside a non-null [stockItemId] does not happen
/// in practice.
@override@JsonKey(name: 'stock_item') final  VariantStockItem? stockItem;
/// What this size costs us when a vendor makes it — «سعر التكلفة».
///
/// **Absent from the payload, not null, for anybody without `products.view_cost`** — so
/// `null` here means one of two things and the screen must not claim it means «بلا تكلفة».
/// Gate the row on the permission, not on the value.
///
/// A decimal string, never a `double`: it is multiplied by a quantity on the server and
/// compared against a price that is also a string.
///
/// ⚠️ **Replaced along with the rest of the size on `PUT /products`** — a size sent without
/// it is saved with none. See `NewProductVariant.costPrice`.
@override@JsonKey(name: 'cost_price') final  String? costPrice;
 final  List<ProductPriceTier> _priceTiers;
@override@JsonKey(name: 'price_tiers') List<ProductPriceTier> get priceTiers {
  if (_priceTiers is EqualUnmodifiableListView) return _priceTiers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_priceTiers);
}


/// Create a copy of ProductVariant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductVariantCopyWith<_ProductVariant> get copyWith => __$ProductVariantCopyWithImpl<_ProductVariant>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductVariantToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductVariant&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.widthCm, widthCm) || other.widthCm == widthCm)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.stockItemId, stockItemId) || other.stockItemId == stockItemId)&&(identical(other.stockItem, stockItem) || other.stockItem == stockItem)&&(identical(other.costPrice, costPrice) || other.costPrice == costPrice)&&const DeepCollectionEquality().equals(other._priceTiers, _priceTiers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,widthCm,heightCm,isActive,sortOrder,stockItemId,stockItem,costPrice,const DeepCollectionEquality().hash(_priceTiers));

@override
String toString() {
  return 'ProductVariant(id: $id, label: $label, widthCm: $widthCm, heightCm: $heightCm, isActive: $isActive, sortOrder: $sortOrder, stockItemId: $stockItemId, stockItem: $stockItem, costPrice: $costPrice, priceTiers: $priceTiers)';
}


}

/// @nodoc
abstract mixin class _$ProductVariantCopyWith<$Res> implements $ProductVariantCopyWith<$Res> {
  factory _$ProductVariantCopyWith(_ProductVariant value, $Res Function(_ProductVariant) _then) = __$ProductVariantCopyWithImpl;
@override @useResult
$Res call({
 int id, String label,@JsonKey(name: 'width_cm') int? widthCm,@JsonKey(name: 'height_cm') int? heightCm,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'sort_order') int sortOrder,@JsonKey(name: 'stock_item_id') int? stockItemId,@JsonKey(name: 'stock_item') VariantStockItem? stockItem,@JsonKey(name: 'cost_price') String? costPrice,@JsonKey(name: 'price_tiers') List<ProductPriceTier> priceTiers
});


@override $VariantStockItemCopyWith<$Res>? get stockItem;

}
/// @nodoc
class __$ProductVariantCopyWithImpl<$Res>
    implements _$ProductVariantCopyWith<$Res> {
  __$ProductVariantCopyWithImpl(this._self, this._then);

  final _ProductVariant _self;
  final $Res Function(_ProductVariant) _then;

/// Create a copy of ProductVariant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? widthCm = freezed,Object? heightCm = freezed,Object? isActive = null,Object? sortOrder = null,Object? stockItemId = freezed,Object? stockItem = freezed,Object? costPrice = freezed,Object? priceTiers = null,}) {
  return _then(_ProductVariant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,widthCm: freezed == widthCm ? _self.widthCm : widthCm // ignore: cast_nullable_to_non_nullable
as int?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as int?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,stockItemId: freezed == stockItemId ? _self.stockItemId : stockItemId // ignore: cast_nullable_to_non_nullable
as int?,stockItem: freezed == stockItem ? _self.stockItem : stockItem // ignore: cast_nullable_to_non_nullable
as VariantStockItem?,costPrice: freezed == costPrice ? _self.costPrice : costPrice // ignore: cast_nullable_to_non_nullable
as String?,priceTiers: null == priceTiers ? _self._priceTiers : priceTiers // ignore: cast_nullable_to_non_nullable
as List<ProductPriceTier>,
  ));
}

/// Create a copy of ProductVariant
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VariantStockItemCopyWith<$Res>? get stockItem {
    if (_self.stockItem == null) {
    return null;
  }

  return $VariantStockItemCopyWith<$Res>(_self.stockItem!, (value) {
    return _then(_self.copyWith(stockItem: value));
  });
}
}


/// @nodoc
mixin _$ProductMaterial {

 int get id;/// `G3` — server-allocated from the id and never settable.
 String get code; String get name;/// What a size created under this material starts out counted in. Changing it on the material
/// disturbs no existing shelf; it only decides what the next one is minted with.
@JsonKey(name: 'default_unit') String get defaultUnit;/// The server's Arabic for [defaultUnit] — «قطعة», «كيلوغرام» — drawn as sent, so a unit the
/// backend grows tomorrow still reads right without this app being rebuilt.
@JsonKey(name: 'default_unit_label') String get defaultUnitLabel;
/// Create a copy of ProductMaterial
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductMaterialCopyWith<ProductMaterial> get copyWith => _$ProductMaterialCopyWithImpl<ProductMaterial>(this as ProductMaterial, _$identity);

  /// Serializes this ProductMaterial to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductMaterial&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.defaultUnit, defaultUnit) || other.defaultUnit == defaultUnit)&&(identical(other.defaultUnitLabel, defaultUnitLabel) || other.defaultUnitLabel == defaultUnitLabel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name,defaultUnit,defaultUnitLabel);

@override
String toString() {
  return 'ProductMaterial(id: $id, code: $code, name: $name, defaultUnit: $defaultUnit, defaultUnitLabel: $defaultUnitLabel)';
}


}

/// @nodoc
abstract mixin class $ProductMaterialCopyWith<$Res>  {
  factory $ProductMaterialCopyWith(ProductMaterial value, $Res Function(ProductMaterial) _then) = _$ProductMaterialCopyWithImpl;
@useResult
$Res call({
 int id, String code, String name,@JsonKey(name: 'default_unit') String defaultUnit,@JsonKey(name: 'default_unit_label') String defaultUnitLabel
});




}
/// @nodoc
class _$ProductMaterialCopyWithImpl<$Res>
    implements $ProductMaterialCopyWith<$Res> {
  _$ProductMaterialCopyWithImpl(this._self, this._then);

  final ProductMaterial _self;
  final $Res Function(ProductMaterial) _then;

/// Create a copy of ProductMaterial
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? name = null,Object? defaultUnit = null,Object? defaultUnitLabel = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,defaultUnit: null == defaultUnit ? _self.defaultUnit : defaultUnit // ignore: cast_nullable_to_non_nullable
as String,defaultUnitLabel: null == defaultUnitLabel ? _self.defaultUnitLabel : defaultUnitLabel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductMaterial].
extension ProductMaterialPatterns on ProductMaterial {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductMaterial value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductMaterial() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductMaterial value)  $default,){
final _that = this;
switch (_that) {
case _ProductMaterial():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductMaterial value)?  $default,){
final _that = this;
switch (_that) {
case _ProductMaterial() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String code,  String name, @JsonKey(name: 'default_unit')  String defaultUnit, @JsonKey(name: 'default_unit_label')  String defaultUnitLabel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductMaterial() when $default != null:
return $default(_that.id,_that.code,_that.name,_that.defaultUnit,_that.defaultUnitLabel);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String code,  String name, @JsonKey(name: 'default_unit')  String defaultUnit, @JsonKey(name: 'default_unit_label')  String defaultUnitLabel)  $default,) {final _that = this;
switch (_that) {
case _ProductMaterial():
return $default(_that.id,_that.code,_that.name,_that.defaultUnit,_that.defaultUnitLabel);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String code,  String name, @JsonKey(name: 'default_unit')  String defaultUnit, @JsonKey(name: 'default_unit_label')  String defaultUnitLabel)?  $default,) {final _that = this;
switch (_that) {
case _ProductMaterial() when $default != null:
return $default(_that.id,_that.code,_that.name,_that.defaultUnit,_that.defaultUnitLabel);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductMaterial implements ProductMaterial {
  const _ProductMaterial({required this.id, required this.code, required this.name, @JsonKey(name: 'default_unit') required this.defaultUnit, @JsonKey(name: 'default_unit_label') required this.defaultUnitLabel});
  factory _ProductMaterial.fromJson(Map<String, dynamic> json) => _$ProductMaterialFromJson(json);

@override final  int id;
/// `G3` — server-allocated from the id and never settable.
@override final  String code;
@override final  String name;
/// What a size created under this material starts out counted in. Changing it on the material
/// disturbs no existing shelf; it only decides what the next one is minted with.
@override@JsonKey(name: 'default_unit') final  String defaultUnit;
/// The server's Arabic for [defaultUnit] — «قطعة», «كيلوغرام» — drawn as sent, so a unit the
/// backend grows tomorrow still reads right without this app being rebuilt.
@override@JsonKey(name: 'default_unit_label') final  String defaultUnitLabel;

/// Create a copy of ProductMaterial
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductMaterialCopyWith<_ProductMaterial> get copyWith => __$ProductMaterialCopyWithImpl<_ProductMaterial>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductMaterialToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductMaterial&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.defaultUnit, defaultUnit) || other.defaultUnit == defaultUnit)&&(identical(other.defaultUnitLabel, defaultUnitLabel) || other.defaultUnitLabel == defaultUnitLabel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name,defaultUnit,defaultUnitLabel);

@override
String toString() {
  return 'ProductMaterial(id: $id, code: $code, name: $name, defaultUnit: $defaultUnit, defaultUnitLabel: $defaultUnitLabel)';
}


}

/// @nodoc
abstract mixin class _$ProductMaterialCopyWith<$Res> implements $ProductMaterialCopyWith<$Res> {
  factory _$ProductMaterialCopyWith(_ProductMaterial value, $Res Function(_ProductMaterial) _then) = __$ProductMaterialCopyWithImpl;
@override @useResult
$Res call({
 int id, String code, String name,@JsonKey(name: 'default_unit') String defaultUnit,@JsonKey(name: 'default_unit_label') String defaultUnitLabel
});




}
/// @nodoc
class __$ProductMaterialCopyWithImpl<$Res>
    implements _$ProductMaterialCopyWith<$Res> {
  __$ProductMaterialCopyWithImpl(this._self, this._then);

  final _ProductMaterial _self;
  final $Res Function(_ProductMaterial) _then;

/// Create a copy of ProductMaterial
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? name = null,Object? defaultUnit = null,Object? defaultUnitLabel = null,}) {
  return _then(_ProductMaterial(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,defaultUnit: null == defaultUnit ? _self.defaultUnit : defaultUnit // ignore: cast_nullable_to_non_nullable
as String,defaultUnitLabel: null == defaultUnitLabel ? _self.defaultUnitLabel : defaultUnitLabel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$VariantStockItem {

 int get id;/// `S7`. **What stands where a product thumbnail used to**: a pile is not one product's, so
/// a picture of either of the two products sharing it would be telling the storekeeper the
/// wrong thing. A code reads well on a row and is safe to say down a phone line.
 String get code;/// The material's name without the size. [displayName] is what gets drawn.
 String get name;@JsonKey(name: 'width_cm') int? get widthCm;@JsonKey(name: 'height_cm') int? get heightCm;/// «كيس شحن 25*35» — composed server-side, a bare `*` with no spaces, and **rendered as
/// sent**. The shortfall message an order is refused with quotes this exact string.
@JsonKey(name: 'display_name') String get displayName;/// What this shelf is counted in — independent of the product's `pricing_unit`, which is what
/// the customer is charged by. The two differ on anything bought by weight and sold by count.
 String get unit;@JsonKey(name: 'unit_label') String get unitLabel;
/// Create a copy of VariantStockItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VariantStockItemCopyWith<VariantStockItem> get copyWith => _$VariantStockItemCopyWithImpl<VariantStockItem>(this as VariantStockItem, _$identity);

  /// Serializes this VariantStockItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VariantStockItem&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.widthCm, widthCm) || other.widthCm == widthCm)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.unitLabel, unitLabel) || other.unitLabel == unitLabel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name,widthCm,heightCm,displayName,unit,unitLabel);

@override
String toString() {
  return 'VariantStockItem(id: $id, code: $code, name: $name, widthCm: $widthCm, heightCm: $heightCm, displayName: $displayName, unit: $unit, unitLabel: $unitLabel)';
}


}

/// @nodoc
abstract mixin class $VariantStockItemCopyWith<$Res>  {
  factory $VariantStockItemCopyWith(VariantStockItem value, $Res Function(VariantStockItem) _then) = _$VariantStockItemCopyWithImpl;
@useResult
$Res call({
 int id, String code, String name,@JsonKey(name: 'width_cm') int? widthCm,@JsonKey(name: 'height_cm') int? heightCm,@JsonKey(name: 'display_name') String displayName, String unit,@JsonKey(name: 'unit_label') String unitLabel
});




}
/// @nodoc
class _$VariantStockItemCopyWithImpl<$Res>
    implements $VariantStockItemCopyWith<$Res> {
  _$VariantStockItemCopyWithImpl(this._self, this._then);

  final VariantStockItem _self;
  final $Res Function(VariantStockItem) _then;

/// Create a copy of VariantStockItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? name = null,Object? widthCm = freezed,Object? heightCm = freezed,Object? displayName = null,Object? unit = null,Object? unitLabel = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,widthCm: freezed == widthCm ? _self.widthCm : widthCm // ignore: cast_nullable_to_non_nullable
as int?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as int?,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,unitLabel: null == unitLabel ? _self.unitLabel : unitLabel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [VariantStockItem].
extension VariantStockItemPatterns on VariantStockItem {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VariantStockItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VariantStockItem() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VariantStockItem value)  $default,){
final _that = this;
switch (_that) {
case _VariantStockItem():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VariantStockItem value)?  $default,){
final _that = this;
switch (_that) {
case _VariantStockItem() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String code,  String name, @JsonKey(name: 'width_cm')  int? widthCm, @JsonKey(name: 'height_cm')  int? heightCm, @JsonKey(name: 'display_name')  String displayName,  String unit, @JsonKey(name: 'unit_label')  String unitLabel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VariantStockItem() when $default != null:
return $default(_that.id,_that.code,_that.name,_that.widthCm,_that.heightCm,_that.displayName,_that.unit,_that.unitLabel);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String code,  String name, @JsonKey(name: 'width_cm')  int? widthCm, @JsonKey(name: 'height_cm')  int? heightCm, @JsonKey(name: 'display_name')  String displayName,  String unit, @JsonKey(name: 'unit_label')  String unitLabel)  $default,) {final _that = this;
switch (_that) {
case _VariantStockItem():
return $default(_that.id,_that.code,_that.name,_that.widthCm,_that.heightCm,_that.displayName,_that.unit,_that.unitLabel);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String code,  String name, @JsonKey(name: 'width_cm')  int? widthCm, @JsonKey(name: 'height_cm')  int? heightCm, @JsonKey(name: 'display_name')  String displayName,  String unit, @JsonKey(name: 'unit_label')  String unitLabel)?  $default,) {final _that = this;
switch (_that) {
case _VariantStockItem() when $default != null:
return $default(_that.id,_that.code,_that.name,_that.widthCm,_that.heightCm,_that.displayName,_that.unit,_that.unitLabel);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VariantStockItem implements VariantStockItem {
  const _VariantStockItem({required this.id, required this.code, required this.name, @JsonKey(name: 'width_cm') this.widthCm, @JsonKey(name: 'height_cm') this.heightCm, @JsonKey(name: 'display_name') required this.displayName, required this.unit, @JsonKey(name: 'unit_label') required this.unitLabel});
  factory _VariantStockItem.fromJson(Map<String, dynamic> json) => _$VariantStockItemFromJson(json);

@override final  int id;
/// `S7`. **What stands where a product thumbnail used to**: a pile is not one product's, so
/// a picture of either of the two products sharing it would be telling the storekeeper the
/// wrong thing. A code reads well on a row and is safe to say down a phone line.
@override final  String code;
/// The material's name without the size. [displayName] is what gets drawn.
@override final  String name;
@override@JsonKey(name: 'width_cm') final  int? widthCm;
@override@JsonKey(name: 'height_cm') final  int? heightCm;
/// «كيس شحن 25*35» — composed server-side, a bare `*` with no spaces, and **rendered as
/// sent**. The shortfall message an order is refused with quotes this exact string.
@override@JsonKey(name: 'display_name') final  String displayName;
/// What this shelf is counted in — independent of the product's `pricing_unit`, which is what
/// the customer is charged by. The two differ on anything bought by weight and sold by count.
@override final  String unit;
@override@JsonKey(name: 'unit_label') final  String unitLabel;

/// Create a copy of VariantStockItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VariantStockItemCopyWith<_VariantStockItem> get copyWith => __$VariantStockItemCopyWithImpl<_VariantStockItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VariantStockItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VariantStockItem&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.widthCm, widthCm) || other.widthCm == widthCm)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.unitLabel, unitLabel) || other.unitLabel == unitLabel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name,widthCm,heightCm,displayName,unit,unitLabel);

@override
String toString() {
  return 'VariantStockItem(id: $id, code: $code, name: $name, widthCm: $widthCm, heightCm: $heightCm, displayName: $displayName, unit: $unit, unitLabel: $unitLabel)';
}


}

/// @nodoc
abstract mixin class _$VariantStockItemCopyWith<$Res> implements $VariantStockItemCopyWith<$Res> {
  factory _$VariantStockItemCopyWith(_VariantStockItem value, $Res Function(_VariantStockItem) _then) = __$VariantStockItemCopyWithImpl;
@override @useResult
$Res call({
 int id, String code, String name,@JsonKey(name: 'width_cm') int? widthCm,@JsonKey(name: 'height_cm') int? heightCm,@JsonKey(name: 'display_name') String displayName, String unit,@JsonKey(name: 'unit_label') String unitLabel
});




}
/// @nodoc
class __$VariantStockItemCopyWithImpl<$Res>
    implements _$VariantStockItemCopyWith<$Res> {
  __$VariantStockItemCopyWithImpl(this._self, this._then);

  final _VariantStockItem _self;
  final $Res Function(_VariantStockItem) _then;

/// Create a copy of VariantStockItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? name = null,Object? widthCm = freezed,Object? heightCm = freezed,Object? displayName = null,Object? unit = null,Object? unitLabel = null,}) {
  return _then(_VariantStockItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,widthCm: freezed == widthCm ? _self.widthCm : widthCm // ignore: cast_nullable_to_non_nullable
as int?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as int?,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,unitLabel: null == unitLabel ? _self.unitLabel : unitLabel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ProductPriceTier {

 int get id;@JsonKey(name: 'min_quantity') String get minQuantity;@JsonKey(name: 'unit_price') String get unitPrice;
/// Create a copy of ProductPriceTier
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductPriceTierCopyWith<ProductPriceTier> get copyWith => _$ProductPriceTierCopyWithImpl<ProductPriceTier>(this as ProductPriceTier, _$identity);

  /// Serializes this ProductPriceTier to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductPriceTier&&(identical(other.id, id) || other.id == id)&&(identical(other.minQuantity, minQuantity) || other.minQuantity == minQuantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,minQuantity,unitPrice);

@override
String toString() {
  return 'ProductPriceTier(id: $id, minQuantity: $minQuantity, unitPrice: $unitPrice)';
}


}

/// @nodoc
abstract mixin class $ProductPriceTierCopyWith<$Res>  {
  factory $ProductPriceTierCopyWith(ProductPriceTier value, $Res Function(ProductPriceTier) _then) = _$ProductPriceTierCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'min_quantity') String minQuantity,@JsonKey(name: 'unit_price') String unitPrice
});




}
/// @nodoc
class _$ProductPriceTierCopyWithImpl<$Res>
    implements $ProductPriceTierCopyWith<$Res> {
  _$ProductPriceTierCopyWithImpl(this._self, this._then);

  final ProductPriceTier _self;
  final $Res Function(ProductPriceTier) _then;

/// Create a copy of ProductPriceTier
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? minQuantity = null,Object? unitPrice = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,minQuantity: null == minQuantity ? _self.minQuantity : minQuantity // ignore: cast_nullable_to_non_nullable
as String,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductPriceTier].
extension ProductPriceTierPatterns on ProductPriceTier {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductPriceTier value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductPriceTier() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductPriceTier value)  $default,){
final _that = this;
switch (_that) {
case _ProductPriceTier():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductPriceTier value)?  $default,){
final _that = this;
switch (_that) {
case _ProductPriceTier() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'min_quantity')  String minQuantity, @JsonKey(name: 'unit_price')  String unitPrice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductPriceTier() when $default != null:
return $default(_that.id,_that.minQuantity,_that.unitPrice);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'min_quantity')  String minQuantity, @JsonKey(name: 'unit_price')  String unitPrice)  $default,) {final _that = this;
switch (_that) {
case _ProductPriceTier():
return $default(_that.id,_that.minQuantity,_that.unitPrice);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'min_quantity')  String minQuantity, @JsonKey(name: 'unit_price')  String unitPrice)?  $default,) {final _that = this;
switch (_that) {
case _ProductPriceTier() when $default != null:
return $default(_that.id,_that.minQuantity,_that.unitPrice);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductPriceTier extends ProductPriceTier {
  const _ProductPriceTier({required this.id, @JsonKey(name: 'min_quantity') required this.minQuantity, @JsonKey(name: 'unit_price') required this.unitPrice}): super._();
  factory _ProductPriceTier.fromJson(Map<String, dynamic> json) => _$ProductPriceTierFromJson(json);

@override final  int id;
@override@JsonKey(name: 'min_quantity') final  String minQuantity;
@override@JsonKey(name: 'unit_price') final  String unitPrice;

/// Create a copy of ProductPriceTier
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductPriceTierCopyWith<_ProductPriceTier> get copyWith => __$ProductPriceTierCopyWithImpl<_ProductPriceTier>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductPriceTierToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductPriceTier&&(identical(other.id, id) || other.id == id)&&(identical(other.minQuantity, minQuantity) || other.minQuantity == minQuantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,minQuantity,unitPrice);

@override
String toString() {
  return 'ProductPriceTier(id: $id, minQuantity: $minQuantity, unitPrice: $unitPrice)';
}


}

/// @nodoc
abstract mixin class _$ProductPriceTierCopyWith<$Res> implements $ProductPriceTierCopyWith<$Res> {
  factory _$ProductPriceTierCopyWith(_ProductPriceTier value, $Res Function(_ProductPriceTier) _then) = __$ProductPriceTierCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'min_quantity') String minQuantity,@JsonKey(name: 'unit_price') String unitPrice
});




}
/// @nodoc
class __$ProductPriceTierCopyWithImpl<$Res>
    implements _$ProductPriceTierCopyWith<$Res> {
  __$ProductPriceTierCopyWithImpl(this._self, this._then);

  final _ProductPriceTier _self;
  final $Res Function(_ProductPriceTier) _then;

/// Create a copy of ProductPriceTier
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? minQuantity = null,Object? unitPrice = null,}) {
  return _then(_ProductPriceTier(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,minQuantity: null == minQuantity ? _self.minQuantity : minQuantity // ignore: cast_nullable_to_non_nullable
as String,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ProductImage {

 int get id; String get url;@JsonKey(name: 'alt_text') String? get altText;@JsonKey(name: 'is_primary') bool get isPrimary;@JsonKey(name: 'sort_order') int get sortOrder;/// What the file actually is. The API has sent these since the media layer landed; nothing
/// read them until a screen existed with room to say what it is showing.
@JsonKey(name: 'mime_type') String? get mimeType;@JsonKey(name: 'size_bytes') int? get sizeBytes;@JsonKey(name: 'width_px') int? get widthPx;@JsonKey(name: 'height_px') int? get heightPx;
/// Create a copy of ProductImage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductImageCopyWith<ProductImage> get copyWith => _$ProductImageCopyWithImpl<ProductImage>(this as ProductImage, _$identity);

  /// Serializes this ProductImage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductImage&&(identical(other.id, id) || other.id == id)&&(identical(other.url, url) || other.url == url)&&(identical(other.altText, altText) || other.altText == altText)&&(identical(other.isPrimary, isPrimary) || other.isPrimary == isPrimary)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.widthPx, widthPx) || other.widthPx == widthPx)&&(identical(other.heightPx, heightPx) || other.heightPx == heightPx));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,url,altText,isPrimary,sortOrder,mimeType,sizeBytes,widthPx,heightPx);

@override
String toString() {
  return 'ProductImage(id: $id, url: $url, altText: $altText, isPrimary: $isPrimary, sortOrder: $sortOrder, mimeType: $mimeType, sizeBytes: $sizeBytes, widthPx: $widthPx, heightPx: $heightPx)';
}


}

/// @nodoc
abstract mixin class $ProductImageCopyWith<$Res>  {
  factory $ProductImageCopyWith(ProductImage value, $Res Function(ProductImage) _then) = _$ProductImageCopyWithImpl;
@useResult
$Res call({
 int id, String url,@JsonKey(name: 'alt_text') String? altText,@JsonKey(name: 'is_primary') bool isPrimary,@JsonKey(name: 'sort_order') int sortOrder,@JsonKey(name: 'mime_type') String? mimeType,@JsonKey(name: 'size_bytes') int? sizeBytes,@JsonKey(name: 'width_px') int? widthPx,@JsonKey(name: 'height_px') int? heightPx
});




}
/// @nodoc
class _$ProductImageCopyWithImpl<$Res>
    implements $ProductImageCopyWith<$Res> {
  _$ProductImageCopyWithImpl(this._self, this._then);

  final ProductImage _self;
  final $Res Function(ProductImage) _then;

/// Create a copy of ProductImage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? url = null,Object? altText = freezed,Object? isPrimary = null,Object? sortOrder = null,Object? mimeType = freezed,Object? sizeBytes = freezed,Object? widthPx = freezed,Object? heightPx = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,altText: freezed == altText ? _self.altText : altText // ignore: cast_nullable_to_non_nullable
as String?,isPrimary: null == isPrimary ? _self.isPrimary : isPrimary // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,widthPx: freezed == widthPx ? _self.widthPx : widthPx // ignore: cast_nullable_to_non_nullable
as int?,heightPx: freezed == heightPx ? _self.heightPx : heightPx // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductImage].
extension ProductImagePatterns on ProductImage {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductImage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductImage() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductImage value)  $default,){
final _that = this;
switch (_that) {
case _ProductImage():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductImage value)?  $default,){
final _that = this;
switch (_that) {
case _ProductImage() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String url, @JsonKey(name: 'alt_text')  String? altText, @JsonKey(name: 'is_primary')  bool isPrimary, @JsonKey(name: 'sort_order')  int sortOrder, @JsonKey(name: 'mime_type')  String? mimeType, @JsonKey(name: 'size_bytes')  int? sizeBytes, @JsonKey(name: 'width_px')  int? widthPx, @JsonKey(name: 'height_px')  int? heightPx)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductImage() when $default != null:
return $default(_that.id,_that.url,_that.altText,_that.isPrimary,_that.sortOrder,_that.mimeType,_that.sizeBytes,_that.widthPx,_that.heightPx);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String url, @JsonKey(name: 'alt_text')  String? altText, @JsonKey(name: 'is_primary')  bool isPrimary, @JsonKey(name: 'sort_order')  int sortOrder, @JsonKey(name: 'mime_type')  String? mimeType, @JsonKey(name: 'size_bytes')  int? sizeBytes, @JsonKey(name: 'width_px')  int? widthPx, @JsonKey(name: 'height_px')  int? heightPx)  $default,) {final _that = this;
switch (_that) {
case _ProductImage():
return $default(_that.id,_that.url,_that.altText,_that.isPrimary,_that.sortOrder,_that.mimeType,_that.sizeBytes,_that.widthPx,_that.heightPx);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String url, @JsonKey(name: 'alt_text')  String? altText, @JsonKey(name: 'is_primary')  bool isPrimary, @JsonKey(name: 'sort_order')  int sortOrder, @JsonKey(name: 'mime_type')  String? mimeType, @JsonKey(name: 'size_bytes')  int? sizeBytes, @JsonKey(name: 'width_px')  int? widthPx, @JsonKey(name: 'height_px')  int? heightPx)?  $default,) {final _that = this;
switch (_that) {
case _ProductImage() when $default != null:
return $default(_that.id,_that.url,_that.altText,_that.isPrimary,_that.sortOrder,_that.mimeType,_that.sizeBytes,_that.widthPx,_that.heightPx);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductImage extends ProductImage {
  const _ProductImage({required this.id, required this.url, @JsonKey(name: 'alt_text') this.altText, @JsonKey(name: 'is_primary') this.isPrimary = false, @JsonKey(name: 'sort_order') this.sortOrder = 0, @JsonKey(name: 'mime_type') this.mimeType, @JsonKey(name: 'size_bytes') this.sizeBytes, @JsonKey(name: 'width_px') this.widthPx, @JsonKey(name: 'height_px') this.heightPx}): super._();
  factory _ProductImage.fromJson(Map<String, dynamic> json) => _$ProductImageFromJson(json);

@override final  int id;
@override final  String url;
@override@JsonKey(name: 'alt_text') final  String? altText;
@override@JsonKey(name: 'is_primary') final  bool isPrimary;
@override@JsonKey(name: 'sort_order') final  int sortOrder;
/// What the file actually is. The API has sent these since the media layer landed; nothing
/// read them until a screen existed with room to say what it is showing.
@override@JsonKey(name: 'mime_type') final  String? mimeType;
@override@JsonKey(name: 'size_bytes') final  int? sizeBytes;
@override@JsonKey(name: 'width_px') final  int? widthPx;
@override@JsonKey(name: 'height_px') final  int? heightPx;

/// Create a copy of ProductImage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductImageCopyWith<_ProductImage> get copyWith => __$ProductImageCopyWithImpl<_ProductImage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductImageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductImage&&(identical(other.id, id) || other.id == id)&&(identical(other.url, url) || other.url == url)&&(identical(other.altText, altText) || other.altText == altText)&&(identical(other.isPrimary, isPrimary) || other.isPrimary == isPrimary)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.widthPx, widthPx) || other.widthPx == widthPx)&&(identical(other.heightPx, heightPx) || other.heightPx == heightPx));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,url,altText,isPrimary,sortOrder,mimeType,sizeBytes,widthPx,heightPx);

@override
String toString() {
  return 'ProductImage(id: $id, url: $url, altText: $altText, isPrimary: $isPrimary, sortOrder: $sortOrder, mimeType: $mimeType, sizeBytes: $sizeBytes, widthPx: $widthPx, heightPx: $heightPx)';
}


}

/// @nodoc
abstract mixin class _$ProductImageCopyWith<$Res> implements $ProductImageCopyWith<$Res> {
  factory _$ProductImageCopyWith(_ProductImage value, $Res Function(_ProductImage) _then) = __$ProductImageCopyWithImpl;
@override @useResult
$Res call({
 int id, String url,@JsonKey(name: 'alt_text') String? altText,@JsonKey(name: 'is_primary') bool isPrimary,@JsonKey(name: 'sort_order') int sortOrder,@JsonKey(name: 'mime_type') String? mimeType,@JsonKey(name: 'size_bytes') int? sizeBytes,@JsonKey(name: 'width_px') int? widthPx,@JsonKey(name: 'height_px') int? heightPx
});




}
/// @nodoc
class __$ProductImageCopyWithImpl<$Res>
    implements _$ProductImageCopyWith<$Res> {
  __$ProductImageCopyWithImpl(this._self, this._then);

  final _ProductImage _self;
  final $Res Function(_ProductImage) _then;

/// Create a copy of ProductImage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? url = null,Object? altText = freezed,Object? isPrimary = null,Object? sortOrder = null,Object? mimeType = freezed,Object? sizeBytes = freezed,Object? widthPx = freezed,Object? heightPx = freezed,}) {
  return _then(_ProductImage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,altText: freezed == altText ? _self.altText : altText // ignore: cast_nullable_to_non_nullable
as String?,isPrimary: null == isPrimary ? _self.isPrimary : isPrimary // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,widthPx: freezed == widthPx ? _self.widthPx : widthPx // ignore: cast_nullable_to_non_nullable
as int?,heightPx: freezed == heightPx ? _self.heightPx : heightPx // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
