// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stock_item_group.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StockItemGroup {

 int get id;/// «G3» — allocated by the server from the id and never settable. Shown because it is what
/// a storekeeper reads out over a phone.
 String get code;/// Uniquely indexed on the server, and that is not tidiness: a size under this material
/// carries this name, so two materials sharing one would fight over the same shelf.
 String get name;@JsonKey(name: 'default_unit', unknownEnumValue: StockUnit.unknown) StockUnit get defaultUnit;/// The server's Arabic for [defaultUnit], so the app keeps no translation table. Rendered
/// as sent; [StockUnit.label] is only for naming a unit nothing has been loaded for yet.
@JsonKey(name: 'default_unit_label') String get defaultUnitLabel; String? get description;@JsonKey(name: 'is_active') bool get isActive;@JsonKey(name: 'sort_order') int get sortOrder;/// How many sizes are filed under it. **Nullable because the key is absent** on a create or
/// an edit's answer — `whenCounted` omits it rather than sending zero — and `0` and «لم
/// يُحسب» are different enough to decide a delete button on. See [renamesItems].
@JsonKey(name: 'items_count') int? get itemsCount;/// How many products name it as their material. Absent on the same two responses.
@JsonKey(name: 'products_count') int? get productsCount;/// The sizes themselves, smallest first — **only ever on `show`**, so an empty list here
/// means «this came from the list endpoint», not «this material has no sizes». Nothing
/// counts them; [itemsCount] is what answers that.
 List<StockItem> get items;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of StockItemGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StockItemGroupCopyWith<StockItemGroup> get copyWith => _$StockItemGroupCopyWithImpl<StockItemGroup>(this as StockItemGroup, _$identity);

  /// Serializes this StockItemGroup to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StockItemGroup&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.defaultUnit, defaultUnit) || other.defaultUnit == defaultUnit)&&(identical(other.defaultUnitLabel, defaultUnitLabel) || other.defaultUnitLabel == defaultUnitLabel)&&(identical(other.description, description) || other.description == description)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.itemsCount, itemsCount) || other.itemsCount == itemsCount)&&(identical(other.productsCount, productsCount) || other.productsCount == productsCount)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name,defaultUnit,defaultUnitLabel,description,isActive,sortOrder,itemsCount,productsCount,const DeepCollectionEquality().hash(items),createdAt,updatedAt);

