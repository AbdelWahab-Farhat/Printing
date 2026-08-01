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

 int get id; String get slug; String get name; String? get description; List<String> get features;/// The machine value, for logic that must switch on a category.
 String get category;/// The Arabic label for it, sent by the server so the app keeps no translation table.
@JsonKey(name: 'category_label') String get categoryLabel;@JsonKey(name: 'pricing_unit') String get pricingUnit;@JsonKey(name: 'pricing_unit_label') String get pricingUnitLabel;@JsonKey(name: 'pricing_mode') String get pricingMode;@JsonKey(name: 'pricing_mode_label') String get pricingModeLabel;/// Whether to render a price or "السعر حسب الطلب" — the server's answer, not a rule the app
/// re-derives from [pricingMode].
@JsonKey(name: 'has_listed_prices') bool get hasListedPrices;/// A decimal string like `'100.000'`: a quantity in [pricingUnit], not a count of rows.
@JsonKey(name: 'min_order_quantity') String get minOrderQuantity;@JsonKey(name: 'is_active') bool get isActive;@JsonKey(name: 'sort_order') int get sortOrder; List<ProductVariant> get variants; List<ProductImage> get images;
/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductCopyWith<Product> get copyWith => _$ProductCopyWithImpl<Product>(this as Product, _$identity);

  /// Serializes this Product to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Product&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.features, features)&&(identical(other.category, category) || other.category == category)&&(identical(other.categoryLabel, categoryLabel) || other.categoryLabel == categoryLabel)&&(identical(other.pricingUnit, pricingUnit) || other.pricingUnit == pricingUnit)&&(identical(other.pricingUnitLabel, pricingUnitLabel) || other.pricingUnitLabel == pricingUnitLabel)&&(identical(other.pricingMode, pricingMode) || other.pricingMode == pricingMode)&&(identical(other.pricingModeLabel, pricingModeLabel) || other.pricingModeLabel == pricingModeLabel)&&(identical(other.hasListedPrices, hasListedPrices) || other.hasListedPrices == hasListedPrices)&&(identical(other.minOrderQuantity, minOrderQuantity) || other.minOrderQuantity == minOrderQuantity)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&const DeepCollectionEquality().equals(other.variants, variants)&&const DeepCollectionEquality().equals(other.images, images));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,name,description,const DeepCollectionEquality().hash(features),category,categoryLabel,pricingUnit,pricingUnitLabel,pricingMode,pricingModeLabel,hasListedPrices,minOrderQuantity,isActive,sortOrder,const DeepCollectionEquality().hash(variants),const DeepCollectionEquality().hash(images));

@override
String toString() {
  return 'Product(id: $id, slug: $slug, name: $name, description: $description, features: $features, category: $category, categoryLabel: $categoryLabel, pricingUnit: $pricingUnit, pricingUnitLabel: $pricingUnitLabel, pricingMode: $pricingMode, pricingModeLabel: $pricingModeLabel, hasListedPrices: $hasListedPrices, minOrderQuantity: $minOrderQuantity, isActive: $isActive, sortOrder: $sortOrder, variants: $variants, images: $images)';
}


}

