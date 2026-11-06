// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nawris_settlement.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NawrisSettlementWarning {

 String get code; String get message;
/// Create a copy of NawrisSettlementWarning
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NawrisSettlementWarningCopyWith<NawrisSettlementWarning> get copyWith => _$NawrisSettlementWarningCopyWithImpl<NawrisSettlementWarning>(this as NawrisSettlementWarning, _$identity);

  /// Serializes this NawrisSettlementWarning to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NawrisSettlementWarning&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message);

@override
String toString() {
  return 'NawrisSettlementWarning(code: $code, message: $message)';
}


}

/// @nodoc
abstract mixin class $NawrisSettlementWarningCopyWith<$Res>  {
  factory $NawrisSettlementWarningCopyWith(NawrisSettlementWarning value, $Res Function(NawrisSettlementWarning) _then) = _$NawrisSettlementWarningCopyWithImpl;
@useResult
$Res call({
 String code, String message
});




}
/// @nodoc
class _$NawrisSettlementWarningCopyWithImpl<$Res>
    implements $NawrisSettlementWarningCopyWith<$Res> {
  _$NawrisSettlementWarningCopyWithImpl(this._self, this._then);

  final NawrisSettlementWarning _self;
  final $Res Function(NawrisSettlementWarning) _then;

/// Create a copy of NawrisSettlementWarning
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? message = null,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [NawrisSettlementWarning].
extension NawrisSettlementWarningPatterns on NawrisSettlementWarning {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NawrisSettlementWarning value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NawrisSettlementWarning() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NawrisSettlementWarning value)  $default,){
final _that = this;
switch (_that) {
case _NawrisSettlementWarning():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NawrisSettlementWarning value)?  $default,){
final _that = this;
switch (_that) {
case _NawrisSettlementWarning() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String code,  String message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NawrisSettlementWarning() when $default != null:
return $default(_that.code,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String code,  String message)  $default,) {final _that = this;
switch (_that) {
case _NawrisSettlementWarning():
return $default(_that.code,_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String code,  String message)?  $default,) {final _that = this;
switch (_that) {
case _NawrisSettlementWarning() when $default != null:
return $default(_that.code,_that.message);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NawrisSettlementWarning implements NawrisSettlementWarning {
  const _NawrisSettlementWarning({required this.code, required this.message});
  factory _NawrisSettlementWarning.fromJson(Map<String, dynamic> json) => _$NawrisSettlementWarningFromJson(json);

@override final  String code;
@override final  String message;

/// Create a copy of NawrisSettlementWarning
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NawrisSettlementWarningCopyWith<_NawrisSettlementWarning> get copyWith => __$NawrisSettlementWarningCopyWithImpl<_NawrisSettlementWarning>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NawrisSettlementWarningToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NawrisSettlementWarning&&(identical(other.code, code) || other.code == code)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,message);

@override
String toString() {
  return 'NawrisSettlementWarning(code: $code, message: $message)';
}


}

/// @nodoc
abstract mixin class _$NawrisSettlementWarningCopyWith<$Res> implements $NawrisSettlementWarningCopyWith<$Res> {
  factory _$NawrisSettlementWarningCopyWith(_NawrisSettlementWarning value, $Res Function(_NawrisSettlementWarning) _then) = __$NawrisSettlementWarningCopyWithImpl;
@override @useResult
$Res call({
 String code, String message
});




}
/// @nodoc
class __$NawrisSettlementWarningCopyWithImpl<$Res>
    implements _$NawrisSettlementWarningCopyWith<$Res> {
  __$NawrisSettlementWarningCopyWithImpl(this._self, this._then);

  final _NawrisSettlementWarning _self;
  final $Res Function(_NawrisSettlementWarning) _then;

/// Create a copy of NawrisSettlementWarning
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? message = null,}) {
  return _then(_NawrisSettlementWarning(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$NawrisSettlementLine {

/// رقم الصف بعد الترويسة. الصف المركّب يعطي أسطراً بالرقم نفسه.
@JsonKey(name: 'row_number') int get rowNumber;@JsonKey(unknownEnumValue: NawrisSettlementOutcome.unknown) NawrisSettlementOutcome get outcome;@JsonKey(name: 'outcome_label') String get outcomeLabel;@JsonKey(name: 'raw_code') String? get rawCode;@JsonKey(name: 'raw_receiver') String? get rawReceiver;@JsonKey(name: 'order_id') int? get orderId;@JsonKey(name: 'order_code') String? get orderCode;@JsonKey(name: 'previous_status_label') String? get previousStatusLabel;/// لماذا لن تتحرك، أو لماذا تُخطّيت — بالعربية كما يُعرض.
 String? get reason; List<NawrisSettlementWarning> get warnings;/// ما عند النورس لهذه الطلبية. نصّ لا `double`.
@JsonKey(name: 'held_amount') String get heldAmount;/// أجرة النورس عليها: المعروفة في المعاينة، والمقيَّدة في الدفعة المنفَّذة.
@JsonKey(name: 'fee_amount') String get feeAmount;
/// Create a copy of NawrisSettlementLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NawrisSettlementLineCopyWith<NawrisSettlementLine> get copyWith => _$NawrisSettlementLineCopyWithImpl<NawrisSettlementLine>(this as NawrisSettlementLine, _$identity);

  /// Serializes this NawrisSettlementLine to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NawrisSettlementLine&&(identical(other.rowNumber, rowNumber) || other.rowNumber == rowNumber)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.outcomeLabel, outcomeLabel) || other.outcomeLabel == outcomeLabel)&&(identical(other.rawCode, rawCode) || other.rawCode == rawCode)&&(identical(other.rawReceiver, rawReceiver) || other.rawReceiver == rawReceiver)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.orderCode, orderCode) || other.orderCode == orderCode)&&(identical(other.previousStatusLabel, previousStatusLabel) || other.previousStatusLabel == previousStatusLabel)&&(identical(other.reason, reason) || other.reason == reason)&&const DeepCollectionEquality().equals(other.warnings, warnings)&&(identical(other.heldAmount, heldAmount) || other.heldAmount == heldAmount)&&(identical(other.feeAmount, feeAmount) || other.feeAmount == feeAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowNumber,outcome,outcomeLabel,rawCode,rawReceiver,orderId,orderCode,previousStatusLabel,reason,const DeepCollectionEquality().hash(warnings),heldAmount,feeAmount);

@override
String toString() {
  return 'NawrisSettlementLine(rowNumber: $rowNumber, outcome: $outcome, outcomeLabel: $outcomeLabel, rawCode: $rawCode, rawReceiver: $rawReceiver, orderId: $orderId, orderCode: $orderCode, previousStatusLabel: $previousStatusLabel, reason: $reason, warnings: $warnings, heldAmount: $heldAmount, feeAmount: $feeAmount)';
}


}

/// @nodoc
abstract mixin class $NawrisSettlementLineCopyWith<$Res>  {
  factory $NawrisSettlementLineCopyWith(NawrisSettlementLine value, $Res Function(NawrisSettlementLine) _then) = _$NawrisSettlementLineCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'row_number') int rowNumber,@JsonKey(unknownEnumValue: NawrisSettlementOutcome.unknown) NawrisSettlementOutcome outcome,@JsonKey(name: 'outcome_label') String outcomeLabel,@JsonKey(name: 'raw_code') String? rawCode,@JsonKey(name: 'raw_receiver') String? rawReceiver,@JsonKey(name: 'order_id') int? orderId,@JsonKey(name: 'order_code') String? orderCode,@JsonKey(name: 'previous_status_label') String? previousStatusLabel, String? reason, List<NawrisSettlementWarning> warnings,@JsonKey(name: 'held_amount') String heldAmount,@JsonKey(name: 'fee_amount') String feeAmount
});




}
/// @nodoc
class _$NawrisSettlementLineCopyWithImpl<$Res>
    implements $NawrisSettlementLineCopyWith<$Res> {
  _$NawrisSettlementLineCopyWithImpl(this._self, this._then);

  final NawrisSettlementLine _self;
  final $Res Function(NawrisSettlementLine) _then;

/// Create a copy of NawrisSettlementLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rowNumber = null,Object? outcome = null,Object? outcomeLabel = null,Object? rawCode = freezed,Object? rawReceiver = freezed,Object? orderId = freezed,Object? orderCode = freezed,Object? previousStatusLabel = freezed,Object? reason = freezed,Object? warnings = null,Object? heldAmount = null,Object? feeAmount = null,}) {
  return _then(_self.copyWith(
rowNumber: null == rowNumber ? _self.rowNumber : rowNumber // ignore: cast_nullable_to_non_nullable
as int,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as NawrisSettlementOutcome,outcomeLabel: null == outcomeLabel ? _self.outcomeLabel : outcomeLabel // ignore: cast_nullable_to_non_nullable
as String,rawCode: freezed == rawCode ? _self.rawCode : rawCode // ignore: cast_nullable_to_non_nullable
as String?,rawReceiver: freezed == rawReceiver ? _self.rawReceiver : rawReceiver // ignore: cast_nullable_to_non_nullable
as String?,orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as int?,orderCode: freezed == orderCode ? _self.orderCode : orderCode // ignore: cast_nullable_to_non_nullable
as String?,previousStatusLabel: freezed == previousStatusLabel ? _self.previousStatusLabel : previousStatusLabel // ignore: cast_nullable_to_non_nullable
as String?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,warnings: null == warnings ? _self.warnings : warnings // ignore: cast_nullable_to_non_nullable
as List<NawrisSettlementWarning>,heldAmount: null == heldAmount ? _self.heldAmount : heldAmount // ignore: cast_nullable_to_non_nullable
as String,feeAmount: null == feeAmount ? _self.feeAmount : feeAmount // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [NawrisSettlementLine].
extension NawrisSettlementLinePatterns on NawrisSettlementLine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NawrisSettlementLine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NawrisSettlementLine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NawrisSettlementLine value)  $default,){
final _that = this;
switch (_that) {
case _NawrisSettlementLine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NawrisSettlementLine value)?  $default,){
final _that = this;
switch (_that) {
case _NawrisSettlementLine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'row_number')  int rowNumber, @JsonKey(unknownEnumValue: NawrisSettlementOutcome.unknown)  NawrisSettlementOutcome outcome, @JsonKey(name: 'outcome_label')  String outcomeLabel, @JsonKey(name: 'raw_code')  String? rawCode, @JsonKey(name: 'raw_receiver')  String? rawReceiver, @JsonKey(name: 'order_id')  int? orderId, @JsonKey(name: 'order_code')  String? orderCode, @JsonKey(name: 'previous_status_label')  String? previousStatusLabel,  String? reason,  List<NawrisSettlementWarning> warnings, @JsonKey(name: 'held_amount')  String heldAmount, @JsonKey(name: 'fee_amount')  String feeAmount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NawrisSettlementLine() when $default != null:
return $default(_that.rowNumber,_that.outcome,_that.outcomeLabel,_that.rawCode,_that.rawReceiver,_that.orderId,_that.orderCode,_that.previousStatusLabel,_that.reason,_that.warnings,_that.heldAmount,_that.feeAmount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'row_number')  int rowNumber, @JsonKey(unknownEnumValue: NawrisSettlementOutcome.unknown)  NawrisSettlementOutcome outcome, @JsonKey(name: 'outcome_label')  String outcomeLabel, @JsonKey(name: 'raw_code')  String? rawCode, @JsonKey(name: 'raw_receiver')  String? rawReceiver, @JsonKey(name: 'order_id')  int? orderId, @JsonKey(name: 'order_code')  String? orderCode, @JsonKey(name: 'previous_status_label')  String? previousStatusLabel,  String? reason,  List<NawrisSettlementWarning> warnings, @JsonKey(name: 'held_amount')  String heldAmount, @JsonKey(name: 'fee_amount')  String feeAmount)  $default,) {final _that = this;
switch (_that) {
case _NawrisSettlementLine():
return $default(_that.rowNumber,_that.outcome,_that.outcomeLabel,_that.rawCode,_that.rawReceiver,_that.orderId,_that.orderCode,_that.previousStatusLabel,_that.reason,_that.warnings,_that.heldAmount,_that.feeAmount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'row_number')  int rowNumber, @JsonKey(unknownEnumValue: NawrisSettlementOutcome.unknown)  NawrisSettlementOutcome outcome, @JsonKey(name: 'outcome_label')  String outcomeLabel, @JsonKey(name: 'raw_code')  String? rawCode, @JsonKey(name: 'raw_receiver')  String? rawReceiver, @JsonKey(name: 'order_id')  int? orderId, @JsonKey(name: 'order_code')  String? orderCode, @JsonKey(name: 'previous_status_label')  String? previousStatusLabel,  String? reason,  List<NawrisSettlementWarning> warnings, @JsonKey(name: 'held_amount')  String heldAmount, @JsonKey(name: 'fee_amount')  String feeAmount)?  $default,) {final _that = this;
switch (_that) {
case _NawrisSettlementLine() when $default != null:
return $default(_that.rowNumber,_that.outcome,_that.outcomeLabel,_that.rawCode,_that.rawReceiver,_that.orderId,_that.orderCode,_that.previousStatusLabel,_that.reason,_that.warnings,_that.heldAmount,_that.feeAmount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NawrisSettlementLine extends NawrisSettlementLine {
  const _NawrisSettlementLine({@JsonKey(name: 'row_number') required this.rowNumber, @JsonKey(unknownEnumValue: NawrisSettlementOutcome.unknown) required this.outcome, @JsonKey(name: 'outcome_label') required this.outcomeLabel, @JsonKey(name: 'raw_code') this.rawCode, @JsonKey(name: 'raw_receiver') this.rawReceiver, @JsonKey(name: 'order_id') this.orderId, @JsonKey(name: 'order_code') this.orderCode, @JsonKey(name: 'previous_status_label') this.previousStatusLabel, this.reason, final  List<NawrisSettlementWarning> warnings = const <NawrisSettlementWarning>[], @JsonKey(name: 'held_amount') this.heldAmount = '0.00', @JsonKey(name: 'fee_amount') this.feeAmount = '0.00'}): _warnings = warnings,super._();
  factory _NawrisSettlementLine.fromJson(Map<String, dynamic> json) => _$NawrisSettlementLineFromJson(json);

/// رقم الصف بعد الترويسة. الصف المركّب يعطي أسطراً بالرقم نفسه.
@override@JsonKey(name: 'row_number') final  int rowNumber;
@override@JsonKey(unknownEnumValue: NawrisSettlementOutcome.unknown) final  NawrisSettlementOutcome outcome;
@override@JsonKey(name: 'outcome_label') final  String outcomeLabel;
@override@JsonKey(name: 'raw_code') final  String? rawCode;
@override@JsonKey(name: 'raw_receiver') final  String? rawReceiver;
@override@JsonKey(name: 'order_id') final  int? orderId;
@override@JsonKey(name: 'order_code') final  String? orderCode;
@override@JsonKey(name: 'previous_status_label') final  String? previousStatusLabel;
/// لماذا لن تتحرك، أو لماذا تُخطّيت — بالعربية كما يُعرض.
@override final  String? reason;
 final  List<NawrisSettlementWarning> _warnings;
@override@JsonKey() List<NawrisSettlementWarning> get warnings {
  if (_warnings is EqualUnmodifiableListView) return _warnings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_warnings);
}

/// ما عند النورس لهذه الطلبية. نصّ لا `double`.
@override@JsonKey(name: 'held_amount') final  String heldAmount;
/// أجرة النورس عليها: المعروفة في المعاينة، والمقيَّدة في الدفعة المنفَّذة.
@override@JsonKey(name: 'fee_amount') final  String feeAmount;

/// Create a copy of NawrisSettlementLine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NawrisSettlementLineCopyWith<_NawrisSettlementLine> get copyWith => __$NawrisSettlementLineCopyWithImpl<_NawrisSettlementLine>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NawrisSettlementLineToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NawrisSettlementLine&&(identical(other.rowNumber, rowNumber) || other.rowNumber == rowNumber)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.outcomeLabel, outcomeLabel) || other.outcomeLabel == outcomeLabel)&&(identical(other.rawCode, rawCode) || other.rawCode == rawCode)&&(identical(other.rawReceiver, rawReceiver) || other.rawReceiver == rawReceiver)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.orderCode, orderCode) || other.orderCode == orderCode)&&(identical(other.previousStatusLabel, previousStatusLabel) || other.previousStatusLabel == previousStatusLabel)&&(identical(other.reason, reason) || other.reason == reason)&&const DeepCollectionEquality().equals(other._warnings, _warnings)&&(identical(other.heldAmount, heldAmount) || other.heldAmount == heldAmount)&&(identical(other.feeAmount, feeAmount) || other.feeAmount == feeAmount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowNumber,outcome,outcomeLabel,rawCode,rawReceiver,orderId,orderCode,previousStatusLabel,reason,const DeepCollectionEquality().hash(_warnings),heldAmount,feeAmount);

@override
String toString() {
  return 'NawrisSettlementLine(rowNumber: $rowNumber, outcome: $outcome, outcomeLabel: $outcomeLabel, rawCode: $rawCode, rawReceiver: $rawReceiver, orderId: $orderId, orderCode: $orderCode, previousStatusLabel: $previousStatusLabel, reason: $reason, warnings: $warnings, heldAmount: $heldAmount, feeAmount: $feeAmount)';
}


}

/// @nodoc
abstract mixin class _$NawrisSettlementLineCopyWith<$Res> implements $NawrisSettlementLineCopyWith<$Res> {
  factory _$NawrisSettlementLineCopyWith(_NawrisSettlementLine value, $Res Function(_NawrisSettlementLine) _then) = __$NawrisSettlementLineCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'row_number') int rowNumber,@JsonKey(unknownEnumValue: NawrisSettlementOutcome.unknown) NawrisSettlementOutcome outcome,@JsonKey(name: 'outcome_label') String outcomeLabel,@JsonKey(name: 'raw_code') String? rawCode,@JsonKey(name: 'raw_receiver') String? rawReceiver,@JsonKey(name: 'order_id') int? orderId,@JsonKey(name: 'order_code') String? orderCode,@JsonKey(name: 'previous_status_label') String? previousStatusLabel, String? reason, List<NawrisSettlementWarning> warnings,@JsonKey(name: 'held_amount') String heldAmount,@JsonKey(name: 'fee_amount') String feeAmount
});




}
/// @nodoc
class __$NawrisSettlementLineCopyWithImpl<$Res>
    implements _$NawrisSettlementLineCopyWith<$Res> {
  __$NawrisSettlementLineCopyWithImpl(this._self, this._then);

  final _NawrisSettlementLine _self;
  final $Res Function(_NawrisSettlementLine) _then;

/// Create a copy of NawrisSettlementLine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rowNumber = null,Object? outcome = null,Object? outcomeLabel = null,Object? rawCode = freezed,Object? rawReceiver = freezed,Object? orderId = freezed,Object? orderCode = freezed,Object? previousStatusLabel = freezed,Object? reason = freezed,Object? warnings = null,Object? heldAmount = null,Object? feeAmount = null,}) {
  return _then(_NawrisSettlementLine(
rowNumber: null == rowNumber ? _self.rowNumber : rowNumber // ignore: cast_nullable_to_non_nullable
as int,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as NawrisSettlementOutcome,outcomeLabel: null == outcomeLabel ? _self.outcomeLabel : outcomeLabel // ignore: cast_nullable_to_non_nullable
as String,rawCode: freezed == rawCode ? _self.rawCode : rawCode // ignore: cast_nullable_to_non_nullable
as String?,rawReceiver: freezed == rawReceiver ? _self.rawReceiver : rawReceiver // ignore: cast_nullable_to_non_nullable
as String?,orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as int?,orderCode: freezed == orderCode ? _self.orderCode : orderCode // ignore: cast_nullable_to_non_nullable
as String?,previousStatusLabel: freezed == previousStatusLabel ? _self.previousStatusLabel : previousStatusLabel // ignore: cast_nullable_to_non_nullable
as String?,reason: freezed == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String?,warnings: null == warnings ? _self._warnings : warnings // ignore: cast_nullable_to_non_nullable
as List<NawrisSettlementWarning>,heldAmount: null == heldAmount ? _self.heldAmount : heldAmount // ignore: cast_nullable_to_non_nullable
as String,feeAmount: null == feeAmount ? _self.feeAmount : feeAmount // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$NawrisSettlementSummary {

@JsonKey(name: 'rows_count') int get rowsCount;@JsonKey(name: 'orders_count') int get ordersCount;@JsonKey(name: 'settled_count') int get settledCount;@JsonKey(name: 'skipped_count') int get skippedCount;@JsonKey(name: 'rejected_count') int get rejectedCount;@JsonKey(name: 'warnings_count') int get warningsCount;/// في الدفعات المنفَّذة وحدها: المعاينة لا تعرف ما سيتركه الموظف.
@JsonKey(name: 'left_out_count') int get leftOutCount;
/// Create a copy of NawrisSettlementSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NawrisSettlementSummaryCopyWith<NawrisSettlementSummary> get copyWith => _$NawrisSettlementSummaryCopyWithImpl<NawrisSettlementSummary>(this as NawrisSettlementSummary, _$identity);

  /// Serializes this NawrisSettlementSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NawrisSettlementSummary&&(identical(other.rowsCount, rowsCount) || other.rowsCount == rowsCount)&&(identical(other.ordersCount, ordersCount) || other.ordersCount == ordersCount)&&(identical(other.settledCount, settledCount) || other.settledCount == settledCount)&&(identical(other.skippedCount, skippedCount) || other.skippedCount == skippedCount)&&(identical(other.rejectedCount, rejectedCount) || other.rejectedCount == rejectedCount)&&(identical(other.warningsCount, warningsCount) || other.warningsCount == warningsCount)&&(identical(other.leftOutCount, leftOutCount) || other.leftOutCount == leftOutCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowsCount,ordersCount,settledCount,skippedCount,rejectedCount,warningsCount,leftOutCount);

@override
String toString() {
  return 'NawrisSettlementSummary(rowsCount: $rowsCount, ordersCount: $ordersCount, settledCount: $settledCount, skippedCount: $skippedCount, rejectedCount: $rejectedCount, warningsCount: $warningsCount, leftOutCount: $leftOutCount)';
}


}

/// @nodoc
abstract mixin class $NawrisSettlementSummaryCopyWith<$Res>  {
  factory $NawrisSettlementSummaryCopyWith(NawrisSettlementSummary value, $Res Function(NawrisSettlementSummary) _then) = _$NawrisSettlementSummaryCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'rows_count') int rowsCount,@JsonKey(name: 'orders_count') int ordersCount,@JsonKey(name: 'settled_count') int settledCount,@JsonKey(name: 'skipped_count') int skippedCount,@JsonKey(name: 'rejected_count') int rejectedCount,@JsonKey(name: 'warnings_count') int warningsCount,@JsonKey(name: 'left_out_count') int leftOutCount
});




}
/// @nodoc
class _$NawrisSettlementSummaryCopyWithImpl<$Res>
    implements $NawrisSettlementSummaryCopyWith<$Res> {
  _$NawrisSettlementSummaryCopyWithImpl(this._self, this._then);

  final NawrisSettlementSummary _self;
  final $Res Function(NawrisSettlementSummary) _then;

/// Create a copy of NawrisSettlementSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rowsCount = null,Object? ordersCount = null,Object? settledCount = null,Object? skippedCount = null,Object? rejectedCount = null,Object? warningsCount = null,Object? leftOutCount = null,}) {
  return _then(_self.copyWith(
rowsCount: null == rowsCount ? _self.rowsCount : rowsCount // ignore: cast_nullable_to_non_nullable
as int,ordersCount: null == ordersCount ? _self.ordersCount : ordersCount // ignore: cast_nullable_to_non_nullable
as int,settledCount: null == settledCount ? _self.settledCount : settledCount // ignore: cast_nullable_to_non_nullable
as int,skippedCount: null == skippedCount ? _self.skippedCount : skippedCount // ignore: cast_nullable_to_non_nullable
as int,rejectedCount: null == rejectedCount ? _self.rejectedCount : rejectedCount // ignore: cast_nullable_to_non_nullable
as int,warningsCount: null == warningsCount ? _self.warningsCount : warningsCount // ignore: cast_nullable_to_non_nullable
as int,leftOutCount: null == leftOutCount ? _self.leftOutCount : leftOutCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [NawrisSettlementSummary].
extension NawrisSettlementSummaryPatterns on NawrisSettlementSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NawrisSettlementSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NawrisSettlementSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NawrisSettlementSummary value)  $default,){
final _that = this;
switch (_that) {
case _NawrisSettlementSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NawrisSettlementSummary value)?  $default,){
final _that = this;
switch (_that) {
case _NawrisSettlementSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'rows_count')  int rowsCount, @JsonKey(name: 'orders_count')  int ordersCount, @JsonKey(name: 'settled_count')  int settledCount, @JsonKey(name: 'skipped_count')  int skippedCount, @JsonKey(name: 'rejected_count')  int rejectedCount, @JsonKey(name: 'warnings_count')  int warningsCount, @JsonKey(name: 'left_out_count')  int leftOutCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NawrisSettlementSummary() when $default != null:
return $default(_that.rowsCount,_that.ordersCount,_that.settledCount,_that.skippedCount,_that.rejectedCount,_that.warningsCount,_that.leftOutCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'rows_count')  int rowsCount, @JsonKey(name: 'orders_count')  int ordersCount, @JsonKey(name: 'settled_count')  int settledCount, @JsonKey(name: 'skipped_count')  int skippedCount, @JsonKey(name: 'rejected_count')  int rejectedCount, @JsonKey(name: 'warnings_count')  int warningsCount, @JsonKey(name: 'left_out_count')  int leftOutCount)  $default,) {final _that = this;
switch (_that) {
case _NawrisSettlementSummary():
return $default(_that.rowsCount,_that.ordersCount,_that.settledCount,_that.skippedCount,_that.rejectedCount,_that.warningsCount,_that.leftOutCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'rows_count')  int rowsCount, @JsonKey(name: 'orders_count')  int ordersCount, @JsonKey(name: 'settled_count')  int settledCount, @JsonKey(name: 'skipped_count')  int skippedCount, @JsonKey(name: 'rejected_count')  int rejectedCount, @JsonKey(name: 'warnings_count')  int warningsCount, @JsonKey(name: 'left_out_count')  int leftOutCount)?  $default,) {final _that = this;
switch (_that) {
case _NawrisSettlementSummary() when $default != null:
return $default(_that.rowsCount,_that.ordersCount,_that.settledCount,_that.skippedCount,_that.rejectedCount,_that.warningsCount,_that.leftOutCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NawrisSettlementSummary implements NawrisSettlementSummary {
  const _NawrisSettlementSummary({@JsonKey(name: 'rows_count') required this.rowsCount, @JsonKey(name: 'orders_count') required this.ordersCount, @JsonKey(name: 'settled_count') required this.settledCount, @JsonKey(name: 'skipped_count') required this.skippedCount, @JsonKey(name: 'rejected_count') required this.rejectedCount, @JsonKey(name: 'warnings_count') required this.warningsCount, @JsonKey(name: 'left_out_count') this.leftOutCount = 0});
  factory _NawrisSettlementSummary.fromJson(Map<String, dynamic> json) => _$NawrisSettlementSummaryFromJson(json);

@override@JsonKey(name: 'rows_count') final  int rowsCount;
@override@JsonKey(name: 'orders_count') final  int ordersCount;
@override@JsonKey(name: 'settled_count') final  int settledCount;
@override@JsonKey(name: 'skipped_count') final  int skippedCount;
@override@JsonKey(name: 'rejected_count') final  int rejectedCount;
@override@JsonKey(name: 'warnings_count') final  int warningsCount;
/// في الدفعات المنفَّذة وحدها: المعاينة لا تعرف ما سيتركه الموظف.
@override@JsonKey(name: 'left_out_count') final  int leftOutCount;

/// Create a copy of NawrisSettlementSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NawrisSettlementSummaryCopyWith<_NawrisSettlementSummary> get copyWith => __$NawrisSettlementSummaryCopyWithImpl<_NawrisSettlementSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NawrisSettlementSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NawrisSettlementSummary&&(identical(other.rowsCount, rowsCount) || other.rowsCount == rowsCount)&&(identical(other.ordersCount, ordersCount) || other.ordersCount == ordersCount)&&(identical(other.settledCount, settledCount) || other.settledCount == settledCount)&&(identical(other.skippedCount, skippedCount) || other.skippedCount == skippedCount)&&(identical(other.rejectedCount, rejectedCount) || other.rejectedCount == rejectedCount)&&(identical(other.warningsCount, warningsCount) || other.warningsCount == warningsCount)&&(identical(other.leftOutCount, leftOutCount) || other.leftOutCount == leftOutCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,rowsCount,ordersCount,settledCount,skippedCount,rejectedCount,warningsCount,leftOutCount);

@override
String toString() {
  return 'NawrisSettlementSummary(rowsCount: $rowsCount, ordersCount: $ordersCount, settledCount: $settledCount, skippedCount: $skippedCount, rejectedCount: $rejectedCount, warningsCount: $warningsCount, leftOutCount: $leftOutCount)';
}


}

/// @nodoc
abstract mixin class _$NawrisSettlementSummaryCopyWith<$Res> implements $NawrisSettlementSummaryCopyWith<$Res> {
  factory _$NawrisSettlementSummaryCopyWith(_NawrisSettlementSummary value, $Res Function(_NawrisSettlementSummary) _then) = __$NawrisSettlementSummaryCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'rows_count') int rowsCount,@JsonKey(name: 'orders_count') int ordersCount,@JsonKey(name: 'settled_count') int settledCount,@JsonKey(name: 'skipped_count') int skippedCount,@JsonKey(name: 'rejected_count') int rejectedCount,@JsonKey(name: 'warnings_count') int warningsCount,@JsonKey(name: 'left_out_count') int leftOutCount
});




}
/// @nodoc
class __$NawrisSettlementSummaryCopyWithImpl<$Res>
    implements _$NawrisSettlementSummaryCopyWith<$Res> {
  __$NawrisSettlementSummaryCopyWithImpl(this._self, this._then);

  final _NawrisSettlementSummary _self;
  final $Res Function(_NawrisSettlementSummary) _then;

/// Create a copy of NawrisSettlementSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rowsCount = null,Object? ordersCount = null,Object? settledCount = null,Object? skippedCount = null,Object? rejectedCount = null,Object? warningsCount = null,Object? leftOutCount = null,}) {
  return _then(_NawrisSettlementSummary(
rowsCount: null == rowsCount ? _self.rowsCount : rowsCount // ignore: cast_nullable_to_non_nullable
as int,ordersCount: null == ordersCount ? _self.ordersCount : ordersCount // ignore: cast_nullable_to_non_nullable
as int,settledCount: null == settledCount ? _self.settledCount : settledCount // ignore: cast_nullable_to_non_nullable
as int,skippedCount: null == skippedCount ? _self.skippedCount : skippedCount // ignore: cast_nullable_to_non_nullable
as int,rejectedCount: null == rejectedCount ? _self.rejectedCount : rejectedCount // ignore: cast_nullable_to_non_nullable
as int,warningsCount: null == warningsCount ? _self.warningsCount : warningsCount // ignore: cast_nullable_to_non_nullable
as int,leftOutCount: null == leftOutCount ? _self.leftOutCount : leftOutCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$NawrisSettlementPreview {

 NawrisSettlementSummary get summary;/// ما عند النورس للطلبيات التي ستُسوّى وحدها — لا لكل الملف، وهذا ما يُكتب مقابله المبلغ.
@JsonKey(name: 'total_held') String get totalHeld;@JsonKey(name: 'known_fees') String get knownFees;/// ما تفتح به خانة «المبلغ المستلم»: ما عنده بعد أجرته المعروفة.
@JsonKey(name: 'expected_received') String get expectedReceived;/// يُعاد مع «تنفيذ»: إن تغيّر شيء منذ هذه المعاينة رفض الخادم ولم يُنفّذ شيء.
 String get fingerprint;/// الحسابات التي تسألها شاشة «تم التسوية» عن هذه الطلبيات — بشكل حقول الحركة نفسه.
 List<TransitionField> get fields; List<NawrisSettlementLine> get lines;
/// Create a copy of NawrisSettlementPreview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NawrisSettlementPreviewCopyWith<NawrisSettlementPreview> get copyWith => _$NawrisSettlementPreviewCopyWithImpl<NawrisSettlementPreview>(this as NawrisSettlementPreview, _$identity);

  /// Serializes this NawrisSettlementPreview to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NawrisSettlementPreview&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.totalHeld, totalHeld) || other.totalHeld == totalHeld)&&(identical(other.knownFees, knownFees) || other.knownFees == knownFees)&&(identical(other.expectedReceived, expectedReceived) || other.expectedReceived == expectedReceived)&&(identical(other.fingerprint, fingerprint) || other.fingerprint == fingerprint)&&const DeepCollectionEquality().equals(other.fields, fields)&&const DeepCollectionEquality().equals(other.lines, lines));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,summary,totalHeld,knownFees,expectedReceived,fingerprint,const DeepCollectionEquality().hash(fields),const DeepCollectionEquality().hash(lines));

@override
String toString() {
  return 'NawrisSettlementPreview(summary: $summary, totalHeld: $totalHeld, knownFees: $knownFees, expectedReceived: $expectedReceived, fingerprint: $fingerprint, fields: $fields, lines: $lines)';
}


}

/// @nodoc
abstract mixin class $NawrisSettlementPreviewCopyWith<$Res>  {
  factory $NawrisSettlementPreviewCopyWith(NawrisSettlementPreview value, $Res Function(NawrisSettlementPreview) _then) = _$NawrisSettlementPreviewCopyWithImpl;
@useResult
$Res call({
 NawrisSettlementSummary summary,@JsonKey(name: 'total_held') String totalHeld,@JsonKey(name: 'known_fees') String knownFees,@JsonKey(name: 'expected_received') String expectedReceived, String fingerprint, List<TransitionField> fields, List<NawrisSettlementLine> lines
});


$NawrisSettlementSummaryCopyWith<$Res> get summary;

}
/// @nodoc
class _$NawrisSettlementPreviewCopyWithImpl<$Res>
    implements $NawrisSettlementPreviewCopyWith<$Res> {
  _$NawrisSettlementPreviewCopyWithImpl(this._self, this._then);

  final NawrisSettlementPreview _self;
  final $Res Function(NawrisSettlementPreview) _then;

/// Create a copy of NawrisSettlementPreview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? summary = null,Object? totalHeld = null,Object? knownFees = null,Object? expectedReceived = null,Object? fingerprint = null,Object? fields = null,Object? lines = null,}) {
  return _then(_self.copyWith(
summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as NawrisSettlementSummary,totalHeld: null == totalHeld ? _self.totalHeld : totalHeld // ignore: cast_nullable_to_non_nullable
as String,knownFees: null == knownFees ? _self.knownFees : knownFees // ignore: cast_nullable_to_non_nullable
as String,expectedReceived: null == expectedReceived ? _self.expectedReceived : expectedReceived // ignore: cast_nullable_to_non_nullable
as String,fingerprint: null == fingerprint ? _self.fingerprint : fingerprint // ignore: cast_nullable_to_non_nullable
as String,fields: null == fields ? _self.fields : fields // ignore: cast_nullable_to_non_nullable
as List<TransitionField>,lines: null == lines ? _self.lines : lines // ignore: cast_nullable_to_non_nullable
as List<NawrisSettlementLine>,
  ));
}
/// Create a copy of NawrisSettlementPreview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NawrisSettlementSummaryCopyWith<$Res> get summary {
  
  return $NawrisSettlementSummaryCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}


/// Adds pattern-matching-related methods to [NawrisSettlementPreview].
extension NawrisSettlementPreviewPatterns on NawrisSettlementPreview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NawrisSettlementPreview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NawrisSettlementPreview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NawrisSettlementPreview value)  $default,){
final _that = this;
switch (_that) {
case _NawrisSettlementPreview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NawrisSettlementPreview value)?  $default,){
final _that = this;
switch (_that) {
case _NawrisSettlementPreview() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( NawrisSettlementSummary summary, @JsonKey(name: 'total_held')  String totalHeld, @JsonKey(name: 'known_fees')  String knownFees, @JsonKey(name: 'expected_received')  String expectedReceived,  String fingerprint,  List<TransitionField> fields,  List<NawrisSettlementLine> lines)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NawrisSettlementPreview() when $default != null:
return $default(_that.summary,_that.totalHeld,_that.knownFees,_that.expectedReceived,_that.fingerprint,_that.fields,_that.lines);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( NawrisSettlementSummary summary, @JsonKey(name: 'total_held')  String totalHeld, @JsonKey(name: 'known_fees')  String knownFees, @JsonKey(name: 'expected_received')  String expectedReceived,  String fingerprint,  List<TransitionField> fields,  List<NawrisSettlementLine> lines)  $default,) {final _that = this;
switch (_that) {
case _NawrisSettlementPreview():
return $default(_that.summary,_that.totalHeld,_that.knownFees,_that.expectedReceived,_that.fingerprint,_that.fields,_that.lines);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( NawrisSettlementSummary summary, @JsonKey(name: 'total_held')  String totalHeld, @JsonKey(name: 'known_fees')  String knownFees, @JsonKey(name: 'expected_received')  String expectedReceived,  String fingerprint,  List<TransitionField> fields,  List<NawrisSettlementLine> lines)?  $default,) {final _that = this;
switch (_that) {
case _NawrisSettlementPreview() when $default != null:
return $default(_that.summary,_that.totalHeld,_that.knownFees,_that.expectedReceived,_that.fingerprint,_that.fields,_that.lines);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NawrisSettlementPreview extends NawrisSettlementPreview {
  const _NawrisSettlementPreview({required this.summary, @JsonKey(name: 'total_held') required this.totalHeld, @JsonKey(name: 'known_fees') required this.knownFees, @JsonKey(name: 'expected_received') required this.expectedReceived, required this.fingerprint, final  List<TransitionField> fields = const <TransitionField>[], final  List<NawrisSettlementLine> lines = const <NawrisSettlementLine>[]}): _fields = fields,_lines = lines,super._();
  factory _NawrisSettlementPreview.fromJson(Map<String, dynamic> json) => _$NawrisSettlementPreviewFromJson(json);

@override final  NawrisSettlementSummary summary;
/// ما عند النورس للطلبيات التي ستُسوّى وحدها — لا لكل الملف، وهذا ما يُكتب مقابله المبلغ.
@override@JsonKey(name: 'total_held') final  String totalHeld;
@override@JsonKey(name: 'known_fees') final  String knownFees;
/// ما تفتح به خانة «المبلغ المستلم»: ما عنده بعد أجرته المعروفة.
@override@JsonKey(name: 'expected_received') final  String expectedReceived;
/// يُعاد مع «تنفيذ»: إن تغيّر شيء منذ هذه المعاينة رفض الخادم ولم يُنفّذ شيء.
@override final  String fingerprint;
/// الحسابات التي تسألها شاشة «تم التسوية» عن هذه الطلبيات — بشكل حقول الحركة نفسه.
 final  List<TransitionField> _fields;
/// الحسابات التي تسألها شاشة «تم التسوية» عن هذه الطلبيات — بشكل حقول الحركة نفسه.
@override@JsonKey() List<TransitionField> get fields {
  if (_fields is EqualUnmodifiableListView) return _fields;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fields);
}

 final  List<NawrisSettlementLine> _lines;
@override@JsonKey() List<NawrisSettlementLine> get lines {
  if (_lines is EqualUnmodifiableListView) return _lines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lines);
}


/// Create a copy of NawrisSettlementPreview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NawrisSettlementPreviewCopyWith<_NawrisSettlementPreview> get copyWith => __$NawrisSettlementPreviewCopyWithImpl<_NawrisSettlementPreview>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NawrisSettlementPreviewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NawrisSettlementPreview&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.totalHeld, totalHeld) || other.totalHeld == totalHeld)&&(identical(other.knownFees, knownFees) || other.knownFees == knownFees)&&(identical(other.expectedReceived, expectedReceived) || other.expectedReceived == expectedReceived)&&(identical(other.fingerprint, fingerprint) || other.fingerprint == fingerprint)&&const DeepCollectionEquality().equals(other._fields, _fields)&&const DeepCollectionEquality().equals(other._lines, _lines));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,summary,totalHeld,knownFees,expectedReceived,fingerprint,const DeepCollectionEquality().hash(_fields),const DeepCollectionEquality().hash(_lines));

@override
String toString() {
  return 'NawrisSettlementPreview(summary: $summary, totalHeld: $totalHeld, knownFees: $knownFees, expectedReceived: $expectedReceived, fingerprint: $fingerprint, fields: $fields, lines: $lines)';
}


}

/// @nodoc
abstract mixin class _$NawrisSettlementPreviewCopyWith<$Res> implements $NawrisSettlementPreviewCopyWith<$Res> {
  factory _$NawrisSettlementPreviewCopyWith(_NawrisSettlementPreview value, $Res Function(_NawrisSettlementPreview) _then) = __$NawrisSettlementPreviewCopyWithImpl;
@override @useResult
$Res call({
 NawrisSettlementSummary summary,@JsonKey(name: 'total_held') String totalHeld,@JsonKey(name: 'known_fees') String knownFees,@JsonKey(name: 'expected_received') String expectedReceived, String fingerprint, List<TransitionField> fields, List<NawrisSettlementLine> lines
});


@override $NawrisSettlementSummaryCopyWith<$Res> get summary;

}
/// @nodoc
class __$NawrisSettlementPreviewCopyWithImpl<$Res>
    implements _$NawrisSettlementPreviewCopyWith<$Res> {
  __$NawrisSettlementPreviewCopyWithImpl(this._self, this._then);

  final _NawrisSettlementPreview _self;
  final $Res Function(_NawrisSettlementPreview) _then;

/// Create a copy of NawrisSettlementPreview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? summary = null,Object? totalHeld = null,Object? knownFees = null,Object? expectedReceived = null,Object? fingerprint = null,Object? fields = null,Object? lines = null,}) {
  return _then(_NawrisSettlementPreview(
summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as NawrisSettlementSummary,totalHeld: null == totalHeld ? _self.totalHeld : totalHeld // ignore: cast_nullable_to_non_nullable
as String,knownFees: null == knownFees ? _self.knownFees : knownFees // ignore: cast_nullable_to_non_nullable
as String,expectedReceived: null == expectedReceived ? _self.expectedReceived : expectedReceived // ignore: cast_nullable_to_non_nullable
as String,fingerprint: null == fingerprint ? _self.fingerprint : fingerprint // ignore: cast_nullable_to_non_nullable
as String,fields: null == fields ? _self._fields : fields // ignore: cast_nullable_to_non_nullable
as List<TransitionField>,lines: null == lines ? _self._lines : lines // ignore: cast_nullable_to_non_nullable
as List<NawrisSettlementLine>,
  ));
}

/// Create a copy of NawrisSettlementPreview
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NawrisSettlementSummaryCopyWith<$Res> get summary {
  
  return $NawrisSettlementSummaryCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}


/// @nodoc
mixin _$NawrisSettlementImporter {

 int get id; String get name;
/// Create a copy of NawrisSettlementImporter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NawrisSettlementImporterCopyWith<NawrisSettlementImporter> get copyWith => _$NawrisSettlementImporterCopyWithImpl<NawrisSettlementImporter>(this as NawrisSettlementImporter, _$identity);

  /// Serializes this NawrisSettlementImporter to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NawrisSettlementImporter&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'NawrisSettlementImporter(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $NawrisSettlementImporterCopyWith<$Res>  {
  factory $NawrisSettlementImporterCopyWith(NawrisSettlementImporter value, $Res Function(NawrisSettlementImporter) _then) = _$NawrisSettlementImporterCopyWithImpl;
@useResult
$Res call({
 int id, String name
});




}
/// @nodoc
class _$NawrisSettlementImporterCopyWithImpl<$Res>
    implements $NawrisSettlementImporterCopyWith<$Res> {
  _$NawrisSettlementImporterCopyWithImpl(this._self, this._then);

  final NawrisSettlementImporter _self;
  final $Res Function(NawrisSettlementImporter) _then;

/// Create a copy of NawrisSettlementImporter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [NawrisSettlementImporter].
extension NawrisSettlementImporterPatterns on NawrisSettlementImporter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NawrisSettlementImporter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NawrisSettlementImporter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NawrisSettlementImporter value)  $default,){
final _that = this;
switch (_that) {
case _NawrisSettlementImporter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NawrisSettlementImporter value)?  $default,){
final _that = this;
switch (_that) {
case _NawrisSettlementImporter() when $default != null:
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
case _NawrisSettlementImporter() when $default != null:
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
case _NawrisSettlementImporter():
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
case _NawrisSettlementImporter() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NawrisSettlementImporter implements NawrisSettlementImporter {
  const _NawrisSettlementImporter({required this.id, required this.name});
  factory _NawrisSettlementImporter.fromJson(Map<String, dynamic> json) => _$NawrisSettlementImporterFromJson(json);

@override final  int id;
@override final  String name;

/// Create a copy of NawrisSettlementImporter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NawrisSettlementImporterCopyWith<_NawrisSettlementImporter> get copyWith => __$NawrisSettlementImporterCopyWithImpl<_NawrisSettlementImporter>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NawrisSettlementImporterToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NawrisSettlementImporter&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'NawrisSettlementImporter(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$NawrisSettlementImporterCopyWith<$Res> implements $NawrisSettlementImporterCopyWith<$Res> {
  factory _$NawrisSettlementImporterCopyWith(_NawrisSettlementImporter value, $Res Function(_NawrisSettlementImporter) _then) = __$NawrisSettlementImporterCopyWithImpl;
@override @useResult
$Res call({
 int id, String name
});




}
/// @nodoc
class __$NawrisSettlementImporterCopyWithImpl<$Res>
    implements _$NawrisSettlementImporterCopyWith<$Res> {
  __$NawrisSettlementImporterCopyWithImpl(this._self, this._then);

  final _NawrisSettlementImporter _self;
  final $Res Function(_NawrisSettlementImporter) _then;

/// Create a copy of NawrisSettlementImporter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_NawrisSettlementImporter(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$NawrisSettlementImport {

 int get id;@JsonKey(name: 'file_name') String get fileName; NawrisSettlementSummary get summary;@JsonKey(name: 'total_held') String get totalHeld;@JsonKey(name: 'received_amount') String get receivedAmount;@JsonKey(name: 'fee_total') String get feeTotal;@JsonKey(name: 'imported_by') NawrisSettlementImporter? get importedBy;@JsonKey(name: 'difference_reason') String? get differenceReason;@JsonKey(name: 'created_at') DateTime? get createdAt; List<NawrisSettlementLine> get items;
/// Create a copy of NawrisSettlementImport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NawrisSettlementImportCopyWith<NawrisSettlementImport> get copyWith => _$NawrisSettlementImportCopyWithImpl<NawrisSettlementImport>(this as NawrisSettlementImport, _$identity);

  /// Serializes this NawrisSettlementImport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NawrisSettlementImport&&(identical(other.id, id) || other.id == id)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.totalHeld, totalHeld) || other.totalHeld == totalHeld)&&(identical(other.receivedAmount, receivedAmount) || other.receivedAmount == receivedAmount)&&(identical(other.feeTotal, feeTotal) || other.feeTotal == feeTotal)&&(identical(other.importedBy, importedBy) || other.importedBy == importedBy)&&(identical(other.differenceReason, differenceReason) || other.differenceReason == differenceReason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other.items, items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fileName,summary,totalHeld,receivedAmount,feeTotal,importedBy,differenceReason,createdAt,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'NawrisSettlementImport(id: $id, fileName: $fileName, summary: $summary, totalHeld: $totalHeld, receivedAmount: $receivedAmount, feeTotal: $feeTotal, importedBy: $importedBy, differenceReason: $differenceReason, createdAt: $createdAt, items: $items)';
}


}

/// @nodoc
abstract mixin class $NawrisSettlementImportCopyWith<$Res>  {
  factory $NawrisSettlementImportCopyWith(NawrisSettlementImport value, $Res Function(NawrisSettlementImport) _then) = _$NawrisSettlementImportCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'file_name') String fileName, NawrisSettlementSummary summary,@JsonKey(name: 'total_held') String totalHeld,@JsonKey(name: 'received_amount') String receivedAmount,@JsonKey(name: 'fee_total') String feeTotal,@JsonKey(name: 'imported_by') NawrisSettlementImporter? importedBy,@JsonKey(name: 'difference_reason') String? differenceReason,@JsonKey(name: 'created_at') DateTime? createdAt, List<NawrisSettlementLine> items
});


