// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
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
 List<OrderStatusCount> get payments;/// «بانتظار رسالة الجاهزية» — how many orders are made and waiting for somebody to tell
/// their customer so.
///
/// **Null is «هذا ليس عملك», not zero.** The server omits the key entirely for a reader
/// without `orders.ready_message`, so the box is not drawn at all rather than drawn empty in
/// a job that belongs to one person. Null again on a build of the API that predates it.
///
/// One number and its Arabic, not a list: it is a single queue, and the label travels with
/// it because the screen it opens is titled with the box's own word.
@JsonKey(name: 'ready_message') ReadyMessageQueue? get readyMessage;/// «طلبيات راجعة بانتظار التواصل» — orders in a return whose customer nobody has asked yet.
/// Same grant and same «null is not your job» as [readyMessage].
@JsonKey(name: 'return_message') ReadyMessageQueue? get returnMessage;/// The branch counter's board — «طلب فوري» and its counters (INSTANT-ORDERS-PLAN.md §11).
/// Null for a reader without `instant_orders.view`, and on an API that predates it.
 InstantBoard? get instant;
/// Create a copy of HomeSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HomeSummaryCopyWith<HomeSummary> get copyWith => _$HomeSummaryCopyWithImpl<HomeSummary>(this as HomeSummary, _$identity);

  /// Serializes this HomeSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as HomeSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HomeSummary&&(identical(other.totalOrders, _this.totalOrders) || other.totalOrders == _this.totalOrders)&&(identical(other.customersCount, _this.customersCount) || other.customersCount == _this.customersCount)&&(identical(other.dailyOrders, _this.dailyOrders) || other.dailyOrders == _this.dailyOrders)&&(identical(other.monthlyOrders, _this.monthlyOrders) || other.monthlyOrders == _this.monthlyOrders)&&const DeepCollectionEquality().equals(other.statuses, _this.statuses)&&const DeepCollectionEquality().equals(other.payments, _this.payments)&&(identical(other.readyMessage, _this.readyMessage) || other.readyMessage == _this.readyMessage)&&(identical(other.returnMessage, _this.returnMessage) || other.returnMessage == _this.returnMessage)&&(identical(other.instant, _this.instant) || other.instant == _this.instant));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as HomeSummary;
  return Object.hash(runtimeType,_this.totalOrders,_this.customersCount,_this.dailyOrders,_this.monthlyOrders,const DeepCollectionEquality().hash(_this.statuses),const DeepCollectionEquality().hash(_this.payments),_this.readyMessage,_this.returnMessage,_this.instant);
}

@override
String toString() {
  final _this = this as HomeSummary;
  return 'HomeSummary(totalOrders: ${_this.totalOrders}, customersCount: ${_this.customersCount}, dailyOrders: ${_this.dailyOrders}, monthlyOrders: ${_this.monthlyOrders}, statuses: ${_this.statuses}, payments: ${_this.payments}, readyMessage: ${_this.readyMessage}, returnMessage: ${_this.returnMessage}, instant: ${_this.instant})';
}


}

/// @nodoc
abstract mixin class $HomeSummaryCopyWith<$Res>  {
  factory $HomeSummaryCopyWith(HomeSummary value, $Res Function(HomeSummary) _then) = _$HomeSummaryCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'total_orders') int totalOrders,@JsonKey(name: 'customers_count') int customersCount,@JsonKey(name: 'daily_orders') int dailyOrders,@JsonKey(name: 'monthly_orders') int monthlyOrders, List<OrderStatusCount> statuses, List<OrderStatusCount> payments,@JsonKey(name: 'ready_message') ReadyMessageQueue? readyMessage,@JsonKey(name: 'return_message') ReadyMessageQueue? returnMessage, InstantBoard? instant
});


