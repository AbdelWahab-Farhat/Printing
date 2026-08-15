// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'new_product.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NewProduct {

/// Omitted by this app: the server generates it from the name and the product's code, so
/// nobody has to invent `shipping-bag` for a product called أكياس الشحن. Kept on the model
/// because the API still accepts a deliberate one from an import.
@JsonKey(includeIfNull: false) String? get slug; String get name;/// Omitted from the body when absent — the API's rule is `nullable`, and sending `null`
/// says something slightly different from not mentioning it.
@JsonKey(includeIfNull: false) String? get description;@JsonKey(includeIfNull: false) List<String>? get features;/// «التصنيف» — the catalogue heading. Required by the API from today on.
@JsonKey(name: 'product_category_id') int get productCategoryId;@JsonKey(name: 'pricing_unit') String get pricingUnit;/// What the warehouse will count this in. **Optional, and omitted from the body when it is
/// not set** — the server then defaults it to [pricingUnit], which is the common case where
/// what is stocked and what is sold agree. Sending the same value again would be this app
/// repeating the server's own rule back at it, and the first place the two could drift.
///
/// Accepted on create only. `PUT /products/{id}` carries no rule for it and ignores the key;
/// correcting it afterwards is `PATCH /products/{id}/stock-unit`, because it cascades to
/// every warehouse balance and cost batch the product's variants have.
@JsonKey(name: 'stock_unit', includeIfNull: false) String? get stockUnit;@JsonKey(name: 'pricing_mode') String get pricingMode;/// A decimal string like `'100'`, already normalised out of whatever the keyboard produced.
@JsonKey(name: 'min_order_quantity') String get minOrderQuantity;/// Sizes. Empty is allowed: a quote-only product can exist before its sizes are known.
 List<NewProductVariant> get variants;
/// Create a copy of NewProduct
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewProductCopyWith<NewProduct> get copyWith => _$NewProductCopyWithImpl<NewProduct>(this as NewProduct, _$identity);

  /// Serializes this NewProduct to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewProduct&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.features, features)&&(identical(other.productCategoryId, productCategoryId) || other.productCategoryId == productCategoryId)&&(identical(other.pricingUnit, pricingUnit) || other.pricingUnit == pricingUnit)&&(identical(other.stockUnit, stockUnit) || other.stockUnit == stockUnit)&&(identical(other.pricingMode, pricingMode) || other.pricingMode == pricingMode)&&(identical(other.minOrderQuantity, minOrderQuantity) || other.minOrderQuantity == minOrderQuantity)&&const DeepCollectionEquality().equals(other.variants, variants));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,slug,name,description,const DeepCollectionEquality().hash(features),productCategoryId,pricingUnit,stockUnit,pricingMode,minOrderQuantity,const DeepCollectionEquality().hash(variants));

@override
String toString() {
  return 'NewProduct(slug: $slug, name: $name, description: $description, features: $features, productCategoryId: $productCategoryId, pricingUnit: $pricingUnit, stockUnit: $stockUnit, pricingMode: $pricingMode, minOrderQuantity: $minOrderQuantity, variants: $variants)';
}


}

