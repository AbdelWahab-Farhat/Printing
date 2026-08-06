// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'price_quote.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PriceQuote {

 String get quantity;/// `piece` or `kilogram`, and the Arabic word for it — sent by the server so the app keeps
/// no translation table.
 String get unit;@JsonKey(name: 'unit_label') String get unitLabel;@JsonKey(name: 'unit_price') String get unitPrice; String get total;/// Which quantity break produced this rate — «أنت على سعر ١٠٠ فأكثر».
@JsonKey(name: 'applied_tier_min_quantity') String get appliedTierMinQuantity;/// The saving still on the table. Null when this quantity is already on the best rate.
@JsonKey(name: 'next_tier') NextPriceTier? get nextTier;
/// Create a copy of PriceQuote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PriceQuoteCopyWith<PriceQuote> get copyWith => _$PriceQuoteCopyWithImpl<PriceQuote>(this as PriceQuote, _$identity);

  /// Serializes this PriceQuote to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PriceQuote&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.unitLabel, unitLabel) || other.unitLabel == unitLabel)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.total, total) || other.total == total)&&(identical(other.appliedTierMinQuantity, appliedTierMinQuantity) || other.appliedTierMinQuantity == appliedTierMinQuantity)&&(identical(other.nextTier, nextTier) || other.nextTier == nextTier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,quantity,unit,unitLabel,unitPrice,total,appliedTierMinQuantity,nextTier);

@override
String toString() {
  return 'PriceQuote(quantity: $quantity, unit: $unit, unitLabel: $unitLabel, unitPrice: $unitPrice, total: $total, appliedTierMinQuantity: $appliedTierMinQuantity, nextTier: $nextTier)';
}


}

/// @nodoc
abstract mixin class $PriceQuoteCopyWith<$Res>  {
  factory $PriceQuoteCopyWith(PriceQuote value, $Res Function(PriceQuote) _then) = _$PriceQuoteCopyWithImpl;
@useResult
$Res call({
 String quantity, String unit,@JsonKey(name: 'unit_label') String unitLabel,@JsonKey(name: 'unit_price') String unitPrice, String total,@JsonKey(name: 'applied_tier_min_quantity') String appliedTierMinQuantity,@JsonKey(name: 'next_tier') NextPriceTier? nextTier
});


$NextPriceTierCopyWith<$Res>? get nextTier;

}
/// @nodoc
class _$PriceQuoteCopyWithImpl<$Res>
    implements $PriceQuoteCopyWith<$Res> {
  _$PriceQuoteCopyWithImpl(this._self, this._then);

  final PriceQuote _self;
  final $Res Function(PriceQuote) _then;

/// Create a copy of PriceQuote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? quantity = null,Object? unit = null,Object? unitLabel = null,Object? unitPrice = null,Object? total = null,Object? appliedTierMinQuantity = null,Object? nextTier = freezed,}) {
  return _then(_self.copyWith(
quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,unitLabel: null == unitLabel ? _self.unitLabel : unitLabel // ignore: cast_nullable_to_non_nullable
as String,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,appliedTierMinQuantity: null == appliedTierMinQuantity ? _self.appliedTierMinQuantity : appliedTierMinQuantity // ignore: cast_nullable_to_non_nullable
as String,nextTier: freezed == nextTier ? _self.nextTier : nextTier // ignore: cast_nullable_to_non_nullable
as NextPriceTier?,
  ));
}
/// Create a copy of PriceQuote
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NextPriceTierCopyWith<$Res>? get nextTier {
    if (_self.nextTier == null) {
    return null;
  }

  return $NextPriceTierCopyWith<$Res>(_self.nextTier!, (value) {
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String quantity,  String unit, @JsonKey(name: 'unit_label')  String unitLabel, @JsonKey(name: 'unit_price')  String unitPrice,  String total, @JsonKey(name: 'applied_tier_min_quantity')  String appliedTierMinQuantity, @JsonKey(name: 'next_tier')  NextPriceTier? nextTier)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PriceQuote() when $default != null:
return $default(_that.quantity,_that.unit,_that.unitLabel,_that.unitPrice,_that.total,_that.appliedTierMinQuantity,_that.nextTier);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String quantity,  String unit, @JsonKey(name: 'unit_label')  String unitLabel, @JsonKey(name: 'unit_price')  String unitPrice,  String total, @JsonKey(name: 'applied_tier_min_quantity')  String appliedTierMinQuantity, @JsonKey(name: 'next_tier')  NextPriceTier? nextTier)  $default,) {final _that = this;
switch (_that) {
case _PriceQuote():
return $default(_that.quantity,_that.unit,_that.unitLabel,_that.unitPrice,_that.total,_that.appliedTierMinQuantity,_that.nextTier);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String quantity,  String unit, @JsonKey(name: 'unit_label')  String unitLabel, @JsonKey(name: 'unit_price')  String unitPrice,  String total, @JsonKey(name: 'applied_tier_min_quantity')  String appliedTierMinQuantity, @JsonKey(name: 'next_tier')  NextPriceTier? nextTier)?  $default,) {final _that = this;
switch (_that) {
case _PriceQuote() when $default != null:
return $default(_that.quantity,_that.unit,_that.unitLabel,_that.unitPrice,_that.total,_that.appliedTierMinQuantity,_that.nextTier);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PriceQuote extends PriceQuote {
  const _PriceQuote({required this.quantity, required this.unit, @JsonKey(name: 'unit_label') required this.unitLabel, @JsonKey(name: 'unit_price') required this.unitPrice, required this.total, @JsonKey(name: 'applied_tier_min_quantity') required this.appliedTierMinQuantity, @JsonKey(name: 'next_tier') this.nextTier}): super._();
  factory _PriceQuote.fromJson(Map<String, dynamic> json) => _$PriceQuoteFromJson(json);

@override final  String quantity;
/// `piece` or `kilogram`, and the Arabic word for it — sent by the server so the app keeps
/// no translation table.
@override final  String unit;
@override@JsonKey(name: 'unit_label') final  String unitLabel;
@override@JsonKey(name: 'unit_price') final  String unitPrice;
@override final  String total;
/// Which quantity break produced this rate — «أنت على سعر ١٠٠ فأكثر».
@override@JsonKey(name: 'applied_tier_min_quantity') final  String appliedTierMinQuantity;
/// The saving still on the table. Null when this quantity is already on the best rate.
@override@JsonKey(name: 'next_tier') final  NextPriceTier? nextTier;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PriceQuote&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.unitLabel, unitLabel) || other.unitLabel == unitLabel)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.total, total) || other.total == total)&&(identical(other.appliedTierMinQuantity, appliedTierMinQuantity) || other.appliedTierMinQuantity == appliedTierMinQuantity)&&(identical(other.nextTier, nextTier) || other.nextTier == nextTier));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,quantity,unit,unitLabel,unitPrice,total,appliedTierMinQuantity,nextTier);