$NawrisSettlementSummaryCopyWith<$Res> get summary;$NawrisSettlementImporterCopyWith<$Res>? get importedBy;

}
/// @nodoc
class _$NawrisSettlementImportCopyWithImpl<$Res>
    implements $NawrisSettlementImportCopyWith<$Res> {
  _$NawrisSettlementImportCopyWithImpl(this._self, this._then);

  final NawrisSettlementImport _self;
  final $Res Function(NawrisSettlementImport) _then;

/// Create a copy of NawrisSettlementImport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fileName = null,Object? summary = null,Object? totalHeld = null,Object? receivedAmount = null,Object? feeTotal = null,Object? importedBy = freezed,Object? differenceReason = freezed,Object? createdAt = freezed,Object? items = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as NawrisSettlementSummary,totalHeld: null == totalHeld ? _self.totalHeld : totalHeld // ignore: cast_nullable_to_non_nullable
as String,receivedAmount: null == receivedAmount ? _self.receivedAmount : receivedAmount // ignore: cast_nullable_to_non_nullable
as String,feeTotal: null == feeTotal ? _self.feeTotal : feeTotal // ignore: cast_nullable_to_non_nullable
as String,importedBy: freezed == importedBy ? _self.importedBy : importedBy // ignore: cast_nullable_to_non_nullable
as NawrisSettlementImporter?,differenceReason: freezed == differenceReason ? _self.differenceReason : differenceReason // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<NawrisSettlementLine>,
  ));
}
/// Create a copy of NawrisSettlementImport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NawrisSettlementSummaryCopyWith<$Res> get summary {
  
  return $NawrisSettlementSummaryCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}/// Create a copy of NawrisSettlementImport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NawrisSettlementImporterCopyWith<$Res>? get importedBy {
    if (_self.importedBy == null) {
    return null;
  }

  return $NawrisSettlementImporterCopyWith<$Res>(_self.importedBy!, (value) {
    return _then(_self.copyWith(importedBy: value));
  });
}
}


