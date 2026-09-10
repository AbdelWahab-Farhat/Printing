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
mixin _$MoneyEffectLine {

 String get label; String get amount; String get currency;
/// Create a copy of MoneyEffectLine
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MoneyEffectLineCopyWith<MoneyEffectLine> get copyWith => _$MoneyEffectLineCopyWithImpl<MoneyEffectLine>(this as MoneyEffectLine, _$identity);

  /// Serializes this MoneyEffectLine to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MoneyEffectLine&&(identical(other.label, label) || other.label == label)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,amount,currency);

@override
String toString() {
  return 'MoneyEffectLine(label: $label, amount: $amount, currency: $currency)';
}


}

/// @nodoc
abstract mixin class $MoneyEffectLineCopyWith<$Res>  {
  factory $MoneyEffectLineCopyWith(MoneyEffectLine value, $Res Function(MoneyEffectLine) _then) = _$MoneyEffectLineCopyWithImpl;
@useResult
$Res call({
 String label, String amount, String currency
});




}
/// @nodoc
class _$MoneyEffectLineCopyWithImpl<$Res>
    implements $MoneyEffectLineCopyWith<$Res> {
  _$MoneyEffectLineCopyWithImpl(this._self, this._then);

  final MoneyEffectLine _self;
  final $Res Function(MoneyEffectLine) _then;

/// Create a copy of MoneyEffectLine
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? label = null,Object? amount = null,Object? currency = null,}) {
  return _then(_self.copyWith(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [MoneyEffectLine].
extension MoneyEffectLinePatterns on MoneyEffectLine {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MoneyEffectLine value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MoneyEffectLine() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MoneyEffectLine value)  $default,){
final _that = this;
switch (_that) {
case _MoneyEffectLine():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MoneyEffectLine value)?  $default,){
final _that = this;
switch (_that) {
case _MoneyEffectLine() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String label,  String amount,  String currency)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MoneyEffectLine() when $default != null:
return $default(_that.label,_that.amount,_that.currency);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String label,  String amount,  String currency)  $default,) {final _that = this;
switch (_that) {
case _MoneyEffectLine():
return $default(_that.label,_that.amount,_that.currency);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String label,  String amount,  String currency)?  $default,) {final _that = this;
switch (_that) {
case _MoneyEffectLine() when $default != null:
return $default(_that.label,_that.amount,_that.currency);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MoneyEffectLine implements MoneyEffectLine {
  const _MoneyEffectLine({required this.label, required this.amount, required this.currency});
  factory _MoneyEffectLine.fromJson(Map<String, dynamic> json) => _$MoneyEffectLineFromJson(json);

@override final  String label;
@override final  String amount;
@override final  String currency;

/// Create a copy of MoneyEffectLine
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MoneyEffectLineCopyWith<_MoneyEffectLine> get copyWith => __$MoneyEffectLineCopyWithImpl<_MoneyEffectLine>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MoneyEffectLineToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MoneyEffectLine&&(identical(other.label, label) || other.label == label)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currency, currency) || other.currency == currency));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,label,amount,currency);

@override
String toString() {
  return 'MoneyEffectLine(label: $label, amount: $amount, currency: $currency)';
}


}