@override
String toString() {
  return 'PriceQuote(quantity: $quantity, unit: $unit, unitLabel: $unitLabel, unitPrice: $unitPrice, total: $total, appliedTierMinQuantity: $appliedTierMinQuantity, nextTier: $nextTier)';
}


}

/// @nodoc
abstract mixin class _$PriceQuoteCopyWith<$Res> implements $PriceQuoteCopyWith<$Res> {
  factory _$PriceQuoteCopyWith(_PriceQuote value, $Res Function(_PriceQuote) _then) = __$PriceQuoteCopyWithImpl;
@override @useResult
$Res call({
 String quantity, String unit,@JsonKey(name: 'unit_label') String unitLabel,@JsonKey(name: 'unit_price') String unitPrice, String total,@JsonKey(name: 'applied_tier_min_quantity') String appliedTierMinQuantity,@JsonKey(name: 'next_tier') NextPriceTier? nextTier
});


@override $NextPriceTierCopyWith<$Res>? get nextTier;

}
/// @nodoc
class __$PriceQuoteCopyWithImpl<$Res>
    implements _$PriceQuoteCopyWith<$Res> {
  __$PriceQuoteCopyWithImpl(this._self, this._then);

  final _PriceQuote _self;
  final $Res Function(_PriceQuote) _then;

/// Create a copy of PriceQuote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? quantity = null,Object? unit = null,Object? unitLabel = null,Object? unitPrice = null,Object? total = null,Object? appliedTierMinQuantity = null,Object? nextTier = freezed,}) {
  return _then(_PriceQuote(
quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,unitLabel: null == unitLabel ? _self.unitLabel : unitLabel // ignore: cast_nullable_to_non_nullable
as String,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,appliedTierMinQuantity: null == appliedTierMinQuantity ? _self.appliedTierMinQuantity : appliedTierMinQuantity // ignore: cast_nullable_to_non_nullable
as String,nextTier: freezed == nextTier ? _self.nextTier : nextTier // ignore: cast_nullable_to_non_nullable
as NextPriceTier?,
  ));
}

/// Create a copy of PriceQuote
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NextPriceTierCopyWith<$Res>? get nextTier {
    if (_self.nextTier == null) {
    return null;
  }

  return $NextPriceTierCopyWith<$Res>(_self.nextTier!, (value) {
    return _then(_self.copyWith(nextTier: value));
  });
}
}


/// @nodoc
mixin _$NextPriceTier {

@JsonKey(name: 'min_quantity') String get minQuantity;@JsonKey(name: 'unit_price') String get unitPrice;@JsonKey(name: 'quantity_to_reach') String get quantityToReach;
/// Create a copy of NextPriceTier
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NextPriceTierCopyWith<NextPriceTier> get copyWith => _$NextPriceTierCopyWithImpl<NextPriceTier>(this as NextPriceTier, _$identity);

  /// Serializes this NextPriceTier to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NextPriceTier&&(identical(other.minQuantity, minQuantity) || other.minQuantity == minQuantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.quantityToReach, quantityToReach) || other.quantityToReach == quantityToReach));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,minQuantity,unitPrice,quantityToReach);

@override
String toString() {
  return 'NextPriceTier(minQuantity: $minQuantity, unitPrice: $unitPrice, quantityToReach: $quantityToReach)';
}


}

