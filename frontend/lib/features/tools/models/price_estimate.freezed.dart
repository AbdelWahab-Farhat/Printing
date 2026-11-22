// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'price_estimate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$EstimateEntry {

 String get productName; String get sizeLabel;/// What was typed, already in western digits. Shown only for a line with no [quote] —
/// a priced line shows the server's normalised quantity instead.
 String get quantity; String get unitLabel; PriceQuote? get quote;/// The price of one unit as the clerk typed it, in western digits — only ever set on a line
/// with no [quote], and only once it reads as money ([parseHandPrice]).
 String? get handUnitPrice;
/// Create a copy of EstimateEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EstimateEntryCopyWith<EstimateEntry> get copyWith => _$EstimateEntryCopyWithImpl<EstimateEntry>(this as EstimateEntry, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as EstimateEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EstimateEntry&&(identical(other.productName, _this.productName) || other.productName == _this.productName)&&(identical(other.sizeLabel, _this.sizeLabel) || other.sizeLabel == _this.sizeLabel)&&(identical(other.quantity, _this.quantity) || other.quantity == _this.quantity)&&(identical(other.unitLabel, _this.unitLabel) || other.unitLabel == _this.unitLabel)&&(identical(other.quote, _this.quote) || other.quote == _this.quote)&&(identical(other.handUnitPrice, _this.handUnitPrice) || other.handUnitPrice == _this.handUnitPrice));
}


@override
int get hashCode {
  final _this = this as EstimateEntry;
  return Object.hash(runtimeType,_this.productName,_this.sizeLabel,_this.quantity,_this.unitLabel,_this.quote,_this.handUnitPrice);
}

@override
String toString() {
  final _this = this as EstimateEntry;
  return 'EstimateEntry(productName: ${_this.productName}, sizeLabel: ${_this.sizeLabel}, quantity: ${_this.quantity}, unitLabel: ${_this.unitLabel}, quote: ${_this.quote}, handUnitPrice: ${_this.handUnitPrice})';
}


}

/// @nodoc
abstract mixin class $EstimateEntryCopyWith<$Res>  {
  factory $EstimateEntryCopyWith(EstimateEntry value, $Res Function(EstimateEntry) _then) = _$EstimateEntryCopyWithImpl;
@useResult
$Res call({
 String productName, String sizeLabel, String quantity, String unitLabel, PriceQuote? quote, String? handUnitPrice
});


$PriceQuoteCopyWith<$Res>? get quote;

}
/// @nodoc
class _$EstimateEntryCopyWithImpl<$Res>
    implements $EstimateEntryCopyWith<$Res> {
  _$EstimateEntryCopyWithImpl(this._self, this._then);

  final EstimateEntry _self;
  final $Res Function(EstimateEntry) _then;

/// Create a copy of EstimateEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productName = null,Object? sizeLabel = null,Object? quantity = null,Object? unitLabel = null,Object? quote = freezed,Object? handUnitPrice = freezed,}) {
  return _then(EstimateEntry(
productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,sizeLabel: null == sizeLabel ? _self.sizeLabel : sizeLabel // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,unitLabel: null == unitLabel ? _self.unitLabel : unitLabel // ignore: cast_nullable_to_non_nullable
as String,quote: freezed == quote ? _self.quote : quote // ignore: cast_nullable_to_non_nullable
as PriceQuote?,handUnitPrice: freezed == handUnitPrice ? _self.handUnitPrice : handUnitPrice // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of EstimateEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PriceQuoteCopyWith<$Res>? get quote {
    if (_self.quote == null) {
    return null;
  }

  return $PriceQuoteCopyWith<$Res>(_self.quote!, (value) {
    return _then(_self.copyWith(quote: value));
  });
}
}


/// Adds pattern-matching-related methods to [EstimateEntry].
extension EstimateEntryPatterns on EstimateEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EstimateEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EstimateEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EstimateEntry value)  $default,){
final _that = this;
switch (_that) {
case _EstimateEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EstimateEntry value)?  $default,){
final _that = this;
switch (_that) {
case _EstimateEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String productName,  String sizeLabel,  String quantity,  String unitLabel,  PriceQuote? quote,  String? handUnitPrice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EstimateEntry() when $default != null:
return $default(_that.productName,_that.sizeLabel,_that.quantity,_that.unitLabel,_that.quote,_that.handUnitPrice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String productName,  String sizeLabel,  String quantity,  String unitLabel,  PriceQuote? quote,  String? handUnitPrice)  $default,) {final _that = this;
switch (_that) {
case _EstimateEntry():
return $default(_that.productName,_that.sizeLabel,_that.quantity,_that.unitLabel,_that.quote,_that.handUnitPrice);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String productName,  String sizeLabel,  String quantity,  String unitLabel,  PriceQuote? quote,  String? handUnitPrice)?  $default,) {final _that = this;
switch (_that) {
case _EstimateEntry() when $default != null:
return $default(_that.productName,_that.sizeLabel,_that.quantity,_that.unitLabel,_that.quote,_that.handUnitPrice);case _:
  return null;

}
}

}