/// @nodoc
abstract mixin class $NewProductCopyWith<$Res>  {
  factory $NewProductCopyWith(NewProduct value, $Res Function(NewProduct) _then) = _$NewProductCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeIfNull: false) String? slug, String name,@JsonKey(includeIfNull: false) String? description,@JsonKey(includeIfNull: false) List<String>? features,@JsonKey(name: 'product_category_id') int productCategoryId,@JsonKey(name: 'pricing_unit') String pricingUnit,@JsonKey(name: 'stock_unit', includeIfNull: false) String? stockUnit,@JsonKey(name: 'pricing_mode') String pricingMode,@JsonKey(name: 'min_order_quantity') String minOrderQuantity, List<NewProductVariant> variants
});




}
/// @nodoc
class _$NewProductCopyWithImpl<$Res>
    implements $NewProductCopyWith<$Res> {
  _$NewProductCopyWithImpl(this._self, this._then);

  final NewProduct _self;
  final $Res Function(NewProduct) _then;

/// Create a copy of NewProduct
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? slug = freezed,Object? name = null,Object? description = freezed,Object? features = freezed,Object? productCategoryId = null,Object? pricingUnit = null,Object? stockUnit = freezed,Object? pricingMode = null,Object? minOrderQuantity = null,Object? variants = null,}) {
  return _then(_self.copyWith(
slug: freezed == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,features: freezed == features ? _self.features : features // ignore: cast_nullable_to_non_nullable
as List<String>?,productCategoryId: null == productCategoryId ? _self.productCategoryId : productCategoryId // ignore: cast_nullable_to_non_nullable
as int,pricingUnit: null == pricingUnit ? _self.pricingUnit : pricingUnit // ignore: cast_nullable_to_non_nullable
as String,stockUnit: freezed == stockUnit ? _self.stockUnit : stockUnit // ignore: cast_nullable_to_non_nullable
as String?,pricingMode: null == pricingMode ? _self.pricingMode : pricingMode // ignore: cast_nullable_to_non_nullable
as String,minOrderQuantity: null == minOrderQuantity ? _self.minOrderQuantity : minOrderQuantity // ignore: cast_nullable_to_non_nullable
as String,variants: null == variants ? _self.variants : variants // ignore: cast_nullable_to_non_nullable
as List<NewProductVariant>,
  ));
}

}


