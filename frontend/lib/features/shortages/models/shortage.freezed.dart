// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shortage.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ShortageTransition {

 String get value; String get label;
/// Create a copy of ShortageTransition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShortageTransitionCopyWith<ShortageTransition> get copyWith => _$ShortageTransitionCopyWithImpl<ShortageTransition>(this as ShortageTransition, _$identity);

  /// Serializes this ShortageTransition to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShortageTransition&&(identical(other.value, value) || other.value == value)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,value,label);

@override
String toString() {
  return 'ShortageTransition(value: $value, label: $label)';
}


}

/// @nodoc
abstract mixin class $ShortageTransitionCopyWith<$Res>  {
  factory $ShortageTransitionCopyWith(ShortageTransition value, $Res Function(ShortageTransition) _then) = _$ShortageTransitionCopyWithImpl;
@useResult
$Res call({
 String value, String label
});




}
/// @nodoc
class _$ShortageTransitionCopyWithImpl<$Res>
    implements $ShortageTransitionCopyWith<$Res> {
  _$ShortageTransitionCopyWithImpl(this._self, this._then);

  final ShortageTransition _self;
  final $Res Function(ShortageTransition) _then;

/// Create a copy of ShortageTransition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,Object? label = null,}) {
  return _then(_self.copyWith(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ShortageTransition].
extension ShortageTransitionPatterns on ShortageTransition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShortageTransition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShortageTransition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShortageTransition value)  $default,){
final _that = this;
switch (_that) {
case _ShortageTransition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShortageTransition value)?  $default,){
final _that = this;
switch (_that) {
case _ShortageTransition() when $default != null:
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
case _ShortageTransition() when $default != null:
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
case _ShortageTransition():
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
case _ShortageTransition() when $default != null:
return $default(_that.value,_that.label);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShortageTransition implements ShortageTransition {
  const _ShortageTransition({required this.value, required this.label});
  factory _ShortageTransition.fromJson(Map<String, dynamic> json) => _$ShortageTransitionFromJson(json);

@override final  String value;
@override final  String label;

/// Create a copy of ShortageTransition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShortageTransitionCopyWith<_ShortageTransition> get copyWith => __$ShortageTransitionCopyWithImpl<_ShortageTransition>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShortageTransitionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShortageTransition&&(identical(other.value, value) || other.value == value)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,value,label);

@override
String toString() {
  return 'ShortageTransition(value: $value, label: $label)';
}


}

/// @nodoc
abstract mixin class _$ShortageTransitionCopyWith<$Res> implements $ShortageTransitionCopyWith<$Res> {
  factory _$ShortageTransitionCopyWith(_ShortageTransition value, $Res Function(_ShortageTransition) _then) = __$ShortageTransitionCopyWithImpl;
@override @useResult
$Res call({
 String value, String label
});




}
/// @nodoc
class __$ShortageTransitionCopyWithImpl<$Res>
    implements _$ShortageTransitionCopyWith<$Res> {
  __$ShortageTransitionCopyWithImpl(this._self, this._then);

  final _ShortageTransition _self;
  final $Res Function(_ShortageTransition) _then;

/// Create a copy of ShortageTransition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = null,Object? label = null,}) {
  return _then(_ShortageTransition(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ShortageOrderRef {

 int get id; String get code; String? get status;@JsonKey(name: 'is_archived') bool get isArchived;
/// Create a copy of ShortageOrderRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShortageOrderRefCopyWith<ShortageOrderRef> get copyWith => _$ShortageOrderRefCopyWithImpl<ShortageOrderRef>(this as ShortageOrderRef, _$identity);

  /// Serializes this ShortageOrderRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShortageOrderRef&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.status, status) || other.status == status)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,status,isArchived);

@override
String toString() {
  return 'ShortageOrderRef(id: $id, code: $code, status: $status, isArchived: $isArchived)';
}


}

/// @nodoc
abstract mixin class $ShortageOrderRefCopyWith<$Res>  {
  factory $ShortageOrderRefCopyWith(ShortageOrderRef value, $Res Function(ShortageOrderRef) _then) = _$ShortageOrderRefCopyWithImpl;
@useResult
$Res call({
 int id, String code, String? status,@JsonKey(name: 'is_archived') bool isArchived
});




}
/// @nodoc
class _$ShortageOrderRefCopyWithImpl<$Res>
    implements $ShortageOrderRefCopyWith<$Res> {
  _$ShortageOrderRefCopyWithImpl(this._self, this._then);

  final ShortageOrderRef _self;
  final $Res Function(ShortageOrderRef) _then;

/// Create a copy of ShortageOrderRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? status = freezed,Object? isArchived = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ShortageOrderRef].
extension ShortageOrderRefPatterns on ShortageOrderRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShortageOrderRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShortageOrderRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShortageOrderRef value)  $default,){
final _that = this;
switch (_that) {
case _ShortageOrderRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShortageOrderRef value)?  $default,){
final _that = this;
switch (_that) {
case _ShortageOrderRef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String code,  String? status, @JsonKey(name: 'is_archived')  bool isArchived)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShortageOrderRef() when $default != null:
return $default(_that.id,_that.code,_that.status,_that.isArchived);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String code,  String? status, @JsonKey(name: 'is_archived')  bool isArchived)  $default,) {final _that = this;
switch (_that) {
case _ShortageOrderRef():
return $default(_that.id,_that.code,_that.status,_that.isArchived);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String code,  String? status, @JsonKey(name: 'is_archived')  bool isArchived)?  $default,) {final _that = this;
switch (_that) {
case _ShortageOrderRef() when $default != null:
return $default(_that.id,_that.code,_that.status,_that.isArchived);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShortageOrderRef implements ShortageOrderRef {
  const _ShortageOrderRef({required this.id, required this.code, this.status, @JsonKey(name: 'is_archived') this.isArchived = false});
  factory _ShortageOrderRef.fromJson(Map<String, dynamic> json) => _$ShortageOrderRefFromJson(json);

@override final  int id;
@override final  String code;
@override final  String? status;
@override@JsonKey(name: 'is_archived') final  bool isArchived;

/// Create a copy of ShortageOrderRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShortageOrderRefCopyWith<_ShortageOrderRef> get copyWith => __$ShortageOrderRefCopyWithImpl<_ShortageOrderRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShortageOrderRefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShortageOrderRef&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.status, status) || other.status == status)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,status,isArchived);

@override
String toString() {
  return 'ShortageOrderRef(id: $id, code: $code, status: $status, isArchived: $isArchived)';
}


}

/// @nodoc
abstract mixin class _$ShortageOrderRefCopyWith<$Res> implements $ShortageOrderRefCopyWith<$Res> {
  factory _$ShortageOrderRefCopyWith(_ShortageOrderRef value, $Res Function(_ShortageOrderRef) _then) = __$ShortageOrderRefCopyWithImpl;
@override @useResult
$Res call({
 int id, String code, String? status,@JsonKey(name: 'is_archived') bool isArchived
});




}
/// @nodoc
class __$ShortageOrderRefCopyWithImpl<$Res>
    implements _$ShortageOrderRefCopyWith<$Res> {
  __$ShortageOrderRefCopyWithImpl(this._self, this._then);

  final _ShortageOrderRef _self;
  final $Res Function(_ShortageOrderRef) _then;

/// Create a copy of ShortageOrderRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? status = freezed,Object? isArchived = null,}) {
  return _then(_ShortageOrderRef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ShortagePerson {

 int get id; String get name;@JsonKey(name: 'employee_code') String? get employeeCode;
/// Create a copy of ShortagePerson
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShortagePersonCopyWith<ShortagePerson> get copyWith => _$ShortagePersonCopyWithImpl<ShortagePerson>(this as ShortagePerson, _$identity);

  /// Serializes this ShortagePerson to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShortagePerson&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.employeeCode, employeeCode) || other.employeeCode == employeeCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,employeeCode);

@override
String toString() {
  return 'ShortagePerson(id: $id, name: $name, employeeCode: $employeeCode)';
}


}

/// @nodoc
abstract mixin class $ShortagePersonCopyWith<$Res>  {
  factory $ShortagePersonCopyWith(ShortagePerson value, $Res Function(ShortagePerson) _then) = _$ShortagePersonCopyWithImpl;
@useResult
$Res call({
 int id, String name,@JsonKey(name: 'employee_code') String? employeeCode
});




}
/// @nodoc
class _$ShortagePersonCopyWithImpl<$Res>
    implements $ShortagePersonCopyWith<$Res> {
  _$ShortagePersonCopyWithImpl(this._self, this._then);

  final ShortagePerson _self;
  final $Res Function(ShortagePerson) _then;

/// Create a copy of ShortagePerson
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? employeeCode = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,employeeCode: freezed == employeeCode ? _self.employeeCode : employeeCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ShortagePerson].
extension ShortagePersonPatterns on ShortagePerson {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShortagePerson value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShortagePerson() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShortagePerson value)  $default,){
final _that = this;
switch (_that) {
case _ShortagePerson():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShortagePerson value)?  $default,){
final _that = this;
switch (_that) {
case _ShortagePerson() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'employee_code')  String? employeeCode)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShortagePerson() when $default != null:
return $default(_that.id,_that.name,_that.employeeCode);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'employee_code')  String? employeeCode)  $default,) {final _that = this;
switch (_that) {
case _ShortagePerson():
return $default(_that.id,_that.name,_that.employeeCode);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name, @JsonKey(name: 'employee_code')  String? employeeCode)?  $default,) {final _that = this;
switch (_that) {
case _ShortagePerson() when $default != null:
return $default(_that.id,_that.name,_that.employeeCode);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShortagePerson implements ShortagePerson {
  const _ShortagePerson({required this.id, required this.name, @JsonKey(name: 'employee_code') this.employeeCode});
  factory _ShortagePerson.fromJson(Map<String, dynamic> json) => _$ShortagePersonFromJson(json);

@override final  int id;
@override final  String name;
@override@JsonKey(name: 'employee_code') final  String? employeeCode;

/// Create a copy of ShortagePerson
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShortagePersonCopyWith<_ShortagePerson> get copyWith => __$ShortagePersonCopyWithImpl<_ShortagePerson>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShortagePersonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShortagePerson&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.employeeCode, employeeCode) || other.employeeCode == employeeCode));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,employeeCode);

@override
String toString() {
  return 'ShortagePerson(id: $id, name: $name, employeeCode: $employeeCode)';
}


}

/// @nodoc
abstract mixin class _$ShortagePersonCopyWith<$Res> implements $ShortagePersonCopyWith<$Res> {
  factory _$ShortagePersonCopyWith(_ShortagePerson value, $Res Function(_ShortagePerson) _then) = __$ShortagePersonCopyWithImpl;
@override @useResult
$Res call({
 int id, String name,@JsonKey(name: 'employee_code') String? employeeCode
});




}
/// @nodoc
class __$ShortagePersonCopyWithImpl<$Res>
    implements _$ShortagePersonCopyWith<$Res> {
  __$ShortagePersonCopyWithImpl(this._self, this._then);

  final _ShortagePerson _self;
  final $Res Function(_ShortagePerson) _then;

/// Create a copy of ShortagePerson
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? employeeCode = freezed,}) {
  return _then(_ShortagePerson(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,employeeCode: freezed == employeeCode ? _self.employeeCode : employeeCode // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ShortageCustomerRef {

 int get id; String get name; String? get phone;
/// Create a copy of ShortageCustomerRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShortageCustomerRefCopyWith<ShortageCustomerRef> get copyWith => _$ShortageCustomerRefCopyWithImpl<ShortageCustomerRef>(this as ShortageCustomerRef, _$identity);

  /// Serializes this ShortageCustomerRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShortageCustomerRef&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,phone);

@override
String toString() {
  return 'ShortageCustomerRef(id: $id, name: $name, phone: $phone)';
}


}

/// @nodoc
abstract mixin class $ShortageCustomerRefCopyWith<$Res>  {
  factory $ShortageCustomerRefCopyWith(ShortageCustomerRef value, $Res Function(ShortageCustomerRef) _then) = _$ShortageCustomerRefCopyWithImpl;
@useResult
$Res call({
 int id, String name, String? phone
});




}
/// @nodoc
class _$ShortageCustomerRefCopyWithImpl<$Res>
    implements $ShortageCustomerRefCopyWith<$Res> {
  _$ShortageCustomerRefCopyWithImpl(this._self, this._then);

  final ShortageCustomerRef _self;
  final $Res Function(ShortageCustomerRef) _then;

/// Create a copy of ShortageCustomerRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? phone = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ShortageCustomerRef].
extension ShortageCustomerRefPatterns on ShortageCustomerRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShortageCustomerRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShortageCustomerRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShortageCustomerRef value)  $default,){
final _that = this;
switch (_that) {
case _ShortageCustomerRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShortageCustomerRef value)?  $default,){
final _that = this;
switch (_that) {
case _ShortageCustomerRef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String? phone)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShortageCustomerRef() when $default != null:
return $default(_that.id,_that.name,_that.phone);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String? phone)  $default,) {final _that = this;
switch (_that) {
case _ShortageCustomerRef():
return $default(_that.id,_that.name,_that.phone);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String? phone)?  $default,) {final _that = this;
switch (_that) {
case _ShortageCustomerRef() when $default != null:
return $default(_that.id,_that.name,_that.phone);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShortageCustomerRef implements ShortageCustomerRef {
  const _ShortageCustomerRef({required this.id, required this.name, this.phone});
  factory _ShortageCustomerRef.fromJson(Map<String, dynamic> json) => _$ShortageCustomerRefFromJson(json);

@override final  int id;
@override final  String name;
@override final  String? phone;

/// Create a copy of ShortageCustomerRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShortageCustomerRefCopyWith<_ShortageCustomerRef> get copyWith => __$ShortageCustomerRefCopyWithImpl<_ShortageCustomerRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShortageCustomerRefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShortageCustomerRef&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,phone);

@override
String toString() {
  return 'ShortageCustomerRef(id: $id, name: $name, phone: $phone)';
}


}

/// @nodoc
abstract mixin class _$ShortageCustomerRefCopyWith<$Res> implements $ShortageCustomerRefCopyWith<$Res> {
  factory _$ShortageCustomerRefCopyWith(_ShortageCustomerRef value, $Res Function(_ShortageCustomerRef) _then) = __$ShortageCustomerRefCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String? phone
});




}
/// @nodoc
class __$ShortageCustomerRefCopyWithImpl<$Res>
    implements _$ShortageCustomerRefCopyWith<$Res> {
  __$ShortageCustomerRefCopyWithImpl(this._self, this._then);

  final _ShortageCustomerRef _self;
  final $Res Function(_ShortageCustomerRef) _then;

/// Create a copy of ShortageCustomerRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? phone = freezed,}) {
  return _then(_ShortageCustomerRef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ShortageProductRef {

 int get id; String get name;
/// Create a copy of ShortageProductRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShortageProductRefCopyWith<ShortageProductRef> get copyWith => _$ShortageProductRefCopyWithImpl<ShortageProductRef>(this as ShortageProductRef, _$identity);

  /// Serializes this ShortageProductRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShortageProductRef&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'ShortageProductRef(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $ShortageProductRefCopyWith<$Res>  {
  factory $ShortageProductRefCopyWith(ShortageProductRef value, $Res Function(ShortageProductRef) _then) = _$ShortageProductRefCopyWithImpl;
@useResult
$Res call({
 int id, String name
});




}
/// @nodoc
class _$ShortageProductRefCopyWithImpl<$Res>
    implements $ShortageProductRefCopyWith<$Res> {
  _$ShortageProductRefCopyWithImpl(this._self, this._then);

  final ShortageProductRef _self;
  final $Res Function(ShortageProductRef) _then;

/// Create a copy of ShortageProductRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ShortageProductRef].
extension ShortageProductRefPatterns on ShortageProductRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShortageProductRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShortageProductRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShortageProductRef value)  $default,){
final _that = this;
switch (_that) {
case _ShortageProductRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShortageProductRef value)?  $default,){
final _that = this;
switch (_that) {
case _ShortageProductRef() when $default != null:
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
case _ShortageProductRef() when $default != null:
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
case _ShortageProductRef():
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
case _ShortageProductRef() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShortageProductRef implements ShortageProductRef {
  const _ShortageProductRef({required this.id, required this.name});
  factory _ShortageProductRef.fromJson(Map<String, dynamic> json) => _$ShortageProductRefFromJson(json);

@override final  int id;
@override final  String name;

/// Create a copy of ShortageProductRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShortageProductRefCopyWith<_ShortageProductRef> get copyWith => __$ShortageProductRefCopyWithImpl<_ShortageProductRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShortageProductRefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShortageProductRef&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'ShortageProductRef(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$ShortageProductRefCopyWith<$Res> implements $ShortageProductRefCopyWith<$Res> {
  factory _$ShortageProductRefCopyWith(_ShortageProductRef value, $Res Function(_ShortageProductRef) _then) = __$ShortageProductRefCopyWithImpl;
@override @useResult
$Res call({
 int id, String name
});




}
/// @nodoc
class __$ShortageProductRefCopyWithImpl<$Res>
    implements _$ShortageProductRefCopyWith<$Res> {
  __$ShortageProductRefCopyWithImpl(this._self, this._then);

  final _ShortageProductRef _self;
  final $Res Function(_ShortageProductRef) _then;

/// Create a copy of ShortageProductRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_ShortageProductRef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$ShortageVariantRef {

 int get id; String get label;
/// Create a copy of ShortageVariantRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShortageVariantRefCopyWith<ShortageVariantRef> get copyWith => _$ShortageVariantRefCopyWithImpl<ShortageVariantRef>(this as ShortageVariantRef, _$identity);

  /// Serializes this ShortageVariantRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShortageVariantRef&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label);

@override
String toString() {
  return 'ShortageVariantRef(id: $id, label: $label)';
}


}

/// @nodoc
abstract mixin class $ShortageVariantRefCopyWith<$Res>  {
  factory $ShortageVariantRefCopyWith(ShortageVariantRef value, $Res Function(ShortageVariantRef) _then) = _$ShortageVariantRefCopyWithImpl;
@useResult
$Res call({
 int id, String label
});




}
/// @nodoc
class _$ShortageVariantRefCopyWithImpl<$Res>
    implements $ShortageVariantRefCopyWith<$Res> {
  _$ShortageVariantRefCopyWithImpl(this._self, this._then);

  final ShortageVariantRef _self;
  final $Res Function(ShortageVariantRef) _then;

/// Create a copy of ShortageVariantRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ShortageVariantRef].
extension ShortageVariantRefPatterns on ShortageVariantRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShortageVariantRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShortageVariantRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShortageVariantRef value)  $default,){
final _that = this;
switch (_that) {
case _ShortageVariantRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShortageVariantRef value)?  $default,){
final _that = this;
switch (_that) {
case _ShortageVariantRef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String label)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShortageVariantRef() when $default != null:
return $default(_that.id,_that.label);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String label)  $default,) {final _that = this;
switch (_that) {
case _ShortageVariantRef():
return $default(_that.id,_that.label);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String label)?  $default,) {final _that = this;
switch (_that) {
case _ShortageVariantRef() when $default != null:
return $default(_that.id,_that.label);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ShortageVariantRef implements ShortageVariantRef {
  const _ShortageVariantRef({required this.id, required this.label});
  factory _ShortageVariantRef.fromJson(Map<String, dynamic> json) => _$ShortageVariantRefFromJson(json);

@override final  int id;
@override final  String label;

/// Create a copy of ShortageVariantRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShortageVariantRefCopyWith<_ShortageVariantRef> get copyWith => __$ShortageVariantRefCopyWithImpl<_ShortageVariantRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShortageVariantRefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShortageVariantRef&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,label);

@override
String toString() {
  return 'ShortageVariantRef(id: $id, label: $label)';
}


}

/// @nodoc
abstract mixin class _$ShortageVariantRefCopyWith<$Res> implements $ShortageVariantRefCopyWith<$Res> {
  factory _$ShortageVariantRefCopyWith(_ShortageVariantRef value, $Res Function(_ShortageVariantRef) _then) = __$ShortageVariantRefCopyWithImpl;
@override @useResult
$Res call({
 int id, String label
});




}
/// @nodoc
class __$ShortageVariantRefCopyWithImpl<$Res>
    implements _$ShortageVariantRefCopyWith<$Res> {
  __$ShortageVariantRefCopyWithImpl(this._self, this._then);

  final _ShortageVariantRef _self;
  final $Res Function(_ShortageVariantRef) _then;

/// Create a copy of ShortageVariantRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,}) {
  return _then(_ShortageVariantRef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$Shortage {

 int get id; String get code;@JsonKey(unknownEnumValue: ShortageSource.unknown) ShortageSource get source;@JsonKey(name: 'source_label') String get sourceLabel;/// What kind of thing is short — see [ShortageType]. Defaulted rather than required so a
/// payload from a server too old to send it renders as «أخرى» instead of failing to parse.
@JsonKey(unknownEnumValue: ShortageType.unknown) ShortageType get type;@JsonKey(name: 'type_label') String? get typeLabel;/// «كيس شحن — 25*35», or whatever somebody typed on a manual one.
 String get name;/// The unit the quantities are counted in, and the server's own word for it. The label is
/// what every screen prints; nothing branches on the value.
 String? get unit;@JsonKey(name: 'unit_label') String? get unitLabel;@JsonKey(name: 'required_quantity') String get requiredQuantity;@JsonKey(name: 'supplied_quantity') String get suppliedQuantity;@JsonKey(name: 'remaining_quantity') String get remainingQuantity;@JsonKey(name: 'total_paid') String get totalPaid;@JsonKey(unknownEnumValue: ShortageStatus.unknown) ShortageStatus get status;@JsonKey(name: 'status_label') String get statusLabel;@JsonKey(name: 'is_final') bool get isFinal;/// Exactly the buttons to draw, and no others — see [ShortageTransition].
@JsonKey(name: 'available_transitions') List<ShortageTransition> get availableTransitions;/// Whether the form may be opened on it. **False on a shortage born of an order**, whose
/// quantity is corrected from the order screen — the server says so rather than the app
/// deriving it from [source], because the rule is the server's.
@JsonKey(name: 'is_editable') bool get isEditable;/// Whether the goods have a shelf to land on.
///
/// **Read, never inferred.** Deriving it from `product_variant_id` would put a warehouse
/// picker in front of a roll of tape — and sending a warehouse for one is a 422 in its own
/// right, because the caller would be telling the server goods are moving when they are not.
@JsonKey(name: 'is_stockable') bool get isStockable;/// What this row will be counted in once somebody states the weight.
///
/// The same as [unitLabel] on every ordinary shortage. It differs only while an order-born
/// row is still waiting: the bags are missing, so the row is counted in the unit it was sold
/// in and this is what it will convert to — which is what labels the box that asks.
@JsonKey(name: 'stock_unit') String? get stockUnit;@JsonKey(name: 'stock_unit_label') String? get stockUnitLabel;/// Whether this shortage is still waiting for somebody to say how much is owed.
///
/// **Read, never inferred.** It depends on the stock item behind the size, two relations past
/// the order line, and no payload the app holds can see it. While true, every supply is
/// refused — so this is also why the record button will turn somebody away.
@JsonKey(name: 'weight_is_unknown') bool get weightIsUnknown;@JsonKey(name: 'order_id') int? get orderId;@JsonKey(name: 'order_item_id') int? get orderItemId; ShortageOrderRef? get order;@JsonKey(name: 'customer_id') int? get customerId; ShortageCustomerRef? get customer;@JsonKey(name: 'product_id') int? get productId;@JsonKey(name: 'product_variant_id') int? get productVariantId; ShortageProductRef? get product; ShortageVariantRef? get variant;@JsonKey(name: 'assigned_to_user_id') int? get assignedToUserId; ShortagePerson? get assignee;@JsonKey(name: 'created_by_user_id') int? get createdByUserId; ShortagePerson? get creator; String? get description;/// The ledger — **detail payload only**, so an empty list on a card means «not asked for»
/// rather than «nothing happened».
 List<ShortageSupply> get supplies;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of Shortage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShortageCopyWith<Shortage> get copyWith => _$ShortageCopyWithImpl<Shortage>(this as Shortage, _$identity);

  /// Serializes this Shortage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Shortage&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.source, source) || other.source == source)&&(identical(other.sourceLabel, sourceLabel) || other.sourceLabel == sourceLabel)&&(identical(other.type, type) || other.type == type)&&(identical(other.typeLabel, typeLabel) || other.typeLabel == typeLabel)&&(identical(other.name, name) || other.name == name)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.unitLabel, unitLabel) || other.unitLabel == unitLabel)&&(identical(other.requiredQuantity, requiredQuantity) || other.requiredQuantity == requiredQuantity)&&(identical(other.suppliedQuantity, suppliedQuantity) || other.suppliedQuantity == suppliedQuantity)&&(identical(other.remainingQuantity, remainingQuantity) || other.remainingQuantity == remainingQuantity)&&(identical(other.totalPaid, totalPaid) || other.totalPaid == totalPaid)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.isFinal, isFinal) || other.isFinal == isFinal)&&const DeepCollectionEquality().equals(other.availableTransitions, availableTransitions)&&(identical(other.isEditable, isEditable) || other.isEditable == isEditable)&&(identical(other.isStockable, isStockable) || other.isStockable == isStockable)&&(identical(other.stockUnit, stockUnit) || other.stockUnit == stockUnit)&&(identical(other.stockUnitLabel, stockUnitLabel) || other.stockUnitLabel == stockUnitLabel)&&(identical(other.weightIsUnknown, weightIsUnknown) || other.weightIsUnknown == weightIsUnknown)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.orderItemId, orderItemId) || other.orderItemId == orderItemId)&&(identical(other.order, order) || other.order == order)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.customer, customer) || other.customer == customer)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productVariantId, productVariantId) || other.productVariantId == productVariantId)&&(identical(other.product, product) || other.product == product)&&(identical(other.variant, variant) || other.variant == variant)&&(identical(other.assignedToUserId, assignedToUserId) || other.assignedToUserId == assignedToUserId)&&(identical(other.assignee, assignee) || other.assignee == assignee)&&(identical(other.createdByUserId, createdByUserId) || other.createdByUserId == createdByUserId)&&(identical(other.creator, creator) || other.creator == creator)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.supplies, supplies)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,code,source,sourceLabel,type,typeLabel,name,unit,unitLabel,requiredQuantity,suppliedQuantity,remainingQuantity,totalPaid,status,statusLabel,isFinal,const DeepCollectionEquality().hash(availableTransitions),isEditable,isStockable,stockUnit,stockUnitLabel,weightIsUnknown,orderId,orderItemId,order,customerId,customer,productId,productVariantId,product,variant,assignedToUserId,assignee,createdByUserId,creator,description,const DeepCollectionEquality().hash(supplies),createdAt,updatedAt]);

@override
String toString() {
  return 'Shortage(id: $id, code: $code, source: $source, sourceLabel: $sourceLabel, type: $type, typeLabel: $typeLabel, name: $name, unit: $unit, unitLabel: $unitLabel, requiredQuantity: $requiredQuantity, suppliedQuantity: $suppliedQuantity, remainingQuantity: $remainingQuantity, totalPaid: $totalPaid, status: $status, statusLabel: $statusLabel, isFinal: $isFinal, availableTransitions: $availableTransitions, isEditable: $isEditable, isStockable: $isStockable, stockUnit: $stockUnit, stockUnitLabel: $stockUnitLabel, weightIsUnknown: $weightIsUnknown, orderId: $orderId, orderItemId: $orderItemId, order: $order, customerId: $customerId, customer: $customer, productId: $productId, productVariantId: $productVariantId, product: $product, variant: $variant, assignedToUserId: $assignedToUserId, assignee: $assignee, createdByUserId: $createdByUserId, creator: $creator, description: $description, supplies: $supplies, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ShortageCopyWith<$Res>  {
  factory $ShortageCopyWith(Shortage value, $Res Function(Shortage) _then) = _$ShortageCopyWithImpl;
@useResult
$Res call({
 int id, String code,@JsonKey(unknownEnumValue: ShortageSource.unknown) ShortageSource source,@JsonKey(name: 'source_label') String sourceLabel,@JsonKey(unknownEnumValue: ShortageType.unknown) ShortageType type,@JsonKey(name: 'type_label') String? typeLabel, String name, String? unit,@JsonKey(name: 'unit_label') String? unitLabel,@JsonKey(name: 'required_quantity') String requiredQuantity,@JsonKey(name: 'supplied_quantity') String suppliedQuantity,@JsonKey(name: 'remaining_quantity') String remainingQuantity,@JsonKey(name: 'total_paid') String totalPaid,@JsonKey(unknownEnumValue: ShortageStatus.unknown) ShortageStatus status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'is_final') bool isFinal,@JsonKey(name: 'available_transitions') List<ShortageTransition> availableTransitions,@JsonKey(name: 'is_editable') bool isEditable,@JsonKey(name: 'is_stockable') bool isStockable,@JsonKey(name: 'stock_unit') String? stockUnit,@JsonKey(name: 'stock_unit_label') String? stockUnitLabel,@JsonKey(name: 'weight_is_unknown') bool weightIsUnknown,@JsonKey(name: 'order_id') int? orderId,@JsonKey(name: 'order_item_id') int? orderItemId, ShortageOrderRef? order,@JsonKey(name: 'customer_id') int? customerId, ShortageCustomerRef? customer,@JsonKey(name: 'product_id') int? productId,@JsonKey(name: 'product_variant_id') int? productVariantId, ShortageProductRef? product, ShortageVariantRef? variant,@JsonKey(name: 'assigned_to_user_id') int? assignedToUserId, ShortagePerson? assignee,@JsonKey(name: 'created_by_user_id') int? createdByUserId, ShortagePerson? creator, String? description, List<ShortageSupply> supplies,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});


$ShortageOrderRefCopyWith<$Res>? get order;$ShortageCustomerRefCopyWith<$Res>? get customer;$ShortageProductRefCopyWith<$Res>? get product;$ShortageVariantRefCopyWith<$Res>? get variant;$ShortagePersonCopyWith<$Res>? get assignee;$ShortagePersonCopyWith<$Res>? get creator;

}
/// @nodoc
class _$ShortageCopyWithImpl<$Res>
    implements $ShortageCopyWith<$Res> {
  _$ShortageCopyWithImpl(this._self, this._then);

  final Shortage _self;
  final $Res Function(Shortage) _then;

/// Create a copy of Shortage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? source = null,Object? sourceLabel = null,Object? type = null,Object? typeLabel = freezed,Object? name = null,Object? unit = freezed,Object? unitLabel = freezed,Object? requiredQuantity = null,Object? suppliedQuantity = null,Object? remainingQuantity = null,Object? totalPaid = null,Object? status = null,Object? statusLabel = null,Object? isFinal = null,Object? availableTransitions = null,Object? isEditable = null,Object? isStockable = null,Object? stockUnit = freezed,Object? stockUnitLabel = freezed,Object? weightIsUnknown = null,Object? orderId = freezed,Object? orderItemId = freezed,Object? order = freezed,Object? customerId = freezed,Object? customer = freezed,Object? productId = freezed,Object? productVariantId = freezed,Object? product = freezed,Object? variant = freezed,Object? assignedToUserId = freezed,Object? assignee = freezed,Object? createdByUserId = freezed,Object? creator = freezed,Object? description = freezed,Object? supplies = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as ShortageSource,sourceLabel: null == sourceLabel ? _self.sourceLabel : sourceLabel // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ShortageType,typeLabel: freezed == typeLabel ? _self.typeLabel : typeLabel // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,unitLabel: freezed == unitLabel ? _self.unitLabel : unitLabel // ignore: cast_nullable_to_non_nullable
as String?,requiredQuantity: null == requiredQuantity ? _self.requiredQuantity : requiredQuantity // ignore: cast_nullable_to_non_nullable
as String,suppliedQuantity: null == suppliedQuantity ? _self.suppliedQuantity : suppliedQuantity // ignore: cast_nullable_to_non_nullable
as String,remainingQuantity: null == remainingQuantity ? _self.remainingQuantity : remainingQuantity // ignore: cast_nullable_to_non_nullable
as String,totalPaid: null == totalPaid ? _self.totalPaid : totalPaid // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ShortageStatus,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,isFinal: null == isFinal ? _self.isFinal : isFinal // ignore: cast_nullable_to_non_nullable
as bool,availableTransitions: null == availableTransitions ? _self.availableTransitions : availableTransitions // ignore: cast_nullable_to_non_nullable
as List<ShortageTransition>,isEditable: null == isEditable ? _self.isEditable : isEditable // ignore: cast_nullable_to_non_nullable
as bool,isStockable: null == isStockable ? _self.isStockable : isStockable // ignore: cast_nullable_to_non_nullable
as bool,stockUnit: freezed == stockUnit ? _self.stockUnit : stockUnit // ignore: cast_nullable_to_non_nullable
as String?,stockUnitLabel: freezed == stockUnitLabel ? _self.stockUnitLabel : stockUnitLabel // ignore: cast_nullable_to_non_nullable
as String?,weightIsUnknown: null == weightIsUnknown ? _self.weightIsUnknown : weightIsUnknown // ignore: cast_nullable_to_non_nullable
as bool,orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as int?,orderItemId: freezed == orderItemId ? _self.orderItemId : orderItemId // ignore: cast_nullable_to_non_nullable
as int?,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as ShortageOrderRef?,customerId: freezed == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as int?,customer: freezed == customer ? _self.customer : customer // ignore: cast_nullable_to_non_nullable
as ShortageCustomerRef?,productId: freezed == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as int?,productVariantId: freezed == productVariantId ? _self.productVariantId : productVariantId // ignore: cast_nullable_to_non_nullable
as int?,product: freezed == product ? _self.product : product // ignore: cast_nullable_to_non_nullable
as ShortageProductRef?,variant: freezed == variant ? _self.variant : variant // ignore: cast_nullable_to_non_nullable
as ShortageVariantRef?,assignedToUserId: freezed == assignedToUserId ? _self.assignedToUserId : assignedToUserId // ignore: cast_nullable_to_non_nullable
as int?,assignee: freezed == assignee ? _self.assignee : assignee // ignore: cast_nullable_to_non_nullable
as ShortagePerson?,createdByUserId: freezed == createdByUserId ? _self.createdByUserId : createdByUserId // ignore: cast_nullable_to_non_nullable
as int?,creator: freezed == creator ? _self.creator : creator // ignore: cast_nullable_to_non_nullable
as ShortagePerson?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,supplies: null == supplies ? _self.supplies : supplies // ignore: cast_nullable_to_non_nullable
as List<ShortageSupply>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of Shortage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShortageOrderRefCopyWith<$Res>? get order {
    if (_self.order == null) {
    return null;
  }

  return $ShortageOrderRefCopyWith<$Res>(_self.order!, (value) {
    return _then(_self.copyWith(order: value));
  });
}/// Create a copy of Shortage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShortageCustomerRefCopyWith<$Res>? get customer {
    if (_self.customer == null) {
    return null;
  }

  return $ShortageCustomerRefCopyWith<$Res>(_self.customer!, (value) {
    return _then(_self.copyWith(customer: value));
  });
}/// Create a copy of Shortage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShortageProductRefCopyWith<$Res>? get product {
    if (_self.product == null) {
    return null;
  }

  return $ShortageProductRefCopyWith<$Res>(_self.product!, (value) {
    return _then(_self.copyWith(product: value));
  });
}/// Create a copy of Shortage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShortageVariantRefCopyWith<$Res>? get variant {
    if (_self.variant == null) {
    return null;
  }

  return $ShortageVariantRefCopyWith<$Res>(_self.variant!, (value) {
    return _then(_self.copyWith(variant: value));
  });
}/// Create a copy of Shortage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShortagePersonCopyWith<$Res>? get assignee {
    if (_self.assignee == null) {
    return null;
  }

  return $ShortagePersonCopyWith<$Res>(_self.assignee!, (value) {
    return _then(_self.copyWith(assignee: value));
  });
}/// Create a copy of Shortage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShortagePersonCopyWith<$Res>? get creator {
    if (_self.creator == null) {
    return null;
  }

  return $ShortagePersonCopyWith<$Res>(_self.creator!, (value) {
    return _then(_self.copyWith(creator: value));
  });
}
}


