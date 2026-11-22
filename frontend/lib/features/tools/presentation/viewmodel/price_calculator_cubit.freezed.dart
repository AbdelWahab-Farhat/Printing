// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'price_calculator_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PriceCalculatorState {

 List<CalculatorLine> get lines;
/// Create a copy of PriceCalculatorState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PriceCalculatorStateCopyWith<PriceCalculatorState> get copyWith => _$PriceCalculatorStateCopyWithImpl<PriceCalculatorState>(this as PriceCalculatorState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PriceCalculatorState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PriceCalculatorState&&const DeepCollectionEquality().equals(other.lines, _this.lines));
}


@override
int get hashCode {
  final _this = this as PriceCalculatorState;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.lines));
}

@override
String toString() {
  final _this = this as PriceCalculatorState;
  return 'PriceCalculatorState(lines: ${_this.lines})';
}


}

/// @nodoc
abstract mixin class $PriceCalculatorStateCopyWith<$Res>  {
  factory $PriceCalculatorStateCopyWith(PriceCalculatorState value, $Res Function(PriceCalculatorState) _then) = _$PriceCalculatorStateCopyWithImpl;
@useResult
$Res call({
 List<CalculatorLine> lines
});




}
/// @nodoc
class _$PriceCalculatorStateCopyWithImpl<$Res>
    implements $PriceCalculatorStateCopyWith<$Res> {
  _$PriceCalculatorStateCopyWithImpl(this._self, this._then);

  final PriceCalculatorState _self;
  final $Res Function(PriceCalculatorState) _then;

/// Create a copy of PriceCalculatorState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lines = null,}) {
  return _then(PriceCalculatorState(
lines: null == lines ? _self.lines : lines // ignore: cast_nullable_to_non_nullable
as List<CalculatorLine>,
  ));
}

}


/// Adds pattern-matching-related methods to [PriceCalculatorState].
extension PriceCalculatorStatePatterns on PriceCalculatorState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PriceCalculatorState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PriceCalculatorState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PriceCalculatorState value)  $default,){
final _that = this;
switch (_that) {
case _PriceCalculatorState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PriceCalculatorState value)?  $default,){
final _that = this;
switch (_that) {
case _PriceCalculatorState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CalculatorLine> lines)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PriceCalculatorState() when $default != null:
return $default(_that.lines);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CalculatorLine> lines)  $default,) {final _that = this;
switch (_that) {
case _PriceCalculatorState():
return $default(_that.lines);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CalculatorLine> lines)?  $default,) {final _that = this;
switch (_that) {
case _PriceCalculatorState() when $default != null:
return $default(_that.lines);case _:
  return null;

}
}

}

/// @nodoc


class _PriceCalculatorState extends PriceCalculatorState {
  const _PriceCalculatorState({ List<CalculatorLine> lines = const <CalculatorLine>[]}): _lines = lines,super._();
  

 final  List<CalculatorLine> _lines;
@override@JsonKey() List<CalculatorLine> get lines {
  if (_lines is EqualUnmodifiableListView) return _lines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lines);
}


/// Create a copy of PriceCalculatorState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PriceCalculatorStateCopyWith<_PriceCalculatorState> get copyWith => __$PriceCalculatorStateCopyWithImpl<_PriceCalculatorState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PriceCalculatorState&&const DeepCollectionEquality().equals(other.lines, _lines));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_lines));
}

@override
String toString() {
    return 'PriceCalculatorState(lines: $lines)';
}


}

/// @nodoc
abstract mixin class _$PriceCalculatorStateCopyWith<$Res> implements $PriceCalculatorStateCopyWith<$Res> {
  factory _$PriceCalculatorStateCopyWith(_PriceCalculatorState value, $Res Function(_PriceCalculatorState) _then) = __$PriceCalculatorStateCopyWithImpl;
@override @useResult
$Res call({
 List<CalculatorLine> lines
});




}
/// @nodoc
class __$PriceCalculatorStateCopyWithImpl<$Res>
    implements _$PriceCalculatorStateCopyWith<$Res> {
  __$PriceCalculatorStateCopyWithImpl(this._self, this._then);

  final _PriceCalculatorState _self;
  final $Res Function(_PriceCalculatorState) _then;

/// Create a copy of PriceCalculatorState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lines = null,}) {
  return _then(_PriceCalculatorState(
lines: null == lines ? _self._lines : lines // ignore: cast_nullable_to_non_nullable
as List<CalculatorLine>,
  ));
}


}