/// @nodoc
abstract mixin class _$MoneyEffectLineCopyWith<$Res> implements $MoneyEffectLineCopyWith<$Res> {
  factory _$MoneyEffectLineCopyWith(_MoneyEffectLine value, $Res Function(_MoneyEffectLine) _then) = __$MoneyEffectLineCopyWithImpl;
@override @useResult
$Res call({
 String label, String amount, String currency
});




}
/// @nodoc
class __$MoneyEffectLineCopyWithImpl<$Res>
    implements _$MoneyEffectLineCopyWith<$Res> {
  __$MoneyEffectLineCopyWithImpl(this._self, this._then);

  final _MoneyEffectLine _self;
  final $Res Function(_MoneyEffectLine) _then;

/// Create a copy of MoneyEffectLine
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? label = null,Object? amount = null,Object? currency = null,}) {
  return _then(_MoneyEffectLine(
label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as String,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$MoneyEffect {

@JsonKey(unknownEnumValue: MoneyEffectKind.unknown) MoneyEffectKind get kind;/// «سيُعكس ما قُبض على هذه الطلبية:» on a delete, and on a restore the sentence saying the
/// reversed payments are not coming back.
 String get warning;/// One line per kind on a [MoneyEffectKind.reverse]. **Empty on
/// [MoneyEffectKind.reversed]**, and deliberately: amounts belong to the confirmation that
/// *did* the reversing, where they could still change somebody's mind. On the way back they
/// would only be a bill for a decision already taken.
 List<MoneyEffectLine> get lines;/// The sentence that is the point of the whole section: a restore does **not** put the
/// payments back, so the money has to be re-entered by hand if it really was taken. Without
/// it a reader takes «سيُعكس» for «and it can be undone», which is the one wrong idea this
/// dialog exists to prevent.
 String? get note;
/// Create a copy of MoneyEffect
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MoneyEffectCopyWith<MoneyEffect> get copyWith => _$MoneyEffectCopyWithImpl<MoneyEffect>(this as MoneyEffect, _$identity);

  /// Serializes this MoneyEffect to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MoneyEffect&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.warning, warning) || other.warning == warning)&&const DeepCollectionEquality().equals(other.lines, lines)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,warning,const DeepCollectionEquality().hash(lines),note);

@override
String toString() {
  return 'MoneyEffect(kind: $kind, warning: $warning, lines: $lines, note: $note)';
}


}

/// @nodoc
abstract mixin class $MoneyEffectCopyWith<$Res>  {
  factory $MoneyEffectCopyWith(MoneyEffect value, $Res Function(MoneyEffect) _then) = _$MoneyEffectCopyWithImpl;
@useResult
$Res call({
@JsonKey(unknownEnumValue: MoneyEffectKind.unknown) MoneyEffectKind kind, String warning, List<MoneyEffectLine> lines, String? note
});




}
/// @nodoc
class _$MoneyEffectCopyWithImpl<$Res>
    implements $MoneyEffectCopyWith<$Res> {
  _$MoneyEffectCopyWithImpl(this._self, this._then);

  final MoneyEffect _self;
  final $Res Function(MoneyEffect) _then;

/// Create a copy of MoneyEffect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? warning = null,Object? lines = null,Object? note = freezed,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MoneyEffectKind,warning: null == warning ? _self.warning : warning // ignore: cast_nullable_to_non_nullable
as String,lines: null == lines ? _self.lines : lines // ignore: cast_nullable_to_non_nullable
as List<MoneyEffectLine>,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [MoneyEffect].
extension MoneyEffectPatterns on MoneyEffect {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MoneyEffect value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MoneyEffect() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MoneyEffect value)  $default,){
final _that = this;
switch (_that) {
case _MoneyEffect():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MoneyEffect value)?  $default,){
final _that = this;
switch (_that) {
case _MoneyEffect() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: MoneyEffectKind.unknown)  MoneyEffectKind kind,  String warning,  List<MoneyEffectLine> lines,  String? note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MoneyEffect() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(unknownEnumValue: MoneyEffectKind.unknown)  MoneyEffectKind kind,  String warning,  List<MoneyEffectLine> lines,  String? note)  $default,) {final _that = this;
switch (_that) {
case _MoneyEffect():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(unknownEnumValue: MoneyEffectKind.unknown)  MoneyEffectKind kind,  String warning,  List<MoneyEffectLine> lines,  String? note)?  $default,) {final _that = this;
switch (_that) {
case _MoneyEffect() when $default != null:
return $default(_that.kind,_that.warning,_that.lines,_that.note);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _MoneyEffect implements MoneyEffect {
  const _MoneyEffect({@JsonKey(unknownEnumValue: MoneyEffectKind.unknown) required this.kind, required this.warning, final  List<MoneyEffectLine> lines = const <MoneyEffectLine>[], this.note}): _lines = lines;
  factory _MoneyEffect.fromJson(Map<String, dynamic> json) => _$MoneyEffectFromJson(json);

@override@JsonKey(unknownEnumValue: MoneyEffectKind.unknown) final  MoneyEffectKind kind;
/// «سيُعكس ما قُبض على هذه الطلبية:» on a delete, and on a restore the sentence saying the
/// reversed payments are not coming back.
@override final  String warning;
/// One line per kind on a [MoneyEffectKind.reverse]. **Empty on
/// [MoneyEffectKind.reversed]**, and deliberately: amounts belong to the confirmation that
/// *did* the reversing, where they could still change somebody's mind. On the way back they
/// would only be a bill for a decision already taken.
 final  List<MoneyEffectLine> _lines;
/// One line per kind on a [MoneyEffectKind.reverse]. **Empty on
/// [MoneyEffectKind.reversed]**, and deliberately: amounts belong to the confirmation that
/// *did* the reversing, where they could still change somebody's mind. On the way back they
/// would only be a bill for a decision already taken.
@override@JsonKey() List<MoneyEffectLine> get lines {
  if (_lines is EqualUnmodifiableListView) return _lines;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_lines);
}

/// The sentence that is the point of the whole section: a restore does **not** put the
/// payments back, so the money has to be re-entered by hand if it really was taken. Without
/// it a reader takes «سيُعكس» for «and it can be undone», which is the one wrong idea this
/// dialog exists to prevent.
@override final  String? note;

/// Create a copy of MoneyEffect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MoneyEffectCopyWith<_MoneyEffect> get copyWith => __$MoneyEffectCopyWithImpl<_MoneyEffect>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MoneyEffectToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MoneyEffect&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.warning, warning) || other.warning == warning)&&const DeepCollectionEquality().equals(other._lines, _lines)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,warning,const DeepCollectionEquality().hash(_lines),note);

@override
String toString() {
  return 'MoneyEffect(kind: $kind, warning: $warning, lines: $lines, note: $note)';
}


}

/// @nodoc
abstract mixin class _$MoneyEffectCopyWith<$Res> implements $MoneyEffectCopyWith<$Res> {
  factory _$MoneyEffectCopyWith(_MoneyEffect value, $Res Function(_MoneyEffect) _then) = __$MoneyEffectCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(unknownEnumValue: MoneyEffectKind.unknown) MoneyEffectKind kind, String warning, List<MoneyEffectLine> lines, String? note
});




}
/// @nodoc
class __$MoneyEffectCopyWithImpl<$Res>
    implements _$MoneyEffectCopyWith<$Res> {
  __$MoneyEffectCopyWithImpl(this._self, this._then);

  final _MoneyEffect _self;
  final $Res Function(_MoneyEffect) _then;

/// Create a copy of MoneyEffect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? warning = null,Object? lines = null,Object? note = freezed,}) {
  return _then(_MoneyEffect(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as MoneyEffectKind,warning: null == warning ? _self.warning : warning // ignore: cast_nullable_to_non_nullable
as String,lines: null == lines ? _self._lines : lines // ignore: cast_nullable_to_non_nullable
as List<MoneyEffectLine>,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$WarehouseEffect {

@JsonKey(unknownEnumValue: StockEffectKind.unknown) StockEffectKind get kind;/// The headline — «سيُعاد إلى المخزن ما خصمته هذه الطلبية:» or «سيُخصم من المخزن من جديد:»,
/// and on a [StockEffectKind.none] a plain sentence saying no stock moves.
 String get warning;/// Empty on [StockEffectKind.none], and that is a list with nothing in it rather than a
/// missing key: the dialog draws the headline either way.
 List<StockEffectLine> get lines;/// The second paragraph, which only the restore has: «وقد تختلف تكلفة الطلبية عمّا كانت…».
 String? get note;
/// Create a copy of WarehouseEffect
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WarehouseEffectCopyWith<WarehouseEffect> get copyWith => _$WarehouseEffectCopyWithImpl<WarehouseEffect>(this as WarehouseEffect, _$identity);

  /// Serializes this WarehouseEffect to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WarehouseEffect&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.warning, warning) || other.warning == warning)&&const DeepCollectionEquality().equals(other.lines, lines)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,warning,const DeepCollectionEquality().hash(lines),note);

@override
String toString() {
  return 'WarehouseEffect(kind: $kind, warning: $warning, lines: $lines, note: $note)';
}


}

/// @nodoc
abstract mixin class $WarehouseEffectCopyWith<$Res>  {
  factory $WarehouseEffectCopyWith(WarehouseEffect value, $Res Function(WarehouseEffect) _then) = _$WarehouseEffectCopyWithImpl;
@useResult
$Res call({
@JsonKey(unknownEnumValue: StockEffectKind.unknown) StockEffectKind kind, String warning, List<StockEffectLine> lines, String? note
});




}
/// @nodoc
class _$WarehouseEffectCopyWithImpl<$Res>
    implements $WarehouseEffectCopyWith<$Res> {
  _$WarehouseEffectCopyWithImpl(this._self, this._then);

  final WarehouseEffect _self;
  final $Res Function(WarehouseEffect) _then;

/// Create a copy of WarehouseEffect
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


/// Adds pattern-matching-related methods to [WarehouseEffect].
extension WarehouseEffectPatterns on WarehouseEffect {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WarehouseEffect value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WarehouseEffect() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WarehouseEffect value)  $default,){
final _that = this;
switch (_that) {
case _WarehouseEffect():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WarehouseEffect value)?  $default,){
final _that = this;
switch (_that) {
case _WarehouseEffect() when $default != null:
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
case _WarehouseEffect() when $default != null:
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
case _WarehouseEffect():
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
case _WarehouseEffect() when $default != null:
return $default(_that.kind,_that.warning,_that.lines,_that.note);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WarehouseEffect extends WarehouseEffect {
  const _WarehouseEffect({@JsonKey(unknownEnumValue: StockEffectKind.unknown) required this.kind, required this.warning, final  List<StockEffectLine> lines = const <StockEffectLine>[], this.note}): _lines = lines,super._();
  factory _WarehouseEffect.fromJson(Map<String, dynamic> json) => _$WarehouseEffectFromJson(json);

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

/// Create a copy of WarehouseEffect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WarehouseEffectCopyWith<_WarehouseEffect> get copyWith => __$WarehouseEffectCopyWithImpl<_WarehouseEffect>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WarehouseEffectToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WarehouseEffect&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.warning, warning) || other.warning == warning)&&const DeepCollectionEquality().equals(other._lines, _lines)&&(identical(other.note, note) || other.note == note));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,warning,const DeepCollectionEquality().hash(_lines),note);

@override
String toString() {
  return 'WarehouseEffect(kind: $kind, warning: $warning, lines: $lines, note: $note)';
}


}

/// @nodoc
abstract mixin class _$WarehouseEffectCopyWith<$Res> implements $WarehouseEffectCopyWith<$Res> {
  factory _$WarehouseEffectCopyWith(_WarehouseEffect value, $Res Function(_WarehouseEffect) _then) = __$WarehouseEffectCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(unknownEnumValue: StockEffectKind.unknown) StockEffectKind kind, String warning, List<StockEffectLine> lines, String? note
});




}
/// @nodoc
class __$WarehouseEffectCopyWithImpl<$Res>
    implements _$WarehouseEffectCopyWith<$Res> {
  __$WarehouseEffectCopyWithImpl(this._self, this._then);

  final _WarehouseEffect _self;
  final $Res Function(_WarehouseEffect) _then;

/// Create a copy of WarehouseEffect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? warning = null,Object? lines = null,Object? note = freezed,}) {
  return _then(_WarehouseEffect(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as StockEffectKind,warning: null == warning ? _self.warning : warning // ignore: cast_nullable_to_non_nullable
as String,lines: null == lines ? _self._lines : lines // ignore: cast_nullable_to_non_nullable
as List<StockEffectLine>,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$StockEffect {

/// The warehouse half. Always present — «لا يتحرّك شيء» is an answer, not an absence.
 WarehouseEffect get stock;/// The ledger half, or null when this order has no money to say anything about.
 MoneyEffect? get money;
/// Create a copy of StockEffect
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StockEffectCopyWith<StockEffect> get copyWith => _$StockEffectCopyWithImpl<StockEffect>(this as StockEffect, _$identity);

  /// Serializes this StockEffect to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StockEffect&&(identical(other.stock, stock) || other.stock == stock)&&(identical(other.money, money) || other.money == money));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,stock,money);

@override
String toString() {
  return 'StockEffect(stock: $stock, money: $money)';
}


}

/// @nodoc
abstract mixin class $StockEffectCopyWith<$Res>  {
  factory $StockEffectCopyWith(StockEffect value, $Res Function(StockEffect) _then) = _$StockEffectCopyWithImpl;
@useResult
$Res call({
 WarehouseEffect stock, MoneyEffect? money
});


$WarehouseEffectCopyWith<$Res> get stock;$MoneyEffectCopyWith<$Res>? get money;

}
/// @nodoc
class _$StockEffectCopyWithImpl<$Res>
    implements $StockEffectCopyWith<$Res> {
  _$StockEffectCopyWithImpl(this._self, this._then);

  final StockEffect _self;
  final $Res Function(StockEffect) _then;

/// Create a copy of StockEffect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? stock = null,Object? money = freezed,}) {
  return _then(_self.copyWith(
stock: null == stock ? _self.stock : stock // ignore: cast_nullable_to_non_nullable
as WarehouseEffect,money: freezed == money ? _self.money : money // ignore: cast_nullable_to_non_nullable
as MoneyEffect?,
  ));
}
/// Create a copy of StockEffect
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WarehouseEffectCopyWith<$Res> get stock {
  
  return $WarehouseEffectCopyWith<$Res>(_self.stock, (value) {
    return _then(_self.copyWith(stock: value));
  });
}/// Create a copy of StockEffect
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyEffectCopyWith<$Res>? get money {
    if (_self.money == null) {
    return null;
  }

  return $MoneyEffectCopyWith<$Res>(_self.money!, (value) {
    return _then(_self.copyWith(money: value));
  });
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( WarehouseEffect stock,  MoneyEffect? money)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StockEffect() when $default != null:
return $default(_that.stock,_that.money);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( WarehouseEffect stock,  MoneyEffect? money)  $default,) {final _that = this;
switch (_that) {
case _StockEffect():
return $default(_that.stock,_that.money);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( WarehouseEffect stock,  MoneyEffect? money)?  $default,) {final _that = this;
switch (_that) {
case _StockEffect() when $default != null:
return $default(_that.stock,_that.money);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StockEffect extends StockEffect {
  const _StockEffect({required this.stock, this.money}): super._();
  factory _StockEffect.fromJson(Map<String, dynamic> json) => _$StockEffectFromJson(json);

/// The warehouse half. Always present — «لا يتحرّك شيء» is an answer, not an absence.
@override final  WarehouseEffect stock;
/// The ledger half, or null when this order has no money to say anything about.
@override final  MoneyEffect? money;

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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StockEffect&&(identical(other.stock, stock) || other.stock == stock)&&(identical(other.money, money) || other.money == money));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,stock,money);

@override
String toString() {
  return 'StockEffect(stock: $stock, money: $money)';
}


}

/// @nodoc
abstract mixin class _$StockEffectCopyWith<$Res> implements $StockEffectCopyWith<$Res> {
  factory _$StockEffectCopyWith(_StockEffect value, $Res Function(_StockEffect) _then) = __$StockEffectCopyWithImpl;
@override @useResult
$Res call({
 WarehouseEffect stock, MoneyEffect? money
});


@override $WarehouseEffectCopyWith<$Res> get stock;@override $MoneyEffectCopyWith<$Res>? get money;

}
/// @nodoc
class __$StockEffectCopyWithImpl<$Res>
    implements _$StockEffectCopyWith<$Res> {
  __$StockEffectCopyWithImpl(this._self, this._then);

  final _StockEffect _self;
  final $Res Function(_StockEffect) _then;

/// Create a copy of StockEffect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? stock = null,Object? money = freezed,}) {
  return _then(_StockEffect(
stock: null == stock ? _self.stock : stock // ignore: cast_nullable_to_non_nullable
as WarehouseEffect,money: freezed == money ? _self.money : money // ignore: cast_nullable_to_non_nullable
as MoneyEffect?,
  ));
}

/// Create a copy of StockEffect
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WarehouseEffectCopyWith<$Res> get stock {
  
  return $WarehouseEffectCopyWith<$Res>(_self.stock, (value) {
    return _then(_self.copyWith(stock: value));
  });
}/// Create a copy of StockEffect
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$MoneyEffectCopyWith<$Res>? get money {
    if (_self.money == null) {
    return null;
  }

  return $MoneyEffectCopyWith<$Res>(_self.money!, (value) {
    return _then(_self.copyWith(money: value));
  });
}
}

// dart format on
