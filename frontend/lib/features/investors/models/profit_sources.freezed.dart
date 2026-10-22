// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profit_sources.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProfitSources {

 String get gate; String get total; List<ProfitSourceGroup> get groups;
/// Create a copy of ProfitSources
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfitSourcesCopyWith<ProfitSources> get copyWith => _$ProfitSourcesCopyWithImpl<ProfitSources>(this as ProfitSources, _$identity);

  /// Serializes this ProfitSources to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfitSources&&(identical(other.gate, gate) || other.gate == gate)&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other.groups, groups));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,gate,total,const DeepCollectionEquality().hash(groups));

@override
String toString() {
  return 'ProfitSources(gate: $gate, total: $total, groups: $groups)';
}


}

/// @nodoc
abstract mixin class $ProfitSourcesCopyWith<$Res>  {
  factory $ProfitSourcesCopyWith(ProfitSources value, $Res Function(ProfitSources) _then) = _$ProfitSourcesCopyWithImpl;
@useResult
$Res call({
 String gate, String total, List<ProfitSourceGroup> groups
});




}
/// @nodoc
class _$ProfitSourcesCopyWithImpl<$Res>
    implements $ProfitSourcesCopyWith<$Res> {
  _$ProfitSourcesCopyWithImpl(this._self, this._then);

  final ProfitSources _self;
  final $Res Function(ProfitSources) _then;

/// Create a copy of ProfitSources
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? gate = null,Object? total = null,Object? groups = null,}) {
  return _then(_self.copyWith(
gate: null == gate ? _self.gate : gate // ignore: cast_nullable_to_non_nullable
as String,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,groups: null == groups ? _self.groups : groups // ignore: cast_nullable_to_non_nullable
as List<ProfitSourceGroup>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfitSources].
extension ProfitSourcesPatterns on ProfitSources {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfitSources value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfitSources() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfitSources value)  $default,){
final _that = this;
switch (_that) {
case _ProfitSources():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfitSources value)?  $default,){
final _that = this;
switch (_that) {
case _ProfitSources() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String gate,  String total,  List<ProfitSourceGroup> groups)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfitSources() when $default != null:
return $default(_that.gate,_that.total,_that.groups);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String gate,  String total,  List<ProfitSourceGroup> groups)  $default,) {final _that = this;
switch (_that) {
case _ProfitSources():
return $default(_that.gate,_that.total,_that.groups);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String gate,  String total,  List<ProfitSourceGroup> groups)?  $default,) {final _that = this;
switch (_that) {
case _ProfitSources() when $default != null:
return $default(_that.gate,_that.total,_that.groups);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProfitSources implements ProfitSources {
  const _ProfitSources({required this.gate, required this.total, final  List<ProfitSourceGroup> groups = const <ProfitSourceGroup>[]}): _groups = groups;
  factory _ProfitSources.fromJson(Map<String, dynamic> json) => _$ProfitSourcesFromJson(json);

@override final  String gate;
@override final  String total;
 final  List<ProfitSourceGroup> _groups;
@override@JsonKey() List<ProfitSourceGroup> get groups {
  if (_groups is EqualUnmodifiableListView) return _groups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_groups);
}


/// Create a copy of ProfitSources
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfitSourcesCopyWith<_ProfitSources> get copyWith => __$ProfitSourcesCopyWithImpl<_ProfitSources>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfitSourcesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfitSources&&(identical(other.gate, gate) || other.gate == gate)&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other._groups, _groups));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,gate,total,const DeepCollectionEquality().hash(_groups));

@override
String toString() {
  return 'ProfitSources(gate: $gate, total: $total, groups: $groups)';
}


}

