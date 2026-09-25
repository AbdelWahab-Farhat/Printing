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
mixin _$ProductCategory {

 int get id; String get name;@JsonKey(name: 'parent_id') int? get parentId;@JsonKey(name: 'image_url') String? get imageUrl;
/// Create a copy of ProductCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductCategoryCopyWith<ProductCategory> get copyWith => _$ProductCategoryCopyWithImpl<ProductCategory>(this as ProductCategory, _$identity);

  /// Serializes this ProductCategory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,parentId,imageUrl);

@override
String toString() {
  return 'ProductCategory(id: $id, name: $name, parentId: $parentId, imageUrl: $imageUrl)';
}


}

/// @nodoc
abstract mixin class $ProductCategoryCopyWith<$Res>  {
  factory $ProductCategoryCopyWith(ProductCategory value, $Res Function(ProductCategory) _then) = _$ProductCategoryCopyWithImpl;
@useResult
$Res call({
 int id, String name,@JsonKey(name: 'parent_id') int? parentId,@JsonKey(name: 'image_url') String? imageUrl
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? parentId = freezed,Object? imageUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as int?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'parent_id')  int? parentId, @JsonKey(name: 'image_url')  String? imageUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductCategory() when $default != null:
return $default(_that.id,_that.name,_that.parentId,_that.imageUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'parent_id')  int? parentId, @JsonKey(name: 'image_url')  String? imageUrl)  $default,) {final _that = this;
switch (_that) {
case _ProductCategory():
return $default(_that.id,_that.name,_that.parentId,_that.imageUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name, @JsonKey(name: 'parent_id')  int? parentId, @JsonKey(name: 'image_url')  String? imageUrl)?  $default,) {final _that = this;
switch (_that) {
case _ProductCategory() when $default != null:
return $default(_that.id,_that.name,_that.parentId,_that.imageUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductCategory implements ProductCategory {
  const _ProductCategory({required this.id, required this.name, @JsonKey(name: 'parent_id') this.parentId, @JsonKey(name: 'image_url') this.imageUrl});
  factory _ProductCategory.fromJson(Map<String, dynamic> json) => _$ProductCategoryFromJson(json);

@override final  int id;
@override final  String name;
@override@JsonKey(name: 'parent_id') final  int? parentId;
@override@JsonKey(name: 'image_url') final  String? imageUrl;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,parentId,imageUrl);

@override
String toString() {
  return 'ProductCategory(id: $id, name: $name, parentId: $parentId, imageUrl: $imageUrl)';
}


}

/// @nodoc
abstract mixin class _$ProductCategoryCopyWith<$Res> implements $ProductCategoryCopyWith<$Res> {
  factory _$ProductCategoryCopyWith(_ProductCategory value, $Res Function(_ProductCategory) _then) = __$ProductCategoryCopyWithImpl;
@override @useResult
$Res call({
 int id, String name,@JsonKey(name: 'parent_id') int? parentId,@JsonKey(name: 'image_url') String? imageUrl
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? parentId = freezed,Object? imageUrl = freezed,}) {
  return _then(_ProductCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as int?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$PriceTier {

 int get id;@JsonKey(name: 'min_quantity') String get minQuantity;@JsonKey(name: 'unit_price') String get unitPrice;
/// Create a copy of PriceTier
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PriceTierCopyWith<PriceTier> get copyWith => _$PriceTierCopyWithImpl<PriceTier>(this as PriceTier, _$identity);

  /// Serializes this PriceTier to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PriceTier&&(identical(other.id, id) || other.id == id)&&(identical(other.minQuantity, minQuantity) || other.minQuantity == minQuantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,minQuantity,unitPrice);

@override
String toString() {
  return 'PriceTier(id: $id, minQuantity: $minQuantity, unitPrice: $unitPrice)';
}


}

/// @nodoc
abstract mixin class $PriceTierCopyWith<$Res>  {
  factory $PriceTierCopyWith(PriceTier value, $Res Function(PriceTier) _then) = _$PriceTierCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'min_quantity') String minQuantity,@JsonKey(name: 'unit_price') String unitPrice
});




}
/// @nodoc
class _$PriceTierCopyWithImpl<$Res>
    implements $PriceTierCopyWith<$Res> {
  _$PriceTierCopyWithImpl(this._self, this._then);

  final PriceTier _self;
  final $Res Function(PriceTier) _then;

/// Create a copy of PriceTier
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


/// Adds pattern-matching-related methods to [PriceTier].
extension PriceTierPatterns on PriceTier {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PriceTier value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PriceTier() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PriceTier value)  $default,){
final _that = this;
switch (_that) {
case _PriceTier():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PriceTier value)?  $default,){
final _that = this;
switch (_that) {
case _PriceTier() when $default != null:
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
case _PriceTier() when $default != null:
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
case _PriceTier():
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
case _PriceTier() when $default != null:
return $default(_that.id,_that.minQuantity,_that.unitPrice);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PriceTier implements PriceTier {
  const _PriceTier({required this.id, @JsonKey(name: 'min_quantity') required this.minQuantity, @JsonKey(name: 'unit_price') required this.unitPrice});
  factory _PriceTier.fromJson(Map<String, dynamic> json) => _$PriceTierFromJson(json);

@override final  int id;
@override@JsonKey(name: 'min_quantity') final  String minQuantity;
@override@JsonKey(name: 'unit_price') final  String unitPrice;

/// Create a copy of PriceTier
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PriceTierCopyWith<_PriceTier> get copyWith => __$PriceTierCopyWithImpl<_PriceTier>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PriceTierToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PriceTier&&(identical(other.id, id) || other.id == id)&&(identical(other.minQuantity, minQuantity) || other.minQuantity == minQuantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,minQuantity,unitPrice);

@override
String toString() {
  return 'PriceTier(id: $id, minQuantity: $minQuantity, unitPrice: $unitPrice)';
}


}

/// @nodoc
abstract mixin class _$PriceTierCopyWith<$Res> implements $PriceTierCopyWith<$Res> {
  factory _$PriceTierCopyWith(_PriceTier value, $Res Function(_PriceTier) _then) = __$PriceTierCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'min_quantity') String minQuantity,@JsonKey(name: 'unit_price') String unitPrice
});




}
/// @nodoc
class __$PriceTierCopyWithImpl<$Res>
    implements _$PriceTierCopyWith<$Res> {
  __$PriceTierCopyWithImpl(this._self, this._then);

  final _PriceTier _self;
  final $Res Function(_PriceTier) _then;

/// Create a copy of PriceTier
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? minQuantity = null,Object? unitPrice = null,}) {
  return _then(_PriceTier(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,minQuantity: null == minQuantity ? _self.minQuantity : minQuantity // ignore: cast_nullable_to_non_nullable
as String,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ProductVariant {

 int get id;/// «25*35» — what the customer picks from.
 String get label;@JsonKey(name: 'width_cm') num? get widthCm;@JsonKey(name: 'height_cm') num? get heightCm;@JsonKey(name: 'price_tiers') List<PriceTier> get priceTiers;
/// Create a copy of ProductVariant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductVariantCopyWith<ProductVariant> get copyWith => _$ProductVariantCopyWithImpl<ProductVariant>(this as ProductVariant, _$identity);

  /// Serializes this ProductVariant to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductVariant&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.widthCm, widthCm) || other.widthCm == widthCm)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&const DeepCollectionEquality().equals(other.priceTiers, priceTiers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,widthCm,heightCm,const DeepCollectionEquality().hash(priceTiers));

@override
String toString() {
  return 'ProductVariant(id: $id, label: $label, widthCm: $widthCm, heightCm: $heightCm, priceTiers: $priceTiers)';
}


}

/// @nodoc
abstract mixin class $ProductVariantCopyWith<$Res>  {
  factory $ProductVariantCopyWith(ProductVariant value, $Res Function(ProductVariant) _then) = _$ProductVariantCopyWithImpl;
@useResult
$Res call({
 int id, String label,@JsonKey(name: 'width_cm') num? widthCm,@JsonKey(name: 'height_cm') num? heightCm,@JsonKey(name: 'price_tiers') List<PriceTier> priceTiers
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? widthCm = freezed,Object? heightCm = freezed,Object? priceTiers = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,widthCm: freezed == widthCm ? _self.widthCm : widthCm // ignore: cast_nullable_to_non_nullable
as num?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as num?,priceTiers: null == priceTiers ? _self.priceTiers : priceTiers // ignore: cast_nullable_to_non_nullable
as List<PriceTier>,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String label, @JsonKey(name: 'width_cm')  num? widthCm, @JsonKey(name: 'height_cm')  num? heightCm, @JsonKey(name: 'price_tiers')  List<PriceTier> priceTiers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductVariant() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String label, @JsonKey(name: 'width_cm')  num? widthCm, @JsonKey(name: 'height_cm')  num? heightCm, @JsonKey(name: 'price_tiers')  List<PriceTier> priceTiers)  $default,) {final _that = this;
switch (_that) {
case _ProductVariant():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String label, @JsonKey(name: 'width_cm')  num? widthCm, @JsonKey(name: 'height_cm')  num? heightCm, @JsonKey(name: 'price_tiers')  List<PriceTier> priceTiers)?  $default,) {final _that = this;
switch (_that) {
case _ProductVariant() when $default != null:
return $default(_that.id,_that.label,_that.widthCm,_that.heightCm,_that.priceTiers);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductVariant implements ProductVariant {
  const _ProductVariant({required this.id, required this.label, @JsonKey(name: 'width_cm') this.widthCm, @JsonKey(name: 'height_cm') this.heightCm, @JsonKey(name: 'price_tiers') final  List<PriceTier> priceTiers = const <PriceTier>[]}): _priceTiers = priceTiers;
  factory _ProductVariant.fromJson(Map<String, dynamic> json) => _$ProductVariantFromJson(json);

@override final  int id;
/// «25*35» — what the customer picks from.
@override final  String label;
@override@JsonKey(name: 'width_cm') final  num? widthCm;
@override@JsonKey(name: 'height_cm') final  num? heightCm;
 final  List<PriceTier> _priceTiers;
@override@JsonKey(name: 'price_tiers') List<PriceTier> get priceTiers {
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductVariant&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.widthCm, widthCm) || other.widthCm == widthCm)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&const DeepCollectionEquality().equals(other._priceTiers, _priceTiers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label,widthCm,heightCm,const DeepCollectionEquality().hash(_priceTiers));

@override
String toString() {
  return 'ProductVariant(id: $id, label: $label, widthCm: $widthCm, heightCm: $heightCm, priceTiers: $priceTiers)';
}


}

/// @nodoc
abstract mixin class _$ProductVariantCopyWith<$Res> implements $ProductVariantCopyWith<$Res> {
  factory _$ProductVariantCopyWith(_ProductVariant value, $Res Function(_ProductVariant) _then) = __$ProductVariantCopyWithImpl;
@override @useResult
$Res call({
 int id, String label,@JsonKey(name: 'width_cm') num? widthCm,@JsonKey(name: 'height_cm') num? heightCm,@JsonKey(name: 'price_tiers') List<PriceTier> priceTiers
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? widthCm = freezed,Object? heightCm = freezed,Object? priceTiers = null,}) {
  return _then(_ProductVariant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,widthCm: freezed == widthCm ? _self.widthCm : widthCm // ignore: cast_nullable_to_non_nullable
as num?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as num?,priceTiers: null == priceTiers ? _self._priceTiers : priceTiers // ignore: cast_nullable_to_non_nullable
as List<PriceTier>,
  ));
}


}


/// @nodoc
mixin _$ProductImage {

 int get id; String get url;@JsonKey(name: 'is_primary') bool get isPrimary;@JsonKey(name: 'alt_text') String? get altText;
/// Create a copy of ProductImage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductImageCopyWith<ProductImage> get copyWith => _$ProductImageCopyWithImpl<ProductImage>(this as ProductImage, _$identity);

  /// Serializes this ProductImage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductImage&&(identical(other.id, id) || other.id == id)&&(identical(other.url, url) || other.url == url)&&(identical(other.isPrimary, isPrimary) || other.isPrimary == isPrimary)&&(identical(other.altText, altText) || other.altText == altText));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,url,isPrimary,altText);

@override
String toString() {
  return 'ProductImage(id: $id, url: $url, isPrimary: $isPrimary, altText: $altText)';
}


}

/// @nodoc
abstract mixin class $ProductImageCopyWith<$Res>  {
  factory $ProductImageCopyWith(ProductImage value, $Res Function(ProductImage) _then) = _$ProductImageCopyWithImpl;
@useResult
$Res call({
 int id, String url,@JsonKey(name: 'is_primary') bool isPrimary,@JsonKey(name: 'alt_text') String? altText
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? url = null,Object? isPrimary = null,Object? altText = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,isPrimary: null == isPrimary ? _self.isPrimary : isPrimary // ignore: cast_nullable_to_non_nullable
as bool,altText: freezed == altText ? _self.altText : altText // ignore: cast_nullable_to_non_nullable
as String?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String url, @JsonKey(name: 'is_primary')  bool isPrimary, @JsonKey(name: 'alt_text')  String? altText)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductImage() when $default != null:
return $default(_that.id,_that.url,_that.isPrimary,_that.altText);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String url, @JsonKey(name: 'is_primary')  bool isPrimary, @JsonKey(name: 'alt_text')  String? altText)  $default,) {final _that = this;
switch (_that) {
case _ProductImage():
return $default(_that.id,_that.url,_that.isPrimary,_that.altText);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String url, @JsonKey(name: 'is_primary')  bool isPrimary, @JsonKey(name: 'alt_text')  String? altText)?  $default,) {final _that = this;
switch (_that) {
case _ProductImage() when $default != null:
return $default(_that.id,_that.url,_that.isPrimary,_that.altText);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductImage implements ProductImage {
  const _ProductImage({required this.id, required this.url, @JsonKey(name: 'is_primary') this.isPrimary = false, @JsonKey(name: 'alt_text') this.altText});
  factory _ProductImage.fromJson(Map<String, dynamic> json) => _$ProductImageFromJson(json);

@override final  int id;
@override final  String url;
@override@JsonKey(name: 'is_primary') final  bool isPrimary;
@override@JsonKey(name: 'alt_text') final  String? altText;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductImage&&(identical(other.id, id) || other.id == id)&&(identical(other.url, url) || other.url == url)&&(identical(other.isPrimary, isPrimary) || other.isPrimary == isPrimary)&&(identical(other.altText, altText) || other.altText == altText));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,url,isPrimary,altText);

@override
String toString() {
  return 'ProductImage(id: $id, url: $url, isPrimary: $isPrimary, altText: $altText)';
}


}

/// @nodoc
abstract mixin class _$ProductImageCopyWith<$Res> implements $ProductImageCopyWith<$Res> {
  factory _$ProductImageCopyWith(_ProductImage value, $Res Function(_ProductImage) _then) = __$ProductImageCopyWithImpl;
@override @useResult
$Res call({
 int id, String url,@JsonKey(name: 'is_primary') bool isPrimary,@JsonKey(name: 'alt_text') String? altText
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? url = null,Object? isPrimary = null,Object? altText = freezed,}) {
  return _then(_ProductImage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,isPrimary: null == isPrimary ? _self.isPrimary : isPrimary // ignore: cast_nullable_to_non_nullable
as bool,altText: freezed == altText ? _self.altText : altText // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Product {

 int get id; String get name;/// «P7» — what a person says out loud when they ring about it.
 String? get code; String? get slug; String? get description; List<String> get features;@JsonKey(name: 'product_category') ProductCategory? get category;@JsonKey(name: 'product_category_id') int? get categoryId;/// What the customer is charged by — piece, kilogram — with its Arabic beside it, so this
/// app keeps no translation table of its own.
@JsonKey(name: 'pricing_unit') String? get pricingUnit;@JsonKey(name: 'pricing_unit_label') String? get pricingUnitLabel;/// **Draw a price, or draw «اطلب عرض سعر».** The decided answer rather than the pricing mode
/// behind it — this app never learns what the modes are.
/// Which products this one may share an order with — **a token, not a reason.**
///
/// The server sends two of these and never says what they mean: «what the category means for
/// production is not on this side of the wall» — see `ClientProductResource`. Two products
/// may go in one basket when their tokens match, and this app never learns why they do.
///
/// Defaulted rather than required so an older server, or a product resource that omits it,
/// leaves every product in one basket instead of splitting the catalogue in two by accident.
/// The refusal that matters is the server's: `CreateOrder` throws
/// `OutsourcedLineCannotShareAnOrder` whatever any client believes.
@JsonKey(name: 'order_group') String get orderGroup;@JsonKey(name: 'has_listed_prices') bool get hasListedPrices;@JsonKey(name: 'min_order_quantity') String? get minOrderQuantity; List<ProductVariant> get variants; List<ProductImage> get images;
/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductCopyWith<Product> get copyWith => _$ProductCopyWithImpl<Product>(this as Product, _$identity);

  /// Serializes this Product to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Product&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.code, code) || other.code == code)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.features, features)&&(identical(other.category, category) || other.category == category)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.pricingUnit, pricingUnit) || other.pricingUnit == pricingUnit)&&(identical(other.pricingUnitLabel, pricingUnitLabel) || other.pricingUnitLabel == pricingUnitLabel)&&(identical(other.orderGroup, orderGroup) || other.orderGroup == orderGroup)&&(identical(other.hasListedPrices, hasListedPrices) || other.hasListedPrices == hasListedPrices)&&(identical(other.minOrderQuantity, minOrderQuantity) || other.minOrderQuantity == minOrderQuantity)&&const DeepCollectionEquality().equals(other.variants, variants)&&const DeepCollectionEquality().equals(other.images, images));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,code,slug,description,const DeepCollectionEquality().hash(features),category,categoryId,pricingUnit,pricingUnitLabel,orderGroup,hasListedPrices,minOrderQuantity,const DeepCollectionEquality().hash(variants),const DeepCollectionEquality().hash(images));

@override
String toString() {
  return 'Product(id: $id, name: $name, code: $code, slug: $slug, description: $description, features: $features, category: $category, categoryId: $categoryId, pricingUnit: $pricingUnit, pricingUnitLabel: $pricingUnitLabel, orderGroup: $orderGroup, hasListedPrices: $hasListedPrices, minOrderQuantity: $minOrderQuantity, variants: $variants, images: $images)';
}


}

/// @nodoc
abstract mixin class $ProductCopyWith<$Res>  {
  factory $ProductCopyWith(Product value, $Res Function(Product) _then) = _$ProductCopyWithImpl;
@useResult
$Res call({
 int id, String name, String? code, String? slug, String? description, List<String> features,@JsonKey(name: 'product_category') ProductCategory? category,@JsonKey(name: 'product_category_id') int? categoryId,@JsonKey(name: 'pricing_unit') String? pricingUnit,@JsonKey(name: 'pricing_unit_label') String? pricingUnitLabel,@JsonKey(name: 'order_group') String orderGroup,@JsonKey(name: 'has_listed_prices') bool hasListedPrices,@JsonKey(name: 'min_order_quantity') String? minOrderQuantity, List<ProductVariant> variants, List<ProductImage> images
});


$ProductCategoryCopyWith<$Res>? get category;

}
/// @nodoc
class _$ProductCopyWithImpl<$Res>
    implements $ProductCopyWith<$Res> {
  _$ProductCopyWithImpl(this._self, this._then);

  final Product _self;
  final $Res Function(Product) _then;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? code = freezed,Object? slug = freezed,Object? description = freezed,Object? features = null,Object? category = freezed,Object? categoryId = freezed,Object? pricingUnit = freezed,Object? pricingUnitLabel = freezed,Object? orderGroup = null,Object? hasListedPrices = null,Object? minOrderQuantity = freezed,Object? variants = null,Object? images = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,slug: freezed == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,features: null == features ? _self.features : features // ignore: cast_nullable_to_non_nullable
as List<String>,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ProductCategory?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int?,pricingUnit: freezed == pricingUnit ? _self.pricingUnit : pricingUnit // ignore: cast_nullable_to_non_nullable
as String?,pricingUnitLabel: freezed == pricingUnitLabel ? _self.pricingUnitLabel : pricingUnitLabel // ignore: cast_nullable_to_non_nullable
as String?,orderGroup: null == orderGroup ? _self.orderGroup : orderGroup // ignore: cast_nullable_to_non_nullable
as String,hasListedPrices: null == hasListedPrices ? _self.hasListedPrices : hasListedPrices // ignore: cast_nullable_to_non_nullable
as bool,minOrderQuantity: freezed == minOrderQuantity ? _self.minOrderQuantity : minOrderQuantity // ignore: cast_nullable_to_non_nullable
as String?,variants: null == variants ? _self.variants : variants // ignore: cast_nullable_to_non_nullable
as List<ProductVariant>,images: null == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as List<ProductImage>,
  ));
}
/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProductCategoryCopyWith<$Res>? get category {
    if (_self.category == null) {
    return null;
  }

  return $ProductCategoryCopyWith<$Res>(_self.category!, (value) {
    return _then(_self.copyWith(category: value));
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String? code,  String? slug,  String? description,  List<String> features, @JsonKey(name: 'product_category')  ProductCategory? category, @JsonKey(name: 'product_category_id')  int? categoryId, @JsonKey(name: 'pricing_unit')  String? pricingUnit, @JsonKey(name: 'pricing_unit_label')  String? pricingUnitLabel, @JsonKey(name: 'order_group')  String orderGroup, @JsonKey(name: 'has_listed_prices')  bool hasListedPrices, @JsonKey(name: 'min_order_quantity')  String? minOrderQuantity,  List<ProductVariant> variants,  List<ProductImage> images)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that.id,_that.name,_that.code,_that.slug,_that.description,_that.features,_that.category,_that.categoryId,_that.pricingUnit,_that.pricingUnitLabel,_that.orderGroup,_that.hasListedPrices,_that.minOrderQuantity,_that.variants,_that.images);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String? code,  String? slug,  String? description,  List<String> features, @JsonKey(name: 'product_category')  ProductCategory? category, @JsonKey(name: 'product_category_id')  int? categoryId, @JsonKey(name: 'pricing_unit')  String? pricingUnit, @JsonKey(name: 'pricing_unit_label')  String? pricingUnitLabel, @JsonKey(name: 'order_group')  String orderGroup, @JsonKey(name: 'has_listed_prices')  bool hasListedPrices, @JsonKey(name: 'min_order_quantity')  String? minOrderQuantity,  List<ProductVariant> variants,  List<ProductImage> images)  $default,) {final _that = this;
switch (_that) {
case _Product():
return $default(_that.id,_that.name,_that.code,_that.slug,_that.description,_that.features,_that.category,_that.categoryId,_that.pricingUnit,_that.pricingUnitLabel,_that.orderGroup,_that.hasListedPrices,_that.minOrderQuantity,_that.variants,_that.images);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String? code,  String? slug,  String? description,  List<String> features, @JsonKey(name: 'product_category')  ProductCategory? category, @JsonKey(name: 'product_category_id')  int? categoryId, @JsonKey(name: 'pricing_unit')  String? pricingUnit, @JsonKey(name: 'pricing_unit_label')  String? pricingUnitLabel, @JsonKey(name: 'order_group')  String orderGroup, @JsonKey(name: 'has_listed_prices')  bool hasListedPrices, @JsonKey(name: 'min_order_quantity')  String? minOrderQuantity,  List<ProductVariant> variants,  List<ProductImage> images)?  $default,) {final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that.id,_that.name,_that.code,_that.slug,_that.description,_that.features,_that.category,_that.categoryId,_that.pricingUnit,_that.pricingUnitLabel,_that.orderGroup,_that.hasListedPrices,_that.minOrderQuantity,_that.variants,_that.images);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Product implements Product {
  const _Product({required this.id, required this.name, this.code, this.slug, this.description, final  List<String> features = const <String>[], @JsonKey(name: 'product_category') this.category, @JsonKey(name: 'product_category_id') this.categoryId, @JsonKey(name: 'pricing_unit') this.pricingUnit, @JsonKey(name: 'pricing_unit_label') this.pricingUnitLabel, @JsonKey(name: 'order_group') this.orderGroup = 'shared', @JsonKey(name: 'has_listed_prices') this.hasListedPrices = true, @JsonKey(name: 'min_order_quantity') this.minOrderQuantity, final  List<ProductVariant> variants = const <ProductVariant>[], final  List<ProductImage> images = const <ProductImage>[]}): _features = features,_variants = variants,_images = images;
  factory _Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);

@override final  int id;
@override final  String name;
/// «P7» — what a person says out loud when they ring about it.
@override final  String? code;
@override final  String? slug;
@override final  String? description;
 final  List<String> _features;
@override@JsonKey() List<String> get features {
  if (_features is EqualUnmodifiableListView) return _features;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_features);
}

@override@JsonKey(name: 'product_category') final  ProductCategory? category;
@override@JsonKey(name: 'product_category_id') final  int? categoryId;
/// What the customer is charged by — piece, kilogram — with its Arabic beside it, so this
/// app keeps no translation table of its own.
@override@JsonKey(name: 'pricing_unit') final  String? pricingUnit;
@override@JsonKey(name: 'pricing_unit_label') final  String? pricingUnitLabel;
/// **Draw a price, or draw «اطلب عرض سعر».** The decided answer rather than the pricing mode
/// behind it — this app never learns what the modes are.
/// Which products this one may share an order with — **a token, not a reason.**
///
/// The server sends two of these and never says what they mean: «what the category means for
/// production is not on this side of the wall» — see `ClientProductResource`. Two products
/// may go in one basket when their tokens match, and this app never learns why they do.
///
/// Defaulted rather than required so an older server, or a product resource that omits it,
/// leaves every product in one basket instead of splitting the catalogue in two by accident.
/// The refusal that matters is the server's: `CreateOrder` throws
/// `OutsourcedLineCannotShareAnOrder` whatever any client believes.
@override@JsonKey(name: 'order_group') final  String orderGroup;
@override@JsonKey(name: 'has_listed_prices') final  bool hasListedPrices;
@override@JsonKey(name: 'min_order_quantity') final  String? minOrderQuantity;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Product&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.code, code) || other.code == code)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._features, _features)&&(identical(other.category, category) || other.category == category)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.pricingUnit, pricingUnit) || other.pricingUnit == pricingUnit)&&(identical(other.pricingUnitLabel, pricingUnitLabel) || other.pricingUnitLabel == pricingUnitLabel)&&(identical(other.orderGroup, orderGroup) || other.orderGroup == orderGroup)&&(identical(other.hasListedPrices, hasListedPrices) || other.hasListedPrices == hasListedPrices)&&(identical(other.minOrderQuantity, minOrderQuantity) || other.minOrderQuantity == minOrderQuantity)&&const DeepCollectionEquality().equals(other._variants, _variants)&&const DeepCollectionEquality().equals(other._images, _images));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,code,slug,description,const DeepCollectionEquality().hash(_features),category,categoryId,pricingUnit,pricingUnitLabel,orderGroup,hasListedPrices,minOrderQuantity,const DeepCollectionEquality().hash(_variants),const DeepCollectionEquality().hash(_images));