$ReadyMessageQueueCopyWith<$Res>? get readyMessage;$ReadyMessageQueueCopyWith<$Res>? get returnMessage;$InstantBoardCopyWith<$Res>? get instant;

}
/// @nodoc
class _$HomeSummaryCopyWithImpl<$Res>
    implements $HomeSummaryCopyWith<$Res> {
  _$HomeSummaryCopyWithImpl(this._self, this._then);

  final HomeSummary _self;
  final $Res Function(HomeSummary) _then;

/// Create a copy of HomeSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalOrders = null,Object? customersCount = null,Object? dailyOrders = null,Object? monthlyOrders = null,Object? statuses = null,Object? payments = null,Object? readyMessage = freezed,Object? returnMessage = freezed,Object? instant = freezed,}) {
  return _then(HomeSummary(
totalOrders: null == totalOrders ? _self.totalOrders : totalOrders // ignore: cast_nullable_to_non_nullable
as int,customersCount: null == customersCount ? _self.customersCount : customersCount // ignore: cast_nullable_to_non_nullable
as int,dailyOrders: null == dailyOrders ? _self.dailyOrders : dailyOrders // ignore: cast_nullable_to_non_nullable
as int,monthlyOrders: null == monthlyOrders ? _self.monthlyOrders : monthlyOrders // ignore: cast_nullable_to_non_nullable
as int,statuses: null == statuses ? _self.statuses : statuses // ignore: cast_nullable_to_non_nullable
as List<OrderStatusCount>,payments: null == payments ? _self.payments : payments // ignore: cast_nullable_to_non_nullable
as List<OrderStatusCount>,readyMessage: freezed == readyMessage ? _self.readyMessage : readyMessage // ignore: cast_nullable_to_non_nullable
as ReadyMessageQueue?,returnMessage: freezed == returnMessage ? _self.returnMessage : returnMessage // ignore: cast_nullable_to_non_nullable
as ReadyMessageQueue?,instant: freezed == instant ? _self.instant : instant // ignore: cast_nullable_to_non_nullable
as InstantBoard?,
  ));
}
/// Create a copy of HomeSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReadyMessageQueueCopyWith<$Res>? get readyMessage {
    if (_self.readyMessage == null) {
    return null;
  }

  return $ReadyMessageQueueCopyWith<$Res>(_self.readyMessage!, (value) {
    return _then(_self.copyWith(readyMessage: value));
  });
}/// Create a copy of HomeSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReadyMessageQueueCopyWith<$Res>? get returnMessage {
    if (_self.returnMessage == null) {
    return null;
  }

  return $ReadyMessageQueueCopyWith<$Res>(_self.returnMessage!, (value) {
    return _then(_self.copyWith(returnMessage: value));
  });
}/// Create a copy of HomeSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InstantBoardCopyWith<$Res>? get instant {
    if (_self.instant == null) {
    return null;
  }

  return $InstantBoardCopyWith<$Res>(_self.instant!, (value) {
    return _then(_self.copyWith(instant: value));
  });
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'total_orders')  int totalOrders, @JsonKey(name: 'customers_count')  int customersCount, @JsonKey(name: 'daily_orders')  int dailyOrders, @JsonKey(name: 'monthly_orders')  int monthlyOrders,  List<OrderStatusCount> statuses,  List<OrderStatusCount> payments, @JsonKey(name: 'ready_message')  ReadyMessageQueue? readyMessage, @JsonKey(name: 'return_message')  ReadyMessageQueue? returnMessage,  InstantBoard? instant)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HomeSummary() when $default != null:
return $default(_that.totalOrders,_that.customersCount,_that.dailyOrders,_that.monthlyOrders,_that.statuses,_that.payments,_that.readyMessage,_that.returnMessage,_that.instant);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'total_orders')  int totalOrders, @JsonKey(name: 'customers_count')  int customersCount, @JsonKey(name: 'daily_orders')  int dailyOrders, @JsonKey(name: 'monthly_orders')  int monthlyOrders,  List<OrderStatusCount> statuses,  List<OrderStatusCount> payments, @JsonKey(name: 'ready_message')  ReadyMessageQueue? readyMessage, @JsonKey(name: 'return_message')  ReadyMessageQueue? returnMessage,  InstantBoard? instant)  $default,) {final _that = this;
switch (_that) {
case _HomeSummary():
return $default(_that.totalOrders,_that.customersCount,_that.dailyOrders,_that.monthlyOrders,_that.statuses,_that.payments,_that.readyMessage,_that.returnMessage,_that.instant);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'total_orders')  int totalOrders, @JsonKey(name: 'customers_count')  int customersCount, @JsonKey(name: 'daily_orders')  int dailyOrders, @JsonKey(name: 'monthly_orders')  int monthlyOrders,  List<OrderStatusCount> statuses,  List<OrderStatusCount> payments, @JsonKey(name: 'ready_message')  ReadyMessageQueue? readyMessage, @JsonKey(name: 'return_message')  ReadyMessageQueue? returnMessage,  InstantBoard? instant)?  $default,) {final _that = this;
switch (_that) {
case _HomeSummary() when $default != null:
return $default(_that.totalOrders,_that.customersCount,_that.dailyOrders,_that.monthlyOrders,_that.statuses,_that.payments,_that.readyMessage,_that.returnMessage,_that.instant);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _HomeSummary extends HomeSummary {
  const _HomeSummary({@JsonKey(name: 'total_orders') required this.totalOrders, @JsonKey(name: 'customers_count') required this.customersCount, @JsonKey(name: 'daily_orders') required this.dailyOrders, @JsonKey(name: 'monthly_orders') required this.monthlyOrders,  List<OrderStatusCount> statuses = const <OrderStatusCount>[],  List<OrderStatusCount> payments = const <OrderStatusCount>[], @JsonKey(name: 'ready_message') this.readyMessage, @JsonKey(name: 'return_message') this.returnMessage, this.instant}): _statuses = statuses,_payments = payments,super._();
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

/// «بانتظار رسالة الجاهزية» — how many orders are made and waiting for somebody to tell
/// their customer so.
///
/// **Null is «هذا ليس عملك», not zero.** The server omits the key entirely for a reader
/// without `orders.ready_message`, so the box is not drawn at all rather than drawn empty in
/// a job that belongs to one person. Null again on a build of the API that predates it.
///
/// One number and its Arabic, not a list: it is a single queue, and the label travels with
/// it because the screen it opens is titled with the box's own word.
@override@JsonKey(name: 'ready_message') final  ReadyMessageQueue? readyMessage;
/// «طلبيات راجعة بانتظار التواصل» — orders in a return whose customer nobody has asked yet.
/// Same grant and same «null is not your job» as [readyMessage].
@override@JsonKey(name: 'return_message') final  ReadyMessageQueue? returnMessage;
/// The branch counter's board — «طلب فوري» and its counters (INSTANT-ORDERS-PLAN.md §11).
/// Null for a reader without `instant_orders.view`, and on an API that predates it.
@override final  InstantBoard? instant;

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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HomeSummary&&(identical(other.totalOrders, totalOrders) || other.totalOrders == totalOrders)&&(identical(other.customersCount, customersCount) || other.customersCount == customersCount)&&(identical(other.dailyOrders, dailyOrders) || other.dailyOrders == dailyOrders)&&(identical(other.monthlyOrders, monthlyOrders) || other.monthlyOrders == monthlyOrders)&&const DeepCollectionEquality().equals(other.statuses, _statuses)&&const DeepCollectionEquality().equals(other.payments, _payments)&&(identical(other.readyMessage, readyMessage) || other.readyMessage == readyMessage)&&(identical(other.returnMessage, returnMessage) || other.returnMessage == returnMessage)&&(identical(other.instant, instant) || other.instant == instant));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,totalOrders,customersCount,dailyOrders,monthlyOrders,const DeepCollectionEquality().hash(_statuses),const DeepCollectionEquality().hash(_payments),readyMessage,returnMessage,instant);
}