/// @nodoc
abstract mixin class $ProductCopyWith<$Res>  {
  factory $ProductCopyWith(Product value, $Res Function(Product) _then) = _$ProductCopyWithImpl;
@useResult
$Res call({
 int id, String slug, String name, String? description, List<String> features, String category,@JsonKey(name: 'category_label') String categoryLabel,@JsonKey(name: 'pricing_unit') String pricingUnit,@JsonKey(name: 'pricing_unit_label') String pricingUnitLabel,@JsonKey(name: 'pricing_mode') String pricingMode,@JsonKey(name: 'pricing_mode_label') String pricingModeLabel,@JsonKey(name: 'has_listed_prices') bool hasListedPrices,@JsonKey(name: 'min_order_quantity') String minOrderQuantity,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'sort_order') int sortOrder, List<ProductVariant> variants, List<ProductImage> images
});




}
/// @nodoc
class _$ProductCopyWithImpl<$Res>
    implements $ProductCopyWith<$Res> {
  _$ProductCopyWithImpl(this._self, this._then);

  final Product _self;
  final $Res Function(Product) _then;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? name = null,Object? description = freezed,Object? features = null,Object? category = null,Object? categoryLabel = null,Object? pricingUnit = null,Object? pricingUnitLabel = null,Object? pricingMode = null,Object? pricingModeLabel = null,Object? hasListedPrices = null,Object? minOrderQuantity = null,Object? isActive = null,Object? sortOrder = null,Object? variants = null,Object? images = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,features: null == features ? _self.features : features // ignore: cast_nullable_to_non_nullable
as List<String>,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,categoryLabel: null == categoryLabel ? _self.categoryLabel : categoryLabel // ignore: cast_nullable_to_non_nullable
as String,pricingUnit: null == pricingUnit ? _self.pricingUnit : pricingUnit // ignore: cast_nullable_to_non_nullable
as String,pricingUnitLabel: null == pricingUnitLabel ? _self.pricingUnitLabel : pricingUnitLabel // ignore: cast_nullable_to_non_nullable
as String,pricingMode: null == pricingMode ? _self.pricingMode : pricingMode // ignore: cast_nullable_to_non_nullable
as String,pricingModeLabel: null == pricingModeLabel ? _self.pricingModeLabel : pricingModeLabel // ignore: cast_nullable_to_non_nullable
as String,hasListedPrices: null == hasListedPrices ? _self.hasListedPrices : hasListedPrices // ignore: cast_nullable_to_non_nullable
as bool,minOrderQuantity: null == minOrderQuantity ? _self.minOrderQuantity : minOrderQuantity // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,variants: null == variants ? _self.variants : variants // ignore: cast_nullable_to_non_nullable
as List<ProductVariant>,images: null == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as List<ProductImage>,
  ));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String slug,  String name,  String? description,  List<String> features,  String category, @JsonKey(name: 'category_label')  String categoryLabel, @JsonKey(name: 'pricing_unit')  String pricingUnit, @JsonKey(name: 'pricing_unit_label')  String pricingUnitLabel, @JsonKey(name: 'pricing_mode')  String pricingMode, @JsonKey(name: 'pricing_mode_label')  String pricingModeLabel, @JsonKey(name: 'has_listed_prices')  bool hasListedPrices, @JsonKey(name: 'min_order_quantity')  String minOrderQuantity, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'sort_order')  int sortOrder,  List<ProductVariant> variants,  List<ProductImage> images)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that.id,_that.slug,_that.name,_that.description,_that.features,_that.category,_that.categoryLabel,_that.pricingUnit,_that.pricingUnitLabel,_that.pricingMode,_that.pricingModeLabel,_that.hasListedPrices,_that.minOrderQuantity,_that.isActive,_that.sortOrder,_that.variants,_that.images);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String slug,  String name,  String? description,  List<String> features,  String category, @JsonKey(name: 'category_label')  String categoryLabel, @JsonKey(name: 'pricing_unit')  String pricingUnit, @JsonKey(name: 'pricing_unit_label')  String pricingUnitLabel, @JsonKey(name: 'pricing_mode')  String pricingMode, @JsonKey(name: 'pricing_mode_label')  String pricingModeLabel, @JsonKey(name: 'has_listed_prices')  bool hasListedPrices, @JsonKey(name: 'min_order_quantity')  String minOrderQuantity, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'sort_order')  int sortOrder,  List<ProductVariant> variants,  List<ProductImage> images)  $default,) {final _that = this;
switch (_that) {
case _Product():
return $default(_that.id,_that.slug,_that.name,_that.description,_that.features,_that.category,_that.categoryLabel,_that.pricingUnit,_that.pricingUnitLabel,_that.pricingMode,_that.pricingModeLabel,_that.hasListedPrices,_that.minOrderQuantity,_that.isActive,_that.sortOrder,_that.variants,_that.images);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String slug,  String name,  String? description,  List<String> features,  String category, @JsonKey(name: 'category_label')  String categoryLabel, @JsonKey(name: 'pricing_unit')  String pricingUnit, @JsonKey(name: 'pricing_unit_label')  String pricingUnitLabel, @JsonKey(name: 'pricing_mode')  String pricingMode, @JsonKey(name: 'pricing_mode_label')  String pricingModeLabel, @JsonKey(name: 'has_listed_prices')  bool hasListedPrices, @JsonKey(name: 'min_order_quantity')  String minOrderQuantity, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'sort_order')  int sortOrder,  List<ProductVariant> variants,  List<ProductImage> images)?  $default,) {final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that.id,_that.slug,_that.name,_that.description,_that.features,_that.category,_that.categoryLabel,_that.pricingUnit,_that.pricingUnitLabel,_that.pricingMode,_that.pricingModeLabel,_that.hasListedPrices,_that.minOrderQuantity,_that.isActive,_that.sortOrder,_that.variants,_that.images);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Product extends Product {
  const _Product({required this.id, required this.slug, required this.name, this.description, final  List<String> features = const <String>[], required this.category, @JsonKey(name: 'category_label') required this.categoryLabel, @JsonKey(name: 'pricing_unit') required this.pricingUnit, @JsonKey(name: 'pricing_unit_label') required this.pricingUnitLabel, @JsonKey(name: 'pricing_mode') required this.pricingMode, @JsonKey(name: 'pricing_mode_label') required this.pricingModeLabel, @JsonKey(name: 'has_listed_prices') this.hasListedPrices = false, @JsonKey(name: 'min_order_quantity') required this.minOrderQuantity, @JsonKey(name: 'is_active') this.isActive = true, @JsonKey(name: 'sort_order') this.sortOrder = 0, final  List<ProductVariant> variants = const <ProductVariant>[], final  List<ProductImage> images = const <ProductImage>[]}): _features = features,_variants = variants,_images = images,super._();
  factory _Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);

