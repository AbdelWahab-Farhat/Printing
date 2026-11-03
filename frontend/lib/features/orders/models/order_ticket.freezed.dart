// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_ticket.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OrderTicket {

@JsonKey(unknownEnumValue: OrderTicketKind.unknown) OrderTicketKind get kind;@JsonKey(name: 'kind_label') String get kindLabel; int get id;/// «T24» و«D6». فارغٌ لتذكرة العميل: صفُّها بلا كود — انظر [label].
 String? get code; String get title; String get status;@JsonKey(name: 'status_label') String get statusLabel;@JsonKey(name: 'is_open') bool get isOpen;@JsonKey(name: 'activity_at') DateTime? get activityAt;
/// Create a copy of OrderTicket
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderTicketCopyWith<OrderTicket> get copyWith => _$OrderTicketCopyWithImpl<OrderTicket>(this as OrderTicket, _$identity);

  /// Serializes this OrderTicket to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderTicket&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.kindLabel, kindLabel) || other.kindLabel == kindLabel)&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.title, title) || other.title == title)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.isOpen, isOpen) || other.isOpen == isOpen)&&(identical(other.activityAt, activityAt) || other.activityAt == activityAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,kindLabel,id,code,title,status,statusLabel,isOpen,activityAt);

@override
String toString() {
  return 'OrderTicket(kind: $kind, kindLabel: $kindLabel, id: $id, code: $code, title: $title, status: $status, statusLabel: $statusLabel, isOpen: $isOpen, activityAt: $activityAt)';
}


}

/// @nodoc
abstract mixin class $OrderTicketCopyWith<$Res>  {
  factory $OrderTicketCopyWith(OrderTicket value, $Res Function(OrderTicket) _then) = _$OrderTicketCopyWithImpl;
@useResult
$Res call({
@JsonKey(unknownEnumValue: OrderTicketKind.unknown) OrderTicketKind kind,@JsonKey(name: 'kind_label') String kindLabel, int id, String? code, String title, String status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'is_open') bool isOpen,@JsonKey(name: 'activity_at') DateTime? activityAt
});




}
/// @nodoc
class _$OrderTicketCopyWithImpl<$Res>
    implements $OrderTicketCopyWith<$Res> {
  _$OrderTicketCopyWithImpl(this._self, this._then);

  final OrderTicket _self;
  final $Res Function(OrderTicket) _then;

/// Create a copy of OrderTicket
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? kindLabel = null,Object? id = null,Object? code = freezed,Object? title = null,Object? status = null,Object? statusLabel = null,Object? isOpen = null,Object? activityAt = freezed,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as OrderTicketKind,kindLabel: null == kindLabel ? _self.kindLabel : kindLabel // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,isOpen: null == isOpen ? _self.isOpen : isOpen // ignore: cast_nullable_to_non_nullable
as bool,activityAt: freezed == activityAt ? _self.activityAt : activityAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderTicket].
extension OrderTicketPatterns on OrderTicket {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderTicket value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderTicket() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderTicket value)  $default,){
final _that = this;
switch (_that) {
case _OrderTicket():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderTicket value)?  $default,){
final _that = this;
switch (_that) {
case _OrderTicket() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: OrderTicketKind.unknown)  OrderTicketKind kind, @JsonKey(name: 'kind_label')  String kindLabel,  int id,  String? code,  String title,  String status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'is_open')  bool isOpen, @JsonKey(name: 'activity_at')  DateTime? activityAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderTicket() when $default != null:
return $default(_that.kind,_that.kindLabel,_that.id,_that.code,_that.title,_that.status,_that.statusLabel,_that.isOpen,_that.activityAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: OrderTicketKind.unknown)  OrderTicketKind kind, @JsonKey(name: 'kind_label')  String kindLabel,  int id,  String? code,  String title,  String status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'is_open')  bool isOpen, @JsonKey(name: 'activity_at')  DateTime? activityAt)  $default,) {final _that = this;
switch (_that) {
case _OrderTicket():
return $default(_that.kind,_that.kindLabel,_that.id,_that.code,_that.title,_that.status,_that.statusLabel,_that.isOpen,_that.activityAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(unknownEnumValue: OrderTicketKind.unknown)  OrderTicketKind kind, @JsonKey(name: 'kind_label')  String kindLabel,  int id,  String? code,  String title,  String status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'is_open')  bool isOpen, @JsonKey(name: 'activity_at')  DateTime? activityAt)?  $default,) {final _that = this;
switch (_that) {
case _OrderTicket() when $default != null:
return $default(_that.kind,_that.kindLabel,_that.id,_that.code,_that.title,_that.status,_that.statusLabel,_that.isOpen,_that.activityAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderTicket extends OrderTicket {
  const _OrderTicket({@JsonKey(unknownEnumValue: OrderTicketKind.unknown) required this.kind, @JsonKey(name: 'kind_label') required this.kindLabel, required this.id, this.code, required this.title, required this.status, @JsonKey(name: 'status_label') required this.statusLabel, @JsonKey(name: 'is_open') this.isOpen = false, @JsonKey(name: 'activity_at') this.activityAt}): super._();
  factory _OrderTicket.fromJson(Map<String, dynamic> json) => _$OrderTicketFromJson(json);

@override@JsonKey(unknownEnumValue: OrderTicketKind.unknown) final  OrderTicketKind kind;
@override@JsonKey(name: 'kind_label') final  String kindLabel;
@override final  int id;
/// «T24» و«D6». فارغٌ لتذكرة العميل: صفُّها بلا كود — انظر [label].
@override final  String? code;
@override final  String title;
@override final  String status;
@override@JsonKey(name: 'status_label') final  String statusLabel;
@override@JsonKey(name: 'is_open') final  bool isOpen;
@override@JsonKey(name: 'activity_at') final  DateTime? activityAt;

/// Create a copy of OrderTicket
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderTicketCopyWith<_OrderTicket> get copyWith => __$OrderTicketCopyWithImpl<_OrderTicket>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderTicketToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderTicket&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.kindLabel, kindLabel) || other.kindLabel == kindLabel)&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.title, title) || other.title == title)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.isOpen, isOpen) || other.isOpen == isOpen)&&(identical(other.activityAt, activityAt) || other.activityAt == activityAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,kindLabel,id,code,title,status,statusLabel,isOpen,activityAt);

