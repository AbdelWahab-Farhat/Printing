// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fund_expense.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FundExpensePeriod {

 int get id; String get code; String get status;@JsonKey(name: 'status_label') String get statusLabel;
/// Create a copy of FundExpensePeriod
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FundExpensePeriodCopyWith<FundExpensePeriod> get copyWith => _$FundExpensePeriodCopyWithImpl<FundExpensePeriod>(this as FundExpensePeriod, _$identity);

  /// Serializes this FundExpensePeriod to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FundExpensePeriod&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,status,statusLabel);

@override
String toString() {
  return 'FundExpensePeriod(id: $id, code: $code, status: $status, statusLabel: $statusLabel)';
}


}

/// @nodoc
abstract mixin class $FundExpensePeriodCopyWith<$Res>  {
  factory $FundExpensePeriodCopyWith(FundExpensePeriod value, $Res Function(FundExpensePeriod) _then) = _$FundExpensePeriodCopyWithImpl;
@useResult
$Res call({
 int id, String code, String status,@JsonKey(name: 'status_label') String statusLabel
});




}
/// @nodoc
class _$FundExpensePeriodCopyWithImpl<$Res>
    implements $FundExpensePeriodCopyWith<$Res> {
  _$FundExpensePeriodCopyWithImpl(this._self, this._then);

  final FundExpensePeriod _self;
  final $Res Function(FundExpensePeriod) _then;

/// Create a copy of FundExpensePeriod
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? status = null,Object? statusLabel = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FundExpensePeriod].
extension FundExpensePeriodPatterns on FundExpensePeriod {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FundExpensePeriod value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FundExpensePeriod() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FundExpensePeriod value)  $default,){
final _that = this;
switch (_that) {
case _FundExpensePeriod():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FundExpensePeriod value)?  $default,){
final _that = this;
switch (_that) {
case _FundExpensePeriod() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String code,  String status, @JsonKey(name: 'status_label')  String statusLabel)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FundExpensePeriod() when $default != null:
return $default(_that.id,_that.code,_that.status,_that.statusLabel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String code,  String status, @JsonKey(name: 'status_label')  String statusLabel)  $default,) {final _that = this;
switch (_that) {
case _FundExpensePeriod():
return $default(_that.id,_that.code,_that.status,_that.statusLabel);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String code,  String status, @JsonKey(name: 'status_label')  String statusLabel)?  $default,) {final _that = this;
switch (_that) {
case _FundExpensePeriod() when $default != null:
return $default(_that.id,_that.code,_that.status,_that.statusLabel);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FundExpensePeriod implements FundExpensePeriod {
  const _FundExpensePeriod({required this.id, required this.code, required this.status, @JsonKey(name: 'status_label') required this.statusLabel});
  factory _FundExpensePeriod.fromJson(Map<String, dynamic> json) => _$FundExpensePeriodFromJson(json);

@override final  int id;
@override final  String code;
@override final  String status;
@override@JsonKey(name: 'status_label') final  String statusLabel;

/// Create a copy of FundExpensePeriod
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FundExpensePeriodCopyWith<_FundExpensePeriod> get copyWith => __$FundExpensePeriodCopyWithImpl<_FundExpensePeriod>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FundExpensePeriodToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FundExpensePeriod&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,status,statusLabel);

@override
String toString() {
  return 'FundExpensePeriod(id: $id, code: $code, status: $status, statusLabel: $statusLabel)';
}


}

/// @nodoc
abstract mixin class _$FundExpensePeriodCopyWith<$Res> implements $FundExpensePeriodCopyWith<$Res> {
  factory _$FundExpensePeriodCopyWith(_FundExpensePeriod value, $Res Function(_FundExpensePeriod) _then) = __$FundExpensePeriodCopyWithImpl;
@override @useResult
$Res call({
 int id, String code, String status,@JsonKey(name: 'status_label') String statusLabel
});




}
/// @nodoc
class __$FundExpensePeriodCopyWithImpl<$Res>
    implements _$FundExpensePeriodCopyWith<$Res> {
  __$FundExpensePeriodCopyWithImpl(this._self, this._then);

  final _FundExpensePeriod _self;
  final $Res Function(_FundExpensePeriod) _then;

/// Create a copy of FundExpensePeriod
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? status = null,Object? statusLabel = null,}) {
  return _then(_FundExpensePeriod(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$FundExpensePurchaseOrder {

 int get id;
/// Create a copy of FundExpensePurchaseOrder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FundExpensePurchaseOrderCopyWith<FundExpensePurchaseOrder> get copyWith => _$FundExpensePurchaseOrderCopyWithImpl<FundExpensePurchaseOrder>(this as FundExpensePurchaseOrder, _$identity);

  /// Serializes this FundExpensePurchaseOrder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FundExpensePurchaseOrder&&(identical(other.id, id) || other.id == id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'FundExpensePurchaseOrder(id: $id)';
}


}

/// @nodoc
abstract mixin class $FundExpensePurchaseOrderCopyWith<$Res>  {
  factory $FundExpensePurchaseOrderCopyWith(FundExpensePurchaseOrder value, $Res Function(FundExpensePurchaseOrder) _then) = _$FundExpensePurchaseOrderCopyWithImpl;
@useResult
$Res call({
 int id
});




}
/// @nodoc
class _$FundExpensePurchaseOrderCopyWithImpl<$Res>
    implements $FundExpensePurchaseOrderCopyWith<$Res> {
  _$FundExpensePurchaseOrderCopyWithImpl(this._self, this._then);

  final FundExpensePurchaseOrder _self;
  final $Res Function(FundExpensePurchaseOrder) _then;

/// Create a copy of FundExpensePurchaseOrder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [FundExpensePurchaseOrder].
extension FundExpensePurchaseOrderPatterns on FundExpensePurchaseOrder {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FundExpensePurchaseOrder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FundExpensePurchaseOrder() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FundExpensePurchaseOrder value)  $default,){
final _that = this;
switch (_that) {
case _FundExpensePurchaseOrder():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FundExpensePurchaseOrder value)?  $default,){
final _that = this;
switch (_that) {
case _FundExpensePurchaseOrder() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FundExpensePurchaseOrder() when $default != null:
return $default(_that.id);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id)  $default,) {final _that = this;
switch (_that) {
case _FundExpensePurchaseOrder():
return $default(_that.id);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id)?  $default,) {final _that = this;
switch (_that) {
case _FundExpensePurchaseOrder() when $default != null:
return $default(_that.id);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FundExpensePurchaseOrder implements FundExpensePurchaseOrder {
  const _FundExpensePurchaseOrder({required this.id});
  factory _FundExpensePurchaseOrder.fromJson(Map<String, dynamic> json) => _$FundExpensePurchaseOrderFromJson(json);

@override final  int id;

/// Create a copy of FundExpensePurchaseOrder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FundExpensePurchaseOrderCopyWith<_FundExpensePurchaseOrder> get copyWith => __$FundExpensePurchaseOrderCopyWithImpl<_FundExpensePurchaseOrder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FundExpensePurchaseOrderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FundExpensePurchaseOrder&&(identical(other.id, id) || other.id == id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'FundExpensePurchaseOrder(id: $id)';
}


}

/// @nodoc
abstract mixin class _$FundExpensePurchaseOrderCopyWith<$Res> implements $FundExpensePurchaseOrderCopyWith<$Res> {
  factory _$FundExpensePurchaseOrderCopyWith(_FundExpensePurchaseOrder value, $Res Function(_FundExpensePurchaseOrder) _then) = __$FundExpensePurchaseOrderCopyWithImpl;
@override @useResult
$Res call({
 int id
});




}
/// @nodoc
class __$FundExpensePurchaseOrderCopyWithImpl<$Res>
    implements _$FundExpensePurchaseOrderCopyWith<$Res> {
  __$FundExpensePurchaseOrderCopyWithImpl(this._self, this._then);

  final _FundExpensePurchaseOrder _self;
  final $Res Function(_FundExpensePurchaseOrder) _then;

/// Create a copy of FundExpensePurchaseOrder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(_FundExpensePurchaseOrder(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$FundExpenseSplit {

@JsonKey(name: 'on_goods') String get onGoods;@JsonKey(name: 'on_sales') String get onSales;
/// Create a copy of FundExpenseSplit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FundExpenseSplitCopyWith<FundExpenseSplit> get copyWith => _$FundExpenseSplitCopyWithImpl<FundExpenseSplit>(this as FundExpenseSplit, _$identity);

  /// Serializes this FundExpenseSplit to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FundExpenseSplit&&(identical(other.onGoods, onGoods) || other.onGoods == onGoods)&&(identical(other.onSales, onSales) || other.onSales == onSales));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,onGoods,onSales);

@override
String toString() {
  return 'FundExpenseSplit(onGoods: $onGoods, onSales: $onSales)';
}


}

/// @nodoc
abstract mixin class $FundExpenseSplitCopyWith<$Res>  {
  factory $FundExpenseSplitCopyWith(FundExpenseSplit value, $Res Function(FundExpenseSplit) _then) = _$FundExpenseSplitCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'on_goods') String onGoods,@JsonKey(name: 'on_sales') String onSales
});




}
/// @nodoc
class _$FundExpenseSplitCopyWithImpl<$Res>
    implements $FundExpenseSplitCopyWith<$Res> {
  _$FundExpenseSplitCopyWithImpl(this._self, this._then);

  final FundExpenseSplit _self;
  final $Res Function(FundExpenseSplit) _then;

/// Create a copy of FundExpenseSplit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? onGoods = null,Object? onSales = null,}) {
  return _then(_self.copyWith(
onGoods: null == onGoods ? _self.onGoods : onGoods // ignore: cast_nullable_to_non_nullable
as String,onSales: null == onSales ? _self.onSales : onSales // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FundExpenseSplit].
extension FundExpenseSplitPatterns on FundExpenseSplit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FundExpenseSplit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FundExpenseSplit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FundExpenseSplit value)  $default,){
final _that = this;
switch (_that) {
case _FundExpenseSplit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FundExpenseSplit value)?  $default,){
final _that = this;
switch (_that) {
case _FundExpenseSplit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'on_goods')  String onGoods, @JsonKey(name: 'on_sales')  String onSales)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FundExpenseSplit() when $default != null:
return $default(_that.onGoods,_that.onSales);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'on_goods')  String onGoods, @JsonKey(name: 'on_sales')  String onSales)  $default,) {final _that = this;
switch (_that) {
case _FundExpenseSplit():
return $default(_that.onGoods,_that.onSales);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'on_goods')  String onGoods, @JsonKey(name: 'on_sales')  String onSales)?  $default,) {final _that = this;
switch (_that) {
case _FundExpenseSplit() when $default != null:
return $default(_that.onGoods,_that.onSales);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FundExpenseSplit implements FundExpenseSplit {
  const _FundExpenseSplit({@JsonKey(name: 'on_goods') required this.onGoods, @JsonKey(name: 'on_sales') required this.onSales});
  factory _FundExpenseSplit.fromJson(Map<String, dynamic> json) => _$FundExpenseSplitFromJson(json);

@override@JsonKey(name: 'on_goods') final  String onGoods;
@override@JsonKey(name: 'on_sales') final  String onSales;

/// Create a copy of FundExpenseSplit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FundExpenseSplitCopyWith<_FundExpenseSplit> get copyWith => __$FundExpenseSplitCopyWithImpl<_FundExpenseSplit>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FundExpenseSplitToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FundExpenseSplit&&(identical(other.onGoods, onGoods) || other.onGoods == onGoods)&&(identical(other.onSales, onSales) || other.onSales == onSales));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,onGoods,onSales);

@override
String toString() {
  return 'FundExpenseSplit(onGoods: $onGoods, onSales: $onSales)';
}


}

/// @nodoc
abstract mixin class _$FundExpenseSplitCopyWith<$Res> implements $FundExpenseSplitCopyWith<$Res> {
  factory _$FundExpenseSplitCopyWith(_FundExpenseSplit value, $Res Function(_FundExpenseSplit) _then) = __$FundExpenseSplitCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'on_goods') String onGoods,@JsonKey(name: 'on_sales') String onSales
});




}
/// @nodoc
class __$FundExpenseSplitCopyWithImpl<$Res>
    implements _$FundExpenseSplitCopyWith<$Res> {
  __$FundExpenseSplitCopyWithImpl(this._self, this._then);

  final _FundExpenseSplit _self;
  final $Res Function(_FundExpenseSplit) _then;

/// Create a copy of FundExpenseSplit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? onGoods = null,Object? onSales = null,}) {
  return _then(_FundExpenseSplit(
onGoods: null == onGoods ? _self.onGoods : onGoods // ignore: cast_nullable_to_non_nullable
as String,onSales: null == onSales ? _self.onSales : onSales // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$FundExpense {

 int get id; String get kind;@JsonKey(name: 'kind_label') String get kindLabel; String get name; String get amount;@JsonKey(name: 'incurred_on') String? get incurredOn; String? get notes;@JsonKey(name: 'treasury_account') PeriodExpenseRef? get treasuryAccount;@JsonKey(name: 'recorded_by') PeriodExpenseRef? get recordedBy;/// `null` لمصروفٍ بتاريخٍ قبل أوّل فترة.
 FundExpensePeriod? get period; bool get counted;/// مؤرّخٌ في فترةٍ أُقفلت وسُجِّل بعد إقفالها — فحُمِّل على المفتوحة يومَ سُجِّل.
@JsonKey(name: 'recorded_after_close') bool get recordedAfterClose;@JsonKey(name: 'is_reversed') bool get isReversed; PeriodExpenseReversal? get reversal;/// مصروفٌ على البضاعة: `amount` ما وقع منه في الفترة المختارة، وكاملُه في [expenseAmount].
@JsonKey(name: 'expense_amount') String? get expenseAmount;@JsonKey(name: 'purchase_order') FundExpensePurchaseOrder? get purchaseOrder; FundExpenseSplit? get split;
/// Create a copy of FundExpense
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FundExpenseCopyWith<FundExpense> get copyWith => _$FundExpenseCopyWithImpl<FundExpense>(this as FundExpense, _$identity);

  /// Serializes this FundExpense to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FundExpense&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.kindLabel, kindLabel) || other.kindLabel == kindLabel)&&(identical(other.name, name) || other.name == name)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.incurredOn, incurredOn) || other.incurredOn == incurredOn)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.treasuryAccount, treasuryAccount) || other.treasuryAccount == treasuryAccount)&&(identical(other.recordedBy, recordedBy) || other.recordedBy == recordedBy)&&(identical(other.period, period) || other.period == period)&&(identical(other.counted, counted) || other.counted == counted)&&(identical(other.recordedAfterClose, recordedAfterClose) || other.recordedAfterClose == recordedAfterClose)&&(identical(other.isReversed, isReversed) || other.isReversed == isReversed)&&(identical(other.reversal, reversal) || other.reversal == reversal)&&(identical(other.expenseAmount, expenseAmount) || other.expenseAmount == expenseAmount)&&(identical(other.purchaseOrder, purchaseOrder) || other.purchaseOrder == purchaseOrder)&&(identical(other.split, split) || other.split == split));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,kindLabel,name,amount,incurredOn,notes,treasuryAccount,recordedBy,period,counted,recordedAfterClose,isReversed,reversal,expenseAmount,purchaseOrder,split);

@override
String toString() {
  return 'FundExpense(id: $id, kind: $kind, kindLabel: $kindLabel, name: $name, amount: $amount, incurredOn: $incurredOn, notes: $notes, treasuryAccount: $treasuryAccount, recordedBy: $recordedBy, period: $period, counted: $counted, recordedAfterClose: $recordedAfterClose, isReversed: $isReversed, reversal: $reversal, expenseAmount: $expenseAmount, purchaseOrder: $purchaseOrder, split: $split)';
}


}

/// @nodoc
abstract mixin class $FundExpenseCopyWith<$Res>  {
  factory $FundExpenseCopyWith(FundExpense value, $Res Function(FundExpense) _then) = _$FundExpenseCopyWithImpl;
@useResult
$Res call({
 int id, String kind,@JsonKey(name: 'kind_label') String kindLabel, String name, String amount,@JsonKey(name: 'incurred_on') String? incurredOn, String? notes,@JsonKey(name: 'treasury_account') PeriodExpenseRef? treasuryAccount,@JsonKey(name: 'recorded_by') PeriodExpenseRef? recordedBy, FundExpensePeriod? period, bool counted,@JsonKey(name: 'recorded_after_close') bool recordedAfterClose,@JsonKey(name: 'is_reversed') bool isReversed, PeriodExpenseReversal? reversal,@JsonKey(name: 'expense_amount') String? expenseAmount,@JsonKey(name: 'purchase_order') FundExpensePurchaseOrder? purchaseOrder, FundExpenseSplit? split
});


$PeriodExpenseRefCopyWith<$Res>? get treasuryAccount;$PeriodExpenseRefCopyWith<$Res>? get recordedBy;$FundExpensePeriodCopyWith<$Res>? get period;$PeriodExpenseReversalCopyWith<$Res>? get reversal;$FundExpensePurchaseOrderCopyWith<$Res>? get purchaseOrder;$FundExpenseSplitCopyWith<$Res>? get split;

}
/// @nodoc
class _$FundExpenseCopyWithImpl<$Res>
    implements $FundExpenseCopyWith<$Res> {
  _$FundExpenseCopyWithImpl(this._self, this._then);

  final FundExpense _self;
  final $Res Function(FundExpense) _then;

/// Create a copy of FundExpense
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? kindLabel = null,Object? name = null,Object? amount = null,Object? incurredOn = freezed,Object? notes = freezed,Object? treasuryAccount = freezed,Object? recordedBy = freezed,Object? period = freezed,Object? counted = null,Object? recordedAfterClose = null,Object? isReversed = null,Object? reversal = freezed,Object? expenseAmount = freezed,Object? purchaseOrder = freezed,Object? split = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,kindLabel: null == kindLabel ? _self.kindLabel : kindLabel // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,incurredOn: freezed == incurredOn ? _self.incurredOn : incurredOn // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,treasuryAccount: freezed == treasuryAccount ? _self.treasuryAccount : treasuryAccount // ignore: cast_nullable_to_non_nullable
as PeriodExpenseRef?,recordedBy: freezed == recordedBy ? _self.recordedBy : recordedBy // ignore: cast_nullable_to_non_nullable
as PeriodExpenseRef?,period: freezed == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as FundExpensePeriod?,counted: null == counted ? _self.counted : counted // ignore: cast_nullable_to_non_nullable
as bool,recordedAfterClose: null == recordedAfterClose ? _self.recordedAfterClose : recordedAfterClose // ignore: cast_nullable_to_non_nullable
as bool,isReversed: null == isReversed ? _self.isReversed : isReversed // ignore: cast_nullable_to_non_nullable
as bool,reversal: freezed == reversal ? _self.reversal : reversal // ignore: cast_nullable_to_non_nullable
as PeriodExpenseReversal?,expenseAmount: freezed == expenseAmount ? _self.expenseAmount : expenseAmount // ignore: cast_nullable_to_non_nullable
as String?,purchaseOrder: freezed == purchaseOrder ? _self.purchaseOrder : purchaseOrder // ignore: cast_nullable_to_non_nullable
as FundExpensePurchaseOrder?,split: freezed == split ? _self.split : split // ignore: cast_nullable_to_non_nullable
as FundExpenseSplit?,
  ));
}
/// Create a copy of FundExpense
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodExpenseRefCopyWith<$Res>? get treasuryAccount {
    if (_self.treasuryAccount == null) {
    return null;
  }

  return $PeriodExpenseRefCopyWith<$Res>(_self.treasuryAccount!, (value) {
    return _then(_self.copyWith(treasuryAccount: value));
  });
}/// Create a copy of FundExpense
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodExpenseRefCopyWith<$Res>? get recordedBy {
    if (_self.recordedBy == null) {
    return null;
  }

  return $PeriodExpenseRefCopyWith<$Res>(_self.recordedBy!, (value) {
    return _then(_self.copyWith(recordedBy: value));
  });
}/// Create a copy of FundExpense
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FundExpensePeriodCopyWith<$Res>? get period {
    if (_self.period == null) {
    return null;
  }

  return $FundExpensePeriodCopyWith<$Res>(_self.period!, (value) {
    return _then(_self.copyWith(period: value));
  });
}/// Create a copy of FundExpense
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodExpenseReversalCopyWith<$Res>? get reversal {
    if (_self.reversal == null) {
    return null;
  }

  return $PeriodExpenseReversalCopyWith<$Res>(_self.reversal!, (value) {
    return _then(_self.copyWith(reversal: value));
  });
}/// Create a copy of FundExpense
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FundExpensePurchaseOrderCopyWith<$Res>? get purchaseOrder {
    if (_self.purchaseOrder == null) {
    return null;
  }

  return $FundExpensePurchaseOrderCopyWith<$Res>(_self.purchaseOrder!, (value) {
    return _then(_self.copyWith(purchaseOrder: value));
  });
}/// Create a copy of FundExpense
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FundExpenseSplitCopyWith<$Res>? get split {
    if (_self.split == null) {
    return null;
  }

  return $FundExpenseSplitCopyWith<$Res>(_self.split!, (value) {
    return _then(_self.copyWith(split: value));
  });
}
}


