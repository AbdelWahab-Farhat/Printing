// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'warehouse_stock_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WarehouseStockSummary {

/// How many sizes have ever been on these shelves. A line at zero is still a line — its
/// history is worth more than the tidiness of removing it.
@JsonKey(name: 'total_lines') int get totalLines;/// Every balance added together, as the string the server sent. A `double` here would be
/// the first step towards arithmetic this app has no business doing.
@JsonKey(name: 'total_quantity') String get totalQuantity;/// Has an alert level and has fallen to it.
@JsonKey(name: 'low_stock_count') int get lowStockCount;/// Nothing left on the shelf, whether or not anybody asked to be warned about it.
@JsonKey(name: 'out_of_stock_count') int get outOfStockCount;/// Neither low nor empty.
@JsonKey(name: 'healthy_count') int get healthyCount;
/// Create a copy of WarehouseStockSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WarehouseStockSummaryCopyWith<WarehouseStockSummary> get copyWith => _$WarehouseStockSummaryCopyWithImpl<WarehouseStockSummary>(this as WarehouseStockSummary, _$identity);

  /// Serializes this WarehouseStockSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WarehouseStockSummary&&(identical(other.totalLines, totalLines) || other.totalLines == totalLines)&&(identical(other.totalQuantity, totalQuantity) || other.totalQuantity == totalQuantity)&&(identical(other.lowStockCount, lowStockCount) || other.lowStockCount == lowStockCount)&&(identical(other.outOfStockCount, outOfStockCount) || other.outOfStockCount == outOfStockCount)&&(identical(other.healthyCount, healthyCount) || other.healthyCount == healthyCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalLines,totalQuantity,lowStockCount,outOfStockCount,healthyCount);

@override
String toString() {
  return 'WarehouseStockSummary(totalLines: $totalLines, totalQuantity: $totalQuantity, lowStockCount: $lowStockCount, outOfStockCount: $outOfStockCount, healthyCount: $healthyCount)';
}


}

