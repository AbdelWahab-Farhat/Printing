// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'investment_pool.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InvestmentPool {

 int get id; String get code; String get name;/// Always `pool` on this model — a legacy صفقة can never be reached through a pool route,
/// because the server binds `{pool}` to `kind = 'pool'`. Carried anyway so a screen showing
/// both kinds in one list has the word rather than an inference.
 String get kind;@JsonKey(name: 'kind_label') String get kindLabel;/// The investors' share of this pool's net profit. Given once when the pool is opened and
/// not editable after: it is the term the partners were shown.
@JsonKey(name: 'investor_profit_share_percent') String get investorProfitSharePercent;/// The shelves this pool buys. **Each belongs to exactly one pool**, guaranteed by a unique
/// index rather than by a rule anybody has to remember — which is why the purchase screen
/// never asks who is financing a line.
@JsonKey(name: 'stock_items') List<PoolStockItem> get stockItems; List<PoolMember> get investors;/// Whether capital offered right now would work this period or wait for the next.
///
/// Null off the list, which does not walk it. Read it **before** showing the capital form:
/// it is answered by the same function that then acts on the request, so the warning and the
/// behaviour cannot drift apart.
@JsonKey(name: 'capital_timing') CapitalTiming? get capitalTiming;@JsonKey(name: 'opened_on') String? get openedOn; String? get notes;
/// Create a copy of InvestmentPool
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvestmentPoolCopyWith<InvestmentPool> get copyWith => _$InvestmentPoolCopyWithImpl<InvestmentPool>(this as InvestmentPool, _$identity);

  /// Serializes this InvestmentPool to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestmentPool&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.kindLabel, kindLabel) || other.kindLabel == kindLabel)&&(identical(other.investorProfitSharePercent, investorProfitSharePercent) || other.investorProfitSharePercent == investorProfitSharePercent)&&const DeepCollectionEquality().equals(other.stockItems, stockItems)&&const DeepCollectionEquality().equals(other.investors, investors)&&(identical(other.capitalTiming, capitalTiming) || other.capitalTiming == capitalTiming)&&(identical(other.openedOn, openedOn) || other.openedOn == openedOn)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name,kind,kindLabel,investorProfitSharePercent,const DeepCollectionEquality().hash(stockItems),const DeepCollectionEquality().hash(investors),capitalTiming,openedOn,notes);

@override
String toString() {
  return 'InvestmentPool(id: $id, code: $code, name: $name, kind: $kind, kindLabel: $kindLabel, investorProfitSharePercent: $investorProfitSharePercent, stockItems: $stockItems, investors: $investors, capitalTiming: $capitalTiming, openedOn: $openedOn, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $InvestmentPoolCopyWith<$Res>  {
  factory $InvestmentPoolCopyWith(InvestmentPool value, $Res Function(InvestmentPool) _then) = _$InvestmentPoolCopyWithImpl;
@useResult
$Res call({
 int id, String code, String name, String kind,@JsonKey(name: 'kind_label') String kindLabel,@JsonKey(name: 'investor_profit_share_percent') String investorProfitSharePercent,@JsonKey(name: 'stock_items') List<PoolStockItem> stockItems, List<PoolMember> investors,@JsonKey(name: 'capital_timing') CapitalTiming? capitalTiming,@JsonKey(name: 'opened_on') String? openedOn, String? notes
});


$CapitalTimingCopyWith<$Res>? get capitalTiming;

}
/// @nodoc
class _$InvestmentPoolCopyWithImpl<$Res>
    implements $InvestmentPoolCopyWith<$Res> {
  _$InvestmentPoolCopyWithImpl(this._self, this._then);

  final InvestmentPool _self;
  final $Res Function(InvestmentPool) _then;

/// Create a copy of InvestmentPool
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? name = null,Object? kind = null,Object? kindLabel = null,Object? investorProfitSharePercent = null,Object? stockItems = null,Object? investors = null,Object? capitalTiming = freezed,Object? openedOn = freezed,Object? notes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,kindLabel: null == kindLabel ? _self.kindLabel : kindLabel // ignore: cast_nullable_to_non_nullable
as String,investorProfitSharePercent: null == investorProfitSharePercent ? _self.investorProfitSharePercent : investorProfitSharePercent // ignore: cast_nullable_to_non_nullable
as String,stockItems: null == stockItems ? _self.stockItems : stockItems // ignore: cast_nullable_to_non_nullable
as List<PoolStockItem>,investors: null == investors ? _self.investors : investors // ignore: cast_nullable_to_non_nullable
as List<PoolMember>,capitalTiming: freezed == capitalTiming ? _self.capitalTiming : capitalTiming // ignore: cast_nullable_to_non_nullable
as CapitalTiming?,openedOn: freezed == openedOn ? _self.openedOn : openedOn // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of InvestmentPool
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CapitalTimingCopyWith<$Res>? get capitalTiming {
    if (_self.capitalTiming == null) {
    return null;
  }

  return $CapitalTimingCopyWith<$Res>(_self.capitalTiming!, (value) {
    return _then(_self.copyWith(capitalTiming: value));
  });
}
}


