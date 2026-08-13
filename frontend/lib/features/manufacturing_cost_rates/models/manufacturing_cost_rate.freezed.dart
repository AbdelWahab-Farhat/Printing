// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'manufacturing_cost_rate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ManufacturingCostRate {

 int get id;/// The product this rate is pinned to, or null when it is not on that rung.
///
/// **Always present as a key**, because every endpoint eager-loads the relation: `null`
/// means «this rate is not about a particular product», never «the server did not send it».
/// The shape is the id-and-name the API flattens a reference into everywhere else, so it is
/// the same class.
 ArrivalRef? get product;/// The size this rate is pinned to. Null on the other two rungs, for the same reason.
@JsonKey(name: 'product_variant') RateVariant? get productVariant;@JsonKey(name: 'cost_type', unknownEnumValue: ManufacturingCostType.unknown) ManufacturingCostType get costType;/// The Arabic the server chose. Rendered as-is wherever *this* rate is on screen, so a kind
/// added on the server still reads correctly here.
@JsonKey(name: 'cost_type_label') String get costTypeLabel;/// What one unit costs — `'3.500'`, as the server stored it.
///
/// **A `String`, like every other amount in this app.** It is a decimal the server sent with
/// exactly three places, and parsing it into a `double` to show it is how `0.850` reaches a
/// screen as `0.8500000000000001`.
@JsonKey(name: 'rate_per_unit') String get ratePerUnit;/// Whether the rate is still consulted. A stopped rate is skipped when the ladder is walked,
/// which lets the rung below it answer instead — it does not shadow.
@JsonKey(name: 'is_active') bool get isActive; String? get notes;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of ManufacturingCostRate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ManufacturingCostRateCopyWith<ManufacturingCostRate> get copyWith => _$ManufacturingCostRateCopyWithImpl<ManufacturingCostRate>(this as ManufacturingCostRate, _$identity);

  /// Serializes this ManufacturingCostRate to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ManufacturingCostRate&&(identical(other.id, id) || other.id == id)&&(identical(other.product, product) || other.product == product)&&(identical(other.productVariant, productVariant) || other.productVariant == productVariant)&&(identical(other.costType, costType) || other.costType == costType)&&(identical(other.costTypeLabel, costTypeLabel) || other.costTypeLabel == costTypeLabel)&&(identical(other.ratePerUnit, ratePerUnit) || other.ratePerUnit == ratePerUnit)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,product,productVariant,costType,costTypeLabel,ratePerUnit,isActive,notes,createdAt,updatedAt);

@override
String toString() {
  return 'ManufacturingCostRate(id: $id, product: $product, productVariant: $productVariant, costType: $costType, costTypeLabel: $costTypeLabel, ratePerUnit: $ratePerUnit, isActive: $isActive, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ManufacturingCostRateCopyWith<$Res>  {
  factory $ManufacturingCostRateCopyWith(ManufacturingCostRate value, $Res Function(ManufacturingCostRate) _then) = _$ManufacturingCostRateCopyWithImpl;
@useResult
$Res call({
 int id, ArrivalRef? product,@JsonKey(name: 'product_variant') RateVariant? productVariant,@JsonKey(name: 'cost_type', unknownEnumValue: ManufacturingCostType.unknown) ManufacturingCostType costType,@JsonKey(name: 'cost_type_label') String costTypeLabel,@JsonKey(name: 'rate_per_unit') String ratePerUnit,@JsonKey(name: 'is_active') bool isActive, String? notes,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});


$ArrivalRefCopyWith<$Res>? get product;$RateVariantCopyWith<$Res>? get productVariant;

}
/// @nodoc
class _$ManufacturingCostRateCopyWithImpl<$Res>
    implements $ManufacturingCostRateCopyWith<$Res> {
  _$ManufacturingCostRateCopyWithImpl(this._self, this._then);

  final ManufacturingCostRate _self;
  final $Res Function(ManufacturingCostRate) _then;

/// Create a copy of ManufacturingCostRate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? product = freezed,Object? productVariant = freezed,Object? costType = null,Object? costTypeLabel = null,Object? ratePerUnit = null,Object? isActive = null,Object? notes = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,product: freezed == product ? _self.product : product // ignore: cast_nullable_to_non_nullable
as ArrivalRef?,productVariant: freezed == productVariant ? _self.productVariant : productVariant // ignore: cast_nullable_to_non_nullable
as RateVariant?,costType: null == costType ? _self.costType : costType // ignore: cast_nullable_to_non_nullable
as ManufacturingCostType,costTypeLabel: null == costTypeLabel ? _self.costTypeLabel : costTypeLabel // ignore: cast_nullable_to_non_nullable
as String,ratePerUnit: null == ratePerUnit ? _self.ratePerUnit : ratePerUnit // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of ManufacturingCostRate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArrivalRefCopyWith<$Res>? get product {
    if (_self.product == null) {
    return null;
  }

  return $ArrivalRefCopyWith<$Res>(_self.product!, (value) {
    return _then(_self.copyWith(product: value));
  });
}/// Create a copy of ManufacturingCostRate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RateVariantCopyWith<$Res>? get productVariant {
    if (_self.productVariant == null) {
    return null;
  }

  return $RateVariantCopyWith<$Res>(_self.productVariant!, (value) {
    return _then(_self.copyWith(productVariant: value));
  });
}
}


