// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HomeSummary {

@JsonKey(name: 'total_orders') int get totalOrders;@JsonKey(name: 'customers_count') int get customersCount;@JsonKey(name: 'daily_orders') int get dailyOrders;@JsonKey(name: 'monthly_orders') int get monthlyOrders;/// How the work in progress is split up.
///
/// A list, not a field per status, because the set of statuses is the business's to change:
/// adding "بانتظار الطباعة" should be a row from the server, not a release of the app.
 List<OrderStatusCount> get statuses;/// Where the money stands, one row per payment state.
///
/// **A second axis beside [statuses], not a slice of it.** An order can be finished and
/// unpaid, or paid before it is printed, so «كم طلبية لم تُدفع» is unanswerable from the
/// counts above — which is why it arrives as its own list rather than as another status.
///
/// Defaulted, so a build of the API that predates payments still parses.
 List<OrderStatusCount> get payments;
/// Create a copy of HomeSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeSummaryCopyWith<HomeSummary> get copyWith => _$HomeSummaryCopyWithImpl<HomeSummary>(this as HomeSummary, _$identity);

  /// Serializes this HomeSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeSummary&&(identical(other.totalOrders, totalOrders) || other.totalOrders == totalOrders)&&(identical(other.customersCount, customersCount) || other.customersCount == customersCount)&&(identical(other.dailyOrders, dailyOrders) || other.dailyOrders == dailyOrders)&&(identical(other.monthlyOrders, monthlyOrders) || other.monthlyOrders == monthlyOrders)&&const DeepCollectionEquality().equals(other.statuses, statuses)&&const DeepCollectionEquality().equals(other.payments, payments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalOrders,customersCount,dailyOrders,monthlyOrders,const DeepCollectionEquality().hash(statuses),const DeepCollectionEquality().hash(payments));

@override
String toString() {
  return 'HomeSummary(totalOrders: $totalOrders, customersCount: $customersCount, dailyOrders: $dailyOrders, monthlyOrders: $monthlyOrders, statuses: $statuses, payments: $payments)';
}


}

/// @nodoc
abstract mixin class $HomeSummaryCopyWith<$Res>  {
  factory $HomeSummaryCopyWith(HomeSummary value, $Res Function(HomeSummary) _then) = _$HomeSummaryCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'total_orders') int totalOrders,@JsonKey(name: 'customers_count') int customersCount,@JsonKey(name: 'daily_orders') int dailyOrders,@JsonKey(name: 'monthly_orders') int monthlyOrders, List<OrderStatusCount> statuses, List<OrderStatusCount> payments
});




}
/// @nodoc
class _$HomeSummaryCopyWithImpl<$Res>
    implements $HomeSummaryCopyWith<$Res> {
  _$HomeSummaryCopyWithImpl(this._self, this._then);

  final HomeSummary _self;
  final $Res Function(HomeSummary) _then;

/// Create a copy of HomeSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalOrders = null,Object? customersCount = null,Object? dailyOrders = null,Object? monthlyOrders = null,Object? statuses = null,Object? payments = null,}) {
  return _then(_self.copyWith(
totalOrders: null == totalOrders ? _self.totalOrders : totalOrders // ignore: cast_nullable_to_non_nullable
as int,customersCount: null == customersCount ? _self.customersCount : customersCount // ignore: cast_nullable_to_non_nullable
as int,dailyOrders: null == dailyOrders ? _self.dailyOrders : dailyOrders // ignore: cast_nullable_to_non_nullable
as int,monthlyOrders: null == monthlyOrders ? _self.monthlyOrders : monthlyOrders // ignore: cast_nullable_to_non_nullable
as int,statuses: null == statuses ? _self.statuses : statuses // ignore: cast_nullable_to_non_nullable
as List<OrderStatusCount>,payments: null == payments ? _self.payments : payments // ignore: cast_nullable_to_non_nullable
as List<OrderStatusCount>,
  ));
}

}


