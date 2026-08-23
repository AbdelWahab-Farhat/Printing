// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transition_field.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TransitionField {

/// What the value is sent back as, inside `fields`.
 String get key;@JsonKey(unknownEnumValue: TransitionFieldType.unknown) TransitionFieldType get type;/// The Arabic the server chose. Rendered as-is, like every other label in this app.
 String get label;@JsonKey(name: 'required') bool get isRequired;/// The field takes several values. Only meaningful for kinds that can hold more than one.
 bool get multiple;/// A text field of several lines rather than one.
 bool get multiline;/// A sentence under the field, when the server has something to say about it.
 String? get hint;/// Bounds for [TransitionFieldType.number]. [max] is typically what was ordered of one
/// line — «الناقص من 30*30» can never exceed it — so it travels with the field.
 num? get min; num? get max;/// The choices, for the one kind that carries its own — see
/// [TransitionFieldType.paymentMethod]. Empty for every other kind.
 List<TransitionFieldOption> get options;/// The key of the field that makes this one mandatory: empty is fine on its own, and
/// refused the moment that other field is answered.
///
/// «طريقة الدفع» is meaningless without an amount and obligatory with one, and neither
/// [isRequired] nor its absence can say that. Sent down so [canSubmit] can hold the same
/// rule the endpoint enforces rather than this app keeping a second copy of it.
@JsonKey(name: 'required_with') String? get requiredWith;/// What the box opens holding — **an answer, not a placeholder.**
///
/// Leaving «نواقص» asks how much of the shortage arrived, and nearly always the answer is
/// all of it: the server fills that in, and agreeing costs a tap. Null on almost every
/// field, because a box that suggests a wrong number is worse than an empty one.
 String? get value;
/// Create a copy of TransitionField
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransitionFieldCopyWith<TransitionField> get copyWith => _$TransitionFieldCopyWithImpl<TransitionField>(this as TransitionField, _$identity);

  /// Serializes this TransitionField to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransitionField&&(identical(other.key, key) || other.key == key)&&(identical(other.type, type) || other.type == type)&&(identical(other.label, label) || other.label == label)&&(identical(other.isRequired, isRequired) || other.isRequired == isRequired)&&(identical(other.multiple, multiple) || other.multiple == multiple)&&(identical(other.multiline, multiline) || other.multiline == multiline)&&(identical(other.hint, hint) || other.hint == hint)&&(identical(other.min, min) || other.min == min)&&(identical(other.max, max) || other.max == max)&&const DeepCollectionEquality().equals(other.options, options)&&(identical(other.requiredWith, requiredWith) || other.requiredWith == requiredWith)&&(identical(other.value, value) || other.value == value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,type,label,isRequired,multiple,multiline,hint,min,max,const DeepCollectionEquality().hash(options),requiredWith,value);

@override
String toString() {
  return 'TransitionField(key: $key, type: $type, label: $label, isRequired: $isRequired, multiple: $multiple, multiline: $multiline, hint: $hint, min: $min, max: $max, options: $options, requiredWith: $requiredWith, value: $value)';
}


}

