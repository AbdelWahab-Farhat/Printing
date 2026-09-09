// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sales_statistics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SalesStatistics {

 StatisticsPeriod get period;@JsonKey(name: 'sales_value') SalesValue get salesValue;@JsonKey(name: 'by_type') List<BagTypeRow> get byType;@JsonKey(name: 'weight_comparison') WeightComparison get weightComparison;/// How many printed bags that was, by the piece — **kept apart from the weights beside it**.
///
/// A different unit answering a different question, and the figure the printing engineer's
/// share will one day be computed from. Plain bags are absent from it by construction.
@JsonKey(name: 'printed_pieces') PrintedPieces get printedPieces;/// How many orders the whole board is actually about.
///
/// **The honest denominator**, and the same job `ordersRecognized` does on الأرباح والخسائر:
/// without it an all-zero board is unreadable, because it could mean the shop sold nothing
/// or it could mean the period was typed wrong. Only orders carrying at least one bag are
/// counted — an order of nothing but ستيكرات contributed nothing above and would inflate it.
@JsonKey(name: 'orders_counted') int get ordersCounted;
/// Create a copy of SalesStatistics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SalesStatisticsCopyWith<SalesStatistics> get copyWith => _$SalesStatisticsCopyWithImpl<SalesStatistics>(this as SalesStatistics, _$identity);

  /// Serializes this SalesStatistics to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SalesStatistics&&(identical(other.period, period) || other.period == period)&&(identical(other.salesValue, salesValue) || other.salesValue == salesValue)&&const DeepCollectionEquality().equals(other.byType, byType)&&(identical(other.weightComparison, weightComparison) || other.weightComparison == weightComparison)&&(identical(other.printedPieces, printedPieces) || other.printedPieces == printedPieces)&&(identical(other.ordersCounted, ordersCounted) || other.ordersCounted == ordersCounted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,period,salesValue,const DeepCollectionEquality().hash(byType),weightComparison,printedPieces,ordersCounted);

@override
String toString() {
  return 'SalesStatistics(period: $period, salesValue: $salesValue, byType: $byType, weightComparison: $weightComparison, printedPieces: $printedPieces, ordersCounted: $ordersCounted)';
}


}