@override
String toString() {
  return 'StockItemGroup(id: $id, code: $code, name: $name, defaultUnit: $defaultUnit, defaultUnitLabel: $defaultUnitLabel, description: $description, isActive: $isActive, sortOrder: $sortOrder, itemsCount: $itemsCount, productsCount: $productsCount, items: $items, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $StockItemGroupCopyWith<$Res>  {
  factory $StockItemGroupCopyWith(StockItemGroup value, $Res Function(StockItemGroup) _then) = _$StockItemGroupCopyWithImpl;
@useResult
$Res call({
 int id, String code, String name,@JsonKey(name: 'default_unit', unknownEnumValue: StockUnit.unknown) StockUnit defaultUnit,@JsonKey(name: 'default_unit_label') String defaultUnitLabel, String? description,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'sort_order') int sortOrder,@JsonKey(name: 'items_count') int? itemsCount,@JsonKey(name: 'products_count') int? productsCount, List<StockItem> items,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class _$StockItemGroupCopyWithImpl<$Res>
    implements $StockItemGroupCopyWith<$Res> {
  _$StockItemGroupCopyWithImpl(this._self, this._then);

  final StockItemGroup _self;
  final $Res Function(StockItemGroup) _then;

/// Create a copy of StockItemGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? name = null,Object? defaultUnit = null,Object? defaultUnitLabel = null,Object? description = freezed,Object? isActive = null,Object? sortOrder = null,Object? itemsCount = freezed,Object? productsCount = freezed,Object? items = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,defaultUnit: null == defaultUnit ? _self.defaultUnit : defaultUnit // ignore: cast_nullable_to_non_nullable
as StockUnit,defaultUnitLabel: null == defaultUnitLabel ? _self.defaultUnitLabel : defaultUnitLabel // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,itemsCount: freezed == itemsCount ? _self.itemsCount : itemsCount // ignore: cast_nullable_to_non_nullable
as int?,productsCount: freezed == productsCount ? _self.productsCount : productsCount // ignore: cast_nullable_to_non_nullable
as int?,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<StockItem>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [StockItemGroup].
extension StockItemGroupPatterns on StockItemGroup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StockItemGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StockItemGroup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StockItemGroup value)  $default,){
final _that = this;
switch (_that) {
case _StockItemGroup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StockItemGroup value)?  $default,){
final _that = this;
switch (_that) {
case _StockItemGroup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String code,  String name, @JsonKey(name: 'default_unit', unknownEnumValue: StockUnit.unknown)  StockUnit defaultUnit, @JsonKey(name: 'default_unit_label')  String defaultUnitLabel,  String? description, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'sort_order')  int sortOrder, @JsonKey(name: 'items_count')  int? itemsCount, @JsonKey(name: 'products_count')  int? productsCount,  List<StockItem> items, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StockItemGroup() when $default != null:
return $default(_that.id,_that.code,_that.name,_that.defaultUnit,_that.defaultUnitLabel,_that.description,_that.isActive,_that.sortOrder,_that.itemsCount,_that.productsCount,_that.items,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String code,  String name, @JsonKey(name: 'default_unit', unknownEnumValue: StockUnit.unknown)  StockUnit defaultUnit, @JsonKey(name: 'default_unit_label')  String defaultUnitLabel,  String? description, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'sort_order')  int sortOrder, @JsonKey(name: 'items_count')  int? itemsCount, @JsonKey(name: 'products_count')  int? productsCount,  List<StockItem> items, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _StockItemGroup():
return $default(_that.id,_that.code,_that.name,_that.defaultUnit,_that.defaultUnitLabel,_that.description,_that.isActive,_that.sortOrder,_that.itemsCount,_that.productsCount,_that.items,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String code,  String name, @JsonKey(name: 'default_unit', unknownEnumValue: StockUnit.unknown)  StockUnit defaultUnit, @JsonKey(name: 'default_unit_label')  String defaultUnitLabel,  String? description, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'sort_order')  int sortOrder, @JsonKey(name: 'items_count')  int? itemsCount, @JsonKey(name: 'products_count')  int? productsCount,  List<StockItem> items, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _StockItemGroup() when $default != null:
return $default(_that.id,_that.code,_that.name,_that.defaultUnit,_that.defaultUnitLabel,_that.description,_that.isActive,_that.sortOrder,_that.itemsCount,_that.productsCount,_that.items,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StockItemGroup extends StockItemGroup {
  const _StockItemGroup({required this.id, required this.code, required this.name, @JsonKey(name: 'default_unit', unknownEnumValue: StockUnit.unknown) required this.defaultUnit, @JsonKey(name: 'default_unit_label') required this.defaultUnitLabel, this.description, @JsonKey(name: 'is_active') required this.isActive, @JsonKey(name: 'sort_order') required this.sortOrder, @JsonKey(name: 'items_count') this.itemsCount, @JsonKey(name: 'products_count') this.productsCount, final  List<StockItem> items = const <StockItem>[], @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt}): _items = items,super._();
  factory _StockItemGroup.fromJson(Map<String, dynamic> json) => _$StockItemGroupFromJson(json);

@override final  int id;
/// «G3» — allocated by the server from the id and never settable. Shown because it is what
/// a storekeeper reads out over a phone.
@override final  String code;
/// Uniquely indexed on the server, and that is not tidiness: a size under this material
/// carries this name, so two materials sharing one would fight over the same shelf.
@override final  String name;
@override@JsonKey(name: 'default_unit', unknownEnumValue: StockUnit.unknown) final  StockUnit defaultUnit;
/// The server's Arabic for [defaultUnit], so the app keeps no translation table. Rendered
/// as sent; [StockUnit.label] is only for naming a unit nothing has been loaded for yet.
@override@JsonKey(name: 'default_unit_label') final  String defaultUnitLabel;
@override final  String? description;
@override@JsonKey(name: 'is_active') final  bool isActive;
@override@JsonKey(name: 'sort_order') final  int sortOrder;
/// How many sizes are filed under it. **Nullable because the key is absent** on a create or
/// an edit's answer — `whenCounted` omits it rather than sending zero — and `0` and «لم
/// يُحسب» are different enough to decide a delete button on. See [renamesItems].
@override@JsonKey(name: 'items_count') final  int? itemsCount;
/// How many products name it as their material. Absent on the same two responses.
@override@JsonKey(name: 'products_count') final  int? productsCount;
/// The sizes themselves, smallest first — **only ever on `show`**, so an empty list here
/// means «this came from the list endpoint», not «this material has no sizes». Nothing
/// counts them; [itemsCount] is what answers that.
 final  List<StockItem> _items;
/// The sizes themselves, smallest first — **only ever on `show`**, so an empty list here
/// means «this came from the list endpoint», not «this material has no sizes». Nothing
/// counts them; [itemsCount] is what answers that.
@override@JsonKey() List<StockItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;

/// Create a copy of StockItemGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StockItemGroupCopyWith<_StockItemGroup> get copyWith => __$StockItemGroupCopyWithImpl<_StockItemGroup>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StockItemGroupToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StockItemGroup&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.defaultUnit, defaultUnit) || other.defaultUnit == defaultUnit)&&(identical(other.defaultUnitLabel, defaultUnitLabel) || other.defaultUnitLabel == defaultUnitLabel)&&(identical(other.description, description) || other.description == description)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.itemsCount, itemsCount) || other.itemsCount == itemsCount)&&(identical(other.productsCount, productsCount) || other.productsCount == productsCount)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name,defaultUnit,defaultUnitLabel,description,isActive,sortOrder,itemsCount,productsCount,const DeepCollectionEquality().hash(_items),createdAt,updatedAt);

@override
String toString() {
  return 'StockItemGroup(id: $id, code: $code, name: $name, defaultUnit: $defaultUnit, defaultUnitLabel: $defaultUnitLabel, description: $description, isActive: $isActive, sortOrder: $sortOrder, itemsCount: $itemsCount, productsCount: $productsCount, items: $items, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$StockItemGroupCopyWith<$Res> implements $StockItemGroupCopyWith<$Res> {
  factory _$StockItemGroupCopyWith(_StockItemGroup value, $Res Function(_StockItemGroup) _then) = __$StockItemGroupCopyWithImpl;
@override @useResult
$Res call({
 int id, String code, String name,@JsonKey(name: 'default_unit', unknownEnumValue: StockUnit.unknown) StockUnit defaultUnit,@JsonKey(name: 'default_unit_label') String defaultUnitLabel, String? description,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'sort_order') int sortOrder,@JsonKey(name: 'items_count') int? itemsCount,@JsonKey(name: 'products_count') int? productsCount, List<StockItem> items,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class __$StockItemGroupCopyWithImpl<$Res>
    implements _$StockItemGroupCopyWith<$Res> {
  __$StockItemGroupCopyWithImpl(this._self, this._then);

  final _StockItemGroup _self;
  final $Res Function(_StockItemGroup) _then;

/// Create a copy of StockItemGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? name = null,Object? defaultUnit = null,Object? defaultUnitLabel = null,Object? description = freezed,Object? isActive = null,Object? sortOrder = null,Object? itemsCount = freezed,Object? productsCount = freezed,Object? items = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_StockItemGroup(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,defaultUnit: null == defaultUnit ? _self.defaultUnit : defaultUnit // ignore: cast_nullable_to_non_nullable
as StockUnit,defaultUnitLabel: null == defaultUnitLabel ? _self.defaultUnitLabel : defaultUnitLabel // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,itemsCount: freezed == itemsCount ? _self.itemsCount : itemsCount // ignore: cast_nullable_to_non_nullable
as int?,productsCount: freezed == productsCount ? _self.productsCount : productsCount // ignore: cast_nullable_to_non_nullable
as int?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<StockItem>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