/// @nodoc
abstract mixin class $TransitionFieldCopyWith<$Res>  {
  factory $TransitionFieldCopyWith(TransitionField value, $Res Function(TransitionField) _then) = _$TransitionFieldCopyWithImpl;
@useResult
$Res call({
 String key,@JsonKey(unknownEnumValue: TransitionFieldType.unknown) TransitionFieldType type, String label,@JsonKey(name: 'required') bool isRequired, bool multiple, bool multiline, String? hint, num? min, num? max, List<TransitionFieldOption> options,@JsonKey(name: 'required_with') String? requiredWith, String? value
});




}
/// @nodoc
class _$TransitionFieldCopyWithImpl<$Res>
    implements $TransitionFieldCopyWith<$Res> {
  _$TransitionFieldCopyWithImpl(this._self, this._then);

  final TransitionField _self;
  final $Res Function(TransitionField) _then;

/// Create a copy of TransitionField
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? type = null,Object? label = null,Object? isRequired = null,Object? multiple = null,Object? multiline = null,Object? hint = freezed,Object? min = freezed,Object? max = freezed,Object? options = null,Object? requiredWith = freezed,Object? value = freezed,}) {
  return _then(_self.copyWith(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TransitionFieldType,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,isRequired: null == isRequired ? _self.isRequired : isRequired // ignore: cast_nullable_to_non_nullable
as bool,multiple: null == multiple ? _self.multiple : multiple // ignore: cast_nullable_to_non_nullable
as bool,multiline: null == multiline ? _self.multiline : multiline // ignore: cast_nullable_to_non_nullable
as bool,hint: freezed == hint ? _self.hint : hint // ignore: cast_nullable_to_non_nullable
as String?,min: freezed == min ? _self.min : min // ignore: cast_nullable_to_non_nullable
as num?,max: freezed == max ? _self.max : max // ignore: cast_nullable_to_non_nullable
as num?,options: null == options ? _self.options : options // ignore: cast_nullable_to_non_nullable
as List<TransitionFieldOption>,requiredWith: freezed == requiredWith ? _self.requiredWith : requiredWith // ignore: cast_nullable_to_non_nullable
as String?,value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TransitionField].
extension TransitionFieldPatterns on TransitionField {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransitionField value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransitionField() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransitionField value)  $default,){
final _that = this;
switch (_that) {
case _TransitionField():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransitionField value)?  $default,){
final _that = this;
switch (_that) {
case _TransitionField() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key, @JsonKey(unknownEnumValue: TransitionFieldType.unknown)  TransitionFieldType type,  String label, @JsonKey(name: 'required')  bool isRequired,  bool multiple,  bool multiline,  String? hint,  num? min,  num? max,  List<TransitionFieldOption> options, @JsonKey(name: 'required_with')  String? requiredWith,  String? value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransitionField() when $default != null:
return $default(_that.key,_that.type,_that.label,_that.isRequired,_that.multiple,_that.multiline,_that.hint,_that.min,_that.max,_that.options,_that.requiredWith,_that.value);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key, @JsonKey(unknownEnumValue: TransitionFieldType.unknown)  TransitionFieldType type,  String label, @JsonKey(name: 'required')  bool isRequired,  bool multiple,  bool multiline,  String? hint,  num? min,  num? max,  List<TransitionFieldOption> options, @JsonKey(name: 'required_with')  String? requiredWith,  String? value)  $default,) {final _that = this;
switch (_that) {
case _TransitionField():
return $default(_that.key,_that.type,_that.label,_that.isRequired,_that.multiple,_that.multiline,_that.hint,_that.min,_that.max,_that.options,_that.requiredWith,_that.value);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key, @JsonKey(unknownEnumValue: TransitionFieldType.unknown)  TransitionFieldType type,  String label, @JsonKey(name: 'required')  bool isRequired,  bool multiple,  bool multiline,  String? hint,  num? min,  num? max,  List<TransitionFieldOption> options, @JsonKey(name: 'required_with')  String? requiredWith,  String? value)?  $default,) {final _that = this;
switch (_that) {
case _TransitionField() when $default != null:
return $default(_that.key,_that.type,_that.label,_that.isRequired,_that.multiple,_that.multiline,_that.hint,_that.min,_that.max,_that.options,_that.requiredWith,_that.value);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TransitionField extends TransitionField {
  const _TransitionField({required this.key, @JsonKey(unknownEnumValue: TransitionFieldType.unknown) required this.type, required this.label, @JsonKey(name: 'required') this.isRequired = false, this.multiple = false, this.multiline = false, this.hint, this.min, this.max, final  List<TransitionFieldOption> options = const <TransitionFieldOption>[], @JsonKey(name: 'required_with') this.requiredWith, this.value}): _options = options,super._();
  factory _TransitionField.fromJson(Map<String, dynamic> json) => _$TransitionFieldFromJson(json);

/// What the value is sent back as, inside `fields`.
@override final  String key;
@override@JsonKey(unknownEnumValue: TransitionFieldType.unknown) final  TransitionFieldType type;
/// The Arabic the server chose. Rendered as-is, like every other label in this app.
@override final  String label;
@override@JsonKey(name: 'required') final  bool isRequired;
/// The field takes several values. Only meaningful for kinds that can hold more than one.
@override@JsonKey() final  bool multiple;
/// A text field of several lines rather than one.
@override@JsonKey() final  bool multiline;
/// A sentence under the field, when the server has something to say about it.
@override final  String? hint;
/// Bounds for [TransitionFieldType.number]. [max] is typically what was ordered of one
/// line — «الناقص من 30*30» can never exceed it — so it travels with the field.
@override final  num? min;
@override final  num? max;
/// The choices, for the one kind that carries its own — see
/// [TransitionFieldType.paymentMethod]. Empty for every other kind.
 final  List<TransitionFieldOption> _options;
/// The choices, for the one kind that carries its own — see
/// [TransitionFieldType.paymentMethod]. Empty for every other kind.
@override@JsonKey() List<TransitionFieldOption> get options {
  if (_options is EqualUnmodifiableListView) return _options;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_options);
}

/// The key of the field that makes this one mandatory: empty is fine on its own, and
/// refused the moment that other field is answered.
///
/// «طريقة الدفع» is meaningless without an amount and obligatory with one, and neither
/// [isRequired] nor its absence can say that. Sent down so [canSubmit] can hold the same
/// rule the endpoint enforces rather than this app keeping a second copy of it.
@override@JsonKey(name: 'required_with') final  String? requiredWith;
/// What the box opens holding — **an answer, not a placeholder.**
///
/// Leaving «نواقص» asks how much of the shortage arrived, and nearly always the answer is
/// all of it: the server fills that in, and agreeing costs a tap. Null on almost every
/// field, because a box that suggests a wrong number is worse than an empty one.
@override final  String? value;

/// Create a copy of TransitionField
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransitionFieldCopyWith<_TransitionField> get copyWith => __$TransitionFieldCopyWithImpl<_TransitionField>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TransitionFieldToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransitionField&&(identical(other.key, key) || other.key == key)&&(identical(other.type, type) || other.type == type)&&(identical(other.label, label) || other.label == label)&&(identical(other.isRequired, isRequired) || other.isRequired == isRequired)&&(identical(other.multiple, multiple) || other.multiple == multiple)&&(identical(other.multiline, multiline) || other.multiline == multiline)&&(identical(other.hint, hint) || other.hint == hint)&&(identical(other.min, min) || other.min == min)&&(identical(other.max, max) || other.max == max)&&const DeepCollectionEquality().equals(other._options, _options)&&(identical(other.requiredWith, requiredWith) || other.requiredWith == requiredWith)&&(identical(other.value, value) || other.value == value));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,type,label,isRequired,multiple,multiline,hint,min,max,const DeepCollectionEquality().hash(_options),requiredWith,value);

@override
String toString() {
  return 'TransitionField(key: $key, type: $type, label: $label, isRequired: $isRequired, multiple: $multiple, multiline: $multiline, hint: $hint, min: $min, max: $max, options: $options, requiredWith: $requiredWith, value: $value)';
}


}

