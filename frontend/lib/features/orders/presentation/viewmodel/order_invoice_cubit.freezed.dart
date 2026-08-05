// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_invoice_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InvoiceLine {

 int get id; int get productId; int get variantId; String get productName; String get variantLabel; String get pricingUnitLabel; String get unitPrice; String get quantity;
/// Create a copy of InvoiceLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvoiceLineCopyWith<InvoiceLine> get copyWith => _$InvoiceLineCopyWithImpl<InvoiceLine>(this as InvoiceLine, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvoiceLine&&(identical(other.id, id) || other.id == id)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.variantId, variantId) || other.variantId == variantId)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.variantLabel, variantLabel) || other.variantLabel == variantLabel)&&(identical(other.pricingUnitLabel, pricingUnitLabel) || other.pricingUnitLabel == pricingUnitLabel)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.quantity, quantity) || other.quantity == quantity));
}


@override
int get hashCode => Object.hash(runtimeType,id,productId,variantId,productName,variantLabel,pricingUnitLabel,unitPrice,quantity);

@override
String toString() {
  return 'InvoiceLine(id: $id, productId: $productId, variantId: $variantId, productName: $productName, variantLabel: $variantLabel, pricingUnitLabel: $pricingUnitLabel, unitPrice: $unitPrice, quantity: $quantity)';
}


}

/// @nodoc
abstract mixin class $InvoiceLineCopyWith<$Res>  {
  factory $InvoiceLineCopyWith(InvoiceLine value, $Res Function(InvoiceLine) _then) = _$InvoiceLineCopyWithImpl;
@useResult
$Res call({
 int id, int productId, int variantId, String productName, String variantLabel, String pricingUnitLabel, String unitPrice, String quantity
});




}
/// @nodoc
class _$InvoiceLineCopyWithImpl<$Res>
    implements $InvoiceLineCopyWith<$Res> {
  _$InvoiceLineCopyWithImpl(this._self, this._then);

  final InvoiceLine _self;
  final $Res Function(InvoiceLine) _then;

/// Create a copy of InvoiceLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? productId = null,Object? variantId = null,Object? productName = null,Object? variantLabel = null,Object? pricingUnitLabel = null,Object? unitPrice = null,Object? quantity = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as int,variantId: null == variantId ? _self.variantId : variantId // ignore: cast_nullable_to_non_nullable
as int,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,variantLabel: null == variantLabel ? _self.variantLabel : variantLabel // ignore: cast_nullable_to_non_nullable
as String,pricingUnitLabel: null == pricingUnitLabel ? _self.pricingUnitLabel : pricingUnitLabel // ignore: cast_nullable_to_non_nullable
as String,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [InvoiceLine].
extension InvoiceLinePatterns on InvoiceLine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InvoiceLine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InvoiceLine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InvoiceLine value)  $default,){
final _that = this;
switch (_that) {
case _InvoiceLine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InvoiceLine value)?  $default,){
final _that = this;
switch (_that) {
case _InvoiceLine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int productId,  int variantId,  String productName,  String variantLabel,  String pricingUnitLabel,  String unitPrice,  String quantity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InvoiceLine() when $default != null:
return $default(_that.id,_that.productId,_that.variantId,_that.productName,_that.variantLabel,_that.pricingUnitLabel,_that.unitPrice,_that.quantity);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int productId,  int variantId,  String productName,  String variantLabel,  String pricingUnitLabel,  String unitPrice,  String quantity)  $default,) {final _that = this;
switch (_that) {
case _InvoiceLine():
return $default(_that.id,_that.productId,_that.variantId,_that.productName,_that.variantLabel,_that.pricingUnitLabel,_that.unitPrice,_that.quantity);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int productId,  int variantId,  String productName,  String variantLabel,  String pricingUnitLabel,  String unitPrice,  String quantity)?  $default,) {final _that = this;
switch (_that) {
case _InvoiceLine() when $default != null:
return $default(_that.id,_that.productId,_that.variantId,_that.productName,_that.variantLabel,_that.pricingUnitLabel,_that.unitPrice,_that.quantity);case _:
  return null;

}
}

}

/// @nodoc


