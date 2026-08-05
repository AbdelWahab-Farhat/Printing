// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stock_movement.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StockMovement {

 int get id;@JsonKey(name: 'movement_type', unknownEnumValue: MovementType.unknown) MovementType get movementType;/// The server's Arabic for [movementType].
@JsonKey(name: 'movement_type_label') String get movementTypeLabel;/// Always positive. Which way it went is [movementType] plus the two warehouses — an
/// adjustment down is a movement *out of* a warehouse, not a negative number.
 String get quantity;@JsonKey(name: 'product_variant_id') int get productVariantId;@JsonKey(name: 'product_variant') StockVariant? get variant;@JsonKey(name: 'from_warehouse_id') int? get fromWarehouseId;@JsonKey(name: 'from_warehouse') MovementPlace? get fromWarehouse;@JsonKey(name: 'to_warehouse_id') int? get toWarehouseId;@JsonKey(name: 'to_warehouse') MovementPlace? get toWarehouse;/// The order a fulfillment was for, or the purchase an arrival came from.
@JsonKey(name: 'reference_id') int? get referenceId;@JsonKey(name: 'employee_id') int? get employeeId; MovementActor? get employee; String? get notes;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of StockMovement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StockMovementCopyWith<StockMovement> get copyWith => _$StockMovementCopyWithImpl<StockMovement>(this as StockMovement, _$identity);

  /// Serializes this StockMovement to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StockMovement&&(identical(other.id, id) || other.id == id)&&(identical(other.movementType, movementType) || other.movementType == movementType)&&(identical(other.movementTypeLabel, movementTypeLabel) || other.movementTypeLabel == movementTypeLabel)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.productVariantId, productVariantId) || other.productVariantId == productVariantId)&&(identical(other.variant, variant) || other.variant == variant)&&(identical(other.fromWarehouseId, fromWarehouseId) || other.fromWarehouseId == fromWarehouseId)&&(identical(other.fromWarehouse, fromWarehouse) || other.fromWarehouse == fromWarehouse)&&(identical(other.toWarehouseId, toWarehouseId) || other.toWarehouseId == toWarehouseId)&&(identical(other.toWarehouse, toWarehouse) || other.toWarehouse == toWarehouse)&&(identical(other.referenceId, referenceId) || other.referenceId == referenceId)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.employee, employee) || other.employee == employee)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,movementType,movementTypeLabel,quantity,productVariantId,variant,fromWarehouseId,fromWarehouse,toWarehouseId,toWarehouse,referenceId,employeeId,employee,notes,createdAt);

@override
String toString() {
  return 'StockMovement(id: $id, movementType: $movementType, movementTypeLabel: $movementTypeLabel, quantity: $quantity, productVariantId: $productVariantId, variant: $variant, fromWarehouseId: $fromWarehouseId, fromWarehouse: $fromWarehouse, toWarehouseId: $toWarehouseId, toWarehouse: $toWarehouse, referenceId: $referenceId, employeeId: $employeeId, employee: $employee, notes: $notes, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $StockMovementCopyWith<$Res>  {
  factory $StockMovementCopyWith(StockMovement value, $Res Function(StockMovement) _then) = _$StockMovementCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'movement_type', unknownEnumValue: MovementType.unknown) MovementType movementType,@JsonKey(name: 'movement_type_label') String movementTypeLabel, String quantity,@JsonKey(name: 'product_variant_id') int productVariantId,@JsonKey(name: 'product_variant') StockVariant? variant,@JsonKey(name: 'from_warehouse_id') int? fromWarehouseId,@JsonKey(name: 'from_warehouse') MovementPlace? fromWarehouse,@JsonKey(name: 'to_warehouse_id') int? toWarehouseId,@JsonKey(name: 'to_warehouse') MovementPlace? toWarehouse,@JsonKey(name: 'reference_id') int? referenceId,@JsonKey(name: 'employee_id') int? employeeId, MovementActor? employee, String? notes,@JsonKey(name: 'created_at') DateTime? createdAt
});


