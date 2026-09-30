// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_note.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OrderNote {

 int get id;/// المرحلة التي كُتبت عندها، بكلمة الخادم في [stageLabel]. ومرحلةٌ لا يعرفها هذا الإصدار
/// تُقرأ [OrderStage.unknown] وتُرسم بكلمتها.
@JsonKey(unknownEnumValue: OrderStage.unknown) OrderStage get stage;@JsonKey(name: 'stage_label') String get stageLabel; String get text;@JsonKey(name: 'written_at') DateTime? get writtenAt;
/// Create a copy of OrderNote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderNoteCopyWith<OrderNote> get copyWith => _$OrderNoteCopyWithImpl<OrderNote>(this as OrderNote, _$identity);

  /// Serializes this OrderNote to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderNote&&(identical(other.id, id) || other.id == id)&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.stageLabel, stageLabel) || other.stageLabel == stageLabel)&&(identical(other.text, text) || other.text == text)&&(identical(other.writtenAt, writtenAt) || other.writtenAt == writtenAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,stage,stageLabel,text,writtenAt);

@override
String toString() {
  return 'OrderNote(id: $id, stage: $stage, stageLabel: $stageLabel, text: $text, writtenAt: $writtenAt)';
}


}

/// @nodoc
abstract mixin class $OrderNoteCopyWith<$Res>  {
  factory $OrderNoteCopyWith(OrderNote value, $Res Function(OrderNote) _then) = _$OrderNoteCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(unknownEnumValue: OrderStage.unknown) OrderStage stage,@JsonKey(name: 'stage_label') String stageLabel, String text,@JsonKey(name: 'written_at') DateTime? writtenAt
});




}
/// @nodoc
class _$OrderNoteCopyWithImpl<$Res>
    implements $OrderNoteCopyWith<$Res> {
  _$OrderNoteCopyWithImpl(this._self, this._then);

  final OrderNote _self;
  final $Res Function(OrderNote) _then;

/// Create a copy of OrderNote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? stage = null,Object? stageLabel = null,Object? text = null,Object? writtenAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as OrderStage,stageLabel: null == stageLabel ? _self.stageLabel : stageLabel // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,writtenAt: freezed == writtenAt ? _self.writtenAt : writtenAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderNote].
extension OrderNotePatterns on OrderNote {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderNote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderNote() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderNote value)  $default,){
final _that = this;
switch (_that) {
case _OrderNote():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderNote value)?  $default,){
final _that = this;
switch (_that) {
case _OrderNote() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(unknownEnumValue: OrderStage.unknown)  OrderStage stage, @JsonKey(name: 'stage_label')  String stageLabel,  String text, @JsonKey(name: 'written_at')  DateTime? writtenAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderNote() when $default != null:
return $default(_that.id,_that.stage,_that.stageLabel,_that.text,_that.writtenAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(unknownEnumValue: OrderStage.unknown)  OrderStage stage, @JsonKey(name: 'stage_label')  String stageLabel,  String text, @JsonKey(name: 'written_at')  DateTime? writtenAt)  $default,) {final _that = this;
switch (_that) {
case _OrderNote():
return $default(_that.id,_that.stage,_that.stageLabel,_that.text,_that.writtenAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(unknownEnumValue: OrderStage.unknown)  OrderStage stage, @JsonKey(name: 'stage_label')  String stageLabel,  String text, @JsonKey(name: 'written_at')  DateTime? writtenAt)?  $default,) {final _that = this;
switch (_that) {
case _OrderNote() when $default != null:
return $default(_that.id,_that.stage,_that.stageLabel,_that.text,_that.writtenAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OrderNote implements OrderNote {
  const _OrderNote({required this.id, @JsonKey(unknownEnumValue: OrderStage.unknown) this.stage = OrderStage.unknown, @JsonKey(name: 'stage_label') required this.stageLabel, required this.text, @JsonKey(name: 'written_at') this.writtenAt});
  factory _OrderNote.fromJson(Map<String, dynamic> json) => _$OrderNoteFromJson(json);

@override final  int id;
/// المرحلة التي كُتبت عندها، بكلمة الخادم في [stageLabel]. ومرحلةٌ لا يعرفها هذا الإصدار
/// تُقرأ [OrderStage.unknown] وتُرسم بكلمتها.
@override@JsonKey(unknownEnumValue: OrderStage.unknown) final  OrderStage stage;
@override@JsonKey(name: 'stage_label') final  String stageLabel;
@override final  String text;
@override@JsonKey(name: 'written_at') final  DateTime? writtenAt;

/// Create a copy of OrderNote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderNoteCopyWith<_OrderNote> get copyWith => __$OrderNoteCopyWithImpl<_OrderNote>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OrderNoteToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderNote&&(identical(other.id, id) || other.id == id)&&(identical(other.stage, stage) || other.stage == stage)&&(identical(other.stageLabel, stageLabel) || other.stageLabel == stageLabel)&&(identical(other.text, text) || other.text == text)&&(identical(other.writtenAt, writtenAt) || other.writtenAt == writtenAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,stage,stageLabel,text,writtenAt);

@override
String toString() {
  return 'OrderNote(id: $id, stage: $stage, stageLabel: $stageLabel, text: $text, writtenAt: $writtenAt)';
}


}

/// @nodoc
abstract mixin class _$OrderNoteCopyWith<$Res> implements $OrderNoteCopyWith<$Res> {
  factory _$OrderNoteCopyWith(_OrderNote value, $Res Function(_OrderNote) _then) = __$OrderNoteCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(unknownEnumValue: OrderStage.unknown) OrderStage stage,@JsonKey(name: 'stage_label') String stageLabel, String text,@JsonKey(name: 'written_at') DateTime? writtenAt
});




}
/// @nodoc
class __$OrderNoteCopyWithImpl<$Res>
    implements _$OrderNoteCopyWith<$Res> {
  __$OrderNoteCopyWithImpl(this._self, this._then);

  final _OrderNote _self;
  final $Res Function(_OrderNote) _then;

/// Create a copy of OrderNote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? stage = null,Object? stageLabel = null,Object? text = null,Object? writtenAt = freezed,}) {
  return _then(_OrderNote(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,stage: null == stage ? _self.stage : stage // ignore: cast_nullable_to_non_nullable
as OrderStage,stageLabel: null == stageLabel ? _self.stageLabel : stageLabel // ignore: cast_nullable_to_non_nullable
as String,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,writtenAt: freezed == writtenAt ? _self.writtenAt : writtenAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