class _InvoiceLine extends InvoiceLine {
  const _InvoiceLine({required this.id, required this.productId, required this.variantId, required this.productName, required this.variantLabel, required this.pricingUnitLabel, required this.unitPrice, required this.quantity}): super._();
  

@override final  int id;
@override final  int productId;
@override final  int variantId;
@override final  String productName;
@override final  String variantLabel;
@override final  String pricingUnitLabel;
@override final  String unitPrice;
@override final  String quantity;

/// Create a copy of InvoiceLine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvoiceLineCopyWith<_InvoiceLine> get copyWith => __$InvoiceLineCopyWithImpl<_InvoiceLine>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvoiceLine&&(identical(other.id, id) || other.id == id)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.variantId, variantId) || other.variantId == variantId)&&(identical(other.productName, productName) || other.productName == productName)&&(identical(other.variantLabel, variantLabel) || other.variantLabel == variantLabel)&&(identical(other.pricingUnitLabel, pricingUnitLabel) || other.pricingUnitLabel == pricingUnitLabel)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.quantity, quantity) || other.quantity == quantity));
}


@override
int get hashCode => Object.hash(runtimeType,id,productId,variantId,productName,variantLabel,pricingUnitLabel,unitPrice,quantity);

@override
String toString() {
  return 'InvoiceLine(id: $id, productId: $productId, variantId: $variantId, productName: $productName, variantLabel: $variantLabel, pricingUnitLabel: $pricingUnitLabel, unitPrice: $unitPrice, quantity: $quantity)';
}


}