$StockVariantCopyWith<$Res>? get variant;$MovementPlaceCopyWith<$Res>? get fromWarehouse;$MovementPlaceCopyWith<$Res>? get toWarehouse;$MovementActorCopyWith<$Res>? get employee;

}
/// @nodoc
class _$StockMovementCopyWithImpl<$Res>
    implements $StockMovementCopyWith<$Res> {
  _$StockMovementCopyWithImpl(this._self, this._then);

  final StockMovement _self;
  final $Res Function(StockMovement) _then;

/// Create a copy of StockMovement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? movementType = null,Object? movementTypeLabel = null,Object? quantity = null,Object? productVariantId = null,Object? variant = freezed,Object? fromWarehouseId = freezed,Object? fromWarehouse = freezed,Object? toWarehouseId = freezed,Object? toWarehouse = freezed,Object? referenceId = freezed,Object? employeeId = freezed,Object? employee = freezed,Object? notes = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,movementType: null == movementType ? _self.movementType : movementType // ignore: cast_nullable_to_non_nullable
as MovementType,movementTypeLabel: null == movementTypeLabel ? _self.movementTypeLabel : movementTypeLabel // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,productVariantId: null == productVariantId ? _self.productVariantId : productVariantId // ignore: cast_nullable_to_non_nullable
as int,variant: freezed == variant ? _self.variant : variant // ignore: cast_nullable_to_non_nullable
as StockVariant?,fromWarehouseId: freezed == fromWarehouseId ? _self.fromWarehouseId : fromWarehouseId // ignore: cast_nullable_to_non_nullable
as int?,fromWarehouse: freezed == fromWarehouse ? _self.fromWarehouse : fromWarehouse // ignore: cast_nullable_to_non_nullable
as MovementPlace?,toWarehouseId: freezed == toWarehouseId ? _self.toWarehouseId : toWarehouseId // ignore: cast_nullable_to_non_nullable
as int?,toWarehouse: freezed == toWarehouse ? _self.toWarehouse : toWarehouse // ignore: cast_nullable_to_non_nullable
as MovementPlace?,referenceId: freezed == referenceId ? _self.referenceId : referenceId // ignore: cast_nullable_to_non_nullable
as int?,employeeId: freezed == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as int?,employee: freezed == employee ? _self.employee : employee // ignore: cast_nullable_to_non_nullable
as MovementActor?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of StockMovement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StockVariantCopyWith<$Res>? get variant {
    if (_self.variant == null) {
    return null;
  }

  return $StockVariantCopyWith<$Res>(_self.variant!, (value) {
    return _then(_self.copyWith(variant: value));
  });
}/// Create a copy of StockMovement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MovementPlaceCopyWith<$Res>? get fromWarehouse {
    if (_self.fromWarehouse == null) {
    return null;
  }

  return $MovementPlaceCopyWith<$Res>(_self.fromWarehouse!, (value) {
    return _then(_self.copyWith(fromWarehouse: value));
  });
}/// Create a copy of StockMovement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MovementPlaceCopyWith<$Res>? get toWarehouse {
    if (_self.toWarehouse == null) {
    return null;
  }

  return $MovementPlaceCopyWith<$Res>(_self.toWarehouse!, (value) {
    return _then(_self.copyWith(toWarehouse: value));
  });
}/// Create a copy of StockMovement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MovementActorCopyWith<$Res>? get employee {
    if (_self.employee == null) {
    return null;
  }

  return $MovementActorCopyWith<$Res>(_self.employee!, (value) {
    return _then(_self.copyWith(employee: value));
  });
}
}


