// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_payment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OrderPayment {

 int get id;@JsonKey(name: 'order_id') int get orderId;@JsonKey(unknownEnumValue: OrderPaymentType.unknown) OrderPaymentType get type;/// The Arabic the server chose. Rendered as-is, so an entry type this build does not know
/// still reads correctly.
@JsonKey(name: 'type_label') String get typeLabel;/// Always positive. Which direction it moves is [type]'s business — see [isIncoming].
 String get amount;/// **The two flags the ledger is drawn from**, both decided by the server. `isReversed`
/// strikes the row through; `isReversible` is what puts a cancel action on it — and the
/// server has already decided that a refund and a reversal are not candidates, so this
/// screen keeps no copy of that rule.
@JsonKey(name: 'is_reversed') bool get isReversed;@JsonKey(name: 'is_reversible') bool get isReversible;/// Whether the receipt (الواصل) is on file. Always true on a transfer, which is the one
/// method that cannot be recorded without one.
@JsonKey(name: 'has_receipt') bool get hasReceipt;/// Null on a reversal alone: no money moved, so there is no method to name.
@JsonKey(unknownEnumValue: PaymentMethod.unknown) PaymentMethod? get method;@JsonKey(name: 'method_label') String? get methodLabel;/// The receipt or transfer number, when there is one.
 String? get reference;/// A link to the receipt PDF, built per request by the server.
///
/// **Expires**, and is not stored: the disk is private, because a receipt carries somebody's
/// bank details. Fetch it when it is opened, never hold it.
@JsonKey(name: 'receipt_url') String? get receiptUrl;@JsonKey(name: 'receipt_filename') String? get receiptFilename;@JsonKey(name: 'receipt_size_bytes') int? get receiptSizeBytes; String? get notes;/// Which entry this one undoes, on a reversal.
@JsonKey(name: 'reverses_payment_id') int? get reversesPaymentId;/// And the other way round, so a struck-through row can name its own correction without
/// the screen pairing rows up by eye.
 OrderPaymentReversal? get reversal;/// Who took it. Absent on an entry written by a console command or a seeder.
@JsonKey(name: 'recorder') PaymentRecorder? get recordedBy;/// **When the money moved**, not when it was typed in — the two genuinely differ on a
/// deposit taken on Thursday and entered on Saturday. [createdAt] answers the other one.
@JsonKey(name: 'paid_at') DateTime? get paidAt;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of OrderPayment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderPaymentCopyWith<OrderPayment> get copyWith => _$OrderPaymentCopyWithImpl<OrderPayment>(this as OrderPayment, _$identity);

  /// Serializes this OrderPayment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderPayment&&(identical(other.id, id) || other.id == id)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.type, type) || other.type == type)&&(identical(other.typeLabel, typeLabel) || other.typeLabel == typeLabel)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.isReversed, isReversed) || other.isReversed == isReversed)&&(identical(other.isReversible, isReversible) || other.isReversible == isReversible)&&(identical(other.hasReceipt, hasReceipt) || other.hasReceipt == hasReceipt)&&(identical(other.method, method) || other.method == method)&&(identical(other.methodLabel, methodLabel) || other.methodLabel == methodLabel)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.receiptUrl, receiptUrl) || other.receiptUrl == receiptUrl)&&(identical(other.receiptFilename, receiptFilename) || other.receiptFilename == receiptFilename)&&(identical(other.receiptSizeBytes, receiptSizeBytes) || other.receiptSizeBytes == receiptSizeBytes)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.reversesPaymentId, reversesPaymentId) || other.reversesPaymentId == reversesPaymentId)&&(identical(other.reversal, reversal) || other.reversal == reversal)&&(identical(other.recordedBy, recordedBy) || other.recordedBy == recordedBy)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,orderId,type,typeLabel,amount,isReversed,isReversible,hasReceipt,method,methodLabel,reference,receiptUrl,receiptFilename,receiptSizeBytes,notes,reversesPaymentId,reversal,recordedBy,paidAt,createdAt]);

@override
String toString() {
  return 'OrderPayment(id: $id, orderId: $orderId, type: $type, typeLabel: $typeLabel, amount: $amount, isReversed: $isReversed, isReversible: $isReversible, hasReceipt: $hasReceipt, method: $method, methodLabel: $methodLabel, reference: $reference, receiptUrl: $receiptUrl, receiptFilename: $receiptFilename, receiptSizeBytes: $receiptSizeBytes, notes: $notes, reversesPaymentId: $reversesPaymentId, reversal: $reversal, recordedBy: $recordedBy, paidAt: $paidAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $OrderPaymentCopyWith<$Res>  {
  factory $OrderPaymentCopyWith(OrderPayment value, $Res Function(OrderPayment) _then) = _$OrderPaymentCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'order_id') int orderId,@JsonKey(unknownEnumValue: OrderPaymentType.unknown) OrderPaymentType type,@JsonKey(name: 'type_label') String typeLabel, String amount,@JsonKey(name: 'is_reversed') bool isReversed,@JsonKey(name: 'is_reversible') bool isReversible,@JsonKey(name: 'has_receipt') bool hasReceipt,@JsonKey(unknownEnumValue: PaymentMethod.unknown) PaymentMethod? method,@JsonKey(name: 'method_label') String? methodLabel, String? reference,@JsonKey(name: 'receipt_url') String? receiptUrl,@JsonKey(name: 'receipt_filename') String? receiptFilename,@JsonKey(name: 'receipt_size_bytes') int? receiptSizeBytes, String? notes,@JsonKey(name: 'reverses_payment_id') int? reversesPaymentId, OrderPaymentReversal? reversal,@JsonKey(name: 'recorder') PaymentRecorder? recordedBy,@JsonKey(name: 'paid_at') DateTime? paidAt,@JsonKey(name: 'created_at') DateTime? createdAt
});


