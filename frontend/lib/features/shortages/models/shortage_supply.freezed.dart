// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shortage_supply.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ShortageSupply {

 int get id;@JsonKey(name: 'shortage_id') int get shortageId;@JsonKey(unknownEnumValue: SupplyKind.unknown) SupplyKind get kind;@JsonKey(name: 'kind_label') String get kindLabel;/// Negative on a reversal, which is how the ledger adds up to the remainder.
 String get quantity;/// **Null on a `resolved_externally` row**, and the reason the table prints a dash rather
/// than a zero there.
 String? get amount; String? get method;@JsonKey(name: 'method_label') String? get methodLabel; String? get reference;/// A plain day, held as a `String` for the reason `PnlPeriod` holds its two: round-tripping
/// one through a `DateTime` is how a date grows a timezone offset it never had.
@JsonKey(name: 'occurred_on') String? get occurredOn; String? get notes;@JsonKey(name: 'warehouse_id') int? get warehouseId; ShortageSupplyWarehouseRef? get warehouse;@JsonKey(name: 'stock_movement_id') int? get stockMovementId;/// Whether the goods actually landed on a shelf. See the class note.
@JsonKey(name: 'moved_stock') bool get movedStock;@JsonKey(name: 'is_reversal') bool get isReversal;@JsonKey(name: 'is_reversed') bool get isReversed;/// Whether this row may be undone. **The server has already decided** that an arrival from
/// the order and a reversal are not candidates, so the cancel action is drawn off this and
/// never off [kind].
@JsonKey(name: 'is_reversible') bool get isReversible;/// **الواصل — the paper this purchase was made with, when there was one.**
///
/// Optional on every method here, unlike a customer's payment: a sack bought from the shop
/// next door often comes with nothing, and the entry is worth having either way. The four
/// keys are the server's own answers — whether it is a picture is decided from the bytes it
/// stored, so no format list lives in this app.
@JsonKey(name: 'has_receipt') bool get hasReceipt;@JsonKey(name: 'receipt_is_image') bool get receiptIsImage;@JsonKey(name: 'receipt_url') String? get receiptUrl;@JsonKey(name: 'receipt_filename') String? get receiptFilename;@JsonKey(name: 'reverses_supply_id') int? get reversesSupplyId;@JsonKey(name: 'recorded_by_user_id') int? get recordedByUserId; ShortageSupplyPersonRef? get recorder;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of ShortageSupply
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShortageSupplyCopyWith<ShortageSupply> get copyWith => _$ShortageSupplyCopyWithImpl<ShortageSupply>(this as ShortageSupply, _$identity);

  /// Serializes this ShortageSupply to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShortageSupply&&(identical(other.id, id) || other.id == id)&&(identical(other.shortageId, shortageId) || other.shortageId == shortageId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.kindLabel, kindLabel) || other.kindLabel == kindLabel)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.method, method) || other.method == method)&&(identical(other.methodLabel, methodLabel) || other.methodLabel == methodLabel)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.occurredOn, occurredOn) || other.occurredOn == occurredOn)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.warehouseId, warehouseId) || other.warehouseId == warehouseId)&&(identical(other.warehouse, warehouse) || other.warehouse == warehouse)&&(identical(other.stockMovementId, stockMovementId) || other.stockMovementId == stockMovementId)&&(identical(other.movedStock, movedStock) || other.movedStock == movedStock)&&(identical(other.isReversal, isReversal) || other.isReversal == isReversal)&&(identical(other.isReversed, isReversed) || other.isReversed == isReversed)&&(identical(other.isReversible, isReversible) || other.isReversible == isReversible)&&(identical(other.hasReceipt, hasReceipt) || other.hasReceipt == hasReceipt)&&(identical(other.receiptIsImage, receiptIsImage) || other.receiptIsImage == receiptIsImage)&&(identical(other.receiptUrl, receiptUrl) || other.receiptUrl == receiptUrl)&&(identical(other.receiptFilename, receiptFilename) || other.receiptFilename == receiptFilename)&&(identical(other.reversesSupplyId, reversesSupplyId) || other.reversesSupplyId == reversesSupplyId)&&(identical(other.recordedByUserId, recordedByUserId) || other.recordedByUserId == recordedByUserId)&&(identical(other.recorder, recorder) || other.recorder == recorder)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,shortageId,kind,kindLabel,quantity,amount,method,methodLabel,reference,occurredOn,notes,warehouseId,warehouse,stockMovementId,movedStock,isReversal,isReversed,isReversible,hasReceipt,receiptIsImage,receiptUrl,receiptFilename,reversesSupplyId,recordedByUserId,recorder,createdAt]);