/// Adds pattern-matching-related methods to [StockMovement].
extension StockMovementPatterns on StockMovement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StockMovement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StockMovement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StockMovement value)  $default,){
final _that = this;
switch (_that) {
case _StockMovement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StockMovement value)?  $default,){
final _that = this;
switch (_that) {
case _StockMovement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'movement_type', unknownEnumValue: MovementType.unknown)  MovementType movementType, @JsonKey(name: 'movement_type_label')  String movementTypeLabel,  String quantity, @JsonKey(name: 'product_variant_id')  int productVariantId, @JsonKey(name: 'product_variant')  StockVariant? variant, @JsonKey(name: 'from_warehouse_id')  int? fromWarehouseId, @JsonKey(name: 'from_warehouse')  MovementPlace? fromWarehouse, @JsonKey(name: 'to_warehouse_id')  int? toWarehouseId, @JsonKey(name: 'to_warehouse')  MovementPlace? toWarehouse, @JsonKey(name: 'reference_id')  int? referenceId, @JsonKey(name: 'employee_id')  int? employeeId,  MovementActor? employee,  String? notes, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StockMovement() when $default != null:
return $default(_that.id,_that.movementType,_that.movementTypeLabel,_that.quantity,_that.productVariantId,_that.variant,_that.fromWarehouseId,_that.fromWarehouse,_that.toWarehouseId,_that.toWarehouse,_that.referenceId,_that.employeeId,_that.employee,_that.notes,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'movement_type', unknownEnumValue: MovementType.unknown)  MovementType movementType, @JsonKey(name: 'movement_type_label')  String movementTypeLabel,  String quantity, @JsonKey(name: 'product_variant_id')  int productVariantId, @JsonKey(name: 'product_variant')  StockVariant? variant, @JsonKey(name: 'from_warehouse_id')  int? fromWarehouseId, @JsonKey(name: 'from_warehouse')  MovementPlace? fromWarehouse, @JsonKey(name: 'to_warehouse_id')  int? toWarehouseId, @JsonKey(name: 'to_warehouse')  MovementPlace? toWarehouse, @JsonKey(name: 'reference_id')  int? referenceId, @JsonKey(name: 'employee_id')  int? employeeId,  MovementActor? employee,  String? notes, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _StockMovement():
return $default(_that.id,_that.movementType,_that.movementTypeLabel,_that.quantity,_that.productVariantId,_that.variant,_that.fromWarehouseId,_that.fromWarehouse,_that.toWarehouseId,_that.toWarehouse,_that.referenceId,_that.employeeId,_that.employee,_that.notes,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'movement_type', unknownEnumValue: MovementType.unknown)  MovementType movementType, @JsonKey(name: 'movement_type_label')  String movementTypeLabel,  String quantity, @JsonKey(name: 'product_variant_id')  int productVariantId, @JsonKey(name: 'product_variant')  StockVariant? variant, @JsonKey(name: 'from_warehouse_id')  int? fromWarehouseId, @JsonKey(name: 'from_warehouse')  MovementPlace? fromWarehouse, @JsonKey(name: 'to_warehouse_id')  int? toWarehouseId, @JsonKey(name: 'to_warehouse')  MovementPlace? toWarehouse, @JsonKey(name: 'reference_id')  int? referenceId, @JsonKey(name: 'employee_id')  int? employeeId,  MovementActor? employee,  String? notes, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _StockMovement() when $default != null:
return $default(_that.id,_that.movementType,_that.movementTypeLabel,_that.quantity,_that.productVariantId,_that.variant,_that.fromWarehouseId,_that.fromWarehouse,_that.toWarehouseId,_that.toWarehouse,_that.referenceId,_that.employeeId,_that.employee,_that.notes,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StockMovement extends StockMovement {
  const _StockMovement({required this.id, @JsonKey(name: 'movement_type', unknownEnumValue: MovementType.unknown) required this.movementType, @JsonKey(name: 'movement_type_label') required this.movementTypeLabel, required this.quantity, @JsonKey(name: 'product_variant_id') required this.productVariantId, @JsonKey(name: 'product_variant') this.variant, @JsonKey(name: 'from_warehouse_id') this.fromWarehouseId, @JsonKey(name: 'from_warehouse') this.fromWarehouse, @JsonKey(name: 'to_warehouse_id') this.toWarehouseId, @JsonKey(name: 'to_warehouse') this.toWarehouse, @JsonKey(name: 'reference_id') this.referenceId, @JsonKey(name: 'employee_id') this.employeeId, this.employee, this.notes, @JsonKey(name: 'created_at') this.createdAt}): super._();
  factory _StockMovement.fromJson(Map<String, dynamic> json) => _$StockMovementFromJson(json);

@override final  int id;
@override@JsonKey(name: 'movement_type', unknownEnumValue: MovementType.unknown) final  MovementType movementType;
/// The server's Arabic for [movementType].
@override@JsonKey(name: 'movement_type_label') final  String movementTypeLabel;
/// Always positive. Which way it went is [movementType] plus the two warehouses — an
/// adjustment down is a movement *out of* a warehouse, not a negative number.
@override final  String quantity;
@override@JsonKey(name: 'product_variant_id') final  int productVariantId;
@override@JsonKey(name: 'product_variant') final  StockVariant? variant;
@override@JsonKey(name: 'from_warehouse_id') final  int? fromWarehouseId;
@override@JsonKey(name: 'from_warehouse') final  MovementPlace? fromWarehouse;
@override@JsonKey(name: 'to_warehouse_id') final  int? toWarehouseId;
@override@JsonKey(name: 'to_warehouse') final  MovementPlace? toWarehouse;
/// The order a fulfillment was for, or the purchase an arrival came from.
@override@JsonKey(name: 'reference_id') final  int? referenceId;
@override@JsonKey(name: 'employee_id') final  int? employeeId;
@override final  MovementActor? employee;
@override final  String? notes;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of StockMovement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StockMovementCopyWith<_StockMovement> get copyWith => __$StockMovementCopyWithImpl<_StockMovement>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StockMovementToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StockMovement&&(identical(other.id, id) || other.id == id)&&(identical(other.movementType, movementType) || other.movementType == movementType)&&(identical(other.movementTypeLabel, movementTypeLabel) || other.movementTypeLabel == movementTypeLabel)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.productVariantId, productVariantId) || other.productVariantId == productVariantId)&&(identical(other.variant, variant) || other.variant == variant)&&(identical(other.fromWarehouseId, fromWarehouseId) || other.fromWarehouseId == fromWarehouseId)&&(identical(other.fromWarehouse, fromWarehouse) || other.fromWarehouse == fromWarehouse)&&(identical(other.toWarehouseId, toWarehouseId) || other.toWarehouseId == toWarehouseId)&&(identical(other.toWarehouse, toWarehouse) || other.toWarehouse == toWarehouse)&&(identical(other.referenceId, referenceId) || other.referenceId == referenceId)&&(identical(other.employeeId, employeeId) || other.employeeId == employeeId)&&(identical(other.employee, employee) || other.employee == employee)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,movementType,movementTypeLabel,quantity,productVariantId,variant,fromWarehouseId,fromWarehouse,toWarehouseId,toWarehouse,referenceId,employeeId,employee,notes,createdAt);