@override
String toString() {
  return 'Product(id: $id, name: $name, code: $code, slug: $slug, description: $description, features: $features, category: $category, categoryId: $categoryId, pricingUnit: $pricingUnit, pricingUnitLabel: $pricingUnitLabel, orderGroup: $orderGroup, hasListedPrices: $hasListedPrices, minOrderQuantity: $minOrderQuantity, variants: $variants, images: $images)';
}


}

/// @nodoc
abstract mixin class _$ProductCopyWith<$Res> implements $ProductCopyWith<$Res> {
  factory _$ProductCopyWith(_Product value, $Res Function(_Product) _then) = __$ProductCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String? code, String? slug, String? description, List<String> features,@JsonKey(name: 'product_category') ProductCategory? category,@JsonKey(name: 'product_category_id') int? categoryId,@JsonKey(name: 'pricing_unit') String? pricingUnit,@JsonKey(name: 'pricing_unit_label') String? pricingUnitLabel,@JsonKey(name: 'order_group') String orderGroup,@JsonKey(name: 'has_listed_prices') bool hasListedPrices,@JsonKey(name: 'min_order_quantity') String? minOrderQuantity, List<ProductVariant> variants, List<ProductImage> images
});


@override $ProductCategoryCopyWith<$Res>? get category;

}
/// @nodoc
class __$ProductCopyWithImpl<$Res>
    implements _$ProductCopyWith<$Res> {
  __$ProductCopyWithImpl(this._self, this._then);

  final _Product _self;
  final $Res Function(_Product) _then;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? code = freezed,Object? slug = freezed,Object? description = freezed,Object? features = null,Object? category = freezed,Object? categoryId = freezed,Object? pricingUnit = freezed,Object? pricingUnitLabel = freezed,Object? orderGroup = null,Object? hasListedPrices = null,Object? minOrderQuantity = freezed,Object? variants = null,Object? images = null,}) {
  return _then(_Product(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,slug: freezed == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,features: null == features ? _self._features : features // ignore: cast_nullable_to_non_nullable
as List<String>,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ProductCategory?,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int?,pricingUnit: freezed == pricingUnit ? _self.pricingUnit : pricingUnit // ignore: cast_nullable_to_non_nullable
as String?,pricingUnitLabel: freezed == pricingUnitLabel ? _self.pricingUnitLabel : pricingUnitLabel // ignore: cast_nullable_to_non_nullable
as String?,orderGroup: null == orderGroup ? _self.orderGroup : orderGroup // ignore: cast_nullable_to_non_nullable
as String,hasListedPrices: null == hasListedPrices ? _self.hasListedPrices : hasListedPrices // ignore: cast_nullable_to_non_nullable
as bool,minOrderQuantity: freezed == minOrderQuantity ? _self.minOrderQuantity : minOrderQuantity // ignore: cast_nullable_to_non_nullable
as String?,variants: null == variants ? _self._variants : variants // ignore: cast_nullable_to_non_nullable
as List<ProductVariant>,images: null == images ? _self._images : images // ignore: cast_nullable_to_non_nullable
as List<ProductImage>,
  ));
}

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProductCategoryCopyWith<$Res>? get category {
    if (_self.category == null) {
    return null;
  }

  return $ProductCategoryCopyWith<$Res>(_self.category!, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}


/// @nodoc
mixin _$PriceQuote {

 String get quantity;@JsonKey(name: 'unit_price') String get unitPrice; String get total; String? get unit;@JsonKey(name: 'unit_label') String? get unitLabel;@JsonKey(name: 'applied_tier_min_quantity') String? get appliedTierMinQuantity;/// The saving still on the table, so the screen can say «اطلب ٤٧ أكثر وينزل سعر الوحدة».
/// Null when the customer is already on the best rate.
@JsonKey(name: 'next_tier') NextTier? get nextTier;
/// Create a copy of PriceQuote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PriceQuoteCopyWith<PriceQuote> get copyWith => _$PriceQuoteCopyWithImpl<PriceQuote>(this as PriceQuote, _$identity);

  /// Serializes this PriceQuote to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PriceQuote&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.total, total) || other.total == total)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.unitLabel, unitLabel) || other.unitLabel == unitLabel)&&(identical(other.appliedTierMinQuantity, appliedTierMinQuantity) || other.appliedTierMinQuantity == appliedTierMinQuantity)&&(identical(other.nextTier, nextTier) || other.nextTier == nextTier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,quantity,unitPrice,total,unit,unitLabel,appliedTierMinQuantity,nextTier);

@override
String toString() {
  return 'PriceQuote(quantity: $quantity, unitPrice: $unitPrice, total: $total, unit: $unit, unitLabel: $unitLabel, appliedTierMinQuantity: $appliedTierMinQuantity, nextTier: $nextTier)';
}


}

/// @nodoc
abstract mixin class $PriceQuoteCopyWith<$Res>  {
  factory $PriceQuoteCopyWith(PriceQuote value, $Res Function(PriceQuote) _then) = _$PriceQuoteCopyWithImpl;
@useResult
$Res call({
 String quantity,@JsonKey(name: 'unit_price') String unitPrice, String total, String? unit,@JsonKey(name: 'unit_label') String? unitLabel,@JsonKey(name: 'applied_tier_min_quantity') String? appliedTierMinQuantity,@JsonKey(name: 'next_tier') NextTier? nextTier
});


$NextTierCopyWith<$Res>? get nextTier;

}
/// @nodoc
class _$PriceQuoteCopyWithImpl<$Res>
    implements $PriceQuoteCopyWith<$Res> {
  _$PriceQuoteCopyWithImpl(this._self, this._then);

  final PriceQuote _self;
  final $Res Function(PriceQuote) _then;

/// Create a copy of PriceQuote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? quantity = null,Object? unitPrice = null,Object? total = null,Object? unit = freezed,Object? unitLabel = freezed,Object? appliedTierMinQuantity = freezed,Object? nextTier = freezed,}) {
  return _then(_self.copyWith(
quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,unitLabel: freezed == unitLabel ? _self.unitLabel : unitLabel // ignore: cast_nullable_to_non_nullable
as String?,appliedTierMinQuantity: freezed == appliedTierMinQuantity ? _self.appliedTierMinQuantity : appliedTierMinQuantity // ignore: cast_nullable_to_non_nullable
as String?,nextTier: freezed == nextTier ? _self.nextTier : nextTier // ignore: cast_nullable_to_non_nullable
as NextTier?,
  ));
}
/// Create a copy of PriceQuote
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NextTierCopyWith<$Res>? get nextTier {
    if (_self.nextTier == null) {
    return null;
  }

  return $NextTierCopyWith<$Res>(_self.nextTier!, (value) {
    return _then(_self.copyWith(nextTier: value));
  });
}
}