/// @nodoc
abstract mixin class $WarehouseStockSummaryCopyWith<$Res>  {
  factory $WarehouseStockSummaryCopyWith(WarehouseStockSummary value, $Res Function(WarehouseStockSummary) _then) = _$WarehouseStockSummaryCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'total_lines') int totalLines,@JsonKey(name: 'total_quantity') String totalQuantity,@JsonKey(name: 'low_stock_count') int lowStockCount,@JsonKey(name: 'out_of_stock_count') int outOfStockCount,@JsonKey(name: 'healthy_count') int healthyCount
});




}
/// @nodoc
class _$WarehouseStockSummaryCopyWithImpl<$Res>
    implements $WarehouseStockSummaryCopyWith<$Res> {
  _$WarehouseStockSummaryCopyWithImpl(this._self, this._then);

  final WarehouseStockSummary _self;
  final $Res Function(WarehouseStockSummary) _then;

/// Create a copy of WarehouseStockSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalLines = null,Object? totalQuantity = null,Object? lowStockCount = null,Object? outOfStockCount = null,Object? healthyCount = null,}) {
  return _then(_self.copyWith(
totalLines: null == totalLines ? _self.totalLines : totalLines // ignore: cast_nullable_to_non_nullable
as int,totalQuantity: null == totalQuantity ? _self.totalQuantity : totalQuantity // ignore: cast_nullable_to_non_nullable
as String,lowStockCount: null == lowStockCount ? _self.lowStockCount : lowStockCount // ignore: cast_nullable_to_non_nullable
as int,outOfStockCount: null == outOfStockCount ? _self.outOfStockCount : outOfStockCount // ignore: cast_nullable_to_non_nullable
as int,healthyCount: null == healthyCount ? _self.healthyCount : healthyCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [WarehouseStockSummary].
extension WarehouseStockSummaryPatterns on WarehouseStockSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WarehouseStockSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WarehouseStockSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WarehouseStockSummary value)  $default,){
final _that = this;
switch (_that) {
case _WarehouseStockSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WarehouseStockSummary value)?  $default,){
final _that = this;
switch (_that) {
case _WarehouseStockSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'total_lines')  int totalLines, @JsonKey(name: 'total_quantity')  String totalQuantity, @JsonKey(name: 'low_stock_count')  int lowStockCount, @JsonKey(name: 'out_of_stock_count')  int outOfStockCount, @JsonKey(name: 'healthy_count')  int healthyCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WarehouseStockSummary() when $default != null:
return $default(_that.totalLines,_that.totalQuantity,_that.lowStockCount,_that.outOfStockCount,_that.healthyCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'total_lines')  int totalLines, @JsonKey(name: 'total_quantity')  String totalQuantity, @JsonKey(name: 'low_stock_count')  int lowStockCount, @JsonKey(name: 'out_of_stock_count')  int outOfStockCount, @JsonKey(name: 'healthy_count')  int healthyCount)  $default,) {final _that = this;
switch (_that) {
case _WarehouseStockSummary():
return $default(_that.totalLines,_that.totalQuantity,_that.lowStockCount,_that.outOfStockCount,_that.healthyCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'total_lines')  int totalLines, @JsonKey(name: 'total_quantity')  String totalQuantity, @JsonKey(name: 'low_stock_count')  int lowStockCount, @JsonKey(name: 'out_of_stock_count')  int outOfStockCount, @JsonKey(name: 'healthy_count')  int healthyCount)?  $default,) {final _that = this;
switch (_that) {
case _WarehouseStockSummary() when $default != null:
return $default(_that.totalLines,_that.totalQuantity,_that.lowStockCount,_that.outOfStockCount,_that.healthyCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WarehouseStockSummary extends WarehouseStockSummary {
  const _WarehouseStockSummary({@JsonKey(name: 'total_lines') this.totalLines = 0, @JsonKey(name: 'total_quantity') this.totalQuantity = '0.000', @JsonKey(name: 'low_stock_count') this.lowStockCount = 0, @JsonKey(name: 'out_of_stock_count') this.outOfStockCount = 0, @JsonKey(name: 'healthy_count') this.healthyCount = 0}): super._();
  factory _WarehouseStockSummary.fromJson(Map<String, dynamic> json) => _$WarehouseStockSummaryFromJson(json);

/// How many sizes have ever been on these shelves. A line at zero is still a line — its
/// history is worth more than the tidiness of removing it.
@override@JsonKey(name: 'total_lines') final  int totalLines;
/// Every balance added together, as the string the server sent. A `double` here would be
/// the first step towards arithmetic this app has no business doing.
@override@JsonKey(name: 'total_quantity') final  String totalQuantity;
/// Has an alert level and has fallen to it.
@override@JsonKey(name: 'low_stock_count') final  int lowStockCount;
/// Nothing left on the shelf, whether or not anybody asked to be warned about it.
@override@JsonKey(name: 'out_of_stock_count') final  int outOfStockCount;
/// Neither low nor empty.
@override@JsonKey(name: 'healthy_count') final  int healthyCount;

/// Create a copy of WarehouseStockSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WarehouseStockSummaryCopyWith<_WarehouseStockSummary> get copyWith => __$WarehouseStockSummaryCopyWithImpl<_WarehouseStockSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WarehouseStockSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WarehouseStockSummary&&(identical(other.totalLines, totalLines) || other.totalLines == totalLines)&&(identical(other.totalQuantity, totalQuantity) || other.totalQuantity == totalQuantity)&&(identical(other.lowStockCount, lowStockCount) || other.lowStockCount == lowStockCount)&&(identical(other.outOfStockCount, outOfStockCount) || other.outOfStockCount == outOfStockCount)&&(identical(other.healthyCount, healthyCount) || other.healthyCount == healthyCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalLines,totalQuantity,lowStockCount,outOfStockCount,healthyCount);

@override
String toString() {
  return 'WarehouseStockSummary(totalLines: $totalLines, totalQuantity: $totalQuantity, lowStockCount: $lowStockCount, outOfStockCount: $outOfStockCount, healthyCount: $healthyCount)';
}


}

/// @nodoc
abstract mixin class _$WarehouseStockSummaryCopyWith<$Res> implements $WarehouseStockSummaryCopyWith<$Res> {
  factory _$WarehouseStockSummaryCopyWith(_WarehouseStockSummary value, $Res Function(_WarehouseStockSummary) _then) = __$WarehouseStockSummaryCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'total_lines') int totalLines,@JsonKey(name: 'total_quantity') String totalQuantity,@JsonKey(name: 'low_stock_count') int lowStockCount,@JsonKey(name: 'out_of_stock_count') int outOfStockCount,@JsonKey(name: 'healthy_count') int healthyCount
});




}
/// @nodoc
class __$WarehouseStockSummaryCopyWithImpl<$Res>
    implements _$WarehouseStockSummaryCopyWith<$Res> {
  __$WarehouseStockSummaryCopyWithImpl(this._self, this._then);

  final _WarehouseStockSummary _self;
  final $Res Function(_WarehouseStockSummary) _then;

/// Create a copy of WarehouseStockSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalLines = null,Object? totalQuantity = null,Object? lowStockCount = null,Object? outOfStockCount = null,Object? healthyCount = null,}) {
  return _then(_WarehouseStockSummary(
totalLines: null == totalLines ? _self.totalLines : totalLines // ignore: cast_nullable_to_non_nullable
as int,totalQuantity: null == totalQuantity ? _self.totalQuantity : totalQuantity // ignore: cast_nullable_to_non_nullable
as String,lowStockCount: null == lowStockCount ? _self.lowStockCount : lowStockCount // ignore: cast_nullable_to_non_nullable
as int,outOfStockCount: null == outOfStockCount ? _self.outOfStockCount : outOfStockCount // ignore: cast_nullable_to_non_nullable
as int,healthyCount: null == healthyCount ? _self.healthyCount : healthyCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