/// Adds pattern-matching-related methods to [NewProduct].
extension NewProductPatterns on NewProduct {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewProduct value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewProduct() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewProduct value)  $default,){
final _that = this;
switch (_that) {
case _NewProduct():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewProduct value)?  $default,){
final _that = this;
switch (_that) {
case _NewProduct() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeIfNull: false)  String? slug,  String name, @JsonKey(includeIfNull: false)  String? description, @JsonKey(includeIfNull: false)  List<String>? features, @JsonKey(name: 'product_category_id')  int productCategoryId, @JsonKey(name: 'pricing_unit')  String pricingUnit, @JsonKey(name: 'stock_unit', includeIfNull: false)  String? stockUnit, @JsonKey(name: 'pricing_mode')  String pricingMode, @JsonKey(name: 'min_order_quantity')  String minOrderQuantity,  List<NewProductVariant> variants)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewProduct() when $default != null:
return $default(_that.slug,_that.name,_that.description,_that.features,_that.productCategoryId,_that.pricingUnit,_that.stockUnit,_that.pricingMode,_that.minOrderQuantity,_that.variants);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeIfNull: false)  String? slug,  String name, @JsonKey(includeIfNull: false)  String? description, @JsonKey(includeIfNull: false)  List<String>? features, @JsonKey(name: 'product_category_id')  int productCategoryId, @JsonKey(name: 'pricing_unit')  String pricingUnit, @JsonKey(name: 'stock_unit', includeIfNull: false)  String? stockUnit, @JsonKey(name: 'pricing_mode')  String pricingMode, @JsonKey(name: 'min_order_quantity')  String minOrderQuantity,  List<NewProductVariant> variants)  $default,) {final _that = this;
switch (_that) {
case _NewProduct():
return $default(_that.slug,_that.name,_that.description,_that.features,_that.productCategoryId,_that.pricingUnit,_that.stockUnit,_that.pricingMode,_that.minOrderQuantity,_that.variants);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeIfNull: false)  String? slug,  String name, @JsonKey(includeIfNull: false)  String? description, @JsonKey(includeIfNull: false)  List<String>? features, @JsonKey(name: 'product_category_id')  int productCategoryId, @JsonKey(name: 'pricing_unit')  String pricingUnit, @JsonKey(name: 'stock_unit', includeIfNull: false)  String? stockUnit, @JsonKey(name: 'pricing_mode')  String pricingMode, @JsonKey(name: 'min_order_quantity')  String minOrderQuantity,  List<NewProductVariant> variants)?  $default,) {final _that = this;
switch (_that) {
case _NewProduct() when $default != null:
return $default(_that.slug,_that.name,_that.description,_that.features,_that.productCategoryId,_that.pricingUnit,_that.stockUnit,_that.pricingMode,_that.minOrderQuantity,_that.variants);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NewProduct implements NewProduct {
  const _NewProduct({@JsonKey(includeIfNull: false) this.slug, required this.name, @JsonKey(includeIfNull: false) this.description, @JsonKey(includeIfNull: false) final  List<String>? features, @JsonKey(name: 'product_category_id') required this.productCategoryId, @JsonKey(name: 'pricing_unit') required this.pricingUnit, @JsonKey(name: 'stock_unit', includeIfNull: false) this.stockUnit, @JsonKey(name: 'pricing_mode') required this.pricingMode, @JsonKey(name: 'min_order_quantity') required this.minOrderQuantity, final  List<NewProductVariant> variants = const <NewProductVariant>[]}): _features = features,_variants = variants;
  factory _NewProduct.fromJson(Map<String, dynamic> json) => _$NewProductFromJson(json);

/// Omitted by this app: the server generates it from the name and the product's code, so
/// nobody has to invent `shipping-bag` for a product called أكياس الشحن. Kept on the model
/// because the API still accepts a deliberate one from an import.
@override@JsonKey(includeIfNull: false) final  String? slug;
@override final  String name;
/// Omitted from the body when absent — the API's rule is `nullable`, and sending `null`
/// says something slightly different from not mentioning it.
@override@JsonKey(includeIfNull: false) final  String? description;
 final  List<String>? _features;
@override@JsonKey(includeIfNull: false) List<String>? get features {
  final value = _features;
  if (value == null) return null;
  if (_features is EqualUnmodifiableListView) return _features;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// «التصنيف» — the catalogue heading. Required by the API from today on.
@override@JsonKey(name: 'product_category_id') final  int productCategoryId;
@override@JsonKey(name: 'pricing_unit') final  String pricingUnit;
/// What the warehouse will count this in. **Optional, and omitted from the body when it is
/// not set** — the server then defaults it to [pricingUnit], which is the common case where
/// what is stocked and what is sold agree. Sending the same value again would be this app
/// repeating the server's own rule back at it, and the first place the two could drift.
///
/// Accepted on create only. `PUT /products/{id}` carries no rule for it and ignores the key;
/// correcting it afterwards is `PATCH /products/{id}/stock-unit`, because it cascades to
/// every warehouse balance and cost batch the product's variants have.
@override@JsonKey(name: 'stock_unit', includeIfNull: false) final  String? stockUnit;
@override@JsonKey(name: 'pricing_mode') final  String pricingMode;
/// A decimal string like `'100'`, already normalised out of whatever the keyboard produced.
@override@JsonKey(name: 'min_order_quantity') final  String minOrderQuantity;
/// Sizes. Empty is allowed: a quote-only product can exist before its sizes are known.
 final  List<NewProductVariant> _variants;
/// Sizes. Empty is allowed: a quote-only product can exist before its sizes are known.
@override@JsonKey() List<NewProductVariant> get variants {
  if (_variants is EqualUnmodifiableListView) return _variants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_variants);
}


/// Create a copy of NewProduct
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewProductCopyWith<_NewProduct> get copyWith => __$NewProductCopyWithImpl<_NewProduct>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NewProductToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewProduct&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._features, _features)&&(identical(other.productCategoryId, productCategoryId) || other.productCategoryId == productCategoryId)&&(identical(other.pricingUnit, pricingUnit) || other.pricingUnit == pricingUnit)&&(identical(other.stockUnit, stockUnit) || other.stockUnit == stockUnit)&&(identical(other.pricingMode, pricingMode) || other.pricingMode == pricingMode)&&(identical(other.minOrderQuantity, minOrderQuantity) || other.minOrderQuantity == minOrderQuantity)&&const DeepCollectionEquality().equals(other._variants, _variants));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,slug,name,description,const DeepCollectionEquality().hash(_features),productCategoryId,pricingUnit,stockUnit,pricingMode,minOrderQuantity,const DeepCollectionEquality().hash(_variants));