/// Adds pattern-matching-related methods to [HomeSummary].
extension HomeSummaryPatterns on HomeSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HomeSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HomeSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HomeSummary value)  $default,){
final _that = this;
switch (_that) {
case _HomeSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HomeSummary value)?  $default,){
final _that = this;
switch (_that) {
case _HomeSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'total_orders')  int totalOrders, @JsonKey(name: 'customers_count')  int customersCount, @JsonKey(name: 'daily_orders')  int dailyOrders, @JsonKey(name: 'monthly_orders')  int monthlyOrders,  List<OrderStatusCount> statuses,  List<OrderStatusCount> payments)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeSummary() when $default != null:
return $default(_that.totalOrders,_that.customersCount,_that.dailyOrders,_that.monthlyOrders,_that.statuses,_that.payments);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'total_orders')  int totalOrders, @JsonKey(name: 'customers_count')  int customersCount, @JsonKey(name: 'daily_orders')  int dailyOrders, @JsonKey(name: 'monthly_orders')  int monthlyOrders,  List<OrderStatusCount> statuses,  List<OrderStatusCount> payments)  $default,) {final _that = this;
switch (_that) {
case _HomeSummary():
return $default(_that.totalOrders,_that.customersCount,_that.dailyOrders,_that.monthlyOrders,_that.statuses,_that.payments);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'total_orders')  int totalOrders, @JsonKey(name: 'customers_count')  int customersCount, @JsonKey(name: 'daily_orders')  int dailyOrders, @JsonKey(name: 'monthly_orders')  int monthlyOrders,  List<OrderStatusCount> statuses,  List<OrderStatusCount> payments)?  $default,) {final _that = this;
switch (_that) {
case _HomeSummary() when $default != null:
return $default(_that.totalOrders,_that.customersCount,_that.dailyOrders,_that.monthlyOrders,_that.statuses,_that.payments);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HomeSummary extends HomeSummary {
  const _HomeSummary({@JsonKey(name: 'total_orders') required this.totalOrders, @JsonKey(name: 'customers_count') required this.customersCount, @JsonKey(name: 'daily_orders') required this.dailyOrders, @JsonKey(name: 'monthly_orders') required this.monthlyOrders, final  List<OrderStatusCount> statuses = const <OrderStatusCount>[], final  List<OrderStatusCount> payments = const <OrderStatusCount>[]}): _statuses = statuses,_payments = payments,super._();
  factory _HomeSummary.fromJson(Map<String, dynamic> json) => _$HomeSummaryFromJson(json);

@override@JsonKey(name: 'total_orders') final  int totalOrders;
@override@JsonKey(name: 'customers_count') final  int customersCount;
@override@JsonKey(name: 'daily_orders') final  int dailyOrders;
@override@JsonKey(name: 'monthly_orders') final  int monthlyOrders;
/// How the work in progress is split up.
///
/// A list, not a field per status, because the set of statuses is the business's to change:
/// adding "بانتظار الطباعة" should be a row from the server, not a release of the app.
 final  List<OrderStatusCount> _statuses;
/// How the work in progress is split up.
///
/// A list, not a field per status, because the set of statuses is the business's to change:
/// adding "بانتظار الطباعة" should be a row from the server, not a release of the app.
@override@JsonKey() List<OrderStatusCount> get statuses {
  if (_statuses is EqualUnmodifiableListView) return _statuses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_statuses);
}

/// Where the money stands, one row per payment state.
///
/// **A second axis beside [statuses], not a slice of it.** An order can be finished and
/// unpaid, or paid before it is printed, so «كم طلبية لم تُدفع» is unanswerable from the
/// counts above — which is why it arrives as its own list rather than as another status.
///
/// Defaulted, so a build of the API that predates payments still parses.
 final  List<OrderStatusCount> _payments;
/// Where the money stands, one row per payment state.
///
/// **A second axis beside [statuses], not a slice of it.** An order can be finished and
/// unpaid, or paid before it is printed, so «كم طلبية لم تُدفع» is unanswerable from the
/// counts above — which is why it arrives as its own list rather than as another status.
///
/// Defaulted, so a build of the API that predates payments still parses.
@override@JsonKey() List<OrderStatusCount> get payments {
  if (_payments is EqualUnmodifiableListView) return _payments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_payments);
}


/// Create a copy of HomeSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HomeSummaryCopyWith<_HomeSummary> get copyWith => __$HomeSummaryCopyWithImpl<_HomeSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HomeSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeSummary&&(identical(other.totalOrders, totalOrders) || other.totalOrders == totalOrders)&&(identical(other.customersCount, customersCount) || other.customersCount == customersCount)&&(identical(other.dailyOrders, dailyOrders) || other.dailyOrders == dailyOrders)&&(identical(other.monthlyOrders, monthlyOrders) || other.monthlyOrders == monthlyOrders)&&const DeepCollectionEquality().equals(other._statuses, _statuses)&&const DeepCollectionEquality().equals(other._payments, _payments));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalOrders,customersCount,dailyOrders,monthlyOrders,const DeepCollectionEquality().hash(_statuses),const DeepCollectionEquality().hash(_payments));

@override
String toString() {
  return 'HomeSummary(totalOrders: $totalOrders, customersCount: $customersCount, dailyOrders: $dailyOrders, monthlyOrders: $monthlyOrders, statuses: $statuses, payments: $payments)';
}


}