@override
String toString() {
  return 'StockMovement(id: $id, movementType: $movementType, movementTypeLabel: $movementTypeLabel, quantity: $quantity, productVariantId: $productVariantId, variant: $variant, fromWarehouseId: $fromWarehouseId, fromWarehouse: $fromWarehouse, toWarehouseId: $toWarehouseId, toWarehouse: $toWarehouse, referenceId: $referenceId, employeeId: $employeeId, employee: $employee, notes: $notes, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$StockMovementCopyWith<$Res> implements $StockMovementCopyWith<$Res> {
  factory _$StockMovementCopyWith(_StockMovement value, $Res Function(_StockMovement) _then) = __$StockMovementCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'movement_type', unknownEnumValue: MovementType.unknown) MovementType movementType,@JsonKey(name: 'movement_type_label') String movementTypeLabel, String quantity,@JsonKey(name: 'product_variant_id') int productVariantId,@JsonKey(name: 'product_variant') StockVariant? variant,@JsonKey(name: 'from_warehouse_id') int? fromWarehouseId,@JsonKey(name: 'from_warehouse') MovementPlace? fromWarehouse,@JsonKey(name: 'to_warehouse_id') int? toWarehouseId,@JsonKey(name: 'to_warehouse') MovementPlace? toWarehouse,@JsonKey(name: 'reference_id') int? referenceId,@JsonKey(name: 'employee_id') int? employeeId, MovementActor? employee, String? notes,@JsonKey(name: 'created_at') DateTime? createdAt
});