/// @nodoc
abstract mixin class _$ProfitSourcesCopyWith<$Res> implements $ProfitSourcesCopyWith<$Res> {
  factory _$ProfitSourcesCopyWith(_ProfitSources value, $Res Function(_ProfitSources) _then) = __$ProfitSourcesCopyWithImpl;
@override @useResult
$Res call({
 String gate, String total, List<ProfitSourceGroup> groups
});




}
/// @nodoc
class __$ProfitSourcesCopyWithImpl<$Res>
    implements _$ProfitSourcesCopyWith<$Res> {
  __$ProfitSourcesCopyWithImpl(this._self, this._then);

  final _ProfitSources _self;
  final $Res Function(_ProfitSources) _then;

/// Create a copy of ProfitSources
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? gate = null,Object? total = null,Object? groups = null,}) {
  return _then(_ProfitSources(
gate: null == gate ? _self.gate : gate // ignore: cast_nullable_to_non_nullable
as String,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,groups: null == groups ? _self._groups : groups // ignore: cast_nullable_to_non_nullable
as List<ProfitSourceGroup>,
  ));
}


}


/// @nodoc
mixin _$ProfitSourceGroup {

 String get key;/// «P3», or the old deal's name; null when the list is one plain run.
 String? get title;@JsonKey(name: 'starts_on') String? get startsOn;@JsonKey(name: 'ends_on') String? get endsOn;/// `open` · `closing` · `closed` — the same words as the period register.
 String? get status;@JsonKey(name: 'status_label') String? get statusLabel; String get total; List<ProfitSourceLine> get lines;
/// Create a copy of ProfitSourceGroup
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfitSourceGroupCopyWith<ProfitSourceGroup> get copyWith => _$ProfitSourceGroupCopyWithImpl<ProfitSourceGroup>(this as ProfitSourceGroup, _$identity);

  /// Serializes this ProfitSourceGroup to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfitSourceGroup&&(identical(other.key, key) || other.key == key)&&(identical(other.title, title) || other.title == title)&&(identical(other.startsOn, startsOn) || other.startsOn == startsOn)&&(identical(other.endsOn, endsOn) || other.endsOn == endsOn)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other.lines, lines));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,title,startsOn,endsOn,status,statusLabel,total,const DeepCollectionEquality().hash(lines));

@override
String toString() {
  return 'ProfitSourceGroup(key: $key, title: $title, startsOn: $startsOn, endsOn: $endsOn, status: $status, statusLabel: $statusLabel, total: $total, lines: $lines)';
}


}