@override
String toString() {
  return 'NewProduct(slug: $slug, name: $name, description: $description, features: $features, productCategoryId: $productCategoryId, pricingUnit: $pricingUnit, stockUnit: $stockUnit, pricingMode: $pricingMode, minOrderQuantity: $minOrderQuantity, variants: $variants)';
}


}

/// @nodoc
abstract mixin class _$NewProductCopyWith<$Res> implements $NewProductCopyWith<$Res> {
  factory _$NewProductCopyWith(_NewProduct value, $Res Function(_NewProduct) _then) = __$NewProductCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeIfNull: false) String? slug, String name,@JsonKey(includeIfNull: false) String? description,@JsonKey(includeIfNull: false) List<String>? features,@JsonKey(name: 'product_category_id') int productCategoryId,@JsonKey(name: 'pricing_unit') String pricingUnit,@JsonKey(name: 'stock_unit', includeIfNull: false) String? stockUnit,@JsonKey(name: 'pricing_mode') String pricingMode,@JsonKey(name: 'min_order_quantity') String minOrderQuantity, List<NewProductVariant> variants
});




}
/// @nodoc
class __$NewProductCopyWithImpl<$Res>
    implements _$NewProductCopyWith<$Res> {
  __$NewProductCopyWithImpl(this._self, this._then);

  final _NewProduct _self;
  final $Res Function(_NewProduct) _then;

/// Create a copy of NewProduct
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? slug = freezed,Object? name = null,Object? description = freezed,Object? features = freezed,Object? productCategoryId = null,Object? pricingUnit = null,Object? stockUnit = freezed,Object? pricingMode = null,Object? minOrderQuantity = null,Object? variants = null,}) {
  return _then(_NewProduct(
slug: freezed == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,features: freezed == features ? _self._features : features // ignore: cast_nullable_to_non_nullable
as List<String>?,productCategoryId: null == productCategoryId ? _self.productCategoryId : productCategoryId // ignore: cast_nullable_to_non_nullable
as int,pricingUnit: null == pricingUnit ? _self.pricingUnit : pricingUnit // ignore: cast_nullable_to_non_nullable
as String,stockUnit: freezed == stockUnit ? _self.stockUnit : stockUnit // ignore: cast_nullable_to_non_nullable
as String?,pricingMode: null == pricingMode ? _self.pricingMode : pricingMode // ignore: cast_nullable_to_non_nullable
as String,minOrderQuantity: null == minOrderQuantity ? _self.minOrderQuantity : minOrderQuantity // ignore: cast_nullable_to_non_nullable
as String,variants: null == variants ? _self._variants : variants // ignore: cast_nullable_to_non_nullable
as List<NewProductVariant>,
  ));
}


}


/// @nodoc
mixin _$NewProductVariant {

/// **The id of a size that already exists, and the reason editing works at all.**
///
/// `PUT /products/{id}` makes the list match exactly: a size carrying an id is updated in
/// place, one without is created, and one left out is *removed*. Sending an existing size
/// without its id would therefore delete it and create a lookalike — and the order lines
/// pointing at the old row would be pointing at a deleted size.
///
/// Null when creating, and omitted from the body then.
@JsonKey(includeIfNull: false) int? get id; String get label;/// Strings, not `int`s, and deliberately.
///
/// `٢٥` is what a Libyan keyboard produces and `int.tryParse('٢٥')` is null. Parsing in the
/// page would drop the dimension silently — the server accepts a null width, so nothing
/// would complain and nobody would find out. Held as text here, normalised in
/// [CreateProduct], which is the one file that converts anything.
@JsonKey(name: 'width_cm', includeIfNull: false) int? get widthCm;@JsonKey(name: 'height_cm', includeIfNull: false) int? get heightCm;@JsonKey(name: 'price_tiers') List<NewPriceTier> get priceTiers;
/// Create a copy of NewProductVariant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewProductVariantCopyWith<NewProductVariant> get copyWith => _$NewProductVariantCopyWithImpl<NewProductVariant>(this as NewProductVariant, _$identity);

  /// Serializes this NewProductVariant to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewProductVariant&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.widthCm, widthCm) || other.widthCm == widthCm)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&const DeepCollectionEquality().equals(other.priceTiers, priceTiers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,widthCm,heightCm,const DeepCollectionEquality().hash(priceTiers));

@override
String toString() {
  return 'NewProductVariant(id: $id, label: $label, widthCm: $widthCm, heightCm: $heightCm, priceTiers: $priceTiers)';
}


}