/// @nodoc
mixin _$CalculatorLine {

/// The calculator's own handle on the line. Not the variant id: the size of a line can be
/// changed in place, and the line must stay the same line while it is.
 int get key; Product get product; ProductVariant get variant;/// As typed, digits and all — Arabic-Indic included. [GetPriceQuote] normalises on the way
/// out, and the box keeps showing what the clerk typed.
 String get quantity; LineQuoteState get quote;/// The clerk's price for one unit, as typed — only on a line the catalogue does not price.
/// Optional: left empty, the line goes out as «السعر حسب الطلب».
 String get unitPrice;
/// Create a copy of CalculatorLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CalculatorLineCopyWith<CalculatorLine> get copyWith => _$CalculatorLineCopyWithImpl<CalculatorLine>(this as CalculatorLine, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CalculatorLine;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CalculatorLine&&(identical(other.key, _this.key) || other.key == _this.key)&&(identical(other.product, _this.product) || other.product == _this.product)&&(identical(other.variant, _this.variant) || other.variant == _this.variant)&&(identical(other.quantity, _this.quantity) || other.quantity == _this.quantity)&&(identical(other.quote, _this.quote) || other.quote == _this.quote)&&(identical(other.unitPrice, _this.unitPrice) || other.unitPrice == _this.unitPrice));
}


@override
int get hashCode {
  final _this = this as CalculatorLine;
  return Object.hash(runtimeType,_this.key,_this.product,_this.variant,_this.quantity,_this.quote,_this.unitPrice);
}

@override
String toString() {
  final _this = this as CalculatorLine;
  return 'CalculatorLine(key: ${_this.key}, product: ${_this.product}, variant: ${_this.variant}, quantity: ${_this.quantity}, quote: ${_this.quote}, unitPrice: ${_this.unitPrice})';
}


}

/// @nodoc
abstract mixin class $CalculatorLineCopyWith<$Res>  {
  factory $CalculatorLineCopyWith(CalculatorLine value, $Res Function(CalculatorLine) _then) = _$CalculatorLineCopyWithImpl;
@useResult
$Res call({
 int key, Product product, ProductVariant variant, String quantity, LineQuoteState quote, String unitPrice
});


$ProductCopyWith<$Res> get product;$ProductVariantCopyWith<$Res> get variant;$LineQuoteStateCopyWith<$Res> get quote;

}
/// @nodoc
class _$CalculatorLineCopyWithImpl<$Res>
    implements $CalculatorLineCopyWith<$Res> {
  _$CalculatorLineCopyWithImpl(this._self, this._then);

  final CalculatorLine _self;
  final $Res Function(CalculatorLine) _then;

/// Create a copy of CalculatorLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? product = null,Object? variant = null,Object? quantity = null,Object? quote = null,Object? unitPrice = null,}) {
  return _then(CalculatorLine(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as int,product: null == product ? _self.product : product // ignore: cast_nullable_to_non_nullable
as Product,variant: null == variant ? _self.variant : variant // ignore: cast_nullable_to_non_nullable
as ProductVariant,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,quote: null == quote ? _self.quote : quote // ignore: cast_nullable_to_non_nullable
as LineQuoteState,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of CalculatorLine
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProductCopyWith<$Res> get product {
  
  return $ProductCopyWith<$Res>(_self.product, (value) {
    return _then(_self.copyWith(product: value));
  });
}/// Create a copy of CalculatorLine
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProductVariantCopyWith<$Res> get variant {
  
  return $ProductVariantCopyWith<$Res>(_self.variant, (value) {
    return _then(_self.copyWith(variant: value));
  });
}/// Create a copy of CalculatorLine
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LineQuoteStateCopyWith<$Res> get quote {
  
  return $LineQuoteStateCopyWith<$Res>(_self.quote, (value) {
    return _then(_self.copyWith(quote: value));
  });
}
}


/// Adds pattern-matching-related methods to [CalculatorLine].
extension CalculatorLinePatterns on CalculatorLine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CalculatorLine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CalculatorLine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CalculatorLine value)  $default,){
final _that = this;
switch (_that) {
case _CalculatorLine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CalculatorLine value)?  $default,){
final _that = this;
switch (_that) {
case _CalculatorLine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int key,  Product product,  ProductVariant variant,  String quantity,  LineQuoteState quote,  String unitPrice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CalculatorLine() when $default != null:
return $default(_that.key,_that.product,_that.variant,_that.quantity,_that.quote,_that.unitPrice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int key,  Product product,  ProductVariant variant,  String quantity,  LineQuoteState quote,  String unitPrice)  $default,) {final _that = this;
switch (_that) {
case _CalculatorLine():
return $default(_that.key,_that.product,_that.variant,_that.quantity,_that.quote,_that.unitPrice);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int key,  Product product,  ProductVariant variant,  String quantity,  LineQuoteState quote,  String unitPrice)?  $default,) {final _that = this;
switch (_that) {
case _CalculatorLine() when $default != null:
return $default(_that.key,_that.product,_that.variant,_that.quantity,_that.quote,_that.unitPrice);case _:
  return null;

}
}

}

