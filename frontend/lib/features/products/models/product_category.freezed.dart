// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProductCategory {

 int get id; String get name;/// The line the catalogue prints under the heading. Null until somebody writes one.
 String? get description;/// Whether it is still offered when recording a product. A stopped category stays on the
/// products already under it — it leaves the picker, it does not retract anything.
@JsonKey(name: 'is_active') bool get isActive;/// Where it sits in the catalogue. The business's own order, not alphabetical.
@JsonKey(name: 'sort_order') int get sortOrder;/// The heading this one sits under, or null when it is one in its own right.
///
/// The tree is one level deep and this app does not manage it yet — the field exists so a
/// child arriving from the API is not silently drawn as a root.
@JsonKey(name: 'parent_id') int? get parentId;/// Products filed directly on this heading. Zero for a parent by construction: a heading
/// with subheadings is a heading, not a slot.
@JsonKey(name: 'products_count') int? get productsCount;/// How many subheadings it holds. What says this row is a heading rather than something a
/// product can be filed under.
@JsonKey(name: 'children_count') int? get childrenCount;/// Everything under it, subheadings included. **This is the number the card shows** — and
/// the same one that decides whether a delete will be refused, so the screen can explain
/// that before the button is pressed.
@JsonKey(name: 'total_products_count') int? get totalProductsCount;/// The picture the catalogue prints above the heading. Built by the server per request and
/// never stored: on a private disk it is a signed link that expires, so a screen holding
/// one for an hour must reload rather than reuse it.
@JsonKey(name: 'image_url') String? get imageUrl;@JsonKey(name: 'image_width_px') int? get imageWidthPx;@JsonKey(name: 'image_height_px') int? get imageHeightPx;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of ProductCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductCategoryCopyWith<ProductCategory> get copyWith => _$ProductCategoryCopyWithImpl<ProductCategory>(this as ProductCategory, _$identity);

  /// Serializes this ProductCategory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.productsCount, productsCount) || other.productsCount == productsCount)&&(identical(other.childrenCount, childrenCount) || other.childrenCount == childrenCount)&&(identical(other.totalProductsCount, totalProductsCount) || other.totalProductsCount == totalProductsCount)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.imageWidthPx, imageWidthPx) || other.imageWidthPx == imageWidthPx)&&(identical(other.imageHeightPx, imageHeightPx) || other.imageHeightPx == imageHeightPx)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,isActive,sortOrder,parentId,productsCount,childrenCount,totalProductsCount,imageUrl,imageWidthPx,imageHeightPx,createdAt,updatedAt);