/// Adds pattern-matching-related methods to [InvestmentPool].
extension InvestmentPoolPatterns on InvestmentPool {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InvestmentPool value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InvestmentPool() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InvestmentPool value)  $default,){
final _that = this;
switch (_that) {
case _InvestmentPool():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InvestmentPool value)?  $default,){
final _that = this;
switch (_that) {
case _InvestmentPool() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String code,  String name,  String kind, @JsonKey(name: 'kind_label')  String kindLabel, @JsonKey(name: 'investor_profit_share_percent')  String investorProfitSharePercent, @JsonKey(name: 'stock_items')  List<PoolStockItem> stockItems,  List<PoolMember> investors, @JsonKey(name: 'capital_timing')  CapitalTiming? capitalTiming, @JsonKey(name: 'opened_on')  String? openedOn,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InvestmentPool() when $default != null:
return $default(_that.id,_that.code,_that.name,_that.kind,_that.kindLabel,_that.investorProfitSharePercent,_that.stockItems,_that.investors,_that.capitalTiming,_that.openedOn,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String code,  String name,  String kind, @JsonKey(name: 'kind_label')  String kindLabel, @JsonKey(name: 'investor_profit_share_percent')  String investorProfitSharePercent, @JsonKey(name: 'stock_items')  List<PoolStockItem> stockItems,  List<PoolMember> investors, @JsonKey(name: 'capital_timing')  CapitalTiming? capitalTiming, @JsonKey(name: 'opened_on')  String? openedOn,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _InvestmentPool():
return $default(_that.id,_that.code,_that.name,_that.kind,_that.kindLabel,_that.investorProfitSharePercent,_that.stockItems,_that.investors,_that.capitalTiming,_that.openedOn,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String code,  String name,  String kind, @JsonKey(name: 'kind_label')  String kindLabel, @JsonKey(name: 'investor_profit_share_percent')  String investorProfitSharePercent, @JsonKey(name: 'stock_items')  List<PoolStockItem> stockItems,  List<PoolMember> investors, @JsonKey(name: 'capital_timing')  CapitalTiming? capitalTiming, @JsonKey(name: 'opened_on')  String? openedOn,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _InvestmentPool() when $default != null:
return $default(_that.id,_that.code,_that.name,_that.kind,_that.kindLabel,_that.investorProfitSharePercent,_that.stockItems,_that.investors,_that.capitalTiming,_that.openedOn,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InvestmentPool implements InvestmentPool {
  const _InvestmentPool({required this.id, required this.code, required this.name, this.kind = 'pool', @JsonKey(name: 'kind_label') this.kindLabel = 'صندوق', @JsonKey(name: 'investor_profit_share_percent') required this.investorProfitSharePercent, @JsonKey(name: 'stock_items') final  List<PoolStockItem> stockItems = const <PoolStockItem>[], final  List<PoolMember> investors = const <PoolMember>[], @JsonKey(name: 'capital_timing') this.capitalTiming, @JsonKey(name: 'opened_on') this.openedOn, this.notes}): _stockItems = stockItems,_investors = investors;
  factory _InvestmentPool.fromJson(Map<String, dynamic> json) => _$InvestmentPoolFromJson(json);

@override final  int id;
@override final  String code;
@override final  String name;
/// Always `pool` on this model — a legacy صفقة can never be reached through a pool route,
/// because the server binds `{pool}` to `kind = 'pool'`. Carried anyway so a screen showing
/// both kinds in one list has the word rather than an inference.
@override@JsonKey() final  String kind;
@override@JsonKey(name: 'kind_label') final  String kindLabel;
/// The investors' share of this pool's net profit. Given once when the pool is opened and
/// not editable after: it is the term the partners were shown.
@override@JsonKey(name: 'investor_profit_share_percent') final  String investorProfitSharePercent;
/// The shelves this pool buys. **Each belongs to exactly one pool**, guaranteed by a unique
/// index rather than by a rule anybody has to remember — which is why the purchase screen
/// never asks who is financing a line.
 final  List<PoolStockItem> _stockItems;
/// The shelves this pool buys. **Each belongs to exactly one pool**, guaranteed by a unique
/// index rather than by a rule anybody has to remember — which is why the purchase screen
/// never asks who is financing a line.
@override@JsonKey(name: 'stock_items') List<PoolStockItem> get stockItems {
  if (_stockItems is EqualUnmodifiableListView) return _stockItems;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_stockItems);
}

 final  List<PoolMember> _investors;
@override@JsonKey() List<PoolMember> get investors {
  if (_investors is EqualUnmodifiableListView) return _investors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_investors);
}

/// Whether capital offered right now would work this period or wait for the next.
///
/// Null off the list, which does not walk it. Read it **before** showing the capital form:
/// it is answered by the same function that then acts on the request, so the warning and the
/// behaviour cannot drift apart.
@override@JsonKey(name: 'capital_timing') final  CapitalTiming? capitalTiming;
@override@JsonKey(name: 'opened_on') final  String? openedOn;
@override final  String? notes;

/// Create a copy of InvestmentPool
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InvestmentPoolCopyWith<_InvestmentPool> get copyWith => __$InvestmentPoolCopyWithImpl<_InvestmentPool>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InvestmentPoolToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InvestmentPool&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.kindLabel, kindLabel) || other.kindLabel == kindLabel)&&(identical(other.investorProfitSharePercent, investorProfitSharePercent) || other.investorProfitSharePercent == investorProfitSharePercent)&&const DeepCollectionEquality().equals(other._stockItems, _stockItems)&&const DeepCollectionEquality().equals(other._investors, _investors)&&(identical(other.capitalTiming, capitalTiming) || other.capitalTiming == capitalTiming)&&(identical(other.openedOn, openedOn) || other.openedOn == openedOn)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name,kind,kindLabel,investorProfitSharePercent,const DeepCollectionEquality().hash(_stockItems),const DeepCollectionEquality().hash(_investors),capitalTiming,openedOn,notes);

@override
String toString() {
  return 'InvestmentPool(id: $id, code: $code, name: $name, kind: $kind, kindLabel: $kindLabel, investorProfitSharePercent: $investorProfitSharePercent, stockItems: $stockItems, investors: $investors, capitalTiming: $capitalTiming, openedOn: $openedOn, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$InvestmentPoolCopyWith<$Res> implements $InvestmentPoolCopyWith<$Res> {
  factory _$InvestmentPoolCopyWith(_InvestmentPool value, $Res Function(_InvestmentPool) _then) = __$InvestmentPoolCopyWithImpl;
@override @useResult
$Res call({
 int id, String code, String name, String kind,@JsonKey(name: 'kind_label') String kindLabel,@JsonKey(name: 'investor_profit_share_percent') String investorProfitSharePercent,@JsonKey(name: 'stock_items') List<PoolStockItem> stockItems, List<PoolMember> investors,@JsonKey(name: 'capital_timing') CapitalTiming? capitalTiming,@JsonKey(name: 'opened_on') String? openedOn, String? notes
});


@override $CapitalTimingCopyWith<$Res>? get capitalTiming;

}
/// @nodoc
class __$InvestmentPoolCopyWithImpl<$Res>
    implements _$InvestmentPoolCopyWith<$Res> {
  __$InvestmentPoolCopyWithImpl(this._self, this._then);

  final _InvestmentPool _self;
  final $Res Function(_InvestmentPool) _then;

/// Create a copy of InvestmentPool
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? name = null,Object? kind = null,Object? kindLabel = null,Object? investorProfitSharePercent = null,Object? stockItems = null,Object? investors = null,Object? capitalTiming = freezed,Object? openedOn = freezed,Object? notes = freezed,}) {
  return _then(_InvestmentPool(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,kindLabel: null == kindLabel ? _self.kindLabel : kindLabel // ignore: cast_nullable_to_non_nullable
as String,investorProfitSharePercent: null == investorProfitSharePercent ? _self.investorProfitSharePercent : investorProfitSharePercent // ignore: cast_nullable_to_non_nullable
as String,stockItems: null == stockItems ? _self._stockItems : stockItems // ignore: cast_nullable_to_non_nullable
as List<PoolStockItem>,investors: null == investors ? _self._investors : investors // ignore: cast_nullable_to_non_nullable
as List<PoolMember>,capitalTiming: freezed == capitalTiming ? _self.capitalTiming : capitalTiming // ignore: cast_nullable_to_non_nullable
as CapitalTiming?,openedOn: freezed == openedOn ? _self.openedOn : openedOn // ignore: cast_nullable_to_non_nullable
as String?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of InvestmentPool
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CapitalTimingCopyWith<$Res>? get capitalTiming {
    if (_self.capitalTiming == null) {
    return null;
  }

  return $CapitalTimingCopyWith<$Res>(_self.capitalTiming!, (value) {
    return _then(_self.copyWith(capitalTiming: value));
  });
}
}


/// @nodoc
mixin _$PoolStockItem {

@JsonKey(name: 'stock_item_id') int get stockItemId; String? get name;
/// Create a copy of PoolStockItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PoolStockItemCopyWith<PoolStockItem> get copyWith => _$PoolStockItemCopyWithImpl<PoolStockItem>(this as PoolStockItem, _$identity);

  /// Serializes this PoolStockItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PoolStockItem&&(identical(other.stockItemId, stockItemId) || other.stockItemId == stockItemId)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,stockItemId,name);

@override
String toString() {
  return 'PoolStockItem(stockItemId: $stockItemId, name: $name)';
}


}

/// @nodoc
abstract mixin class $PoolStockItemCopyWith<$Res>  {
  factory $PoolStockItemCopyWith(PoolStockItem value, $Res Function(PoolStockItem) _then) = _$PoolStockItemCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'stock_item_id') int stockItemId, String? name
});




}
/// @nodoc
class _$PoolStockItemCopyWithImpl<$Res>
    implements $PoolStockItemCopyWith<$Res> {
  _$PoolStockItemCopyWithImpl(this._self, this._then);

  final PoolStockItem _self;
  final $Res Function(PoolStockItem) _then;

/// Create a copy of PoolStockItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? stockItemId = null,Object? name = freezed,}) {
  return _then(_self.copyWith(
stockItemId: null == stockItemId ? _self.stockItemId : stockItemId // ignore: cast_nullable_to_non_nullable
as int,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PoolStockItem].
extension PoolStockItemPatterns on PoolStockItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PoolStockItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PoolStockItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PoolStockItem value)  $default,){
final _that = this;
switch (_that) {
case _PoolStockItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PoolStockItem value)?  $default,){
final _that = this;
switch (_that) {
case _PoolStockItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'stock_item_id')  int stockItemId,  String? name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PoolStockItem() when $default != null:
return $default(_that.stockItemId,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'stock_item_id')  int stockItemId,  String? name)  $default,) {final _that = this;
switch (_that) {
case _PoolStockItem():
return $default(_that.stockItemId,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'stock_item_id')  int stockItemId,  String? name)?  $default,) {final _that = this;
switch (_that) {
case _PoolStockItem() when $default != null:
return $default(_that.stockItemId,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PoolStockItem implements PoolStockItem {
  const _PoolStockItem({@JsonKey(name: 'stock_item_id') required this.stockItemId, this.name});
  factory _PoolStockItem.fromJson(Map<String, dynamic> json) => _$PoolStockItemFromJson(json);

@override@JsonKey(name: 'stock_item_id') final  int stockItemId;
@override final  String? name;

/// Create a copy of PoolStockItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PoolStockItemCopyWith<_PoolStockItem> get copyWith => __$PoolStockItemCopyWithImpl<_PoolStockItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PoolStockItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PoolStockItem&&(identical(other.stockItemId, stockItemId) || other.stockItemId == stockItemId)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,stockItemId,name);

@override
String toString() {
  return 'PoolStockItem(stockItemId: $stockItemId, name: $name)';
}


}

/// @nodoc
abstract mixin class _$PoolStockItemCopyWith<$Res> implements $PoolStockItemCopyWith<$Res> {
  factory _$PoolStockItemCopyWith(_PoolStockItem value, $Res Function(_PoolStockItem) _then) = __$PoolStockItemCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'stock_item_id') int stockItemId, String? name
});




}
/// @nodoc
class __$PoolStockItemCopyWithImpl<$Res>
    implements _$PoolStockItemCopyWith<$Res> {
  __$PoolStockItemCopyWithImpl(this._self, this._then);

  final _PoolStockItem _self;
  final $Res Function(_PoolStockItem) _then;

/// Create a copy of PoolStockItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? stockItemId = null,Object? name = freezed,}) {
  return _then(_PoolStockItem(
stockItemId: null == stockItemId ? _self.stockItemId : stockItemId // ignore: cast_nullable_to_non_nullable
as int,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$PoolMember {

@JsonKey(name: 'investor_id') int get investorId; String? get name;@JsonKey(name: 'joined_at') String? get joinedAt;/// What he has in this pool, walked from the ledger.
 String get capital;/// **His weight as it stands today** — his capital over the pool's, derived on each read and
/// stored nowhere.
///
/// Not the same figure as the one on a closed period: this moves whenever anybody's capital
/// moves, and it is what the next close *would* apply if it happened now. What he was actually
/// paid last month is frozen on that period.
@JsonKey(name: 'share_percent') String get sharePercent;/// The company's own row. It takes a capital weight like anybody else, and is **exempt from
/// the minimum term** — it is the operator, not a partner who might take a month's profit
/// and leave.
@JsonKey(name: 'is_company') bool get isCompany;/// The day his capital may be asked back, or null when it already may.
///
/// Null covers the three cases a screen treats identically — no minimum is set, he holds
/// nothing here, and the term has already run — because in all three there is nothing to
/// tell him. Answered by the same function that then refuses an early exit, so the date
/// shown and the date enforced are one.
@JsonKey(name: 'capital_free_on') String? get capitalFreeOn;
/// Create a copy of PoolMember
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PoolMemberCopyWith<PoolMember> get copyWith => _$PoolMemberCopyWithImpl<PoolMember>(this as PoolMember, _$identity);

  /// Serializes this PoolMember to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PoolMember&&(identical(other.investorId, investorId) || other.investorId == investorId)&&(identical(other.name, name) || other.name == name)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.capital, capital) || other.capital == capital)&&(identical(other.sharePercent, sharePercent) || other.sharePercent == sharePercent)&&(identical(other.isCompany, isCompany) || other.isCompany == isCompany)&&(identical(other.capitalFreeOn, capitalFreeOn) || other.capitalFreeOn == capitalFreeOn));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,investorId,name,joinedAt,capital,sharePercent,isCompany,capitalFreeOn);

@override
String toString() {
  return 'PoolMember(investorId: $investorId, name: $name, joinedAt: $joinedAt, capital: $capital, sharePercent: $sharePercent, isCompany: $isCompany, capitalFreeOn: $capitalFreeOn)';
}


}

/// @nodoc
abstract mixin class $PoolMemberCopyWith<$Res>  {
  factory $PoolMemberCopyWith(PoolMember value, $Res Function(PoolMember) _then) = _$PoolMemberCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'investor_id') int investorId, String? name,@JsonKey(name: 'joined_at') String? joinedAt, String capital,@JsonKey(name: 'share_percent') String sharePercent,@JsonKey(name: 'is_company') bool isCompany,@JsonKey(name: 'capital_free_on') String? capitalFreeOn
});




}
/// @nodoc
class _$PoolMemberCopyWithImpl<$Res>
    implements $PoolMemberCopyWith<$Res> {
  _$PoolMemberCopyWithImpl(this._self, this._then);

  final PoolMember _self;
  final $Res Function(PoolMember) _then;

/// Create a copy of PoolMember
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? investorId = null,Object? name = freezed,Object? joinedAt = freezed,Object? capital = null,Object? sharePercent = null,Object? isCompany = null,Object? capitalFreeOn = freezed,}) {
  return _then(_self.copyWith(
investorId: null == investorId ? _self.investorId : investorId // ignore: cast_nullable_to_non_nullable
as int,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,joinedAt: freezed == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as String?,capital: null == capital ? _self.capital : capital // ignore: cast_nullable_to_non_nullable
as String,sharePercent: null == sharePercent ? _self.sharePercent : sharePercent // ignore: cast_nullable_to_non_nullable
as String,isCompany: null == isCompany ? _self.isCompany : isCompany // ignore: cast_nullable_to_non_nullable
as bool,capitalFreeOn: freezed == capitalFreeOn ? _self.capitalFreeOn : capitalFreeOn // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PoolMember].
extension PoolMemberPatterns on PoolMember {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PoolMember value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PoolMember() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PoolMember value)  $default,){
final _that = this;
switch (_that) {
case _PoolMember():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PoolMember value)?  $default,){
final _that = this;
switch (_that) {
case _PoolMember() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'investor_id')  int investorId,  String? name, @JsonKey(name: 'joined_at')  String? joinedAt,  String capital, @JsonKey(name: 'share_percent')  String sharePercent, @JsonKey(name: 'is_company')  bool isCompany, @JsonKey(name: 'capital_free_on')  String? capitalFreeOn)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PoolMember() when $default != null:
return $default(_that.investorId,_that.name,_that.joinedAt,_that.capital,_that.sharePercent,_that.isCompany,_that.capitalFreeOn);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'investor_id')  int investorId,  String? name, @JsonKey(name: 'joined_at')  String? joinedAt,  String capital, @JsonKey(name: 'share_percent')  String sharePercent, @JsonKey(name: 'is_company')  bool isCompany, @JsonKey(name: 'capital_free_on')  String? capitalFreeOn)  $default,) {final _that = this;
switch (_that) {
case _PoolMember():
return $default(_that.investorId,_that.name,_that.joinedAt,_that.capital,_that.sharePercent,_that.isCompany,_that.capitalFreeOn);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'investor_id')  int investorId,  String? name, @JsonKey(name: 'joined_at')  String? joinedAt,  String capital, @JsonKey(name: 'share_percent')  String sharePercent, @JsonKey(name: 'is_company')  bool isCompany, @JsonKey(name: 'capital_free_on')  String? capitalFreeOn)?  $default,) {final _that = this;
switch (_that) {
case _PoolMember() when $default != null:
return $default(_that.investorId,_that.name,_that.joinedAt,_that.capital,_that.sharePercent,_that.isCompany,_that.capitalFreeOn);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PoolMember implements PoolMember {
  const _PoolMember({@JsonKey(name: 'investor_id') required this.investorId, this.name, @JsonKey(name: 'joined_at') this.joinedAt, this.capital = '0.00', @JsonKey(name: 'share_percent') this.sharePercent = '0.0000', @JsonKey(name: 'is_company') this.isCompany = false, @JsonKey(name: 'capital_free_on') this.capitalFreeOn});
  factory _PoolMember.fromJson(Map<String, dynamic> json) => _$PoolMemberFromJson(json);

@override@JsonKey(name: 'investor_id') final  int investorId;
@override final  String? name;
@override@JsonKey(name: 'joined_at') final  String? joinedAt;
/// What he has in this pool, walked from the ledger.
@override@JsonKey() final  String capital;
/// **His weight as it stands today** — his capital over the pool's, derived on each read and
/// stored nowhere.
///
/// Not the same figure as the one on a closed period: this moves whenever anybody's capital
/// moves, and it is what the next close *would* apply if it happened now. What he was actually
/// paid last month is frozen on that period.
@override@JsonKey(name: 'share_percent') final  String sharePercent;
/// The company's own row. It takes a capital weight like anybody else, and is **exempt from
/// the minimum term** — it is the operator, not a partner who might take a month's profit
/// and leave.
@override@JsonKey(name: 'is_company') final  bool isCompany;
/// The day his capital may be asked back, or null when it already may.
///
/// Null covers the three cases a screen treats identically — no minimum is set, he holds
/// nothing here, and the term has already run — because in all three there is nothing to
/// tell him. Answered by the same function that then refuses an early exit, so the date
/// shown and the date enforced are one.
@override@JsonKey(name: 'capital_free_on') final  String? capitalFreeOn;

/// Create a copy of PoolMember
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PoolMemberCopyWith<_PoolMember> get copyWith => __$PoolMemberCopyWithImpl<_PoolMember>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PoolMemberToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PoolMember&&(identical(other.investorId, investorId) || other.investorId == investorId)&&(identical(other.name, name) || other.name == name)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.capital, capital) || other.capital == capital)&&(identical(other.sharePercent, sharePercent) || other.sharePercent == sharePercent)&&(identical(other.isCompany, isCompany) || other.isCompany == isCompany)&&(identical(other.capitalFreeOn, capitalFreeOn) || other.capitalFreeOn == capitalFreeOn));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,investorId,name,joinedAt,capital,sharePercent,isCompany,capitalFreeOn);

