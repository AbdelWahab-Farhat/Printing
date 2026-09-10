// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stock_effect.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StockEffectLine {

 String get label; String get quantity; String get unit;
/// Create a copy of StockEffectLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StockEffectLineCopyWith<StockEffectLine> get copyWith => _$StockEffectLineCopyWithImpl<StockEffectLine>(this as StockEffectLine, _$identity);

  /// Serializes this StockEffectLine to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StockEffectLine&&(identical(other.label, label) || other.label == label)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unit, unit) || other.unit == unit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,quantity,unit);

@override
String toString() {
  return 'StockEffectLine(label: $label, quantity: $quantity, unit: $unit)';
}


}

/// @nodoc
abstract mixin class $StockEffectLineCopyWith<$Res>  {
  factory $StockEffectLineCopyWith(StockEffectLine value, $Res Function(StockEffectLine) _then) = _$StockEffectLineCopyWithImpl;
@useResult
$Res call({
 String label, String quantity, String unit
});




}
/// @nodoc
class _$StockEffectLineCopyWithImpl<$Res>
    implements $StockEffectLineCopyWith<$Res> {
  _$StockEffectLineCopyWithImpl(this._self, this._then);

  final StockEffectLine _self;
  final $Res Function(StockEffectLine) _then;

/// Create a copy of StockEffectLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? quantity = null,Object? unit = null,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [StockEffectLine].
extension StockEffectLinePatterns on StockEffectLine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StockEffectLine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StockEffectLine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StockEffectLine value)  $default,){
final _that = this;
switch (_that) {
case _StockEffectLine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StockEffectLine value)?  $default,){
final _that = this;
switch (_that) {
case _StockEffectLine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  String quantity,  String unit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StockEffectLine() when $default != null:
return $default(_that.label,_that.quantity,_that.unit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  String quantity,  String unit)  $default,) {final _that = this;
switch (_that) {
case _StockEffectLine():
return $default(_that.label,_that.quantity,_that.unit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  String quantity,  String unit)?  $default,) {final _that = this;
switch (_that) {
case _StockEffectLine() when $default != null:
return $default(_that.label,_that.quantity,_that.unit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StockEffectLine implements StockEffectLine {
  const _StockEffectLine({required this.label, required this.quantity, required this.unit});
  factory _StockEffectLine.fromJson(Map<String, dynamic> json) => _$StockEffectLineFromJson(json);

@override final  String label;
@override final  String quantity;
@override final  String unit;

/// Create a copy of StockEffectLine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StockEffectLineCopyWith<_StockEffectLine> get copyWith => __$StockEffectLineCopyWithImpl<_StockEffectLine>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StockEffectLineToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StockEffectLine&&(identical(other.label, label) || other.label == label)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unit, unit) || other.unit == unit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,quantity,unit);

@override
String toString() {
  return 'StockEffectLine(label: $label, quantity: $quantity, unit: $unit)';
}


}

/// @nodoc
abstract mixin class _$StockEffectLineCopyWith<$Res> implements $StockEffectLineCopyWith<$Res> {
  factory _$StockEffectLineCopyWith(_StockEffectLine value, $Res Function(_StockEffectLine) _then) = __$StockEffectLineCopyWithImpl;
@override @useResult
$Res call({
 String label, String quantity, String unit
});




}
/// @nodoc
class __$StockEffectLineCopyWithImpl<$Res>
    implements _$StockEffectLineCopyWith<$Res> {
  __$StockEffectLineCopyWithImpl(this._self, this._then);

  final _StockEffectLine _self;
  final $Res Function(_StockEffectLine) _then;

/// Create a copy of StockEffectLine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? quantity = null,Object? unit = null,}) {
  return _then(_StockEffectLine(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as String,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$StockEffect {

@JsonKey(unknownEnumValue: StockEffectKind.unknown) StockEffectKind get kind;/// The headline — «سيُعاد إلى المخزن ما خصمته هذه الطلبية:» or «سيُخصم من المخزن من جديد:»,
/// and on a [StockEffectKind.none] a plain sentence saying no stock moves.
 String get warning;/// Empty on [StockEffectKind.none], and that is a list with nothing in it rather than a
/// missing key: the dialog draws the headline either way.
 List<StockEffectLine> get lines;/// The second paragraph, which only the restore has: «وقد تختلف تكلفة الطلبية عمّا كانت…».
 String? get note;
/// Create a copy of StockEffect
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StockEffectCopyWith<StockEffect> get copyWith => _$StockEffectCopyWithImpl<StockEffect>(this as StockEffect, _$identity);

  /// Serializes this StockEffect to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StockEffect&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.warning, warning) || other.warning == warning)&&const DeepCollectionEquality().equals(other.lines, lines)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,warning,const DeepCollectionEquality().hash(lines),note);

@override
String toString() {
  return 'StockEffect(kind: $kind, warning: $warning, lines: $lines, note: $note)';
}


}

/// @nodoc
abstract mixin class $StockEffectCopyWith<$Res>  {
  factory $StockEffectCopyWith(StockEffect value, $Res Function(StockEffect) _then) = _$StockEffectCopyWithImpl;
@useResult
$Res call({
@JsonKey(unknownEnumValue: StockEffectKind.unknown) StockEffectKind kind, String warning, List<StockEffectLine> lines, String? note
});




}
/// @nodoc
class _$StockEffectCopyWithImpl<$Res>
    implements $StockEffectCopyWith<$Res> {
  _$StockEffectCopyWithImpl(this._self, this._then);

  final StockEffect _self;
  final $Res Function(StockEffect) _then;

/// Create a copy of StockEffect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? warning = null,Object? lines = null,Object? note = freezed,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as StockEffectKind,warning: null == warning ? _self.warning : warning // ignore: cast_nullable_to_non_nullable
as String,lines: null == lines ? _self.lines : lines // ignore: cast_nullable_to_non_nullable
as List<StockEffectLine>,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [StockEffect].
extension StockEffectPatterns on StockEffect {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StockEffect value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StockEffect() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StockEffect value)  $default,){
final _that = this;
switch (_that) {
case _StockEffect():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StockEffect value)?  $default,){
final _that = this;
switch (_that) {
case _StockEffect() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: StockEffectKind.unknown)  StockEffectKind kind,  String warning,  List<StockEffectLine> lines,  String? note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StockEffect() when $default != null:
return $default(_that.kind,_that.warning,_that.lines,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: StockEffectKind.unknown)  StockEffectKind kind,  String warning,  List<StockEffectLine> lines,  String? note)  $default,) {final _that = this;
switch (_that) {
case _StockEffect():
return $default(_that.kind,_that.warning,_that.lines,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(unknownEnumValue: StockEffectKind.unknown)  StockEffectKind kind,  String warning,  List<StockEffectLine> lines,  String? note)?  $default,) {final _that = this;
switch (_that) {
case _StockEffect() when $default != null:
return $default(_that.kind,_that.warning,_that.lines,_that.note);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StockEffect extends StockEffect {
  const _StockEffect({@JsonKey(unknownEnumValue: StockEffectKind.unknown) required this.kind, required this.warning, final  List<StockEffectLine> lines = const <StockEffectLine>[], this.note}): _lines = lines,super._();
  factory _StockEffect.fromJson(Map<String, dynamic> json) => _$StockEffectFromJson(json);

@override@JsonKey(unknownEnumValue: StockEffectKind.unknown) final  StockEffectKind kind;
/// The headline — «سيُعاد إلى المخزن ما خصمته هذه الطلبية:» or «سيُخصم من المخزن من جديد:»,
/// and on a [StockEffectKind.none] a plain sentence saying no stock moves.
@override final  String warning;
/// Empty on [StockEffectKind.none], and that is a list with nothing in it rather than a
/// missing key: the dialog draws the headline either way.
 final  List<StockEffectLine> _lines;
/// Empty on [StockEffectKind.none], and that is a list with nothing in it rather than a
/// missing key: the dialog draws the headline either way.
@override@JsonKey() List<StockEffectLine> get lines {
  if (_lines is EqualUnmodifiableListView) return _lines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lines);
}

/// The second paragraph, which only the restore has: «وقد تختلف تكلفة الطلبية عمّا كانت…».
@override final  String? note;

/// Create a copy of StockEffect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StockEffectCopyWith<_StockEffect> get copyWith => __$StockEffectCopyWithImpl<_StockEffect>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StockEffectToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StockEffect&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.warning, warning) || other.warning == warning)&&const DeepCollectionEquality().equals(other._lines, _lines)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,warning,const DeepCollectionEquality().hash(_lines),note);

@override
String toString() {
  return 'StockEffect(kind: $kind, warning: $warning, lines: $lines, note: $note)';
}


}

/// @nodoc
abstract mixin class _$StockEffectCopyWith<$Res> implements $StockEffectCopyWith<$Res> {
  factory _$StockEffectCopyWith(_StockEffect value, $Res Function(_StockEffect) _then) = __$StockEffectCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(unknownEnumValue: StockEffectKind.unknown) StockEffectKind kind, String warning, List<StockEffectLine> lines, String? note
});




}
/// @nodoc
class __$StockEffectCopyWithImpl<$Res>
    implements _$StockEffectCopyWith<$Res> {
  __$StockEffectCopyWithImpl(this._self, this._then);

  final _StockEffect _self;
  final $Res Function(_StockEffect) _then;

/// Create a copy of StockEffect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? warning = null,Object? lines = null,Object? note = freezed,}) {
  return _then(_StockEffect(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as StockEffectKind,warning: null == warning ? _self.warning : warning // ignore: cast_nullable_to_non_nullable
as String,lines: null == lines ? _self._lines : lines // ignore: cast_nullable_to_non_nullable
as List<StockEffectLine>,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