@override
String toString() {
    return 'HomeSummary(totalOrders: $totalOrders, customersCount: $customersCount, dailyOrders: $dailyOrders, monthlyOrders: $monthlyOrders, statuses: $statuses, payments: $payments, readyMessage: $readyMessage, returnMessage: $returnMessage, instant: $instant)';
}


}

/// @nodoc
abstract mixin class _$HomeSummaryCopyWith<$Res> implements $HomeSummaryCopyWith<$Res> {
  factory _$HomeSummaryCopyWith(_HomeSummary value, $Res Function(_HomeSummary) _then) = __$HomeSummaryCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'total_orders') int totalOrders,@JsonKey(name: 'customers_count') int customersCount,@JsonKey(name: 'daily_orders') int dailyOrders,@JsonKey(name: 'monthly_orders') int monthlyOrders, List<OrderStatusCount> statuses, List<OrderStatusCount> payments,@JsonKey(name: 'ready_message') ReadyMessageQueue? readyMessage,@JsonKey(name: 'return_message') ReadyMessageQueue? returnMessage, InstantBoard? instant
});


@override $ReadyMessageQueueCopyWith<$Res>? get readyMessage;@override $ReadyMessageQueueCopyWith<$Res>? get returnMessage;@override $InstantBoardCopyWith<$Res>? get instant;

}
/// @nodoc
class __$HomeSummaryCopyWithImpl<$Res>
    implements _$HomeSummaryCopyWith<$Res> {
  __$HomeSummaryCopyWithImpl(this._self, this._then);

  final _HomeSummary _self;
  final $Res Function(_HomeSummary) _then;

/// Create a copy of HomeSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalOrders = null,Object? customersCount = null,Object? dailyOrders = null,Object? monthlyOrders = null,Object? statuses = null,Object? payments = null,Object? readyMessage = freezed,Object? returnMessage = freezed,Object? instant = freezed,}) {
  return _then(_HomeSummary(
totalOrders: null == totalOrders ? _self.totalOrders : totalOrders // ignore: cast_nullable_to_non_nullable
as int,customersCount: null == customersCount ? _self.customersCount : customersCount // ignore: cast_nullable_to_non_nullable
as int,dailyOrders: null == dailyOrders ? _self.dailyOrders : dailyOrders // ignore: cast_nullable_to_non_nullable
as int,monthlyOrders: null == monthlyOrders ? _self.monthlyOrders : monthlyOrders // ignore: cast_nullable_to_non_nullable
as int,statuses: null == statuses ? _self._statuses : statuses // ignore: cast_nullable_to_non_nullable
as List<OrderStatusCount>,payments: null == payments ? _self._payments : payments // ignore: cast_nullable_to_non_nullable
as List<OrderStatusCount>,readyMessage: freezed == readyMessage ? _self.readyMessage : readyMessage // ignore: cast_nullable_to_non_nullable
as ReadyMessageQueue?,returnMessage: freezed == returnMessage ? _self.returnMessage : returnMessage // ignore: cast_nullable_to_non_nullable
as ReadyMessageQueue?,instant: freezed == instant ? _self.instant : instant // ignore: cast_nullable_to_non_nullable
as InstantBoard?,
  ));
}