/// @nodoc
abstract mixin class $SalesStatisticsCopyWith<$Res>  {
  factory $SalesStatisticsCopyWith(SalesStatistics value, $Res Function(SalesStatistics) _then) = _$SalesStatisticsCopyWithImpl;
@useResult
$Res call({
 StatisticsPeriod period,@JsonKey(name: 'sales_value') SalesValue salesValue,@JsonKey(name: 'by_type') List<BagTypeRow> byType,@JsonKey(name: 'weight_comparison') WeightComparison weightComparison,@JsonKey(name: 'printed_pieces') PrintedPieces printedPieces,@JsonKey(name: 'orders_counted') int ordersCounted
});


$StatisticsPeriodCopyWith<$Res> get period;$SalesValueCopyWith<$Res> get salesValue;$WeightComparisonCopyWith<$Res> get weightComparison;$PrintedPiecesCopyWith<$Res> get printedPieces;

}
/// @nodoc
class _$SalesStatisticsCopyWithImpl<$Res>
    implements $SalesStatisticsCopyWith<$Res> {
  _$SalesStatisticsCopyWithImpl(this._self, this._then);

  final SalesStatistics _self;
  final $Res Function(SalesStatistics) _then;

/// Create a copy of SalesStatistics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? period = null,Object? salesValue = null,Object? byType = null,Object? weightComparison = null,Object? printedPieces = null,Object? ordersCounted = null,}) {
  return _then(_self.copyWith(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as StatisticsPeriod,salesValue: null == salesValue ? _self.salesValue : salesValue // ignore: cast_nullable_to_non_nullable
as SalesValue,byType: null == byType ? _self.byType : byType // ignore: cast_nullable_to_non_nullable
as List<BagTypeRow>,weightComparison: null == weightComparison ? _self.weightComparison : weightComparison // ignore: cast_nullable_to_non_nullable
as WeightComparison,printedPieces: null == printedPieces ? _self.printedPieces : printedPieces // ignore: cast_nullable_to_non_nullable
as PrintedPieces,ordersCounted: null == ordersCounted ? _self.ordersCounted : ordersCounted // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of SalesStatistics
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatisticsPeriodCopyWith<$Res> get period {
  
  return $StatisticsPeriodCopyWith<$Res>(_self.period, (value) {
    return _then(_self.copyWith(period: value));
  });
}/// Create a copy of SalesStatistics
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SalesValueCopyWith<$Res> get salesValue {
  
  return $SalesValueCopyWith<$Res>(_self.salesValue, (value) {
    return _then(_self.copyWith(salesValue: value));
  });
}/// Create a copy of SalesStatistics
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WeightComparisonCopyWith<$Res> get weightComparison {
  
  return $WeightComparisonCopyWith<$Res>(_self.weightComparison, (value) {
    return _then(_self.copyWith(weightComparison: value));
  });
}/// Create a copy of SalesStatistics
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PrintedPiecesCopyWith<$Res> get printedPieces {
  
  return $PrintedPiecesCopyWith<$Res>(_self.printedPieces, (value) {
    return _then(_self.copyWith(printedPieces: value));
  });
}
}


/// Adds pattern-matching-related methods to [SalesStatistics].
extension SalesStatisticsPatterns on SalesStatistics {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SalesStatistics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SalesStatistics() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SalesStatistics value)  $default,){
final _that = this;
switch (_that) {
case _SalesStatistics():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SalesStatistics value)?  $default,){
final _that = this;
switch (_that) {
case _SalesStatistics() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( StatisticsPeriod period, @JsonKey(name: 'sales_value')  SalesValue salesValue, @JsonKey(name: 'by_type')  List<BagTypeRow> byType, @JsonKey(name: 'weight_comparison')  WeightComparison weightComparison, @JsonKey(name: 'printed_pieces')  PrintedPieces printedPieces, @JsonKey(name: 'orders_counted')  int ordersCounted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SalesStatistics() when $default != null:
return $default(_that.period,_that.salesValue,_that.byType,_that.weightComparison,_that.printedPieces,_that.ordersCounted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( StatisticsPeriod period, @JsonKey(name: 'sales_value')  SalesValue salesValue, @JsonKey(name: 'by_type')  List<BagTypeRow> byType, @JsonKey(name: 'weight_comparison')  WeightComparison weightComparison, @JsonKey(name: 'printed_pieces')  PrintedPieces printedPieces, @JsonKey(name: 'orders_counted')  int ordersCounted)  $default,) {final _that = this;
switch (_that) {
case _SalesStatistics():
return $default(_that.period,_that.salesValue,_that.byType,_that.weightComparison,_that.printedPieces,_that.ordersCounted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( StatisticsPeriod period, @JsonKey(name: 'sales_value')  SalesValue salesValue, @JsonKey(name: 'by_type')  List<BagTypeRow> byType, @JsonKey(name: 'weight_comparison')  WeightComparison weightComparison, @JsonKey(name: 'printed_pieces')  PrintedPieces printedPieces, @JsonKey(name: 'orders_counted')  int ordersCounted)?  $default,) {final _that = this;
switch (_that) {
case _SalesStatistics() when $default != null:
return $default(_that.period,_that.salesValue,_that.byType,_that.weightComparison,_that.printedPieces,_that.ordersCounted);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SalesStatistics extends SalesStatistics {
  const _SalesStatistics({required this.period, @JsonKey(name: 'sales_value') required this.salesValue, @JsonKey(name: 'by_type') required final  List<BagTypeRow> byType, @JsonKey(name: 'weight_comparison') required this.weightComparison, @JsonKey(name: 'printed_pieces') required this.printedPieces, @JsonKey(name: 'orders_counted') required this.ordersCounted}): _byType = byType,super._();
  factory _SalesStatistics.fromJson(Map<String, dynamic> json) => _$SalesStatisticsFromJson(json);

@override final  StatisticsPeriod period;
@override@JsonKey(name: 'sales_value') final  SalesValue salesValue;
 final  List<BagTypeRow> _byType;
@override@JsonKey(name: 'by_type') List<BagTypeRow> get byType {
  if (_byType is EqualUnmodifiableListView) return _byType;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_byType);
}

@override@JsonKey(name: 'weight_comparison') final  WeightComparison weightComparison;
/// How many printed bags that was, by the piece — **kept apart from the weights beside it**.
///
/// A different unit answering a different question, and the figure the printing engineer's
/// share will one day be computed from. Plain bags are absent from it by construction.
@override@JsonKey(name: 'printed_pieces') final  PrintedPieces printedPieces;
/// How many orders the whole board is actually about.
///
/// **The honest denominator**, and the same job `ordersRecognized` does on الأرباح والخسائر:
/// without it an all-zero board is unreadable, because it could mean the shop sold nothing
/// or it could mean the period was typed wrong. Only orders carrying at least one bag are
/// counted — an order of nothing but ستيكرات contributed nothing above and would inflate it.
@override@JsonKey(name: 'orders_counted') final  int ordersCounted;

/// Create a copy of SalesStatistics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SalesStatisticsCopyWith<_SalesStatistics> get copyWith => __$SalesStatisticsCopyWithImpl<_SalesStatistics>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SalesStatisticsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SalesStatistics&&(identical(other.period, period) || other.period == period)&&(identical(other.salesValue, salesValue) || other.salesValue == salesValue)&&const DeepCollectionEquality().equals(other._byType, _byType)&&(identical(other.weightComparison, weightComparison) || other.weightComparison == weightComparison)&&(identical(other.printedPieces, printedPieces) || other.printedPieces == printedPieces)&&(identical(other.ordersCounted, ordersCounted) || other.ordersCounted == ordersCounted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,period,salesValue,const DeepCollectionEquality().hash(_byType),weightComparison,printedPieces,ordersCounted);

@override
String toString() {
  return 'SalesStatistics(period: $period, salesValue: $salesValue, byType: $byType, weightComparison: $weightComparison, printedPieces: $printedPieces, ordersCounted: $ordersCounted)';
}


}

/// @nodoc
abstract mixin class _$SalesStatisticsCopyWith<$Res> implements $SalesStatisticsCopyWith<$Res> {
  factory _$SalesStatisticsCopyWith(_SalesStatistics value, $Res Function(_SalesStatistics) _then) = __$SalesStatisticsCopyWithImpl;
@override @useResult
$Res call({
 StatisticsPeriod period,@JsonKey(name: 'sales_value') SalesValue salesValue,@JsonKey(name: 'by_type') List<BagTypeRow> byType,@JsonKey(name: 'weight_comparison') WeightComparison weightComparison,@JsonKey(name: 'printed_pieces') PrintedPieces printedPieces,@JsonKey(name: 'orders_counted') int ordersCounted
});


@override $StatisticsPeriodCopyWith<$Res> get period;@override $SalesValueCopyWith<$Res> get salesValue;@override $WeightComparisonCopyWith<$Res> get weightComparison;@override $PrintedPiecesCopyWith<$Res> get printedPieces;

}
/// @nodoc
class __$SalesStatisticsCopyWithImpl<$Res>
    implements _$SalesStatisticsCopyWith<$Res> {
  __$SalesStatisticsCopyWithImpl(this._self, this._then);

  final _SalesStatistics _self;
  final $Res Function(_SalesStatistics) _then;

/// Create a copy of SalesStatistics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? period = null,Object? salesValue = null,Object? byType = null,Object? weightComparison = null,Object? printedPieces = null,Object? ordersCounted = null,}) {
  return _then(_SalesStatistics(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as StatisticsPeriod,salesValue: null == salesValue ? _self.salesValue : salesValue // ignore: cast_nullable_to_non_nullable
as SalesValue,byType: null == byType ? _self._byType : byType // ignore: cast_nullable_to_non_nullable
as List<BagTypeRow>,weightComparison: null == weightComparison ? _self.weightComparison : weightComparison // ignore: cast_nullable_to_non_nullable
as WeightComparison,printedPieces: null == printedPieces ? _self.printedPieces : printedPieces // ignore: cast_nullable_to_non_nullable
as PrintedPieces,ordersCounted: null == ordersCounted ? _self.ordersCounted : ordersCounted // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of SalesStatistics
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatisticsPeriodCopyWith<$Res> get period {
  
  return $StatisticsPeriodCopyWith<$Res>(_self.period, (value) {
    return _then(_self.copyWith(period: value));
  });
}/// Create a copy of SalesStatistics
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SalesValueCopyWith<$Res> get salesValue {
  
  return $SalesValueCopyWith<$Res>(_self.salesValue, (value) {
    return _then(_self.copyWith(salesValue: value));
  });
}/// Create a copy of SalesStatistics
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WeightComparisonCopyWith<$Res> get weightComparison {
  
  return $WeightComparisonCopyWith<$Res>(_self.weightComparison, (value) {
    return _then(_self.copyWith(weightComparison: value));
  });
}/// Create a copy of SalesStatistics
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PrintedPiecesCopyWith<$Res> get printedPieces {
  
  return $PrintedPiecesCopyWith<$Res>(_self.printedPieces, (value) {
    return _then(_self.copyWith(printedPieces: value));
  });
}
}


/// @nodoc
mixin _$StatisticsPeriod {

 String get from; String get to;
/// Create a copy of StatisticsPeriod
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatisticsPeriodCopyWith<StatisticsPeriod> get copyWith => _$StatisticsPeriodCopyWithImpl<StatisticsPeriod>(this as StatisticsPeriod, _$identity);

  /// Serializes this StatisticsPeriod to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatisticsPeriod&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,from,to);

@override
String toString() {
  return 'StatisticsPeriod(from: $from, to: $to)';
}


}

/// @nodoc
abstract mixin class $StatisticsPeriodCopyWith<$Res>  {
  factory $StatisticsPeriodCopyWith(StatisticsPeriod value, $Res Function(StatisticsPeriod) _then) = _$StatisticsPeriodCopyWithImpl;
@useResult
$Res call({
 String from, String to
});




}
/// @nodoc
class _$StatisticsPeriodCopyWithImpl<$Res>
    implements $StatisticsPeriodCopyWith<$Res> {
  _$StatisticsPeriodCopyWithImpl(this._self, this._then);

  final StatisticsPeriod _self;
  final $Res Function(StatisticsPeriod) _then;

/// Create a copy of StatisticsPeriod
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? from = null,Object? to = null,}) {
  return _then(_self.copyWith(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [StatisticsPeriod].
extension StatisticsPeriodPatterns on StatisticsPeriod {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StatisticsPeriod value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StatisticsPeriod() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StatisticsPeriod value)  $default,){
final _that = this;
switch (_that) {
case _StatisticsPeriod():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StatisticsPeriod value)?  $default,){
final _that = this;
switch (_that) {
case _StatisticsPeriod() when $default != null:
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
case _StatisticsPeriod() when $default != null:
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
case _StatisticsPeriod():
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
case _StatisticsPeriod() when $default != null:
return $default(_that.from,_that.to);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StatisticsPeriod extends StatisticsPeriod {
  const _StatisticsPeriod({required this.from, required this.to}): super._();
  factory _StatisticsPeriod.fromJson(Map<String, dynamic> json) => _$StatisticsPeriodFromJson(json);

@override final  String from;
@override final  String to;

/// Create a copy of StatisticsPeriod
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StatisticsPeriodCopyWith<_StatisticsPeriod> get copyWith => __$StatisticsPeriodCopyWithImpl<_StatisticsPeriod>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StatisticsPeriodToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StatisticsPeriod&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,from,to);

@override
String toString() {
  return 'StatisticsPeriod(from: $from, to: $to)';
}


}

/// @nodoc
abstract mixin class _$StatisticsPeriodCopyWith<$Res> implements $StatisticsPeriodCopyWith<$Res> {
  factory _$StatisticsPeriodCopyWith(_StatisticsPeriod value, $Res Function(_StatisticsPeriod) _then) = __$StatisticsPeriodCopyWithImpl;
@override @useResult
$Res call({
 String from, String to
});




}
/// @nodoc
class __$StatisticsPeriodCopyWithImpl<$Res>
    implements _$StatisticsPeriodCopyWith<$Res> {
  __$StatisticsPeriodCopyWithImpl(this._self, this._then);

  final _StatisticsPeriod _self;
  final $Res Function(_StatisticsPeriod) _then;

/// Create a copy of StatisticsPeriod
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? from = null,Object? to = null,}) {
  return _then(_StatisticsPeriod(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as String,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$SalesValue {

 String get plain; String get printed; String get total;
/// Create a copy of SalesValue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SalesValueCopyWith<SalesValue> get copyWith => _$SalesValueCopyWithImpl<SalesValue>(this as SalesValue, _$identity);

  /// Serializes this SalesValue to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SalesValue&&(identical(other.plain, plain) || other.plain == plain)&&(identical(other.printed, printed) || other.printed == printed)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,plain,printed,total);

@override
String toString() {
  return 'SalesValue(plain: $plain, printed: $printed, total: $total)';
}


}

/// @nodoc
abstract mixin class $SalesValueCopyWith<$Res>  {
  factory $SalesValueCopyWith(SalesValue value, $Res Function(SalesValue) _then) = _$SalesValueCopyWithImpl;
@useResult
$Res call({
 String plain, String printed, String total
});




}
/// @nodoc
class _$SalesValueCopyWithImpl<$Res>
    implements $SalesValueCopyWith<$Res> {
  _$SalesValueCopyWithImpl(this._self, this._then);

  final SalesValue _self;
  final $Res Function(SalesValue) _then;

/// Create a copy of SalesValue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? plain = null,Object? printed = null,Object? total = null,}) {
  return _then(_self.copyWith(
plain: null == plain ? _self.plain : plain // ignore: cast_nullable_to_non_nullable
as String,printed: null == printed ? _self.printed : printed // ignore: cast_nullable_to_non_nullable
as String,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SalesValue].
extension SalesValuePatterns on SalesValue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SalesValue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SalesValue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SalesValue value)  $default,){
final _that = this;
switch (_that) {
case _SalesValue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SalesValue value)?  $default,){
final _that = this;
switch (_that) {
case _SalesValue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String plain,  String printed,  String total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SalesValue() when $default != null:
return $default(_that.plain,_that.printed,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String plain,  String printed,  String total)  $default,) {final _that = this;
switch (_that) {
case _SalesValue():
return $default(_that.plain,_that.printed,_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String plain,  String printed,  String total)?  $default,) {final _that = this;
switch (_that) {
case _SalesValue() when $default != null:
return $default(_that.plain,_that.printed,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SalesValue implements SalesValue {
  const _SalesValue({required this.plain, required this.printed, required this.total});
  factory _SalesValue.fromJson(Map<String, dynamic> json) => _$SalesValueFromJson(json);

@override final  String plain;
@override final  String printed;
@override final  String total;

/// Create a copy of SalesValue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SalesValueCopyWith<_SalesValue> get copyWith => __$SalesValueCopyWithImpl<_SalesValue>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SalesValueToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SalesValue&&(identical(other.plain, plain) || other.plain == plain)&&(identical(other.printed, printed) || other.printed == printed)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,plain,printed,total);

@override
String toString() {
  return 'SalesValue(plain: $plain, printed: $printed, total: $total)';
}


}

/// @nodoc
abstract mixin class _$SalesValueCopyWith<$Res> implements $SalesValueCopyWith<$Res> {
  factory _$SalesValueCopyWith(_SalesValue value, $Res Function(_SalesValue) _then) = __$SalesValueCopyWithImpl;
@override @useResult
$Res call({
 String plain, String printed, String total
});




}
/// @nodoc
class __$SalesValueCopyWithImpl<$Res>
    implements _$SalesValueCopyWith<$Res> {
  __$SalesValueCopyWithImpl(this._self, this._then);

  final _SalesValue _self;
  final $Res Function(_SalesValue) _then;

/// Create a copy of SalesValue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? plain = null,Object? printed = null,Object? total = null,}) {
  return _then(_SalesValue(
plain: null == plain ? _self.plain : plain // ignore: cast_nullable_to_non_nullable
as String,printed: null == printed ? _self.printed : printed // ignore: cast_nullable_to_non_nullable
as String,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$BagTypeRow {

 String get type; String get value;@JsonKey(name: 'weight_kg') String get weightKg;@JsonKey(name: 'plain_kg') String get plainKg;@JsonKey(name: 'printed_kg') String get printedKg;/// Printed pieces on this material only; a plain row carries `0`.
 int get pieces;
/// Create a copy of BagTypeRow
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BagTypeRowCopyWith<BagTypeRow> get copyWith => _$BagTypeRowCopyWithImpl<BagTypeRow>(this as BagTypeRow, _$identity);

  /// Serializes this BagTypeRow to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BagTypeRow&&(identical(other.type, type) || other.type == type)&&(identical(other.value, value) || other.value == value)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.plainKg, plainKg) || other.plainKg == plainKg)&&(identical(other.printedKg, printedKg) || other.printedKg == printedKg)&&(identical(other.pieces, pieces) || other.pieces == pieces));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,value,weightKg,plainKg,printedKg,pieces);

@override
String toString() {
  return 'BagTypeRow(type: $type, value: $value, weightKg: $weightKg, plainKg: $plainKg, printedKg: $printedKg, pieces: $pieces)';
}


}

/// @nodoc
abstract mixin class $BagTypeRowCopyWith<$Res>  {
  factory $BagTypeRowCopyWith(BagTypeRow value, $Res Function(BagTypeRow) _then) = _$BagTypeRowCopyWithImpl;
@useResult
$Res call({
 String type, String value,@JsonKey(name: 'weight_kg') String weightKg,@JsonKey(name: 'plain_kg') String plainKg,@JsonKey(name: 'printed_kg') String printedKg, int pieces
});




}
/// @nodoc
class _$BagTypeRowCopyWithImpl<$Res>
    implements $BagTypeRowCopyWith<$Res> {
  _$BagTypeRowCopyWithImpl(this._self, this._then);

  final BagTypeRow _self;
  final $Res Function(BagTypeRow) _then;

/// Create a copy of BagTypeRow
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? value = null,Object? weightKg = null,Object? plainKg = null,Object? printedKg = null,Object? pieces = null,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,weightKg: null == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as String,plainKg: null == plainKg ? _self.plainKg : plainKg // ignore: cast_nullable_to_non_nullable
as String,printedKg: null == printedKg ? _self.printedKg : printedKg // ignore: cast_nullable_to_non_nullable
as String,pieces: null == pieces ? _self.pieces : pieces // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BagTypeRow].
extension BagTypeRowPatterns on BagTypeRow {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BagTypeRow value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BagTypeRow() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BagTypeRow value)  $default,){
final _that = this;
switch (_that) {
case _BagTypeRow():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BagTypeRow value)?  $default,){
final _that = this;
switch (_that) {
case _BagTypeRow() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type,  String value, @JsonKey(name: 'weight_kg')  String weightKg, @JsonKey(name: 'plain_kg')  String plainKg, @JsonKey(name: 'printed_kg')  String printedKg,  int pieces)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BagTypeRow() when $default != null:
return $default(_that.type,_that.value,_that.weightKg,_that.plainKg,_that.printedKg,_that.pieces);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type,  String value, @JsonKey(name: 'weight_kg')  String weightKg, @JsonKey(name: 'plain_kg')  String plainKg, @JsonKey(name: 'printed_kg')  String printedKg,  int pieces)  $default,) {final _that = this;
switch (_that) {
case _BagTypeRow():
return $default(_that.type,_that.value,_that.weightKg,_that.plainKg,_that.printedKg,_that.pieces);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type,  String value, @JsonKey(name: 'weight_kg')  String weightKg, @JsonKey(name: 'plain_kg')  String plainKg, @JsonKey(name: 'printed_kg')  String printedKg,  int pieces)?  $default,) {final _that = this;
switch (_that) {
case _BagTypeRow() when $default != null:
return $default(_that.type,_that.value,_that.weightKg,_that.plainKg,_that.printedKg,_that.pieces);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BagTypeRow extends BagTypeRow {
  const _BagTypeRow({required this.type, required this.value, @JsonKey(name: 'weight_kg') required this.weightKg, @JsonKey(name: 'plain_kg') required this.plainKg, @JsonKey(name: 'printed_kg') required this.printedKg, required this.pieces}): super._();
  factory _BagTypeRow.fromJson(Map<String, dynamic> json) => _$BagTypeRowFromJson(json);

@override final  String type;
@override final  String value;
@override@JsonKey(name: 'weight_kg') final  String weightKg;
@override@JsonKey(name: 'plain_kg') final  String plainKg;
@override@JsonKey(name: 'printed_kg') final  String printedKg;
/// Printed pieces on this material only; a plain row carries `0`.
@override final  int pieces;

/// Create a copy of BagTypeRow
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BagTypeRowCopyWith<_BagTypeRow> get copyWith => __$BagTypeRowCopyWithImpl<_BagTypeRow>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BagTypeRowToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BagTypeRow&&(identical(other.type, type) || other.type == type)&&(identical(other.value, value) || other.value == value)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.plainKg, plainKg) || other.plainKg == plainKg)&&(identical(other.printedKg, printedKg) || other.printedKg == printedKg)&&(identical(other.pieces, pieces) || other.pieces == pieces));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,value,weightKg,plainKg,printedKg,pieces);

@override
String toString() {
  return 'BagTypeRow(type: $type, value: $value, weightKg: $weightKg, plainKg: $plainKg, printedKg: $printedKg, pieces: $pieces)';
}


}

/// @nodoc
abstract mixin class _$BagTypeRowCopyWith<$Res> implements $BagTypeRowCopyWith<$Res> {
  factory _$BagTypeRowCopyWith(_BagTypeRow value, $Res Function(_BagTypeRow) _then) = __$BagTypeRowCopyWithImpl;
@override @useResult
$Res call({
 String type, String value,@JsonKey(name: 'weight_kg') String weightKg,@JsonKey(name: 'plain_kg') String plainKg,@JsonKey(name: 'printed_kg') String printedKg, int pieces
});




}
/// @nodoc
class __$BagTypeRowCopyWithImpl<$Res>
    implements _$BagTypeRowCopyWith<$Res> {
  __$BagTypeRowCopyWithImpl(this._self, this._then);

  final _BagTypeRow _self;
  final $Res Function(_BagTypeRow) _then;

/// Create a copy of BagTypeRow
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? value = null,Object? weightKg = null,Object? plainKg = null,Object? printedKg = null,Object? pieces = null,}) {
  return _then(_BagTypeRow(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,weightKg: null == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as String,plainKg: null == plainKg ? _self.plainKg : plainKg // ignore: cast_nullable_to_non_nullable
as String,printedKg: null == printedKg ? _self.printedKg : printedKg // ignore: cast_nullable_to_non_nullable
as String,pieces: null == pieces ? _self.pieces : pieces // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$WeightComparison {

@JsonKey(name: 'plain_kg') String get plainKg;@JsonKey(name: 'printed_kg') String get printedKg;@JsonKey(name: 'total_kg') String get totalKg;/// «كم نسبة المطبوع؟» — the server's own division, to one decimal place.
///
/// **Never recomputed from the two weights beside it.** It is the question the whole
/// comparison exists to answer, and it is answered once, on the server.
@JsonKey(name: 'printed_share_percent') String get printedSharePercent;/// How much of the period's *value* has a weight behind it.
///
/// Three kinds of line legitimately have none: work a vendor made, a size with no shelf, and
/// a shelf counted in pieces. Without this figure a month full of any of them shows a weight
/// that looks wrong beside its own dinars, and no reader can tell «باعوا قليلاً» from «ما
/// وزنوهش».
@JsonKey(name: 'weight_coverage_percent') String get weightCoveragePercent;
/// Create a copy of WeightComparison
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeightComparisonCopyWith<WeightComparison> get copyWith => _$WeightComparisonCopyWithImpl<WeightComparison>(this as WeightComparison, _$identity);

  /// Serializes this WeightComparison to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeightComparison&&(identical(other.plainKg, plainKg) || other.plainKg == plainKg)&&(identical(other.printedKg, printedKg) || other.printedKg == printedKg)&&(identical(other.totalKg, totalKg) || other.totalKg == totalKg)&&(identical(other.printedSharePercent, printedSharePercent) || other.printedSharePercent == printedSharePercent)&&(identical(other.weightCoveragePercent, weightCoveragePercent) || other.weightCoveragePercent == weightCoveragePercent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,plainKg,printedKg,totalKg,printedSharePercent,weightCoveragePercent);

@override
String toString() {
  return 'WeightComparison(plainKg: $plainKg, printedKg: $printedKg, totalKg: $totalKg, printedSharePercent: $printedSharePercent, weightCoveragePercent: $weightCoveragePercent)';
}


}

/// @nodoc
abstract mixin class $WeightComparisonCopyWith<$Res>  {
  factory $WeightComparisonCopyWith(WeightComparison value, $Res Function(WeightComparison) _then) = _$WeightComparisonCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'plain_kg') String plainKg,@JsonKey(name: 'printed_kg') String printedKg,@JsonKey(name: 'total_kg') String totalKg,@JsonKey(name: 'printed_share_percent') String printedSharePercent,@JsonKey(name: 'weight_coverage_percent') String weightCoveragePercent
});




}
/// @nodoc
class _$WeightComparisonCopyWithImpl<$Res>
    implements $WeightComparisonCopyWith<$Res> {
  _$WeightComparisonCopyWithImpl(this._self, this._then);

  final WeightComparison _self;
  final $Res Function(WeightComparison) _then;

/// Create a copy of WeightComparison
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? plainKg = null,Object? printedKg = null,Object? totalKg = null,Object? printedSharePercent = null,Object? weightCoveragePercent = null,}) {
  return _then(_self.copyWith(
plainKg: null == plainKg ? _self.plainKg : plainKg // ignore: cast_nullable_to_non_nullable
as String,printedKg: null == printedKg ? _self.printedKg : printedKg // ignore: cast_nullable_to_non_nullable
as String,totalKg: null == totalKg ? _self.totalKg : totalKg // ignore: cast_nullable_to_non_nullable
as String,printedSharePercent: null == printedSharePercent ? _self.printedSharePercent : printedSharePercent // ignore: cast_nullable_to_non_nullable
as String,weightCoveragePercent: null == weightCoveragePercent ? _self.weightCoveragePercent : weightCoveragePercent // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WeightComparison].
extension WeightComparisonPatterns on WeightComparison {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeightComparison value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeightComparison() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeightComparison value)  $default,){
final _that = this;
switch (_that) {
case _WeightComparison():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeightComparison value)?  $default,){
final _that = this;
switch (_that) {
case _WeightComparison() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'plain_kg')  String plainKg, @JsonKey(name: 'printed_kg')  String printedKg, @JsonKey(name: 'total_kg')  String totalKg, @JsonKey(name: 'printed_share_percent')  String printedSharePercent, @JsonKey(name: 'weight_coverage_percent')  String weightCoveragePercent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeightComparison() when $default != null:
return $default(_that.plainKg,_that.printedKg,_that.totalKg,_that.printedSharePercent,_that.weightCoveragePercent);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'plain_kg')  String plainKg, @JsonKey(name: 'printed_kg')  String printedKg, @JsonKey(name: 'total_kg')  String totalKg, @JsonKey(name: 'printed_share_percent')  String printedSharePercent, @JsonKey(name: 'weight_coverage_percent')  String weightCoveragePercent)  $default,) {final _that = this;
switch (_that) {
case _WeightComparison():
return $default(_that.plainKg,_that.printedKg,_that.totalKg,_that.printedSharePercent,_that.weightCoveragePercent);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'plain_kg')  String plainKg, @JsonKey(name: 'printed_kg')  String printedKg, @JsonKey(name: 'total_kg')  String totalKg, @JsonKey(name: 'printed_share_percent')  String printedSharePercent, @JsonKey(name: 'weight_coverage_percent')  String weightCoveragePercent)?  $default,) {final _that = this;
switch (_that) {
case _WeightComparison() when $default != null:
return $default(_that.plainKg,_that.printedKg,_that.totalKg,_that.printedSharePercent,_that.weightCoveragePercent);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WeightComparison extends WeightComparison {
  const _WeightComparison({@JsonKey(name: 'plain_kg') required this.plainKg, @JsonKey(name: 'printed_kg') required this.printedKg, @JsonKey(name: 'total_kg') required this.totalKg, @JsonKey(name: 'printed_share_percent') required this.printedSharePercent, @JsonKey(name: 'weight_coverage_percent') required this.weightCoveragePercent}): super._();
  factory _WeightComparison.fromJson(Map<String, dynamic> json) => _$WeightComparisonFromJson(json);

@override@JsonKey(name: 'plain_kg') final  String plainKg;
@override@JsonKey(name: 'printed_kg') final  String printedKg;
@override@JsonKey(name: 'total_kg') final  String totalKg;
/// «كم نسبة المطبوع؟» — the server's own division, to one decimal place.
///
/// **Never recomputed from the two weights beside it.** It is the question the whole
/// comparison exists to answer, and it is answered once, on the server.
@override@JsonKey(name: 'printed_share_percent') final  String printedSharePercent;
/// How much of the period's *value* has a weight behind it.
///
/// Three kinds of line legitimately have none: work a vendor made, a size with no shelf, and
/// a shelf counted in pieces. Without this figure a month full of any of them shows a weight
/// that looks wrong beside its own dinars, and no reader can tell «باعوا قليلاً» from «ما
/// وزنوهش».
@override@JsonKey(name: 'weight_coverage_percent') final  String weightCoveragePercent;

/// Create a copy of WeightComparison
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeightComparisonCopyWith<_WeightComparison> get copyWith => __$WeightComparisonCopyWithImpl<_WeightComparison>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WeightComparisonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeightComparison&&(identical(other.plainKg, plainKg) || other.plainKg == plainKg)&&(identical(other.printedKg, printedKg) || other.printedKg == printedKg)&&(identical(other.totalKg, totalKg) || other.totalKg == totalKg)&&(identical(other.printedSharePercent, printedSharePercent) || other.printedSharePercent == printedSharePercent)&&(identical(other.weightCoveragePercent, weightCoveragePercent) || other.weightCoveragePercent == weightCoveragePercent));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,plainKg,printedKg,totalKg,printedSharePercent,weightCoveragePercent);

@override
String toString() {
  return 'WeightComparison(plainKg: $plainKg, printedKg: $printedKg, totalKg: $totalKg, printedSharePercent: $printedSharePercent, weightCoveragePercent: $weightCoveragePercent)';
}


}

/// @nodoc
abstract mixin class _$WeightComparisonCopyWith<$Res> implements $WeightComparisonCopyWith<$Res> {
  factory _$WeightComparisonCopyWith(_WeightComparison value, $Res Function(_WeightComparison) _then) = __$WeightComparisonCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'plain_kg') String plainKg,@JsonKey(name: 'printed_kg') String printedKg,@JsonKey(name: 'total_kg') String totalKg,@JsonKey(name: 'printed_share_percent') String printedSharePercent,@JsonKey(name: 'weight_coverage_percent') String weightCoveragePercent
});




}
/// @nodoc
class __$WeightComparisonCopyWithImpl<$Res>
    implements _$WeightComparisonCopyWith<$Res> {
  __$WeightComparisonCopyWithImpl(this._self, this._then);

  final _WeightComparison _self;
  final $Res Function(_WeightComparison) _then;

/// Create a copy of WeightComparison
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? plainKg = null,Object? printedKg = null,Object? totalKg = null,Object? printedSharePercent = null,Object? weightCoveragePercent = null,}) {
  return _then(_WeightComparison(
plainKg: null == plainKg ? _self.plainKg : plainKg // ignore: cast_nullable_to_non_nullable
as String,printedKg: null == printedKg ? _self.printedKg : printedKg // ignore: cast_nullable_to_non_nullable
as String,totalKg: null == totalKg ? _self.totalKg : totalKg // ignore: cast_nullable_to_non_nullable
as String,printedSharePercent: null == printedSharePercent ? _self.printedSharePercent : printedSharePercent // ignore: cast_nullable_to_non_nullable
as String,weightCoveragePercent: null == weightCoveragePercent ? _self.weightCoveragePercent : weightCoveragePercent // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PrintedPieces {

 int get count;@JsonKey(name: 'weight_kg') String get weightKg;
/// Create a copy of PrintedPieces
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PrintedPiecesCopyWith<PrintedPieces> get copyWith => _$PrintedPiecesCopyWithImpl<PrintedPieces>(this as PrintedPieces, _$identity);

  /// Serializes this PrintedPieces to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PrintedPieces&&(identical(other.count, count) || other.count == count)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,count,weightKg);

@override
String toString() {
  return 'PrintedPieces(count: $count, weightKg: $weightKg)';
}


}

/// @nodoc
abstract mixin class $PrintedPiecesCopyWith<$Res>  {
  factory $PrintedPiecesCopyWith(PrintedPieces value, $Res Function(PrintedPieces) _then) = _$PrintedPiecesCopyWithImpl;
@useResult
$Res call({
 int count,@JsonKey(name: 'weight_kg') String weightKg
});




}
/// @nodoc
class _$PrintedPiecesCopyWithImpl<$Res>
    implements $PrintedPiecesCopyWith<$Res> {
  _$PrintedPiecesCopyWithImpl(this._self, this._then);

  final PrintedPieces _self;
  final $Res Function(PrintedPieces) _then;

/// Create a copy of PrintedPieces
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? count = null,Object? weightKg = null,}) {
  return _then(_self.copyWith(
count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,weightKg: null == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PrintedPieces].
extension PrintedPiecesPatterns on PrintedPieces {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PrintedPieces value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PrintedPieces() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PrintedPieces value)  $default,){
final _that = this;
switch (_that) {
case _PrintedPieces():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PrintedPieces value)?  $default,){
final _that = this;
switch (_that) {
case _PrintedPieces() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int count, @JsonKey(name: 'weight_kg')  String weightKg)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PrintedPieces() when $default != null:
return $default(_that.count,_that.weightKg);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int count, @JsonKey(name: 'weight_kg')  String weightKg)  $default,) {final _that = this;
switch (_that) {
case _PrintedPieces():
return $default(_that.count,_that.weightKg);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int count, @JsonKey(name: 'weight_kg')  String weightKg)?  $default,) {final _that = this;
switch (_that) {
case _PrintedPieces() when $default != null:
return $default(_that.count,_that.weightKg);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PrintedPieces extends PrintedPieces {
  const _PrintedPieces({required this.count, @JsonKey(name: 'weight_kg') required this.weightKg}): super._();
  factory _PrintedPieces.fromJson(Map<String, dynamic> json) => _$PrintedPiecesFromJson(json);

@override final  int count;
@override@JsonKey(name: 'weight_kg') final  String weightKg;

/// Create a copy of PrintedPieces
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PrintedPiecesCopyWith<_PrintedPieces> get copyWith => __$PrintedPiecesCopyWithImpl<_PrintedPieces>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PrintedPiecesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PrintedPieces&&(identical(other.count, count) || other.count == count)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,count,weightKg);

@override
String toString() {
  return 'PrintedPieces(count: $count, weightKg: $weightKg)';
}


}

/// @nodoc
abstract mixin class _$PrintedPiecesCopyWith<$Res> implements $PrintedPiecesCopyWith<$Res> {
  factory _$PrintedPiecesCopyWith(_PrintedPieces value, $Res Function(_PrintedPieces) _then) = __$PrintedPiecesCopyWithImpl;
@override @useResult
$Res call({
 int count,@JsonKey(name: 'weight_kg') String weightKg
});




}
/// @nodoc
class __$PrintedPiecesCopyWithImpl<$Res>
    implements _$PrintedPiecesCopyWith<$Res> {
  __$PrintedPiecesCopyWithImpl(this._self, this._then);

  final _PrintedPieces _self;
  final $Res Function(_PrintedPieces) _then;

/// Create a copy of PrintedPieces
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? count = null,Object? weightKg = null,}) {
  return _then(_PrintedPieces(
count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,weightKg: null == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