@override $StockVariantCopyWith<$Res>? get variant;@override $MovementPlaceCopyWith<$Res>? get fromWarehouse;@override $MovementPlaceCopyWith<$Res>? get toWarehouse;@override $MovementActorCopyWith<$Res>? get employee;

}
/// @nodoc
class __$StockMovementCopyWithImpl<$Res>
    implements _$StockMovementCopyWith<$Res> {
  __$StockMovementCopyWithImpl(this._self, this._then);

  final _StockMovement _self;
  final $Res Function(_StockMovement) _then;

/// Create a copy of StockMovement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? movementType = null,Object? movementTypeLabel = null,Object? quantity = null,Object? productVariantId = null,Object? variant = freezed,Object? fromWarehouseId = freezed,Object? fromWarehouse = freezed,Object? toWarehouseId = freezed,Object? toWarehouse = freezed,Object? referenceId = freezed,Object? employeeId = freezed,Object? employee = freezed,Object? notes = freezed,Object? createdAt = freezed,}) {
  return _then(_StockMovement(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,movementType: null == movementType ? _self.movementType : movementType // ignore: cast_nullable_to_non_nullable
as MovementType,movementTypeLabel: null == movementTypeLabel ? _self.movementTypeLabel : movementTypeLabel // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,productVariantId: null == productVariantId ? _self.productVariantId : productVariantId // ignore: cast_nullable_to_non_nullable
as int,variant: freezed == variant ? _self.variant : variant // ignore: cast_nullable_to_non_nullable
as StockVariant?,fromWarehouseId: freezed == fromWarehouseId ? _self.fromWarehouseId : fromWarehouseId // ignore: cast_nullable_to_non_nullable
as int?,fromWarehouse: freezed == fromWarehouse ? _self.fromWarehouse : fromWarehouse // ignore: cast_nullable_to_non_nullable
as MovementPlace?,toWarehouseId: freezed == toWarehouseId ? _self.toWarehouseId : toWarehouseId // ignore: cast_nullable_to_non_nullable
as int?,toWarehouse: freezed == toWarehouse ? _self.toWarehouse : toWarehouse // ignore: cast_nullable_to_non_nullable
as MovementPlace?,referenceId: freezed == referenceId ? _self.referenceId : referenceId // ignore: cast_nullable_to_non_nullable
as int?,employeeId: freezed == employeeId ? _self.employeeId : employeeId // ignore: cast_nullable_to_non_nullable
as int?,employee: freezed == employee ? _self.employee : employee // ignore: cast_nullable_to_non_nullable
as MovementActor?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of StockMovement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StockVariantCopyWith<$Res>? get variant {
    if (_self.variant == null) {
    return null;
  }

  return $StockVariantCopyWith<$Res>(_self.variant!, (value) {
    return _then(_self.copyWith(variant: value));
  });
}/// Create a copy of StockMovement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MovementPlaceCopyWith<$Res>? get fromWarehouse {
    if (_self.fromWarehouse == null) {
    return null;
  }

  return $MovementPlaceCopyWith<$Res>(_self.fromWarehouse!, (value) {
    return _then(_self.copyWith(fromWarehouse: value));
  });
}/// Create a copy of StockMovement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MovementPlaceCopyWith<$Res>? get toWarehouse {
    if (_self.toWarehouse == null) {
    return null;
  }

  return $MovementPlaceCopyWith<$Res>(_self.toWarehouse!, (value) {
    return _then(_self.copyWith(toWarehouse: value));
  });
}/// Create a copy of StockMovement
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MovementActorCopyWith<$Res>? get employee {
    if (_self.employee == null) {
    return null;
  }

  return $MovementActorCopyWith<$Res>(_self.employee!, (value) {
    return _then(_self.copyWith(employee: value));
  });
}
}