/// @nodoc


class _CalculatorLine extends CalculatorLine {
  const _CalculatorLine({required this.key, required this.product, required this.variant, this.quantity = '', this.quote = const LineQuoteState.idle(), this.unitPrice = ''}): super._();
  

/// The calculator's own handle on the line. Not the variant id: the size of a line can be
/// changed in place, and the line must stay the same line while it is.
@override final  int key;
@override final  Product product;
@override final  ProductVariant variant;
/// As typed, digits and all — Arabic-Indic included. [GetPriceQuote] normalises on the way
/// out, and the box keeps showing what the clerk typed.
@override@JsonKey() final  String quantity;
@override@JsonKey() final  LineQuoteState quote;
/// The clerk's price for one unit, as typed — only on a line the catalogue does not price.
/// Optional: left empty, the line goes out as «السعر حسب الطلب».
@override@JsonKey() final  String unitPrice;

/// Create a copy of CalculatorLine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CalculatorLineCopyWith<_CalculatorLine> get copyWith => __$CalculatorLineCopyWithImpl<_CalculatorLine>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CalculatorLine&&(identical(other.key, key) || other.key == key)&&(identical(other.product, product) || other.product == product)&&(identical(other.variant, variant) || other.variant == variant)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.quote, quote) || other.quote == quote)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice));
}


@override
int get hashCode {
    return Object.hash(runtimeType,key,product,variant,quantity,quote,unitPrice);
}

@override
String toString() {
    return 'CalculatorLine(key: $key, product: $product, variant: $variant, quantity: $quantity, quote: $quote, unitPrice: $unitPrice)';
}


}

/// @nodoc
abstract mixin class _$CalculatorLineCopyWith<$Res> implements $CalculatorLineCopyWith<$Res> {
  factory _$CalculatorLineCopyWith(_CalculatorLine value, $Res Function(_CalculatorLine) _then) = __$CalculatorLineCopyWithImpl;
@override @useResult
$Res call({
 int key, Product product, ProductVariant variant, String quantity, LineQuoteState quote, String unitPrice
});


@override $ProductCopyWith<$Res> get product;@override $ProductVariantCopyWith<$Res> get variant;@override $LineQuoteStateCopyWith<$Res> get quote;

}
/// @nodoc
class __$CalculatorLineCopyWithImpl<$Res>
    implements _$CalculatorLineCopyWith<$Res> {
  __$CalculatorLineCopyWithImpl(this._self, this._then);

  final _CalculatorLine _self;
  final $Res Function(_CalculatorLine) _then;

/// Create a copy of CalculatorLine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? product = null,Object? variant = null,Object? quantity = null,Object? quote = null,Object? unitPrice = null,}) {
  return _then(_CalculatorLine(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as int,product: null == product ? _self.product : product // ignore: cast_nullable_to_non_nullable
as Product,variant: null == variant ? _self.variant : variant // ignore: cast_nullable_to_non_nullable
as ProductVariant,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,quote: null == quote ? _self.quote : quote // ignore: cast_nullable_to_non_nullable
as LineQuoteState,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of CalculatorLine
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProductCopyWith<$Res> get product {
  
  return $ProductCopyWith<$Res>(_self.product, (value) {
    return _then(_self.copyWith(product: value));
  });
}/// Create a copy of CalculatorLine
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProductVariantCopyWith<$Res> get variant {
  
  return $ProductVariantCopyWith<$Res>(_self.variant, (value) {
    return _then(_self.copyWith(variant: value));
  });
}/// Create a copy of CalculatorLine
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LineQuoteStateCopyWith<$Res> get quote {
  
  return $LineQuoteStateCopyWith<$Res>(_self.quote, (value) {
    return _then(_self.copyWith(quote: value));
  });
}
}

// dart format on
