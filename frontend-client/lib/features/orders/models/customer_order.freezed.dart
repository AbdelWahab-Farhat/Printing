// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'customer_order.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CustomerOrder {

 int get id;/// «1228» — what the customer reads out when they ring.
 String get code;@JsonKey(unknownEnumValue: OrderStage.unknown) OrderStage get stage;/// **Always drawn instead of translating [stage] here.** The Arabic travels with the value,
/// so a stage added to the business appears correctly without an app release.
@JsonKey(name: 'stage_label') String get stageLabel;@JsonKey(name: 'is_open') bool get isOpen;/// The sentence the card draws under the line — «نراجع طلبيتك ونؤكّدها خلال ساعات العمل».
///
/// **Also the server's, and for the same reason as [stageLabel].** A `switch` over
/// [OrderStage] written here would be a second copy of a mapping the backend keeps in one
/// place, and a stage added to the business would arrive with no sentence. Null for the
/// stages that are over: nothing reassuring is owed about a delivered order.
@JsonKey(name: 'stage_hint') String? get stageHint;/// «كيس شحن فلاير ٣٠×٤٠ و٢ أخرى» — built by the server so the list draws without opening
/// every order to write a subtitle.
 String? get summary;@JsonKey(name: 'items_count') int? get itemsCount;/// A decimal string, like every amount in this app — **and null while the shop has not
/// priced every line**, which is what [isAwaitingQuote] says in one word. The card draws
/// «يُحدَّد بعد المراجعة» rather than a figure smaller than the real one.
 String? get total;@JsonKey(name: 'is_awaiting_quote') bool get isAwaitingQuote;@JsonKey(name: 'placed_at') DateTime? get placedAt;
/// Create a copy of CustomerOrder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerOrderCopyWith<CustomerOrder> get copyWith => _$CustomerOrderCopyWithImpl<CustomerOrder>(this as CustomerOrder, _$identity);

  /// Serializes this CustomerOrder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerOrder&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.stageLabel, stageLabel) || other.stageLabel == stageLabel)&&(identical(other.isOpen, isOpen) || other.isOpen == isOpen)&&(identical(other.stageHint, stageHint) || other.stageHint == stageHint)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.itemsCount, itemsCount) || other.itemsCount == itemsCount)&&(identical(other.total, total) || other.total == total)&&(identical(other.isAwaitingQuote, isAwaitingQuote) || other.isAwaitingQuote == isAwaitingQuote)&&(identical(other.placedAt, placedAt) || other.placedAt == placedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,stage,stageLabel,isOpen,stageHint,summary,itemsCount,total,isAwaitingQuote,placedAt);

@override
String toString() {
  return 'CustomerOrder(id: $id, code: $code, stage: $stage, stageLabel: $stageLabel, isOpen: $isOpen, stageHint: $stageHint, summary: $summary, itemsCount: $itemsCount, total: $total, isAwaitingQuote: $isAwaitingQuote, placedAt: $placedAt)';
}


}