/// Adds pattern-matching-related methods to [NawrisSettlementImport].
extension NawrisSettlementImportPatterns on NawrisSettlementImport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NawrisSettlementImport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NawrisSettlementImport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NawrisSettlementImport value)  $default,){
final _that = this;
switch (_that) {
case _NawrisSettlementImport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NawrisSettlementImport value)?  $default,){
final _that = this;
switch (_that) {
case _NawrisSettlementImport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'file_name')  String fileName,  NawrisSettlementSummary summary, @JsonKey(name: 'total_held')  String totalHeld, @JsonKey(name: 'received_amount')  String receivedAmount, @JsonKey(name: 'fee_total')  String feeTotal, @JsonKey(name: 'imported_by')  NawrisSettlementImporter? importedBy, @JsonKey(name: 'difference_reason')  String? differenceReason, @JsonKey(name: 'created_at')  DateTime? createdAt,  List<NawrisSettlementLine> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NawrisSettlementImport() when $default != null:
return $default(_that.id,_that.fileName,_that.summary,_that.totalHeld,_that.receivedAmount,_that.feeTotal,_that.importedBy,_that.differenceReason,_that.createdAt,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'file_name')  String fileName,  NawrisSettlementSummary summary, @JsonKey(name: 'total_held')  String totalHeld, @JsonKey(name: 'received_amount')  String receivedAmount, @JsonKey(name: 'fee_total')  String feeTotal, @JsonKey(name: 'imported_by')  NawrisSettlementImporter? importedBy, @JsonKey(name: 'difference_reason')  String? differenceReason, @JsonKey(name: 'created_at')  DateTime? createdAt,  List<NawrisSettlementLine> items)  $default,) {final _that = this;
switch (_that) {
case _NawrisSettlementImport():
return $default(_that.id,_that.fileName,_that.summary,_that.totalHeld,_that.receivedAmount,_that.feeTotal,_that.importedBy,_that.differenceReason,_that.createdAt,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'file_name')  String fileName,  NawrisSettlementSummary summary, @JsonKey(name: 'total_held')  String totalHeld, @JsonKey(name: 'received_amount')  String receivedAmount, @JsonKey(name: 'fee_total')  String feeTotal, @JsonKey(name: 'imported_by')  NawrisSettlementImporter? importedBy, @JsonKey(name: 'difference_reason')  String? differenceReason, @JsonKey(name: 'created_at')  DateTime? createdAt,  List<NawrisSettlementLine> items)?  $default,) {final _that = this;
switch (_that) {
case _NawrisSettlementImport() when $default != null:
return $default(_that.id,_that.fileName,_that.summary,_that.totalHeld,_that.receivedAmount,_that.feeTotal,_that.importedBy,_that.differenceReason,_that.createdAt,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NawrisSettlementImport implements NawrisSettlementImport {
  const _NawrisSettlementImport({required this.id, @JsonKey(name: 'file_name') required this.fileName, required this.summary, @JsonKey(name: 'total_held') required this.totalHeld, @JsonKey(name: 'received_amount') required this.receivedAmount, @JsonKey(name: 'fee_total') required this.feeTotal, @JsonKey(name: 'imported_by') this.importedBy, @JsonKey(name: 'difference_reason') this.differenceReason, @JsonKey(name: 'created_at') this.createdAt, final  List<NawrisSettlementLine> items = const <NawrisSettlementLine>[]}): _items = items;
  factory _NawrisSettlementImport.fromJson(Map<String, dynamic> json) => _$NawrisSettlementImportFromJson(json);

@override final  int id;
@override@JsonKey(name: 'file_name') final  String fileName;
@override final  NawrisSettlementSummary summary;
@override@JsonKey(name: 'total_held') final  String totalHeld;
@override@JsonKey(name: 'received_amount') final  String receivedAmount;
@override@JsonKey(name: 'fee_total') final  String feeTotal;
@override@JsonKey(name: 'imported_by') final  NawrisSettlementImporter? importedBy;
@override@JsonKey(name: 'difference_reason') final  String? differenceReason;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
 final  List<NawrisSettlementLine> _items;
@override@JsonKey() List<NawrisSettlementLine> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of NawrisSettlementImport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NawrisSettlementImportCopyWith<_NawrisSettlementImport> get copyWith => __$NawrisSettlementImportCopyWithImpl<_NawrisSettlementImport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NawrisSettlementImportToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NawrisSettlementImport&&(identical(other.id, id) || other.id == id)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.totalHeld, totalHeld) || other.totalHeld == totalHeld)&&(identical(other.receivedAmount, receivedAmount) || other.receivedAmount == receivedAmount)&&(identical(other.feeTotal, feeTotal) || other.feeTotal == feeTotal)&&(identical(other.importedBy, importedBy) || other.importedBy == importedBy)&&(identical(other.differenceReason, differenceReason) || other.differenceReason == differenceReason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&const DeepCollectionEquality().equals(other._items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fileName,summary,totalHeld,receivedAmount,feeTotal,importedBy,differenceReason,createdAt,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'NawrisSettlementImport(id: $id, fileName: $fileName, summary: $summary, totalHeld: $totalHeld, receivedAmount: $receivedAmount, feeTotal: $feeTotal, importedBy: $importedBy, differenceReason: $differenceReason, createdAt: $createdAt, items: $items)';
}


}

/// @nodoc
abstract mixin class _$NawrisSettlementImportCopyWith<$Res> implements $NawrisSettlementImportCopyWith<$Res> {
  factory _$NawrisSettlementImportCopyWith(_NawrisSettlementImport value, $Res Function(_NawrisSettlementImport) _then) = __$NawrisSettlementImportCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'file_name') String fileName, NawrisSettlementSummary summary,@JsonKey(name: 'total_held') String totalHeld,@JsonKey(name: 'received_amount') String receivedAmount,@JsonKey(name: 'fee_total') String feeTotal,@JsonKey(name: 'imported_by') NawrisSettlementImporter? importedBy,@JsonKey(name: 'difference_reason') String? differenceReason,@JsonKey(name: 'created_at') DateTime? createdAt, List<NawrisSettlementLine> items
});