/// Create a copy of HomeSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReadyMessageQueueCopyWith<$Res>? get readyMessage {
    if (_self.readyMessage == null) {
    return null;
  }

  return $ReadyMessageQueueCopyWith<$Res>(_self.readyMessage!, (value) {
    return _then(_self.copyWith(readyMessage: value));
  });
}/// Create a copy of HomeSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReadyMessageQueueCopyWith<$Res>? get returnMessage {
    if (_self.returnMessage == null) {
    return null;
  }

  return $ReadyMessageQueueCopyWith<$Res>(_self.returnMessage!, (value) {
    return _then(_self.copyWith(returnMessage: value));
  });
}/// Create a copy of HomeSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InstantBoardCopyWith<$Res>? get instant {
    if (_self.instant == null) {
    return null;
  }

  return $InstantBoardCopyWith<$Res>(_self.instant!, (value) {
    return _then(_self.copyWith(instant: value));
  });
}
}


/// @nodoc
mixin _$ReadyMessageQueue {

 int get count; String get label;
/// Create a copy of ReadyMessageQueue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadyMessageQueueCopyWith<ReadyMessageQueue> get copyWith => _$ReadyMessageQueueCopyWithImpl<ReadyMessageQueue>(this as ReadyMessageQueue, _$identity);

  /// Serializes this ReadyMessageQueue to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as ReadyMessageQueue;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadyMessageQueue&&(identical(other.count, _this.count) || other.count == _this.count)&&(identical(other.label, _this.label) || other.label == _this.label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as ReadyMessageQueue;
  return Object.hash(runtimeType,_this.count,_this.label);
}

@override
String toString() {
  final _this = this as ReadyMessageQueue;
  return 'ReadyMessageQueue(count: ${_this.count}, label: ${_this.label})';
}


}