@override final  int id;
@override final  String slug;
@override final  String name;
@override final  String? description;
 final  List<String> _features;
@override@JsonKey() List<String> get features {
  if (_features is EqualUnmodifiableListView) return _features;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_features);
}

/// The machine value, for logic that must switch on a category.
@override final  String category;
/// The Arabic label for it, sent by the server so the app keeps no translation table.
@override@JsonKey(name: 'category_label') final  String categoryLabel;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Product&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._features, _features)&&(identical(other.category, category) || other.category == category)&&(identical(other.categoryLabel, categoryLabel) || other.categoryLabel == categoryLabel)&&(identical(other.pricingUnit, pricingUnit) || other.pricingUnit == pricingUnit)&&(identical(other.pricingUnitLabel, pricingUnitLabel) || other.pricingUnitLabel == pricingUnitLabel)&&(identical(other.pricingMode, pricingMode) || other.pricingMode == pricingMode)&&(identical(other.pricingModeLabel, pricingModeLabel) || other.pricingModeLabel == pricingModeLabel)&&(identical(other.hasListedPrices, hasListedPrices) || other.hasListedPrices == hasListedPrices)&&(identical(other.minOrderQuantity, minOrderQuantity) || other.minOrderQuantity == minOrderQuantity)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&const DeepCollectionEquality().equals(other._variants, _variants)&&const DeepCollectionEquality().equals(other._images, _images));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,name,description,const DeepCollectionEquality().hash(_features),category,categoryLabel,pricingUnit,pricingUnitLabel,pricingMode,pricingModeLabel,hasListedPrices,minOrderQuantity,isActive,sortOrder,const DeepCollectionEquality().hash(_variants),const DeepCollectionEquality().hash(_images));

@override
String toString() {
  return 'Product(id: $id, slug: $slug, name: $name, description: $description, features: $features, category: $category, categoryLabel: $categoryLabel, pricingUnit: $pricingUnit, pricingUnitLabel: $pricingUnitLabel, pricingMode: $pricingMode, pricingModeLabel: $pricingModeLabel, hasListedPrices: $hasListedPrices, minOrderQuantity: $minOrderQuantity, isActive: $isActive, sortOrder: $sortOrder, variants: $variants, images: $images)';
}


}