/// @nodoc
abstract mixin class $NextPriceTierCopyWith<$Res>  {
  factory $NextPriceTierCopyWith(NextPriceTier value, $Res Function(NextPriceTier) _then) = _$NextPriceTierCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'min_quantity') String minQuantity,@JsonKey(name: 'unit_price') String unitPrice,@JsonKey(name: 'quantity_to_reach') String quantityToReach
});




}
/// @nodoc
class _$NextPriceTierCopyWithImpl<$Res>
    implements $NextPriceTierCopyWith<$Res> {
  _$NextPriceTierCopyWithImpl(this._self, this._then);

  final NextPriceTier _self;
  final $Res Function(NextPriceTier) _then;

/// Create a copy of NextPriceTier
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? minQuantity = null,Object? unitPrice = null,Object? quantityToReach = null,}) {
  return _then(_self.copyWith(
minQuantity: null == minQuantity ? _self.minQuantity : minQuantity // ignore: cast_nullable_to_non_nullable
as String,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,quantityToReach: null == quantityToReach ? _self.quantityToReach : quantityToReach // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [NextPriceTier].
extension NextPriceTierPatterns on NextPriceTier {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NextPriceTier value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NextPriceTier() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NextPriceTier value)  $default,){
final _that = this;
switch (_that) {
case _NextPriceTier():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NextPriceTier value)?  $default,){
final _that = this;
switch (_that) {
case _NextPriceTier() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'min_quantity')  String minQuantity, @JsonKey(name: 'unit_price')  String unitPrice, @JsonKey(name: 'quantity_to_reach')  String quantityToReach)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NextPriceTier() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'min_quantity')  String minQuantity, @JsonKey(name: 'unit_price')  String unitPrice, @JsonKey(name: 'quantity_to_reach')  String quantityToReach)  $default,) {final _that = this;
switch (_that) {
case _NextPriceTier():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'min_quantity')  String minQuantity, @JsonKey(name: 'unit_price')  String unitPrice, @JsonKey(name: 'quantity_to_reach')  String quantityToReach)?  $default,) {final _that = this;
switch (_that) {
case _NextPriceTier() when $default != null:
return $default(_that.minQuantity,_that.unitPrice,_that.quantityToReach);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NextPriceTier extends NextPriceTier {
  const _NextPriceTier({@JsonKey(name: 'min_quantity') required this.minQuantity, @JsonKey(name: 'unit_price') required this.unitPrice, @JsonKey(name: 'quantity_to_reach') required this.quantityToReach}): super._();
  factory _NextPriceTier.fromJson(Map<String, dynamic> json) => _$NextPriceTierFromJson(json);

@override@JsonKey(name: 'min_quantity') final  String minQuantity;
@override@JsonKey(name: 'unit_price') final  String unitPrice;
@override@JsonKey(name: 'quantity_to_reach') final  String quantityToReach;

/// Create a copy of NextPriceTier
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NextPriceTierCopyWith<_NextPriceTier> get copyWith => __$NextPriceTierCopyWithImpl<_NextPriceTier>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NextPriceTierToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NextPriceTier&&(identical(other.minQuantity, minQuantity) || other.minQuantity == minQuantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.quantityToReach, quantityToReach) || other.quantityToReach == quantityToReach));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,minQuantity,unitPrice,quantityToReach);

@override
String toString() {
  return 'NextPriceTier(minQuantity: $minQuantity, unitPrice: $unitPrice, quantityToReach: $quantityToReach)';
}


}

/// @nodoc
abstract mixin class _$NextPriceTierCopyWith<$Res> implements $NextPriceTierCopyWith<$Res> {
  factory _$NextPriceTierCopyWith(_NextPriceTier value, $Res Function(_NextPriceTier) _then) = __$NextPriceTierCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'min_quantity') String minQuantity,@JsonKey(name: 'unit_price') String unitPrice,@JsonKey(name: 'quantity_to_reach') String quantityToReach
});




}
/// @nodoc
class __$NextPriceTierCopyWithImpl<$Res>
    implements _$NextPriceTierCopyWith<$Res> {
  __$NextPriceTierCopyWithImpl(this._self, this._then);

  final _NextPriceTier _self;
  final $Res Function(_NextPriceTier) _then;

/// Create a copy of NextPriceTier
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? minQuantity = null,Object? unitPrice = null,Object? quantityToReach = null,}) {
  return _then(_NextPriceTier(
minQuantity: null == minQuantity ? _self.minQuantity : minQuantity // ignore: cast_nullable_to_non_nullable
as String,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,quantityToReach: null == quantityToReach ? _self.quantityToReach : quantityToReach // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