/// @nodoc
abstract mixin class $ReadyMessageQueueCopyWith<$Res>  {
  factory $ReadyMessageQueueCopyWith(ReadyMessageQueue value, $Res Function(ReadyMessageQueue) _then) = _$ReadyMessageQueueCopyWithImpl;
@useResult
$Res call({
 int count, String label
});




}
/// @nodoc
class _$ReadyMessageQueueCopyWithImpl<$Res>
    implements $ReadyMessageQueueCopyWith<$Res> {
  _$ReadyMessageQueueCopyWithImpl(this._self, this._then);

  final ReadyMessageQueue _self;
  final $Res Function(ReadyMessageQueue) _then;

/// Create a copy of ReadyMessageQueue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? count = null,Object? label = null,}) {
  return _then(ReadyMessageQueue(
count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ReadyMessageQueue].
extension ReadyMessageQueuePatterns on ReadyMessageQueue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReadyMessageQueue value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReadyMessageQueue() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReadyMessageQueue value)  $default,){
final _that = this;
switch (_that) {
case _ReadyMessageQueue():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReadyMessageQueue value)?  $default,){
final _that = this;
switch (_that) {
case _ReadyMessageQueue() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int count,  String label)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReadyMessageQueue() when $default != null:
return $default(_that.count,_that.label);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int count,  String label)  $default,) {final _that = this;
switch (_that) {
case _ReadyMessageQueue():
return $default(_that.count,_that.label);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int count,  String label)?  $default,) {final _that = this;
switch (_that) {
case _ReadyMessageQueue() when $default != null:
return $default(_that.count,_that.label);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReadyMessageQueue implements ReadyMessageQueue {
  const _ReadyMessageQueue({required this.count, required this.label});
  factory _ReadyMessageQueue.fromJson(Map<String, dynamic> json) => _$ReadyMessageQueueFromJson(json);

@override final  int count;
@override final  String label;

/// Create a copy of ReadyMessageQueue
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReadyMessageQueueCopyWith<_ReadyMessageQueue> get copyWith => __$ReadyMessageQueueCopyWithImpl<_ReadyMessageQueue>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReadyMessageQueueToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReadyMessageQueue&&(identical(other.count, count) || other.count == count)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,count,label);
}

@override
String toString() {
    return 'ReadyMessageQueue(count: $count, label: $label)';
}


}