$OrderPaymentReversalCopyWith<$Res>? get reversal;$PaymentRecorderCopyWith<$Res>? get recordedBy;

}
/// @nodoc
class _$OrderPaymentCopyWithImpl<$Res>
    implements $OrderPaymentCopyWith<$Res> {
  _$OrderPaymentCopyWithImpl(this._self, this._then);

  final OrderPayment _self;
  final $Res Function(OrderPayment) _then;

/// Create a copy of OrderPayment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? orderId = null,Object? type = null,Object? typeLabel = null,Object? amount = null,Object? isReversed = null,Object? isReversible = null,Object? hasReceipt = null,Object? method = freezed,Object? methodLabel = freezed,Object? reference = freezed,Object? receiptUrl = freezed,Object? receiptFilename = freezed,Object? receiptSizeBytes = freezed,Object? notes = freezed,Object? reversesPaymentId = freezed,Object? reversal = freezed,Object? recordedBy = freezed,Object? paidAt = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as OrderPaymentType,typeLabel: null == typeLabel ? _self.typeLabel : typeLabel // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,isReversed: null == isReversed ? _self.isReversed : isReversed // ignore: cast_nullable_to_non_nullable
as bool,isReversible: null == isReversible ? _self.isReversible : isReversible // ignore: cast_nullable_to_non_nullable
as bool,hasReceipt: null == hasReceipt ? _self.hasReceipt : hasReceipt // ignore: cast_nullable_to_non_nullable
as bool,method: freezed == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as PaymentMethod?,methodLabel: freezed == methodLabel ? _self.methodLabel : methodLabel // ignore: cast_nullable_to_non_nullable
as String?,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,receiptUrl: freezed == receiptUrl ? _self.receiptUrl : receiptUrl // ignore: cast_nullable_to_non_nullable
as String?,receiptFilename: freezed == receiptFilename ? _self.receiptFilename : receiptFilename // ignore: cast_nullable_to_non_nullable
as String?,receiptSizeBytes: freezed == receiptSizeBytes ? _self.receiptSizeBytes : receiptSizeBytes // ignore: cast_nullable_to_non_nullable
as int?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,reversesPaymentId: freezed == reversesPaymentId ? _self.reversesPaymentId : reversesPaymentId // ignore: cast_nullable_to_non_nullable
as int?,reversal: freezed == reversal ? _self.reversal : reversal // ignore: cast_nullable_to_non_nullable
as OrderPaymentReversal?,recordedBy: freezed == recordedBy ? _self.recordedBy : recordedBy // ignore: cast_nullable_to_non_nullable
as PaymentRecorder?,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of OrderPayment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderPaymentReversalCopyWith<$Res>? get reversal {
    if (_self.reversal == null) {
    return null;
  }

  return $OrderPaymentReversalCopyWith<$Res>(_self.reversal!, (value) {
    return _then(_self.copyWith(reversal: value));
  });
}/// Create a copy of OrderPayment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaymentRecorderCopyWith<$Res>? get recordedBy {
    if (_self.recordedBy == null) {
    return null;
  }

  return $PaymentRecorderCopyWith<$Res>(_self.recordedBy!, (value) {
    return _then(_self.copyWith(recordedBy: value));
  });
}
}