@override
String toString() {
  return 'ShortageSupply(id: $id, shortageId: $shortageId, kind: $kind, kindLabel: $kindLabel, quantity: $quantity, amount: $amount, method: $method, methodLabel: $methodLabel, reference: $reference, occurredOn: $occurredOn, notes: $notes, warehouseId: $warehouseId, warehouse: $warehouse, stockMovementId: $stockMovementId, movedStock: $movedStock, isReversal: $isReversal, isReversed: $isReversed, isReversible: $isReversible, hasReceipt: $hasReceipt, receiptIsImage: $receiptIsImage, receiptUrl: $receiptUrl, receiptFilename: $receiptFilename, reversesSupplyId: $reversesSupplyId, recordedByUserId: $recordedByUserId, recorder: $recorder, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ShortageSupplyCopyWith<$Res>  {
  factory $ShortageSupplyCopyWith(ShortageSupply value, $Res Function(ShortageSupply) _then) = _$ShortageSupplyCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'shortage_id') int shortageId,@JsonKey(unknownEnumValue: SupplyKind.unknown) SupplyKind kind,@JsonKey(name: 'kind_label') String kindLabel, String quantity, String? amount, String? method,@JsonKey(name: 'method_label') String? methodLabel, String? reference,@JsonKey(name: 'occurred_on') String? occurredOn, String? notes,@JsonKey(name: 'warehouse_id') int? warehouseId, ShortageSupplyWarehouseRef? warehouse,@JsonKey(name: 'stock_movement_id') int? stockMovementId,@JsonKey(name: 'moved_stock') bool movedStock,@JsonKey(name: 'is_reversal') bool isReversal,@JsonKey(name: 'is_reversed') bool isReversed,@JsonKey(name: 'is_reversible') bool isReversible,@JsonKey(name: 'has_receipt') bool hasReceipt,@JsonKey(name: 'receipt_is_image') bool receiptIsImage,@JsonKey(name: 'receipt_url') String? receiptUrl,@JsonKey(name: 'receipt_filename') String? receiptFilename,@JsonKey(name: 'reverses_supply_id') int? reversesSupplyId,@JsonKey(name: 'recorded_by_user_id') int? recordedByUserId, ShortageSupplyPersonRef? recorder,@JsonKey(name: 'created_at') DateTime? createdAt
});


$ShortageSupplyWarehouseRefCopyWith<$Res>? get warehouse;$ShortageSupplyPersonRefCopyWith<$Res>? get recorder;

}
/// @nodoc
class _$ShortageSupplyCopyWithImpl<$Res>
    implements $ShortageSupplyCopyWith<$Res> {
  _$ShortageSupplyCopyWithImpl(this._self, this._then);

  final ShortageSupply _self;
  final $Res Function(ShortageSupply) _then;

/// Create a copy of ShortageSupply
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? shortageId = null,Object? kind = null,Object? kindLabel = null,Object? quantity = null,Object? amount = freezed,Object? method = freezed,Object? methodLabel = freezed,Object? reference = freezed,Object? occurredOn = freezed,Object? notes = freezed,Object? warehouseId = freezed,Object? warehouse = freezed,Object? stockMovementId = freezed,Object? movedStock = null,Object? isReversal = null,Object? isReversed = null,Object? isReversible = null,Object? hasReceipt = null,Object? receiptIsImage = null,Object? receiptUrl = freezed,Object? receiptFilename = freezed,Object? reversesSupplyId = freezed,Object? recordedByUserId = freezed,Object? recorder = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,shortageId: null == shortageId ? _self.shortageId : shortageId // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as SupplyKind,kindLabel: null == kindLabel ? _self.kindLabel : kindLabel // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String?,method: freezed == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String?,methodLabel: freezed == methodLabel ? _self.methodLabel : methodLabel // ignore: cast_nullable_to_non_nullable
as String?,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,occurredOn: freezed == occurredOn ? _self.occurredOn : occurredOn // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,warehouseId: freezed == warehouseId ? _self.warehouseId : warehouseId // ignore: cast_nullable_to_non_nullable
as int?,warehouse: freezed == warehouse ? _self.warehouse : warehouse // ignore: cast_nullable_to_non_nullable
as ShortageSupplyWarehouseRef?,stockMovementId: freezed == stockMovementId ? _self.stockMovementId : stockMovementId // ignore: cast_nullable_to_non_nullable
as int?,movedStock: null == movedStock ? _self.movedStock : movedStock // ignore: cast_nullable_to_non_nullable
as bool,isReversal: null == isReversal ? _self.isReversal : isReversal // ignore: cast_nullable_to_non_nullable
as bool,isReversed: null == isReversed ? _self.isReversed : isReversed // ignore: cast_nullable_to_non_nullable
as bool,isReversible: null == isReversible ? _self.isReversible : isReversible // ignore: cast_nullable_to_non_nullable
as bool,hasReceipt: null == hasReceipt ? _self.hasReceipt : hasReceipt // ignore: cast_nullable_to_non_nullable
as bool,receiptIsImage: null == receiptIsImage ? _self.receiptIsImage : receiptIsImage // ignore: cast_nullable_to_non_nullable
as bool,receiptUrl: freezed == receiptUrl ? _self.receiptUrl : receiptUrl // ignore: cast_nullable_to_non_nullable
as String?,receiptFilename: freezed == receiptFilename ? _self.receiptFilename : receiptFilename // ignore: cast_nullable_to_non_nullable
as String?,reversesSupplyId: freezed == reversesSupplyId ? _self.reversesSupplyId : reversesSupplyId // ignore: cast_nullable_to_non_nullable
as int?,recordedByUserId: freezed == recordedByUserId ? _self.recordedByUserId : recordedByUserId // ignore: cast_nullable_to_non_nullable
as int?,recorder: freezed == recorder ? _self.recorder : recorder // ignore: cast_nullable_to_non_nullable
as ShortageSupplyPersonRef?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of ShortageSupply
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShortageSupplyWarehouseRefCopyWith<$Res>? get warehouse {
    if (_self.warehouse == null) {
    return null;
  }

  return $ShortageSupplyWarehouseRefCopyWith<$Res>(_self.warehouse!, (value) {
    return _then(_self.copyWith(warehouse: value));
  });
}/// Create a copy of ShortageSupply
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShortageSupplyPersonRefCopyWith<$Res>? get recorder {
    if (_self.recorder == null) {
    return null;
  }

  return $ShortageSupplyPersonRefCopyWith<$Res>(_self.recorder!, (value) {
    return _then(_self.copyWith(recorder: value));
  });
}
}


