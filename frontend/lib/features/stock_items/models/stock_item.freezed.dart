// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stock_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StockItem {

 int get id;/// `S7` — server-allocated and never settable. **What replaces the product thumbnail on a
/// stock row**: a pile is not one product's, so a picture of either of the two products
/// sharing it would be picking one arbitrarily and telling the storekeeper the wrong thing.
/// A code reads well on a row and is the one thing safe to read down a phone line.
 String get code;/// The material's name, without the size. [displayName] is what gets drawn.
 String get name;/// Null for something counted without dimensions — a roll, an ink. **The two travel
/// together**: half a size is not a size, and the server refuses a width with no height.
@JsonKey(name: 'width_cm') int? get widthCm;@JsonKey(name: 'height_cm') int? get heightCm;/// The material this is a size of, or null for a standalone shelf. **Always present** — a
/// plain column, not a relation — so it answers even where [group] does not.
@JsonKey(name: 'stock_item_group_id') int? get stockItemGroupId;/// The material itself, when a caller asked for it.
///
/// **Absent from every response the API sends today**, and modelled all the same: it is
/// `whenLoaded('stockItemGroup')` on the resource and no query eager-loads it on a stock
/// item. Null therefore means «لم يُطلب», not «لا مادة له» — [stockItemGroupId] is the field
/// that answers that. Anything needing the material's name today reads it from the group's
/// own endpoint.
@JsonKey(name: 'stock_item_group') StockItemGroupRef? get group;/// «كيس شحن 25*35» — composed **server-side** from the name and the size.
///
/// **Rendered as sent, never rebuilt here.** The separator is a bare `*` with no spaces, an
/// unsized item's display name is just its name, and the shortfall message an order is
/// refused with quotes this exact string. A second implementation in Dart would drift from
/// it, and the first screen to notice would be one comparing a refusal to a list.
@JsonKey(name: 'display_name') String get displayName;/// What **this** shelf is counted in — independent of any product's `pricing_unit`.
@JsonKey(unknownEnumValue: StockUnit.unknown) StockUnit get unit;/// The server's Arabic for [unit]. Drawn as sent, so a unit added to the backend tomorrow
/// still reads right without this app being rebuilt.
@JsonKey(name: 'unit_label') String get unitLabel; String? get description;@JsonKey(name: 'is_active') bool get isActive;@JsonKey(name: 'sort_order') int get sortOrder;/// How many product sizes draw on this shelf — **the number that makes the sharing
/// visible**, and the one that says whether deleting will be refused.
///
/// Nullable because it is `whenCounted('variants')`: the list and the show endpoint carry it,
/// and create, update, set-unit and the sizes nested inside a group's payload do not. Null is
/// «لم يُحسب», never zero — see [sharedByLabel], which draws nothing rather than «لا مقاس».
@JsonKey(name: 'variants_count') int? get variantsCount;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of StockItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StockItemCopyWith<StockItem> get copyWith => _$StockItemCopyWithImpl<StockItem>(this as StockItem, _$identity);

  /// Serializes this StockItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StockItem&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.widthCm, widthCm) || other.widthCm == widthCm)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.stockItemGroupId, stockItemGroupId) || other.stockItemGroupId == stockItemGroupId)&&(identical(other.group, group) || other.group == group)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.unitLabel, unitLabel) || other.unitLabel == unitLabel)&&(identical(other.description, description) || other.description == description)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.variantsCount, variantsCount) || other.variantsCount == variantsCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name,widthCm,heightCm,stockItemGroupId,group,displayName,unit,unitLabel,description,isActive,sortOrder,variantsCount,createdAt,updatedAt);