/// @nodoc
abstract mixin class _$InvoiceLineCopyWith<$Res> implements $InvoiceLineCopyWith<$Res> {
  factory _$InvoiceLineCopyWith(_InvoiceLine value, $Res Function(_InvoiceLine) _then) = __$InvoiceLineCopyWithImpl;
@override @useResult
$Res call({
 int id, int productId, int variantId, String productName, String variantLabel, String pricingUnitLabel, String unitPrice, String quantity
});




}
/// @nodoc
class __$InvoiceLineCopyWithImpl<$Res>
    implements _$InvoiceLineCopyWith<$Res> {
  __$InvoiceLineCopyWithImpl(this._self, this._then);

  final _InvoiceLine _self;
  final $Res Function(_InvoiceLine) _then;

/// Create a copy of InvoiceLine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? productId = null,Object? variantId = null,Object? productName = null,Object? variantLabel = null,Object? pricingUnitLabel = null,Object? unitPrice = null,Object? quantity = null,}) {
  return _then(_InvoiceLine(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as int,variantId: null == variantId ? _self.variantId : variantId // ignore: cast_nullable_to_non_nullable
as int,productName: null == productName ? _self.productName : productName // ignore: cast_nullable_to_non_nullable
as String,variantLabel: null == variantLabel ? _self.variantLabel : variantLabel // ignore: cast_nullable_to_non_nullable
as String,pricingUnitLabel: null == pricingUnitLabel ? _self.pricingUnitLabel : pricingUnitLabel // ignore: cast_nullable_to_non_nullable
as String,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$OrderInvoiceState {

 int get orderId; List<InvoiceLine> get lines; String get discount; String get designFee; String get deliveryPrice; bool get isSaving; bool get isSaved; bool get isDirty; Failure? get failure;
/// Create a copy of OrderInvoiceState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderInvoiceStateCopyWith<OrderInvoiceState> get copyWith => _$OrderInvoiceStateCopyWithImpl<OrderInvoiceState>(this as OrderInvoiceState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderInvoiceState&&(identical(other.orderId, orderId) || other.orderId == orderId)&&const DeepCollectionEquality().equals(other.lines, lines)&&(identical(other.discount, discount) || other.discount == discount)&&(identical(other.designFee, designFee) || other.designFee == designFee)&&(identical(other.deliveryPrice, deliveryPrice) || other.deliveryPrice == deliveryPrice)&&(identical(other.isSaving, isSaving) || other.isSaving == isSaving)&&(identical(other.isSaved, isSaved) || other.isSaved == isSaved)&&(identical(other.isDirty, isDirty) || other.isDirty == isDirty)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,orderId,const DeepCollectionEquality().hash(lines),discount,designFee,deliveryPrice,isSaving,isSaved,isDirty,failure);

@override
String toString() {
  return 'OrderInvoiceState(orderId: $orderId, lines: $lines, discount: $discount, designFee: $designFee, deliveryPrice: $deliveryPrice, isSaving: $isSaving, isSaved: $isSaved, isDirty: $isDirty, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $OrderInvoiceStateCopyWith<$Res>  {
  factory $OrderInvoiceStateCopyWith(OrderInvoiceState value, $Res Function(OrderInvoiceState) _then) = _$OrderInvoiceStateCopyWithImpl;
@useResult
$Res call({
 int orderId, List<InvoiceLine> lines, String discount, String designFee, String deliveryPrice, bool isSaving, bool isSaved, bool isDirty, Failure? failure
});


$FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class _$OrderInvoiceStateCopyWithImpl<$Res>
    implements $OrderInvoiceStateCopyWith<$Res> {
  _$OrderInvoiceStateCopyWithImpl(this._self, this._then);

  final OrderInvoiceState _self;
  final $Res Function(OrderInvoiceState) _then;

/// Create a copy of OrderInvoiceState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? orderId = null,Object? lines = null,Object? discount = null,Object? designFee = null,Object? deliveryPrice = null,Object? isSaving = null,Object? isSaved = null,Object? isDirty = null,Object? failure = freezed,}) {
  return _then(_self.copyWith(
orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as int,lines: null == lines ? _self.lines : lines // ignore: cast_nullable_to_non_nullable
as List<InvoiceLine>,discount: null == discount ? _self.discount : discount // ignore: cast_nullable_to_non_nullable
as String,designFee: null == designFee ? _self.designFee : designFee // ignore: cast_nullable_to_non_nullable
as String,deliveryPrice: null == deliveryPrice ? _self.deliveryPrice : deliveryPrice // ignore: cast_nullable_to_non_nullable
as String,isSaving: null == isSaving ? _self.isSaving : isSaving // ignore: cast_nullable_to_non_nullable
as bool,isSaved: null == isSaved ? _self.isSaved : isSaved // ignore: cast_nullable_to_non_nullable
as bool,isDirty: null == isDirty ? _self.isDirty : isDirty // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}
/// Create a copy of OrderInvoiceState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res>? get failure {
    if (_self.failure == null) {
    return null;
  }

  return $FailureCopyWith<$Res>(_self.failure!, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}


/// Adds pattern-matching-related methods to [OrderInvoiceState].
extension OrderInvoiceStatePatterns on OrderInvoiceState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderInvoiceState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderInvoiceState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderInvoiceState value)  $default,){
final _that = this;
switch (_that) {
case _OrderInvoiceState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderInvoiceState value)?  $default,){
final _that = this;
switch (_that) {
case _OrderInvoiceState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int orderId,  List<InvoiceLine> lines,  String discount,  String designFee,  String deliveryPrice,  bool isSaving,  bool isSaved,  bool isDirty,  Failure? failure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderInvoiceState() when $default != null:
return $default(_that.orderId,_that.lines,_that.discount,_that.designFee,_that.deliveryPrice,_that.isSaving,_that.isSaved,_that.isDirty,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int orderId,  List<InvoiceLine> lines,  String discount,  String designFee,  String deliveryPrice,  bool isSaving,  bool isSaved,  bool isDirty,  Failure? failure)  $default,) {final _that = this;
switch (_that) {
case _OrderInvoiceState():
return $default(_that.orderId,_that.lines,_that.discount,_that.designFee,_that.deliveryPrice,_that.isSaving,_that.isSaved,_that.isDirty,_that.failure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int orderId,  List<InvoiceLine> lines,  String discount,  String designFee,  String deliveryPrice,  bool isSaving,  bool isSaved,  bool isDirty,  Failure? failure)?  $default,) {final _that = this;
switch (_that) {
case _OrderInvoiceState() when $default != null:
return $default(_that.orderId,_that.lines,_that.discount,_that.designFee,_that.deliveryPrice,_that.isSaving,_that.isSaved,_that.isDirty,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _OrderInvoiceState extends OrderInvoiceState {
  const _OrderInvoiceState({required this.orderId, required final  List<InvoiceLine> lines, required this.discount, required this.designFee, required this.deliveryPrice, this.isSaving = false, this.isSaved = false, this.isDirty = false, this.failure}): _lines = lines,super._();
  

@override final  int orderId;
 final  List<InvoiceLine> _lines;
@override List<InvoiceLine> get lines {
  if (_lines is EqualUnmodifiableListView) return _lines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lines);
}

@override final  String discount;
@override final  String designFee;
@override final  String deliveryPrice;
@override@JsonKey() final  bool isSaving;
@override@JsonKey() final  bool isSaved;
@override@JsonKey() final  bool isDirty;
@override final  Failure? failure;

/// Create a copy of OrderInvoiceState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderInvoiceStateCopyWith<_OrderInvoiceState> get copyWith => __$OrderInvoiceStateCopyWithImpl<_OrderInvoiceState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderInvoiceState&&(identical(other.orderId, orderId) || other.orderId == orderId)&&const DeepCollectionEquality().equals(other._lines, _lines)&&(identical(other.discount, discount) || other.discount == discount)&&(identical(other.designFee, designFee) || other.designFee == designFee)&&(identical(other.deliveryPrice, deliveryPrice) || other.deliveryPrice == deliveryPrice)&&(identical(other.isSaving, isSaving) || other.isSaving == isSaving)&&(identical(other.isSaved, isSaved) || other.isSaved == isSaved)&&(identical(other.isDirty, isDirty) || other.isDirty == isDirty)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,orderId,const DeepCollectionEquality().hash(_lines),discount,designFee,deliveryPrice,isSaving,isSaved,isDirty,failure);

@override
String toString() {
  return 'OrderInvoiceState(orderId: $orderId, lines: $lines, discount: $discount, designFee: $designFee, deliveryPrice: $deliveryPrice, isSaving: $isSaving, isSaved: $isSaved, isDirty: $isDirty, failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$OrderInvoiceStateCopyWith<$Res> implements $OrderInvoiceStateCopyWith<$Res> {
  factory _$OrderInvoiceStateCopyWith(_OrderInvoiceState value, $Res Function(_OrderInvoiceState) _then) = __$OrderInvoiceStateCopyWithImpl;
@override @useResult
$Res call({
 int orderId, List<InvoiceLine> lines, String discount, String designFee, String deliveryPrice, bool isSaving, bool isSaved, bool isDirty, Failure? failure
});


@override $FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class __$OrderInvoiceStateCopyWithImpl<$Res>
    implements _$OrderInvoiceStateCopyWith<$Res> {
  __$OrderInvoiceStateCopyWithImpl(this._self, this._then);

  final _OrderInvoiceState _self;
  final $Res Function(_OrderInvoiceState) _then;

/// Create a copy of OrderInvoiceState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? orderId = null,Object? lines = null,Object? discount = null,Object? designFee = null,Object? deliveryPrice = null,Object? isSaving = null,Object? isSaved = null,Object? isDirty = null,Object? failure = freezed,}) {
  return _then(_OrderInvoiceState(
orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as int,lines: null == lines ? _self._lines : lines // ignore: cast_nullable_to_non_nullable
as List<InvoiceLine>,discount: null == discount ? _self.discount : discount // ignore: cast_nullable_to_non_nullable
as String,designFee: null == designFee ? _self.designFee : designFee // ignore: cast_nullable_to_non_nullable
as String,deliveryPrice: null == deliveryPrice ? _self.deliveryPrice : deliveryPrice // ignore: cast_nullable_to_non_nullable
as String,isSaving: null == isSaving ? _self.isSaving : isSaving // ignore: cast_nullable_to_non_nullable
as bool,isSaved: null == isSaved ? _self.isSaved : isSaved // ignore: cast_nullable_to_non_nullable
as bool,isDirty: null == isDirty ? _self.isDirty : isDirty // ignore: cast_nullable_to_non_nullable
as bool,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of OrderInvoiceState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res>? get failure {
    if (_self.failure == null) {
    return null;
  }

  return $FailureCopyWith<$Res>(_self.failure!, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

// dart format on
