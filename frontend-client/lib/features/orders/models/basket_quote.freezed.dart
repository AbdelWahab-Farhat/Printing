// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'basket_quote.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BasketQuote {

/// بترتيب السلة نفسه.
 List<BasketLineQuote> get lines;/// مجموع البضاعة.
@JsonKey(name: 'items_total') String? get itemsTotal;/// رسم المندوب إلى المدينة المختارة، يُدفع له عند الاستلام. `"0.00"` للاستلام من المكتب.
@JsonKey(name: 'delivery_price') String? get deliveryPrice;/// البضاعة مع التوصيل: ما يدفعه العميل في النهاية.
@JsonKey(name: 'total_with_delivery') String? get totalWithDelivery;
/// Create a copy of BasketQuote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BasketQuoteCopyWith<BasketQuote> get copyWith => _$BasketQuoteCopyWithImpl<BasketQuote>(this as BasketQuote, _$identity);

  /// Serializes this BasketQuote to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BasketQuote&&const DeepCollectionEquality().equals(other.lines, lines)&&(identical(other.itemsTotal, itemsTotal) || other.itemsTotal == itemsTotal)&&(identical(other.deliveryPrice, deliveryPrice) || other.deliveryPrice == deliveryPrice)&&(identical(other.totalWithDelivery, totalWithDelivery) || other.totalWithDelivery == totalWithDelivery));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(lines),itemsTotal,deliveryPrice,totalWithDelivery);

@override
String toString() {
  return 'BasketQuote(lines: $lines, itemsTotal: $itemsTotal, deliveryPrice: $deliveryPrice, totalWithDelivery: $totalWithDelivery)';
}


}