/// Adds pattern-matching-related methods to [ShortageSupply].
extension ShortageSupplyPatterns on ShortageSupply {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShortageSupply value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShortageSupply() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShortageSupply value)  $default,){
final _that = this;
switch (_that) {
case _ShortageSupply():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShortageSupply value)?  $default,){
final _that = this;
switch (_that) {
case _ShortageSupply() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'shortage_id')  int shortageId, @JsonKey(unknownEnumValue: SupplyKind.unknown)  SupplyKind kind, @JsonKey(name: 'kind_label')  String kindLabel,  String quantity,  String? amount,  String? method, @JsonKey(name: 'method_label')  String? methodLabel,  String? reference, @JsonKey(name: 'occurred_on')  String? occurredOn,  String? notes, @JsonKey(name: 'warehouse_id')  int? warehouseId,  ShortageSupplyWarehouseRef? warehouse, @JsonKey(name: 'stock_movement_id')  int? stockMovementId, @JsonKey(name: 'moved_stock')  bool movedStock, @JsonKey(name: 'is_reversal')  bool isReversal, @JsonKey(name: 'is_reversed')  bool isReversed, @JsonKey(name: 'is_reversible')  bool isReversible, @JsonKey(name: 'has_receipt')  bool hasReceipt, @JsonKey(name: 'receipt_is_image')  bool receiptIsImage, @JsonKey(name: 'receipt_url')  String? receiptUrl, @JsonKey(name: 'receipt_filename')  String? receiptFilename, @JsonKey(name: 'reverses_supply_id')  int? reversesSupplyId, @JsonKey(name: 'recorded_by_user_id')  int? recordedByUserId,  ShortageSupplyPersonRef? recorder, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShortageSupply() when $default != null:
return $default(_that.id,_that.shortageId,_that.kind,_that.kindLabel,_that.quantity,_that.amount,_that.method,_that.methodLabel,_that.reference,_that.occurredOn,_that.notes,_that.warehouseId,_that.warehouse,_that.stockMovementId,_that.movedStock,_that.isReversal,_that.isReversed,_that.isReversible,_that.hasReceipt,_that.receiptIsImage,_that.receiptUrl,_that.receiptFilename,_that.reversesSupplyId,_that.recordedByUserId,_that.recorder,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'shortage_id')  int shortageId, @JsonKey(unknownEnumValue: SupplyKind.unknown)  SupplyKind kind, @JsonKey(name: 'kind_label')  String kindLabel,  String quantity,  String? amount,  String? method, @JsonKey(name: 'method_label')  String? methodLabel,  String? reference, @JsonKey(name: 'occurred_on')  String? occurredOn,  String? notes, @JsonKey(name: 'warehouse_id')  int? warehouseId,  ShortageSupplyWarehouseRef? warehouse, @JsonKey(name: 'stock_movement_id')  int? stockMovementId, @JsonKey(name: 'moved_stock')  bool movedStock, @JsonKey(name: 'is_reversal')  bool isReversal, @JsonKey(name: 'is_reversed')  bool isReversed, @JsonKey(name: 'is_reversible')  bool isReversible, @JsonKey(name: 'has_receipt')  bool hasReceipt, @JsonKey(name: 'receipt_is_image')  bool receiptIsImage, @JsonKey(name: 'receipt_url')  String? receiptUrl, @JsonKey(name: 'receipt_filename')  String? receiptFilename, @JsonKey(name: 'reverses_supply_id')  int? reversesSupplyId, @JsonKey(name: 'recorded_by_user_id')  int? recordedByUserId,  ShortageSupplyPersonRef? recorder, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _ShortageSupply():
return $default(_that.id,_that.shortageId,_that.kind,_that.kindLabel,_that.quantity,_that.amount,_that.method,_that.methodLabel,_that.reference,_that.occurredOn,_that.notes,_that.warehouseId,_that.warehouse,_that.stockMovementId,_that.movedStock,_that.isReversal,_that.isReversed,_that.isReversible,_that.hasReceipt,_that.receiptIsImage,_that.receiptUrl,_that.receiptFilename,_that.reversesSupplyId,_that.recordedByUserId,_that.recorder,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'shortage_id')  int shortageId, @JsonKey(unknownEnumValue: SupplyKind.unknown)  SupplyKind kind, @JsonKey(name: 'kind_label')  String kindLabel,  String quantity,  String? amount,  String? method, @JsonKey(name: 'method_label')  String? methodLabel,  String? reference, @JsonKey(name: 'occurred_on')  String? occurredOn,  String? notes, @JsonKey(name: 'warehouse_id')  int? warehouseId,  ShortageSupplyWarehouseRef? warehouse, @JsonKey(name: 'stock_movement_id')  int? stockMovementId, @JsonKey(name: 'moved_stock')  bool movedStock, @JsonKey(name: 'is_reversal')  bool isReversal, @JsonKey(name: 'is_reversed')  bool isReversed, @JsonKey(name: 'is_reversible')  bool isReversible, @JsonKey(name: 'has_receipt')  bool hasReceipt, @JsonKey(name: 'receipt_is_image')  bool receiptIsImage, @JsonKey(name: 'receipt_url')  String? receiptUrl, @JsonKey(name: 'receipt_filename')  String? receiptFilename, @JsonKey(name: 'reverses_supply_id')  int? reversesSupplyId, @JsonKey(name: 'recorded_by_user_id')  int? recordedByUserId,  ShortageSupplyPersonRef? recorder, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ShortageSupply() when $default != null:
return $default(_that.id,_that.shortageId,_that.kind,_that.kindLabel,_that.quantity,_that.amount,_that.method,_that.methodLabel,_that.reference,_that.occurredOn,_that.notes,_that.warehouseId,_that.warehouse,_that.stockMovementId,_that.movedStock,_that.isReversal,_that.isReversed,_that.isReversible,_that.hasReceipt,_that.receiptIsImage,_that.receiptUrl,_that.receiptFilename,_that.reversesSupplyId,_that.recordedByUserId,_that.recorder,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShortageSupply extends ShortageSupply {
  const _ShortageSupply({required this.id, @JsonKey(name: 'shortage_id') required this.shortageId, @JsonKey(unknownEnumValue: SupplyKind.unknown) required this.kind, @JsonKey(name: 'kind_label') required this.kindLabel, required this.quantity, this.amount, this.method, @JsonKey(name: 'method_label') this.methodLabel, this.reference, @JsonKey(name: 'occurred_on') this.occurredOn, this.notes, @JsonKey(name: 'warehouse_id') this.warehouseId, this.warehouse, @JsonKey(name: 'stock_movement_id') this.stockMovementId, @JsonKey(name: 'moved_stock') this.movedStock = false, @JsonKey(name: 'is_reversal') this.isReversal = false, @JsonKey(name: 'is_reversed') this.isReversed = false, @JsonKey(name: 'is_reversible') this.isReversible = false, @JsonKey(name: 'has_receipt') this.hasReceipt = false, @JsonKey(name: 'receipt_is_image') this.receiptIsImage = false, @JsonKey(name: 'receipt_url') this.receiptUrl, @JsonKey(name: 'receipt_filename') this.receiptFilename, @JsonKey(name: 'reverses_supply_id') this.reversesSupplyId, @JsonKey(name: 'recorded_by_user_id') this.recordedByUserId, this.recorder, @JsonKey(name: 'created_at') this.createdAt}): super._();
  factory _ShortageSupply.fromJson(Map<String, dynamic> json) => _$ShortageSupplyFromJson(json);

@override final  int id;
@override@JsonKey(name: 'shortage_id') final  int shortageId;
@override@JsonKey(unknownEnumValue: SupplyKind.unknown) final  SupplyKind kind;
@override@JsonKey(name: 'kind_label') final  String kindLabel;
/// Negative on a reversal, which is how the ledger adds up to the remainder.
@override final  String quantity;
/// **Null on a `resolved_externally` row**, and the reason the table prints a dash rather
/// than a zero there.
@override final  String? amount;
@override final  String? method;
@override@JsonKey(name: 'method_label') final  String? methodLabel;
@override final  String? reference;
/// A plain day, held as a `String` for the reason `PnlPeriod` holds its two: round-tripping
/// one through a `DateTime` is how a date grows a timezone offset it never had.
@override@JsonKey(name: 'occurred_on') final  String? occurredOn;
@override final  String? notes;
@override@JsonKey(name: 'warehouse_id') final  int? warehouseId;
@override final  ShortageSupplyWarehouseRef? warehouse;
@override@JsonKey(name: 'stock_movement_id') final  int? stockMovementId;
/// Whether the goods actually landed on a shelf. See the class note.
@override@JsonKey(name: 'moved_stock') final  bool movedStock;
@override@JsonKey(name: 'is_reversal') final  bool isReversal;
@override@JsonKey(name: 'is_reversed') final  bool isReversed;
/// Whether this row may be undone. **The server has already decided** that an arrival from
/// the order and a reversal are not candidates, so the cancel action is drawn off this and
/// never off [kind].
@override@JsonKey(name: 'is_reversible') final  bool isReversible;
/// **الواصل — the paper this purchase was made with, when there was one.**
///
/// Optional on every method here, unlike a customer's payment: a sack bought from the shop
/// next door often comes with nothing, and the entry is worth having either way. The four
/// keys are the server's own answers — whether it is a picture is decided from the bytes it
/// stored, so no format list lives in this app.
@override@JsonKey(name: 'has_receipt') final  bool hasReceipt;
@override@JsonKey(name: 'receipt_is_image') final  bool receiptIsImage;
@override@JsonKey(name: 'receipt_url') final  String? receiptUrl;
@override@JsonKey(name: 'receipt_filename') final  String? receiptFilename;
@override@JsonKey(name: 'reverses_supply_id') final  int? reversesSupplyId;
@override@JsonKey(name: 'recorded_by_user_id') final  int? recordedByUserId;
@override final  ShortageSupplyPersonRef? recorder;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of ShortageSupply
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShortageSupplyCopyWith<_ShortageSupply> get copyWith => __$ShortageSupplyCopyWithImpl<_ShortageSupply>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShortageSupplyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShortageSupply&&(identical(other.id, id) || other.id == id)&&(identical(other.shortageId, shortageId) || other.shortageId == shortageId)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.kindLabel, kindLabel) || other.kindLabel == kindLabel)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.method, method) || other.method == method)&&(identical(other.methodLabel, methodLabel) || other.methodLabel == methodLabel)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.occurredOn, occurredOn) || other.occurredOn == occurredOn)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.warehouseId, warehouseId) || other.warehouseId == warehouseId)&&(identical(other.warehouse, warehouse) || other.warehouse == warehouse)&&(identical(other.stockMovementId, stockMovementId) || other.stockMovementId == stockMovementId)&&(identical(other.movedStock, movedStock) || other.movedStock == movedStock)&&(identical(other.isReversal, isReversal) || other.isReversal == isReversal)&&(identical(other.isReversed, isReversed) || other.isReversed == isReversed)&&(identical(other.isReversible, isReversible) || other.isReversible == isReversible)&&(identical(other.hasReceipt, hasReceipt) || other.hasReceipt == hasReceipt)&&(identical(other.receiptIsImage, receiptIsImage) || other.receiptIsImage == receiptIsImage)&&(identical(other.receiptUrl, receiptUrl) || other.receiptUrl == receiptUrl)&&(identical(other.receiptFilename, receiptFilename) || other.receiptFilename == receiptFilename)&&(identical(other.reversesSupplyId, reversesSupplyId) || other.reversesSupplyId == reversesSupplyId)&&(identical(other.recordedByUserId, recordedByUserId) || other.recordedByUserId == recordedByUserId)&&(identical(other.recorder, recorder) || other.recorder == recorder)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,shortageId,kind,kindLabel,quantity,amount,method,methodLabel,reference,occurredOn,notes,warehouseId,warehouse,stockMovementId,movedStock,isReversal,isReversed,isReversible,hasReceipt,receiptIsImage,receiptUrl,receiptFilename,reversesSupplyId,recordedByUserId,recorder,createdAt]);