/// @nodoc
abstract mixin class $ProfitSourceGroupCopyWith<$Res>  {
  factory $ProfitSourceGroupCopyWith(ProfitSourceGroup value, $Res Function(ProfitSourceGroup) _then) = _$ProfitSourceGroupCopyWithImpl;
@useResult
$Res call({
 String key, String? title,@JsonKey(name: 'starts_on') String? startsOn,@JsonKey(name: 'ends_on') String? endsOn, String? status,@JsonKey(name: 'status_label') String? statusLabel, String total, List<ProfitSourceLine> lines
});




}
/// @nodoc
class _$ProfitSourceGroupCopyWithImpl<$Res>
    implements $ProfitSourceGroupCopyWith<$Res> {
  _$ProfitSourceGroupCopyWithImpl(this._self, this._then);

  final ProfitSourceGroup _self;
  final $Res Function(ProfitSourceGroup) _then;

/// Create a copy of ProfitSourceGroup
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? title = freezed,Object? startsOn = freezed,Object? endsOn = freezed,Object? status = freezed,Object? statusLabel = freezed,Object? total = null,Object? lines = null,}) {
  return _then(_self.copyWith(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,startsOn: freezed == startsOn ? _self.startsOn : startsOn // ignore: cast_nullable_to_non_nullable
as String?,endsOn: freezed == endsOn ? _self.endsOn : endsOn // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,statusLabel: freezed == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String?,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,lines: null == lines ? _self.lines : lines // ignore: cast_nullable_to_non_nullable
as List<ProfitSourceLine>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfitSourceGroup].
extension ProfitSourceGroupPatterns on ProfitSourceGroup {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfitSourceGroup value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfitSourceGroup() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfitSourceGroup value)  $default,){
final _that = this;
switch (_that) {
case _ProfitSourceGroup():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfitSourceGroup value)?  $default,){
final _that = this;
switch (_that) {
case _ProfitSourceGroup() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  String? title, @JsonKey(name: 'starts_on')  String? startsOn, @JsonKey(name: 'ends_on')  String? endsOn,  String? status, @JsonKey(name: 'status_label')  String? statusLabel,  String total,  List<ProfitSourceLine> lines)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfitSourceGroup() when $default != null:
return $default(_that.key,_that.title,_that.startsOn,_that.endsOn,_that.status,_that.statusLabel,_that.total,_that.lines);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  String? title, @JsonKey(name: 'starts_on')  String? startsOn, @JsonKey(name: 'ends_on')  String? endsOn,  String? status, @JsonKey(name: 'status_label')  String? statusLabel,  String total,  List<ProfitSourceLine> lines)  $default,) {final _that = this;
switch (_that) {
case _ProfitSourceGroup():
return $default(_that.key,_that.title,_that.startsOn,_that.endsOn,_that.status,_that.statusLabel,_that.total,_that.lines);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  String? title, @JsonKey(name: 'starts_on')  String? startsOn, @JsonKey(name: 'ends_on')  String? endsOn,  String? status, @JsonKey(name: 'status_label')  String? statusLabel,  String total,  List<ProfitSourceLine> lines)?  $default,) {final _that = this;
switch (_that) {
case _ProfitSourceGroup() when $default != null:
return $default(_that.key,_that.title,_that.startsOn,_that.endsOn,_that.status,_that.statusLabel,_that.total,_that.lines);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProfitSourceGroup implements ProfitSourceGroup {
  const _ProfitSourceGroup({required this.key, this.title, @JsonKey(name: 'starts_on') this.startsOn, @JsonKey(name: 'ends_on') this.endsOn, this.status, @JsonKey(name: 'status_label') this.statusLabel, required this.total, final  List<ProfitSourceLine> lines = const <ProfitSourceLine>[]}): _lines = lines;
  factory _ProfitSourceGroup.fromJson(Map<String, dynamic> json) => _$ProfitSourceGroupFromJson(json);

@override final  String key;
/// «P3», or the old deal's name; null when the list is one plain run.
@override final  String? title;
@override@JsonKey(name: 'starts_on') final  String? startsOn;
@override@JsonKey(name: 'ends_on') final  String? endsOn;
/// `open` · `closing` · `closed` — the same words as the period register.
@override final  String? status;
@override@JsonKey(name: 'status_label') final  String? statusLabel;
@override final  String total;
 final  List<ProfitSourceLine> _lines;
@override@JsonKey() List<ProfitSourceLine> get lines {
  if (_lines is EqualUnmodifiableListView) return _lines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lines);
}


/// Create a copy of ProfitSourceGroup
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfitSourceGroupCopyWith<_ProfitSourceGroup> get copyWith => __$ProfitSourceGroupCopyWithImpl<_ProfitSourceGroup>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfitSourceGroupToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfitSourceGroup&&(identical(other.key, key) || other.key == key)&&(identical(other.title, title) || other.title == title)&&(identical(other.startsOn, startsOn) || other.startsOn == startsOn)&&(identical(other.endsOn, endsOn) || other.endsOn == endsOn)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other._lines, _lines));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,title,startsOn,endsOn,status,statusLabel,total,const DeepCollectionEquality().hash(_lines));

@override
String toString() {
  return 'ProfitSourceGroup(key: $key, title: $title, startsOn: $startsOn, endsOn: $endsOn, status: $status, statusLabel: $statusLabel, total: $total, lines: $lines)';
}


}

/// @nodoc
abstract mixin class _$ProfitSourceGroupCopyWith<$Res> implements $ProfitSourceGroupCopyWith<$Res> {
  factory _$ProfitSourceGroupCopyWith(_ProfitSourceGroup value, $Res Function(_ProfitSourceGroup) _then) = __$ProfitSourceGroupCopyWithImpl;
@override @useResult
$Res call({
 String key, String? title,@JsonKey(name: 'starts_on') String? startsOn,@JsonKey(name: 'ends_on') String? endsOn, String? status,@JsonKey(name: 'status_label') String? statusLabel, String total, List<ProfitSourceLine> lines
});




}
/// @nodoc
class __$ProfitSourceGroupCopyWithImpl<$Res>
    implements _$ProfitSourceGroupCopyWith<$Res> {
  __$ProfitSourceGroupCopyWithImpl(this._self, this._then);

  final _ProfitSourceGroup _self;
  final $Res Function(_ProfitSourceGroup) _then;

/// Create a copy of ProfitSourceGroup
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? title = freezed,Object? startsOn = freezed,Object? endsOn = freezed,Object? status = freezed,Object? statusLabel = freezed,Object? total = null,Object? lines = null,}) {
  return _then(_ProfitSourceGroup(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,startsOn: freezed == startsOn ? _self.startsOn : startsOn // ignore: cast_nullable_to_non_nullable
as String?,endsOn: freezed == endsOn ? _self.endsOn : endsOn // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,statusLabel: freezed == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String?,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as String,lines: null == lines ? _self._lines : lines // ignore: cast_nullable_to_non_nullable
as List<ProfitSourceLine>,
  ));
}


}


