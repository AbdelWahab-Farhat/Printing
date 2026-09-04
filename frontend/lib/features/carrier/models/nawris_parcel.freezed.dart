// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nawris_parcel.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NawrisParcel {

 int get id;/// Their identifier for this parcel. Shown to the person who dispatched it.
 String get code;/// Ours — minted at dispatch so a duplicate hand-over is detectable on both sides.
 String? get reference;@JsonKey(name: 'bar_code') String? get barCode;/// Their government and area ids, resolved from the order's own city and region. Kept
/// because a parcel that went to the wrong place is diagnosed by comparing these two
/// against the city that was picked.
 String? get government; String? get area;/// The COD we asked them to collect.
@JsonKey(name: 'amount_to_collect') String? get amountToCollect;/// Our delivery fee, taken off the COD before dispatch and frozen here. The customer pays it
/// to the courier, so it never reaches our drawer.
@JsonKey(name: 'delivery_price_deducted') String? get deliveryPriceDeducted;/// What they actually collected — null until a delivery is reported.
@JsonKey(name: 'collected_amount') String? get collectedAmount;/// Their integer and their prose. The status mapping is written against the first; the
/// second is what support reads, and it is never interpreted.
@JsonKey(name: 'remote_status_code') int? get remoteStatusCode;@JsonKey(name: 'remote_status_text') String? get remoteStatusText;@JsonKey(name: 'is_open') bool get isOpen;@JsonKey(name: 'has_open_conflict') bool get hasOpenConflict;@JsonKey(name: 'dispatched_at') DateTime? get dispatchedAt;@JsonKey(name: 'closed_at') DateTime? get closedAt;
/// Create a copy of NawrisParcel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NawrisParcelCopyWith<NawrisParcel> get copyWith => _$NawrisParcelCopyWithImpl<NawrisParcel>(this as NawrisParcel, _$identity);

  /// Serializes this NawrisParcel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NawrisParcel&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.barCode, barCode) || other.barCode == barCode)&&(identical(other.government, government) || other.government == government)&&(identical(other.area, area) || other.area == area)&&(identical(other.amountToCollect, amountToCollect) || other.amountToCollect == amountToCollect)&&(identical(other.deliveryPriceDeducted, deliveryPriceDeducted) || other.deliveryPriceDeducted == deliveryPriceDeducted)&&(identical(other.collectedAmount, collectedAmount) || other.collectedAmount == collectedAmount)&&(identical(other.remoteStatusCode, remoteStatusCode) || other.remoteStatusCode == remoteStatusCode)&&(identical(other.remoteStatusText, remoteStatusText) || other.remoteStatusText == remoteStatusText)&&(identical(other.isOpen, isOpen) || other.isOpen == isOpen)&&(identical(other.hasOpenConflict, hasOpenConflict) || other.hasOpenConflict == hasOpenConflict)&&(identical(other.dispatchedAt, dispatchedAt) || other.dispatchedAt == dispatchedAt)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,reference,barCode,government,area,amountToCollect,deliveryPriceDeducted,collectedAmount,remoteStatusCode,remoteStatusText,isOpen,hasOpenConflict,dispatchedAt,closedAt);

@override
String toString() {
  return 'NawrisParcel(id: $id, code: $code, reference: $reference, barCode: $barCode, government: $government, area: $area, amountToCollect: $amountToCollect, deliveryPriceDeducted: $deliveryPriceDeducted, collectedAmount: $collectedAmount, remoteStatusCode: $remoteStatusCode, remoteStatusText: $remoteStatusText, isOpen: $isOpen, hasOpenConflict: $hasOpenConflict, dispatchedAt: $dispatchedAt, closedAt: $closedAt)';
}


}