@override
String toString() {
  return 'StockItem(id: $id, code: $code, name: $name, widthCm: $widthCm, heightCm: $heightCm, stockItemGroupId: $stockItemGroupId, group: $group, displayName: $displayName, unit: $unit, unitLabel: $unitLabel, description: $description, isActive: $isActive, sortOrder: $sortOrder, variantsCount: $variantsCount, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $StockItemCopyWith<$Res>  {
  factory $StockItemCopyWith(StockItem value, $Res Function(StockItem) _then) = _$StockItemCopyWithImpl;
@useResult
$Res call({
 int id, String code, String name,@JsonKey(name: 'width_cm') int? widthCm,@JsonKey(name: 'height_cm') int? heightCm,@JsonKey(name: 'stock_item_group_id') int? stockItemGroupId,@JsonKey(name: 'stock_item_group') StockItemGroupRef? group,@JsonKey(name: 'display_name') String displayName,@JsonKey(unknownEnumValue: StockUnit.unknown) StockUnit unit,@JsonKey(name: 'unit_label') String unitLabel, String? description,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'sort_order') int sortOrder,@JsonKey(name: 'variants_count') int? variantsCount,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});


$StockItemGroupRefCopyWith<$Res>? get group;

}
/// @nodoc
class _$StockItemCopyWithImpl<$Res>
    implements $StockItemCopyWith<$Res> {
  _$StockItemCopyWithImpl(this._self, this._then);

  final StockItem _self;
  final $Res Function(StockItem) _then;

/// Create a copy of StockItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? name = null,Object? widthCm = freezed,Object? heightCm = freezed,Object? stockItemGroupId = freezed,Object? group = freezed,Object? displayName = null,Object? unit = null,Object? unitLabel = null,Object? description = freezed,Object? isActive = null,Object? sortOrder = null,Object? variantsCount = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,widthCm: freezed == widthCm ? _self.widthCm : widthCm // ignore: cast_nullable_to_non_nullable
as int?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as int?,stockItemGroupId: freezed == stockItemGroupId ? _self.stockItemGroupId : stockItemGroupId // ignore: cast_nullable_to_non_nullable
as int?,group: freezed == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as StockItemGroupRef?,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as StockUnit,unitLabel: null == unitLabel ? _self.unitLabel : unitLabel // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,variantsCount: freezed == variantsCount ? _self.variantsCount : variantsCount // ignore: cast_nullable_to_non_nullable
as int?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of StockItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StockItemGroupRefCopyWith<$Res>? get group {
    if (_self.group == null) {
    return null;
  }

  return $StockItemGroupRefCopyWith<$Res>(_self.group!, (value) {
    return _then(_self.copyWith(group: value));
  });
}
}