/// @nodoc
abstract mixin class _$ReadyMessageQueueCopyWith<$Res> implements $ReadyMessageQueueCopyWith<$Res> {
  factory _$ReadyMessageQueueCopyWith(_ReadyMessageQueue value, $Res Function(_ReadyMessageQueue) _then) = __$ReadyMessageQueueCopyWithImpl;
@override @useResult
$Res call({
 int count, String label
});




}
/// @nodoc
class __$ReadyMessageQueueCopyWithImpl<$Res>
    implements _$ReadyMessageQueueCopyWith<$Res> {
  __$ReadyMessageQueueCopyWithImpl(this._self, this._then);

  final _ReadyMessageQueue _self;
  final $Res Function(_ReadyMessageQueue) _then;

/// Create a copy of ReadyMessageQueue
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? count = null,Object? label = null,}) {
  return _then(_ReadyMessageQueue(
count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$InstantBoard {

@JsonKey(name: 'can_create') bool get canCreate;/// The active branches this employee may sell from. Empty draws «طلب فوري» disabled.
 List<BranchRef> get branches;/// جديدة، تم الاستلام، إلغاء تام، تم التسوية — the instant orders by status.
 List<OrderStatusCount> get statuses;/// Instant orders still «جديدة» past [lateAfterHours].
@JsonKey(name: 'late_count') int get lateCount;@JsonKey(name: 'late_after_hours') int get lateAfterHours;/// «استلام مكتب» orders waiting at the employee's own branches.
@JsonKey(name: 'pickup_count') int get pickupCount;
/// Create a copy of InstantBoard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InstantBoardCopyWith<InstantBoard> get copyWith => _$InstantBoardCopyWithImpl<InstantBoard>(this as InstantBoard, _$identity);

  /// Serializes this InstantBoard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as InstantBoard;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InstantBoard&&(identical(other.canCreate, _this.canCreate) || other.canCreate == _this.canCreate)&&const DeepCollectionEquality().equals(other.branches, _this.branches)&&const DeepCollectionEquality().equals(other.statuses, _this.statuses)&&(identical(other.lateCount, _this.lateCount) || other.lateCount == _this.lateCount)&&(identical(other.lateAfterHours, _this.lateAfterHours) || other.lateAfterHours == _this.lateAfterHours)&&(identical(other.pickupCount, _this.pickupCount) || other.pickupCount == _this.pickupCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as InstantBoard;
  return Object.hash(runtimeType,_this.canCreate,const DeepCollectionEquality().hash(_this.branches),const DeepCollectionEquality().hash(_this.statuses),_this.lateCount,_this.lateAfterHours,_this.pickupCount);
}

@override
String toString() {
  final _this = this as InstantBoard;
  return 'InstantBoard(canCreate: ${_this.canCreate}, branches: ${_this.branches}, statuses: ${_this.statuses}, lateCount: ${_this.lateCount}, lateAfterHours: ${_this.lateAfterHours}, pickupCount: ${_this.pickupCount})';
}


}

/// @nodoc
abstract mixin class $InstantBoardCopyWith<$Res>  {
  factory $InstantBoardCopyWith(InstantBoard value, $Res Function(InstantBoard) _then) = _$InstantBoardCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'can_create') bool canCreate, List<BranchRef> branches, List<OrderStatusCount> statuses,@JsonKey(name: 'late_count') int lateCount,@JsonKey(name: 'late_after_hours') int lateAfterHours,@JsonKey(name: 'pickup_count') int pickupCount
});




}
/// @nodoc
class _$InstantBoardCopyWithImpl<$Res>
    implements $InstantBoardCopyWith<$Res> {
  _$InstantBoardCopyWithImpl(this._self, this._then);

  final InstantBoard _self;
  final $Res Function(InstantBoard) _then;

/// Create a copy of InstantBoard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? canCreate = null,Object? branches = null,Object? statuses = null,Object? lateCount = null,Object? lateAfterHours = null,Object? pickupCount = null,}) {
  return _then(InstantBoard(
canCreate: null == canCreate ? _self.canCreate : canCreate // ignore: cast_nullable_to_non_nullable
as bool,branches: null == branches ? _self.branches : branches // ignore: cast_nullable_to_non_nullable
as List<BranchRef>,statuses: null == statuses ? _self.statuses : statuses // ignore: cast_nullable_to_non_nullable
as List<OrderStatusCount>,lateCount: null == lateCount ? _self.lateCount : lateCount // ignore: cast_nullable_to_non_nullable
as int,lateAfterHours: null == lateAfterHours ? _self.lateAfterHours : lateAfterHours // ignore: cast_nullable_to_non_nullable
as int,pickupCount: null == pickupCount ? _self.pickupCount : pickupCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [InstantBoard].
extension InstantBoardPatterns on InstantBoard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InstantBoard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InstantBoard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InstantBoard value)  $default,){
final _that = this;
switch (_that) {
case _InstantBoard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InstantBoard value)?  $default,){
final _that = this;
switch (_that) {
case _InstantBoard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'can_create')  bool canCreate,  List<BranchRef> branches,  List<OrderStatusCount> statuses, @JsonKey(name: 'late_count')  int lateCount, @JsonKey(name: 'late_after_hours')  int lateAfterHours, @JsonKey(name: 'pickup_count')  int pickupCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InstantBoard() when $default != null:
return $default(_that.canCreate,_that.branches,_that.statuses,_that.lateCount,_that.lateAfterHours,_that.pickupCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'can_create')  bool canCreate,  List<BranchRef> branches,  List<OrderStatusCount> statuses, @JsonKey(name: 'late_count')  int lateCount, @JsonKey(name: 'late_after_hours')  int lateAfterHours, @JsonKey(name: 'pickup_count')  int pickupCount)  $default,) {final _that = this;
switch (_that) {
case _InstantBoard():
return $default(_that.canCreate,_that.branches,_that.statuses,_that.lateCount,_that.lateAfterHours,_that.pickupCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'can_create')  bool canCreate,  List<BranchRef> branches,  List<OrderStatusCount> statuses, @JsonKey(name: 'late_count')  int lateCount, @JsonKey(name: 'late_after_hours')  int lateAfterHours, @JsonKey(name: 'pickup_count')  int pickupCount)?  $default,) {final _that = this;
switch (_that) {
case _InstantBoard() when $default != null:
return $default(_that.canCreate,_that.branches,_that.statuses,_that.lateCount,_that.lateAfterHours,_that.pickupCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InstantBoard extends InstantBoard {
  const _InstantBoard({@JsonKey(name: 'can_create') this.canCreate = false,  List<BranchRef> branches = const <BranchRef>[],  List<OrderStatusCount> statuses = const <OrderStatusCount>[], @JsonKey(name: 'late_count') this.lateCount = 0, @JsonKey(name: 'late_after_hours') this.lateAfterHours = 24, @JsonKey(name: 'pickup_count') this.pickupCount = 0}): _branches = branches,_statuses = statuses,super._();
  factory _InstantBoard.fromJson(Map<String, dynamic> json) => _$InstantBoardFromJson(json);

@override@JsonKey(name: 'can_create') final  bool canCreate;
/// The active branches this employee may sell from. Empty draws «طلب فوري» disabled.
 final  List<BranchRef> _branches;
/// The active branches this employee may sell from. Empty draws «طلب فوري» disabled.
@override@JsonKey() List<BranchRef> get branches {
  if (_branches is EqualUnmodifiableListView) return _branches;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_branches);
}

/// جديدة، تم الاستلام، إلغاء تام، تم التسوية — the instant orders by status.
 final  List<OrderStatusCount> _statuses;
/// جديدة، تم الاستلام، إلغاء تام، تم التسوية — the instant orders by status.
@override@JsonKey() List<OrderStatusCount> get statuses {
  if (_statuses is EqualUnmodifiableListView) return _statuses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_statuses);
}

/// Instant orders still «جديدة» past [lateAfterHours].
@override@JsonKey(name: 'late_count') final  int lateCount;
@override@JsonKey(name: 'late_after_hours') final  int lateAfterHours;
/// «استلام مكتب» orders waiting at the employee's own branches.
@override@JsonKey(name: 'pickup_count') final  int pickupCount;

/// Create a copy of InstantBoard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InstantBoardCopyWith<_InstantBoard> get copyWith => __$InstantBoardCopyWithImpl<_InstantBoard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InstantBoardToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _InstantBoard&&(identical(other.canCreate, canCreate) || other.canCreate == canCreate)&&const DeepCollectionEquality().equals(other.branches, _branches)&&const DeepCollectionEquality().equals(other.statuses, _statuses)&&(identical(other.lateCount, lateCount) || other.lateCount == lateCount)&&(identical(other.lateAfterHours, lateAfterHours) || other.lateAfterHours == lateAfterHours)&&(identical(other.pickupCount, pickupCount) || other.pickupCount == pickupCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,canCreate,const DeepCollectionEquality().hash(_branches),const DeepCollectionEquality().hash(_statuses),lateCount,lateAfterHours,pickupCount);
}

@override
String toString() {
    return 'InstantBoard(canCreate: $canCreate, branches: $branches, statuses: $statuses, lateCount: $lateCount, lateAfterHours: $lateAfterHours, pickupCount: $pickupCount)';
}


}