/// Adds pattern-matching-related methods to [FundExpense].
extension FundExpensePatterns on FundExpense {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FundExpense value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FundExpense() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FundExpense value)  $default,){
final _that = this;
switch (_that) {
case _FundExpense():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FundExpense value)?  $default,){
final _that = this;
switch (_that) {
case _FundExpense() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String kind, @JsonKey(name: 'kind_label')  String kindLabel,  String name,  String amount, @JsonKey(name: 'incurred_on')  String? incurredOn,  String? notes, @JsonKey(name: 'treasury_account')  PeriodExpenseRef? treasuryAccount, @JsonKey(name: 'recorded_by')  PeriodExpenseRef? recordedBy,  FundExpensePeriod? period,  bool counted, @JsonKey(name: 'recorded_after_close')  bool recordedAfterClose, @JsonKey(name: 'is_reversed')  bool isReversed,  PeriodExpenseReversal? reversal, @JsonKey(name: 'expense_amount')  String? expenseAmount, @JsonKey(name: 'purchase_order')  FundExpensePurchaseOrder? purchaseOrder,  FundExpenseSplit? split)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FundExpense() when $default != null:
return $default(_that.id,_that.kind,_that.kindLabel,_that.name,_that.amount,_that.incurredOn,_that.notes,_that.treasuryAccount,_that.recordedBy,_that.period,_that.counted,_that.recordedAfterClose,_that.isReversed,_that.reversal,_that.expenseAmount,_that.purchaseOrder,_that.split);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String kind, @JsonKey(name: 'kind_label')  String kindLabel,  String name,  String amount, @JsonKey(name: 'incurred_on')  String? incurredOn,  String? notes, @JsonKey(name: 'treasury_account')  PeriodExpenseRef? treasuryAccount, @JsonKey(name: 'recorded_by')  PeriodExpenseRef? recordedBy,  FundExpensePeriod? period,  bool counted, @JsonKey(name: 'recorded_after_close')  bool recordedAfterClose, @JsonKey(name: 'is_reversed')  bool isReversed,  PeriodExpenseReversal? reversal, @JsonKey(name: 'expense_amount')  String? expenseAmount, @JsonKey(name: 'purchase_order')  FundExpensePurchaseOrder? purchaseOrder,  FundExpenseSplit? split)  $default,) {final _that = this;
switch (_that) {
case _FundExpense():
return $default(_that.id,_that.kind,_that.kindLabel,_that.name,_that.amount,_that.incurredOn,_that.notes,_that.treasuryAccount,_that.recordedBy,_that.period,_that.counted,_that.recordedAfterClose,_that.isReversed,_that.reversal,_that.expenseAmount,_that.purchaseOrder,_that.split);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String kind, @JsonKey(name: 'kind_label')  String kindLabel,  String name,  String amount, @JsonKey(name: 'incurred_on')  String? incurredOn,  String? notes, @JsonKey(name: 'treasury_account')  PeriodExpenseRef? treasuryAccount, @JsonKey(name: 'recorded_by')  PeriodExpenseRef? recordedBy,  FundExpensePeriod? period,  bool counted, @JsonKey(name: 'recorded_after_close')  bool recordedAfterClose, @JsonKey(name: 'is_reversed')  bool isReversed,  PeriodExpenseReversal? reversal, @JsonKey(name: 'expense_amount')  String? expenseAmount, @JsonKey(name: 'purchase_order')  FundExpensePurchaseOrder? purchaseOrder,  FundExpenseSplit? split)?  $default,) {final _that = this;
switch (_that) {
case _FundExpense() when $default != null:
return $default(_that.id,_that.kind,_that.kindLabel,_that.name,_that.amount,_that.incurredOn,_that.notes,_that.treasuryAccount,_that.recordedBy,_that.period,_that.counted,_that.recordedAfterClose,_that.isReversed,_that.reversal,_that.expenseAmount,_that.purchaseOrder,_that.split);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FundExpense implements FundExpense {
  const _FundExpense({required this.id, required this.kind, @JsonKey(name: 'kind_label') required this.kindLabel, required this.name, required this.amount, @JsonKey(name: 'incurred_on') this.incurredOn, this.notes, @JsonKey(name: 'treasury_account') this.treasuryAccount, @JsonKey(name: 'recorded_by') this.recordedBy, this.period, this.counted = true, @JsonKey(name: 'recorded_after_close') this.recordedAfterClose = false, @JsonKey(name: 'is_reversed') this.isReversed = false, this.reversal, @JsonKey(name: 'expense_amount') this.expenseAmount, @JsonKey(name: 'purchase_order') this.purchaseOrder, this.split});
  factory _FundExpense.fromJson(Map<String, dynamic> json) => _$FundExpenseFromJson(json);

@override final  int id;
@override final  String kind;
@override@JsonKey(name: 'kind_label') final  String kindLabel;
@override final  String name;
@override final  String amount;
@override@JsonKey(name: 'incurred_on') final  String? incurredOn;
@override final  String? notes;
@override@JsonKey(name: 'treasury_account') final  PeriodExpenseRef? treasuryAccount;
@override@JsonKey(name: 'recorded_by') final  PeriodExpenseRef? recordedBy;
/// `null` لمصروفٍ بتاريخٍ قبل أوّل فترة.
@override final  FundExpensePeriod? period;
@override@JsonKey() final  bool counted;
/// مؤرّخٌ في فترةٍ أُقفلت وسُجِّل بعد إقفالها — فحُمِّل على المفتوحة يومَ سُجِّل.
@override@JsonKey(name: 'recorded_after_close') final  bool recordedAfterClose;
@override@JsonKey(name: 'is_reversed') final  bool isReversed;
@override final  PeriodExpenseReversal? reversal;
/// مصروفٌ على البضاعة: `amount` ما وقع منه في الفترة المختارة، وكاملُه في [expenseAmount].
@override@JsonKey(name: 'expense_amount') final  String? expenseAmount;
@override@JsonKey(name: 'purchase_order') final  FundExpensePurchaseOrder? purchaseOrder;
@override final  FundExpenseSplit? split;

/// Create a copy of FundExpense
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FundExpenseCopyWith<_FundExpense> get copyWith => __$FundExpenseCopyWithImpl<_FundExpense>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FundExpenseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FundExpense&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.kindLabel, kindLabel) || other.kindLabel == kindLabel)&&(identical(other.name, name) || other.name == name)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.incurredOn, incurredOn) || other.incurredOn == incurredOn)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.treasuryAccount, treasuryAccount) || other.treasuryAccount == treasuryAccount)&&(identical(other.recordedBy, recordedBy) || other.recordedBy == recordedBy)&&(identical(other.period, period) || other.period == period)&&(identical(other.counted, counted) || other.counted == counted)&&(identical(other.recordedAfterClose, recordedAfterClose) || other.recordedAfterClose == recordedAfterClose)&&(identical(other.isReversed, isReversed) || other.isReversed == isReversed)&&(identical(other.reversal, reversal) || other.reversal == reversal)&&(identical(other.expenseAmount, expenseAmount) || other.expenseAmount == expenseAmount)&&(identical(other.purchaseOrder, purchaseOrder) || other.purchaseOrder == purchaseOrder)&&(identical(other.split, split) || other.split == split));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,kindLabel,name,amount,incurredOn,notes,treasuryAccount,recordedBy,period,counted,recordedAfterClose,isReversed,reversal,expenseAmount,purchaseOrder,split);