/// Adds pattern-matching-related methods to [StockItem].
extension StockItemPatterns on StockItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StockItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StockItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StockItem value)  $default,){
final _that = this;
switch (_that) {
case _StockItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StockItem value)?  $default,){
final _that = this;
switch (_that) {
case _StockItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String code,  String name, @JsonKey(name: 'width_cm')  int? widthCm, @JsonKey(name: 'height_cm')  int? heightCm, @JsonKey(name: 'stock_item_group_id')  int? stockItemGroupId, @JsonKey(name: 'stock_item_group')  StockItemGroupRef? group, @JsonKey(name: 'display_name')  String displayName, @JsonKey(unknownEnumValue: StockUnit.unknown)  StockUnit unit, @JsonKey(name: 'unit_label')  String unitLabel,  String? description, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'sort_order')  int sortOrder, @JsonKey(name: 'variants_count')  int? variantsCount, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StockItem() when $default != null:
return $default(_that.id,_that.code,_that.name,_that.widthCm,_that.heightCm,_that.stockItemGroupId,_that.group,_that.displayName,_that.unit,_that.unitLabel,_that.description,_that.isActive,_that.sortOrder,_that.variantsCount,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String code,  String name, @JsonKey(name: 'width_cm')  int? widthCm, @JsonKey(name: 'height_cm')  int? heightCm, @JsonKey(name: 'stock_item_group_id')  int? stockItemGroupId, @JsonKey(name: 'stock_item_group')  StockItemGroupRef? group, @JsonKey(name: 'display_name')  String displayName, @JsonKey(unknownEnumValue: StockUnit.unknown)  StockUnit unit, @JsonKey(name: 'unit_label')  String unitLabel,  String? description, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'sort_order')  int sortOrder, @JsonKey(name: 'variants_count')  int? variantsCount, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _StockItem():
return $default(_that.id,_that.code,_that.name,_that.widthCm,_that.heightCm,_that.stockItemGroupId,_that.group,_that.displayName,_that.unit,_that.unitLabel,_that.description,_that.isActive,_that.sortOrder,_that.variantsCount,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String code,  String name, @JsonKey(name: 'width_cm')  int? widthCm, @JsonKey(name: 'height_cm')  int? heightCm, @JsonKey(name: 'stock_item_group_id')  int? stockItemGroupId, @JsonKey(name: 'stock_item_group')  StockItemGroupRef? group, @JsonKey(name: 'display_name')  String displayName, @JsonKey(unknownEnumValue: StockUnit.unknown)  StockUnit unit, @JsonKey(name: 'unit_label')  String unitLabel,  String? description, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'sort_order')  int sortOrder, @JsonKey(name: 'variants_count')  int? variantsCount, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _StockItem() when $default != null:
return $default(_that.id,_that.code,_that.name,_that.widthCm,_that.heightCm,_that.stockItemGroupId,_that.group,_that.displayName,_that.unit,_that.unitLabel,_that.description,_that.isActive,_that.sortOrder,_that.variantsCount,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StockItem extends StockItem {
  const _StockItem({required this.id, required this.code, required this.name, @JsonKey(name: 'width_cm') this.widthCm, @JsonKey(name: 'height_cm') this.heightCm, @JsonKey(name: 'stock_item_group_id') this.stockItemGroupId, @JsonKey(name: 'stock_item_group') this.group, @JsonKey(name: 'display_name') required this.displayName, @JsonKey(unknownEnumValue: StockUnit.unknown) required this.unit, @JsonKey(name: 'unit_label') required this.unitLabel, this.description, @JsonKey(name: 'is_active') required this.isActive, @JsonKey(name: 'sort_order') required this.sortOrder, @JsonKey(name: 'variants_count') this.variantsCount, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt}): super._();
  factory _StockItem.fromJson(Map<String, dynamic> json) => _$StockItemFromJson(json);

@override final  int id;
/// `S7` — server-allocated and never settable. **What replaces the product thumbnail on a
/// stock row**: a pile is not one product's, so a picture of either of the two products
/// sharing it would be picking one arbitrarily and telling the storekeeper the wrong thing.
/// A code reads well on a row and is the one thing safe to read down a phone line.
@override final  String code;
/// The material's name, without the size. [displayName] is what gets drawn.
@override final  String name;
/// Null for something counted without dimensions — a roll, an ink. **The two travel
/// together**: half a size is not a size, and the server refuses a width with no height.
@override@JsonKey(name: 'width_cm') final  int? widthCm;
@override@JsonKey(name: 'height_cm') final  int? heightCm;
/// The material this is a size of, or null for a standalone shelf. **Always present** — a
/// plain column, not a relation — so it answers even where [group] does not.
@override@JsonKey(name: 'stock_item_group_id') final  int? stockItemGroupId;
/// The material itself, when a caller asked for it.
///
/// **Absent from every response the API sends today**, and modelled all the same: it is
/// `whenLoaded('stockItemGroup')` on the resource and no query eager-loads it on a stock
/// item. Null therefore means «لم يُطلب», not «لا مادة له» — [stockItemGroupId] is the field
/// that answers that. Anything needing the material's name today reads it from the group's
/// own endpoint.
@override@JsonKey(name: 'stock_item_group') final  StockItemGroupRef? group;
/// «كيس شحن 25*35» — composed **server-side** from the name and the size.
///
/// **Rendered as sent, never rebuilt here.** The separator is a bare `*` with no spaces, an
/// unsized item's display name is just its name, and the shortfall message an order is
/// refused with quotes this exact string. A second implementation in Dart would drift from
/// it, and the first screen to notice would be one comparing a refusal to a list.
@override@JsonKey(name: 'display_name') final  String displayName;
/// What **this** shelf is counted in — independent of any product's `pricing_unit`.
@override@JsonKey(unknownEnumValue: StockUnit.unknown) final  StockUnit unit;
/// The server's Arabic for [unit]. Drawn as sent, so a unit added to the backend tomorrow
/// still reads right without this app being rebuilt.
@override@JsonKey(name: 'unit_label') final  String unitLabel;
@override final  String? description;
@override@JsonKey(name: 'is_active') final  bool isActive;
@override@JsonKey(name: 'sort_order') final  int sortOrder;
/// How many product sizes draw on this shelf — **the number that makes the sharing
/// visible**, and the one that says whether deleting will be refused.
///
/// Nullable because it is `whenCounted('variants')`: the list and the show endpoint carry it,
/// and create, update, set-unit and the sizes nested inside a group's payload do not. Null is
/// «لم يُحسب», never zero — see [sharedByLabel], which draws nothing rather than «لا مقاس».
@override@JsonKey(name: 'variants_count') final  int? variantsCount;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;

/// Create a copy of StockItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StockItemCopyWith<_StockItem> get copyWith => __$StockItemCopyWithImpl<_StockItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StockItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StockItem&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.widthCm, widthCm) || other.widthCm == widthCm)&&(identical(other.heightCm, heightCm) || other.heightCm == heightCm)&&(identical(other.stockItemGroupId, stockItemGroupId) || other.stockItemGroupId == stockItemGroupId)&&(identical(other.group, group) || other.group == group)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.unitLabel, unitLabel) || other.unitLabel == unitLabel)&&(identical(other.description, description) || other.description == description)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.variantsCount, variantsCount) || other.variantsCount == variantsCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name,widthCm,heightCm,stockItemGroupId,group,displayName,unit,unitLabel,description,isActive,sortOrder,variantsCount,createdAt,updatedAt);

@override
String toString() {
  return 'StockItem(id: $id, code: $code, name: $name, widthCm: $widthCm, heightCm: $heightCm, stockItemGroupId: $stockItemGroupId, group: $group, displayName: $displayName, unit: $unit, unitLabel: $unitLabel, description: $description, isActive: $isActive, sortOrder: $sortOrder, variantsCount: $variantsCount, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$StockItemCopyWith<$Res> implements $StockItemCopyWith<$Res> {
  factory _$StockItemCopyWith(_StockItem value, $Res Function(_StockItem) _then) = __$StockItemCopyWithImpl;
@override @useResult
$Res call({
 int id, String code, String name,@JsonKey(name: 'width_cm') int? widthCm,@JsonKey(name: 'height_cm') int? heightCm,@JsonKey(name: 'stock_item_group_id') int? stockItemGroupId,@JsonKey(name: 'stock_item_group') StockItemGroupRef? group,@JsonKey(name: 'display_name') String displayName,@JsonKey(unknownEnumValue: StockUnit.unknown) StockUnit unit,@JsonKey(name: 'unit_label') String unitLabel, String? description,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'sort_order') int sortOrder,@JsonKey(name: 'variants_count') int? variantsCount,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});


@override $StockItemGroupRefCopyWith<$Res>? get group;

}
/// @nodoc
class __$StockItemCopyWithImpl<$Res>
    implements _$StockItemCopyWith<$Res> {
  __$StockItemCopyWithImpl(this._self, this._then);

  final _StockItem _self;
  final $Res Function(_StockItem) _then;

/// Create a copy of StockItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? name = null,Object? widthCm = freezed,Object? heightCm = freezed,Object? stockItemGroupId = freezed,Object? group = freezed,Object? displayName = null,Object? unit = null,Object? unitLabel = null,Object? description = freezed,Object? isActive = null,Object? sortOrder = null,Object? variantsCount = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_StockItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,widthCm: freezed == widthCm ? _self.widthCm : widthCm // ignore: cast_nullable_to_non_nullable
as int?,heightCm: freezed == heightCm ? _self.heightCm : heightCm // ignore: cast_nullable_to_non_nullable
as int?,stockItemGroupId: freezed == stockItemGroupId ? _self.stockItemGroupId : stockItemGroupId // ignore: cast_nullable_to_non_nullable
as int?,group: freezed == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as StockItemGroupRef?,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as StockUnit,unitLabel: null == unitLabel ? _self.unitLabel : unitLabel // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,variantsCount: freezed == variantsCount ? _self.variantsCount : variantsCount // ignore: cast_nullable_to_non_nullable
as int?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of StockItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StockItemGroupRefCopyWith<$Res>? get group {
    if (_self.group == null) {
    return null;
  }

  return $StockItemGroupRefCopyWith<$Res>(_self.group!, (value) {
    return _then(_self.copyWith(group: value));
  });
}
}


/// @nodoc
mixin _$StockItemGroupRef {

 int get id;/// `G3` — server-allocated, like a stock item's own.
 String get code; String get name;
/// Create a copy of StockItemGroupRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StockItemGroupRefCopyWith<StockItemGroupRef> get copyWith => _$StockItemGroupRefCopyWithImpl<StockItemGroupRef>(this as StockItemGroupRef, _$identity);

  /// Serializes this StockItemGroupRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StockItemGroupRef&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name);

@override
String toString() {
  return 'StockItemGroupRef(id: $id, code: $code, name: $name)';
}


}

/// @nodoc
abstract mixin class $StockItemGroupRefCopyWith<$Res>  {
  factory $StockItemGroupRefCopyWith(StockItemGroupRef value, $Res Function(StockItemGroupRef) _then) = _$StockItemGroupRefCopyWithImpl;
@useResult
$Res call({
 int id, String code, String name
});




}
/// @nodoc
class _$StockItemGroupRefCopyWithImpl<$Res>
    implements $StockItemGroupRefCopyWith<$Res> {
  _$StockItemGroupRefCopyWithImpl(this._self, this._then);

  final StockItemGroupRef _self;
  final $Res Function(StockItemGroupRef) _then;

/// Create a copy of StockItemGroupRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? name = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [StockItemGroupRef].
extension StockItemGroupRefPatterns on StockItemGroupRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StockItemGroupRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StockItemGroupRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StockItemGroupRef value)  $default,){
final _that = this;
switch (_that) {
case _StockItemGroupRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StockItemGroupRef value)?  $default,){
final _that = this;
switch (_that) {
case _StockItemGroupRef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String code,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StockItemGroupRef() when $default != null:
return $default(_that.id,_that.code,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String code,  String name)  $default,) {final _that = this;
switch (_that) {
case _StockItemGroupRef():
return $default(_that.id,_that.code,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String code,  String name)?  $default,) {final _that = this;
switch (_that) {
case _StockItemGroupRef() when $default != null:
return $default(_that.id,_that.code,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StockItemGroupRef implements StockItemGroupRef {
  const _StockItemGroupRef({required this.id, required this.code, required this.name});
  factory _StockItemGroupRef.fromJson(Map<String, dynamic> json) => _$StockItemGroupRefFromJson(json);

@override final  int id;
/// `G3` — server-allocated, like a stock item's own.
@override final  String code;
@override final  String name;

/// Create a copy of StockItemGroupRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StockItemGroupRefCopyWith<_StockItemGroupRef> get copyWith => __$StockItemGroupRefCopyWithImpl<_StockItemGroupRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StockItemGroupRefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StockItemGroupRef&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name);

@override
String toString() {
  return 'StockItemGroupRef(id: $id, code: $code, name: $name)';
}


}

/// @nodoc
abstract mixin class _$StockItemGroupRefCopyWith<$Res> implements $StockItemGroupRefCopyWith<$Res> {
  factory _$StockItemGroupRefCopyWith(_StockItemGroupRef value, $Res Function(_StockItemGroupRef) _then) = __$StockItemGroupRefCopyWithImpl;
@override @useResult
$Res call({
 int id, String code, String name
});




}
/// @nodoc
class __$StockItemGroupRefCopyWithImpl<$Res>
    implements _$StockItemGroupRefCopyWith<$Res> {
  __$StockItemGroupRefCopyWithImpl(this._self, this._then);

  final _StockItemGroupRef _self;
  final $Res Function(_StockItemGroupRef) _then;

/// Create a copy of StockItemGroupRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? name = null,}) {
  return _then(_StockItemGroupRef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