/// @nodoc
abstract mixin class _$ProductCopyWith<$Res> implements $ProductCopyWith<$Res> {
  factory _$ProductCopyWith(_Product value, $Res Function(_Product) _then) = __$ProductCopyWithImpl;
@override @useResult
$Res call({
 int id, String slug, String name, String? description, List<String> features, String category,@JsonKey(name: 'category_label') String categoryLabel,@JsonKey(name: 'pricing_unit') String pricingUnit,@JsonKey(name: 'pricing_unit_label') String pricingUnitLabel,@JsonKey(name: 'pricing_mode') String pricingMode,@JsonKey(name: 'pricing_mode_label') String pricingModeLabel,@JsonKey(name: 'has_listed_prices') bool hasListedPrices,@JsonKey(name: 'min_order_quantity') String minOrderQuantity,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'sort_order') int sortOrder, List<ProductVariant> variants, List<ProductImage> images
});




}
/// @nodoc
class __$ProductCopyWithImpl<$Res>
    implements _$ProductCopyWith<$Res> {
  __$ProductCopyWithImpl(this._self, this._then);

  final _Product _self;
  final $Res Function(_Product) _then;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? name = null,Object? description = freezed,Object? features = null,Object? category = null,Object? categoryLabel = null,Object? pricingUnit = null,Object? pricingUnitLabel = null,Object? pricingMode = null,Object? pricingModeLabel = null,Object? hasListedPrices = null,Object? minOrderQuantity = null,Object? isActive = null,Object? sortOrder = null,Object? variants = null,Object? images = null,}) {
  return _then(_Product(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,features: null == features ? _self._features : features // ignore: cast_nullable_to_non_nullable
as List<String>,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,categoryLabel: null == categoryLabel ? _self.categoryLabel : categoryLabel // ignore: cast_nullable_to_non_nullable
as String,pricingUnit: null == pricingUnit ? _self.pricingUnit : pricingUnit // ignore: cast_nullable_to_non_nullable
as String,pricingUnitLabel: null == pricingUnitLabel ? _self.pricingUnitLabel : pricingUnitLabel // ignore: cast_nullable_to_non_nullable
as String,pricingMode: null == pricingMode ? _self.pricingMode : pricingMode // ignore: cast_nullable_to_non_nullable
as String,pricingModeLabel: null == pricingModeLabel ? _self.pricingModeLabel : pricingModeLabel // ignore: cast_nullable_to_non_nullable
as String,hasListedPrices: null == hasListedPrices ? _self.hasListedPrices : hasListedPrices // ignore: cast_nullable_to_non_nullable
as bool,minOrderQuantity: null == minOrderQuantity ? _self.minOrderQuantity : minOrderQuantity // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,variants: null == variants ? _self._variants : variants // ignore: cast_nullable_to_non_nullable
as List<ProductVariant>,images: null == images ? _self._images : images // ignore: cast_nullable_to_non_nullable
as List<ProductImage>,
  ));
}


}


/// @nodoc
mixin _$ProductVariant {

 int get id;/// What the shop calls this size — `'25*35'`. Shown as sent, never rebuilt from the
/// dimensions, because the two are not always the same thing.
 String get label;@JsonKey(name: 'width_cm') int? get widthCm;@JsonKey(name: 'height_cm') int? get heightCm;@JsonKey(name: 'is_active') bool get isActive;@JsonKey(name: 'sort_order') int get sortOrder;@JsonKey(name: 'price_tiers') List<ProductPriceTier> get priceTiers;
/// Create a copy of ProductVariant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductVariantCopyWith<ProductVariant> get copyWith => _$ProductVariantCopyWithImpl<ProductVariant>(this as ProductVariant, _$identity);

  /// Serializes this ProductVariant to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductVariant&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.widthCm, widthCm) || other.widthCm == widthCm)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&const DeepCollectionEquality().equals(other.priceTiers, priceTiers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,widthCm,heightCm,isActive,sortOrder,const DeepCollectionEquality().hash(priceTiers));

@override
String toString() {
  return 'ProductVariant(id: $id, label: $label, widthCm: $widthCm, heightCm: $heightCm, isActive: $isActive, sortOrder: $sortOrder, priceTiers: $priceTiers)';
}


}

/// @nodoc
abstract mixin class $ProductVariantCopyWith<$Res>  {
  factory $ProductVariantCopyWith(ProductVariant value, $Res Function(ProductVariant) _then) = _$ProductVariantCopyWithImpl;
@useResult
$Res call({
 int id, String label,@JsonKey(name: 'width_cm') int? widthCm,@JsonKey(name: 'height_cm') int? heightCm,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'sort_order') int sortOrder,@JsonKey(name: 'price_tiers') List<ProductPriceTier> priceTiers
});




}
/// @nodoc
class _$ProductVariantCopyWithImpl<$Res>
    implements $ProductVariantCopyWith<$Res> {
  _$ProductVariantCopyWithImpl(this._self, this._then);

  final ProductVariant _self;
  final $Res Function(ProductVariant) _then;

/// Create a copy of ProductVariant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? widthCm = freezed,Object? heightCm = freezed,Object? isActive = null,Object? sortOrder = null,Object? priceTiers = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,widthCm: freezed == widthCm ? _self.widthCm : widthCm // ignore: cast_nullable_to_non_nullable
as int?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as int?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,priceTiers: null == priceTiers ? _self.priceTiers : priceTiers // ignore: cast_nullable_to_non_nullable
as List<ProductPriceTier>,
  ));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String label, @JsonKey(name: 'width_cm')  int? widthCm, @JsonKey(name: 'height_cm')  int? heightCm, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'sort_order')  int sortOrder, @JsonKey(name: 'price_tiers')  List<ProductPriceTier> priceTiers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductVariant() when $default != null:
return $default(_that.id,_that.label,_that.widthCm,_that.heightCm,_that.isActive,_that.sortOrder,_that.priceTiers);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String label, @JsonKey(name: 'width_cm')  int? widthCm, @JsonKey(name: 'height_cm')  int? heightCm, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'sort_order')  int sortOrder, @JsonKey(name: 'price_tiers')  List<ProductPriceTier> priceTiers)  $default,) {final _that = this;
switch (_that) {
case _ProductVariant():
return $default(_that.id,_that.label,_that.widthCm,_that.heightCm,_that.isActive,_that.sortOrder,_that.priceTiers);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String label, @JsonKey(name: 'width_cm')  int? widthCm, @JsonKey(name: 'height_cm')  int? heightCm, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'sort_order')  int sortOrder, @JsonKey(name: 'price_tiers')  List<ProductPriceTier> priceTiers)?  $default,) {final _that = this;
switch (_that) {
case _ProductVariant() when $default != null:
return $default(_that.id,_that.label,_that.widthCm,_that.heightCm,_that.isActive,_that.sortOrder,_that.priceTiers);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductVariant extends ProductVariant {
  const _ProductVariant({required this.id, required this.label, @JsonKey(name: 'width_cm') this.widthCm, @JsonKey(name: 'height_cm') this.heightCm, @JsonKey(name: 'is_active') this.isActive = true, @JsonKey(name: 'sort_order') this.sortOrder = 0, @JsonKey(name: 'price_tiers') final  List<ProductPriceTier> priceTiers = const <ProductPriceTier>[]}): _priceTiers = priceTiers,super._();
  factory _ProductVariant.fromJson(Map<String, dynamic> json) => _$ProductVariantFromJson(json);

@override final  int id;
/// What the shop calls this size — `'25*35'`. Shown as sent, never rebuilt from the
/// dimensions, because the two are not always the same thing.
@override final  String label;
@override@JsonKey(name: 'width_cm') final  int? widthCm;
@override@JsonKey(name: 'height_cm') final  int? heightCm;
@override@JsonKey(name: 'is_active') final  bool isActive;
@override@JsonKey(name: 'sort_order') final  int sortOrder;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductVariant&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.widthCm, widthCm) || other.widthCm == widthCm)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&const DeepCollectionEquality().equals(other._priceTiers, _priceTiers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,widthCm,heightCm,isActive,sortOrder,const DeepCollectionEquality().hash(_priceTiers));

@override
String toString() {
  return 'ProductVariant(id: $id, label: $label, widthCm: $widthCm, heightCm: $heightCm, isActive: $isActive, sortOrder: $sortOrder, priceTiers: $priceTiers)';
}


}