/// Adds pattern-matching-related methods to [PriceQuote].
extension PriceQuotePatterns on PriceQuote {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PriceQuote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PriceQuote() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PriceQuote value)  $default,){
final _that = this;
switch (_that) {
case _PriceQuote():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PriceQuote value)?  $default,){
final _that = this;
switch (_that) {
case _PriceQuote() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String quantity, @JsonKey(name: 'unit_price')  String unitPrice,  String total,  String? unit, @JsonKey(name: 'unit_label')  String? unitLabel, @JsonKey(name: 'applied_tier_min_quantity')  String? appliedTierMinQuantity, @JsonKey(name: 'next_tier')  NextTier? nextTier)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PriceQuote() when $default != null:
return $default(_that.quantity,_that.unitPrice,_that.total,_that.unit,_that.unitLabel,_that.appliedTierMinQuantity,_that.nextTier);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String quantity, @JsonKey(name: 'unit_price')  String unitPrice,  String total,  String? unit, @JsonKey(name: 'unit_label')  String? unitLabel, @JsonKey(name: 'applied_tier_min_quantity')  String? appliedTierMinQuantity, @JsonKey(name: 'next_tier')  NextTier? nextTier)  $default,) {final _that = this;
switch (_that) {
case _PriceQuote():
return $default(_that.quantity,_that.unitPrice,_that.total,_that.unit,_that.unitLabel,_that.appliedTierMinQuantity,_that.nextTier);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String quantity, @JsonKey(name: 'unit_price')  String unitPrice,  String total,  String? unit, @JsonKey(name: 'unit_label')  String? unitLabel, @JsonKey(name: 'applied_tier_min_quantity')  String? appliedTierMinQuantity, @JsonKey(name: 'next_tier')  NextTier? nextTier)?  $default,) {final _that = this;
switch (_that) {
case _PriceQuote() when $default != null:
return $default(_that.quantity,_that.unitPrice,_that.total,_that.unit,_that.unitLabel,_that.appliedTierMinQuantity,_that.nextTier);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PriceQuote implements PriceQuote {
  const _PriceQuote({required this.quantity, @JsonKey(name: 'unit_price') required this.unitPrice, required this.total, this.unit, @JsonKey(name: 'unit_label') this.unitLabel, @JsonKey(name: 'applied_tier_min_quantity') this.appliedTierMinQuantity, @JsonKey(name: 'next_tier') this.nextTier});
  factory _PriceQuote.fromJson(Map<String, dynamic> json) => _$PriceQuoteFromJson(json);

@override final  String quantity;
@override@JsonKey(name: 'unit_price') final  String unitPrice;
@override final  String total;
@override final  String? unit;
@override@JsonKey(name: 'unit_label') final  String? unitLabel;
@override@JsonKey(name: 'applied_tier_min_quantity') final  String? appliedTierMinQuantity;
/// The saving still on the table, so the screen can say «اطلب ٤٧ أكثر وينزل سعر الوحدة».
/// Null when the customer is already on the best rate.
@override@JsonKey(name: 'next_tier') final  NextTier? nextTier;

/// Create a copy of PriceQuote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PriceQuoteCopyWith<_PriceQuote> get copyWith => __$PriceQuoteCopyWithImpl<_PriceQuote>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PriceQuoteToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PriceQuote&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.total, total) || other.total == total)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.unitLabel, unitLabel) || other.unitLabel == unitLabel)&&(identical(other.appliedTierMinQuantity, appliedTierMinQuantity) || other.appliedTierMinQuantity == appliedTierMinQuantity)&&(identical(other.nextTier, nextTier) || other.nextTier == nextTier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,quantity,unitPrice,total,unit,unitLabel,appliedTierMinQuantity,nextTier);

@override
String toString() {
  return 'PriceQuote(quantity: $quantity, unitPrice: $unitPrice, total: $total, unit: $unit, unitLabel: $unitLabel, appliedTierMinQuantity: $appliedTierMinQuantity, nextTier: $nextTier)';
}


}

/// @nodoc
abstract mixin class _$PriceQuoteCopyWith<$Res> implements $PriceQuoteCopyWith<$Res> {
  factory _$PriceQuoteCopyWith(_PriceQuote value, $Res Function(_PriceQuote) _then) = __$PriceQuoteCopyWithImpl;
@override @useResult
$Res call({
 String quantity,@JsonKey(name: 'unit_price') String unitPrice, String total, String? unit,@JsonKey(name: 'unit_label') String? unitLabel,@JsonKey(name: 'applied_tier_min_quantity') String? appliedTierMinQuantity,@JsonKey(name: 'next_tier') NextTier? nextTier
});


@override $NextTierCopyWith<$Res>? get nextTier;

}
/// @nodoc
class __$PriceQuoteCopyWithImpl<$Res>
    implements _$PriceQuoteCopyWith<$Res> {
  __$PriceQuoteCopyWithImpl(this._self, this._then);

  final _PriceQuote _self;
  final $Res Function(_PriceQuote) _then;

/// Create a copy of PriceQuote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? quantity = null,Object? unitPrice = null,Object? total = null,Object? unit = freezed,Object? unitLabel = freezed,Object? appliedTierMinQuantity = freezed,Object? nextTier = freezed,}) {
  return _then(_PriceQuote(
quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,unitLabel: freezed == unitLabel ? _self.unitLabel : unitLabel // ignore: cast_nullable_to_non_nullable
as String?,appliedTierMinQuantity: freezed == appliedTierMinQuantity ? _self.appliedTierMinQuantity : appliedTierMinQuantity // ignore: cast_nullable_to_non_nullable
as String?,nextTier: freezed == nextTier ? _self.nextTier : nextTier // ignore: cast_nullable_to_non_nullable
as NextTier?,
  ));
}

/// Create a copy of PriceQuote
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NextTierCopyWith<$Res>? get nextTier {
    if (_self.nextTier == null) {
    return null;
  }

  return $NextTierCopyWith<$Res>(_self.nextTier!, (value) {
    return _then(_self.copyWith(nextTier: value));
  });
}
}


/// @nodoc
mixin _$NextTier {

@JsonKey(name: 'min_quantity') String get minQuantity;@JsonKey(name: 'unit_price') String get unitPrice;@JsonKey(name: 'quantity_to_reach') String? get quantityToReach;
/// Create a copy of NextTier
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NextTierCopyWith<NextTier> get copyWith => _$NextTierCopyWithImpl<NextTier>(this as NextTier, _$identity);

  /// Serializes this NextTier to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NextTier&&(identical(other.minQuantity, minQuantity) || other.minQuantity == minQuantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.quantityToReach, quantityToReach) || other.quantityToReach == quantityToReach));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,minQuantity,unitPrice,quantityToReach);

@override
String toString() {
  return 'NextTier(minQuantity: $minQuantity, unitPrice: $unitPrice, quantityToReach: $quantityToReach)';
}


}

/// @nodoc
abstract mixin class $NextTierCopyWith<$Res>  {
  factory $NextTierCopyWith(NextTier value, $Res Function(NextTier) _then) = _$NextTierCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'min_quantity') String minQuantity,@JsonKey(name: 'unit_price') String unitPrice,@JsonKey(name: 'quantity_to_reach') String? quantityToReach
});




}
/// @nodoc
class _$NextTierCopyWithImpl<$Res>
    implements $NextTierCopyWith<$Res> {
  _$NextTierCopyWithImpl(this._self, this._then);

  final NextTier _self;
  final $Res Function(NextTier) _then;

/// Create a copy of NextTier
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? minQuantity = null,Object? unitPrice = null,Object? quantityToReach = freezed,}) {
  return _then(_self.copyWith(
minQuantity: null == minQuantity ? _self.minQuantity : minQuantity // ignore: cast_nullable_to_non_nullable
as String,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,quantityToReach: freezed == quantityToReach ? _self.quantityToReach : quantityToReach // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [NextTier].
extension NextTierPatterns on NextTier {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NextTier value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NextTier() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NextTier value)  $default,){
final _that = this;
switch (_that) {
case _NextTier():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NextTier value)?  $default,){
final _that = this;
switch (_that) {
case _NextTier() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'min_quantity')  String minQuantity, @JsonKey(name: 'unit_price')  String unitPrice, @JsonKey(name: 'quantity_to_reach')  String? quantityToReach)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NextTier() when $default != null:
return $default(_that.minQuantity,_that.unitPrice,_that.quantityToReach);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'min_quantity')  String minQuantity, @JsonKey(name: 'unit_price')  String unitPrice, @JsonKey(name: 'quantity_to_reach')  String? quantityToReach)  $default,) {final _that = this;
switch (_that) {
case _NextTier():
return $default(_that.minQuantity,_that.unitPrice,_that.quantityToReach);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'min_quantity')  String minQuantity, @JsonKey(name: 'unit_price')  String unitPrice, @JsonKey(name: 'quantity_to_reach')  String? quantityToReach)?  $default,) {final _that = this;
switch (_that) {
case _NextTier() when $default != null:
return $default(_that.minQuantity,_that.unitPrice,_that.quantityToReach);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NextTier implements NextTier {
  const _NextTier({@JsonKey(name: 'min_quantity') required this.minQuantity, @JsonKey(name: 'unit_price') required this.unitPrice, @JsonKey(name: 'quantity_to_reach') this.quantityToReach});
  factory _NextTier.fromJson(Map<String, dynamic> json) => _$NextTierFromJson(json);

@override@JsonKey(name: 'min_quantity') final  String minQuantity;
@override@JsonKey(name: 'unit_price') final  String unitPrice;
@override@JsonKey(name: 'quantity_to_reach') final  String? quantityToReach;

/// Create a copy of NextTier
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NextTierCopyWith<_NextTier> get copyWith => __$NextTierCopyWithImpl<_NextTier>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NextTierToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NextTier&&(identical(other.minQuantity, minQuantity) || other.minQuantity == minQuantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.quantityToReach, quantityToReach) || other.quantityToReach == quantityToReach));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,minQuantity,unitPrice,quantityToReach);

@override
String toString() {
  return 'NextTier(minQuantity: $minQuantity, unitPrice: $unitPrice, quantityToReach: $quantityToReach)';
}


}

/// @nodoc
abstract mixin class _$NextTierCopyWith<$Res> implements $NextTierCopyWith<$Res> {
  factory _$NextTierCopyWith(_NextTier value, $Res Function(_NextTier) _then) = __$NextTierCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'min_quantity') String minQuantity,@JsonKey(name: 'unit_price') String unitPrice,@JsonKey(name: 'quantity_to_reach') String? quantityToReach
});




}
/// @nodoc
class __$NextTierCopyWithImpl<$Res>
    implements _$NextTierCopyWith<$Res> {
  __$NextTierCopyWithImpl(this._self, this._then);

  final _NextTier _self;
  final $Res Function(_NextTier) _then;

/// Create a copy of NextTier
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? minQuantity = null,Object? unitPrice = null,Object? quantityToReach = freezed,}) {
  return _then(_NextTier(
minQuantity: null == minQuantity ? _self.minQuantity : minQuantity // ignore: cast_nullable_to_non_nullable
as String,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,quantityToReach: freezed == quantityToReach ? _self.quantityToReach : quantityToReach // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