/// @nodoc
abstract mixin class _$TransitionFieldCopyWith<$Res> implements $TransitionFieldCopyWith<$Res> {
  factory _$TransitionFieldCopyWith(_TransitionField value, $Res Function(_TransitionField) _then) = __$TransitionFieldCopyWithImpl;
@override @useResult
$Res call({
 String key,@JsonKey(unknownEnumValue: TransitionFieldType.unknown) TransitionFieldType type, String label,@JsonKey(name: 'required') bool isRequired, bool multiple, bool multiline, String? hint, num? min, num? max, List<TransitionFieldOption> options,@JsonKey(name: 'required_with') String? requiredWith, String? value
});




}
/// @nodoc
class __$TransitionFieldCopyWithImpl<$Res>
    implements _$TransitionFieldCopyWith<$Res> {
  __$TransitionFieldCopyWithImpl(this._self, this._then);

  final _TransitionField _self;
  final $Res Function(_TransitionField) _then;

/// Create a copy of TransitionField
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? type = null,Object? label = null,Object? isRequired = null,Object? multiple = null,Object? multiline = null,Object? hint = freezed,Object? min = freezed,Object? max = freezed,Object? options = null,Object? requiredWith = freezed,Object? value = freezed,}) {
  return _then(_TransitionField(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as TransitionFieldType,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,isRequired: null == isRequired ? _self.isRequired : isRequired // ignore: cast_nullable_to_non_nullable
as bool,multiple: null == multiple ? _self.multiple : multiple // ignore: cast_nullable_to_non_nullable
as bool,multiline: null == multiline ? _self.multiline : multiline // ignore: cast_nullable_to_non_nullable
as bool,hint: freezed == hint ? _self.hint : hint // ignore: cast_nullable_to_non_nullable
as String?,min: freezed == min ? _self.min : min // ignore: cast_nullable_to_non_nullable
as num?,max: freezed == max ? _self.max : max // ignore: cast_nullable_to_non_nullable
as num?,options: null == options ? _self._options : options // ignore: cast_nullable_to_non_nullable
as List<TransitionFieldOption>,requiredWith: freezed == requiredWith ? _self.requiredWith : requiredWith // ignore: cast_nullable_to_non_nullable
as String?,value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$TransitionFieldOption {

 String get value; String get label;
/// Create a copy of TransitionFieldOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TransitionFieldOptionCopyWith<TransitionFieldOption> get copyWith => _$TransitionFieldOptionCopyWithImpl<TransitionFieldOption>(this as TransitionFieldOption, _$identity);

  /// Serializes this TransitionFieldOption to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TransitionFieldOption&&(identical(other.value, value) || other.value == value)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,value,label);

@override
String toString() {
  return 'TransitionFieldOption(value: $value, label: $label)';
}


}

/// @nodoc
abstract mixin class $TransitionFieldOptionCopyWith<$Res>  {
  factory $TransitionFieldOptionCopyWith(TransitionFieldOption value, $Res Function(TransitionFieldOption) _then) = _$TransitionFieldOptionCopyWithImpl;
@useResult
$Res call({
 String value, String label
});




}
/// @nodoc
class _$TransitionFieldOptionCopyWithImpl<$Res>
    implements $TransitionFieldOptionCopyWith<$Res> {
  _$TransitionFieldOptionCopyWithImpl(this._self, this._then);

  final TransitionFieldOption _self;
  final $Res Function(TransitionFieldOption) _then;

/// Create a copy of TransitionFieldOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,Object? label = null,}) {
  return _then(_self.copyWith(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TransitionFieldOption].
extension TransitionFieldOptionPatterns on TransitionFieldOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TransitionFieldOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TransitionFieldOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TransitionFieldOption value)  $default,){
final _that = this;
switch (_that) {
case _TransitionFieldOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TransitionFieldOption value)?  $default,){
final _that = this;
switch (_that) {
case _TransitionFieldOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String value,  String label)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TransitionFieldOption() when $default != null:
return $default(_that.value,_that.label);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String value,  String label)  $default,) {final _that = this;
switch (_that) {
case _TransitionFieldOption():
return $default(_that.value,_that.label);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String value,  String label)?  $default,) {final _that = this;
switch (_that) {
case _TransitionFieldOption() when $default != null:
return $default(_that.value,_that.label);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TransitionFieldOption implements TransitionFieldOption {
  const _TransitionFieldOption({required this.value, required this.label});
  factory _TransitionFieldOption.fromJson(Map<String, dynamic> json) => _$TransitionFieldOptionFromJson(json);

@override final  String value;
@override final  String label;

/// Create a copy of TransitionFieldOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TransitionFieldOptionCopyWith<_TransitionFieldOption> get copyWith => __$TransitionFieldOptionCopyWithImpl<_TransitionFieldOption>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TransitionFieldOptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TransitionFieldOption&&(identical(other.value, value) || other.value == value)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,value,label);

@override
String toString() {
  return 'TransitionFieldOption(value: $value, label: $label)';
}


}

/// @nodoc
abstract mixin class _$TransitionFieldOptionCopyWith<$Res> implements $TransitionFieldOptionCopyWith<$Res> {
  factory _$TransitionFieldOptionCopyWith(_TransitionFieldOption value, $Res Function(_TransitionFieldOption) _then) = __$TransitionFieldOptionCopyWithImpl;
@override @useResult
$Res call({
 String value, String label
});




}
/// @nodoc
class __$TransitionFieldOptionCopyWithImpl<$Res>
    implements _$TransitionFieldOptionCopyWith<$Res> {
  __$TransitionFieldOptionCopyWithImpl(this._self, this._then);

  final _TransitionFieldOption _self;
  final $Res Function(_TransitionFieldOption) _then;

/// Create a copy of TransitionFieldOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = null,Object? label = null,}) {
  return _then(_TransitionFieldOption(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