/// @nodoc
abstract mixin class $NawrisParcelCopyWith<$Res>  {
  factory $NawrisParcelCopyWith(NawrisParcel value, $Res Function(NawrisParcel) _then) = _$NawrisParcelCopyWithImpl;
@useResult
$Res call({
 int id, String code, String? reference,@JsonKey(name: 'bar_code') String? barCode, String? government, String? area,@JsonKey(name: 'amount_to_collect') String? amountToCollect,@JsonKey(name: 'delivery_price_deducted') String? deliveryPriceDeducted,@JsonKey(name: 'collected_amount') String? collectedAmount,@JsonKey(name: 'remote_status_code') int? remoteStatusCode,@JsonKey(name: 'remote_status_text') String? remoteStatusText,@JsonKey(name: 'is_open') bool isOpen,@JsonKey(name: 'has_open_conflict') bool hasOpenConflict,@JsonKey(name: 'dispatched_at') DateTime? dispatchedAt,@JsonKey(name: 'closed_at') DateTime? closedAt
});




}
/// @nodoc
class _$NawrisParcelCopyWithImpl<$Res>
    implements $NawrisParcelCopyWith<$Res> {
  _$NawrisParcelCopyWithImpl(this._self, this._then);

  final NawrisParcel _self;
  final $Res Function(NawrisParcel) _then;

/// Create a copy of NawrisParcel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? reference = freezed,Object? barCode = freezed,Object? government = freezed,Object? area = freezed,Object? amountToCollect = freezed,Object? deliveryPriceDeducted = freezed,Object? collectedAmount = freezed,Object? remoteStatusCode = freezed,Object? remoteStatusText = freezed,Object? isOpen = null,Object? hasOpenConflict = null,Object? dispatchedAt = freezed,Object? closedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,barCode: freezed == barCode ? _self.barCode : barCode // ignore: cast_nullable_to_non_nullable
as String?,government: freezed == government ? _self.government : government // ignore: cast_nullable_to_non_nullable
as String?,area: freezed == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as String?,amountToCollect: freezed == amountToCollect ? _self.amountToCollect : amountToCollect // ignore: cast_nullable_to_non_nullable
as String?,deliveryPriceDeducted: freezed == deliveryPriceDeducted ? _self.deliveryPriceDeducted : deliveryPriceDeducted // ignore: cast_nullable_to_non_nullable
as String?,collectedAmount: freezed == collectedAmount ? _self.collectedAmount : collectedAmount // ignore: cast_nullable_to_non_nullable
as String?,remoteStatusCode: freezed == remoteStatusCode ? _self.remoteStatusCode : remoteStatusCode // ignore: cast_nullable_to_non_nullable
as int?,remoteStatusText: freezed == remoteStatusText ? _self.remoteStatusText : remoteStatusText // ignore: cast_nullable_to_non_nullable
as String?,isOpen: null == isOpen ? _self.isOpen : isOpen // ignore: cast_nullable_to_non_nullable
as bool,hasOpenConflict: null == hasOpenConflict ? _self.hasOpenConflict : hasOpenConflict // ignore: cast_nullable_to_non_nullable
as bool,dispatchedAt: freezed == dispatchedAt ? _self.dispatchedAt : dispatchedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [NawrisParcel].
extension NawrisParcelPatterns on NawrisParcel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NawrisParcel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NawrisParcel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NawrisParcel value)  $default,){
final _that = this;
switch (_that) {
case _NawrisParcel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NawrisParcel value)?  $default,){
final _that = this;
switch (_that) {
case _NawrisParcel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String code,  String? reference, @JsonKey(name: 'bar_code')  String? barCode,  String? government,  String? area, @JsonKey(name: 'amount_to_collect')  String? amountToCollect, @JsonKey(name: 'delivery_price_deducted')  String? deliveryPriceDeducted, @JsonKey(name: 'collected_amount')  String? collectedAmount, @JsonKey(name: 'remote_status_code')  int? remoteStatusCode, @JsonKey(name: 'remote_status_text')  String? remoteStatusText, @JsonKey(name: 'is_open')  bool isOpen, @JsonKey(name: 'has_open_conflict')  bool hasOpenConflict, @JsonKey(name: 'dispatched_at')  DateTime? dispatchedAt, @JsonKey(name: 'closed_at')  DateTime? closedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NawrisParcel() when $default != null:
return $default(_that.id,_that.code,_that.reference,_that.barCode,_that.government,_that.area,_that.amountToCollect,_that.deliveryPriceDeducted,_that.collectedAmount,_that.remoteStatusCode,_that.remoteStatusText,_that.isOpen,_that.hasOpenConflict,_that.dispatchedAt,_that.closedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String code,  String? reference, @JsonKey(name: 'bar_code')  String? barCode,  String? government,  String? area, @JsonKey(name: 'amount_to_collect')  String? amountToCollect, @JsonKey(name: 'delivery_price_deducted')  String? deliveryPriceDeducted, @JsonKey(name: 'collected_amount')  String? collectedAmount, @JsonKey(name: 'remote_status_code')  int? remoteStatusCode, @JsonKey(name: 'remote_status_text')  String? remoteStatusText, @JsonKey(name: 'is_open')  bool isOpen, @JsonKey(name: 'has_open_conflict')  bool hasOpenConflict, @JsonKey(name: 'dispatched_at')  DateTime? dispatchedAt, @JsonKey(name: 'closed_at')  DateTime? closedAt)  $default,) {final _that = this;
switch (_that) {
case _NawrisParcel():
return $default(_that.id,_that.code,_that.reference,_that.barCode,_that.government,_that.area,_that.amountToCollect,_that.deliveryPriceDeducted,_that.collectedAmount,_that.remoteStatusCode,_that.remoteStatusText,_that.isOpen,_that.hasOpenConflict,_that.dispatchedAt,_that.closedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String code,  String? reference, @JsonKey(name: 'bar_code')  String? barCode,  String? government,  String? area, @JsonKey(name: 'amount_to_collect')  String? amountToCollect, @JsonKey(name: 'delivery_price_deducted')  String? deliveryPriceDeducted, @JsonKey(name: 'collected_amount')  String? collectedAmount, @JsonKey(name: 'remote_status_code')  int? remoteStatusCode, @JsonKey(name: 'remote_status_text')  String? remoteStatusText, @JsonKey(name: 'is_open')  bool isOpen, @JsonKey(name: 'has_open_conflict')  bool hasOpenConflict, @JsonKey(name: 'dispatched_at')  DateTime? dispatchedAt, @JsonKey(name: 'closed_at')  DateTime? closedAt)?  $default,) {final _that = this;
switch (_that) {
case _NawrisParcel() when $default != null:
return $default(_that.id,_that.code,_that.reference,_that.barCode,_that.government,_that.area,_that.amountToCollect,_that.deliveryPriceDeducted,_that.collectedAmount,_that.remoteStatusCode,_that.remoteStatusText,_that.isOpen,_that.hasOpenConflict,_that.dispatchedAt,_that.closedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NawrisParcel implements NawrisParcel {
  const _NawrisParcel({required this.id, required this.code, this.reference, @JsonKey(name: 'bar_code') this.barCode, this.government, this.area, @JsonKey(name: 'amount_to_collect') this.amountToCollect, @JsonKey(name: 'delivery_price_deducted') this.deliveryPriceDeducted, @JsonKey(name: 'collected_amount') this.collectedAmount, @JsonKey(name: 'remote_status_code') this.remoteStatusCode, @JsonKey(name: 'remote_status_text') this.remoteStatusText, @JsonKey(name: 'is_open') this.isOpen = false, @JsonKey(name: 'has_open_conflict') this.hasOpenConflict = false, @JsonKey(name: 'dispatched_at') this.dispatchedAt, @JsonKey(name: 'closed_at') this.closedAt});
  factory _NawrisParcel.fromJson(Map<String, dynamic> json) => _$NawrisParcelFromJson(json);

@override final  int id;
/// Their identifier for this parcel. Shown to the person who dispatched it.
@override final  String code;
/// Ours — minted at dispatch so a duplicate hand-over is detectable on both sides.
@override final  String? reference;
@override@JsonKey(name: 'bar_code') final  String? barCode;
/// Their government and area ids, resolved from the order's own city and region. Kept
/// because a parcel that went to the wrong place is diagnosed by comparing these two
/// against the city that was picked.
@override final  String? government;
@override final  String? area;
/// The COD we asked them to collect.
@override@JsonKey(name: 'amount_to_collect') final  String? amountToCollect;
/// Our delivery fee, taken off the COD before dispatch and frozen here. The customer pays it
/// to the courier, so it never reaches our drawer.
@override@JsonKey(name: 'delivery_price_deducted') final  String? deliveryPriceDeducted;
/// What they actually collected — null until a delivery is reported.
@override@JsonKey(name: 'collected_amount') final  String? collectedAmount;
/// Their integer and their prose. The status mapping is written against the first; the
/// second is what support reads, and it is never interpreted.
@override@JsonKey(name: 'remote_status_code') final  int? remoteStatusCode;
@override@JsonKey(name: 'remote_status_text') final  String? remoteStatusText;
@override@JsonKey(name: 'is_open') final  bool isOpen;
@override@JsonKey(name: 'has_open_conflict') final  bool hasOpenConflict;
@override@JsonKey(name: 'dispatched_at') final  DateTime? dispatchedAt;
@override@JsonKey(name: 'closed_at') final  DateTime? closedAt;

/// Create a copy of NawrisParcel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NawrisParcelCopyWith<_NawrisParcel> get copyWith => __$NawrisParcelCopyWithImpl<_NawrisParcel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NawrisParcelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NawrisParcel&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.barCode, barCode) || other.barCode == barCode)&&(identical(other.government, government) || other.government == government)&&(identical(other.area, area) || other.area == area)&&(identical(other.amountToCollect, amountToCollect) || other.amountToCollect == amountToCollect)&&(identical(other.deliveryPriceDeducted, deliveryPriceDeducted) || other.deliveryPriceDeducted == deliveryPriceDeducted)&&(identical(other.collectedAmount, collectedAmount) || other.collectedAmount == collectedAmount)&&(identical(other.remoteStatusCode, remoteStatusCode) || other.remoteStatusCode == remoteStatusCode)&&(identical(other.remoteStatusText, remoteStatusText) || other.remoteStatusText == remoteStatusText)&&(identical(other.isOpen, isOpen) || other.isOpen == isOpen)&&(identical(other.hasOpenConflict, hasOpenConflict) || other.hasOpenConflict == hasOpenConflict)&&(identical(other.dispatchedAt, dispatchedAt) || other.dispatchedAt == dispatchedAt)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,reference,barCode,government,area,amountToCollect,deliveryPriceDeducted,collectedAmount,remoteStatusCode,remoteStatusText,isOpen,hasOpenConflict,dispatchedAt,closedAt);

@override
String toString() {
  return 'NawrisParcel(id: $id, code: $code, reference: $reference, barCode: $barCode, government: $government, area: $area, amountToCollect: $amountToCollect, deliveryPriceDeducted: $deliveryPriceDeducted, collectedAmount: $collectedAmount, remoteStatusCode: $remoteStatusCode, remoteStatusText: $remoteStatusText, isOpen: $isOpen, hasOpenConflict: $hasOpenConflict, dispatchedAt: $dispatchedAt, closedAt: $closedAt)';
}


}

/// @nodoc
abstract mixin class _$NawrisParcelCopyWith<$Res> implements $NawrisParcelCopyWith<$Res> {
  factory _$NawrisParcelCopyWith(_NawrisParcel value, $Res Function(_NawrisParcel) _then) = __$NawrisParcelCopyWithImpl;
@override @useResult
$Res call({
 int id, String code, String? reference,@JsonKey(name: 'bar_code') String? barCode, String? government, String? area,@JsonKey(name: 'amount_to_collect') String? amountToCollect,@JsonKey(name: 'delivery_price_deducted') String? deliveryPriceDeducted,@JsonKey(name: 'collected_amount') String? collectedAmount,@JsonKey(name: 'remote_status_code') int? remoteStatusCode,@JsonKey(name: 'remote_status_text') String? remoteStatusText,@JsonKey(name: 'is_open') bool isOpen,@JsonKey(name: 'has_open_conflict') bool hasOpenConflict,@JsonKey(name: 'dispatched_at') DateTime? dispatchedAt,@JsonKey(name: 'closed_at') DateTime? closedAt
});




}
/// @nodoc
class __$NawrisParcelCopyWithImpl<$Res>
    implements _$NawrisParcelCopyWith<$Res> {
  __$NawrisParcelCopyWithImpl(this._self, this._then);

  final _NawrisParcel _self;
  final $Res Function(_NawrisParcel) _then;

/// Create a copy of NawrisParcel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? reference = freezed,Object? barCode = freezed,Object? government = freezed,Object? area = freezed,Object? amountToCollect = freezed,Object? deliveryPriceDeducted = freezed,Object? collectedAmount = freezed,Object? remoteStatusCode = freezed,Object? remoteStatusText = freezed,Object? isOpen = null,Object? hasOpenConflict = null,Object? dispatchedAt = freezed,Object? closedAt = freezed,}) {
  return _then(_NawrisParcel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,barCode: freezed == barCode ? _self.barCode : barCode // ignore: cast_nullable_to_non_nullable
as String?,government: freezed == government ? _self.government : government // ignore: cast_nullable_to_non_nullable
as String?,area: freezed == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as String?,amountToCollect: freezed == amountToCollect ? _self.amountToCollect : amountToCollect // ignore: cast_nullable_to_non_nullable
as String?,deliveryPriceDeducted: freezed == deliveryPriceDeducted ? _self.deliveryPriceDeducted : deliveryPriceDeducted // ignore: cast_nullable_to_non_nullable
as String?,collectedAmount: freezed == collectedAmount ? _self.collectedAmount : collectedAmount // ignore: cast_nullable_to_non_nullable
as String?,remoteStatusCode: freezed == remoteStatusCode ? _self.remoteStatusCode : remoteStatusCode // ignore: cast_nullable_to_non_nullable
as int?,remoteStatusText: freezed == remoteStatusText ? _self.remoteStatusText : remoteStatusText // ignore: cast_nullable_to_non_nullable
as String?,isOpen: null == isOpen ? _self.isOpen : isOpen // ignore: cast_nullable_to_non_nullable
as bool,hasOpenConflict: null == hasOpenConflict ? _self.hasOpenConflict : hasOpenConflict // ignore: cast_nullable_to_non_nullable
as bool,dispatchedAt: freezed == dispatchedAt ? _self.dispatchedAt : dispatchedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