/// Adds pattern-matching-related methods to [Shortage].
extension ShortagePatterns on Shortage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Shortage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Shortage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Shortage value)  $default,){
final _that = this;
switch (_that) {
case _Shortage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Shortage value)?  $default,){
final _that = this;
switch (_that) {
case _Shortage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String code, @JsonKey(unknownEnumValue: ShortageSource.unknown)  ShortageSource source, @JsonKey(name: 'source_label')  String sourceLabel, @JsonKey(unknownEnumValue: ShortageType.unknown)  ShortageType type, @JsonKey(name: 'type_label')  String? typeLabel,  String name,  String? unit, @JsonKey(name: 'unit_label')  String? unitLabel, @JsonKey(name: 'required_quantity')  String requiredQuantity, @JsonKey(name: 'supplied_quantity')  String suppliedQuantity, @JsonKey(name: 'remaining_quantity')  String remainingQuantity, @JsonKey(name: 'total_paid')  String totalPaid, @JsonKey(unknownEnumValue: ShortageStatus.unknown)  ShortageStatus status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'is_final')  bool isFinal, @JsonKey(name: 'available_transitions')  List<ShortageTransition> availableTransitions, @JsonKey(name: 'is_editable')  bool isEditable, @JsonKey(name: 'is_stockable')  bool isStockable, @JsonKey(name: 'stock_unit')  String? stockUnit, @JsonKey(name: 'stock_unit_label')  String? stockUnitLabel, @JsonKey(name: 'weight_is_unknown')  bool weightIsUnknown, @JsonKey(name: 'order_id')  int? orderId, @JsonKey(name: 'order_item_id')  int? orderItemId,  ShortageOrderRef? order, @JsonKey(name: 'customer_id')  int? customerId,  ShortageCustomerRef? customer, @JsonKey(name: 'product_id')  int? productId, @JsonKey(name: 'product_variant_id')  int? productVariantId,  ShortageProductRef? product,  ShortageVariantRef? variant, @JsonKey(name: 'assigned_to_user_id')  int? assignedToUserId,  ShortagePerson? assignee, @JsonKey(name: 'created_by_user_id')  int? createdByUserId,  ShortagePerson? creator,  String? description,  List<ShortageSupply> supplies, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Shortage() when $default != null:
return $default(_that.id,_that.code,_that.source,_that.sourceLabel,_that.type,_that.typeLabel,_that.name,_that.unit,_that.unitLabel,_that.requiredQuantity,_that.suppliedQuantity,_that.remainingQuantity,_that.totalPaid,_that.status,_that.statusLabel,_that.isFinal,_that.availableTransitions,_that.isEditable,_that.isStockable,_that.stockUnit,_that.stockUnitLabel,_that.weightIsUnknown,_that.orderId,_that.orderItemId,_that.order,_that.customerId,_that.customer,_that.productId,_that.productVariantId,_that.product,_that.variant,_that.assignedToUserId,_that.assignee,_that.createdByUserId,_that.creator,_that.description,_that.supplies,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String code, @JsonKey(unknownEnumValue: ShortageSource.unknown)  ShortageSource source, @JsonKey(name: 'source_label')  String sourceLabel, @JsonKey(unknownEnumValue: ShortageType.unknown)  ShortageType type, @JsonKey(name: 'type_label')  String? typeLabel,  String name,  String? unit, @JsonKey(name: 'unit_label')  String? unitLabel, @JsonKey(name: 'required_quantity')  String requiredQuantity, @JsonKey(name: 'supplied_quantity')  String suppliedQuantity, @JsonKey(name: 'remaining_quantity')  String remainingQuantity, @JsonKey(name: 'total_paid')  String totalPaid, @JsonKey(unknownEnumValue: ShortageStatus.unknown)  ShortageStatus status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'is_final')  bool isFinal, @JsonKey(name: 'available_transitions')  List<ShortageTransition> availableTransitions, @JsonKey(name: 'is_editable')  bool isEditable, @JsonKey(name: 'is_stockable')  bool isStockable, @JsonKey(name: 'stock_unit')  String? stockUnit, @JsonKey(name: 'stock_unit_label')  String? stockUnitLabel, @JsonKey(name: 'weight_is_unknown')  bool weightIsUnknown, @JsonKey(name: 'order_id')  int? orderId, @JsonKey(name: 'order_item_id')  int? orderItemId,  ShortageOrderRef? order, @JsonKey(name: 'customer_id')  int? customerId,  ShortageCustomerRef? customer, @JsonKey(name: 'product_id')  int? productId, @JsonKey(name: 'product_variant_id')  int? productVariantId,  ShortageProductRef? product,  ShortageVariantRef? variant, @JsonKey(name: 'assigned_to_user_id')  int? assignedToUserId,  ShortagePerson? assignee, @JsonKey(name: 'created_by_user_id')  int? createdByUserId,  ShortagePerson? creator,  String? description,  List<ShortageSupply> supplies, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Shortage():
return $default(_that.id,_that.code,_that.source,_that.sourceLabel,_that.type,_that.typeLabel,_that.name,_that.unit,_that.unitLabel,_that.requiredQuantity,_that.suppliedQuantity,_that.remainingQuantity,_that.totalPaid,_that.status,_that.statusLabel,_that.isFinal,_that.availableTransitions,_that.isEditable,_that.isStockable,_that.stockUnit,_that.stockUnitLabel,_that.weightIsUnknown,_that.orderId,_that.orderItemId,_that.order,_that.customerId,_that.customer,_that.productId,_that.productVariantId,_that.product,_that.variant,_that.assignedToUserId,_that.assignee,_that.createdByUserId,_that.creator,_that.description,_that.supplies,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String code, @JsonKey(unknownEnumValue: ShortageSource.unknown)  ShortageSource source, @JsonKey(name: 'source_label')  String sourceLabel, @JsonKey(unknownEnumValue: ShortageType.unknown)  ShortageType type, @JsonKey(name: 'type_label')  String? typeLabel,  String name,  String? unit, @JsonKey(name: 'unit_label')  String? unitLabel, @JsonKey(name: 'required_quantity')  String requiredQuantity, @JsonKey(name: 'supplied_quantity')  String suppliedQuantity, @JsonKey(name: 'remaining_quantity')  String remainingQuantity, @JsonKey(name: 'total_paid')  String totalPaid, @JsonKey(unknownEnumValue: ShortageStatus.unknown)  ShortageStatus status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'is_final')  bool isFinal, @JsonKey(name: 'available_transitions')  List<ShortageTransition> availableTransitions, @JsonKey(name: 'is_editable')  bool isEditable, @JsonKey(name: 'is_stockable')  bool isStockable, @JsonKey(name: 'stock_unit')  String? stockUnit, @JsonKey(name: 'stock_unit_label')  String? stockUnitLabel, @JsonKey(name: 'weight_is_unknown')  bool weightIsUnknown, @JsonKey(name: 'order_id')  int? orderId, @JsonKey(name: 'order_item_id')  int? orderItemId,  ShortageOrderRef? order, @JsonKey(name: 'customer_id')  int? customerId,  ShortageCustomerRef? customer, @JsonKey(name: 'product_id')  int? productId, @JsonKey(name: 'product_variant_id')  int? productVariantId,  ShortageProductRef? product,  ShortageVariantRef? variant, @JsonKey(name: 'assigned_to_user_id')  int? assignedToUserId,  ShortagePerson? assignee, @JsonKey(name: 'created_by_user_id')  int? createdByUserId,  ShortagePerson? creator,  String? description,  List<ShortageSupply> supplies, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Shortage() when $default != null:
return $default(_that.id,_that.code,_that.source,_that.sourceLabel,_that.type,_that.typeLabel,_that.name,_that.unit,_that.unitLabel,_that.requiredQuantity,_that.suppliedQuantity,_that.remainingQuantity,_that.totalPaid,_that.status,_that.statusLabel,_that.isFinal,_that.availableTransitions,_that.isEditable,_that.isStockable,_that.stockUnit,_that.stockUnitLabel,_that.weightIsUnknown,_that.orderId,_that.orderItemId,_that.order,_that.customerId,_that.customer,_that.productId,_that.productVariantId,_that.product,_that.variant,_that.assignedToUserId,_that.assignee,_that.createdByUserId,_that.creator,_that.description,_that.supplies,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Shortage extends Shortage {
  const _Shortage({required this.id, required this.code, @JsonKey(unknownEnumValue: ShortageSource.unknown) required this.source, @JsonKey(name: 'source_label') required this.sourceLabel, @JsonKey(unknownEnumValue: ShortageType.unknown) this.type = ShortageType.other, @JsonKey(name: 'type_label') this.typeLabel, required this.name, this.unit, @JsonKey(name: 'unit_label') this.unitLabel, @JsonKey(name: 'required_quantity') required this.requiredQuantity, @JsonKey(name: 'supplied_quantity') required this.suppliedQuantity, @JsonKey(name: 'remaining_quantity') required this.remainingQuantity, @JsonKey(name: 'total_paid') required this.totalPaid, @JsonKey(unknownEnumValue: ShortageStatus.unknown) required this.status, @JsonKey(name: 'status_label') required this.statusLabel, @JsonKey(name: 'is_final') this.isFinal = false, @JsonKey(name: 'available_transitions') final  List<ShortageTransition> availableTransitions = const <ShortageTransition>[], @JsonKey(name: 'is_editable') this.isEditable = false, @JsonKey(name: 'is_stockable') this.isStockable = false, @JsonKey(name: 'stock_unit') this.stockUnit, @JsonKey(name: 'stock_unit_label') this.stockUnitLabel, @JsonKey(name: 'weight_is_unknown') this.weightIsUnknown = false, @JsonKey(name: 'order_id') this.orderId, @JsonKey(name: 'order_item_id') this.orderItemId, this.order, @JsonKey(name: 'customer_id') this.customerId, this.customer, @JsonKey(name: 'product_id') this.productId, @JsonKey(name: 'product_variant_id') this.productVariantId, this.product, this.variant, @JsonKey(name: 'assigned_to_user_id') this.assignedToUserId, this.assignee, @JsonKey(name: 'created_by_user_id') this.createdByUserId, this.creator, this.description, final  List<ShortageSupply> supplies = const <ShortageSupply>[], @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt}): _availableTransitions = availableTransitions,_supplies = supplies,super._();
  factory _Shortage.fromJson(Map<String, dynamic> json) => _$ShortageFromJson(json);

@override final  int id;
@override final  String code;
@override@JsonKey(unknownEnumValue: ShortageSource.unknown) final  ShortageSource source;
@override@JsonKey(name: 'source_label') final  String sourceLabel;
/// What kind of thing is short — see [ShortageType]. Defaulted rather than required so a
/// payload from a server too old to send it renders as «أخرى» instead of failing to parse.
@override@JsonKey(unknownEnumValue: ShortageType.unknown) final  ShortageType type;
@override@JsonKey(name: 'type_label') final  String? typeLabel;
/// «كيس شحن — 25*35», or whatever somebody typed on a manual one.
@override final  String name;
/// The unit the quantities are counted in, and the server's own word for it. The label is
/// what every screen prints; nothing branches on the value.
@override final  String? unit;
@override@JsonKey(name: 'unit_label') final  String? unitLabel;
@override@JsonKey(name: 'required_quantity') final  String requiredQuantity;
@override@JsonKey(name: 'supplied_quantity') final  String suppliedQuantity;
@override@JsonKey(name: 'remaining_quantity') final  String remainingQuantity;
@override@JsonKey(name: 'total_paid') final  String totalPaid;
@override@JsonKey(unknownEnumValue: ShortageStatus.unknown) final  ShortageStatus status;
@override@JsonKey(name: 'status_label') final  String statusLabel;
@override@JsonKey(name: 'is_final') final  bool isFinal;
/// Exactly the buttons to draw, and no others — see [ShortageTransition].
 final  List<ShortageTransition> _availableTransitions;
/// Exactly the buttons to draw, and no others — see [ShortageTransition].
@override@JsonKey(name: 'available_transitions') List<ShortageTransition> get availableTransitions {
  if (_availableTransitions is EqualUnmodifiableListView) return _availableTransitions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_availableTransitions);
}

/// Whether the form may be opened on it. **False on a shortage born of an order**, whose
/// quantity is corrected from the order screen — the server says so rather than the app
/// deriving it from [source], because the rule is the server's.
@override@JsonKey(name: 'is_editable') final  bool isEditable;
/// Whether the goods have a shelf to land on.
///
/// **Read, never inferred.** Deriving it from `product_variant_id` would put a warehouse
/// picker in front of a roll of tape — and sending a warehouse for one is a 422 in its own
/// right, because the caller would be telling the server goods are moving when they are not.
@override@JsonKey(name: 'is_stockable') final  bool isStockable;
/// What this row will be counted in once somebody states the weight.
///
/// The same as [unitLabel] on every ordinary shortage. It differs only while an order-born
/// row is still waiting: the bags are missing, so the row is counted in the unit it was sold
/// in and this is what it will convert to — which is what labels the box that asks.
@override@JsonKey(name: 'stock_unit') final  String? stockUnit;
@override@JsonKey(name: 'stock_unit_label') final  String? stockUnitLabel;
/// Whether this shortage is still waiting for somebody to say how much is owed.
///
/// **Read, never inferred.** It depends on the stock item behind the size, two relations past
/// the order line, and no payload the app holds can see it. While true, every supply is
/// refused — so this is also why the record button will turn somebody away.
@override@JsonKey(name: 'weight_is_unknown') final  bool weightIsUnknown;
@override@JsonKey(name: 'order_id') final  int? orderId;
@override@JsonKey(name: 'order_item_id') final  int? orderItemId;
@override final  ShortageOrderRef? order;
@override@JsonKey(name: 'customer_id') final  int? customerId;
@override final  ShortageCustomerRef? customer;
@override@JsonKey(name: 'product_id') final  int? productId;
@override@JsonKey(name: 'product_variant_id') final  int? productVariantId;
@override final  ShortageProductRef? product;
@override final  ShortageVariantRef? variant;
@override@JsonKey(name: 'assigned_to_user_id') final  int? assignedToUserId;
@override final  ShortagePerson? assignee;
@override@JsonKey(name: 'created_by_user_id') final  int? createdByUserId;
@override final  ShortagePerson? creator;
@override final  String? description;
/// The ledger — **detail payload only**, so an empty list on a card means «not asked for»
/// rather than «nothing happened».
 final  List<ShortageSupply> _supplies;
/// The ledger — **detail payload only**, so an empty list on a card means «not asked for»
/// rather than «nothing happened».
@override@JsonKey() List<ShortageSupply> get supplies {
  if (_supplies is EqualUnmodifiableListView) return _supplies;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_supplies);
}

@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;

/// Create a copy of Shortage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShortageCopyWith<_Shortage> get copyWith => __$ShortageCopyWithImpl<_Shortage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShortageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Shortage&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.source, source) || other.source == source)&&(identical(other.sourceLabel, sourceLabel) || other.sourceLabel == sourceLabel)&&(identical(other.type, type) || other.type == type)&&(identical(other.typeLabel, typeLabel) || other.typeLabel == typeLabel)&&(identical(other.name, name) || other.name == name)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.unitLabel, unitLabel) || other.unitLabel == unitLabel)&&(identical(other.requiredQuantity, requiredQuantity) || other.requiredQuantity == requiredQuantity)&&(identical(other.suppliedQuantity, suppliedQuantity) || other.suppliedQuantity == suppliedQuantity)&&(identical(other.remainingQuantity, remainingQuantity) || other.remainingQuantity == remainingQuantity)&&(identical(other.totalPaid, totalPaid) || other.totalPaid == totalPaid)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.isFinal, isFinal) || other.isFinal == isFinal)&&const DeepCollectionEquality().equals(other._availableTransitions, _availableTransitions)&&(identical(other.isEditable, isEditable) || other.isEditable == isEditable)&&(identical(other.isStockable, isStockable) || other.isStockable == isStockable)&&(identical(other.stockUnit, stockUnit) || other.stockUnit == stockUnit)&&(identical(other.stockUnitLabel, stockUnitLabel) || other.stockUnitLabel == stockUnitLabel)&&(identical(other.weightIsUnknown, weightIsUnknown) || other.weightIsUnknown == weightIsUnknown)&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.orderItemId, orderItemId) || other.orderItemId == orderItemId)&&(identical(other.order, order) || other.order == order)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.customer, customer) || other.customer == customer)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.productVariantId, productVariantId) || other.productVariantId == productVariantId)&&(identical(other.product, product) || other.product == product)&&(identical(other.variant, variant) || other.variant == variant)&&(identical(other.assignedToUserId, assignedToUserId) || other.assignedToUserId == assignedToUserId)&&(identical(other.assignee, assignee) || other.assignee == assignee)&&(identical(other.createdByUserId, createdByUserId) || other.createdByUserId == createdByUserId)&&(identical(other.creator, creator) || other.creator == creator)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._supplies, _supplies)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,code,source,sourceLabel,type,typeLabel,name,unit,unitLabel,requiredQuantity,suppliedQuantity,remainingQuantity,totalPaid,status,statusLabel,isFinal,const DeepCollectionEquality().hash(_availableTransitions),isEditable,isStockable,stockUnit,stockUnitLabel,weightIsUnknown,orderId,orderItemId,order,customerId,customer,productId,productVariantId,product,variant,assignedToUserId,assignee,createdByUserId,creator,description,const DeepCollectionEquality().hash(_supplies),createdAt,updatedAt]);

@override
String toString() {
  return 'Shortage(id: $id, code: $code, source: $source, sourceLabel: $sourceLabel, type: $type, typeLabel: $typeLabel, name: $name, unit: $unit, unitLabel: $unitLabel, requiredQuantity: $requiredQuantity, suppliedQuantity: $suppliedQuantity, remainingQuantity: $remainingQuantity, totalPaid: $totalPaid, status: $status, statusLabel: $statusLabel, isFinal: $isFinal, availableTransitions: $availableTransitions, isEditable: $isEditable, isStockable: $isStockable, stockUnit: $stockUnit, stockUnitLabel: $stockUnitLabel, weightIsUnknown: $weightIsUnknown, orderId: $orderId, orderItemId: $orderItemId, order: $order, customerId: $customerId, customer: $customer, productId: $productId, productVariantId: $productVariantId, product: $product, variant: $variant, assignedToUserId: $assignedToUserId, assignee: $assignee, createdByUserId: $createdByUserId, creator: $creator, description: $description, supplies: $supplies, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ShortageCopyWith<$Res> implements $ShortageCopyWith<$Res> {
  factory _$ShortageCopyWith(_Shortage value, $Res Function(_Shortage) _then) = __$ShortageCopyWithImpl;
@override @useResult
$Res call({
 int id, String code,@JsonKey(unknownEnumValue: ShortageSource.unknown) ShortageSource source,@JsonKey(name: 'source_label') String sourceLabel,@JsonKey(unknownEnumValue: ShortageType.unknown) ShortageType type,@JsonKey(name: 'type_label') String? typeLabel, String name, String? unit,@JsonKey(name: 'unit_label') String? unitLabel,@JsonKey(name: 'required_quantity') String requiredQuantity,@JsonKey(name: 'supplied_quantity') String suppliedQuantity,@JsonKey(name: 'remaining_quantity') String remainingQuantity,@JsonKey(name: 'total_paid') String totalPaid,@JsonKey(unknownEnumValue: ShortageStatus.unknown) ShortageStatus status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'is_final') bool isFinal,@JsonKey(name: 'available_transitions') List<ShortageTransition> availableTransitions,@JsonKey(name: 'is_editable') bool isEditable,@JsonKey(name: 'is_stockable') bool isStockable,@JsonKey(name: 'stock_unit') String? stockUnit,@JsonKey(name: 'stock_unit_label') String? stockUnitLabel,@JsonKey(name: 'weight_is_unknown') bool weightIsUnknown,@JsonKey(name: 'order_id') int? orderId,@JsonKey(name: 'order_item_id') int? orderItemId, ShortageOrderRef? order,@JsonKey(name: 'customer_id') int? customerId, ShortageCustomerRef? customer,@JsonKey(name: 'product_id') int? productId,@JsonKey(name: 'product_variant_id') int? productVariantId, ShortageProductRef? product, ShortageVariantRef? variant,@JsonKey(name: 'assigned_to_user_id') int? assignedToUserId, ShortagePerson? assignee,@JsonKey(name: 'created_by_user_id') int? createdByUserId, ShortagePerson? creator, String? description, List<ShortageSupply> supplies,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});


@override $ShortageOrderRefCopyWith<$Res>? get order;@override $ShortageCustomerRefCopyWith<$Res>? get customer;@override $ShortageProductRefCopyWith<$Res>? get product;@override $ShortageVariantRefCopyWith<$Res>? get variant;@override $ShortagePersonCopyWith<$Res>? get assignee;@override $ShortagePersonCopyWith<$Res>? get creator;

}
/// @nodoc
class __$ShortageCopyWithImpl<$Res>
    implements _$ShortageCopyWith<$Res> {
  __$ShortageCopyWithImpl(this._self, this._then);

  final _Shortage _self;
  final $Res Function(_Shortage) _then;

/// Create a copy of Shortage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? source = null,Object? sourceLabel = null,Object? type = null,Object? typeLabel = freezed,Object? name = null,Object? unit = freezed,Object? unitLabel = freezed,Object? requiredQuantity = null,Object? suppliedQuantity = null,Object? remainingQuantity = null,Object? totalPaid = null,Object? status = null,Object? statusLabel = null,Object? isFinal = null,Object? availableTransitions = null,Object? isEditable = null,Object? isStockable = null,Object? stockUnit = freezed,Object? stockUnitLabel = freezed,Object? weightIsUnknown = null,Object? orderId = freezed,Object? orderItemId = freezed,Object? order = freezed,Object? customerId = freezed,Object? customer = freezed,Object? productId = freezed,Object? productVariantId = freezed,Object? product = freezed,Object? variant = freezed,Object? assignedToUserId = freezed,Object? assignee = freezed,Object? createdByUserId = freezed,Object? creator = freezed,Object? description = freezed,Object? supplies = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Shortage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as ShortageSource,sourceLabel: null == sourceLabel ? _self.sourceLabel : sourceLabel // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as ShortageType,typeLabel: freezed == typeLabel ? _self.typeLabel : typeLabel // ignore: cast_nullable_to_non_nullable
as String?,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,unit: freezed == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as String?,unitLabel: freezed == unitLabel ? _self.unitLabel : unitLabel // ignore: cast_nullable_to_non_nullable
as String?,requiredQuantity: null == requiredQuantity ? _self.requiredQuantity : requiredQuantity // ignore: cast_nullable_to_non_nullable
as String,suppliedQuantity: null == suppliedQuantity ? _self.suppliedQuantity : suppliedQuantity // ignore: cast_nullable_to_non_nullable
as String,remainingQuantity: null == remainingQuantity ? _self.remainingQuantity : remainingQuantity // ignore: cast_nullable_to_non_nullable
as String,totalPaid: null == totalPaid ? _self.totalPaid : totalPaid // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ShortageStatus,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,isFinal: null == isFinal ? _self.isFinal : isFinal // ignore: cast_nullable_to_non_nullable
as bool,availableTransitions: null == availableTransitions ? _self._availableTransitions : availableTransitions // ignore: cast_nullable_to_non_nullable
as List<ShortageTransition>,isEditable: null == isEditable ? _self.isEditable : isEditable // ignore: cast_nullable_to_non_nullable
as bool,isStockable: null == isStockable ? _self.isStockable : isStockable // ignore: cast_nullable_to_non_nullable
as bool,stockUnit: freezed == stockUnit ? _self.stockUnit : stockUnit // ignore: cast_nullable_to_non_nullable
as String?,stockUnitLabel: freezed == stockUnitLabel ? _self.stockUnitLabel : stockUnitLabel // ignore: cast_nullable_to_non_nullable
as String?,weightIsUnknown: null == weightIsUnknown ? _self.weightIsUnknown : weightIsUnknown // ignore: cast_nullable_to_non_nullable
as bool,orderId: freezed == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as int?,orderItemId: freezed == orderItemId ? _self.orderItemId : orderItemId // ignore: cast_nullable_to_non_nullable
as int?,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as ShortageOrderRef?,customerId: freezed == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as int?,customer: freezed == customer ? _self.customer : customer // ignore: cast_nullable_to_non_nullable
as ShortageCustomerRef?,productId: freezed == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as int?,productVariantId: freezed == productVariantId ? _self.productVariantId : productVariantId // ignore: cast_nullable_to_non_nullable
as int?,product: freezed == product ? _self.product : product // ignore: cast_nullable_to_non_nullable
as ShortageProductRef?,variant: freezed == variant ? _self.variant : variant // ignore: cast_nullable_to_non_nullable
as ShortageVariantRef?,assignedToUserId: freezed == assignedToUserId ? _self.assignedToUserId : assignedToUserId // ignore: cast_nullable_to_non_nullable
as int?,assignee: freezed == assignee ? _self.assignee : assignee // ignore: cast_nullable_to_non_nullable
as ShortagePerson?,createdByUserId: freezed == createdByUserId ? _self.createdByUserId : createdByUserId // ignore: cast_nullable_to_non_nullable
as int?,creator: freezed == creator ? _self.creator : creator // ignore: cast_nullable_to_non_nullable
as ShortagePerson?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,supplies: null == supplies ? _self._supplies : supplies // ignore: cast_nullable_to_non_nullable
as List<ShortageSupply>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of Shortage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShortageOrderRefCopyWith<$Res>? get order {
    if (_self.order == null) {
    return null;
  }

  return $ShortageOrderRefCopyWith<$Res>(_self.order!, (value) {
    return _then(_self.copyWith(order: value));
  });
}/// Create a copy of Shortage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShortageCustomerRefCopyWith<$Res>? get customer {
    if (_self.customer == null) {
    return null;
  }

  return $ShortageCustomerRefCopyWith<$Res>(_self.customer!, (value) {
    return _then(_self.copyWith(customer: value));
  });
}/// Create a copy of Shortage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShortageProductRefCopyWith<$Res>? get product {
    if (_self.product == null) {
    return null;
  }

  return $ShortageProductRefCopyWith<$Res>(_self.product!, (value) {
    return _then(_self.copyWith(product: value));
  });
}/// Create a copy of Shortage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShortageVariantRefCopyWith<$Res>? get variant {
    if (_self.variant == null) {
    return null;
  }

  return $ShortageVariantRefCopyWith<$Res>(_self.variant!, (value) {
    return _then(_self.copyWith(variant: value));
  });
}/// Create a copy of Shortage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShortagePersonCopyWith<$Res>? get assignee {
    if (_self.assignee == null) {
    return null;
  }

  return $ShortagePersonCopyWith<$Res>(_self.assignee!, (value) {
    return _then(_self.copyWith(assignee: value));
  });
}/// Create a copy of Shortage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShortagePersonCopyWith<$Res>? get creator {
    if (_self.creator == null) {
    return null;
  }

  return $ShortagePersonCopyWith<$Res>(_self.creator!, (value) {
    return _then(_self.copyWith(creator: value));
  });
}
}

// dart format on