/// @nodoc
abstract mixin class $BasketQuoteCopyWith<$Res>  {
  factory $BasketQuoteCopyWith(BasketQuote value, $Res Function(BasketQuote) _then) = _$BasketQuoteCopyWithImpl;
@useResult
$Res call({
 List<BasketLineQuote> lines,@JsonKey(name: 'items_total') String? itemsTotal,@JsonKey(name: 'delivery_price') String? deliveryPrice,@JsonKey(name: 'total_with_delivery') String? totalWithDelivery
});




}
/// @nodoc
class _$BasketQuoteCopyWithImpl<$Res>
    implements $BasketQuoteCopyWith<$Res> {
  _$BasketQuoteCopyWithImpl(this._self, this._then);

  final BasketQuote _self;
  final $Res Function(BasketQuote) _then;

/// Create a copy of BasketQuote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lines = null,Object? itemsTotal = freezed,Object? deliveryPrice = freezed,Object? totalWithDelivery = freezed,}) {
  return _then(_self.copyWith(
lines: null == lines ? _self.lines : lines // ignore: cast_nullable_to_non_nullable
as List<BasketLineQuote>,itemsTotal: freezed == itemsTotal ? _self.itemsTotal : itemsTotal // ignore: cast_nullable_to_non_nullable
as String?,deliveryPrice: freezed == deliveryPrice ? _self.deliveryPrice : deliveryPrice // ignore: cast_nullable_to_non_nullable
as String?,totalWithDelivery: freezed == totalWithDelivery ? _self.totalWithDelivery : totalWithDelivery // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BasketQuote].
extension BasketQuotePatterns on BasketQuote {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BasketQuote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BasketQuote() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BasketQuote value)  $default,){
final _that = this;
switch (_that) {
case _BasketQuote():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BasketQuote value)?  $default,){
final _that = this;
switch (_that) {
case _BasketQuote() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<BasketLineQuote> lines, @JsonKey(name: 'items_total')  String? itemsTotal, @JsonKey(name: 'delivery_price')  String? deliveryPrice, @JsonKey(name: 'total_with_delivery')  String? totalWithDelivery)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BasketQuote() when $default != null:
return $default(_that.lines,_that.itemsTotal,_that.deliveryPrice,_that.totalWithDelivery);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<BasketLineQuote> lines, @JsonKey(name: 'items_total')  String? itemsTotal, @JsonKey(name: 'delivery_price')  String? deliveryPrice, @JsonKey(name: 'total_with_delivery')  String? totalWithDelivery)  $default,) {final _that = this;
switch (_that) {
case _BasketQuote():
return $default(_that.lines,_that.itemsTotal,_that.deliveryPrice,_that.totalWithDelivery);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<BasketLineQuote> lines, @JsonKey(name: 'items_total')  String? itemsTotal, @JsonKey(name: 'delivery_price')  String? deliveryPrice, @JsonKey(name: 'total_with_delivery')  String? totalWithDelivery)?  $default,) {final _that = this;
switch (_that) {
case _BasketQuote() when $default != null:
return $default(_that.lines,_that.itemsTotal,_that.deliveryPrice,_that.totalWithDelivery);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BasketQuote implements BasketQuote {
  const _BasketQuote({final  List<BasketLineQuote> lines = const <BasketLineQuote>[], @JsonKey(name: 'items_total') this.itemsTotal, @JsonKey(name: 'delivery_price') this.deliveryPrice, @JsonKey(name: 'total_with_delivery') this.totalWithDelivery}): _lines = lines;
  factory _BasketQuote.fromJson(Map<String, dynamic> json) => _$BasketQuoteFromJson(json);

/// بترتيب السلة نفسه.
 final  List<BasketLineQuote> _lines;
/// بترتيب السلة نفسه.
@override@JsonKey() List<BasketLineQuote> get lines {
  if (_lines is EqualUnmodifiableListView) return _lines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lines);
}

/// مجموع البضاعة.
@override@JsonKey(name: 'items_total') final  String? itemsTotal;
/// رسم المندوب إلى المدينة المختارة، يُدفع له عند الاستلام. `"0.00"` للاستلام من المكتب.
@override@JsonKey(name: 'delivery_price') final  String? deliveryPrice;
/// البضاعة مع التوصيل: ما يدفعه العميل في النهاية.
@override@JsonKey(name: 'total_with_delivery') final  String? totalWithDelivery;

/// Create a copy of BasketQuote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BasketQuoteCopyWith<_BasketQuote> get copyWith => __$BasketQuoteCopyWithImpl<_BasketQuote>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BasketQuoteToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BasketQuote&&const DeepCollectionEquality().equals(other._lines, _lines)&&(identical(other.itemsTotal, itemsTotal) || other.itemsTotal == itemsTotal)&&(identical(other.deliveryPrice, deliveryPrice) || other.deliveryPrice == deliveryPrice)&&(identical(other.totalWithDelivery, totalWithDelivery) || other.totalWithDelivery == totalWithDelivery));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_lines),itemsTotal,deliveryPrice,totalWithDelivery);

@override
String toString() {
  return 'BasketQuote(lines: $lines, itemsTotal: $itemsTotal, deliveryPrice: $deliveryPrice, totalWithDelivery: $totalWithDelivery)';
}


}

/// @nodoc
abstract mixin class _$BasketQuoteCopyWith<$Res> implements $BasketQuoteCopyWith<$Res> {
  factory _$BasketQuoteCopyWith(_BasketQuote value, $Res Function(_BasketQuote) _then) = __$BasketQuoteCopyWithImpl;
@override @useResult
$Res call({
 List<BasketLineQuote> lines,@JsonKey(name: 'items_total') String? itemsTotal,@JsonKey(name: 'delivery_price') String? deliveryPrice,@JsonKey(name: 'total_with_delivery') String? totalWithDelivery
});




}
/// @nodoc
class __$BasketQuoteCopyWithImpl<$Res>
    implements _$BasketQuoteCopyWith<$Res> {
  __$BasketQuoteCopyWithImpl(this._self, this._then);

  final _BasketQuote _self;
  final $Res Function(_BasketQuote) _then;

/// Create a copy of BasketQuote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lines = null,Object? itemsTotal = freezed,Object? deliveryPrice = freezed,Object? totalWithDelivery = freezed,}) {
  return _then(_BasketQuote(
lines: null == lines ? _self._lines : lines // ignore: cast_nullable_to_non_nullable
as List<BasketLineQuote>,itemsTotal: freezed == itemsTotal ? _self.itemsTotal : itemsTotal // ignore: cast_nullable_to_non_nullable
as String?,deliveryPrice: freezed == deliveryPrice ? _self.deliveryPrice : deliveryPrice // ignore: cast_nullable_to_non_nullable
as String?,totalWithDelivery: freezed == totalWithDelivery ? _self.totalWithDelivery : totalWithDelivery // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$BasketLineQuote {

@JsonKey(name: 'product_id') int get productId;@JsonKey(name: 'product_variant_id') int get productVariantId;/// «قطعة» أو «كجم» — بأيّهما تُحسب الكمية.
@JsonKey(name: 'unit_label') String? get unitLabel;@JsonKey(name: 'unit_price') String? get unitPrice;/// `null` لمنتجٍ «حسب الطلب»: يُسعّره المتجر حين يقبل الطلبية.
@JsonKey(name: 'line_total') String? get lineTotal;
/// Create a copy of BasketLineQuote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BasketLineQuoteCopyWith<BasketLineQuote> get copyWith => _$BasketLineQuoteCopyWithImpl<BasketLineQuote>(this as BasketLineQuote, _$identity);

  /// Serializes this BasketLineQuote to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BasketLineQuote&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productVariantId, productVariantId) || other.productVariantId == productVariantId)&&(identical(other.unitLabel, unitLabel) || other.unitLabel == unitLabel)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.lineTotal, lineTotal) || other.lineTotal == lineTotal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productId,productVariantId,unitLabel,unitPrice,lineTotal);

@override
String toString() {
  return 'BasketLineQuote(productId: $productId, productVariantId: $productVariantId, unitLabel: $unitLabel, unitPrice: $unitPrice, lineTotal: $lineTotal)';
}


}

/// @nodoc
abstract mixin class $BasketLineQuoteCopyWith<$Res>  {
  factory $BasketLineQuoteCopyWith(BasketLineQuote value, $Res Function(BasketLineQuote) _then) = _$BasketLineQuoteCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'product_id') int productId,@JsonKey(name: 'product_variant_id') int productVariantId,@JsonKey(name: 'unit_label') String? unitLabel,@JsonKey(name: 'unit_price') String? unitPrice,@JsonKey(name: 'line_total') String? lineTotal
});




}
/// @nodoc
class _$BasketLineQuoteCopyWithImpl<$Res>
    implements $BasketLineQuoteCopyWith<$Res> {
  _$BasketLineQuoteCopyWithImpl(this._self, this._then);

  final BasketLineQuote _self;
  final $Res Function(BasketLineQuote) _then;

/// Create a copy of BasketLineQuote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productId = null,Object? productVariantId = null,Object? unitLabel = freezed,Object? unitPrice = freezed,Object? lineTotal = freezed,}) {
  return _then(_self.copyWith(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as int,productVariantId: null == productVariantId ? _self.productVariantId : productVariantId // ignore: cast_nullable_to_non_nullable
as int,unitLabel: freezed == unitLabel ? _self.unitLabel : unitLabel // ignore: cast_nullable_to_non_nullable
as String?,unitPrice: freezed == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String?,lineTotal: freezed == lineTotal ? _self.lineTotal : lineTotal // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BasketLineQuote].
extension BasketLineQuotePatterns on BasketLineQuote {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BasketLineQuote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BasketLineQuote() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BasketLineQuote value)  $default,){
final _that = this;
switch (_that) {
case _BasketLineQuote():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BasketLineQuote value)?  $default,){
final _that = this;
switch (_that) {
case _BasketLineQuote() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'product_id')  int productId, @JsonKey(name: 'product_variant_id')  int productVariantId, @JsonKey(name: 'unit_label')  String? unitLabel, @JsonKey(name: 'unit_price')  String? unitPrice, @JsonKey(name: 'line_total')  String? lineTotal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BasketLineQuote() when $default != null:
return $default(_that.productId,_that.productVariantId,_that.unitLabel,_that.unitPrice,_that.lineTotal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'product_id')  int productId, @JsonKey(name: 'product_variant_id')  int productVariantId, @JsonKey(name: 'unit_label')  String? unitLabel, @JsonKey(name: 'unit_price')  String? unitPrice, @JsonKey(name: 'line_total')  String? lineTotal)  $default,) {final _that = this;
switch (_that) {
case _BasketLineQuote():
return $default(_that.productId,_that.productVariantId,_that.unitLabel,_that.unitPrice,_that.lineTotal);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'product_id')  int productId, @JsonKey(name: 'product_variant_id')  int productVariantId, @JsonKey(name: 'unit_label')  String? unitLabel, @JsonKey(name: 'unit_price')  String? unitPrice, @JsonKey(name: 'line_total')  String? lineTotal)?  $default,) {final _that = this;
switch (_that) {
case _BasketLineQuote() when $default != null:
return $default(_that.productId,_that.productVariantId,_that.unitLabel,_that.unitPrice,_that.lineTotal);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BasketLineQuote implements BasketLineQuote {
  const _BasketLineQuote({@JsonKey(name: 'product_id') required this.productId, @JsonKey(name: 'product_variant_id') required this.productVariantId, @JsonKey(name: 'unit_label') this.unitLabel, @JsonKey(name: 'unit_price') this.unitPrice, @JsonKey(name: 'line_total') this.lineTotal});
  factory _BasketLineQuote.fromJson(Map<String, dynamic> json) => _$BasketLineQuoteFromJson(json);

@override@JsonKey(name: 'product_id') final  int productId;
@override@JsonKey(name: 'product_variant_id') final  int productVariantId;
/// «قطعة» أو «كجم» — بأيّهما تُحسب الكمية.
@override@JsonKey(name: 'unit_label') final  String? unitLabel;
@override@JsonKey(name: 'unit_price') final  String? unitPrice;
/// `null` لمنتجٍ «حسب الطلب»: يُسعّره المتجر حين يقبل الطلبية.
@override@JsonKey(name: 'line_total') final  String? lineTotal;

/// Create a copy of BasketLineQuote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BasketLineQuoteCopyWith<_BasketLineQuote> get copyWith => __$BasketLineQuoteCopyWithImpl<_BasketLineQuote>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BasketLineQuoteToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BasketLineQuote&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productVariantId, productVariantId) || other.productVariantId == productVariantId)&&(identical(other.unitLabel, unitLabel) || other.unitLabel == unitLabel)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.lineTotal, lineTotal) || other.lineTotal == lineTotal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productId,productVariantId,unitLabel,unitPrice,lineTotal);

@override
String toString() {
  return 'BasketLineQuote(productId: $productId, productVariantId: $productVariantId, unitLabel: $unitLabel, unitPrice: $unitPrice, lineTotal: $lineTotal)';
}


}

/// @nodoc
abstract mixin class _$BasketLineQuoteCopyWith<$Res> implements $BasketLineQuoteCopyWith<$Res> {
  factory _$BasketLineQuoteCopyWith(_BasketLineQuote value, $Res Function(_BasketLineQuote) _then) = __$BasketLineQuoteCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'product_id') int productId,@JsonKey(name: 'product_variant_id') int productVariantId,@JsonKey(name: 'unit_label') String? unitLabel,@JsonKey(name: 'unit_price') String? unitPrice,@JsonKey(name: 'line_total') String? lineTotal
});




}
/// @nodoc
class __$BasketLineQuoteCopyWithImpl<$Res>
    implements _$BasketLineQuoteCopyWith<$Res> {
  __$BasketLineQuoteCopyWithImpl(this._self, this._then);

  final _BasketLineQuote _self;
  final $Res Function(_BasketLineQuote) _then;

/// Create a copy of BasketLineQuote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productId = null,Object? productVariantId = null,Object? unitLabel = freezed,Object? unitPrice = freezed,Object? lineTotal = freezed,}) {
  return _then(_BasketLineQuote(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as int,productVariantId: null == productVariantId ? _self.productVariantId : productVariantId // ignore: cast_nullable_to_non_nullable
as int,unitLabel: freezed == unitLabel ? _self.unitLabel : unitLabel // ignore: cast_nullable_to_non_nullable
as String?,unitPrice: freezed == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String?,lineTotal: freezed == lineTotal ? _self.lineTotal : lineTotal // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