@override
String toString() {
  return 'ShortageSupply(id: $id, shortageId: $shortageId, kind: $kind, kindLabel: $kindLabel, quantity: $quantity, amount: $amount, method: $method, methodLabel: $methodLabel, reference: $reference, occurredOn: $occurredOn, notes: $notes, warehouseId: $warehouseId, warehouse: $warehouse, stockMovementId: $stockMovementId, movedStock: $movedStock, isReversal: $isReversal, isReversed: $isReversed, isReversible: $isReversible, hasReceipt: $hasReceipt, receiptIsImage: $receiptIsImage, receiptUrl: $receiptUrl, receiptFilename: $receiptFilename, reversesSupplyId: $reversesSupplyId, recordedByUserId: $recordedByUserId, recorder: $recorder, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ShortageSupplyCopyWith<$Res> implements $ShortageSupplyCopyWith<$Res> {
  factory _$ShortageSupplyCopyWith(_ShortageSupply value, $Res Function(_ShortageSupply) _then) = __$ShortageSupplyCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'shortage_id') int shortageId,@JsonKey(unknownEnumValue: SupplyKind.unknown) SupplyKind kind,@JsonKey(name: 'kind_label') String kindLabel, String quantity, String? amount, String? method,@JsonKey(name: 'method_label') String? methodLabel, String? reference,@JsonKey(name: 'occurred_on') String? occurredOn, String? notes,@JsonKey(name: 'warehouse_id') int? warehouseId, ShortageSupplyWarehouseRef? warehouse,@JsonKey(name: 'stock_movement_id') int? stockMovementId,@JsonKey(name: 'moved_stock') bool movedStock,@JsonKey(name: 'is_reversal') bool isReversal,@JsonKey(name: 'is_reversed') bool isReversed,@JsonKey(name: 'is_reversible') bool isReversible,@JsonKey(name: 'has_receipt') bool hasReceipt,@JsonKey(name: 'receipt_is_image') bool receiptIsImage,@JsonKey(name: 'receipt_url') String? receiptUrl,@JsonKey(name: 'receipt_filename') String? receiptFilename,@JsonKey(name: 'reverses_supply_id') int? reversesSupplyId,@JsonKey(name: 'recorded_by_user_id') int? recordedByUserId, ShortageSupplyPersonRef? recorder,@JsonKey(name: 'created_at') DateTime? createdAt
});


