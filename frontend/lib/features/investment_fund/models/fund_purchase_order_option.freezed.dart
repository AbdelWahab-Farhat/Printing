// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fund_purchase_order_option.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FundPurchaseOrderOption {

 int get id; String? get vendor;@JsonKey(name: 'order_date') String? get orderDate;@JsonKey(name: 'received_on') String? get receivedOn;/// أسماءُ ما اشتراه الصندوقُ منه — ليُعرف دون أن يُفتح.
 List<String> get items;
/// Create a copy of FundPurchaseOrderOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FundPurchaseOrderOptionCopyWith<FundPurchaseOrderOption> get copyWith => _$FundPurchaseOrderOptionCopyWithImpl<FundPurchaseOrderOption>(this as FundPurchaseOrderOption, _$identity);

  /// Serializes this FundPurchaseOrderOption to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FundPurchaseOrderOption&&(identical(other.id, id) || other.id == id)&&(identical(other.vendor, vendor) || other.vendor == vendor)&&(identical(other.orderDate, orderDate) || other.orderDate == orderDate)&&(identical(other.receivedOn, receivedOn) || other.receivedOn == receivedOn)&&const DeepCollectionEquality().equals(other.items, items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,vendor,orderDate,receivedOn,const DeepCollectionEquality().hash(items));

@override
String toString() {
  return 'FundPurchaseOrderOption(id: $id, vendor: $vendor, orderDate: $orderDate, receivedOn: $receivedOn, items: $items)';
}


}

/// @nodoc
abstract mixin class $FundPurchaseOrderOptionCopyWith<$Res>  {
  factory $FundPurchaseOrderOptionCopyWith(FundPurchaseOrderOption value, $Res Function(FundPurchaseOrderOption) _then) = _$FundPurchaseOrderOptionCopyWithImpl;
@useResult
$Res call({
 int id, String? vendor,@JsonKey(name: 'order_date') String? orderDate,@JsonKey(name: 'received_on') String? receivedOn, List<String> items
});




}
/// @nodoc
class _$FundPurchaseOrderOptionCopyWithImpl<$Res>
    implements $FundPurchaseOrderOptionCopyWith<$Res> {
  _$FundPurchaseOrderOptionCopyWithImpl(this._self, this._then);

  final FundPurchaseOrderOption _self;
  final $Res Function(FundPurchaseOrderOption) _then;

/// Create a copy of FundPurchaseOrderOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? vendor = freezed,Object? orderDate = freezed,Object? receivedOn = freezed,Object? items = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,vendor: freezed == vendor ? _self.vendor : vendor // ignore: cast_nullable_to_non_nullable
as String?,orderDate: freezed == orderDate ? _self.orderDate : orderDate // ignore: cast_nullable_to_non_nullable
as String?,receivedOn: freezed == receivedOn ? _self.receivedOn : receivedOn // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [FundPurchaseOrderOption].
extension FundPurchaseOrderOptionPatterns on FundPurchaseOrderOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FundPurchaseOrderOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FundPurchaseOrderOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FundPurchaseOrderOption value)  $default,){
final _that = this;
switch (_that) {
case _FundPurchaseOrderOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FundPurchaseOrderOption value)?  $default,){
final _that = this;
switch (_that) {
case _FundPurchaseOrderOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String? vendor, @JsonKey(name: 'order_date')  String? orderDate, @JsonKey(name: 'received_on')  String? receivedOn,  List<String> items)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FundPurchaseOrderOption() when $default != null:
return $default(_that.id,_that.vendor,_that.orderDate,_that.receivedOn,_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String? vendor, @JsonKey(name: 'order_date')  String? orderDate, @JsonKey(name: 'received_on')  String? receivedOn,  List<String> items)  $default,) {final _that = this;
switch (_that) {
case _FundPurchaseOrderOption():
return $default(_that.id,_that.vendor,_that.orderDate,_that.receivedOn,_that.items);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String? vendor, @JsonKey(name: 'order_date')  String? orderDate, @JsonKey(name: 'received_on')  String? receivedOn,  List<String> items)?  $default,) {final _that = this;
switch (_that) {
case _FundPurchaseOrderOption() when $default != null:
return $default(_that.id,_that.vendor,_that.orderDate,_that.receivedOn,_that.items);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FundPurchaseOrderOption implements FundPurchaseOrderOption {
  const _FundPurchaseOrderOption({required this.id, this.vendor, @JsonKey(name: 'order_date') this.orderDate, @JsonKey(name: 'received_on') this.receivedOn, final  List<String> items = const <String>[]}): _items = items;
  factory _FundPurchaseOrderOption.fromJson(Map<String, dynamic> json) => _$FundPurchaseOrderOptionFromJson(json);

@override final  int id;
@override final  String? vendor;
@override@JsonKey(name: 'order_date') final  String? orderDate;
@override@JsonKey(name: 'received_on') final  String? receivedOn;
/// أسماءُ ما اشتراه الصندوقُ منه — ليُعرف دون أن يُفتح.
 final  List<String> _items;
/// أسماءُ ما اشتراه الصندوقُ منه — ليُعرف دون أن يُفتح.
@override@JsonKey() List<String> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of FundPurchaseOrderOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FundPurchaseOrderOptionCopyWith<_FundPurchaseOrderOption> get copyWith => __$FundPurchaseOrderOptionCopyWithImpl<_FundPurchaseOrderOption>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FundPurchaseOrderOptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FundPurchaseOrderOption&&(identical(other.id, id) || other.id == id)&&(identical(other.vendor, vendor) || other.vendor == vendor)&&(identical(other.orderDate, orderDate) || other.orderDate == orderDate)&&(identical(other.receivedOn, receivedOn) || other.receivedOn == receivedOn)&&const DeepCollectionEquality().equals(other._items, _items));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,vendor,orderDate,receivedOn,const DeepCollectionEquality().hash(_items));

@override
String toString() {
  return 'FundPurchaseOrderOption(id: $id, vendor: $vendor, orderDate: $orderDate, receivedOn: $receivedOn, items: $items)';
}


}

/// @nodoc
abstract mixin class _$FundPurchaseOrderOptionCopyWith<$Res> implements $FundPurchaseOrderOptionCopyWith<$Res> {
  factory _$FundPurchaseOrderOptionCopyWith(_FundPurchaseOrderOption value, $Res Function(_FundPurchaseOrderOption) _then) = __$FundPurchaseOrderOptionCopyWithImpl;
@override @useResult
$Res call({
 int id, String? vendor,@JsonKey(name: 'order_date') String? orderDate,@JsonKey(name: 'received_on') String? receivedOn, List<String> items
});




}
/// @nodoc
class __$FundPurchaseOrderOptionCopyWithImpl<$Res>
    implements _$FundPurchaseOrderOptionCopyWith<$Res> {
  __$FundPurchaseOrderOptionCopyWithImpl(this._self, this._then);

  final _FundPurchaseOrderOption _self;
  final $Res Function(_FundPurchaseOrderOption) _then;

/// Create a copy of FundPurchaseOrderOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? vendor = freezed,Object? orderDate = freezed,Object? receivedOn = freezed,Object? items = null,}) {
  return _then(_FundPurchaseOrderOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,vendor: freezed == vendor ? _self.vendor : vendor // ignore: cast_nullable_to_non_nullable
as String?,orderDate: freezed == orderDate ? _self.orderDate : orderDate // ignore: cast_nullable_to_non_nullable
as String?,receivedOn: freezed == receivedOn ? _self.receivedOn : receivedOn // ignore: cast_nullable_to_non_nullable
as String?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