@override
String toString() {
  return 'FundExpense(id: $id, kind: $kind, kindLabel: $kindLabel, name: $name, amount: $amount, incurredOn: $incurredOn, notes: $notes, treasuryAccount: $treasuryAccount, recordedBy: $recordedBy, period: $period, counted: $counted, recordedAfterClose: $recordedAfterClose, isReversed: $isReversed, reversal: $reversal, expenseAmount: $expenseAmount, purchaseOrder: $purchaseOrder, split: $split)';
}


}

/// @nodoc
abstract mixin class _$FundExpenseCopyWith<$Res> implements $FundExpenseCopyWith<$Res> {
  factory _$FundExpenseCopyWith(_FundExpense value, $Res Function(_FundExpense) _then) = __$FundExpenseCopyWithImpl;
@override @useResult
$Res call({
 int id, String kind,@JsonKey(name: 'kind_label') String kindLabel, String name, String amount,@JsonKey(name: 'incurred_on') String? incurredOn, String? notes,@JsonKey(name: 'treasury_account') PeriodExpenseRef? treasuryAccount,@JsonKey(name: 'recorded_by') PeriodExpenseRef? recordedBy, FundExpensePeriod? period, bool counted,@JsonKey(name: 'recorded_after_close') bool recordedAfterClose,@JsonKey(name: 'is_reversed') bool isReversed, PeriodExpenseReversal? reversal,@JsonKey(name: 'expense_amount') String? expenseAmount,@JsonKey(name: 'purchase_order') FundExpensePurchaseOrder? purchaseOrder, FundExpenseSplit? split
});


@override $PeriodExpenseRefCopyWith<$Res>? get treasuryAccount;@override $PeriodExpenseRefCopyWith<$Res>? get recordedBy;@override $FundExpensePeriodCopyWith<$Res>? get period;@override $PeriodExpenseReversalCopyWith<$Res>? get reversal;@override $FundExpensePurchaseOrderCopyWith<$Res>? get purchaseOrder;@override $FundExpenseSplitCopyWith<$Res>? get split;

}
/// @nodoc
class __$FundExpenseCopyWithImpl<$Res>
    implements _$FundExpenseCopyWith<$Res> {
  __$FundExpenseCopyWithImpl(this._self, this._then);

  final _FundExpense _self;
  final $Res Function(_FundExpense) _then;

/// Create a copy of FundExpense
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? kindLabel = null,Object? name = null,Object? amount = null,Object? incurredOn = freezed,Object? notes = freezed,Object? treasuryAccount = freezed,Object? recordedBy = freezed,Object? period = freezed,Object? counted = null,Object? recordedAfterClose = null,Object? isReversed = null,Object? reversal = freezed,Object? expenseAmount = freezed,Object? purchaseOrder = freezed,Object? split = freezed,}) {
  return _then(_FundExpense(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,kindLabel: null == kindLabel ? _self.kindLabel : kindLabel // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,incurredOn: freezed == incurredOn ? _self.incurredOn : incurredOn // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,treasuryAccount: freezed == treasuryAccount ? _self.treasuryAccount : treasuryAccount // ignore: cast_nullable_to_non_nullable
as PeriodExpenseRef?,recordedBy: freezed == recordedBy ? _self.recordedBy : recordedBy // ignore: cast_nullable_to_non_nullable
as PeriodExpenseRef?,period: freezed == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as FundExpensePeriod?,counted: null == counted ? _self.counted : counted // ignore: cast_nullable_to_non_nullable
as bool,recordedAfterClose: null == recordedAfterClose ? _self.recordedAfterClose : recordedAfterClose // ignore: cast_nullable_to_non_nullable
as bool,isReversed: null == isReversed ? _self.isReversed : isReversed // ignore: cast_nullable_to_non_nullable
as bool,reversal: freezed == reversal ? _self.reversal : reversal // ignore: cast_nullable_to_non_nullable
as PeriodExpenseReversal?,expenseAmount: freezed == expenseAmount ? _self.expenseAmount : expenseAmount // ignore: cast_nullable_to_non_nullable
as String?,purchaseOrder: freezed == purchaseOrder ? _self.purchaseOrder : purchaseOrder // ignore: cast_nullable_to_non_nullable
as FundExpensePurchaseOrder?,split: freezed == split ? _self.split : split // ignore: cast_nullable_to_non_nullable
as FundExpenseSplit?,
  ));
}