/// @nodoc
abstract mixin class $CustomerOrderCopyWith<$Res>  {
  factory $CustomerOrderCopyWith(CustomerOrder value, $Res Function(CustomerOrder) _then) = _$CustomerOrderCopyWithImpl;
@useResult
$Res call({
 int id, String code,@JsonKey(unknownEnumValue: OrderStage.unknown) OrderStage stage,@JsonKey(name: 'stage_label') String stageLabel,@JsonKey(name: 'is_open') bool isOpen,@JsonKey(name: 'stage_hint') String? stageHint, String? summary,@JsonKey(name: 'items_count') int? itemsCount, String? total,@JsonKey(name: 'is_awaiting_quote') bool isAwaitingQuote,@JsonKey(name: 'placed_at') DateTime? placedAt
});




}
/// @nodoc
class _$CustomerOrderCopyWithImpl<$Res>
    implements $CustomerOrderCopyWith<$Res> {
  _$CustomerOrderCopyWithImpl(this._self, this._then);

  final CustomerOrder _self;
  final $Res Function(CustomerOrder) _then;

/// Create a copy of CustomerOrder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? stage = null,Object? stageLabel = null,Object? isOpen = null,Object? stageHint = freezed,Object? summary = freezed,Object? itemsCount = freezed,Object? total = freezed,Object? isAwaitingQuote = null,Object? placedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as OrderStage,stageLabel: null == stageLabel ? _self.stageLabel : stageLabel // ignore: cast_nullable_to_non_nullable
as String,isOpen: null == isOpen ? _self.isOpen : isOpen // ignore: cast_nullable_to_non_nullable
as bool,stageHint: freezed == stageHint ? _self.stageHint : stageHint // ignore: cast_nullable_to_non_nullable
as String?,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String?,itemsCount: freezed == itemsCount ? _self.itemsCount : itemsCount // ignore: cast_nullable_to_non_nullable
as int?,total: freezed == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String?,isAwaitingQuote: null == isAwaitingQuote ? _self.isAwaitingQuote : isAwaitingQuote // ignore: cast_nullable_to_non_nullable
as bool,placedAt: freezed == placedAt ? _self.placedAt : placedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [CustomerOrder].
extension CustomerOrderPatterns on CustomerOrder {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CustomerOrder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CustomerOrder() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CustomerOrder value)  $default,){
final _that = this;
switch (_that) {
case _CustomerOrder():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CustomerOrder value)?  $default,){
final _that = this;
switch (_that) {
case _CustomerOrder() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String code, @JsonKey(unknownEnumValue: OrderStage.unknown)  OrderStage stage, @JsonKey(name: 'stage_label')  String stageLabel, @JsonKey(name: 'is_open')  bool isOpen, @JsonKey(name: 'stage_hint')  String? stageHint,  String? summary, @JsonKey(name: 'items_count')  int? itemsCount,  String? total, @JsonKey(name: 'is_awaiting_quote')  bool isAwaitingQuote, @JsonKey(name: 'placed_at')  DateTime? placedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CustomerOrder() when $default != null:
return $default(_that.id,_that.code,_that.stage,_that.stageLabel,_that.isOpen,_that.stageHint,_that.summary,_that.itemsCount,_that.total,_that.isAwaitingQuote,_that.placedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String code, @JsonKey(unknownEnumValue: OrderStage.unknown)  OrderStage stage, @JsonKey(name: 'stage_label')  String stageLabel, @JsonKey(name: 'is_open')  bool isOpen, @JsonKey(name: 'stage_hint')  String? stageHint,  String? summary, @JsonKey(name: 'items_count')  int? itemsCount,  String? total, @JsonKey(name: 'is_awaiting_quote')  bool isAwaitingQuote, @JsonKey(name: 'placed_at')  DateTime? placedAt)  $default,) {final _that = this;
switch (_that) {
case _CustomerOrder():
return $default(_that.id,_that.code,_that.stage,_that.stageLabel,_that.isOpen,_that.stageHint,_that.summary,_that.itemsCount,_that.total,_that.isAwaitingQuote,_that.placedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String code, @JsonKey(unknownEnumValue: OrderStage.unknown)  OrderStage stage, @JsonKey(name: 'stage_label')  String stageLabel, @JsonKey(name: 'is_open')  bool isOpen, @JsonKey(name: 'stage_hint')  String? stageHint,  String? summary, @JsonKey(name: 'items_count')  int? itemsCount,  String? total, @JsonKey(name: 'is_awaiting_quote')  bool isAwaitingQuote, @JsonKey(name: 'placed_at')  DateTime? placedAt)?  $default,) {final _that = this;
switch (_that) {
case _CustomerOrder() when $default != null:
return $default(_that.id,_that.code,_that.stage,_that.stageLabel,_that.isOpen,_that.stageHint,_that.summary,_that.itemsCount,_that.total,_that.isAwaitingQuote,_that.placedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CustomerOrder implements CustomerOrder {
  const _CustomerOrder({required this.id, required this.code, @JsonKey(unknownEnumValue: OrderStage.unknown) this.stage = OrderStage.unknown, @JsonKey(name: 'stage_label') required this.stageLabel, @JsonKey(name: 'is_open') this.isOpen = true, @JsonKey(name: 'stage_hint') this.stageHint, this.summary, @JsonKey(name: 'items_count') this.itemsCount, this.total, @JsonKey(name: 'is_awaiting_quote') this.isAwaitingQuote = false, @JsonKey(name: 'placed_at') this.placedAt});
  factory _CustomerOrder.fromJson(Map<String, dynamic> json) => _$CustomerOrderFromJson(json);

@override final  int id;
/// «1228» — what the customer reads out when they ring.
@override final  String code;
@override@JsonKey(unknownEnumValue: OrderStage.unknown) final  OrderStage stage;
/// **Always drawn instead of translating [stage] here.** The Arabic travels with the value,
/// so a stage added to the business appears correctly without an app release.
@override@JsonKey(name: 'stage_label') final  String stageLabel;
@override@JsonKey(name: 'is_open') final  bool isOpen;
/// The sentence the card draws under the line — «نراجع طلبيتك ونؤكّدها خلال ساعات العمل».
///
/// **Also the server's, and for the same reason as [stageLabel].** A `switch` over
/// [OrderStage] written here would be a second copy of a mapping the backend keeps in one
/// place, and a stage added to the business would arrive with no sentence. Null for the
/// stages that are over: nothing reassuring is owed about a delivered order.
@override@JsonKey(name: 'stage_hint') final  String? stageHint;
/// «كيس شحن فلاير ٣٠×٤٠ و٢ أخرى» — built by the server so the list draws without opening
/// every order to write a subtitle.
@override final  String? summary;
@override@JsonKey(name: 'items_count') final  int? itemsCount;
/// A decimal string, like every amount in this app — **and null while the shop has not
/// priced every line**, which is what [isAwaitingQuote] says in one word. The card draws
/// «يُحدَّد بعد المراجعة» rather than a figure smaller than the real one.
@override final  String? total;
@override@JsonKey(name: 'is_awaiting_quote') final  bool isAwaitingQuote;
@override@JsonKey(name: 'placed_at') final  DateTime? placedAt;

/// Create a copy of CustomerOrder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomerOrderCopyWith<_CustomerOrder> get copyWith => __$CustomerOrderCopyWithImpl<_CustomerOrder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CustomerOrderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustomerOrder&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.stageLabel, stageLabel) || other.stageLabel == stageLabel)&&(identical(other.isOpen, isOpen) || other.isOpen == isOpen)&&(identical(other.stageHint, stageHint) || other.stageHint == stageHint)&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.itemsCount, itemsCount) || other.itemsCount == itemsCount)&&(identical(other.total, total) || other.total == total)&&(identical(other.isAwaitingQuote, isAwaitingQuote) || other.isAwaitingQuote == isAwaitingQuote)&&(identical(other.placedAt, placedAt) || other.placedAt == placedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,stage,stageLabel,isOpen,stageHint,summary,itemsCount,total,isAwaitingQuote,placedAt);

@override
String toString() {
  return 'CustomerOrder(id: $id, code: $code, stage: $stage, stageLabel: $stageLabel, isOpen: $isOpen, stageHint: $stageHint, summary: $summary, itemsCount: $itemsCount, total: $total, isAwaitingQuote: $isAwaitingQuote, placedAt: $placedAt)';
}


}

/// @nodoc
abstract mixin class _$CustomerOrderCopyWith<$Res> implements $CustomerOrderCopyWith<$Res> {
  factory _$CustomerOrderCopyWith(_CustomerOrder value, $Res Function(_CustomerOrder) _then) = __$CustomerOrderCopyWithImpl;
@override @useResult
$Res call({
 int id, String code,@JsonKey(unknownEnumValue: OrderStage.unknown) OrderStage stage,@JsonKey(name: 'stage_label') String stageLabel,@JsonKey(name: 'is_open') bool isOpen,@JsonKey(name: 'stage_hint') String? stageHint, String? summary,@JsonKey(name: 'items_count') int? itemsCount, String? total,@JsonKey(name: 'is_awaiting_quote') bool isAwaitingQuote,@JsonKey(name: 'placed_at') DateTime? placedAt
});




}
/// @nodoc
class __$CustomerOrderCopyWithImpl<$Res>
    implements _$CustomerOrderCopyWith<$Res> {
  __$CustomerOrderCopyWithImpl(this._self, this._then);

  final _CustomerOrder _self;
  final $Res Function(_CustomerOrder) _then;

/// Create a copy of CustomerOrder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? stage = null,Object? stageLabel = null,Object? isOpen = null,Object? stageHint = freezed,Object? summary = freezed,Object? itemsCount = freezed,Object? total = freezed,Object? isAwaitingQuote = null,Object? placedAt = freezed,}) {
  return _then(_CustomerOrder(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as OrderStage,stageLabel: null == stageLabel ? _self.stageLabel : stageLabel // ignore: cast_nullable_to_non_nullable
as String,isOpen: null == isOpen ? _self.isOpen : isOpen // ignore: cast_nullable_to_non_nullable
as bool,stageHint: freezed == stageHint ? _self.stageHint : stageHint // ignore: cast_nullable_to_non_nullable
as String?,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String?,itemsCount: freezed == itemsCount ? _self.itemsCount : itemsCount // ignore: cast_nullable_to_non_nullable
as int?,total: freezed == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String?,isAwaitingQuote: null == isAwaitingQuote ? _self.isAwaitingQuote : isAwaitingQuote // ignore: cast_nullable_to_non_nullable
as bool,placedAt: freezed == placedAt ? _self.placedAt : placedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$OrderLine {

 int get id;@JsonKey(name: 'product_name') String get productName;@JsonKey(name: 'variant_label') String? get variantLabel; String get quantity;/// **Null until the shop quotes it.** A product priced «حسب الطلب» is ordered without a
/// price — the app is never told one and must not invent one — and a zero here would read
/// as «مجاناً» on the customer's own screen.
@JsonKey(name: 'unit_price') String? get unitPrice;@JsonKey(name: 'line_total') String? get lineTotal;
/// Create a copy of OrderLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderLineCopyWith<OrderLine> get copyWith => _$OrderLineCopyWithImpl<OrderLine>(this as OrderLine, _$identity);

  /// Serializes this OrderLine to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderLine&&(identical(other.id, id) || other.id == id)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.variantLabel, variantLabel) || other.variantLabel == variantLabel)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.lineTotal, lineTotal) || other.lineTotal == lineTotal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,productName,variantLabel,quantity,unitPrice,lineTotal);

@override
String toString() {
  return 'OrderLine(id: $id, productName: $productName, variantLabel: $variantLabel, quantity: $quantity, unitPrice: $unitPrice, lineTotal: $lineTotal)';
}


}

/// @nodoc
abstract mixin class $OrderLineCopyWith<$Res>  {
  factory $OrderLineCopyWith(OrderLine value, $Res Function(OrderLine) _then) = _$OrderLineCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'product_name') String productName,@JsonKey(name: 'variant_label') String? variantLabel, String quantity,@JsonKey(name: 'unit_price') String? unitPrice,@JsonKey(name: 'line_total') String? lineTotal
});




}
/// @nodoc
class _$OrderLineCopyWithImpl<$Res>
    implements $OrderLineCopyWith<$Res> {
  _$OrderLineCopyWithImpl(this._self, this._then);

  final OrderLine _self;
  final $Res Function(OrderLine) _then;

/// Create a copy of OrderLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? productName = null,Object? variantLabel = freezed,Object? quantity = null,Object? unitPrice = freezed,Object? lineTotal = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,variantLabel: freezed == variantLabel ? _self.variantLabel : variantLabel // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,unitPrice: freezed == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String?,lineTotal: freezed == lineTotal ? _self.lineTotal : lineTotal // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderLine].
extension OrderLinePatterns on OrderLine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderLine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderLine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderLine value)  $default,){
final _that = this;
switch (_that) {
case _OrderLine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderLine value)?  $default,){
final _that = this;
switch (_that) {
case _OrderLine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'product_name')  String productName, @JsonKey(name: 'variant_label')  String? variantLabel,  String quantity, @JsonKey(name: 'unit_price')  String? unitPrice, @JsonKey(name: 'line_total')  String? lineTotal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderLine() when $default != null:
return $default(_that.id,_that.productName,_that.variantLabel,_that.quantity,_that.unitPrice,_that.lineTotal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'product_name')  String productName, @JsonKey(name: 'variant_label')  String? variantLabel,  String quantity, @JsonKey(name: 'unit_price')  String? unitPrice, @JsonKey(name: 'line_total')  String? lineTotal)  $default,) {final _that = this;
switch (_that) {
case _OrderLine():
return $default(_that.id,_that.productName,_that.variantLabel,_that.quantity,_that.unitPrice,_that.lineTotal);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'product_name')  String productName, @JsonKey(name: 'variant_label')  String? variantLabel,  String quantity, @JsonKey(name: 'unit_price')  String? unitPrice, @JsonKey(name: 'line_total')  String? lineTotal)?  $default,) {final _that = this;
switch (_that) {
case _OrderLine() when $default != null:
return $default(_that.id,_that.productName,_that.variantLabel,_that.quantity,_that.unitPrice,_that.lineTotal);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderLine implements OrderLine {
  const _OrderLine({required this.id, @JsonKey(name: 'product_name') required this.productName, @JsonKey(name: 'variant_label') this.variantLabel, required this.quantity, @JsonKey(name: 'unit_price') this.unitPrice, @JsonKey(name: 'line_total') this.lineTotal});
  factory _OrderLine.fromJson(Map<String, dynamic> json) => _$OrderLineFromJson(json);

@override final  int id;
@override@JsonKey(name: 'product_name') final  String productName;
@override@JsonKey(name: 'variant_label') final  String? variantLabel;
@override final  String quantity;
/// **Null until the shop quotes it.** A product priced «حسب الطلب» is ordered without a
/// price — the app is never told one and must not invent one — and a zero here would read
/// as «مجاناً» on the customer's own screen.
@override@JsonKey(name: 'unit_price') final  String? unitPrice;
@override@JsonKey(name: 'line_total') final  String? lineTotal;

/// Create a copy of OrderLine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderLineCopyWith<_OrderLine> get copyWith => __$OrderLineCopyWithImpl<_OrderLine>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderLineToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderLine&&(identical(other.id, id) || other.id == id)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.variantLabel, variantLabel) || other.variantLabel == variantLabel)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.lineTotal, lineTotal) || other.lineTotal == lineTotal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,productName,variantLabel,quantity,unitPrice,lineTotal);

@override
String toString() {
  return 'OrderLine(id: $id, productName: $productName, variantLabel: $variantLabel, quantity: $quantity, unitPrice: $unitPrice, lineTotal: $lineTotal)';
}


}

/// @nodoc
abstract mixin class _$OrderLineCopyWith<$Res> implements $OrderLineCopyWith<$Res> {
  factory _$OrderLineCopyWith(_OrderLine value, $Res Function(_OrderLine) _then) = __$OrderLineCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'product_name') String productName,@JsonKey(name: 'variant_label') String? variantLabel, String quantity,@JsonKey(name: 'unit_price') String? unitPrice,@JsonKey(name: 'line_total') String? lineTotal
});




}
/// @nodoc
class __$OrderLineCopyWithImpl<$Res>
    implements _$OrderLineCopyWith<$Res> {
  __$OrderLineCopyWithImpl(this._self, this._then);

  final _OrderLine _self;
  final $Res Function(_OrderLine) _then;

/// Create a copy of OrderLine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? productName = null,Object? variantLabel = freezed,Object? quantity = null,Object? unitPrice = freezed,Object? lineTotal = freezed,}) {
  return _then(_OrderLine(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,variantLabel: freezed == variantLabel ? _self.variantLabel : variantLabel // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,unitPrice: freezed == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String?,lineTotal: freezed == lineTotal ? _self.lineTotal : lineTotal // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$OrderTimelineEntry {

 String get stage;@JsonKey(name: 'stage_label') String get stageLabel;@JsonKey(name: 'reached_at') DateTime? get reachedAt;
/// Create a copy of OrderTimelineEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderTimelineEntryCopyWith<OrderTimelineEntry> get copyWith => _$OrderTimelineEntryCopyWithImpl<OrderTimelineEntry>(this as OrderTimelineEntry, _$identity);

  /// Serializes this OrderTimelineEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderTimelineEntry&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.stageLabel, stageLabel) || other.stageLabel == stageLabel)&&(identical(other.reachedAt, reachedAt) || other.reachedAt == reachedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,stage,stageLabel,reachedAt);

@override
String toString() {
  return 'OrderTimelineEntry(stage: $stage, stageLabel: $stageLabel, reachedAt: $reachedAt)';
}


}

/// @nodoc
abstract mixin class $OrderTimelineEntryCopyWith<$Res>  {
  factory $OrderTimelineEntryCopyWith(OrderTimelineEntry value, $Res Function(OrderTimelineEntry) _then) = _$OrderTimelineEntryCopyWithImpl;
@useResult
$Res call({
 String stage,@JsonKey(name: 'stage_label') String stageLabel,@JsonKey(name: 'reached_at') DateTime? reachedAt
});




}
/// @nodoc
class _$OrderTimelineEntryCopyWithImpl<$Res>
    implements $OrderTimelineEntryCopyWith<$Res> {
  _$OrderTimelineEntryCopyWithImpl(this._self, this._then);

  final OrderTimelineEntry _self;
  final $Res Function(OrderTimelineEntry) _then;

/// Create a copy of OrderTimelineEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? stage = null,Object? stageLabel = null,Object? reachedAt = freezed,}) {
  return _then(_self.copyWith(
stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as String,stageLabel: null == stageLabel ? _self.stageLabel : stageLabel // ignore: cast_nullable_to_non_nullable
as String,reachedAt: freezed == reachedAt ? _self.reachedAt : reachedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderTimelineEntry].
extension OrderTimelineEntryPatterns on OrderTimelineEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderTimelineEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderTimelineEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderTimelineEntry value)  $default,){
final _that = this;
switch (_that) {
case _OrderTimelineEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderTimelineEntry value)?  $default,){
final _that = this;
switch (_that) {
case _OrderTimelineEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String stage, @JsonKey(name: 'stage_label')  String stageLabel, @JsonKey(name: 'reached_at')  DateTime? reachedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderTimelineEntry() when $default != null:
return $default(_that.stage,_that.stageLabel,_that.reachedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String stage, @JsonKey(name: 'stage_label')  String stageLabel, @JsonKey(name: 'reached_at')  DateTime? reachedAt)  $default,) {final _that = this;
switch (_that) {
case _OrderTimelineEntry():
return $default(_that.stage,_that.stageLabel,_that.reachedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String stage, @JsonKey(name: 'stage_label')  String stageLabel, @JsonKey(name: 'reached_at')  DateTime? reachedAt)?  $default,) {final _that = this;
switch (_that) {
case _OrderTimelineEntry() when $default != null:
return $default(_that.stage,_that.stageLabel,_that.reachedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderTimelineEntry implements OrderTimelineEntry {
  const _OrderTimelineEntry({required this.stage, @JsonKey(name: 'stage_label') required this.stageLabel, @JsonKey(name: 'reached_at') this.reachedAt});
  factory _OrderTimelineEntry.fromJson(Map<String, dynamic> json) => _$OrderTimelineEntryFromJson(json);

@override final  String stage;
@override@JsonKey(name: 'stage_label') final  String stageLabel;
@override@JsonKey(name: 'reached_at') final  DateTime? reachedAt;

/// Create a copy of OrderTimelineEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderTimelineEntryCopyWith<_OrderTimelineEntry> get copyWith => __$OrderTimelineEntryCopyWithImpl<_OrderTimelineEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderTimelineEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderTimelineEntry&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.stageLabel, stageLabel) || other.stageLabel == stageLabel)&&(identical(other.reachedAt, reachedAt) || other.reachedAt == reachedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,stage,stageLabel,reachedAt);

@override
String toString() {
  return 'OrderTimelineEntry(stage: $stage, stageLabel: $stageLabel, reachedAt: $reachedAt)';
}


}

/// @nodoc
abstract mixin class _$OrderTimelineEntryCopyWith<$Res> implements $OrderTimelineEntryCopyWith<$Res> {
  factory _$OrderTimelineEntryCopyWith(_OrderTimelineEntry value, $Res Function(_OrderTimelineEntry) _then) = __$OrderTimelineEntryCopyWithImpl;
@override @useResult
$Res call({
 String stage,@JsonKey(name: 'stage_label') String stageLabel,@JsonKey(name: 'reached_at') DateTime? reachedAt
});




}
/// @nodoc
class __$OrderTimelineEntryCopyWithImpl<$Res>
    implements _$OrderTimelineEntryCopyWith<$Res> {
  __$OrderTimelineEntryCopyWithImpl(this._self, this._then);

  final _OrderTimelineEntry _self;
  final $Res Function(_OrderTimelineEntry) _then;

/// Create a copy of OrderTimelineEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? stage = null,Object? stageLabel = null,Object? reachedAt = freezed,}) {
  return _then(_OrderTimelineEntry(
stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as String,stageLabel: null == stageLabel ? _self.stageLabel : stageLabel // ignore: cast_nullable_to_non_nullable
as String,reachedAt: freezed == reachedAt ? _self.reachedAt : reachedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$CustomerOrderDetail {

 int get id; String get code;@JsonKey(unknownEnumValue: OrderStage.unknown) OrderStage get stage;@JsonKey(name: 'stage_label') String get stageLabel;@JsonKey(name: 'is_open') bool get isOpen;@JsonKey(name: 'stage_hint') String? get stageHint;/// Why the shop would not take this request.
///
/// **The only reason string that reaches this app.** An order's `cancellation_reason` is
/// written for the accountant about something the shop took and wrote off, and it stays on
/// the staff side. This one is the shop's answer to the person who placed the order. Null on
/// every order that was not refused.
@JsonKey(name: 'rejection_reason') String? get rejectionReason;/// The snapshot the order carries, not a live lookup — a renamed district must not rewrite
/// where an old order said it was headed.
@JsonKey(name: 'city_name') String? get cityName;@JsonKey(name: 'region_name') String? get regionName;@JsonKey(name: 'address_details') String? get addressDetails;@JsonKey(name: 'recipient_name') String? get recipientName;@JsonKey(name: 'recipient_phone') String? get recipientPhone;@JsonKey(name: 'fulfilment_type_label') String? get fulfilmentTypeLabel; List<OrderLine> get items;/// Every number here is one the customer is owed an answer about. What the goods cost the
/// shop is not among them and never arrives.
@JsonKey(name: 'items_total') String? get itemsTotal;@JsonKey(name: 'delivery_price') String? get deliveryPrice;@JsonKey(name: 'design_fee') String? get designFee; String? get discount;/// **Null while the shop has not quoted every line.**
///
/// A product priced «حسب الطلب» reaches an order with no price, and the server sends null
/// rather than the figure it has — that figure is the sum of the priced lines only, and
/// showing it would quote a number smaller than what will actually be asked for. The screen
/// draws «يُحدَّد بعد المراجعة» instead; see [isAwaitingQuote].
 String? get total;@JsonKey(name: 'paid_amount') String? get paidAmount; String? get balance;/// Whether any line is still waiting to be priced.
///
/// **The decided answer, sent rather than inferred.** Working it out from a handful of
/// nulls would make every screen re-derive the same rule, and get it subtly different.
@JsonKey(name: 'is_awaiting_quote') bool get isAwaitingQuote; List<OrderTimelineEntry> get timeline;@JsonKey(name: 'placed_at') DateTime? get placedAt;
/// Create a copy of CustomerOrderDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerOrderDetailCopyWith<CustomerOrderDetail> get copyWith => _$CustomerOrderDetailCopyWithImpl<CustomerOrderDetail>(this as CustomerOrderDetail, _$identity);

  /// Serializes this CustomerOrderDetail to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerOrderDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.stageLabel, stageLabel) || other.stageLabel == stageLabel)&&(identical(other.isOpen, isOpen) || other.isOpen == isOpen)&&(identical(other.stageHint, stageHint) || other.stageHint == stageHint)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason)&&(identical(other.cityName, cityName) || other.cityName == cityName)&&(identical(other.regionName, regionName) || other.regionName == regionName)&&(identical(other.addressDetails, addressDetails) || other.addressDetails == addressDetails)&&(identical(other.recipientName, recipientName) || other.recipientName == recipientName)&&(identical(other.recipientPhone, recipientPhone) || other.recipientPhone == recipientPhone)&&(identical(other.fulfilmentTypeLabel, fulfilmentTypeLabel) || other.fulfilmentTypeLabel == fulfilmentTypeLabel)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.itemsTotal, itemsTotal) || other.itemsTotal == itemsTotal)&&(identical(other.deliveryPrice, deliveryPrice) || other.deliveryPrice == deliveryPrice)&&(identical(other.designFee, designFee) || other.designFee == designFee)&&(identical(other.discount, discount) || other.discount == discount)&&(identical(other.total, total) || other.total == total)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount)&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.isAwaitingQuote, isAwaitingQuote) || other.isAwaitingQuote == isAwaitingQuote)&&const DeepCollectionEquality().equals(other.timeline, timeline)&&(identical(other.placedAt, placedAt) || other.placedAt == placedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,code,stage,stageLabel,isOpen,stageHint,rejectionReason,cityName,regionName,addressDetails,recipientName,recipientPhone,fulfilmentTypeLabel,const DeepCollectionEquality().hash(items),itemsTotal,deliveryPrice,designFee,discount,total,paidAmount,balance,isAwaitingQuote,const DeepCollectionEquality().hash(timeline),placedAt]);

@override
String toString() {
  return 'CustomerOrderDetail(id: $id, code: $code, stage: $stage, stageLabel: $stageLabel, isOpen: $isOpen, stageHint: $stageHint, rejectionReason: $rejectionReason, cityName: $cityName, regionName: $regionName, addressDetails: $addressDetails, recipientName: $recipientName, recipientPhone: $recipientPhone, fulfilmentTypeLabel: $fulfilmentTypeLabel, items: $items, itemsTotal: $itemsTotal, deliveryPrice: $deliveryPrice, designFee: $designFee, discount: $discount, total: $total, paidAmount: $paidAmount, balance: $balance, isAwaitingQuote: $isAwaitingQuote, timeline: $timeline, placedAt: $placedAt)';
}


}

/// @nodoc
abstract mixin class $CustomerOrderDetailCopyWith<$Res>  {
  factory $CustomerOrderDetailCopyWith(CustomerOrderDetail value, $Res Function(CustomerOrderDetail) _then) = _$CustomerOrderDetailCopyWithImpl;
@useResult
$Res call({
 int id, String code,@JsonKey(unknownEnumValue: OrderStage.unknown) OrderStage stage,@JsonKey(name: 'stage_label') String stageLabel,@JsonKey(name: 'is_open') bool isOpen,@JsonKey(name: 'stage_hint') String? stageHint,@JsonKey(name: 'rejection_reason') String? rejectionReason,@JsonKey(name: 'city_name') String? cityName,@JsonKey(name: 'region_name') String? regionName,@JsonKey(name: 'address_details') String? addressDetails,@JsonKey(name: 'recipient_name') String? recipientName,@JsonKey(name: 'recipient_phone') String? recipientPhone,@JsonKey(name: 'fulfilment_type_label') String? fulfilmentTypeLabel, List<OrderLine> items,@JsonKey(name: 'items_total') String? itemsTotal,@JsonKey(name: 'delivery_price') String? deliveryPrice,@JsonKey(name: 'design_fee') String? designFee, String? discount, String? total,@JsonKey(name: 'paid_amount') String? paidAmount, String? balance,@JsonKey(name: 'is_awaiting_quote') bool isAwaitingQuote, List<OrderTimelineEntry> timeline,@JsonKey(name: 'placed_at') DateTime? placedAt
});




}
/// @nodoc
class _$CustomerOrderDetailCopyWithImpl<$Res>
    implements $CustomerOrderDetailCopyWith<$Res> {
  _$CustomerOrderDetailCopyWithImpl(this._self, this._then);

  final CustomerOrderDetail _self;
  final $Res Function(CustomerOrderDetail) _then;

/// Create a copy of CustomerOrderDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? stage = null,Object? stageLabel = null,Object? isOpen = null,Object? stageHint = freezed,Object? rejectionReason = freezed,Object? cityName = freezed,Object? regionName = freezed,Object? addressDetails = freezed,Object? recipientName = freezed,Object? recipientPhone = freezed,Object? fulfilmentTypeLabel = freezed,Object? items = null,Object? itemsTotal = freezed,Object? deliveryPrice = freezed,Object? designFee = freezed,Object? discount = freezed,Object? total = freezed,Object? paidAmount = freezed,Object? balance = freezed,Object? isAwaitingQuote = null,Object? timeline = null,Object? placedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as OrderStage,stageLabel: null == stageLabel ? _self.stageLabel : stageLabel // ignore: cast_nullable_to_non_nullable
as String,isOpen: null == isOpen ? _self.isOpen : isOpen // ignore: cast_nullable_to_non_nullable
as bool,stageHint: freezed == stageHint ? _self.stageHint : stageHint // ignore: cast_nullable_to_non_nullable
as String?,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,cityName: freezed == cityName ? _self.cityName : cityName // ignore: cast_nullable_to_non_nullable
as String?,regionName: freezed == regionName ? _self.regionName : regionName // ignore: cast_nullable_to_non_nullable
as String?,addressDetails: freezed == addressDetails ? _self.addressDetails : addressDetails // ignore: cast_nullable_to_non_nullable
as String?,recipientName: freezed == recipientName ? _self.recipientName : recipientName // ignore: cast_nullable_to_non_nullable
as String?,recipientPhone: freezed == recipientPhone ? _self.recipientPhone : recipientPhone // ignore: cast_nullable_to_non_nullable
as String?,fulfilmentTypeLabel: freezed == fulfilmentTypeLabel ? _self.fulfilmentTypeLabel : fulfilmentTypeLabel // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<OrderLine>,itemsTotal: freezed == itemsTotal ? _self.itemsTotal : itemsTotal // ignore: cast_nullable_to_non_nullable
as String?,deliveryPrice: freezed == deliveryPrice ? _self.deliveryPrice : deliveryPrice // ignore: cast_nullable_to_non_nullable
as String?,designFee: freezed == designFee ? _self.designFee : designFee // ignore: cast_nullable_to_non_nullable
as String?,discount: freezed == discount ? _self.discount : discount // ignore: cast_nullable_to_non_nullable
as String?,total: freezed == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String?,paidAmount: freezed == paidAmount ? _self.paidAmount : paidAmount // ignore: cast_nullable_to_non_nullable
as String?,balance: freezed == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as String?,isAwaitingQuote: null == isAwaitingQuote ? _self.isAwaitingQuote : isAwaitingQuote // ignore: cast_nullable_to_non_nullable
as bool,timeline: null == timeline ? _self.timeline : timeline // ignore: cast_nullable_to_non_nullable
as List<OrderTimelineEntry>,placedAt: freezed == placedAt ? _self.placedAt : placedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [CustomerOrderDetail].
extension CustomerOrderDetailPatterns on CustomerOrderDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CustomerOrderDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CustomerOrderDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CustomerOrderDetail value)  $default,){
final _that = this;
switch (_that) {
case _CustomerOrderDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CustomerOrderDetail value)?  $default,){
final _that = this;
switch (_that) {
case _CustomerOrderDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String code, @JsonKey(unknownEnumValue: OrderStage.unknown)  OrderStage stage, @JsonKey(name: 'stage_label')  String stageLabel, @JsonKey(name: 'is_open')  bool isOpen, @JsonKey(name: 'stage_hint')  String? stageHint, @JsonKey(name: 'rejection_reason')  String? rejectionReason, @JsonKey(name: 'city_name')  String? cityName, @JsonKey(name: 'region_name')  String? regionName, @JsonKey(name: 'address_details')  String? addressDetails, @JsonKey(name: 'recipient_name')  String? recipientName, @JsonKey(name: 'recipient_phone')  String? recipientPhone, @JsonKey(name: 'fulfilment_type_label')  String? fulfilmentTypeLabel,  List<OrderLine> items, @JsonKey(name: 'items_total')  String? itemsTotal, @JsonKey(name: 'delivery_price')  String? deliveryPrice, @JsonKey(name: 'design_fee')  String? designFee,  String? discount,  String? total, @JsonKey(name: 'paid_amount')  String? paidAmount,  String? balance, @JsonKey(name: 'is_awaiting_quote')  bool isAwaitingQuote,  List<OrderTimelineEntry> timeline, @JsonKey(name: 'placed_at')  DateTime? placedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CustomerOrderDetail() when $default != null:
return $default(_that.id,_that.code,_that.stage,_that.stageLabel,_that.isOpen,_that.stageHint,_that.rejectionReason,_that.cityName,_that.regionName,_that.addressDetails,_that.recipientName,_that.recipientPhone,_that.fulfilmentTypeLabel,_that.items,_that.itemsTotal,_that.deliveryPrice,_that.designFee,_that.discount,_that.total,_that.paidAmount,_that.balance,_that.isAwaitingQuote,_that.timeline,_that.placedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String code, @JsonKey(unknownEnumValue: OrderStage.unknown)  OrderStage stage, @JsonKey(name: 'stage_label')  String stageLabel, @JsonKey(name: 'is_open')  bool isOpen, @JsonKey(name: 'stage_hint')  String? stageHint, @JsonKey(name: 'rejection_reason')  String? rejectionReason, @JsonKey(name: 'city_name')  String? cityName, @JsonKey(name: 'region_name')  String? regionName, @JsonKey(name: 'address_details')  String? addressDetails, @JsonKey(name: 'recipient_name')  String? recipientName, @JsonKey(name: 'recipient_phone')  String? recipientPhone, @JsonKey(name: 'fulfilment_type_label')  String? fulfilmentTypeLabel,  List<OrderLine> items, @JsonKey(name: 'items_total')  String? itemsTotal, @JsonKey(name: 'delivery_price')  String? deliveryPrice, @JsonKey(name: 'design_fee')  String? designFee,  String? discount,  String? total, @JsonKey(name: 'paid_amount')  String? paidAmount,  String? balance, @JsonKey(name: 'is_awaiting_quote')  bool isAwaitingQuote,  List<OrderTimelineEntry> timeline, @JsonKey(name: 'placed_at')  DateTime? placedAt)  $default,) {final _that = this;
switch (_that) {
case _CustomerOrderDetail():
return $default(_that.id,_that.code,_that.stage,_that.stageLabel,_that.isOpen,_that.stageHint,_that.rejectionReason,_that.cityName,_that.regionName,_that.addressDetails,_that.recipientName,_that.recipientPhone,_that.fulfilmentTypeLabel,_that.items,_that.itemsTotal,_that.deliveryPrice,_that.designFee,_that.discount,_that.total,_that.paidAmount,_that.balance,_that.isAwaitingQuote,_that.timeline,_that.placedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String code, @JsonKey(unknownEnumValue: OrderStage.unknown)  OrderStage stage, @JsonKey(name: 'stage_label')  String stageLabel, @JsonKey(name: 'is_open')  bool isOpen, @JsonKey(name: 'stage_hint')  String? stageHint, @JsonKey(name: 'rejection_reason')  String? rejectionReason, @JsonKey(name: 'city_name')  String? cityName, @JsonKey(name: 'region_name')  String? regionName, @JsonKey(name: 'address_details')  String? addressDetails, @JsonKey(name: 'recipient_name')  String? recipientName, @JsonKey(name: 'recipient_phone')  String? recipientPhone, @JsonKey(name: 'fulfilment_type_label')  String? fulfilmentTypeLabel,  List<OrderLine> items, @JsonKey(name: 'items_total')  String? itemsTotal, @JsonKey(name: 'delivery_price')  String? deliveryPrice, @JsonKey(name: 'design_fee')  String? designFee,  String? discount,  String? total, @JsonKey(name: 'paid_amount')  String? paidAmount,  String? balance, @JsonKey(name: 'is_awaiting_quote')  bool isAwaitingQuote,  List<OrderTimelineEntry> timeline, @JsonKey(name: 'placed_at')  DateTime? placedAt)?  $default,) {final _that = this;
switch (_that) {
case _CustomerOrderDetail() when $default != null:
return $default(_that.id,_that.code,_that.stage,_that.stageLabel,_that.isOpen,_that.stageHint,_that.rejectionReason,_that.cityName,_that.regionName,_that.addressDetails,_that.recipientName,_that.recipientPhone,_that.fulfilmentTypeLabel,_that.items,_that.itemsTotal,_that.deliveryPrice,_that.designFee,_that.discount,_that.total,_that.paidAmount,_that.balance,_that.isAwaitingQuote,_that.timeline,_that.placedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CustomerOrderDetail implements CustomerOrderDetail {
  const _CustomerOrderDetail({required this.id, required this.code, @JsonKey(unknownEnumValue: OrderStage.unknown) this.stage = OrderStage.unknown, @JsonKey(name: 'stage_label') required this.stageLabel, @JsonKey(name: 'is_open') this.isOpen = true, @JsonKey(name: 'stage_hint') this.stageHint, @JsonKey(name: 'rejection_reason') this.rejectionReason, @JsonKey(name: 'city_name') this.cityName, @JsonKey(name: 'region_name') this.regionName, @JsonKey(name: 'address_details') this.addressDetails, @JsonKey(name: 'recipient_name') this.recipientName, @JsonKey(name: 'recipient_phone') this.recipientPhone, @JsonKey(name: 'fulfilment_type_label') this.fulfilmentTypeLabel, final  List<OrderLine> items = const <OrderLine>[], @JsonKey(name: 'items_total') this.itemsTotal, @JsonKey(name: 'delivery_price') this.deliveryPrice, @JsonKey(name: 'design_fee') this.designFee, this.discount, this.total, @JsonKey(name: 'paid_amount') this.paidAmount, this.balance, @JsonKey(name: 'is_awaiting_quote') this.isAwaitingQuote = false, final  List<OrderTimelineEntry> timeline = const <OrderTimelineEntry>[], @JsonKey(name: 'placed_at') this.placedAt}): _items = items,_timeline = timeline;
  factory _CustomerOrderDetail.fromJson(Map<String, dynamic> json) => _$CustomerOrderDetailFromJson(json);

@override final  int id;
@override final  String code;
@override@JsonKey(unknownEnumValue: OrderStage.unknown) final  OrderStage stage;
@override@JsonKey(name: 'stage_label') final  String stageLabel;
@override@JsonKey(name: 'is_open') final  bool isOpen;
@override@JsonKey(name: 'stage_hint') final  String? stageHint;
/// Why the shop would not take this request.
///
/// **The only reason string that reaches this app.** An order's `cancellation_reason` is
/// written for the accountant about something the shop took and wrote off, and it stays on
/// the staff side. This one is the shop's answer to the person who placed the order. Null on
/// every order that was not refused.
@override@JsonKey(name: 'rejection_reason') final  String? rejectionReason;
/// The snapshot the order carries, not a live lookup — a renamed district must not rewrite
/// where an old order said it was headed.
@override@JsonKey(name: 'city_name') final  String? cityName;
@override@JsonKey(name: 'region_name') final  String? regionName;
@override@JsonKey(name: 'address_details') final  String? addressDetails;
@override@JsonKey(name: 'recipient_name') final  String? recipientName;
@override@JsonKey(name: 'recipient_phone') final  String? recipientPhone;
@override@JsonKey(name: 'fulfilment_type_label') final  String? fulfilmentTypeLabel;
 final  List<OrderLine> _items;
@override@JsonKey() List<OrderLine> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

/// Every number here is one the customer is owed an answer about. What the goods cost the
/// shop is not among them and never arrives.
@override@JsonKey(name: 'items_total') final  String? itemsTotal;
@override@JsonKey(name: 'delivery_price') final  String? deliveryPrice;
@override@JsonKey(name: 'design_fee') final  String? designFee;
@override final  String? discount;
/// **Null while the shop has not quoted every line.**
///
/// A product priced «حسب الطلب» reaches an order with no price, and the server sends null
/// rather than the figure it has — that figure is the sum of the priced lines only, and
/// showing it would quote a number smaller than what will actually be asked for. The screen
/// draws «يُحدَّد بعد المراجعة» instead; see [isAwaitingQuote].
@override final  String? total;
@override@JsonKey(name: 'paid_amount') final  String? paidAmount;
@override final  String? balance;
/// Whether any line is still waiting to be priced.
///
/// **The decided answer, sent rather than inferred.** Working it out from a handful of
/// nulls would make every screen re-derive the same rule, and get it subtly different.
@override@JsonKey(name: 'is_awaiting_quote') final  bool isAwaitingQuote;
 final  List<OrderTimelineEntry> _timeline;
@override@JsonKey() List<OrderTimelineEntry> get timeline {
  if (_timeline is EqualUnmodifiableListView) return _timeline;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_timeline);
}

@override@JsonKey(name: 'placed_at') final  DateTime? placedAt;

/// Create a copy of CustomerOrderDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CustomerOrderDetailCopyWith<_CustomerOrderDetail> get copyWith => __$CustomerOrderDetailCopyWithImpl<_CustomerOrderDetail>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CustomerOrderDetailToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CustomerOrderDetail&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.stageLabel, stageLabel) || other.stageLabel == stageLabel)&&(identical(other.isOpen, isOpen) || other.isOpen == isOpen)&&(identical(other.stageHint, stageHint) || other.stageHint == stageHint)&&(identical(other.rejectionReason, rejectionReason) || other.rejectionReason == rejectionReason)&&(identical(other.cityName, cityName) || other.cityName == cityName)&&(identical(other.regionName, regionName) || other.regionName == regionName)&&(identical(other.addressDetails, addressDetails) || other.addressDetails == addressDetails)&&(identical(other.recipientName, recipientName) || other.recipientName == recipientName)&&(identical(other.recipientPhone, recipientPhone) || other.recipientPhone == recipientPhone)&&(identical(other.fulfilmentTypeLabel, fulfilmentTypeLabel) || other.fulfilmentTypeLabel == fulfilmentTypeLabel)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.itemsTotal, itemsTotal) || other.itemsTotal == itemsTotal)&&(identical(other.deliveryPrice, deliveryPrice) || other.deliveryPrice == deliveryPrice)&&(identical(other.designFee, designFee) || other.designFee == designFee)&&(identical(other.discount, discount) || other.discount == discount)&&(identical(other.total, total) || other.total == total)&&(identical(other.paidAmount, paidAmount) || other.paidAmount == paidAmount)&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.isAwaitingQuote, isAwaitingQuote) || other.isAwaitingQuote == isAwaitingQuote)&&const DeepCollectionEquality().equals(other._timeline, _timeline)&&(identical(other.placedAt, placedAt) || other.placedAt == placedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,code,stage,stageLabel,isOpen,stageHint,rejectionReason,cityName,regionName,addressDetails,recipientName,recipientPhone,fulfilmentTypeLabel,const DeepCollectionEquality().hash(_items),itemsTotal,deliveryPrice,designFee,discount,total,paidAmount,balance,isAwaitingQuote,const DeepCollectionEquality().hash(_timeline),placedAt]);

@override
String toString() {
  return 'CustomerOrderDetail(id: $id, code: $code, stage: $stage, stageLabel: $stageLabel, isOpen: $isOpen, stageHint: $stageHint, rejectionReason: $rejectionReason, cityName: $cityName, regionName: $regionName, addressDetails: $addressDetails, recipientName: $recipientName, recipientPhone: $recipientPhone, fulfilmentTypeLabel: $fulfilmentTypeLabel, items: $items, itemsTotal: $itemsTotal, deliveryPrice: $deliveryPrice, designFee: $designFee, discount: $discount, total: $total, paidAmount: $paidAmount, balance: $balance, isAwaitingQuote: $isAwaitingQuote, timeline: $timeline, placedAt: $placedAt)';
}


}

/// @nodoc
abstract mixin class _$CustomerOrderDetailCopyWith<$Res> implements $CustomerOrderDetailCopyWith<$Res> {
  factory _$CustomerOrderDetailCopyWith(_CustomerOrderDetail value, $Res Function(_CustomerOrderDetail) _then) = __$CustomerOrderDetailCopyWithImpl;
@override @useResult
$Res call({
 int id, String code,@JsonKey(unknownEnumValue: OrderStage.unknown) OrderStage stage,@JsonKey(name: 'stage_label') String stageLabel,@JsonKey(name: 'is_open') bool isOpen,@JsonKey(name: 'stage_hint') String? stageHint,@JsonKey(name: 'rejection_reason') String? rejectionReason,@JsonKey(name: 'city_name') String? cityName,@JsonKey(name: 'region_name') String? regionName,@JsonKey(name: 'address_details') String? addressDetails,@JsonKey(name: 'recipient_name') String? recipientName,@JsonKey(name: 'recipient_phone') String? recipientPhone,@JsonKey(name: 'fulfilment_type_label') String? fulfilmentTypeLabel, List<OrderLine> items,@JsonKey(name: 'items_total') String? itemsTotal,@JsonKey(name: 'delivery_price') String? deliveryPrice,@JsonKey(name: 'design_fee') String? designFee, String? discount, String? total,@JsonKey(name: 'paid_amount') String? paidAmount, String? balance,@JsonKey(name: 'is_awaiting_quote') bool isAwaitingQuote, List<OrderTimelineEntry> timeline,@JsonKey(name: 'placed_at') DateTime? placedAt
});




}
/// @nodoc
class __$CustomerOrderDetailCopyWithImpl<$Res>
    implements _$CustomerOrderDetailCopyWith<$Res> {
  __$CustomerOrderDetailCopyWithImpl(this._self, this._then);

  final _CustomerOrderDetail _self;
  final $Res Function(_CustomerOrderDetail) _then;

/// Create a copy of CustomerOrderDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? stage = null,Object? stageLabel = null,Object? isOpen = null,Object? stageHint = freezed,Object? rejectionReason = freezed,Object? cityName = freezed,Object? regionName = freezed,Object? addressDetails = freezed,Object? recipientName = freezed,Object? recipientPhone = freezed,Object? fulfilmentTypeLabel = freezed,Object? items = null,Object? itemsTotal = freezed,Object? deliveryPrice = freezed,Object? designFee = freezed,Object? discount = freezed,Object? total = freezed,Object? paidAmount = freezed,Object? balance = freezed,Object? isAwaitingQuote = null,Object? timeline = null,Object? placedAt = freezed,}) {
  return _then(_CustomerOrderDetail(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as OrderStage,stageLabel: null == stageLabel ? _self.stageLabel : stageLabel // ignore: cast_nullable_to_non_nullable
as String,isOpen: null == isOpen ? _self.isOpen : isOpen // ignore: cast_nullable_to_non_nullable
as bool,stageHint: freezed == stageHint ? _self.stageHint : stageHint // ignore: cast_nullable_to_non_nullable
as String?,rejectionReason: freezed == rejectionReason ? _self.rejectionReason : rejectionReason // ignore: cast_nullable_to_non_nullable
as String?,cityName: freezed == cityName ? _self.cityName : cityName // ignore: cast_nullable_to_non_nullable
as String?,regionName: freezed == regionName ? _self.regionName : regionName // ignore: cast_nullable_to_non_nullable
as String?,addressDetails: freezed == addressDetails ? _self.addressDetails : addressDetails // ignore: cast_nullable_to_non_nullable
as String?,recipientName: freezed == recipientName ? _self.recipientName : recipientName // ignore: cast_nullable_to_non_nullable
as String?,recipientPhone: freezed == recipientPhone ? _self.recipientPhone : recipientPhone // ignore: cast_nullable_to_non_nullable
as String?,fulfilmentTypeLabel: freezed == fulfilmentTypeLabel ? _self.fulfilmentTypeLabel : fulfilmentTypeLabel // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<OrderLine>,itemsTotal: freezed == itemsTotal ? _self.itemsTotal : itemsTotal // ignore: cast_nullable_to_non_nullable
as String?,deliveryPrice: freezed == deliveryPrice ? _self.deliveryPrice : deliveryPrice // ignore: cast_nullable_to_non_nullable
as String?,designFee: freezed == designFee ? _self.designFee : designFee // ignore: cast_nullable_to_non_nullable
as String?,discount: freezed == discount ? _self.discount : discount // ignore: cast_nullable_to_non_nullable
as String?,total: freezed == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String?,paidAmount: freezed == paidAmount ? _self.paidAmount : paidAmount // ignore: cast_nullable_to_non_nullable
as String?,balance: freezed == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as String?,isAwaitingQuote: null == isAwaitingQuote ? _self.isAwaitingQuote : isAwaitingQuote // ignore: cast_nullable_to_non_nullable
as bool,timeline: null == timeline ? _self._timeline : timeline // ignore: cast_nullable_to_non_nullable
as List<OrderTimelineEntry>,placedAt: freezed == placedAt ? _self.placedAt : placedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$NewOrderLine {

@JsonKey(name: 'product_id') int get productId;@JsonKey(name: 'product_variant_id') int get productVariantId; String get quantity;
/// Create a copy of NewOrderLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewOrderLineCopyWith<NewOrderLine> get copyWith => _$NewOrderLineCopyWithImpl<NewOrderLine>(this as NewOrderLine, _$identity);

  /// Serializes this NewOrderLine to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewOrderLine&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productVariantId, productVariantId) || other.productVariantId == productVariantId)&&(identical(other.quantity, quantity) || other.quantity == quantity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productId,productVariantId,quantity);

@override
String toString() {
  return 'NewOrderLine(productId: $productId, productVariantId: $productVariantId, quantity: $quantity)';
}


}

/// @nodoc
abstract mixin class $NewOrderLineCopyWith<$Res>  {
  factory $NewOrderLineCopyWith(NewOrderLine value, $Res Function(NewOrderLine) _then) = _$NewOrderLineCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'product_id') int productId,@JsonKey(name: 'product_variant_id') int productVariantId, String quantity
});




}
/// @nodoc
class _$NewOrderLineCopyWithImpl<$Res>
    implements $NewOrderLineCopyWith<$Res> {
  _$NewOrderLineCopyWithImpl(this._self, this._then);

  final NewOrderLine _self;
  final $Res Function(NewOrderLine) _then;

/// Create a copy of NewOrderLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productId = null,Object? productVariantId = null,Object? quantity = null,}) {
  return _then(_self.copyWith(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as int,productVariantId: null == productVariantId ? _self.productVariantId : productVariantId // ignore: cast_nullable_to_non_nullable
as int,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [NewOrderLine].
extension NewOrderLinePatterns on NewOrderLine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewOrderLine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewOrderLine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewOrderLine value)  $default,){
final _that = this;
switch (_that) {
case _NewOrderLine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewOrderLine value)?  $default,){
final _that = this;
switch (_that) {
case _NewOrderLine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'product_id')  int productId, @JsonKey(name: 'product_variant_id')  int productVariantId,  String quantity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewOrderLine() when $default != null:
return $default(_that.productId,_that.productVariantId,_that.quantity);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'product_id')  int productId, @JsonKey(name: 'product_variant_id')  int productVariantId,  String quantity)  $default,) {final _that = this;
switch (_that) {
case _NewOrderLine():
return $default(_that.productId,_that.productVariantId,_that.quantity);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'product_id')  int productId, @JsonKey(name: 'product_variant_id')  int productVariantId,  String quantity)?  $default,) {final _that = this;
switch (_that) {
case _NewOrderLine() when $default != null:
return $default(_that.productId,_that.productVariantId,_that.quantity);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NewOrderLine implements NewOrderLine {
  const _NewOrderLine({@JsonKey(name: 'product_id') required this.productId, @JsonKey(name: 'product_variant_id') required this.productVariantId, required this.quantity});
  factory _NewOrderLine.fromJson(Map<String, dynamic> json) => _$NewOrderLineFromJson(json);

@override@JsonKey(name: 'product_id') final  int productId;
@override@JsonKey(name: 'product_variant_id') final  int productVariantId;
@override final  String quantity;

/// Create a copy of NewOrderLine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewOrderLineCopyWith<_NewOrderLine> get copyWith => __$NewOrderLineCopyWithImpl<_NewOrderLine>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NewOrderLineToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewOrderLine&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productVariantId, productVariantId) || other.productVariantId == productVariantId)&&(identical(other.quantity, quantity) || other.quantity == quantity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productId,productVariantId,quantity);

@override
String toString() {
  return 'NewOrderLine(productId: $productId, productVariantId: $productVariantId, quantity: $quantity)';
}


}

/// @nodoc
abstract mixin class _$NewOrderLineCopyWith<$Res> implements $NewOrderLineCopyWith<$Res> {
  factory _$NewOrderLineCopyWith(_NewOrderLine value, $Res Function(_NewOrderLine) _then) = __$NewOrderLineCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'product_id') int productId,@JsonKey(name: 'product_variant_id') int productVariantId, String quantity
});




}
/// @nodoc
class __$NewOrderLineCopyWithImpl<$Res>
    implements _$NewOrderLineCopyWith<$Res> {
  __$NewOrderLineCopyWithImpl(this._self, this._then);

  final _NewOrderLine _self;
  final $Res Function(_NewOrderLine) _then;

/// Create a copy of NewOrderLine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productId = null,Object? productVariantId = null,Object? quantity = null,}) {
  return _then(_NewOrderLine(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as int,productVariantId: null == productVariantId ? _self.productVariantId : productVariantId // ignore: cast_nullable_to_non_nullable
as int,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$NewOrder {

@JsonKey(name: 'city_id') int get cityId; List<NewOrderLine> get items;@JsonKey(name: 'region_id') int? get regionId;@JsonKey(name: 'customer_shop_id') int? get customerShopId;@JsonKey(name: 'recipient_name') String? get recipientName;@JsonKey(name: 'recipient_phone') String? get recipientPhone;@JsonKey(name: 'address_details') String? get addressDetails;@JsonKey(name: 'design_ids') List<int> get designIds;/// What the customer wants to say about the order. It lands in the order's note prefixed
/// «ملاحظة العميل:», so whoever reviews it can see at a glance whose words they are.
@JsonKey(name: 'customer_note') String? get customerNote;
/// Create a copy of NewOrder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NewOrderCopyWith<NewOrder> get copyWith => _$NewOrderCopyWithImpl<NewOrder>(this as NewOrder, _$identity);

  /// Serializes this NewOrder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NewOrder&&(identical(other.cityId, cityId) || other.cityId == cityId)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.regionId, regionId) || other.regionId == regionId)&&(identical(other.customerShopId, customerShopId) || other.customerShopId == customerShopId)&&(identical(other.recipientName, recipientName) || other.recipientName == recipientName)&&(identical(other.recipientPhone, recipientPhone) || other.recipientPhone == recipientPhone)&&(identical(other.addressDetails, addressDetails) || other.addressDetails == addressDetails)&&const DeepCollectionEquality().equals(other.designIds, designIds)&&(identical(other.customerNote, customerNote) || other.customerNote == customerNote));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cityId,const DeepCollectionEquality().hash(items),regionId,customerShopId,recipientName,recipientPhone,addressDetails,const DeepCollectionEquality().hash(designIds),customerNote);

@override
String toString() {
  return 'NewOrder(cityId: $cityId, items: $items, regionId: $regionId, customerShopId: $customerShopId, recipientName: $recipientName, recipientPhone: $recipientPhone, addressDetails: $addressDetails, designIds: $designIds, customerNote: $customerNote)';
}


}

/// @nodoc
abstract mixin class $NewOrderCopyWith<$Res>  {
  factory $NewOrderCopyWith(NewOrder value, $Res Function(NewOrder) _then) = _$NewOrderCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'city_id') int cityId, List<NewOrderLine> items,@JsonKey(name: 'region_id') int? regionId,@JsonKey(name: 'customer_shop_id') int? customerShopId,@JsonKey(name: 'recipient_name') String? recipientName,@JsonKey(name: 'recipient_phone') String? recipientPhone,@JsonKey(name: 'address_details') String? addressDetails,@JsonKey(name: 'design_ids') List<int> designIds,@JsonKey(name: 'customer_note') String? customerNote
});




}
/// @nodoc
class _$NewOrderCopyWithImpl<$Res>
    implements $NewOrderCopyWith<$Res> {
  _$NewOrderCopyWithImpl(this._self, this._then);

  final NewOrder _self;
  final $Res Function(NewOrder) _then;

/// Create a copy of NewOrder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cityId = null,Object? items = null,Object? regionId = freezed,Object? customerShopId = freezed,Object? recipientName = freezed,Object? recipientPhone = freezed,Object? addressDetails = freezed,Object? designIds = null,Object? customerNote = freezed,}) {
  return _then(_self.copyWith(
cityId: null == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as int,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<NewOrderLine>,regionId: freezed == regionId ? _self.regionId : regionId // ignore: cast_nullable_to_non_nullable
as int?,customerShopId: freezed == customerShopId ? _self.customerShopId : customerShopId // ignore: cast_nullable_to_non_nullable
as int?,recipientName: freezed == recipientName ? _self.recipientName : recipientName // ignore: cast_nullable_to_non_nullable
as String?,recipientPhone: freezed == recipientPhone ? _self.recipientPhone : recipientPhone // ignore: cast_nullable_to_non_nullable
as String?,addressDetails: freezed == addressDetails ? _self.addressDetails : addressDetails // ignore: cast_nullable_to_non_nullable
as String?,designIds: null == designIds ? _self.designIds : designIds // ignore: cast_nullable_to_non_nullable
as List<int>,customerNote: freezed == customerNote ? _self.customerNote : customerNote // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [NewOrder].
extension NewOrderPatterns on NewOrder {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NewOrder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NewOrder() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NewOrder value)  $default,){
final _that = this;
switch (_that) {
case _NewOrder():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NewOrder value)?  $default,){
final _that = this;
switch (_that) {
case _NewOrder() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'city_id')  int cityId,  List<NewOrderLine> items, @JsonKey(name: 'region_id')  int? regionId, @JsonKey(name: 'customer_shop_id')  int? customerShopId, @JsonKey(name: 'recipient_name')  String? recipientName, @JsonKey(name: 'recipient_phone')  String? recipientPhone, @JsonKey(name: 'address_details')  String? addressDetails, @JsonKey(name: 'design_ids')  List<int> designIds, @JsonKey(name: 'customer_note')  String? customerNote)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NewOrder() when $default != null:
return $default(_that.cityId,_that.items,_that.regionId,_that.customerShopId,_that.recipientName,_that.recipientPhone,_that.addressDetails,_that.designIds,_that.customerNote);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'city_id')  int cityId,  List<NewOrderLine> items, @JsonKey(name: 'region_id')  int? regionId, @JsonKey(name: 'customer_shop_id')  int? customerShopId, @JsonKey(name: 'recipient_name')  String? recipientName, @JsonKey(name: 'recipient_phone')  String? recipientPhone, @JsonKey(name: 'address_details')  String? addressDetails, @JsonKey(name: 'design_ids')  List<int> designIds, @JsonKey(name: 'customer_note')  String? customerNote)  $default,) {final _that = this;
switch (_that) {
case _NewOrder():
return $default(_that.cityId,_that.items,_that.regionId,_that.customerShopId,_that.recipientName,_that.recipientPhone,_that.addressDetails,_that.designIds,_that.customerNote);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'city_id')  int cityId,  List<NewOrderLine> items, @JsonKey(name: 'region_id')  int? regionId, @JsonKey(name: 'customer_shop_id')  int? customerShopId, @JsonKey(name: 'recipient_name')  String? recipientName, @JsonKey(name: 'recipient_phone')  String? recipientPhone, @JsonKey(name: 'address_details')  String? addressDetails, @JsonKey(name: 'design_ids')  List<int> designIds, @JsonKey(name: 'customer_note')  String? customerNote)?  $default,) {final _that = this;
switch (_that) {
case _NewOrder() when $default != null:
return $default(_that.cityId,_that.items,_that.regionId,_that.customerShopId,_that.recipientName,_that.recipientPhone,_that.addressDetails,_that.designIds,_that.customerNote);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NewOrder implements NewOrder {
  const _NewOrder({@JsonKey(name: 'city_id') required this.cityId, required final  List<NewOrderLine> items, @JsonKey(name: 'region_id') this.regionId, @JsonKey(name: 'customer_shop_id') this.customerShopId, @JsonKey(name: 'recipient_name') this.recipientName, @JsonKey(name: 'recipient_phone') this.recipientPhone, @JsonKey(name: 'address_details') this.addressDetails, @JsonKey(name: 'design_ids') final  List<int> designIds = const <int>[], @JsonKey(name: 'customer_note') this.customerNote}): _items = items,_designIds = designIds;
  factory _NewOrder.fromJson(Map<String, dynamic> json) => _$NewOrderFromJson(json);

@override@JsonKey(name: 'city_id') final  int cityId;
 final  List<NewOrderLine> _items;
@override List<NewOrderLine> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey(name: 'region_id') final  int? regionId;
@override@JsonKey(name: 'customer_shop_id') final  int? customerShopId;
@override@JsonKey(name: 'recipient_name') final  String? recipientName;
@override@JsonKey(name: 'recipient_phone') final  String? recipientPhone;
@override@JsonKey(name: 'address_details') final  String? addressDetails;
 final  List<int> _designIds;
@override@JsonKey(name: 'design_ids') List<int> get designIds {
  if (_designIds is EqualUnmodifiableListView) return _designIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_designIds);
}

/// What the customer wants to say about the order. It lands in the order's note prefixed
/// «ملاحظة العميل:», so whoever reviews it can see at a glance whose words they are.
@override@JsonKey(name: 'customer_note') final  String? customerNote;

/// Create a copy of NewOrder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NewOrderCopyWith<_NewOrder> get copyWith => __$NewOrderCopyWithImpl<_NewOrder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NewOrderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NewOrder&&(identical(other.cityId, cityId) || other.cityId == cityId)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.regionId, regionId) || other.regionId == regionId)&&(identical(other.customerShopId, customerShopId) || other.customerShopId == customerShopId)&&(identical(other.recipientName, recipientName) || other.recipientName == recipientName)&&(identical(other.recipientPhone, recipientPhone) || other.recipientPhone == recipientPhone)&&(identical(other.addressDetails, addressDetails) || other.addressDetails == addressDetails)&&const DeepCollectionEquality().equals(other._designIds, _designIds)&&(identical(other.customerNote, customerNote) || other.customerNote == customerNote));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cityId,const DeepCollectionEquality().hash(_items),regionId,customerShopId,recipientName,recipientPhone,addressDetails,const DeepCollectionEquality().hash(_designIds),customerNote);

@override
String toString() {
  return 'NewOrder(cityId: $cityId, items: $items, regionId: $regionId, customerShopId: $customerShopId, recipientName: $recipientName, recipientPhone: $recipientPhone, addressDetails: $addressDetails, designIds: $designIds, customerNote: $customerNote)';
}


}

/// @nodoc
abstract mixin class _$NewOrderCopyWith<$Res> implements $NewOrderCopyWith<$Res> {
  factory _$NewOrderCopyWith(_NewOrder value, $Res Function(_NewOrder) _then) = __$NewOrderCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'city_id') int cityId, List<NewOrderLine> items,@JsonKey(name: 'region_id') int? regionId,@JsonKey(name: 'customer_shop_id') int? customerShopId,@JsonKey(name: 'recipient_name') String? recipientName,@JsonKey(name: 'recipient_phone') String? recipientPhone,@JsonKey(name: 'address_details') String? addressDetails,@JsonKey(name: 'design_ids') List<int> designIds,@JsonKey(name: 'customer_note') String? customerNote
});




}
/// @nodoc
class __$NewOrderCopyWithImpl<$Res>
    implements _$NewOrderCopyWith<$Res> {
  __$NewOrderCopyWithImpl(this._self, this._then);

  final _NewOrder _self;
  final $Res Function(_NewOrder) _then;

/// Create a copy of NewOrder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cityId = null,Object? items = null,Object? regionId = freezed,Object? customerShopId = freezed,Object? recipientName = freezed,Object? recipientPhone = freezed,Object? addressDetails = freezed,Object? designIds = null,Object? customerNote = freezed,}) {
  return _then(_NewOrder(
cityId: null == cityId ? _self.cityId : cityId // ignore: cast_nullable_to_non_nullable
as int,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<NewOrderLine>,regionId: freezed == regionId ? _self.regionId : regionId // ignore: cast_nullable_to_non_nullable
as int?,customerShopId: freezed == customerShopId ? _self.customerShopId : customerShopId // ignore: cast_nullable_to_non_nullable
as int?,recipientName: freezed == recipientName ? _self.recipientName : recipientName // ignore: cast_nullable_to_non_nullable
as String?,recipientPhone: freezed == recipientPhone ? _self.recipientPhone : recipientPhone // ignore: cast_nullable_to_non_nullable
as String?,addressDetails: freezed == addressDetails ? _self.addressDetails : addressDetails // ignore: cast_nullable_to_non_nullable
as String?,designIds: null == designIds ? _self._designIds : designIds // ignore: cast_nullable_to_non_nullable
as List<int>,customerNote: freezed == customerNote ? _self.customerNote : customerNote // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