/// @nodoc
abstract mixin class $NewProductVariantCopyWith<$Res>  {
  factory $NewProductVariantCopyWith(NewProductVariant value, $Res Function(NewProductVariant) _then) = _$NewProductVariantCopyWithImpl;
@useResult
$Res call({
@JsonKey(includeIfNull: false) int? id, String label,@JsonKey(name: 'width_cm', includeIfNull: false) int? widthCm,@JsonKey(name: 'height_cm', includeIfNull: false) int? heightCm,@JsonKey(name: 'price_tiers') List<NewPriceTier> priceTiers
});




}
/// @nodoc
class _$NewProductVariantCopyWithImpl<$Res>
    implements $NewProductVariantCopyWith<$Res> {
  _$NewProductVariantCopyWithImpl(this._self, this._then);

  final NewProductVariant _self;
  final $Res Function(NewProductVariant) _then;

/// Create a copy of NewProductVariant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? label = null,Object? widthCm = freezed,Object? heightCm = freezed,Object? priceTiers = null,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,widthCm: freezed == widthCm ? _self.widthCm : widthCm // ignore: cast_nullable_to_non_nullable
as int?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as int?,priceTiers: null == priceTiers ? _self.priceTiers : priceTiers // ignore: cast_nullable_to_non_nullable
as List<NewPriceTier>,
  ));
}

}