@override $ShortageSupplyWarehouseRefCopyWith<$Res>? get warehouse;@override $ShortageSupplyPersonRefCopyWith<$Res>? get recorder;

}
/// @nodoc
class __$ShortageSupplyCopyWithImpl<$Res>
    implements _$ShortageSupplyCopyWith<$Res> {
  __$ShortageSupplyCopyWithImpl(this._self, this._then);

  final _ShortageSupply _self;
  final $Res Function(_ShortageSupply) _then;

/// Create a copy of ShortageSupply
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? shortageId = null,Object? kind = null,Object? kindLabel = null,Object? quantity = null,Object? amount = freezed,Object? method = freezed,Object? methodLabel = freezed,Object? reference = freezed,Object? occurredOn = freezed,Object? notes = freezed,Object? warehouseId = freezed,Object? warehouse = freezed,Object? stockMovementId = freezed,Object? movedStock = null,Object? isReversal = null,Object? isReversed = null,Object? isReversible = null,Object? hasReceipt = null,Object? receiptIsImage = null,Object? receiptUrl = freezed,Object? receiptFilename = freezed,Object? reversesSupplyId = freezed,Object? recordedByUserId = freezed,Object? recorder = freezed,Object? createdAt = freezed,}) {
  return _then(_ShortageSupply(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,shortageId: null == shortageId ? _self.shortageId : shortageId // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as SupplyKind,kindLabel: null == kindLabel ? _self.kindLabel : kindLabel // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String?,method: freezed == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String?,methodLabel: freezed == methodLabel ? _self.methodLabel : methodLabel // ignore: cast_nullable_to_non_nullable
as String?,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,occurredOn: freezed == occurredOn ? _self.occurredOn : occurredOn // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,warehouseId: freezed == warehouseId ? _self.warehouseId : warehouseId // ignore: cast_nullable_to_non_nullable
as int?,warehouse: freezed == warehouse ? _self.warehouse : warehouse // ignore: cast_nullable_to_non_nullable
as ShortageSupplyWarehouseRef?,stockMovementId: freezed == stockMovementId ? _self.stockMovementId : stockMovementId // ignore: cast_nullable_to_non_nullable
as int?,movedStock: null == movedStock ? _self.movedStock : movedStock // ignore: cast_nullable_to_non_nullable
as bool,isReversal: null == isReversal ? _self.isReversal : isReversal // ignore: cast_nullable_to_non_nullable
as bool,isReversed: null == isReversed ? _self.isReversed : isReversed // ignore: cast_nullable_to_non_nullable
as bool,isReversible: null == isReversible ? _self.isReversible : isReversible // ignore: cast_nullable_to_non_nullable
as bool,hasReceipt: null == hasReceipt ? _self.hasReceipt : hasReceipt // ignore: cast_nullable_to_non_nullable
as bool,receiptIsImage: null == receiptIsImage ? _self.receiptIsImage : receiptIsImage // ignore: cast_nullable_to_non_nullable
as bool,receiptUrl: freezed == receiptUrl ? _self.receiptUrl : receiptUrl // ignore: cast_nullable_to_non_nullable
as String?,receiptFilename: freezed == receiptFilename ? _self.receiptFilename : receiptFilename // ignore: cast_nullable_to_non_nullable
as String?,reversesSupplyId: freezed == reversesSupplyId ? _self.reversesSupplyId : reversesSupplyId // ignore: cast_nullable_to_non_nullable
as int?,recordedByUserId: freezed == recordedByUserId ? _self.recordedByUserId : recordedByUserId // ignore: cast_nullable_to_non_nullable
as int?,recorder: freezed == recorder ? _self.recorder : recorder // ignore: cast_nullable_to_non_nullable
as ShortageSupplyPersonRef?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of ShortageSupply
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShortageSupplyWarehouseRefCopyWith<$Res>? get warehouse {
    if (_self.warehouse == null) {
    return null;
  }

  return $ShortageSupplyWarehouseRefCopyWith<$Res>(_self.warehouse!, (value) {
    return _then(_self.copyWith(warehouse: value));
  });
}/// Create a copy of ShortageSupply
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShortageSupplyPersonRefCopyWith<$Res>? get recorder {
    if (_self.recorder == null) {
    return null;
  }

  return $ShortageSupplyPersonRefCopyWith<$Res>(_self.recorder!, (value) {
    return _then(_self.copyWith(recorder: value));
  });
}
}


/// @nodoc
mixin _$ShortageSupplyWarehouseRef {

 int get id; String get name;
/// Create a copy of ShortageSupplyWarehouseRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShortageSupplyWarehouseRefCopyWith<ShortageSupplyWarehouseRef> get copyWith => _$ShortageSupplyWarehouseRefCopyWithImpl<ShortageSupplyWarehouseRef>(this as ShortageSupplyWarehouseRef, _$identity);

  /// Serializes this ShortageSupplyWarehouseRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShortageSupplyWarehouseRef&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'ShortageSupplyWarehouseRef(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $ShortageSupplyWarehouseRefCopyWith<$Res>  {
  factory $ShortageSupplyWarehouseRefCopyWith(ShortageSupplyWarehouseRef value, $Res Function(ShortageSupplyWarehouseRef) _then) = _$ShortageSupplyWarehouseRefCopyWithImpl;
@useResult
$Res call({
 int id, String name
});




}
/// @nodoc
class _$ShortageSupplyWarehouseRefCopyWithImpl<$Res>
    implements $ShortageSupplyWarehouseRefCopyWith<$Res> {
  _$ShortageSupplyWarehouseRefCopyWithImpl(this._self, this._then);

  final ShortageSupplyWarehouseRef _self;
  final $Res Function(ShortageSupplyWarehouseRef) _then;

/// Create a copy of ShortageSupplyWarehouseRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ShortageSupplyWarehouseRef].
extension ShortageSupplyWarehouseRefPatterns on ShortageSupplyWarehouseRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShortageSupplyWarehouseRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShortageSupplyWarehouseRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShortageSupplyWarehouseRef value)  $default,){
final _that = this;
switch (_that) {
case _ShortageSupplyWarehouseRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShortageSupplyWarehouseRef value)?  $default,){
final _that = this;
switch (_that) {
case _ShortageSupplyWarehouseRef() when $default != null:
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
case _ShortageSupplyWarehouseRef() when $default != null:
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
case _ShortageSupplyWarehouseRef():
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
case _ShortageSupplyWarehouseRef() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShortageSupplyWarehouseRef implements ShortageSupplyWarehouseRef {
  const _ShortageSupplyWarehouseRef({required this.id, required this.name});
  factory _ShortageSupplyWarehouseRef.fromJson(Map<String, dynamic> json) => _$ShortageSupplyWarehouseRefFromJson(json);

@override final  int id;
@override final  String name;

/// Create a copy of ShortageSupplyWarehouseRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShortageSupplyWarehouseRefCopyWith<_ShortageSupplyWarehouseRef> get copyWith => __$ShortageSupplyWarehouseRefCopyWithImpl<_ShortageSupplyWarehouseRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShortageSupplyWarehouseRefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShortageSupplyWarehouseRef&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'ShortageSupplyWarehouseRef(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$ShortageSupplyWarehouseRefCopyWith<$Res> implements $ShortageSupplyWarehouseRefCopyWith<$Res> {
  factory _$ShortageSupplyWarehouseRefCopyWith(_ShortageSupplyWarehouseRef value, $Res Function(_ShortageSupplyWarehouseRef) _then) = __$ShortageSupplyWarehouseRefCopyWithImpl;
@override @useResult
$Res call({
 int id, String name
});




}
/// @nodoc
class __$ShortageSupplyWarehouseRefCopyWithImpl<$Res>
    implements _$ShortageSupplyWarehouseRefCopyWith<$Res> {
  __$ShortageSupplyWarehouseRefCopyWithImpl(this._self, this._then);

  final _ShortageSupplyWarehouseRef _self;
  final $Res Function(_ShortageSupplyWarehouseRef) _then;

/// Create a copy of ShortageSupplyWarehouseRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_ShortageSupplyWarehouseRef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ShortageSupplyPersonRef {

 int get id; String get name;@JsonKey(name: 'employee_code') String? get employeeCode;
/// Create a copy of ShortageSupplyPersonRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShortageSupplyPersonRefCopyWith<ShortageSupplyPersonRef> get copyWith => _$ShortageSupplyPersonRefCopyWithImpl<ShortageSupplyPersonRef>(this as ShortageSupplyPersonRef, _$identity);

  /// Serializes this ShortageSupplyPersonRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShortageSupplyPersonRef&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.employeeCode, employeeCode) || other.employeeCode == employeeCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,employeeCode);

@override
String toString() {
  return 'ShortageSupplyPersonRef(id: $id, name: $name, employeeCode: $employeeCode)';
}


}

/// @nodoc
abstract mixin class $ShortageSupplyPersonRefCopyWith<$Res>  {
  factory $ShortageSupplyPersonRefCopyWith(ShortageSupplyPersonRef value, $Res Function(ShortageSupplyPersonRef) _then) = _$ShortageSupplyPersonRefCopyWithImpl;
@useResult
$Res call({
 int id, String name,@JsonKey(name: 'employee_code') String? employeeCode
});




}
/// @nodoc
class _$ShortageSupplyPersonRefCopyWithImpl<$Res>
    implements $ShortageSupplyPersonRefCopyWith<$Res> {
  _$ShortageSupplyPersonRefCopyWithImpl(this._self, this._then);

  final ShortageSupplyPersonRef _self;
  final $Res Function(ShortageSupplyPersonRef) _then;

/// Create a copy of ShortageSupplyPersonRef
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


/// Adds pattern-matching-related methods to [ShortageSupplyPersonRef].
extension ShortageSupplyPersonRefPatterns on ShortageSupplyPersonRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShortageSupplyPersonRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShortageSupplyPersonRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShortageSupplyPersonRef value)  $default,){
final _that = this;
switch (_that) {
case _ShortageSupplyPersonRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShortageSupplyPersonRef value)?  $default,){
final _that = this;
switch (_that) {
case _ShortageSupplyPersonRef() when $default != null:
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
case _ShortageSupplyPersonRef() when $default != null:
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
case _ShortageSupplyPersonRef():
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
case _ShortageSupplyPersonRef() when $default != null:
return $default(_that.id,_that.name,_that.employeeCode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShortageSupplyPersonRef implements ShortageSupplyPersonRef {
  const _ShortageSupplyPersonRef({required this.id, required this.name, @JsonKey(name: 'employee_code') this.employeeCode});
  factory _ShortageSupplyPersonRef.fromJson(Map<String, dynamic> json) => _$ShortageSupplyPersonRefFromJson(json);

@override final  int id;
@override final  String name;
@override@JsonKey(name: 'employee_code') final  String? employeeCode;

/// Create a copy of ShortageSupplyPersonRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShortageSupplyPersonRefCopyWith<_ShortageSupplyPersonRef> get copyWith => __$ShortageSupplyPersonRefCopyWithImpl<_ShortageSupplyPersonRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShortageSupplyPersonRefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShortageSupplyPersonRef&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.employeeCode, employeeCode) || other.employeeCode == employeeCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,employeeCode);

@override
String toString() {
  return 'ShortageSupplyPersonRef(id: $id, name: $name, employeeCode: $employeeCode)';
}


}

/// @nodoc
abstract mixin class _$ShortageSupplyPersonRefCopyWith<$Res> implements $ShortageSupplyPersonRefCopyWith<$Res> {
  factory _$ShortageSupplyPersonRefCopyWith(_ShortageSupplyPersonRef value, $Res Function(_ShortageSupplyPersonRef) _then) = __$ShortageSupplyPersonRefCopyWithImpl;
@override @useResult
$Res call({
 int id, String name,@JsonKey(name: 'employee_code') String? employeeCode
});




}
/// @nodoc
class __$ShortageSupplyPersonRefCopyWithImpl<$Res>
    implements _$ShortageSupplyPersonRefCopyWith<$Res> {
  __$ShortageSupplyPersonRefCopyWithImpl(this._self, this._then);

  final _ShortageSupplyPersonRef _self;
  final $Res Function(_ShortageSupplyPersonRef) _then;

/// Create a copy of ShortageSupplyPersonRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? employeeCode = freezed,}) {
  return _then(_ShortageSupplyPersonRef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,employeeCode: freezed == employeeCode ? _self.employeeCode : employeeCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
