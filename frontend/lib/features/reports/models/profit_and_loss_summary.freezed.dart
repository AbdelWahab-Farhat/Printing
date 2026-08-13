// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profit_and_loss_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProfitAndLossSummary {

 PnlPeriod get period; PnlRevenue get revenue;@JsonKey(name: 'cost_of_goods_sold') PnlCostOfGoodsSold get costOfGoodsSold;@JsonKey(name: 'gross_profit') String get grossProfit;/// Money that came in over these same days — and nothing more than that. See [PnlPeriod]
/// for what the days mean and the class note on the screen for why it is never netted.
@JsonKey(name: 'cash_collected') String get cashCollected;/// How many orders the revenue and cost blocks are actually about.
///
/// **The honest denominator, and the only integer in the payload.** Without it, an
/// all-zero report is unreadable: it could mean the shop delivered nothing, or it could
/// mean the period was typed wrong. A zero here beside a non-zero [cashCollected] is an
/// ordinary state — deposits taken against work not yet delivered — not a contradiction.
@JsonKey(name: 'orders_recognized') int get ordersRecognized;
/// Create a copy of ProfitAndLossSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfitAndLossSummaryCopyWith<ProfitAndLossSummary> get copyWith => _$ProfitAndLossSummaryCopyWithImpl<ProfitAndLossSummary>(this as ProfitAndLossSummary, _$identity);

  /// Serializes this ProfitAndLossSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfitAndLossSummary&&(identical(other.period, period) || other.period == period)&&(identical(other.revenue, revenue) || other.revenue == revenue)&&(identical(other.costOfGoodsSold, costOfGoodsSold) || other.costOfGoodsSold == costOfGoodsSold)&&(identical(other.grossProfit, grossProfit) || other.grossProfit == grossProfit)&&(identical(other.cashCollected, cashCollected) || other.cashCollected == cashCollected)&&(identical(other.ordersRecognized, ordersRecognized) || other.ordersRecognized == ordersRecognized));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,period,revenue,costOfGoodsSold,grossProfit,cashCollected,ordersRecognized);

@override
String toString() {
  return 'ProfitAndLossSummary(period: $period, revenue: $revenue, costOfGoodsSold: $costOfGoodsSold, grossProfit: $grossProfit, cashCollected: $cashCollected, ordersRecognized: $ordersRecognized)';
}


}

/// @nodoc
abstract mixin class $ProfitAndLossSummaryCopyWith<$Res>  {
  factory $ProfitAndLossSummaryCopyWith(ProfitAndLossSummary value, $Res Function(ProfitAndLossSummary) _then) = _$ProfitAndLossSummaryCopyWithImpl;
@useResult
$Res call({
 PnlPeriod period, PnlRevenue revenue,@JsonKey(name: 'cost_of_goods_sold') PnlCostOfGoodsSold costOfGoodsSold,@JsonKey(name: 'gross_profit') String grossProfit,@JsonKey(name: 'cash_collected') String cashCollected,@JsonKey(name: 'orders_recognized') int ordersRecognized
});


$PnlPeriodCopyWith<$Res> get period;$PnlRevenueCopyWith<$Res> get revenue;$PnlCostOfGoodsSoldCopyWith<$Res> get costOfGoodsSold;

}
/// @nodoc
class _$ProfitAndLossSummaryCopyWithImpl<$Res>
    implements $ProfitAndLossSummaryCopyWith<$Res> {
  _$ProfitAndLossSummaryCopyWithImpl(this._self, this._then);

  final ProfitAndLossSummary _self;
  final $Res Function(ProfitAndLossSummary) _then;

/// Create a copy of ProfitAndLossSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? period = null,Object? revenue = null,Object? costOfGoodsSold = null,Object? grossProfit = null,Object? cashCollected = null,Object? ordersRecognized = null,}) {
  return _then(_self.copyWith(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as PnlPeriod,revenue: null == revenue ? _self.revenue : revenue // ignore: cast_nullable_to_non_nullable
as PnlRevenue,costOfGoodsSold: null == costOfGoodsSold ? _self.costOfGoodsSold : costOfGoodsSold // ignore: cast_nullable_to_non_nullable
as PnlCostOfGoodsSold,grossProfit: null == grossProfit ? _self.grossProfit : grossProfit // ignore: cast_nullable_to_non_nullable
as String,cashCollected: null == cashCollected ? _self.cashCollected : cashCollected // ignore: cast_nullable_to_non_nullable
as String,ordersRecognized: null == ordersRecognized ? _self.ordersRecognized : ordersRecognized // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of ProfitAndLossSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PnlPeriodCopyWith<$Res> get period {
  
  return $PnlPeriodCopyWith<$Res>(_self.period, (value) {
    return _then(_self.copyWith(period: value));
  });
}/// Create a copy of ProfitAndLossSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PnlRevenueCopyWith<$Res> get revenue {
  
  return $PnlRevenueCopyWith<$Res>(_self.revenue, (value) {
    return _then(_self.copyWith(revenue: value));
  });
}/// Create a copy of ProfitAndLossSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PnlCostOfGoodsSoldCopyWith<$Res> get costOfGoodsSold {
  
  return $PnlCostOfGoodsSoldCopyWith<$Res>(_self.costOfGoodsSold, (value) {
    return _then(_self.copyWith(costOfGoodsSold: value));
  });
}
}