@override $NawrisSettlementSummaryCopyWith<$Res> get summary;@override $NawrisSettlementImporterCopyWith<$Res>? get importedBy;

}
/// @nodoc
class __$NawrisSettlementImportCopyWithImpl<$Res>
    implements _$NawrisSettlementImportCopyWith<$Res> {
  __$NawrisSettlementImportCopyWithImpl(this._self, this._then);

  final _NawrisSettlementImport _self;
  final $Res Function(_NawrisSettlementImport) _then;

/// Create a copy of NawrisSettlementImport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fileName = null,Object? summary = null,Object? totalHeld = null,Object? receivedAmount = null,Object? feeTotal = null,Object? importedBy = freezed,Object? differenceReason = freezed,Object? createdAt = freezed,Object? items = null,}) {
  return _then(_NawrisSettlementImport(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as NawrisSettlementSummary,totalHeld: null == totalHeld ? _self.totalHeld : totalHeld // ignore: cast_nullable_to_non_nullable
as String,receivedAmount: null == receivedAmount ? _self.receivedAmount : receivedAmount // ignore: cast_nullable_to_non_nullable
as String,feeTotal: null == feeTotal ? _self.feeTotal : feeTotal // ignore: cast_nullable_to_non_nullable
as String,importedBy: freezed == importedBy ? _self.importedBy : importedBy // ignore: cast_nullable_to_non_nullable
as NawrisSettlementImporter?,differenceReason: freezed == differenceReason ? _self.differenceReason : differenceReason // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<NawrisSettlementLine>,
  ));
}

/// Create a copy of NawrisSettlementImport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NawrisSettlementSummaryCopyWith<$Res> get summary {
  
  return $NawrisSettlementSummaryCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}/// Create a copy of NawrisSettlementImport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NawrisSettlementImporterCopyWith<$Res>? get importedBy {
    if (_self.importedBy == null) {
    return null;
  }

  return $NawrisSettlementImporterCopyWith<$Res>(_self.importedBy!, (value) {
    return _then(_self.copyWith(importedBy: value));
  });
}
}

// dart format on