/// @nodoc
abstract mixin class _$ProductVariantCopyWith<$Res> implements $ProductVariantCopyWith<$Res> {
  factory _$ProductVariantCopyWith(_ProductVariant value, $Res Function(_ProductVariant) _then) = __$ProductVariantCopyWithImpl;
@override @useResult
$Res call({
 int id, String label,@JsonKey(name: 'width_cm') int? widthCm,@JsonKey(name: 'height_cm') int? heightCm,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'sort_order') int sortOrder,@JsonKey(name: 'price_tiers') List<ProductPriceTier> priceTiers
});




}
/// @nodoc
class __$ProductVariantCopyWithImpl<$Res>
    implements _$ProductVariantCopyWith<$Res> {
  __$ProductVariantCopyWithImpl(this._self, this._then);

  final _ProductVariant _self;
  final $Res Function(_ProductVariant) _then;

/// Create a copy of ProductVariant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? widthCm = freezed,Object? heightCm = freezed,Object? isActive = null,Object? sortOrder = null,Object? priceTiers = null,}) {
  return _then(_ProductVariant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,widthCm: freezed == widthCm ? _self.widthCm : widthCm // ignore: cast_nullable_to_non_nullable
as int?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as int?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,priceTiers: null == priceTiers ? _self._priceTiers : priceTiers // ignore: cast_nullable_to_non_nullable
as List<ProductPriceTier>,
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

 int get id; String get url;@JsonKey(name: 'alt_text') String? get altText;@JsonKey(name: 'is_primary') bool get isPrimary;@JsonKey(name: 'sort_order') int get sortOrder;
/// Create a copy of ProductImage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductImageCopyWith<ProductImage> get copyWith => _$ProductImageCopyWithImpl<ProductImage>(this as ProductImage, _$identity);

  /// Serializes this ProductImage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductImage&&(identical(other.id, id) || other.id == id)&&(identical(other.url, url) || other.url == url)&&(identical(other.altText, altText) || other.altText == altText)&&(identical(other.isPrimary, isPrimary) || other.isPrimary == isPrimary)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,url,altText,isPrimary,sortOrder);

@override
String toString() {
  return 'ProductImage(id: $id, url: $url, altText: $altText, isPrimary: $isPrimary, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $ProductImageCopyWith<$Res>  {
  factory $ProductImageCopyWith(ProductImage value, $Res Function(ProductImage) _then) = _$ProductImageCopyWithImpl;
@useResult
$Res call({
 int id, String url,@JsonKey(name: 'alt_text') String? altText,@JsonKey(name: 'is_primary') bool isPrimary,@JsonKey(name: 'sort_order') int sortOrder
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? url = null,Object? altText = freezed,Object? isPrimary = null,Object? sortOrder = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,altText: freezed == altText ? _self.altText : altText // ignore: cast_nullable_to_non_nullable
as String?,isPrimary: null == isPrimary ? _self.isPrimary : isPrimary // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String url, @JsonKey(name: 'alt_text')  String? altText, @JsonKey(name: 'is_primary')  bool isPrimary, @JsonKey(name: 'sort_order')  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductImage() when $default != null:
return $default(_that.id,_that.url,_that.altText,_that.isPrimary,_that.sortOrder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String url, @JsonKey(name: 'alt_text')  String? altText, @JsonKey(name: 'is_primary')  bool isPrimary, @JsonKey(name: 'sort_order')  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _ProductImage():
return $default(_that.id,_that.url,_that.altText,_that.isPrimary,_that.sortOrder);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String url, @JsonKey(name: 'alt_text')  String? altText, @JsonKey(name: 'is_primary')  bool isPrimary, @JsonKey(name: 'sort_order')  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _ProductImage() when $default != null:
return $default(_that.id,_that.url,_that.altText,_that.isPrimary,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductImage implements ProductImage {
  const _ProductImage({required this.id, required this.url, @JsonKey(name: 'alt_text') this.altText, @JsonKey(name: 'is_primary') this.isPrimary = false, @JsonKey(name: 'sort_order') this.sortOrder = 0});
  factory _ProductImage.fromJson(Map<String, dynamic> json) => _$ProductImageFromJson(json);

@override final  int id;
@override final  String url;
@override@JsonKey(name: 'alt_text') final  String? altText;
@override@JsonKey(name: 'is_primary') final  bool isPrimary;
@override@JsonKey(name: 'sort_order') final  int sortOrder;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductImage&&(identical(other.id, id) || other.id == id)&&(identical(other.url, url) || other.url == url)&&(identical(other.altText, altText) || other.altText == altText)&&(identical(other.isPrimary, isPrimary) || other.isPrimary == isPrimary)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,url,altText,isPrimary,sortOrder);

@override
String toString() {
  return 'ProductImage(id: $id, url: $url, altText: $altText, isPrimary: $isPrimary, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class _$ProductImageCopyWith<$Res> implements $ProductImageCopyWith<$Res> {
  factory _$ProductImageCopyWith(_ProductImage value, $Res Function(_ProductImage) _then) = __$ProductImageCopyWithImpl;
@override @useResult
$Res call({
 int id, String url,@JsonKey(name: 'alt_text') String? altText,@JsonKey(name: 'is_primary') bool isPrimary,@JsonKey(name: 'sort_order') int sortOrder
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? url = null,Object? altText = freezed,Object? isPrimary = null,Object? sortOrder = null,}) {
  return _then(_ProductImage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,altText: freezed == altText ? _self.altText : altText // ignore: cast_nullable_to_non_nullable
as String?,isPrimary: null == isPrimary ? _self.isPrimary : isPrimary // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