/// Adds pattern-matching-related methods to [OrderPayment].
extension OrderPaymentPatterns on OrderPayment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderPayment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderPayment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderPayment value)  $default,){
final _that = this;
switch (_that) {
case _OrderPayment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderPayment value)?  $default,){
final _that = this;
switch (_that) {
case _OrderPayment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'order_id')  int orderId, @JsonKey(unknownEnumValue: OrderPaymentType.unknown)  OrderPaymentType type, @JsonKey(name: 'type_label')  String typeLabel,  String amount, @JsonKey(name: 'is_reversed')  bool isReversed, @JsonKey(name: 'is_reversible')  bool isReversible, @JsonKey(name: 'has_receipt')  bool hasReceipt, @JsonKey(unknownEnumValue: PaymentMethod.unknown)  PaymentMethod? method, @JsonKey(name: 'method_label')  String? methodLabel,  String? reference, @JsonKey(name: 'receipt_url')  String? receiptUrl, @JsonKey(name: 'receipt_filename')  String? receiptFilename, @JsonKey(name: 'receipt_size_bytes')  int? receiptSizeBytes,  String? notes, @JsonKey(name: 'reverses_payment_id')  int? reversesPaymentId,  OrderPaymentReversal? reversal, @JsonKey(name: 'recorder')  PaymentRecorder? recordedBy, @JsonKey(name: 'paid_at')  DateTime? paidAt, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderPayment() when $default != null:
return $default(_that.id,_that.orderId,_that.type,_that.typeLabel,_that.amount,_that.isReversed,_that.isReversible,_that.hasReceipt,_that.method,_that.methodLabel,_that.reference,_that.receiptUrl,_that.receiptFilename,_that.receiptSizeBytes,_that.notes,_that.reversesPaymentId,_that.reversal,_that.recordedBy,_that.paidAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'order_id')  int orderId, @JsonKey(unknownEnumValue: OrderPaymentType.unknown)  OrderPaymentType type, @JsonKey(name: 'type_label')  String typeLabel,  String amount, @JsonKey(name: 'is_reversed')  bool isReversed, @JsonKey(name: 'is_reversible')  bool isReversible, @JsonKey(name: 'has_receipt')  bool hasReceipt, @JsonKey(unknownEnumValue: PaymentMethod.unknown)  PaymentMethod? method, @JsonKey(name: 'method_label')  String? methodLabel,  String? reference, @JsonKey(name: 'receipt_url')  String? receiptUrl, @JsonKey(name: 'receipt_filename')  String? receiptFilename, @JsonKey(name: 'receipt_size_bytes')  int? receiptSizeBytes,  String? notes, @JsonKey(name: 'reverses_payment_id')  int? reversesPaymentId,  OrderPaymentReversal? reversal, @JsonKey(name: 'recorder')  PaymentRecorder? recordedBy, @JsonKey(name: 'paid_at')  DateTime? paidAt, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _OrderPayment():
return $default(_that.id,_that.orderId,_that.type,_that.typeLabel,_that.amount,_that.isReversed,_that.isReversible,_that.hasReceipt,_that.method,_that.methodLabel,_that.reference,_that.receiptUrl,_that.receiptFilename,_that.receiptSizeBytes,_that.notes,_that.reversesPaymentId,_that.reversal,_that.recordedBy,_that.paidAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'order_id')  int orderId, @JsonKey(unknownEnumValue: OrderPaymentType.unknown)  OrderPaymentType type, @JsonKey(name: 'type_label')  String typeLabel,  String amount, @JsonKey(name: 'is_reversed')  bool isReversed, @JsonKey(name: 'is_reversible')  bool isReversible, @JsonKey(name: 'has_receipt')  bool hasReceipt, @JsonKey(unknownEnumValue: PaymentMethod.unknown)  PaymentMethod? method, @JsonKey(name: 'method_label')  String? methodLabel,  String? reference, @JsonKey(name: 'receipt_url')  String? receiptUrl, @JsonKey(name: 'receipt_filename')  String? receiptFilename, @JsonKey(name: 'receipt_size_bytes')  int? receiptSizeBytes,  String? notes, @JsonKey(name: 'reverses_payment_id')  int? reversesPaymentId,  OrderPaymentReversal? reversal, @JsonKey(name: 'recorder')  PaymentRecorder? recordedBy, @JsonKey(name: 'paid_at')  DateTime? paidAt, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _OrderPayment() when $default != null:
return $default(_that.id,_that.orderId,_that.type,_that.typeLabel,_that.amount,_that.isReversed,_that.isReversible,_that.hasReceipt,_that.method,_that.methodLabel,_that.reference,_that.receiptUrl,_that.receiptFilename,_that.receiptSizeBytes,_that.notes,_that.reversesPaymentId,_that.reversal,_that.recordedBy,_that.paidAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderPayment extends OrderPayment {
  const _OrderPayment({required this.id, @JsonKey(name: 'order_id') required this.orderId, @JsonKey(unknownEnumValue: OrderPaymentType.unknown) required this.type, @JsonKey(name: 'type_label') required this.typeLabel, required this.amount, @JsonKey(name: 'is_reversed') this.isReversed = false, @JsonKey(name: 'is_reversible') this.isReversible = false, @JsonKey(name: 'has_receipt') this.hasReceipt = false, @JsonKey(unknownEnumValue: PaymentMethod.unknown) this.method, @JsonKey(name: 'method_label') this.methodLabel, this.reference, @JsonKey(name: 'receipt_url') this.receiptUrl, @JsonKey(name: 'receipt_filename') this.receiptFilename, @JsonKey(name: 'receipt_size_bytes') this.receiptSizeBytes, this.notes, @JsonKey(name: 'reverses_payment_id') this.reversesPaymentId, this.reversal, @JsonKey(name: 'recorder') this.recordedBy, @JsonKey(name: 'paid_at') this.paidAt, @JsonKey(name: 'created_at') this.createdAt}): super._();
  factory _OrderPayment.fromJson(Map<String, dynamic> json) => _$OrderPaymentFromJson(json);

@override final  int id;
@override@JsonKey(name: 'order_id') final  int orderId;
@override@JsonKey(unknownEnumValue: OrderPaymentType.unknown) final  OrderPaymentType type;
/// The Arabic the server chose. Rendered as-is, so an entry type this build does not know
/// still reads correctly.
@override@JsonKey(name: 'type_label') final  String typeLabel;
/// Always positive. Which direction it moves is [type]'s business — see [isIncoming].
@override final  String amount;
/// **The two flags the ledger is drawn from**, both decided by the server. `isReversed`
/// strikes the row through; `isReversible` is what puts a cancel action on it — and the
/// server has already decided that a refund and a reversal are not candidates, so this
/// screen keeps no copy of that rule.
@override@JsonKey(name: 'is_reversed') final  bool isReversed;
@override@JsonKey(name: 'is_reversible') final  bool isReversible;
/// Whether the receipt (الواصل) is on file. Always true on a transfer, which is the one
/// method that cannot be recorded without one.
@override@JsonKey(name: 'has_receipt') final  bool hasReceipt;
/// Null on a reversal alone: no money moved, so there is no method to name.
@override@JsonKey(unknownEnumValue: PaymentMethod.unknown) final  PaymentMethod? method;
@override@JsonKey(name: 'method_label') final  String? methodLabel;
/// The receipt or transfer number, when there is one.
@override final  String? reference;
/// A link to the receipt PDF, built per request by the server.
///
/// **Expires**, and is not stored: the disk is private, because a receipt carries somebody's
/// bank details. Fetch it when it is opened, never hold it.
@override@JsonKey(name: 'receipt_url') final  String? receiptUrl;
@override@JsonKey(name: 'receipt_filename') final  String? receiptFilename;
@override@JsonKey(name: 'receipt_size_bytes') final  int? receiptSizeBytes;
@override final  String? notes;
/// Which entry this one undoes, on a reversal.
@override@JsonKey(name: 'reverses_payment_id') final  int? reversesPaymentId;
/// And the other way round, so a struck-through row can name its own correction without
/// the screen pairing rows up by eye.
@override final  OrderPaymentReversal? reversal;
/// Who took it. Absent on an entry written by a console command or a seeder.
@override@JsonKey(name: 'recorder') final  PaymentRecorder? recordedBy;
/// **When the money moved**, not when it was typed in — the two genuinely differ on a
/// deposit taken on Thursday and entered on Saturday. [createdAt] answers the other one.
@override@JsonKey(name: 'paid_at') final  DateTime? paidAt;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of OrderPayment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderPaymentCopyWith<_OrderPayment> get copyWith => __$OrderPaymentCopyWithImpl<_OrderPayment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderPaymentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderPayment&&(identical(other.id, id) || other.id == id)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.type, type) || other.type == type)&&(identical(other.typeLabel, typeLabel) || other.typeLabel == typeLabel)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.isReversed, isReversed) || other.isReversed == isReversed)&&(identical(other.isReversible, isReversible) || other.isReversible == isReversible)&&(identical(other.hasReceipt, hasReceipt) || other.hasReceipt == hasReceipt)&&(identical(other.method, method) || other.method == method)&&(identical(other.methodLabel, methodLabel) || other.methodLabel == methodLabel)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.receiptUrl, receiptUrl) || other.receiptUrl == receiptUrl)&&(identical(other.receiptFilename, receiptFilename) || other.receiptFilename == receiptFilename)&&(identical(other.receiptSizeBytes, receiptSizeBytes) || other.receiptSizeBytes == receiptSizeBytes)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.reversesPaymentId, reversesPaymentId) || other.reversesPaymentId == reversesPaymentId)&&(identical(other.reversal, reversal) || other.reversal == reversal)&&(identical(other.recordedBy, recordedBy) || other.recordedBy == recordedBy)&&(identical(other.paidAt, paidAt) || other.paidAt == paidAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,orderId,type,typeLabel,amount,isReversed,isReversible,hasReceipt,method,methodLabel,reference,receiptUrl,receiptFilename,receiptSizeBytes,notes,reversesPaymentId,reversal,recordedBy,paidAt,createdAt]);