/// @nodoc
mixin _$ProfitSourceLine {

/// `order` · `release` · `entry`.
 String get kind; String get key;/// Signed: a release taken out of «معلّقة» and a withdrawal are negative.
 String get amount;/// What the line is when it is not an order.
 String? get label;@JsonKey(name: 'order_id') int? get orderId; String? get code;@JsonKey(name: 'customer_name') String? get customerName;@JsonKey(name: 'order_status_label') String? get orderStatusLabel;/// `awaiting_delivery` · `awaiting_period_end` · `awaiting_payment` · `awaiting_deal_close`
/// · `released`.
 String? get state;@JsonKey(name: 'state_label') String? get stateLabel;@JsonKey(name: 'occurred_at') String? get occurredAt;/// A release's orders, and what is not an order in it.
 List<ProfitSourceLine> get children;
/// Create a copy of ProfitSourceLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfitSourceLineCopyWith<ProfitSourceLine> get copyWith => _$ProfitSourceLineCopyWithImpl<ProfitSourceLine>(this as ProfitSourceLine, _$identity);

  /// Serializes this ProfitSourceLine to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfitSourceLine&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.key, key) || other.key == key)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.label, label) || other.label == label)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.code, code) || other.code == code)&&(identical(other.customerName, customerName) || other.customerName == customerName)&&(identical(other.orderStatusLabel, orderStatusLabel) || other.orderStatusLabel == orderStatusLabel)&&(identical(other.state, state) || other.state == state)&&(identical(other.stateLabel, stateLabel) || other.stateLabel == stateLabel)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&const DeepCollectionEquality().equals(other.children, children));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,key,amount,label,orderId,code,customerName,orderStatusLabel,state,stateLabel,occurredAt,const DeepCollectionEquality().hash(children));

@override
String toString() {
  return 'ProfitSourceLine(kind: $kind, key: $key, amount: $amount, label: $label, orderId: $orderId, code: $code, customerName: $customerName, orderStatusLabel: $orderStatusLabel, state: $state, stateLabel: $stateLabel, occurredAt: $occurredAt, children: $children)';
}


}