@override
String toString() {
  return 'PoolMember(investorId: $investorId, name: $name, joinedAt: $joinedAt, capital: $capital, sharePercent: $sharePercent, isCompany: $isCompany, capitalFreeOn: $capitalFreeOn)';
}


}

/// @nodoc
abstract mixin class _$PoolMemberCopyWith<$Res> implements $PoolMemberCopyWith<$Res> {
  factory _$PoolMemberCopyWith(_PoolMember value, $Res Function(_PoolMember) _then) = __$PoolMemberCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'investor_id') int investorId, String? name,@JsonKey(name: 'joined_at') String? joinedAt, String capital,@JsonKey(name: 'share_percent') String sharePercent,@JsonKey(name: 'is_company') bool isCompany,@JsonKey(name: 'capital_free_on') String? capitalFreeOn
});




}
/// @nodoc
class __$PoolMemberCopyWithImpl<$Res>
    implements _$PoolMemberCopyWith<$Res> {
  __$PoolMemberCopyWithImpl(this._self, this._then);

  final _PoolMember _self;
  final $Res Function(_PoolMember) _then;

/// Create a copy of PoolMember
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? investorId = null,Object? name = freezed,Object? joinedAt = freezed,Object? capital = null,Object? sharePercent = null,Object? isCompany = null,Object? capitalFreeOn = freezed,}) {
  return _then(_PoolMember(
investorId: null == investorId ? _self.investorId : investorId // ignore: cast_nullable_to_non_nullable
as int,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,joinedAt: freezed == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as String?,capital: null == capital ? _self.capital : capital // ignore: cast_nullable_to_non_nullable
as String,sharePercent: null == sharePercent ? _self.sharePercent : sharePercent // ignore: cast_nullable_to_non_nullable
as String,isCompany: null == isCompany ? _self.isCompany : isCompany // ignore: cast_nullable_to_non_nullable
as bool,capitalFreeOn: freezed == capitalFreeOn ? _self.capitalFreeOn : capitalFreeOn // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$CapitalTiming {

@JsonKey(name: 'current_period') InvestmentPeriod? get currentPeriod;/// The last day money may still join the period that is running.
@JsonKey(name: 'grace_window_ends_on') String? get graceWindowEndsOn;/// The day capital offered **now** would begin to earn — today's period, or the next one.
@JsonKey(name: 'capital_takes_effect_on') String? get capitalTakesEffectOn;@JsonKey(name: 'is_inside_grace_window') bool get isInsideGraceWindow;
/// Create a copy of CapitalTiming
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CapitalTimingCopyWith<CapitalTiming> get copyWith => _$CapitalTimingCopyWithImpl<CapitalTiming>(this as CapitalTiming, _$identity);

  /// Serializes this CapitalTiming to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CapitalTiming&&(identical(other.currentPeriod, currentPeriod) || other.currentPeriod == currentPeriod)&&(identical(other.graceWindowEndsOn, graceWindowEndsOn) || other.graceWindowEndsOn == graceWindowEndsOn)&&(identical(other.capitalTakesEffectOn, capitalTakesEffectOn) || other.capitalTakesEffectOn == capitalTakesEffectOn)&&(identical(other.isInsideGraceWindow, isInsideGraceWindow) || other.isInsideGraceWindow == isInsideGraceWindow));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,currentPeriod,graceWindowEndsOn,capitalTakesEffectOn,isInsideGraceWindow);

@override
String toString() {
  return 'CapitalTiming(currentPeriod: $currentPeriod, graceWindowEndsOn: $graceWindowEndsOn, capitalTakesEffectOn: $capitalTakesEffectOn, isInsideGraceWindow: $isInsideGraceWindow)';
}


}

/// @nodoc
abstract mixin class $CapitalTimingCopyWith<$Res>  {
  factory $CapitalTimingCopyWith(CapitalTiming value, $Res Function(CapitalTiming) _then) = _$CapitalTimingCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'current_period') InvestmentPeriod? currentPeriod,@JsonKey(name: 'grace_window_ends_on') String? graceWindowEndsOn,@JsonKey(name: 'capital_takes_effect_on') String? capitalTakesEffectOn,@JsonKey(name: 'is_inside_grace_window') bool isInsideGraceWindow
});