@override
String toString() {
  return 'OrderPayment(id: $id, orderId: $orderId, type: $type, typeLabel: $typeLabel, amount: $amount, isReversed: $isReversed, isReversible: $isReversible, hasReceipt: $hasReceipt, method: $method, methodLabel: $methodLabel, reference: $reference, receiptUrl: $receiptUrl, receiptFilename: $receiptFilename, receiptSizeBytes: $receiptSizeBytes, notes: $notes, reversesPaymentId: $reversesPaymentId, reversal: $reversal, recordedBy: $recordedBy, paidAt: $paidAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$OrderPaymentCopyWith<$Res> implements $OrderPaymentCopyWith<$Res> {
  factory _$OrderPaymentCopyWith(_OrderPayment value, $Res Function(_OrderPayment) _then) = __$OrderPaymentCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'order_id') int orderId,@JsonKey(unknownEnumValue: OrderPaymentType.unknown) OrderPaymentType type,@JsonKey(name: 'type_label') String typeLabel, String amount,@JsonKey(name: 'is_reversed') bool isReversed,@JsonKey(name: 'is_reversible') bool isReversible,@JsonKey(name: 'has_receipt') bool hasReceipt,@JsonKey(unknownEnumValue: PaymentMethod.unknown) PaymentMethod? method,@JsonKey(name: 'method_label') String? methodLabel, String? reference,@JsonKey(name: 'receipt_url') String? receiptUrl,@JsonKey(name: 'receipt_filename') String? receiptFilename,@JsonKey(name: 'receipt_size_bytes') int? receiptSizeBytes, String? notes,@JsonKey(name: 'reverses_payment_id') int? reversesPaymentId, OrderPaymentReversal? reversal,@JsonKey(name: 'recorder') PaymentRecorder? recordedBy,@JsonKey(name: 'paid_at') DateTime? paidAt,@JsonKey(name: 'created_at') DateTime? createdAt
});