/// @nodoc
abstract mixin class _$HomeSummaryCopyWith<$Res> implements $HomeSummaryCopyWith<$Res> {
  factory _$HomeSummaryCopyWith(_HomeSummary value, $Res Function(_HomeSummary) _then) = __$HomeSummaryCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'total_orders') int totalOrders,@JsonKey(name: 'customers_count') int customersCount,@JsonKey(name: 'daily_orders') int dailyOrders,@JsonKey(name: 'monthly_orders') int monthlyOrders, List<OrderStatusCount> statuses, List<OrderStatusCount> payments
});




}
/// @nodoc
class __$HomeSummaryCopyWithImpl<$Res>
    implements _$HomeSummaryCopyWith<$Res> {
  __$HomeSummaryCopyWithImpl(this._self, this._then);

  final _HomeSummary _self;
  final $Res Function(_HomeSummary) _then;

/// Create a copy of HomeSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalOrders = null,Object? customersCount = null,Object? dailyOrders = null,Object? monthlyOrders = null,Object? statuses = null,Object? payments = null,}) {
  return _then(_HomeSummary(
totalOrders: null == totalOrders ? _self.totalOrders : totalOrders // ignore: cast_nullable_to_non_nullable
as int,customersCount: null == customersCount ? _self.customersCount : customersCount // ignore: cast_nullable_to_non_nullable
as int,dailyOrders: null == dailyOrders ? _self.dailyOrders : dailyOrders // ignore: cast_nullable_to_non_nullable
as int,monthlyOrders: null == monthlyOrders ? _self.monthlyOrders : monthlyOrders // ignore: cast_nullable_to_non_nullable
as int,statuses: null == statuses ? _self._statuses : statuses // ignore: cast_nullable_to_non_nullable
as List<OrderStatusCount>,payments: null == payments ? _self._payments : payments // ignore: cast_nullable_to_non_nullable
as List<OrderStatusCount>,
  ));
}


}


/// @nodoc
mixin _$OrderStatusCount {

/// The machine name to switch on once these become our own statuses — `pending`,
/// `rejected`. Kept apart from [label] so the UI never compares against Arabic text.
 String get status;/// The Arabic label to show, sent by the server so the app holds no translation table.
 String get label; int get count;
/// Create a copy of OrderStatusCount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderStatusCountCopyWith<OrderStatusCount> get copyWith => _$OrderStatusCountCopyWithImpl<OrderStatusCount>(this as OrderStatusCount, _$identity);

  /// Serializes this OrderStatusCount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderStatusCount&&(identical(other.status, status) || other.status == status)&&(identical(other.label, label) || other.label == label)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,label,count);

@override
String toString() {
  return 'OrderStatusCount(status: $status, label: $label, count: $count)';
}


}

/// @nodoc
abstract mixin class $OrderStatusCountCopyWith<$Res>  {
  factory $OrderStatusCountCopyWith(OrderStatusCount value, $Res Function(OrderStatusCount) _then) = _$OrderStatusCountCopyWithImpl;
@useResult
$Res call({
 String status, String label, int count
});




}
/// @nodoc
class _$OrderStatusCountCopyWithImpl<$Res>
    implements $OrderStatusCountCopyWith<$Res> {
  _$OrderStatusCountCopyWithImpl(this._self, this._then);

  final OrderStatusCount _self;
  final $Res Function(OrderStatusCount) _then;

/// Create a copy of OrderStatusCount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? label = null,Object? count = null,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderStatusCount].
extension OrderStatusCountPatterns on OrderStatusCount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderStatusCount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderStatusCount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderStatusCount value)  $default,){
final _that = this;
switch (_that) {
case _OrderStatusCount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderStatusCount value)?  $default,){
final _that = this;
switch (_that) {
case _OrderStatusCount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String status,  String label,  int count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderStatusCount() when $default != null:
return $default(_that.status,_that.label,_that.count);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String status,  String label,  int count)  $default,) {final _that = this;
switch (_that) {
case _OrderStatusCount():
return $default(_that.status,_that.label,_that.count);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String status,  String label,  int count)?  $default,) {final _that = this;
switch (_that) {
case _OrderStatusCount() when $default != null:
return $default(_that.status,_that.label,_that.count);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderStatusCount implements OrderStatusCount {
  const _OrderStatusCount({required this.status, required this.label, required this.count});
  factory _OrderStatusCount.fromJson(Map<String, dynamic> json) => _$OrderStatusCountFromJson(json);

/// The machine name to switch on once these become our own statuses — `pending`,
/// `rejected`. Kept apart from [label] so the UI never compares against Arabic text.
@override final  String status;
/// The Arabic label to show, sent by the server so the app holds no translation table.
@override final  String label;
@override final  int count;

/// Create a copy of OrderStatusCount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderStatusCountCopyWith<_OrderStatusCount> get copyWith => __$OrderStatusCountCopyWithImpl<_OrderStatusCount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderStatusCountToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderStatusCount&&(identical(other.status, status) || other.status == status)&&(identical(other.label, label) || other.label == label)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,label,count);

@override
String toString() {
  return 'OrderStatusCount(status: $status, label: $label, count: $count)';
}


}

/// @nodoc
abstract mixin class _$OrderStatusCountCopyWith<$Res> implements $OrderStatusCountCopyWith<$Res> {
  factory _$OrderStatusCountCopyWith(_OrderStatusCount value, $Res Function(_OrderStatusCount) _then) = __$OrderStatusCountCopyWithImpl;
@override @useResult
$Res call({
 String status, String label, int count
});




}
/// @nodoc
class __$OrderStatusCountCopyWithImpl<$Res>
    implements _$OrderStatusCountCopyWith<$Res> {
  __$OrderStatusCountCopyWithImpl(this._self, this._then);

  final _OrderStatusCount _self;
  final $Res Function(_OrderStatusCount) _then;

/// Create a copy of OrderStatusCount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? label = null,Object? count = null,}) {
  return _then(_OrderStatusCount(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
