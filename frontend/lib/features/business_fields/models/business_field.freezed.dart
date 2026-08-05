// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'business_field.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BusinessField {

 int get id; String get name;/// Whether it is still offered when recording a shop. A stopped field stays on the shops
/// already recorded under it — it leaves the picker, it does not retract anything.
@JsonKey(name: 'is_active') bool get isActive;/// Where it sits in the picker. The business's own order, not alphabetical.
@JsonKey(name: 'sort_order') int get sortOrder;/// How many shops are recorded in this trade. Present on the list and on a single field.
///
/// It is also what says whether deleting will be refused — the server allows a delete only
/// while this is zero — so the screen can explain that before the button is pressed.
@JsonKey(name: 'shops_count') int? get shopsCount;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of BusinessField
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BusinessFieldCopyWith<BusinessField> get copyWith => _$BusinessFieldCopyWithImpl<BusinessField>(this as BusinessField, _$identity);

  /// Serializes this BusinessField to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BusinessField&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.shopsCount, shopsCount) || other.shopsCount == shopsCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,isActive,sortOrder,shopsCount,createdAt,updatedAt);

@override
String toString() {
  return 'BusinessField(id: $id, name: $name, isActive: $isActive, sortOrder: $sortOrder, shopsCount: $shopsCount, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $BusinessFieldCopyWith<$Res>  {
  factory $BusinessFieldCopyWith(BusinessField value, $Res Function(BusinessField) _then) = _$BusinessFieldCopyWithImpl;
@useResult
$Res call({
 int id, String name,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'sort_order') int sortOrder,@JsonKey(name: 'shops_count') int? shopsCount,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class _$BusinessFieldCopyWithImpl<$Res>
    implements $BusinessFieldCopyWith<$Res> {
  _$BusinessFieldCopyWithImpl(this._self, this._then);

  final BusinessField _self;
  final $Res Function(BusinessField) _then;

/// Create a copy of BusinessField
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? isActive = null,Object? sortOrder = null,Object? shopsCount = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,shopsCount: freezed == shopsCount ? _self.shopsCount : shopsCount // ignore: cast_nullable_to_non_nullable
as int?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [BusinessField].
extension BusinessFieldPatterns on BusinessField {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BusinessField value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BusinessField() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BusinessField value)  $default,){
final _that = this;
switch (_that) {
case _BusinessField():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BusinessField value)?  $default,){
final _that = this;
switch (_that) {
case _BusinessField() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'sort_order')  int sortOrder, @JsonKey(name: 'shops_count')  int? shopsCount, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BusinessField() when $default != null:
return $default(_that.id,_that.name,_that.isActive,_that.sortOrder,_that.shopsCount,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'sort_order')  int sortOrder, @JsonKey(name: 'shops_count')  int? shopsCount, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _BusinessField():
return $default(_that.id,_that.name,_that.isActive,_that.sortOrder,_that.shopsCount,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name, @JsonKey(name: 'is_active')  bool isActive, @JsonKey(name: 'sort_order')  int sortOrder, @JsonKey(name: 'shops_count')  int? shopsCount, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _BusinessField() when $default != null:
return $default(_that.id,_that.name,_that.isActive,_that.sortOrder,_that.shopsCount,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BusinessField extends BusinessField {
  const _BusinessField({required this.id, required this.name, @JsonKey(name: 'is_active') this.isActive = true, @JsonKey(name: 'sort_order') this.sortOrder = 0, @JsonKey(name: 'shops_count') this.shopsCount, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt}): super._();
  factory _BusinessField.fromJson(Map<String, dynamic> json) => _$BusinessFieldFromJson(json);

@override final  int id;
@override final  String name;
/// Whether it is still offered when recording a shop. A stopped field stays on the shops
/// already recorded under it — it leaves the picker, it does not retract anything.
@override@JsonKey(name: 'is_active') final  bool isActive;
/// Where it sits in the picker. The business's own order, not alphabetical.
@override@JsonKey(name: 'sort_order') final  int sortOrder;
/// How many shops are recorded in this trade. Present on the list and on a single field.
///
/// It is also what says whether deleting will be refused — the server allows a delete only
/// while this is zero — so the screen can explain that before the button is pressed.
@override@JsonKey(name: 'shops_count') final  int? shopsCount;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;

/// Create a copy of BusinessField
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BusinessFieldCopyWith<_BusinessField> get copyWith => __$BusinessFieldCopyWithImpl<_BusinessField>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BusinessFieldToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BusinessField&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.shopsCount, shopsCount) || other.shopsCount == shopsCount)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,isActive,sortOrder,shopsCount,createdAt,updatedAt);

@override
String toString() {
  return 'BusinessField(id: $id, name: $name, isActive: $isActive, sortOrder: $sortOrder, shopsCount: $shopsCount, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$BusinessFieldCopyWith<$Res> implements $BusinessFieldCopyWith<$Res> {
  factory _$BusinessFieldCopyWith(_BusinessField value, $Res Function(_BusinessField) _then) = __$BusinessFieldCopyWithImpl;
@override @useResult
$Res call({
 int id, String name,@JsonKey(name: 'is_active') bool isActive,@JsonKey(name: 'sort_order') int sortOrder,@JsonKey(name: 'shops_count') int? shopsCount,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class __$BusinessFieldCopyWithImpl<$Res>
    implements _$BusinessFieldCopyWith<$Res> {
  __$BusinessFieldCopyWithImpl(this._self, this._then);

  final _BusinessField _self;
  final $Res Function(_BusinessField) _then;

/// Create a copy of BusinessField
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? isActive = null,Object? sortOrder = null,Object? shopsCount = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_BusinessField(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,shopsCount: freezed == shopsCount ? _self.shopsCount : shopsCount // ignore: cast_nullable_to_non_nullable
as int?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