@override $OrderPaymentReversalCopyWith<$Res>? get reversal;@override $PaymentRecorderCopyWith<$Res>? get recordedBy;

}
/// @nodoc
class __$OrderPaymentCopyWithImpl<$Res>
    implements _$OrderPaymentCopyWith<$Res> {
  __$OrderPaymentCopyWithImpl(this._self, this._then);

  final _OrderPayment _self;
  final $Res Function(_OrderPayment) _then;

/// Create a copy of OrderPayment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? orderId = null,Object? type = null,Object? typeLabel = null,Object? amount = null,Object? isReversed = null,Object? isReversible = null,Object? hasReceipt = null,Object? method = freezed,Object? methodLabel = freezed,Object? reference = freezed,Object? receiptUrl = freezed,Object? receiptFilename = freezed,Object? receiptSizeBytes = freezed,Object? notes = freezed,Object? reversesPaymentId = freezed,Object? reversal = freezed,Object? recordedBy = freezed,Object? paidAt = freezed,Object? createdAt = freezed,}) {
  return _then(_OrderPayment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as OrderPaymentType,typeLabel: null == typeLabel ? _self.typeLabel : typeLabel // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,isReversed: null == isReversed ? _self.isReversed : isReversed // ignore: cast_nullable_to_non_nullable
as bool,isReversible: null == isReversible ? _self.isReversible : isReversible // ignore: cast_nullable_to_non_nullable
as bool,hasReceipt: null == hasReceipt ? _self.hasReceipt : hasReceipt // ignore: cast_nullable_to_non_nullable
as bool,method: freezed == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as PaymentMethod?,methodLabel: freezed == methodLabel ? _self.methodLabel : methodLabel // ignore: cast_nullable_to_non_nullable
as String?,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,receiptUrl: freezed == receiptUrl ? _self.receiptUrl : receiptUrl // ignore: cast_nullable_to_non_nullable
as String?,receiptFilename: freezed == receiptFilename ? _self.receiptFilename : receiptFilename // ignore: cast_nullable_to_non_nullable
as String?,receiptSizeBytes: freezed == receiptSizeBytes ? _self.receiptSizeBytes : receiptSizeBytes // ignore: cast_nullable_to_non_nullable
as int?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,reversesPaymentId: freezed == reversesPaymentId ? _self.reversesPaymentId : reversesPaymentId // ignore: cast_nullable_to_non_nullable
as int?,reversal: freezed == reversal ? _self.reversal : reversal // ignore: cast_nullable_to_non_nullable
as OrderPaymentReversal?,recordedBy: freezed == recordedBy ? _self.recordedBy : recordedBy // ignore: cast_nullable_to_non_nullable
as PaymentRecorder?,paidAt: freezed == paidAt ? _self.paidAt : paidAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of OrderPayment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderPaymentReversalCopyWith<$Res>? get reversal {
    if (_self.reversal == null) {
    return null;
  }

  return $OrderPaymentReversalCopyWith<$Res>(_self.reversal!, (value) {
    return _then(_self.copyWith(reversal: value));
  });
}/// Create a copy of OrderPayment
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaymentRecorderCopyWith<$Res>? get recordedBy {
    if (_self.recordedBy == null) {
    return null;
  }

  return $PaymentRecorderCopyWith<$Res>(_self.recordedBy!, (value) {
    return _then(_self.copyWith(recordedBy: value));
  });
}
}


/// @nodoc
mixin _$OrderPaymentReversal {

 int get id;/// Why it was cancelled. Required by the server, so it is never blank on a real entry.
 String? get reason;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of OrderPaymentReversal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderPaymentReversalCopyWith<OrderPaymentReversal> get copyWith => _$OrderPaymentReversalCopyWithImpl<OrderPaymentReversal>(this as OrderPaymentReversal, _$identity);

  /// Serializes this OrderPaymentReversal to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderPaymentReversal&&(identical(other.id, id) || other.id == id)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,reason,createdAt);

@override
String toString() {
  return 'OrderPaymentReversal(id: $id, reason: $reason, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $OrderPaymentReversalCopyWith<$Res>  {
  factory $OrderPaymentReversalCopyWith(OrderPaymentReversal value, $Res Function(OrderPaymentReversal) _then) = _$OrderPaymentReversalCopyWithImpl;
@useResult
$Res call({
 int id, String? reason,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class _$OrderPaymentReversalCopyWithImpl<$Res>
    implements $OrderPaymentReversalCopyWith<$Res> {
  _$OrderPaymentReversalCopyWithImpl(this._self, this._then);

  final OrderPaymentReversal _self;
  final $Res Function(OrderPaymentReversal) _then;

/// Create a copy of OrderPaymentReversal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? reason = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderPaymentReversal].
extension OrderPaymentReversalPatterns on OrderPaymentReversal {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderPaymentReversal value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderPaymentReversal() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderPaymentReversal value)  $default,){
final _that = this;
switch (_that) {
case _OrderPaymentReversal():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderPaymentReversal value)?  $default,){
final _that = this;
switch (_that) {
case _OrderPaymentReversal() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String? reason, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderPaymentReversal() when $default != null:
return $default(_that.id,_that.reason,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String? reason, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _OrderPaymentReversal():
return $default(_that.id,_that.reason,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String? reason, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _OrderPaymentReversal() when $default != null:
return $default(_that.id,_that.reason,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderPaymentReversal implements OrderPaymentReversal {
  const _OrderPaymentReversal({required this.id, this.reason, @JsonKey(name: 'created_at') this.createdAt});
  factory _OrderPaymentReversal.fromJson(Map<String, dynamic> json) => _$OrderPaymentReversalFromJson(json);

@override final  int id;
/// Why it was cancelled. Required by the server, so it is never blank on a real entry.
@override final  String? reason;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of OrderPaymentReversal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderPaymentReversalCopyWith<_OrderPaymentReversal> get copyWith => __$OrderPaymentReversalCopyWithImpl<_OrderPaymentReversal>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderPaymentReversalToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderPaymentReversal&&(identical(other.id, id) || other.id == id)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,reason,createdAt);

@override
String toString() {
  return 'OrderPaymentReversal(id: $id, reason: $reason, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$OrderPaymentReversalCopyWith<$Res> implements $OrderPaymentReversalCopyWith<$Res> {
  factory _$OrderPaymentReversalCopyWith(_OrderPaymentReversal value, $Res Function(_OrderPaymentReversal) _then) = __$OrderPaymentReversalCopyWithImpl;
@override @useResult
$Res call({
 int id, String? reason,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class __$OrderPaymentReversalCopyWithImpl<$Res>
    implements _$OrderPaymentReversalCopyWith<$Res> {
  __$OrderPaymentReversalCopyWithImpl(this._self, this._then);

  final _OrderPaymentReversal _self;
  final $Res Function(_OrderPaymentReversal) _then;

/// Create a copy of OrderPaymentReversal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? reason = freezed,Object? createdAt = freezed,}) {
  return _then(_OrderPaymentReversal(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$PaymentRecorder {

 int get id; String get name;@JsonKey(name: 'employee_code') String? get employeeCode;
/// Create a copy of PaymentRecorder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentRecorderCopyWith<PaymentRecorder> get copyWith => _$PaymentRecorderCopyWithImpl<PaymentRecorder>(this as PaymentRecorder, _$identity);

  /// Serializes this PaymentRecorder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentRecorder&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.employeeCode, employeeCode) || other.employeeCode == employeeCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,employeeCode);

@override
String toString() {
  return 'PaymentRecorder(id: $id, name: $name, employeeCode: $employeeCode)';
}


}

/// @nodoc
abstract mixin class $PaymentRecorderCopyWith<$Res>  {
  factory $PaymentRecorderCopyWith(PaymentRecorder value, $Res Function(PaymentRecorder) _then) = _$PaymentRecorderCopyWithImpl;
@useResult
$Res call({
 int id, String name,@JsonKey(name: 'employee_code') String? employeeCode
});




}
/// @nodoc
class _$PaymentRecorderCopyWithImpl<$Res>
    implements $PaymentRecorderCopyWith<$Res> {
  _$PaymentRecorderCopyWithImpl(this._self, this._then);

  final PaymentRecorder _self;
  final $Res Function(PaymentRecorder) _then;

/// Create a copy of PaymentRecorder
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


/// Adds pattern-matching-related methods to [PaymentRecorder].
extension PaymentRecorderPatterns on PaymentRecorder {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaymentRecorder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaymentRecorder() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaymentRecorder value)  $default,){
final _that = this;
switch (_that) {
case _PaymentRecorder():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaymentRecorder value)?  $default,){
final _that = this;
switch (_that) {
case _PaymentRecorder() when $default != null:
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
case _PaymentRecorder() when $default != null:
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
case _PaymentRecorder():
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
case _PaymentRecorder() when $default != null:
return $default(_that.id,_that.name,_that.employeeCode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaymentRecorder implements PaymentRecorder {
  const _PaymentRecorder({required this.id, required this.name, @JsonKey(name: 'employee_code') this.employeeCode});
  factory _PaymentRecorder.fromJson(Map<String, dynamic> json) => _$PaymentRecorderFromJson(json);

@override final  int id;
@override final  String name;
@override@JsonKey(name: 'employee_code') final  String? employeeCode;

/// Create a copy of PaymentRecorder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentRecorderCopyWith<_PaymentRecorder> get copyWith => __$PaymentRecorderCopyWithImpl<_PaymentRecorder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaymentRecorderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaymentRecorder&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.employeeCode, employeeCode) || other.employeeCode == employeeCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,employeeCode);

@override
String toString() {
  return 'PaymentRecorder(id: $id, name: $name, employeeCode: $employeeCode)';
}


}

/// @nodoc
abstract mixin class _$PaymentRecorderCopyWith<$Res> implements $PaymentRecorderCopyWith<$Res> {
  factory _$PaymentRecorderCopyWith(_PaymentRecorder value, $Res Function(_PaymentRecorder) _then) = __$PaymentRecorderCopyWithImpl;
@override @useResult
$Res call({
 int id, String name,@JsonKey(name: 'employee_code') String? employeeCode
});




}
/// @nodoc
class __$PaymentRecorderCopyWithImpl<$Res>
    implements _$PaymentRecorderCopyWith<$Res> {
  __$PaymentRecorderCopyWithImpl(this._self, this._then);

  final _PaymentRecorder _self;
  final $Res Function(_PaymentRecorder) _then;

/// Create a copy of PaymentRecorder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? employeeCode = freezed,}) {
  return _then(_PaymentRecorder(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,employeeCode: freezed == employeeCode ? _self.employeeCode : employeeCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$PaymentSummary {

@JsonKey(name: 'grand_total') String get grandTotal;@JsonKey(name: 'paid_amount') String get paidAmount;/// What is still owed. **Negative when the order is overpaid**, so the screen can say
/// «زائد ٥٠» rather than flooring the fact away.
@JsonKey(name: 'remaining_amount') String get remainingAmount;@JsonKey(name: 'payment_status', unknownEnumValue: PaymentStatus.unknown) PaymentStatus get paymentStatus;@JsonKey(name: 'payment_status_label') String get paymentStatusLabel;/// An order that finished without its money accounted for.
///
/// Settling an order writes no ledger entry — nothing records a payment except the person
/// who took it — so this is how that gap is surfaced instead of being papered over with an
/// entry nobody made. The screen shows a warning; somebody records what was collected.
@JsonKey(name: 'has_unrecorded_money') bool get hasUnrecordedMoney;
/// Create a copy of PaymentSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentSummaryCopyWith<PaymentSummary> get copyWith => _$PaymentSummaryCopyWithImpl<PaymentSummary>(this as PaymentSummary, _$identity);

  /// Serializes this PaymentSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentSummary&&(identical(other.grandTotal, grandTotal) || other.grandTotal == grandTotal)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount)&&(identical(other.remainingAmount, remainingAmount) || other.remainingAmount == remainingAmount)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.paymentStatusLabel, paymentStatusLabel) || other.paymentStatusLabel == paymentStatusLabel)&&(identical(other.hasUnrecordedMoney, hasUnrecordedMoney) || other.hasUnrecordedMoney == hasUnrecordedMoney));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,grandTotal,paidAmount,remainingAmount,paymentStatus,paymentStatusLabel,hasUnrecordedMoney);

@override
String toString() {
  return 'PaymentSummary(grandTotal: $grandTotal, paidAmount: $paidAmount, remainingAmount: $remainingAmount, paymentStatus: $paymentStatus, paymentStatusLabel: $paymentStatusLabel, hasUnrecordedMoney: $hasUnrecordedMoney)';
}


}

/// @nodoc
abstract mixin class $PaymentSummaryCopyWith<$Res>  {
  factory $PaymentSummaryCopyWith(PaymentSummary value, $Res Function(PaymentSummary) _then) = _$PaymentSummaryCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'grand_total') String grandTotal,@JsonKey(name: 'paid_amount') String paidAmount,@JsonKey(name: 'remaining_amount') String remainingAmount,@JsonKey(name: 'payment_status', unknownEnumValue: PaymentStatus.unknown) PaymentStatus paymentStatus,@JsonKey(name: 'payment_status_label') String paymentStatusLabel,@JsonKey(name: 'has_unrecorded_money') bool hasUnrecordedMoney
});




}
/// @nodoc
class _$PaymentSummaryCopyWithImpl<$Res>
    implements $PaymentSummaryCopyWith<$Res> {
  _$PaymentSummaryCopyWithImpl(this._self, this._then);

  final PaymentSummary _self;
  final $Res Function(PaymentSummary) _then;

/// Create a copy of PaymentSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? grandTotal = null,Object? paidAmount = null,Object? remainingAmount = null,Object? paymentStatus = null,Object? paymentStatusLabel = null,Object? hasUnrecordedMoney = null,}) {
  return _then(_self.copyWith(
grandTotal: null == grandTotal ? _self.grandTotal : grandTotal // ignore: cast_nullable_to_non_nullable
as String,paidAmount: null == paidAmount ? _self.paidAmount : paidAmount // ignore: cast_nullable_to_non_nullable
as String,remainingAmount: null == remainingAmount ? _self.remainingAmount : remainingAmount // ignore: cast_nullable_to_non_nullable
as String,paymentStatus: null == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as PaymentStatus,paymentStatusLabel: null == paymentStatusLabel ? _self.paymentStatusLabel : paymentStatusLabel // ignore: cast_nullable_to_non_nullable
as String,hasUnrecordedMoney: null == hasUnrecordedMoney ? _self.hasUnrecordedMoney : hasUnrecordedMoney // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PaymentSummary].
extension PaymentSummaryPatterns on PaymentSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaymentSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaymentSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaymentSummary value)  $default,){
final _that = this;
switch (_that) {
case _PaymentSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaymentSummary value)?  $default,){
final _that = this;
switch (_that) {
case _PaymentSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'grand_total')  String grandTotal, @JsonKey(name: 'paid_amount')  String paidAmount, @JsonKey(name: 'remaining_amount')  String remainingAmount, @JsonKey(name: 'payment_status', unknownEnumValue: PaymentStatus.unknown)  PaymentStatus paymentStatus, @JsonKey(name: 'payment_status_label')  String paymentStatusLabel, @JsonKey(name: 'has_unrecorded_money')  bool hasUnrecordedMoney)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaymentSummary() when $default != null:
return $default(_that.grandTotal,_that.paidAmount,_that.remainingAmount,_that.paymentStatus,_that.paymentStatusLabel,_that.hasUnrecordedMoney);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'grand_total')  String grandTotal, @JsonKey(name: 'paid_amount')  String paidAmount, @JsonKey(name: 'remaining_amount')  String remainingAmount, @JsonKey(name: 'payment_status', unknownEnumValue: PaymentStatus.unknown)  PaymentStatus paymentStatus, @JsonKey(name: 'payment_status_label')  String paymentStatusLabel, @JsonKey(name: 'has_unrecorded_money')  bool hasUnrecordedMoney)  $default,) {final _that = this;
switch (_that) {
case _PaymentSummary():
return $default(_that.grandTotal,_that.paidAmount,_that.remainingAmount,_that.paymentStatus,_that.paymentStatusLabel,_that.hasUnrecordedMoney);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'grand_total')  String grandTotal, @JsonKey(name: 'paid_amount')  String paidAmount, @JsonKey(name: 'remaining_amount')  String remainingAmount, @JsonKey(name: 'payment_status', unknownEnumValue: PaymentStatus.unknown)  PaymentStatus paymentStatus, @JsonKey(name: 'payment_status_label')  String paymentStatusLabel, @JsonKey(name: 'has_unrecorded_money')  bool hasUnrecordedMoney)?  $default,) {final _that = this;
switch (_that) {
case _PaymentSummary() when $default != null:
return $default(_that.grandTotal,_that.paidAmount,_that.remainingAmount,_that.paymentStatus,_that.paymentStatusLabel,_that.hasUnrecordedMoney);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaymentSummary extends PaymentSummary {
  const _PaymentSummary({@JsonKey(name: 'grand_total') required this.grandTotal, @JsonKey(name: 'paid_amount') required this.paidAmount, @JsonKey(name: 'remaining_amount') required this.remainingAmount, @JsonKey(name: 'payment_status', unknownEnumValue: PaymentStatus.unknown) required this.paymentStatus, @JsonKey(name: 'payment_status_label') required this.paymentStatusLabel, @JsonKey(name: 'has_unrecorded_money') this.hasUnrecordedMoney = false}): super._();
  factory _PaymentSummary.fromJson(Map<String, dynamic> json) => _$PaymentSummaryFromJson(json);

@override@JsonKey(name: 'grand_total') final  String grandTotal;
@override@JsonKey(name: 'paid_amount') final  String paidAmount;
/// What is still owed. **Negative when the order is overpaid**, so the screen can say
/// «زائد ٥٠» rather than flooring the fact away.
@override@JsonKey(name: 'remaining_amount') final  String remainingAmount;
@override@JsonKey(name: 'payment_status', unknownEnumValue: PaymentStatus.unknown) final  PaymentStatus paymentStatus;
@override@JsonKey(name: 'payment_status_label') final  String paymentStatusLabel;
/// An order that finished without its money accounted for.
///
/// Settling an order writes no ledger entry — nothing records a payment except the person
/// who took it — so this is how that gap is surfaced instead of being papered over with an
/// entry nobody made. The screen shows a warning; somebody records what was collected.
@override@JsonKey(name: 'has_unrecorded_money') final  bool hasUnrecordedMoney;

/// Create a copy of PaymentSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentSummaryCopyWith<_PaymentSummary> get copyWith => __$PaymentSummaryCopyWithImpl<_PaymentSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaymentSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaymentSummary&&(identical(other.grandTotal, grandTotal) || other.grandTotal == grandTotal)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount)&&(identical(other.remainingAmount, remainingAmount) || other.remainingAmount == remainingAmount)&&(identical(other.paymentStatus, paymentStatus) || other.paymentStatus == paymentStatus)&&(identical(other.paymentStatusLabel, paymentStatusLabel) || other.paymentStatusLabel == paymentStatusLabel)&&(identical(other.hasUnrecordedMoney, hasUnrecordedMoney) || other.hasUnrecordedMoney == hasUnrecordedMoney));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,grandTotal,paidAmount,remainingAmount,paymentStatus,paymentStatusLabel,hasUnrecordedMoney);

@override
String toString() {
  return 'PaymentSummary(grandTotal: $grandTotal, paidAmount: $paidAmount, remainingAmount: $remainingAmount, paymentStatus: $paymentStatus, paymentStatusLabel: $paymentStatusLabel, hasUnrecordedMoney: $hasUnrecordedMoney)';
}


}

/// @nodoc
abstract mixin class _$PaymentSummaryCopyWith<$Res> implements $PaymentSummaryCopyWith<$Res> {
  factory _$PaymentSummaryCopyWith(_PaymentSummary value, $Res Function(_PaymentSummary) _then) = __$PaymentSummaryCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'grand_total') String grandTotal,@JsonKey(name: 'paid_amount') String paidAmount,@JsonKey(name: 'remaining_amount') String remainingAmount,@JsonKey(name: 'payment_status', unknownEnumValue: PaymentStatus.unknown) PaymentStatus paymentStatus,@JsonKey(name: 'payment_status_label') String paymentStatusLabel,@JsonKey(name: 'has_unrecorded_money') bool hasUnrecordedMoney
});




}
/// @nodoc
class __$PaymentSummaryCopyWithImpl<$Res>
    implements _$PaymentSummaryCopyWith<$Res> {
  __$PaymentSummaryCopyWithImpl(this._self, this._then);

  final _PaymentSummary _self;
  final $Res Function(_PaymentSummary) _then;

/// Create a copy of PaymentSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? grandTotal = null,Object? paidAmount = null,Object? remainingAmount = null,Object? paymentStatus = null,Object? paymentStatusLabel = null,Object? hasUnrecordedMoney = null,}) {
  return _then(_PaymentSummary(
grandTotal: null == grandTotal ? _self.grandTotal : grandTotal // ignore: cast_nullable_to_non_nullable
as String,paidAmount: null == paidAmount ? _self.paidAmount : paidAmount // ignore: cast_nullable_to_non_nullable
as String,remainingAmount: null == remainingAmount ? _self.remainingAmount : remainingAmount // ignore: cast_nullable_to_non_nullable
as String,paymentStatus: null == paymentStatus ? _self.paymentStatus : paymentStatus // ignore: cast_nullable_to_non_nullable
as PaymentStatus,paymentStatusLabel: null == paymentStatusLabel ? _self.paymentStatusLabel : paymentStatusLabel // ignore: cast_nullable_to_non_nullable
as String,hasUnrecordedMoney: null == hasUnrecordedMoney ? _self.hasUnrecordedMoney : hasUnrecordedMoney // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$OrderLedger {

 List<OrderPayment> get payments; PaymentSummary get summary;
/// Create a copy of OrderLedger
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderLedgerCopyWith<OrderLedger> get copyWith => _$OrderLedgerCopyWithImpl<OrderLedger>(this as OrderLedger, _$identity);

  /// Serializes this OrderLedger to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderLedger&&const DeepCollectionEquality().equals(other.payments, payments)&&(identical(other.summary, summary) || other.summary == summary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(payments),summary);

@override
String toString() {
  return 'OrderLedger(payments: $payments, summary: $summary)';
}


}

/// @nodoc
abstract mixin class $OrderLedgerCopyWith<$Res>  {
  factory $OrderLedgerCopyWith(OrderLedger value, $Res Function(OrderLedger) _then) = _$OrderLedgerCopyWithImpl;
@useResult
$Res call({
 List<OrderPayment> payments, PaymentSummary summary
});


$PaymentSummaryCopyWith<$Res> get summary;

}
/// @nodoc
class _$OrderLedgerCopyWithImpl<$Res>
    implements $OrderLedgerCopyWith<$Res> {
  _$OrderLedgerCopyWithImpl(this._self, this._then);

  final OrderLedger _self;
  final $Res Function(OrderLedger) _then;

/// Create a copy of OrderLedger
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? payments = null,Object? summary = null,}) {
  return _then(_self.copyWith(
payments: null == payments ? _self.payments : payments // ignore: cast_nullable_to_non_nullable
as List<OrderPayment>,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as PaymentSummary,
  ));
}
/// Create a copy of OrderLedger
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaymentSummaryCopyWith<$Res> get summary {
  
  return $PaymentSummaryCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}


/// Adds pattern-matching-related methods to [OrderLedger].
extension OrderLedgerPatterns on OrderLedger {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderLedger value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderLedger() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderLedger value)  $default,){
final _that = this;
switch (_that) {
case _OrderLedger():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderLedger value)?  $default,){
final _that = this;
switch (_that) {
case _OrderLedger() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<OrderPayment> payments,  PaymentSummary summary)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderLedger() when $default != null:
return $default(_that.payments,_that.summary);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<OrderPayment> payments,  PaymentSummary summary)  $default,) {final _that = this;
switch (_that) {
case _OrderLedger():
return $default(_that.payments,_that.summary);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<OrderPayment> payments,  PaymentSummary summary)?  $default,) {final _that = this;
switch (_that) {
case _OrderLedger() when $default != null:
return $default(_that.payments,_that.summary);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderLedger implements OrderLedger {
  const _OrderLedger({required final  List<OrderPayment> payments, required this.summary}): _payments = payments;
  factory _OrderLedger.fromJson(Map<String, dynamic> json) => _$OrderLedgerFromJson(json);

 final  List<OrderPayment> _payments;
@override List<OrderPayment> get payments {
  if (_payments is EqualUnmodifiableListView) return _payments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_payments);
}

@override final  PaymentSummary summary;

/// Create a copy of OrderLedger
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderLedgerCopyWith<_OrderLedger> get copyWith => __$OrderLedgerCopyWithImpl<_OrderLedger>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderLedgerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderLedger&&const DeepCollectionEquality().equals(other._payments, _payments)&&(identical(other.summary, summary) || other.summary == summary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_payments),summary);

@override
String toString() {
  return 'OrderLedger(payments: $payments, summary: $summary)';
}


}

/// @nodoc
abstract mixin class _$OrderLedgerCopyWith<$Res> implements $OrderLedgerCopyWith<$Res> {
  factory _$OrderLedgerCopyWith(_OrderLedger value, $Res Function(_OrderLedger) _then) = __$OrderLedgerCopyWithImpl;
@override @useResult
$Res call({
 List<OrderPayment> payments, PaymentSummary summary
});


@override $PaymentSummaryCopyWith<$Res> get summary;

}
/// @nodoc
class __$OrderLedgerCopyWithImpl<$Res>
    implements _$OrderLedgerCopyWith<$Res> {
  __$OrderLedgerCopyWithImpl(this._self, this._then);

  final _OrderLedger _self;
  final $Res Function(_OrderLedger) _then;

/// Create a copy of OrderLedger
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? payments = null,Object? summary = null,}) {
  return _then(_OrderLedger(
payments: null == payments ? _self._payments : payments // ignore: cast_nullable_to_non_nullable
as List<OrderPayment>,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as PaymentSummary,
  ));
}

/// Create a copy of OrderLedger
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaymentSummaryCopyWith<$Res> get summary {
  
  return $PaymentSummaryCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}

// dart format on