/// @nodoc


class _EstimateEntry extends EstimateEntry {
  const _EstimateEntry({required this.productName, required this.sizeLabel, required this.quantity, required this.unitLabel, this.quote, this.handUnitPrice}): super._();
  

@override final  String productName;
@override final  String sizeLabel;
/// What was typed, already in western digits. Shown only for a line with no [quote] —
/// a priced line shows the server's normalised quantity instead.
@override final  String quantity;
@override final  String unitLabel;
@override final  PriceQuote? quote;
/// The price of one unit as the clerk typed it, in western digits — only ever set on a line
/// with no [quote], and only once it reads as money ([parseHandPrice]).
@override final  String? handUnitPrice;

/// Create a copy of EstimateEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EstimateEntryCopyWith<_EstimateEntry> get copyWith => __$EstimateEntryCopyWithImpl<_EstimateEntry>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EstimateEntry&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.sizeLabel, sizeLabel) || other.sizeLabel == sizeLabel)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitLabel, unitLabel) || other.unitLabel == unitLabel)&&(identical(other.quote, quote) || other.quote == quote)&&(identical(other.handUnitPrice, handUnitPrice) || other.handUnitPrice == handUnitPrice));
}


@override
int get hashCode {
    return Object.hash(runtimeType,productName,sizeLabel,quantity,unitLabel,quote,handUnitPrice);
}

@override
String toString() {
    return 'EstimateEntry(productName: $productName, sizeLabel: $sizeLabel, quantity: $quantity, unitLabel: $unitLabel, quote: $quote, handUnitPrice: $handUnitPrice)';
}


}

/// @nodoc
abstract mixin class _$EstimateEntryCopyWith<$Res> implements $EstimateEntryCopyWith<$Res> {
  factory _$EstimateEntryCopyWith(_EstimateEntry value, $Res Function(_EstimateEntry) _then) = __$EstimateEntryCopyWithImpl;
@override @useResult
$Res call({
 String productName, String sizeLabel, String quantity, String unitLabel, PriceQuote? quote, String? handUnitPrice
});


@override $PriceQuoteCopyWith<$Res>? get quote;

}
/// @nodoc
class __$EstimateEntryCopyWithImpl<$Res>
    implements _$EstimateEntryCopyWith<$Res> {
  __$EstimateEntryCopyWithImpl(this._self, this._then);

  final _EstimateEntry _self;
  final $Res Function(_EstimateEntry) _then;

/// Create a copy of EstimateEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productName = null,Object? sizeLabel = null,Object? quantity = null,Object? unitLabel = null,Object? quote = freezed,Object? handUnitPrice = freezed,}) {
  return _then(_EstimateEntry(
productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,sizeLabel: null == sizeLabel ? _self.sizeLabel : sizeLabel // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,unitLabel: null == unitLabel ? _self.unitLabel : unitLabel // ignore: cast_nullable_to_non_nullable
as String,quote: freezed == quote ? _self.quote : quote // ignore: cast_nullable_to_non_nullable
as PriceQuote?,handUnitPrice: freezed == handUnitPrice ? _self.handUnitPrice : handUnitPrice // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of EstimateEntry
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PriceQuoteCopyWith<$Res>? get quote {
    if (_self.quote == null) {
    return null;
  }

  return $PriceQuoteCopyWith<$Res>(_self.quote!, (value) {
    return _then(_self.copyWith(quote: value));
  });
}
}

// dart format on