/// Create a copy of FundExpense
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodExpenseRefCopyWith<$Res>? get treasuryAccount {
    if (_self.treasuryAccount == null) {
    return null;
  }

  return $PeriodExpenseRefCopyWith<$Res>(_self.treasuryAccount!, (value) {
    return _then(_self.copyWith(treasuryAccount: value));
  });
}/// Create a copy of FundExpense
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodExpenseRefCopyWith<$Res>? get recordedBy {
    if (_self.recordedBy == null) {
    return null;
  }

  return $PeriodExpenseRefCopyWith<$Res>(_self.recordedBy!, (value) {
    return _then(_self.copyWith(recordedBy: value));
  });
}/// Create a copy of FundExpense
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FundExpensePeriodCopyWith<$Res>? get period {
    if (_self.period == null) {
    return null;
  }

  return $FundExpensePeriodCopyWith<$Res>(_self.period!, (value) {
    return _then(_self.copyWith(period: value));
  });
}/// Create a copy of FundExpense
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodExpenseReversalCopyWith<$Res>? get reversal {
    if (_self.reversal == null) {
    return null;
  }

  return $PeriodExpenseReversalCopyWith<$Res>(_self.reversal!, (value) {
    return _then(_self.copyWith(reversal: value));
  });
}/// Create a copy of FundExpense
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FundExpensePurchaseOrderCopyWith<$Res>? get purchaseOrder {
    if (_self.purchaseOrder == null) {
    return null;
  }

  return $FundExpensePurchaseOrderCopyWith<$Res>(_self.purchaseOrder!, (value) {
    return _then(_self.copyWith(purchaseOrder: value));
  });
}/// Create a copy of FundExpense
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FundExpenseSplitCopyWith<$Res>? get split {
    if (_self.split == null) {
    return null;
  }

  return $FundExpenseSplitCopyWith<$Res>(_self.split!, (value) {
    return _then(_self.copyWith(split: value));
  });
}
}

// dart format on