/// Adds pattern-matching-related methods to [NewProductVariant].
extension NewProductVariantPatterns on NewProductVariant {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewProductVariant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewProductVariant() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewProductVariant value)  $default,){
final _that = this;
switch (_that) {
case _NewProductVariant():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewProductVariant value)?  $default,){
final _that = this;
switch (_that) {
case _NewProductVariant() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(includeIfNull: false)  int? id,  String label, @JsonKey(name: 'width_cm', includeIfNull: false)  int? widthCm, @JsonKey(name: 'height_cm', includeIfNull: false)  int? heightCm, @JsonKey(name: 'price_tiers')  List<NewPriceTier> priceTiers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewProductVariant() when $default != null:
return $default(_that.id,_that.label,_that.widthCm,_that.heightCm,_that.priceTiers);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(includeIfNull: false)  int? id,  String label, @JsonKey(name: 'width_cm', includeIfNull: false)  int? widthCm, @JsonKey(name: 'height_cm', includeIfNull: false)  int? heightCm, @JsonKey(name: 'price_tiers')  List<NewPriceTier> priceTiers)  $default,) {final _that = this;
switch (_that) {
case _NewProductVariant():
return $default(_that.id,_that.label,_that.widthCm,_that.heightCm,_that.priceTiers);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(includeIfNull: false)  int? id,  String label, @JsonKey(name: 'width_cm', includeIfNull: false)  int? widthCm, @JsonKey(name: 'height_cm', includeIfNull: false)  int? heightCm, @JsonKey(name: 'price_tiers')  List<NewPriceTier> priceTiers)?  $default,) {final _that = this;
switch (_that) {
case _NewProductVariant() when $default != null:
return $default(_that.id,_that.label,_that.widthCm,_that.heightCm,_that.priceTiers);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NewProductVariant implements NewProductVariant {
  const _NewProductVariant({@JsonKey(includeIfNull: false) this.id, required this.label, @JsonKey(name: 'width_cm', includeIfNull: false) this.widthCm, @JsonKey(name: 'height_cm', includeIfNull: false) this.heightCm, @JsonKey(name: 'price_tiers') final  List<NewPriceTier> priceTiers = const <NewPriceTier>[]}): _priceTiers = priceTiers;
  factory _NewProductVariant.fromJson(Map<String, dynamic> json) => _$NewProductVariantFromJson(json);

/// **The id of a size that already exists, and the reason editing works at all.**
///
/// `PUT /products/{id}` makes the list match exactly: a size carrying an id is updated in
/// place, one without is created, and one left out is *removed*. Sending an existing size
/// without its id would therefore delete it and create a lookalike — and the order lines
/// pointing at the old row would be pointing at a deleted size.
///
/// Null when creating, and omitted from the body then.
@override@JsonKey(includeIfNull: false) final  int? id;
@override final  String label;
/// Strings, not `int`s, and deliberately.
///
/// `٢٥` is what a Libyan keyboard produces and `int.tryParse('٢٥')` is null. Parsing in the
/// page would drop the dimension silently — the server accepts a null width, so nothing
/// would complain and nobody would find out. Held as text here, normalised in
/// [CreateProduct], which is the one file that converts anything.
@override@JsonKey(name: 'width_cm', includeIfNull: false) final  int? widthCm;
@override@JsonKey(name: 'height_cm', includeIfNull: false) final  int? heightCm;
 final  List<NewPriceTier> _priceTiers;
@override@JsonKey(name: 'price_tiers') List<NewPriceTier> get priceTiers {
  if (_priceTiers is EqualUnmodifiableListView) return _priceTiers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_priceTiers);
}


/// Create a copy of NewProductVariant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewProductVariantCopyWith<_NewProductVariant> get copyWith => __$NewProductVariantCopyWithImpl<_NewProductVariant>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NewProductVariantToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewProductVariant&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.widthCm, widthCm) || other.widthCm == widthCm)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&const DeepCollectionEquality().equals(other._priceTiers, _priceTiers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,widthCm,heightCm,const DeepCollectionEquality().hash(_priceTiers));

@override
String toString() {
  return 'NewProductVariant(id: $id, label: $label, widthCm: $widthCm, heightCm: $heightCm, priceTiers: $priceTiers)';
}


}

/// @nodoc
abstract mixin class _$NewProductVariantCopyWith<$Res> implements $NewProductVariantCopyWith<$Res> {
  factory _$NewProductVariantCopyWith(_NewProductVariant value, $Res Function(_NewProductVariant) _then) = __$NewProductVariantCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(includeIfNull: false) int? id, String label,@JsonKey(name: 'width_cm', includeIfNull: false) int? widthCm,@JsonKey(name: 'height_cm', includeIfNull: false) int? heightCm,@JsonKey(name: 'price_tiers') List<NewPriceTier> priceTiers
});




}
/// @nodoc
class __$NewProductVariantCopyWithImpl<$Res>
    implements _$NewProductVariantCopyWith<$Res> {
  __$NewProductVariantCopyWithImpl(this._self, this._then);

  final _NewProductVariant _self;
  final $Res Function(_NewProductVariant) _then;

/// Create a copy of NewProductVariant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? label = null,Object? widthCm = freezed,Object? heightCm = freezed,Object? priceTiers = null,}) {
  return _then(_NewProductVariant(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,widthCm: freezed == widthCm ? _self.widthCm : widthCm // ignore: cast_nullable_to_non_nullable
as int?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as int?,priceTiers: null == priceTiers ? _self._priceTiers : priceTiers // ignore: cast_nullable_to_non_nullable
as List<NewPriceTier>,
  ));
}


}


/// @nodoc
mixin _$NewPriceTier {

@JsonKey(name: 'min_quantity') String get minQuantity;@JsonKey(name: 'unit_price') String get unitPrice;
/// Create a copy of NewPriceTier
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewPriceTierCopyWith<NewPriceTier> get copyWith => _$NewPriceTierCopyWithImpl<NewPriceTier>(this as NewPriceTier, _$identity);

  /// Serializes this NewPriceTier to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewPriceTier&&(identical(other.minQuantity, minQuantity) || other.minQuantity == minQuantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,minQuantity,unitPrice);

@override
String toString() {
  return 'NewPriceTier(minQuantity: $minQuantity, unitPrice: $unitPrice)';
}


}