$InvestmentPeriodCopyWith<$Res>? get currentPeriod;

}
/// @nodoc
class _$CapitalTimingCopyWithImpl<$Res>
    implements $CapitalTimingCopyWith<$Res> {
  _$CapitalTimingCopyWithImpl(this._self, this._then);

  final CapitalTiming _self;
  final $Res Function(CapitalTiming) _then;

/// Create a copy of CapitalTiming
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currentPeriod = freezed,Object? graceWindowEndsOn = freezed,Object? capitalTakesEffectOn = freezed,Object? isInsideGraceWindow = null,}) {
  return _then(_self.copyWith(
currentPeriod: freezed == currentPeriod ? _self.currentPeriod : currentPeriod // ignore: cast_nullable_to_non_nullable
as InvestmentPeriod?,graceWindowEndsOn: freezed == graceWindowEndsOn ? _self.graceWindowEndsOn : graceWindowEndsOn // ignore: cast_nullable_to_non_nullable
as String?,capitalTakesEffectOn: freezed == capitalTakesEffectOn ? _self.capitalTakesEffectOn : capitalTakesEffectOn // ignore: cast_nullable_to_non_nullable
as String?,isInsideGraceWindow: null == isInsideGraceWindow ? _self.isInsideGraceWindow : isInsideGraceWindow // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of CapitalTiming
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InvestmentPeriodCopyWith<$Res>? get currentPeriod {
    if (_self.currentPeriod == null) {
    return null;
  }

  return $InvestmentPeriodCopyWith<$Res>(_self.currentPeriod!, (value) {
    return _then(_self.copyWith(currentPeriod: value));
  });
}
}


/// Adds pattern-matching-related methods to [CapitalTiming].
extension CapitalTimingPatterns on CapitalTiming {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CapitalTiming value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CapitalTiming() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CapitalTiming value)  $default,){
final _that = this;
switch (_that) {
case _CapitalTiming():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CapitalTiming value)?  $default,){
final _that = this;
switch (_that) {
case _CapitalTiming() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'current_period')  InvestmentPeriod? currentPeriod, @JsonKey(name: 'grace_window_ends_on')  String? graceWindowEndsOn, @JsonKey(name: 'capital_takes_effect_on')  String? capitalTakesEffectOn, @JsonKey(name: 'is_inside_grace_window')  bool isInsideGraceWindow)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CapitalTiming() when $default != null:
return $default(_that.currentPeriod,_that.graceWindowEndsOn,_that.capitalTakesEffectOn,_that.isInsideGraceWindow);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'current_period')  InvestmentPeriod? currentPeriod, @JsonKey(name: 'grace_window_ends_on')  String? graceWindowEndsOn, @JsonKey(name: 'capital_takes_effect_on')  String? capitalTakesEffectOn, @JsonKey(name: 'is_inside_grace_window')  bool isInsideGraceWindow)  $default,) {final _that = this;
switch (_that) {
case _CapitalTiming():
return $default(_that.currentPeriod,_that.graceWindowEndsOn,_that.capitalTakesEffectOn,_that.isInsideGraceWindow);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'current_period')  InvestmentPeriod? currentPeriod, @JsonKey(name: 'grace_window_ends_on')  String? graceWindowEndsOn, @JsonKey(name: 'capital_takes_effect_on')  String? capitalTakesEffectOn, @JsonKey(name: 'is_inside_grace_window')  bool isInsideGraceWindow)?  $default,) {final _that = this;
switch (_that) {
case _CapitalTiming() when $default != null:
return $default(_that.currentPeriod,_that.graceWindowEndsOn,_that.capitalTakesEffectOn,_that.isInsideGraceWindow);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CapitalTiming implements CapitalTiming {
  const _CapitalTiming({@JsonKey(name: 'current_period') this.currentPeriod, @JsonKey(name: 'grace_window_ends_on') this.graceWindowEndsOn, @JsonKey(name: 'capital_takes_effect_on') this.capitalTakesEffectOn, @JsonKey(name: 'is_inside_grace_window') this.isInsideGraceWindow = false});
  factory _CapitalTiming.fromJson(Map<String, dynamic> json) => _$CapitalTimingFromJson(json);

@override@JsonKey(name: 'current_period') final  InvestmentPeriod? currentPeriod;
/// The last day money may still join the period that is running.
@override@JsonKey(name: 'grace_window_ends_on') final  String? graceWindowEndsOn;
/// The day capital offered **now** would begin to earn — today's period, or the next one.
@override@JsonKey(name: 'capital_takes_effect_on') final  String? capitalTakesEffectOn;
@override@JsonKey(name: 'is_inside_grace_window') final  bool isInsideGraceWindow;

/// Create a copy of CapitalTiming
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CapitalTimingCopyWith<_CapitalTiming> get copyWith => __$CapitalTimingCopyWithImpl<_CapitalTiming>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CapitalTimingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CapitalTiming&&(identical(other.currentPeriod, currentPeriod) || other.currentPeriod == currentPeriod)&&(identical(other.graceWindowEndsOn, graceWindowEndsOn) || other.graceWindowEndsOn == graceWindowEndsOn)&&(identical(other.capitalTakesEffectOn, capitalTakesEffectOn) || other.capitalTakesEffectOn == capitalTakesEffectOn)&&(identical(other.isInsideGraceWindow, isInsideGraceWindow) || other.isInsideGraceWindow == isInsideGraceWindow));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,currentPeriod,graceWindowEndsOn,capitalTakesEffectOn,isInsideGraceWindow);

@override
String toString() {
  return 'CapitalTiming(currentPeriod: $currentPeriod, graceWindowEndsOn: $graceWindowEndsOn, capitalTakesEffectOn: $capitalTakesEffectOn, isInsideGraceWindow: $isInsideGraceWindow)';
}


}