/// @nodoc
abstract mixin class $ProfitSourceLineCopyWith<$Res>  {
  factory $ProfitSourceLineCopyWith(ProfitSourceLine value, $Res Function(ProfitSourceLine) _then) = _$ProfitSourceLineCopyWithImpl;
@useResult
$Res call({
 String kind, String key, String amount, String? label,@JsonKey(name: 'order_id') int? orderId, String? code,@JsonKey(name: 'customer_name') String? customerName,@JsonKey(name: 'order_status_label') String? orderStatusLabel, String? state,@JsonKey(name: 'state_label') String? stateLabel,@JsonKey(name: 'occurred_at') String? occurredAt, List<ProfitSourceLine> children
});




}
/// @nodoc
class _$ProfitSourceLineCopyWithImpl<$Res>
    implements $ProfitSourceLineCopyWith<$Res> {
  _$ProfitSourceLineCopyWithImpl(this._self, this._then);

  final ProfitSourceLine _self;
  final $Res Function(ProfitSourceLine) _then;

/// Create a copy of ProfitSourceLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? key = null,Object? amount = null,Object? label = freezed,Object? orderId = freezed,Object? code = freezed,Object? customerName = freezed,Object? orderStatusLabel = freezed,Object? state = freezed,Object? stateLabel = freezed,Object? occurredAt = freezed,Object? children = null,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as int?,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,customerName: freezed == customerName ? _self.customerName : customerName // ignore: cast_nullable_to_non_nullable
as String?,orderStatusLabel: freezed == orderStatusLabel ? _self.orderStatusLabel : orderStatusLabel // ignore: cast_nullable_to_non_nullable
as String?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,stateLabel: freezed == stateLabel ? _self.stateLabel : stateLabel // ignore: cast_nullable_to_non_nullable
as String?,occurredAt: freezed == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as String?,children: null == children ? _self.children : children // ignore: cast_nullable_to_non_nullable
as List<ProfitSourceLine>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProfitSourceLine].
extension ProfitSourceLinePatterns on ProfitSourceLine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProfitSourceLine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProfitSourceLine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProfitSourceLine value)  $default,){
final _that = this;
switch (_that) {
case _ProfitSourceLine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProfitSourceLine value)?  $default,){
final _that = this;
switch (_that) {
case _ProfitSourceLine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String kind,  String key,  String amount,  String? label, @JsonKey(name: 'order_id')  int? orderId,  String? code, @JsonKey(name: 'customer_name')  String? customerName, @JsonKey(name: 'order_status_label')  String? orderStatusLabel,  String? state, @JsonKey(name: 'state_label')  String? stateLabel, @JsonKey(name: 'occurred_at')  String? occurredAt,  List<ProfitSourceLine> children)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProfitSourceLine() when $default != null:
return $default(_that.kind,_that.key,_that.amount,_that.label,_that.orderId,_that.code,_that.customerName,_that.orderStatusLabel,_that.state,_that.stateLabel,_that.occurredAt,_that.children);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String kind,  String key,  String amount,  String? label, @JsonKey(name: 'order_id')  int? orderId,  String? code, @JsonKey(name: 'customer_name')  String? customerName, @JsonKey(name: 'order_status_label')  String? orderStatusLabel,  String? state, @JsonKey(name: 'state_label')  String? stateLabel, @JsonKey(name: 'occurred_at')  String? occurredAt,  List<ProfitSourceLine> children)  $default,) {final _that = this;
switch (_that) {
case _ProfitSourceLine():
return $default(_that.kind,_that.key,_that.amount,_that.label,_that.orderId,_that.code,_that.customerName,_that.orderStatusLabel,_that.state,_that.stateLabel,_that.occurredAt,_that.children);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String kind,  String key,  String amount,  String? label, @JsonKey(name: 'order_id')  int? orderId,  String? code, @JsonKey(name: 'customer_name')  String? customerName, @JsonKey(name: 'order_status_label')  String? orderStatusLabel,  String? state, @JsonKey(name: 'state_label')  String? stateLabel, @JsonKey(name: 'occurred_at')  String? occurredAt,  List<ProfitSourceLine> children)?  $default,) {final _that = this;
switch (_that) {
case _ProfitSourceLine() when $default != null:
return $default(_that.kind,_that.key,_that.amount,_that.label,_that.orderId,_that.code,_that.customerName,_that.orderStatusLabel,_that.state,_that.stateLabel,_that.occurredAt,_that.children);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProfitSourceLine implements ProfitSourceLine {
  const _ProfitSourceLine({required this.kind, required this.key, required this.amount, this.label, @JsonKey(name: 'order_id') this.orderId, this.code, @JsonKey(name: 'customer_name') this.customerName, @JsonKey(name: 'order_status_label') this.orderStatusLabel, this.state, @JsonKey(name: 'state_label') this.stateLabel, @JsonKey(name: 'occurred_at') this.occurredAt, final  List<ProfitSourceLine> children = const <ProfitSourceLine>[]}): _children = children;
  factory _ProfitSourceLine.fromJson(Map<String, dynamic> json) => _$ProfitSourceLineFromJson(json);

/// `order` · `release` · `entry`.
@override final  String kind;
@override final  String key;
/// Signed: a release taken out of «معلّقة» and a withdrawal are negative.
@override final  String amount;
/// What the line is when it is not an order.
@override final  String? label;
@override@JsonKey(name: 'order_id') final  int? orderId;
@override final  String? code;
@override@JsonKey(name: 'customer_name') final  String? customerName;
@override@JsonKey(name: 'order_status_label') final  String? orderStatusLabel;
/// `awaiting_delivery` · `awaiting_period_end` · `awaiting_payment` · `awaiting_deal_close`
/// · `released`.
@override final  String? state;
@override@JsonKey(name: 'state_label') final  String? stateLabel;
@override@JsonKey(name: 'occurred_at') final  String? occurredAt;
/// A release's orders, and what is not an order in it.
 final  List<ProfitSourceLine> _children;
/// A release's orders, and what is not an order in it.
@override@JsonKey() List<ProfitSourceLine> get children {
  if (_children is EqualUnmodifiableListView) return _children;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_children);
}


/// Create a copy of ProfitSourceLine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfitSourceLineCopyWith<_ProfitSourceLine> get copyWith => __$ProfitSourceLineCopyWithImpl<_ProfitSourceLine>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfitSourceLineToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProfitSourceLine&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.key, key) || other.key == key)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.label, label) || other.label == label)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.code, code) || other.code == code)&&(identical(other.customerName, customerName) || other.customerName == customerName)&&(identical(other.orderStatusLabel, orderStatusLabel) || other.orderStatusLabel == orderStatusLabel)&&(identical(other.state, state) || other.state == state)&&(identical(other.stateLabel, stateLabel) || other.stateLabel == stateLabel)&&(identical(other.occurredAt, occurredAt) || other.occurredAt == occurredAt)&&const DeepCollectionEquality().equals(other._children, _children));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,key,amount,label,orderId,code,customerName,orderStatusLabel,state,stateLabel,occurredAt,const DeepCollectionEquality().hash(_children));

@override
String toString() {
  return 'ProfitSourceLine(kind: $kind, key: $key, amount: $amount, label: $label, orderId: $orderId, code: $code, customerName: $customerName, orderStatusLabel: $orderStatusLabel, state: $state, stateLabel: $stateLabel, occurredAt: $occurredAt, children: $children)';
}


}

/// @nodoc
abstract mixin class _$ProfitSourceLineCopyWith<$Res> implements $ProfitSourceLineCopyWith<$Res> {
  factory _$ProfitSourceLineCopyWith(_ProfitSourceLine value, $Res Function(_ProfitSourceLine) _then) = __$ProfitSourceLineCopyWithImpl;
@override @useResult
$Res call({
 String kind, String key, String amount, String? label,@JsonKey(name: 'order_id') int? orderId, String? code,@JsonKey(name: 'customer_name') String? customerName,@JsonKey(name: 'order_status_label') String? orderStatusLabel, String? state,@JsonKey(name: 'state_label') String? stateLabel,@JsonKey(name: 'occurred_at') String? occurredAt, List<ProfitSourceLine> children
});




}
/// @nodoc
class __$ProfitSourceLineCopyWithImpl<$Res>
    implements _$ProfitSourceLineCopyWith<$Res> {
  __$ProfitSourceLineCopyWithImpl(this._self, this._then);

  final _ProfitSourceLine _self;
  final $Res Function(_ProfitSourceLine) _then;

/// Create a copy of ProfitSourceLine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? key = null,Object? amount = null,Object? label = freezed,Object? orderId = freezed,Object? code = freezed,Object? customerName = freezed,Object? orderStatusLabel = freezed,Object? state = freezed,Object? stateLabel = freezed,Object? occurredAt = freezed,Object? children = null,}) {
  return _then(_ProfitSourceLine(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as int?,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,customerName: freezed == customerName ? _self.customerName : customerName // ignore: cast_nullable_to_non_nullable
as String?,orderStatusLabel: freezed == orderStatusLabel ? _self.orderStatusLabel : orderStatusLabel // ignore: cast_nullable_to_non_nullable
as String?,state: freezed == state ? _self.state : state // ignore: cast_nullable_to_non_nullable
as String?,stateLabel: freezed == stateLabel ? _self.stateLabel : stateLabel // ignore: cast_nullable_to_non_nullable
as String?,occurredAt: freezed == occurredAt ? _self.occurredAt : occurredAt // ignore: cast_nullable_to_non_nullable
as String?,children: null == children ? _self._children : children // ignore: cast_nullable_to_non_nullable
as List<ProfitSourceLine>,
  ));
}


}

// dart format on