/// @nodoc
mixin _$MovementPlace {

 int get id; String get name;
/// Create a copy of MovementPlace
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MovementPlaceCopyWith<MovementPlace> get copyWith => _$MovementPlaceCopyWithImpl<MovementPlace>(this as MovementPlace, _$identity);

  /// Serializes this MovementPlace to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MovementPlace&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'MovementPlace(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $MovementPlaceCopyWith<$Res>  {
  factory $MovementPlaceCopyWith(MovementPlace value, $Res Function(MovementPlace) _then) = _$MovementPlaceCopyWithImpl;
@useResult
$Res call({
 int id, String name
});




}
/// @nodoc
class _$MovementPlaceCopyWithImpl<$Res>
    implements $MovementPlaceCopyWith<$Res> {
  _$MovementPlaceCopyWithImpl(this._self, this._then);

  final MovementPlace _self;
  final $Res Function(MovementPlace) _then;

/// Create a copy of MovementPlace
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MovementPlace].
extension MovementPlacePatterns on MovementPlace {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MovementPlace value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MovementPlace() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MovementPlace value)  $default,){
final _that = this;
switch (_that) {
case _MovementPlace():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MovementPlace value)?  $default,){
final _that = this;
switch (_that) {
case _MovementPlace() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MovementPlace() when $default != null:
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name)  $default,) {final _that = this;
switch (_that) {
case _MovementPlace():
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name)?  $default,) {final _that = this;
switch (_that) {
case _MovementPlace() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MovementPlace implements MovementPlace {
  const _MovementPlace({required this.id, required this.name});
  factory _MovementPlace.fromJson(Map<String, dynamic> json) => _$MovementPlaceFromJson(json);

@override final  int id;
@override final  String name;

/// Create a copy of MovementPlace
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MovementPlaceCopyWith<_MovementPlace> get copyWith => __$MovementPlaceCopyWithImpl<_MovementPlace>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MovementPlaceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MovementPlace&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'MovementPlace(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$MovementPlaceCopyWith<$Res> implements $MovementPlaceCopyWith<$Res> {
  factory _$MovementPlaceCopyWith(_MovementPlace value, $Res Function(_MovementPlace) _then) = __$MovementPlaceCopyWithImpl;
@override @useResult
$Res call({
 int id, String name
});




}
/// @nodoc
class __$MovementPlaceCopyWithImpl<$Res>
    implements _$MovementPlaceCopyWith<$Res> {
  __$MovementPlaceCopyWithImpl(this._self, this._then);

  final _MovementPlace _self;
  final $Res Function(_MovementPlace) _then;

/// Create a copy of MovementPlace
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_MovementPlace(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$MovementActor {

 int get id; String get name;@JsonKey(name: 'employee_code') String? get employeeCode;
/// Create a copy of MovementActor
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MovementActorCopyWith<MovementActor> get copyWith => _$MovementActorCopyWithImpl<MovementActor>(this as MovementActor, _$identity);

  /// Serializes this MovementActor to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MovementActor&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.employeeCode, employeeCode) || other.employeeCode == employeeCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,employeeCode);

@override
String toString() {
  return 'MovementActor(id: $id, name: $name, employeeCode: $employeeCode)';
}


}

/// @nodoc
abstract mixin class $MovementActorCopyWith<$Res>  {
  factory $MovementActorCopyWith(MovementActor value, $Res Function(MovementActor) _then) = _$MovementActorCopyWithImpl;
@useResult
$Res call({
 int id, String name,@JsonKey(name: 'employee_code') String? employeeCode
});




}
/// @nodoc
class _$MovementActorCopyWithImpl<$Res>
    implements $MovementActorCopyWith<$Res> {
  _$MovementActorCopyWithImpl(this._self, this._then);

  final MovementActor _self;
  final $Res Function(MovementActor) _then;

/// Create a copy of MovementActor
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? employeeCode = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,employeeCode: freezed == employeeCode ? _self.employeeCode : employeeCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MovementActor].
extension MovementActorPatterns on MovementActor {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MovementActor value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MovementActor() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MovementActor value)  $default,){
final _that = this;
switch (_that) {
case _MovementActor():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MovementActor value)?  $default,){
final _that = this;
switch (_that) {
case _MovementActor() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'employee_code')  String? employeeCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MovementActor() when $default != null:
return $default(_that.id,_that.name,_that.employeeCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'employee_code')  String? employeeCode)  $default,) {final _that = this;
switch (_that) {
case _MovementActor():
return $default(_that.id,_that.name,_that.employeeCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name, @JsonKey(name: 'employee_code')  String? employeeCode)?  $default,) {final _that = this;
switch (_that) {
case _MovementActor() when $default != null:
return $default(_that.id,_that.name,_that.employeeCode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MovementActor implements MovementActor {
  const _MovementActor({required this.id, required this.name, @JsonKey(name: 'employee_code') this.employeeCode});
  factory _MovementActor.fromJson(Map<String, dynamic> json) => _$MovementActorFromJson(json);

@override final  int id;
@override final  String name;
@override@JsonKey(name: 'employee_code') final  String? employeeCode;

/// Create a copy of MovementActor
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MovementActorCopyWith<_MovementActor> get copyWith => __$MovementActorCopyWithImpl<_MovementActor>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MovementActorToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MovementActor&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.employeeCode, employeeCode) || other.employeeCode == employeeCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,employeeCode);

@override
String toString() {
  return 'MovementActor(id: $id, name: $name, employeeCode: $employeeCode)';
}


}

/// @nodoc
abstract mixin class _$MovementActorCopyWith<$Res> implements $MovementActorCopyWith<$Res> {
  factory _$MovementActorCopyWith(_MovementActor value, $Res Function(_MovementActor) _then) = __$MovementActorCopyWithImpl;
@override @useResult
$Res call({
 int id, String name,@JsonKey(name: 'employee_code') String? employeeCode
});




}
/// @nodoc
class __$MovementActorCopyWithImpl<$Res>
    implements _$MovementActorCopyWith<$Res> {
  __$MovementActorCopyWithImpl(this._self, this._then);

  final _MovementActor _self;
  final $Res Function(_MovementActor) _then;

/// Create a copy of MovementActor
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? employeeCode = freezed,}) {
  return _then(_MovementActor(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,employeeCode: freezed == employeeCode ? _self.employeeCode : employeeCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