/// @nodoc
abstract mixin class _$CapitalTimingCopyWith<$Res> implements $CapitalTimingCopyWith<$Res> {
  factory _$CapitalTimingCopyWith(_CapitalTiming value, $Res Function(_CapitalTiming) _then) = __$CapitalTimingCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'current_period') InvestmentPeriod? currentPeriod,@JsonKey(name: 'grace_window_ends_on') String? graceWindowEndsOn,@JsonKey(name: 'capital_takes_effect_on') String? capitalTakesEffectOn,@JsonKey(name: 'is_inside_grace_window') bool isInsideGraceWindow
});


@override $InvestmentPeriodCopyWith<$Res>? get currentPeriod;

}
/// @nodoc
class __$CapitalTimingCopyWithImpl<$Res>
    implements _$CapitalTimingCopyWith<$Res> {
  __$CapitalTimingCopyWithImpl(this._self, this._then);

  final _CapitalTiming _self;
  final $Res Function(_CapitalTiming) _then;

/// Create a copy of CapitalTiming
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currentPeriod = freezed,Object? graceWindowEndsOn = freezed,Object? capitalTakesEffectOn = freezed,Object? isInsideGraceWindow = null,}) {
  return _then(_CapitalTiming(
currentPeriod: freezed == currentPeriod ? _self.currentPeriod : currentPeriod // ignore: cast_nullable_to_non_nullable
as InvestmentPeriod?,graceWindowEndsOn: freezed == graceWindowEndsOn ? _self.graceWindowEndsOn : graceWindowEndsOn // ignore: cast_nullable_to_non_nullable
as String?,capitalTakesEffectOn: freezed == capitalTakesEffectOn ? _self.capitalTakesEffectOn : capitalTakesEffectOn // ignore: cast_nullable_to_non_nullable
as String?,isInsideGraceWindow: null == isInsideGraceWindow ? _self.isInsideGraceWindow : isInsideGraceWindow // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of CapitalTiming
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InvestmentPeriodCopyWith<$Res>? get currentPeriod {
    if (_self.currentPeriod == null) {
    return null;
  }

  return $InvestmentPeriodCopyWith<$Res>(_self.currentPeriod!, (value) {
    return _then(_self.copyWith(currentPeriod: value));
  });
}
}


/// @nodoc
mixin _$PoolDeployableCash {

 String get capital;/// The current period's earnings, banked whole and not yet divided.
@JsonKey(name: 'unsettled_profit') String get unsettledProfit;@JsonKey(name: 'book_value') String get bookValue;@JsonKey(name: 'stock_at_cost') String get stockAtCost;@JsonKey(name: 'deployable_cash') String get deployableCash;
/// Create a copy of PoolDeployableCash
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PoolDeployableCashCopyWith<PoolDeployableCash> get copyWith => _$PoolDeployableCashCopyWithImpl<PoolDeployableCash>(this as PoolDeployableCash, _$identity);

  /// Serializes this PoolDeployableCash to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PoolDeployableCash&&(identical(other.capital, capital) || other.capital == capital)&&(identical(other.unsettledProfit, unsettledProfit) || other.unsettledProfit == unsettledProfit)&&(identical(other.bookValue, bookValue) || other.bookValue == bookValue)&&(identical(other.stockAtCost, stockAtCost) || other.stockAtCost == stockAtCost)&&(identical(other.deployableCash, deployableCash) || other.deployableCash == deployableCash));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,capital,unsettledProfit,bookValue,stockAtCost,deployableCash);

@override
String toString() {
  return 'PoolDeployableCash(capital: $capital, unsettledProfit: $unsettledProfit, bookValue: $bookValue, stockAtCost: $stockAtCost, deployableCash: $deployableCash)';
}


}

/// @nodoc
abstract mixin class $PoolDeployableCashCopyWith<$Res>  {
  factory $PoolDeployableCashCopyWith(PoolDeployableCash value, $Res Function(PoolDeployableCash) _then) = _$PoolDeployableCashCopyWithImpl;
@useResult
$Res call({
 String capital,@JsonKey(name: 'unsettled_profit') String unsettledProfit,@JsonKey(name: 'book_value') String bookValue,@JsonKey(name: 'stock_at_cost') String stockAtCost,@JsonKey(name: 'deployable_cash') String deployableCash
});




}
/// @nodoc
class _$PoolDeployableCashCopyWithImpl<$Res>
    implements $PoolDeployableCashCopyWith<$Res> {
  _$PoolDeployableCashCopyWithImpl(this._self, this._then);

  final PoolDeployableCash _self;
  final $Res Function(PoolDeployableCash) _then;

/// Create a copy of PoolDeployableCash
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? capital = null,Object? unsettledProfit = null,Object? bookValue = null,Object? stockAtCost = null,Object? deployableCash = null,}) {
  return _then(_self.copyWith(
capital: null == capital ? _self.capital : capital // ignore: cast_nullable_to_non_nullable
as String,unsettledProfit: null == unsettledProfit ? _self.unsettledProfit : unsettledProfit // ignore: cast_nullable_to_non_nullable
as String,bookValue: null == bookValue ? _self.bookValue : bookValue // ignore: cast_nullable_to_non_nullable
as String,stockAtCost: null == stockAtCost ? _self.stockAtCost : stockAtCost // ignore: cast_nullable_to_non_nullable
as String,deployableCash: null == deployableCash ? _self.deployableCash : deployableCash // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PoolDeployableCash].
extension PoolDeployableCashPatterns on PoolDeployableCash {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PoolDeployableCash value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PoolDeployableCash() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PoolDeployableCash value)  $default,){
final _that = this;
switch (_that) {
case _PoolDeployableCash():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PoolDeployableCash value)?  $default,){
final _that = this;
switch (_that) {
case _PoolDeployableCash() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String capital, @JsonKey(name: 'unsettled_profit')  String unsettledProfit, @JsonKey(name: 'book_value')  String bookValue, @JsonKey(name: 'stock_at_cost')  String stockAtCost, @JsonKey(name: 'deployable_cash')  String deployableCash)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PoolDeployableCash() when $default != null:
return $default(_that.capital,_that.unsettledProfit,_that.bookValue,_that.stockAtCost,_that.deployableCash);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String capital, @JsonKey(name: 'unsettled_profit')  String unsettledProfit, @JsonKey(name: 'book_value')  String bookValue, @JsonKey(name: 'stock_at_cost')  String stockAtCost, @JsonKey(name: 'deployable_cash')  String deployableCash)  $default,) {final _that = this;
switch (_that) {
case _PoolDeployableCash():
return $default(_that.capital,_that.unsettledProfit,_that.bookValue,_that.stockAtCost,_that.deployableCash);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String capital, @JsonKey(name: 'unsettled_profit')  String unsettledProfit, @JsonKey(name: 'book_value')  String bookValue, @JsonKey(name: 'stock_at_cost')  String stockAtCost, @JsonKey(name: 'deployable_cash')  String deployableCash)?  $default,) {final _that = this;
switch (_that) {
case _PoolDeployableCash() when $default != null:
return $default(_that.capital,_that.unsettledProfit,_that.bookValue,_that.stockAtCost,_that.deployableCash);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PoolDeployableCash implements PoolDeployableCash {
  const _PoolDeployableCash({required this.capital, @JsonKey(name: 'unsettled_profit') required this.unsettledProfit, @JsonKey(name: 'book_value') required this.bookValue, @JsonKey(name: 'stock_at_cost') required this.stockAtCost, @JsonKey(name: 'deployable_cash') required this.deployableCash});
  factory _PoolDeployableCash.fromJson(Map<String, dynamic> json) => _$PoolDeployableCashFromJson(json);

@override final  String capital;
/// The current period's earnings, banked whole and not yet divided.
@override@JsonKey(name: 'unsettled_profit') final  String unsettledProfit;
@override@JsonKey(name: 'book_value') final  String bookValue;
@override@JsonKey(name: 'stock_at_cost') final  String stockAtCost;
@override@JsonKey(name: 'deployable_cash') final  String deployableCash;

/// Create a copy of PoolDeployableCash
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PoolDeployableCashCopyWith<_PoolDeployableCash> get copyWith => __$PoolDeployableCashCopyWithImpl<_PoolDeployableCash>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PoolDeployableCashToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PoolDeployableCash&&(identical(other.capital, capital) || other.capital == capital)&&(identical(other.unsettledProfit, unsettledProfit) || other.unsettledProfit == unsettledProfit)&&(identical(other.bookValue, bookValue) || other.bookValue == bookValue)&&(identical(other.stockAtCost, stockAtCost) || other.stockAtCost == stockAtCost)&&(identical(other.deployableCash, deployableCash) || other.deployableCash == deployableCash));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,capital,unsettledProfit,bookValue,stockAtCost,deployableCash);

@override
String toString() {
  return 'PoolDeployableCash(capital: $capital, unsettledProfit: $unsettledProfit, bookValue: $bookValue, stockAtCost: $stockAtCost, deployableCash: $deployableCash)';
}


}

/// @nodoc
abstract mixin class _$PoolDeployableCashCopyWith<$Res> implements $PoolDeployableCashCopyWith<$Res> {
  factory _$PoolDeployableCashCopyWith(_PoolDeployableCash value, $Res Function(_PoolDeployableCash) _then) = __$PoolDeployableCashCopyWithImpl;
@override @useResult
$Res call({
 String capital,@JsonKey(name: 'unsettled_profit') String unsettledProfit,@JsonKey(name: 'book_value') String bookValue,@JsonKey(name: 'stock_at_cost') String stockAtCost,@JsonKey(name: 'deployable_cash') String deployableCash
});




}
/// @nodoc
class __$PoolDeployableCashCopyWithImpl<$Res>
    implements _$PoolDeployableCashCopyWith<$Res> {
  __$PoolDeployableCashCopyWithImpl(this._self, this._then);

  final _PoolDeployableCash _self;
  final $Res Function(_PoolDeployableCash) _then;

/// Create a copy of PoolDeployableCash
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? capital = null,Object? unsettledProfit = null,Object? bookValue = null,Object? stockAtCost = null,Object? deployableCash = null,}) {
  return _then(_PoolDeployableCash(
capital: null == capital ? _self.capital : capital // ignore: cast_nullable_to_non_nullable
as String,unsettledProfit: null == unsettledProfit ? _self.unsettledProfit : unsettledProfit // ignore: cast_nullable_to_non_nullable
as String,bookValue: null == bookValue ? _self.bookValue : bookValue // ignore: cast_nullable_to_non_nullable
as String,stockAtCost: null == stockAtCost ? _self.stockAtCost : stockAtCost // ignore: cast_nullable_to_non_nullable
as String,deployableCash: null == deployableCash ? _self.deployableCash : deployableCash // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