@override
String toString() {
  return 'OrderTicket(kind: $kind, kindLabel: $kindLabel, id: $id, code: $code, title: $title, status: $status, statusLabel: $statusLabel, isOpen: $isOpen, activityAt: $activityAt)';
}


}

/// @nodoc
abstract mixin class _$OrderTicketCopyWith<$Res> implements $OrderTicketCopyWith<$Res> {
  factory _$OrderTicketCopyWith(_OrderTicket value, $Res Function(_OrderTicket) _then) = __$OrderTicketCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(unknownEnumValue: OrderTicketKind.unknown) OrderTicketKind kind,@JsonKey(name: 'kind_label') String kindLabel, int id, String? code, String title, String status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'is_open') bool isOpen,@JsonKey(name: 'activity_at') DateTime? activityAt
});




}
/// @nodoc
class __$OrderTicketCopyWithImpl<$Res>
    implements _$OrderTicketCopyWith<$Res> {
  __$OrderTicketCopyWithImpl(this._self, this._then);

  final _OrderTicket _self;
  final $Res Function(_OrderTicket) _then;

/// Create a copy of OrderTicket
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? kindLabel = null,Object? id = null,Object? code = freezed,Object? title = null,Object? status = null,Object? statusLabel = null,Object? isOpen = null,Object? activityAt = freezed,}) {
  return _then(_OrderTicket(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as OrderTicketKind,kindLabel: null == kindLabel ? _self.kindLabel : kindLabel // ignore: cast_nullable_to_non_nullable
as String,id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,isOpen: null == isOpen ? _self.isOpen : isOpen // ignore: cast_nullable_to_non_nullable
as bool,activityAt: freezed == activityAt ? _self.activityAt : activityAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