@override
String toString() {
  return 'ProductCategory(id: $id, name: $name, description: $description, isActive: $isActive, sortOrder: $sortOrder, parentId: $parentId, productsCount: $productsCount, childrenCount: $childrenCount, totalProductsCount: $totalProductsCount, imageUrl: $imageUrl, imageWidthPx: $imageWidthPx, imageHeightPx: $imageHeightPx, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ProductCategoryCopyWith<$Res>  {
  factory $ProductCategoryCopyWith(ProductCategory value, $Res Function(ProductCategory) _then) = _$ProductCategoryCopyWithImpl;
@useResult
$Res call({
 int id, String name, String? description,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'sort_order') int sortOrder,@JsonKey(name: 'parent_id') int? parentId,@JsonKey(name: 'products_count') int? productsCount,@JsonKey(name: 'children_count') int? childrenCount,@JsonKey(name: 'total_products_count') int? totalProductsCount,@JsonKey(name: 'image_url') String? imageUrl,@JsonKey(name: 'image_width_px') int? imageWidthPx,@JsonKey(name: 'image_height_px') int? imageHeightPx,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class _$ProductCategoryCopyWithImpl<$Res>
    implements $ProductCategoryCopyWith<$Res> {
  _$ProductCategoryCopyWithImpl(this._self, this._then);

  final ProductCategory _self;
  final $Res Function(ProductCategory) _then;

/// Create a copy of ProductCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? isActive = null,Object? sortOrder = null,Object? parentId = freezed,Object? productsCount = freezed,Object? childrenCount = freezed,Object? totalProductsCount = freezed,Object? imageUrl = freezed,Object? imageWidthPx = freezed,Object? imageHeightPx = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as int?,productsCount: freezed == productsCount ? _self.productsCount : productsCount // ignore: cast_nullable_to_non_nullable
as int?,childrenCount: freezed == childrenCount ? _self.childrenCount : childrenCount // ignore: cast_nullable_to_non_nullable
as int?,totalProductsCount: freezed == totalProductsCount ? _self.totalProductsCount : totalProductsCount // ignore: cast_nullable_to_non_nullable
as int?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,imageWidthPx: freezed == imageWidthPx ? _self.imageWidthPx : imageWidthPx // ignore: cast_nullable_to_non_nullable
as int?,imageHeightPx: freezed == imageHeightPx ? _self.imageHeightPx : imageHeightPx // ignore: cast_nullable_to_non_nullable
as int?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductCategory].
extension ProductCategoryPatterns on ProductCategory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductCategory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductCategory value)  $default,){
final _that = this;
switch (_that) {
case _ProductCategory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductCategory value)?  $default,){
final _that = this;
switch (_that) {
case _ProductCategory() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String? description, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'sort_order')  int sortOrder, @JsonKey(name: 'parent_id')  int? parentId, @JsonKey(name: 'products_count')  int? productsCount, @JsonKey(name: 'children_count')  int? childrenCount, @JsonKey(name: 'total_products_count')  int? totalProductsCount, @JsonKey(name: 'image_url')  String? imageUrl, @JsonKey(name: 'image_width_px')  int? imageWidthPx, @JsonKey(name: 'image_height_px')  int? imageHeightPx, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductCategory() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.isActive,_that.sortOrder,_that.parentId,_that.productsCount,_that.childrenCount,_that.totalProductsCount,_that.imageUrl,_that.imageWidthPx,_that.imageHeightPx,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String? description, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'sort_order')  int sortOrder, @JsonKey(name: 'parent_id')  int? parentId, @JsonKey(name: 'products_count')  int? productsCount, @JsonKey(name: 'children_count')  int? childrenCount, @JsonKey(name: 'total_products_count')  int? totalProductsCount, @JsonKey(name: 'image_url')  String? imageUrl, @JsonKey(name: 'image_width_px')  int? imageWidthPx, @JsonKey(name: 'image_height_px')  int? imageHeightPx, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _ProductCategory():
return $default(_that.id,_that.name,_that.description,_that.isActive,_that.sortOrder,_that.parentId,_that.productsCount,_that.childrenCount,_that.totalProductsCount,_that.imageUrl,_that.imageWidthPx,_that.imageHeightPx,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String? description, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'sort_order')  int sortOrder, @JsonKey(name: 'parent_id')  int? parentId, @JsonKey(name: 'products_count')  int? productsCount, @JsonKey(name: 'children_count')  int? childrenCount, @JsonKey(name: 'total_products_count')  int? totalProductsCount, @JsonKey(name: 'image_url')  String? imageUrl, @JsonKey(name: 'image_width_px')  int? imageWidthPx, @JsonKey(name: 'image_height_px')  int? imageHeightPx, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ProductCategory() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.isActive,_that.sortOrder,_that.parentId,_that.productsCount,_that.childrenCount,_that.totalProductsCount,_that.imageUrl,_that.imageWidthPx,_that.imageHeightPx,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductCategory extends ProductCategory {
  const _ProductCategory({required this.id, required this.name, this.description, @JsonKey(name: 'is_active') this.isActive = true, @JsonKey(name: 'sort_order') this.sortOrder = 0, @JsonKey(name: 'parent_id') this.parentId, @JsonKey(name: 'products_count') this.productsCount, @JsonKey(name: 'children_count') this.childrenCount, @JsonKey(name: 'total_products_count') this.totalProductsCount, @JsonKey(name: 'image_url') this.imageUrl, @JsonKey(name: 'image_width_px') this.imageWidthPx, @JsonKey(name: 'image_height_px') this.imageHeightPx, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt}): super._();
  factory _ProductCategory.fromJson(Map<String, dynamic> json) => _$ProductCategoryFromJson(json);

@override final  int id;
@override final  String name;
/// The line the catalogue prints under the heading. Null until somebody writes one.
@override final  String? description;
/// Whether it is still offered when recording a product. A stopped category stays on the
/// products already under it — it leaves the picker, it does not retract anything.
@override@JsonKey(name: 'is_active') final  bool isActive;
/// Where it sits in the catalogue. The business's own order, not alphabetical.
@override@JsonKey(name: 'sort_order') final  int sortOrder;
/// The heading this one sits under, or null when it is one in its own right.
///
/// The tree is one level deep and this app does not manage it yet — the field exists so a
/// child arriving from the API is not silently drawn as a root.
@override@JsonKey(name: 'parent_id') final  int? parentId;
/// Products filed directly on this heading. Zero for a parent by construction: a heading
/// with subheadings is a heading, not a slot.
@override@JsonKey(name: 'products_count') final  int? productsCount;
/// How many subheadings it holds. What says this row is a heading rather than something a
/// product can be filed under.
@override@JsonKey(name: 'children_count') final  int? childrenCount;
/// Everything under it, subheadings included. **This is the number the card shows** — and
/// the same one that decides whether a delete will be refused, so the screen can explain
/// that before the button is pressed.
@override@JsonKey(name: 'total_products_count') final  int? totalProductsCount;
/// The picture the catalogue prints above the heading. Built by the server per request and
/// never stored: on a private disk it is a signed link that expires, so a screen holding
/// one for an hour must reload rather than reuse it.
@override@JsonKey(name: 'image_url') final  String? imageUrl;
@override@JsonKey(name: 'image_width_px') final  int? imageWidthPx;
@override@JsonKey(name: 'image_height_px') final  int? imageHeightPx;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;

/// Create a copy of ProductCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductCategoryCopyWith<_ProductCategory> get copyWith => __$ProductCategoryCopyWithImpl<_ProductCategory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductCategoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.productsCount, productsCount) || other.productsCount == productsCount)&&(identical(other.childrenCount, childrenCount) || other.childrenCount == childrenCount)&&(identical(other.totalProductsCount, totalProductsCount) || other.totalProductsCount == totalProductsCount)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.imageWidthPx, imageWidthPx) || other.imageWidthPx == imageWidthPx)&&(identical(other.imageHeightPx, imageHeightPx) || other.imageHeightPx == imageHeightPx)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,description,isActive,sortOrder,parentId,productsCount,childrenCount,totalProductsCount,imageUrl,imageWidthPx,imageHeightPx,createdAt,updatedAt);

@override
String toString() {
  return 'ProductCategory(id: $id, name: $name, description: $description, isActive: $isActive, sortOrder: $sortOrder, parentId: $parentId, productsCount: $productsCount, childrenCount: $childrenCount, totalProductsCount: $totalProductsCount, imageUrl: $imageUrl, imageWidthPx: $imageWidthPx, imageHeightPx: $imageHeightPx, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ProductCategoryCopyWith<$Res> implements $ProductCategoryCopyWith<$Res> {
  factory _$ProductCategoryCopyWith(_ProductCategory value, $Res Function(_ProductCategory) _then) = __$ProductCategoryCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String? description,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'sort_order') int sortOrder,@JsonKey(name: 'parent_id') int? parentId,@JsonKey(name: 'products_count') int? productsCount,@JsonKey(name: 'children_count') int? childrenCount,@JsonKey(name: 'total_products_count') int? totalProductsCount,@JsonKey(name: 'image_url') String? imageUrl,@JsonKey(name: 'image_width_px') int? imageWidthPx,@JsonKey(name: 'image_height_px') int? imageHeightPx,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class __$ProductCategoryCopyWithImpl<$Res>
    implements _$ProductCategoryCopyWith<$Res> {
  __$ProductCategoryCopyWithImpl(this._self, this._then);

  final _ProductCategory _self;
  final $Res Function(_ProductCategory) _then;

/// Create a copy of ProductCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? isActive = null,Object? sortOrder = null,Object? parentId = freezed,Object? productsCount = freezed,Object? childrenCount = freezed,Object? totalProductsCount = freezed,Object? imageUrl = freezed,Object? imageWidthPx = freezed,Object? imageHeightPx = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_ProductCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as int?,productsCount: freezed == productsCount ? _self.productsCount : productsCount // ignore: cast_nullable_to_non_nullable
as int?,childrenCount: freezed == childrenCount ? _self.childrenCount : childrenCount // ignore: cast_nullable_to_non_nullable
as int?,totalProductsCount: freezed == totalProductsCount ? _self.totalProductsCount : totalProductsCount // ignore: cast_nullable_to_non_nullable
as int?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,imageWidthPx: freezed == imageWidthPx ? _self.imageWidthPx : imageWidthPx // ignore: cast_nullable_to_non_nullable
as int?,imageHeightPx: freezed == imageHeightPx ? _self.imageHeightPx : imageHeightPx // ignore: cast_nullable_to_non_nullable
as int?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