/// Adds pattern-matching-related methods to [ManufacturingCostRate].
extension ManufacturingCostRatePatterns on ManufacturingCostRate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ManufacturingCostRate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ManufacturingCostRate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ManufacturingCostRate value)  $default,){
final _that = this;
switch (_that) {
case _ManufacturingCostRate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ManufacturingCostRate value)?  $default,){
final _that = this;
switch (_that) {
case _ManufacturingCostRate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  ArrivalRef? product, @JsonKey(name: 'product_variant')  RateVariant? productVariant, @JsonKey(name: 'cost_type', unknownEnumValue: ManufacturingCostType.unknown)  ManufacturingCostType costType, @JsonKey(name: 'cost_type_label')  String costTypeLabel, @JsonKey(name: 'rate_per_unit')  String ratePerUnit, @JsonKey(name: 'is_active')  bool isActive,  String? notes, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ManufacturingCostRate() when $default != null:
return $default(_that.id,_that.product,_that.productVariant,_that.costType,_that.costTypeLabel,_that.ratePerUnit,_that.isActive,_that.notes,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  ArrivalRef? product, @JsonKey(name: 'product_variant')  RateVariant? productVariant, @JsonKey(name: 'cost_type', unknownEnumValue: ManufacturingCostType.unknown)  ManufacturingCostType costType, @JsonKey(name: 'cost_type_label')  String costTypeLabel, @JsonKey(name: 'rate_per_unit')  String ratePerUnit, @JsonKey(name: 'is_active')  bool isActive,  String? notes, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _ManufacturingCostRate():
return $default(_that.id,_that.product,_that.productVariant,_that.costType,_that.costTypeLabel,_that.ratePerUnit,_that.isActive,_that.notes,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  ArrivalRef? product, @JsonKey(name: 'product_variant')  RateVariant? productVariant, @JsonKey(name: 'cost_type', unknownEnumValue: ManufacturingCostType.unknown)  ManufacturingCostType costType, @JsonKey(name: 'cost_type_label')  String costTypeLabel, @JsonKey(name: 'rate_per_unit')  String ratePerUnit, @JsonKey(name: 'is_active')  bool isActive,  String? notes, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ManufacturingCostRate() when $default != null:
return $default(_that.id,_that.product,_that.productVariant,_that.costType,_that.costTypeLabel,_that.ratePerUnit,_that.isActive,_that.notes,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ManufacturingCostRate extends ManufacturingCostRate {
  const _ManufacturingCostRate({required this.id, this.product, @JsonKey(name: 'product_variant') this.productVariant, @JsonKey(name: 'cost_type', unknownEnumValue: ManufacturingCostType.unknown) required this.costType, @JsonKey(name: 'cost_type_label') required this.costTypeLabel, @JsonKey(name: 'rate_per_unit') required this.ratePerUnit, @JsonKey(name: 'is_active') this.isActive = true, this.notes, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt}): super._();
  factory _ManufacturingCostRate.fromJson(Map<String, dynamic> json) => _$ManufacturingCostRateFromJson(json);

@override final  int id;
/// The product this rate is pinned to, or null when it is not on that rung.
///
/// **Always present as a key**, because every endpoint eager-loads the relation: `null`
/// means «this rate is not about a particular product», never «the server did not send it».
/// The shape is the id-and-name the API flattens a reference into everywhere else, so it is
/// the same class.
@override final  ArrivalRef? product;
/// The size this rate is pinned to. Null on the other two rungs, for the same reason.
@override@JsonKey(name: 'product_variant') final  RateVariant? productVariant;
@override@JsonKey(name: 'cost_type', unknownEnumValue: ManufacturingCostType.unknown) final  ManufacturingCostType costType;
/// The Arabic the server chose. Rendered as-is wherever *this* rate is on screen, so a kind
/// added on the server still reads correctly here.
@override@JsonKey(name: 'cost_type_label') final  String costTypeLabel;
/// What one unit costs — `'3.500'`, as the server stored it.
///
/// **A `String`, like every other amount in this app.** It is a decimal the server sent with
/// exactly three places, and parsing it into a `double` to show it is how `0.850` reaches a
/// screen as `0.8500000000000001`.
@override@JsonKey(name: 'rate_per_unit') final  String ratePerUnit;
/// Whether the rate is still consulted. A stopped rate is skipped when the ladder is walked,
/// which lets the rung below it answer instead — it does not shadow.
@override@JsonKey(name: 'is_active') final  bool isActive;
@override final  String? notes;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;

/// Create a copy of ManufacturingCostRate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ManufacturingCostRateCopyWith<_ManufacturingCostRate> get copyWith => __$ManufacturingCostRateCopyWithImpl<_ManufacturingCostRate>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ManufacturingCostRateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ManufacturingCostRate&&(identical(other.id, id) || other.id == id)&&(identical(other.product, product) || other.product == product)&&(identical(other.productVariant, productVariant) || other.productVariant == productVariant)&&(identical(other.costType, costType) || other.costType == costType)&&(identical(other.costTypeLabel, costTypeLabel) || other.costTypeLabel == costTypeLabel)&&(identical(other.ratePerUnit, ratePerUnit) || other.ratePerUnit == ratePerUnit)&&(identical(other.isActive, isActive) || other.isActive == isActive)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,product,productVariant,costType,costTypeLabel,ratePerUnit,isActive,notes,createdAt,updatedAt);

@override
String toString() {
  return 'ManufacturingCostRate(id: $id, product: $product, productVariant: $productVariant, costType: $costType, costTypeLabel: $costTypeLabel, ratePerUnit: $ratePerUnit, isActive: $isActive, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ManufacturingCostRateCopyWith<$Res> implements $ManufacturingCostRateCopyWith<$Res> {
  factory _$ManufacturingCostRateCopyWith(_ManufacturingCostRate value, $Res Function(_ManufacturingCostRate) _then) = __$ManufacturingCostRateCopyWithImpl;
@override @useResult
$Res call({
 int id, ArrivalRef? product,@JsonKey(name: 'product_variant') RateVariant? productVariant,@JsonKey(name: 'cost_type', unknownEnumValue: ManufacturingCostType.unknown) ManufacturingCostType costType,@JsonKey(name: 'cost_type_label') String costTypeLabel,@JsonKey(name: 'rate_per_unit') String ratePerUnit,@JsonKey(name: 'is_active') bool isActive, String? notes,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});


@override $ArrivalRefCopyWith<$Res>? get product;@override $RateVariantCopyWith<$Res>? get productVariant;

}
/// @nodoc
class __$ManufacturingCostRateCopyWithImpl<$Res>
    implements _$ManufacturingCostRateCopyWith<$Res> {
  __$ManufacturingCostRateCopyWithImpl(this._self, this._then);

  final _ManufacturingCostRate _self;
  final $Res Function(_ManufacturingCostRate) _then;

/// Create a copy of ManufacturingCostRate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? product = freezed,Object? productVariant = freezed,Object? costType = null,Object? costTypeLabel = null,Object? ratePerUnit = null,Object? isActive = null,Object? notes = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_ManufacturingCostRate(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,product: freezed == product ? _self.product : product // ignore: cast_nullable_to_non_nullable
as ArrivalRef?,productVariant: freezed == productVariant ? _self.productVariant : productVariant // ignore: cast_nullable_to_non_nullable
as RateVariant?,costType: null == costType ? _self.costType : costType // ignore: cast_nullable_to_non_nullable
as ManufacturingCostType,costTypeLabel: null == costTypeLabel ? _self.costTypeLabel : costTypeLabel // ignore: cast_nullable_to_non_nullable
as String,ratePerUnit: null == ratePerUnit ? _self.ratePerUnit : ratePerUnit // ignore: cast_nullable_to_non_nullable
as String,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of ManufacturingCostRate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArrivalRefCopyWith<$Res>? get product {
    if (_self.product == null) {
    return null;
  }

  return $ArrivalRefCopyWith<$Res>(_self.product!, (value) {
    return _then(_self.copyWith(product: value));
  });
}/// Create a copy of ManufacturingCostRate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RateVariantCopyWith<$Res>? get productVariant {
    if (_self.productVariant == null) {
    return null;
  }

  return $RateVariantCopyWith<$Res>(_self.productVariant!, (value) {
    return _then(_self.copyWith(productVariant: value));
  });
}
}


/// @nodoc
mixin _$RateVariant {

 int get id; String get label;
/// Create a copy of RateVariant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RateVariantCopyWith<RateVariant> get copyWith => _$RateVariantCopyWithImpl<RateVariant>(this as RateVariant, _$identity);

  /// Serializes this RateVariant to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RateVariant&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label);

@override
String toString() {
  return 'RateVariant(id: $id, label: $label)';
}


}

/// @nodoc
abstract mixin class $RateVariantCopyWith<$Res>  {
  factory $RateVariantCopyWith(RateVariant value, $Res Function(RateVariant) _then) = _$RateVariantCopyWithImpl;
@useResult
$Res call({
 int id, String label
});




}
/// @nodoc
class _$RateVariantCopyWithImpl<$Res>
    implements $RateVariantCopyWith<$Res> {
  _$RateVariantCopyWithImpl(this._self, this._then);

  final RateVariant _self;
  final $Res Function(RateVariant) _then;

/// Create a copy of RateVariant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RateVariant].
extension RateVariantPatterns on RateVariant {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RateVariant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RateVariant() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RateVariant value)  $default,){
final _that = this;
switch (_that) {
case _RateVariant():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RateVariant value)?  $default,){
final _that = this;
switch (_that) {
case _RateVariant() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String label)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RateVariant() when $default != null:
return $default(_that.id,_that.label);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String label)  $default,) {final _that = this;
switch (_that) {
case _RateVariant():
return $default(_that.id,_that.label);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String label)?  $default,) {final _that = this;
switch (_that) {
case _RateVariant() when $default != null:
return $default(_that.id,_that.label);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RateVariant implements RateVariant {
  const _RateVariant({required this.id, required this.label});
  factory _RateVariant.fromJson(Map<String, dynamic> json) => _$RateVariantFromJson(json);

@override final  int id;
@override final  String label;

/// Create a copy of RateVariant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RateVariantCopyWith<_RateVariant> get copyWith => __$RateVariantCopyWithImpl<_RateVariant>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RateVariantToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RateVariant&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label);

@override
String toString() {
  return 'RateVariant(id: $id, label: $label)';
}


}

/// @nodoc
abstract mixin class _$RateVariantCopyWith<$Res> implements $RateVariantCopyWith<$Res> {
  factory _$RateVariantCopyWith(_RateVariant value, $Res Function(_RateVariant) _then) = __$RateVariantCopyWithImpl;
@override @useResult
$Res call({
 int id, String label
});




}
/// @nodoc
class __$RateVariantCopyWithImpl<$Res>
    implements _$RateVariantCopyWith<$Res> {
  __$RateVariantCopyWithImpl(this._self, this._then);

  final _RateVariant _self;
  final $Res Function(_RateVariant) _then;

/// Create a copy of RateVariant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,}) {
  return _then(_RateVariant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