/// @nodoc
abstract mixin class $NewPriceTierCopyWith<$Res>  {
  factory $NewPriceTierCopyWith(NewPriceTier value, $Res Function(NewPriceTier) _then) = _$NewPriceTierCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'min_quantity') String minQuantity,@JsonKey(name: 'unit_price') String unitPrice
});




}
/// @nodoc
class _$NewPriceTierCopyWithImpl<$Res>
    implements $NewPriceTierCopyWith<$Res> {
  _$NewPriceTierCopyWithImpl(this._self, this._then);

  final NewPriceTier _self;
  final $Res Function(NewPriceTier) _then;

/// Create a copy of NewPriceTier
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? minQuantity = null,Object? unitPrice = null,}) {
  return _then(_self.copyWith(
minQuantity: null == minQuantity ? _self.minQuantity : minQuantity // ignore: cast_nullable_to_non_nullable
as String,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [NewPriceTier].
extension NewPriceTierPatterns on NewPriceTier {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewPriceTier value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewPriceTier() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewPriceTier value)  $default,){
final _that = this;
switch (_that) {
case _NewPriceTier():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewPriceTier value)?  $default,){
final _that = this;
switch (_that) {
case _NewPriceTier() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'min_quantity')  String minQuantity, @JsonKey(name: 'unit_price')  String unitPrice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewPriceTier() when $default != null:
return $default(_that.minQuantity,_that.unitPrice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'min_quantity')  String minQuantity, @JsonKey(name: 'unit_price')  String unitPrice)  $default,) {final _that = this;
switch (_that) {
case _NewPriceTier():
return $default(_that.minQuantity,_that.unitPrice);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'min_quantity')  String minQuantity, @JsonKey(name: 'unit_price')  String unitPrice)?  $default,) {final _that = this;
switch (_that) {
case _NewPriceTier() when $default != null:
return $default(_that.minQuantity,_that.unitPrice);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NewPriceTier implements NewPriceTier {
  const _NewPriceTier({@JsonKey(name: 'min_quantity') required this.minQuantity, @JsonKey(name: 'unit_price') required this.unitPrice});
  factory _NewPriceTier.fromJson(Map<String, dynamic> json) => _$NewPriceTierFromJson(json);

@override@JsonKey(name: 'min_quantity') final  String minQuantity;
@override@JsonKey(name: 'unit_price') final  String unitPrice;

/// Create a copy of NewPriceTier
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewPriceTierCopyWith<_NewPriceTier> get copyWith => __$NewPriceTierCopyWithImpl<_NewPriceTier>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NewPriceTierToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewPriceTier&&(identical(other.minQuantity, minQuantity) || other.minQuantity == minQuantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,minQuantity,unitPrice);

@override
String toString() {
  return 'NewPriceTier(minQuantity: $minQuantity, unitPrice: $unitPrice)';
}


}

/// @nodoc
abstract mixin class _$NewPriceTierCopyWith<$Res> implements $NewPriceTierCopyWith<$Res> {
  factory _$NewPriceTierCopyWith(_NewPriceTier value, $Res Function(_NewPriceTier) _then) = __$NewPriceTierCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'min_quantity') String minQuantity,@JsonKey(name: 'unit_price') String unitPrice
});




}
/// @nodoc
class __$NewPriceTierCopyWithImpl<$Res>
    implements _$NewPriceTierCopyWith<$Res> {
  __$NewPriceTierCopyWithImpl(this._self, this._then);

  final _NewPriceTier _self;
  final $Res Function(_NewPriceTier) _then;

/// Create a copy of NewPriceTier
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? minQuantity = null,Object? unitPrice = null,}) {
  return _then(_NewPriceTier(
minQuantity: null == minQuantity ? _self.minQuantity : minQuantity // ignore: cast_nullable_to_non_nullable
as String,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