/// @nodoc
abstract mixin class _$InstantBoardCopyWith<$Res> implements $InstantBoardCopyWith<$Res> {
  factory _$InstantBoardCopyWith(_InstantBoard value, $Res Function(_InstantBoard) _then) = __$InstantBoardCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'can_create') bool canCreate, List<BranchRef> branches, List<OrderStatusCount> statuses,@JsonKey(name: 'late_count') int lateCount,@JsonKey(name: 'late_after_hours') int lateAfterHours,@JsonKey(name: 'pickup_count') int pickupCount
});




}
/// @nodoc
class __$InstantBoardCopyWithImpl<$Res>
    implements _$InstantBoardCopyWith<$Res> {
  __$InstantBoardCopyWithImpl(this._self, this._then);

  final _InstantBoard _self;
  final $Res Function(_InstantBoard) _then;

/// Create a copy of InstantBoard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? canCreate = null,Object? branches = null,Object? statuses = null,Object? lateCount = null,Object? lateAfterHours = null,Object? pickupCount = null,}) {
  return _then(_InstantBoard(
canCreate: null == canCreate ? _self.canCreate : canCreate // ignore: cast_nullable_to_non_nullable
as bool,branches: null == branches ? _self._branches : branches // ignore: cast_nullable_to_non_nullable
as List<BranchRef>,statuses: null == statuses ? _self._statuses : statuses // ignore: cast_nullable_to_non_nullable
as List<OrderStatusCount>,lateCount: null == lateCount ? _self.lateCount : lateCount // ignore: cast_nullable_to_non_nullable
as int,lateAfterHours: null == lateAfterHours ? _self.lateAfterHours : lateAfterHours // ignore: cast_nullable_to_non_nullable
as int,pickupCount: null == pickupCount ? _self.pickupCount : pickupCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$BranchRef {

 int get id; String get name;
/// Create a copy of BranchRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BranchRefCopyWith<BranchRef> get copyWith => _$BranchRefCopyWithImpl<BranchRef>(this as BranchRef, _$identity);

  /// Serializes this BranchRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BranchRef;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BranchRef&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.name, _this.name) || other.name == _this.name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BranchRef;
  return Object.hash(runtimeType,_this.id,_this.name);
}

@override
String toString() {
  final _this = this as BranchRef;
  return 'BranchRef(id: ${_this.id}, name: ${_this.name})';
}


}

/// @nodoc
abstract mixin class $BranchRefCopyWith<$Res>  {
  factory $BranchRefCopyWith(BranchRef value, $Res Function(BranchRef) _then) = _$BranchRefCopyWithImpl;
@useResult
$Res call({
 int id, String name
});




}
/// @nodoc
class _$BranchRefCopyWithImpl<$Res>
    implements $BranchRefCopyWith<$Res> {
  _$BranchRefCopyWithImpl(this._self, this._then);

  final BranchRef _self;
  final $Res Function(BranchRef) _then;

/// Create a copy of BranchRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(BranchRef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [BranchRef].
extension BranchRefPatterns on BranchRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BranchRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BranchRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BranchRef value)  $default,){
final _that = this;
switch (_that) {
case _BranchRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BranchRef value)?  $default,){
final _that = this;
switch (_that) {
case _BranchRef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BranchRef() when $default != null:
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name)  $default,) {final _that = this;
switch (_that) {
case _BranchRef():
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name)?  $default,) {final _that = this;
switch (_that) {
case _BranchRef() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BranchRef implements BranchRef {
  const _BranchRef({required this.id, required this.name});
  factory _BranchRef.fromJson(Map<String, dynamic> json) => _$BranchRefFromJson(json);

@override final  int id;
@override final  String name;

/// Create a copy of BranchRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BranchRefCopyWith<_BranchRef> get copyWith => __$BranchRefCopyWithImpl<_BranchRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BranchRefToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BranchRef&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,name);
}

@override
String toString() {
    return 'BranchRef(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$BranchRefCopyWith<$Res> implements $BranchRefCopyWith<$Res> {
  factory _$BranchRefCopyWith(_BranchRef value, $Res Function(_BranchRef) _then) = __$BranchRefCopyWithImpl;
@override @useResult
$Res call({
 int id, String name
});




}
/// @nodoc
class __$BranchRefCopyWithImpl<$Res>
    implements _$BranchRefCopyWith<$Res> {
  __$BranchRefCopyWithImpl(this._self, this._then);

  final _BranchRef _self;
  final $Res Function(_BranchRef) _then;

/// Create a copy of BranchRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_BranchRef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
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
  final _this = this as OrderStatusCount;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderStatusCount&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.count, _this.count) || other.count == _this.count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as OrderStatusCount;
  return Object.hash(runtimeType,_this.status,_this.label,_this.count);
}

@override
String toString() {
  final _this = this as OrderStatusCount;
  return 'OrderStatusCount(status: ${_this.status}, label: ${_this.label}, count: ${_this.count})';
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
  return _then(OrderStatusCount(
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
int get hashCode {
    return Object.hash(runtimeType,status,label,count);
}

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