/// Adds pattern-matching-related methods to [ProfitAndLossSummary].
extension ProfitAndLossSummaryPatterns on ProfitAndLossSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfitAndLossSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfitAndLossSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfitAndLossSummary value)  $default,){
final _that = this;
switch (_that) {
case _ProfitAndLossSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfitAndLossSummary value)?  $default,){
final _that = this;
switch (_that) {
case _ProfitAndLossSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PnlPeriod period,  PnlRevenue revenue, @JsonKey(name: 'cost_of_goods_sold')  PnlCostOfGoodsSold costOfGoodsSold, @JsonKey(name: 'gross_profit')  String grossProfit, @JsonKey(name: 'cash_collected')  String cashCollected, @JsonKey(name: 'orders_recognized')  int ordersRecognized)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfitAndLossSummary() when $default != null:
return $default(_that.period,_that.revenue,_that.costOfGoodsSold,_that.grossProfit,_that.cashCollected,_that.ordersRecognized);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PnlPeriod period,  PnlRevenue revenue, @JsonKey(name: 'cost_of_goods_sold')  PnlCostOfGoodsSold costOfGoodsSold, @JsonKey(name: 'gross_profit')  String grossProfit, @JsonKey(name: 'cash_collected')  String cashCollected, @JsonKey(name: 'orders_recognized')  int ordersRecognized)  $default,) {final _that = this;
switch (_that) {
case _ProfitAndLossSummary():
return $default(_that.period,_that.revenue,_that.costOfGoodsSold,_that.grossProfit,_that.cashCollected,_that.ordersRecognized);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PnlPeriod period,  PnlRevenue revenue, @JsonKey(name: 'cost_of_goods_sold')  PnlCostOfGoodsSold costOfGoodsSold, @JsonKey(name: 'gross_profit')  String grossProfit, @JsonKey(name: 'cash_collected')  String cashCollected, @JsonKey(name: 'orders_recognized')  int ordersRecognized)?  $default,) {final _that = this;
switch (_that) {
case _ProfitAndLossSummary() when $default != null:
return $default(_that.period,_that.revenue,_that.costOfGoodsSold,_that.grossProfit,_that.cashCollected,_that.ordersRecognized);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProfitAndLossSummary extends ProfitAndLossSummary {
  const _ProfitAndLossSummary({required this.period, required this.revenue, @JsonKey(name: 'cost_of_goods_sold') required this.costOfGoodsSold, @JsonKey(name: 'gross_profit') required this.grossProfit, @JsonKey(name: 'cash_collected') required this.cashCollected, @JsonKey(name: 'orders_recognized') required this.ordersRecognized}): super._();
  factory _ProfitAndLossSummary.fromJson(Map<String, dynamic> json) => _$ProfitAndLossSummaryFromJson(json);

@override final  PnlPeriod period;
@override final  PnlRevenue revenue;
@override@JsonKey(name: 'cost_of_goods_sold') final  PnlCostOfGoodsSold costOfGoodsSold;
@override@JsonKey(name: 'gross_profit') final  String grossProfit;
/// Money that came in over these same days — and nothing more than that. See [PnlPeriod]
/// for what the days mean and the class note on the screen for why it is never netted.
@override@JsonKey(name: 'cash_collected') final  String cashCollected;
/// How many orders the revenue and cost blocks are actually about.
///
/// **The honest denominator, and the only integer in the payload.** Without it, an
/// all-zero report is unreadable: it could mean the shop delivered nothing, or it could
/// mean the period was typed wrong. A zero here beside a non-zero [cashCollected] is an
/// ordinary state — deposits taken against work not yet delivered — not a contradiction.
@override@JsonKey(name: 'orders_recognized') final  int ordersRecognized;

/// Create a copy of ProfitAndLossSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfitAndLossSummaryCopyWith<_ProfitAndLossSummary> get copyWith => __$ProfitAndLossSummaryCopyWithImpl<_ProfitAndLossSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfitAndLossSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfitAndLossSummary&&(identical(other.period, period) || other.period == period)&&(identical(other.revenue, revenue) || other.revenue == revenue)&&(identical(other.costOfGoodsSold, costOfGoodsSold) || other.costOfGoodsSold == costOfGoodsSold)&&(identical(other.grossProfit, grossProfit) || other.grossProfit == grossProfit)&&(identical(other.cashCollected, cashCollected) || other.cashCollected == cashCollected)&&(identical(other.ordersRecognized, ordersRecognized) || other.ordersRecognized == ordersRecognized));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,period,revenue,costOfGoodsSold,grossProfit,cashCollected,ordersRecognized);

@override
String toString() {
  return 'ProfitAndLossSummary(period: $period, revenue: $revenue, costOfGoodsSold: $costOfGoodsSold, grossProfit: $grossProfit, cashCollected: $cashCollected, ordersRecognized: $ordersRecognized)';
}


}

/// @nodoc
abstract mixin class _$ProfitAndLossSummaryCopyWith<$Res> implements $ProfitAndLossSummaryCopyWith<$Res> {
  factory _$ProfitAndLossSummaryCopyWith(_ProfitAndLossSummary value, $Res Function(_ProfitAndLossSummary) _then) = __$ProfitAndLossSummaryCopyWithImpl;
@override @useResult
$Res call({
 PnlPeriod period, PnlRevenue revenue,@JsonKey(name: 'cost_of_goods_sold') PnlCostOfGoodsSold costOfGoodsSold,@JsonKey(name: 'gross_profit') String grossProfit,@JsonKey(name: 'cash_collected') String cashCollected,@JsonKey(name: 'orders_recognized') int ordersRecognized
});


@override $PnlPeriodCopyWith<$Res> get period;@override $PnlRevenueCopyWith<$Res> get revenue;@override $PnlCostOfGoodsSoldCopyWith<$Res> get costOfGoodsSold;

}
/// @nodoc
class __$ProfitAndLossSummaryCopyWithImpl<$Res>
    implements _$ProfitAndLossSummaryCopyWith<$Res> {
  __$ProfitAndLossSummaryCopyWithImpl(this._self, this._then);

  final _ProfitAndLossSummary _self;
  final $Res Function(_ProfitAndLossSummary) _then;

/// Create a copy of ProfitAndLossSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? period = null,Object? revenue = null,Object? costOfGoodsSold = null,Object? grossProfit = null,Object? cashCollected = null,Object? ordersRecognized = null,}) {
  return _then(_ProfitAndLossSummary(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as PnlPeriod,revenue: null == revenue ? _self.revenue : revenue // ignore: cast_nullable_to_non_nullable
as PnlRevenue,costOfGoodsSold: null == costOfGoodsSold ? _self.costOfGoodsSold : costOfGoodsSold // ignore: cast_nullable_to_non_nullable
as PnlCostOfGoodsSold,grossProfit: null == grossProfit ? _self.grossProfit : grossProfit // ignore: cast_nullable_to_non_nullable
as String,cashCollected: null == cashCollected ? _self.cashCollected : cashCollected // ignore: cast_nullable_to_non_nullable
as String,ordersRecognized: null == ordersRecognized ? _self.ordersRecognized : ordersRecognized // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of ProfitAndLossSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PnlPeriodCopyWith<$Res> get period {
  
  return $PnlPeriodCopyWith<$Res>(_self.period, (value) {
    return _then(_self.copyWith(period: value));
  });
}/// Create a copy of ProfitAndLossSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PnlRevenueCopyWith<$Res> get revenue {
  
  return $PnlRevenueCopyWith<$Res>(_self.revenue, (value) {
    return _then(_self.copyWith(revenue: value));
  });
}/// Create a copy of ProfitAndLossSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PnlCostOfGoodsSoldCopyWith<$Res> get costOfGoodsSold {
  
  return $PnlCostOfGoodsSoldCopyWith<$Res>(_self.costOfGoodsSold, (value) {
    return _then(_self.copyWith(costOfGoodsSold: value));
  });
}
}


/// @nodoc
mixin _$PnlPeriod {

 String get from; String get to;
/// Create a copy of PnlPeriod
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PnlPeriodCopyWith<PnlPeriod> get copyWith => _$PnlPeriodCopyWithImpl<PnlPeriod>(this as PnlPeriod, _$identity);

  /// Serializes this PnlPeriod to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PnlPeriod&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,from,to);

@override
String toString() {
  return 'PnlPeriod(from: $from, to: $to)';
}


}

/// @nodoc
abstract mixin class $PnlPeriodCopyWith<$Res>  {
  factory $PnlPeriodCopyWith(PnlPeriod value, $Res Function(PnlPeriod) _then) = _$PnlPeriodCopyWithImpl;
@useResult
$Res call({
 String from, String to
});




}
/// @nodoc
class _$PnlPeriodCopyWithImpl<$Res>
    implements $PnlPeriodCopyWith<$Res> {
  _$PnlPeriodCopyWithImpl(this._self, this._then);

  final PnlPeriod _self;
  final $Res Function(PnlPeriod) _then;

/// Create a copy of PnlPeriod
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? from = null,Object? to = null,}) {
  return _then(_self.copyWith(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PnlPeriod].
extension PnlPeriodPatterns on PnlPeriod {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PnlPeriod value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PnlPeriod() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PnlPeriod value)  $default,){
final _that = this;
switch (_that) {
case _PnlPeriod():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PnlPeriod value)?  $default,){
final _that = this;
switch (_that) {
case _PnlPeriod() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String from,  String to)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PnlPeriod() when $default != null:
return $default(_that.from,_that.to);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String from,  String to)  $default,) {final _that = this;
switch (_that) {
case _PnlPeriod():
return $default(_that.from,_that.to);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String from,  String to)?  $default,) {final _that = this;
switch (_that) {
case _PnlPeriod() when $default != null:
return $default(_that.from,_that.to);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PnlPeriod extends PnlPeriod {
  const _PnlPeriod({required this.from, required this.to}): super._();
  factory _PnlPeriod.fromJson(Map<String, dynamic> json) => _$PnlPeriodFromJson(json);

@override final  String from;
@override final  String to;

/// Create a copy of PnlPeriod
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PnlPeriodCopyWith<_PnlPeriod> get copyWith => __$PnlPeriodCopyWithImpl<_PnlPeriod>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PnlPeriodToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PnlPeriod&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,from,to);

@override
String toString() {
  return 'PnlPeriod(from: $from, to: $to)';
}


}

/// @nodoc
abstract mixin class _$PnlPeriodCopyWith<$Res> implements $PnlPeriodCopyWith<$Res> {
  factory _$PnlPeriodCopyWith(_PnlPeriod value, $Res Function(_PnlPeriod) _then) = __$PnlPeriodCopyWithImpl;
@override @useResult
$Res call({
 String from, String to
});




}
/// @nodoc
class __$PnlPeriodCopyWithImpl<$Res>
    implements _$PnlPeriodCopyWith<$Res> {
  __$PnlPeriodCopyWithImpl(this._self, this._then);

  final _PnlPeriod _self;
  final $Res Function(_PnlPeriod) _then;

/// Create a copy of PnlPeriod
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? from = null,Object? to = null,}) {
  return _then(_PnlPeriod(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PnlRevenue {

/// The lines on every recognised order, added up.
 String get product;/// The design fee — but only where the design was ours to charge for.
///
/// A fee left on a customer-supplied design contributes `'0.00'` however large it is, since
/// the fee stays on the row when the source flips so that toggling it back does not lose
/// the number. It carries no cost anywhere in this system, deliberately, so there is no
/// service-cost row to go looking for.
 String get service; String get total;
/// Create a copy of PnlRevenue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PnlRevenueCopyWith<PnlRevenue> get copyWith => _$PnlRevenueCopyWithImpl<PnlRevenue>(this as PnlRevenue, _$identity);

  /// Serializes this PnlRevenue to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PnlRevenue&&(identical(other.product, product) || other.product == product)&&(identical(other.service, service) || other.service == service)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,product,service,total);

@override
String toString() {
  return 'PnlRevenue(product: $product, service: $service, total: $total)';
}


}

/// @nodoc
abstract mixin class $PnlRevenueCopyWith<$Res>  {
  factory $PnlRevenueCopyWith(PnlRevenue value, $Res Function(PnlRevenue) _then) = _$PnlRevenueCopyWithImpl;
@useResult
$Res call({
 String product, String service, String total
});




}
/// @nodoc
class _$PnlRevenueCopyWithImpl<$Res>
    implements $PnlRevenueCopyWith<$Res> {
  _$PnlRevenueCopyWithImpl(this._self, this._then);

  final PnlRevenue _self;
  final $Res Function(PnlRevenue) _then;

/// Create a copy of PnlRevenue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? product = null,Object? service = null,Object? total = null,}) {
  return _then(_self.copyWith(
product: null == product ? _self.product : product // ignore: cast_nullable_to_non_nullable
as String,service: null == service ? _self.service : service // ignore: cast_nullable_to_non_nullable
as String,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PnlRevenue].
extension PnlRevenuePatterns on PnlRevenue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PnlRevenue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PnlRevenue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PnlRevenue value)  $default,){
final _that = this;
switch (_that) {
case _PnlRevenue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PnlRevenue value)?  $default,){
final _that = this;
switch (_that) {
case _PnlRevenue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String product,  String service,  String total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PnlRevenue() when $default != null:
return $default(_that.product,_that.service,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String product,  String service,  String total)  $default,) {final _that = this;
switch (_that) {
case _PnlRevenue():
return $default(_that.product,_that.service,_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String product,  String service,  String total)?  $default,) {final _that = this;
switch (_that) {
case _PnlRevenue() when $default != null:
return $default(_that.product,_that.service,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PnlRevenue implements PnlRevenue {
  const _PnlRevenue({required this.product, required this.service, required this.total});
  factory _PnlRevenue.fromJson(Map<String, dynamic> json) => _$PnlRevenueFromJson(json);

/// The lines on every recognised order, added up.
@override final  String product;
/// The design fee — but only where the design was ours to charge for.
///
/// A fee left on a customer-supplied design contributes `'0.00'` however large it is, since
/// the fee stays on the row when the source flips so that toggling it back does not lose
/// the number. It carries no cost anywhere in this system, deliberately, so there is no
/// service-cost row to go looking for.
@override final  String service;
@override final  String total;

/// Create a copy of PnlRevenue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PnlRevenueCopyWith<_PnlRevenue> get copyWith => __$PnlRevenueCopyWithImpl<_PnlRevenue>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PnlRevenueToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PnlRevenue&&(identical(other.product, product) || other.product == product)&&(identical(other.service, service) || other.service == service)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,product,service,total);

@override
String toString() {
  return 'PnlRevenue(product: $product, service: $service, total: $total)';
}


}

/// @nodoc
abstract mixin class _$PnlRevenueCopyWith<$Res> implements $PnlRevenueCopyWith<$Res> {
  factory _$PnlRevenueCopyWith(_PnlRevenue value, $Res Function(_PnlRevenue) _then) = __$PnlRevenueCopyWithImpl;
@override @useResult
$Res call({
 String product, String service, String total
});




}
/// @nodoc
class __$PnlRevenueCopyWithImpl<$Res>
    implements _$PnlRevenueCopyWith<$Res> {
  __$PnlRevenueCopyWithImpl(this._self, this._then);

  final _PnlRevenue _self;
  final $Res Function(_PnlRevenue) _then;

/// Create a copy of PnlRevenue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? product = null,Object? service = null,Object? total = null,}) {
  return _then(_PnlRevenue(
product: null == product ? _self.product : product // ignore: cast_nullable_to_non_nullable
as String,service: null == service ? _self.service : service // ignore: cast_nullable_to_non_nullable
as String,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PnlCostOfGoodsSold {

/// What left the shelves, at what the batches it came out of actually cost.
 String get material;/// The two rate-driven costs, applied when an order first entered printing. American
/// spelling because that is the key on the wire.
 String get labor; String get overhead; String get total;
/// Create a copy of PnlCostOfGoodsSold
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PnlCostOfGoodsSoldCopyWith<PnlCostOfGoodsSold> get copyWith => _$PnlCostOfGoodsSoldCopyWithImpl<PnlCostOfGoodsSold>(this as PnlCostOfGoodsSold, _$identity);

  /// Serializes this PnlCostOfGoodsSold to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PnlCostOfGoodsSold&&(identical(other.material, material) || other.material == material)&&(identical(other.labor, labor) || other.labor == labor)&&(identical(other.overhead, overhead) || other.overhead == overhead)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,material,labor,overhead,total);

@override
String toString() {
  return 'PnlCostOfGoodsSold(material: $material, labor: $labor, overhead: $overhead, total: $total)';
}


}

/// @nodoc
abstract mixin class $PnlCostOfGoodsSoldCopyWith<$Res>  {
  factory $PnlCostOfGoodsSoldCopyWith(PnlCostOfGoodsSold value, $Res Function(PnlCostOfGoodsSold) _then) = _$PnlCostOfGoodsSoldCopyWithImpl;
@useResult
$Res call({
 String material, String labor, String overhead, String total
});




}
/// @nodoc
class _$PnlCostOfGoodsSoldCopyWithImpl<$Res>
    implements $PnlCostOfGoodsSoldCopyWith<$Res> {
  _$PnlCostOfGoodsSoldCopyWithImpl(this._self, this._then);

  final PnlCostOfGoodsSold _self;
  final $Res Function(PnlCostOfGoodsSold) _then;

/// Create a copy of PnlCostOfGoodsSold
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? material = null,Object? labor = null,Object? overhead = null,Object? total = null,}) {
  return _then(_self.copyWith(
material: null == material ? _self.material : material // ignore: cast_nullable_to_non_nullable
as String,labor: null == labor ? _self.labor : labor // ignore: cast_nullable_to_non_nullable
as String,overhead: null == overhead ? _self.overhead : overhead // ignore: cast_nullable_to_non_nullable
as String,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PnlCostOfGoodsSold].
extension PnlCostOfGoodsSoldPatterns on PnlCostOfGoodsSold {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PnlCostOfGoodsSold value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PnlCostOfGoodsSold() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PnlCostOfGoodsSold value)  $default,){
final _that = this;
switch (_that) {
case _PnlCostOfGoodsSold():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PnlCostOfGoodsSold value)?  $default,){
final _that = this;
switch (_that) {
case _PnlCostOfGoodsSold() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String material,  String labor,  String overhead,  String total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PnlCostOfGoodsSold() when $default != null:
return $default(_that.material,_that.labor,_that.overhead,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String material,  String labor,  String overhead,  String total)  $default,) {final _that = this;
switch (_that) {
case _PnlCostOfGoodsSold():
return $default(_that.material,_that.labor,_that.overhead,_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String material,  String labor,  String overhead,  String total)?  $default,) {final _that = this;
switch (_that) {
case _PnlCostOfGoodsSold() when $default != null:
return $default(_that.material,_that.labor,_that.overhead,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PnlCostOfGoodsSold implements PnlCostOfGoodsSold {
  const _PnlCostOfGoodsSold({required this.material, required this.labor, required this.overhead, required this.total});
  factory _PnlCostOfGoodsSold.fromJson(Map<String, dynamic> json) => _$PnlCostOfGoodsSoldFromJson(json);

/// What left the shelves, at what the batches it came out of actually cost.
@override final  String material;
/// The two rate-driven costs, applied when an order first entered printing. American
/// spelling because that is the key on the wire.
@override final  String labor;
@override final  String overhead;
@override final  String total;

/// Create a copy of PnlCostOfGoodsSold
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PnlCostOfGoodsSoldCopyWith<_PnlCostOfGoodsSold> get copyWith => __$PnlCostOfGoodsSoldCopyWithImpl<_PnlCostOfGoodsSold>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PnlCostOfGoodsSoldToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PnlCostOfGoodsSold&&(identical(other.material, material) || other.material == material)&&(identical(other.labor, labor) || other.labor == labor)&&(identical(other.overhead, overhead) || other.overhead == overhead)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,material,labor,overhead,total);

@override
String toString() {
  return 'PnlCostOfGoodsSold(material: $material, labor: $labor, overhead: $overhead, total: $total)';
}


}

/// @nodoc
abstract mixin class _$PnlCostOfGoodsSoldCopyWith<$Res> implements $PnlCostOfGoodsSoldCopyWith<$Res> {
  factory _$PnlCostOfGoodsSoldCopyWith(_PnlCostOfGoodsSold value, $Res Function(_PnlCostOfGoodsSold) _then) = __$PnlCostOfGoodsSoldCopyWithImpl;
@override @useResult
$Res call({
 String material, String labor, String overhead, String total
});




}
/// @nodoc
class __$PnlCostOfGoodsSoldCopyWithImpl<$Res>
    implements _$PnlCostOfGoodsSoldCopyWith<$Res> {
  __$PnlCostOfGoodsSoldCopyWithImpl(this._self, this._then);

  final _PnlCostOfGoodsSold _self;
  final $Res Function(_PnlCostOfGoodsSold) _then;

/// Create a copy of PnlCostOfGoodsSold
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? material = null,Object? labor = null,Object? overhead = null,Object? total = null,}) {
  return _then(_PnlCostOfGoodsSold(
material: null == material ? _self.material : material // ignore: cast_nullable_to_non_nullable
as String,labor: null == labor ? _self.labor : labor // ignore: cast_nullable_to_non_nullable
as String,overhead: null == overhead ? _self.overhead : overhead // ignore: cast_nullable_to_non_nullable
as String,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
