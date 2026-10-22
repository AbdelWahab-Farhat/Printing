// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'internal_ticket.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InternalPerson {

 int get id; String get name;
/// Create a copy of InternalPerson
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InternalPersonCopyWith<InternalPerson> get copyWith => _$InternalPersonCopyWithImpl<InternalPerson>(this as InternalPerson, _$identity);

  /// Serializes this InternalPerson to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InternalPerson&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'InternalPerson(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $InternalPersonCopyWith<$Res>  {
  factory $InternalPersonCopyWith(InternalPerson value, $Res Function(InternalPerson) _then) = _$InternalPersonCopyWithImpl;
@useResult
$Res call({
 int id, String name
});




}
/// @nodoc
class _$InternalPersonCopyWithImpl<$Res>
    implements $InternalPersonCopyWith<$Res> {
  _$InternalPersonCopyWithImpl(this._self, this._then);

  final InternalPerson _self;
  final $Res Function(InternalPerson) _then;

/// Create a copy of InternalPerson
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [InternalPerson].
extension InternalPersonPatterns on InternalPerson {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InternalPerson value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InternalPerson() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InternalPerson value)  $default,){
final _that = this;
switch (_that) {
case _InternalPerson():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InternalPerson value)?  $default,){
final _that = this;
switch (_that) {
case _InternalPerson() when $default != null:
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
case _InternalPerson() when $default != null:
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
case _InternalPerson():
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
case _InternalPerson() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InternalPerson implements InternalPerson {
  const _InternalPerson({required this.id, required this.name});
  factory _InternalPerson.fromJson(Map<String, dynamic> json) => _$InternalPersonFromJson(json);

@override final  int id;
@override final  String name;

/// Create a copy of InternalPerson
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InternalPersonCopyWith<_InternalPerson> get copyWith => __$InternalPersonCopyWithImpl<_InternalPerson>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InternalPersonToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InternalPerson&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'InternalPerson(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$InternalPersonCopyWith<$Res> implements $InternalPersonCopyWith<$Res> {
  factory _$InternalPersonCopyWith(_InternalPerson value, $Res Function(_InternalPerson) _then) = __$InternalPersonCopyWithImpl;
@override @useResult
$Res call({
 int id, String name
});




}
/// @nodoc
class __$InternalPersonCopyWithImpl<$Res>
    implements _$InternalPersonCopyWith<$Res> {
  __$InternalPersonCopyWithImpl(this._self, this._then);

  final _InternalPerson _self;
  final $Res Function(_InternalPerson) _then;

/// Create a copy of InternalPerson
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_InternalPerson(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$InternalCustomerRef {

 int get id; String? get code; String? get name; String? get phone;
/// Create a copy of InternalCustomerRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InternalCustomerRefCopyWith<InternalCustomerRef> get copyWith => _$InternalCustomerRefCopyWithImpl<InternalCustomerRef>(this as InternalCustomerRef, _$identity);

  /// Serializes this InternalCustomerRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InternalCustomerRef&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name,phone);

@override
String toString() {
  return 'InternalCustomerRef(id: $id, code: $code, name: $name, phone: $phone)';
}


}

/// @nodoc
abstract mixin class $InternalCustomerRefCopyWith<$Res>  {
  factory $InternalCustomerRefCopyWith(InternalCustomerRef value, $Res Function(InternalCustomerRef) _then) = _$InternalCustomerRefCopyWithImpl;
@useResult
$Res call({
 int id, String? code, String? name, String? phone
});




}
/// @nodoc
class _$InternalCustomerRefCopyWithImpl<$Res>
    implements $InternalCustomerRefCopyWith<$Res> {
  _$InternalCustomerRefCopyWithImpl(this._self, this._then);

  final InternalCustomerRef _self;
  final $Res Function(InternalCustomerRef) _then;

/// Create a copy of InternalCustomerRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = freezed,Object? name = freezed,Object? phone = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [InternalCustomerRef].
extension InternalCustomerRefPatterns on InternalCustomerRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InternalCustomerRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InternalCustomerRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InternalCustomerRef value)  $default,){
final _that = this;
switch (_that) {
case _InternalCustomerRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InternalCustomerRef value)?  $default,){
final _that = this;
switch (_that) {
case _InternalCustomerRef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String? code,  String? name,  String? phone)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InternalCustomerRef() when $default != null:
return $default(_that.id,_that.code,_that.name,_that.phone);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String? code,  String? name,  String? phone)  $default,) {final _that = this;
switch (_that) {
case _InternalCustomerRef():
return $default(_that.id,_that.code,_that.name,_that.phone);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String? code,  String? name,  String? phone)?  $default,) {final _that = this;
switch (_that) {
case _InternalCustomerRef() when $default != null:
return $default(_that.id,_that.code,_that.name,_that.phone);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InternalCustomerRef implements InternalCustomerRef {
  const _InternalCustomerRef({required this.id, this.code, this.name, this.phone});
  factory _InternalCustomerRef.fromJson(Map<String, dynamic> json) => _$InternalCustomerRefFromJson(json);

@override final  int id;
@override final  String? code;
@override final  String? name;
@override final  String? phone;

/// Create a copy of InternalCustomerRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InternalCustomerRefCopyWith<_InternalCustomerRef> get copyWith => __$InternalCustomerRefCopyWithImpl<_InternalCustomerRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InternalCustomerRefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InternalCustomerRef&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name,phone);

@override
String toString() {
  return 'InternalCustomerRef(id: $id, code: $code, name: $name, phone: $phone)';
}


}

/// @nodoc
abstract mixin class _$InternalCustomerRefCopyWith<$Res> implements $InternalCustomerRefCopyWith<$Res> {
  factory _$InternalCustomerRefCopyWith(_InternalCustomerRef value, $Res Function(_InternalCustomerRef) _then) = __$InternalCustomerRefCopyWithImpl;
@override @useResult
$Res call({
 int id, String? code, String? name, String? phone
});




}
/// @nodoc
class __$InternalCustomerRefCopyWithImpl<$Res>
    implements _$InternalCustomerRefCopyWith<$Res> {
  __$InternalCustomerRefCopyWithImpl(this._self, this._then);

  final _InternalCustomerRef _self;
  final $Res Function(_InternalCustomerRef) _then;

/// Create a copy of InternalCustomerRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = freezed,Object? name = freezed,Object? phone = freezed,}) {
  return _then(_InternalCustomerRef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$InternalOrderRef {

 int get id; String get code;
/// Create a copy of InternalOrderRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InternalOrderRefCopyWith<InternalOrderRef> get copyWith => _$InternalOrderRefCopyWithImpl<InternalOrderRef>(this as InternalOrderRef, _$identity);

  /// Serializes this InternalOrderRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InternalOrderRef&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code);

@override
String toString() {
  return 'InternalOrderRef(id: $id, code: $code)';
}


}

/// @nodoc
abstract mixin class $InternalOrderRefCopyWith<$Res>  {
  factory $InternalOrderRefCopyWith(InternalOrderRef value, $Res Function(InternalOrderRef) _then) = _$InternalOrderRefCopyWithImpl;
@useResult
$Res call({
 int id, String code
});




}
/// @nodoc
class _$InternalOrderRefCopyWithImpl<$Res>
    implements $InternalOrderRefCopyWith<$Res> {
  _$InternalOrderRefCopyWithImpl(this._self, this._then);

  final InternalOrderRef _self;
  final $Res Function(InternalOrderRef) _then;

/// Create a copy of InternalOrderRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [InternalOrderRef].
extension InternalOrderRefPatterns on InternalOrderRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InternalOrderRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InternalOrderRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InternalOrderRef value)  $default,){
final _that = this;
switch (_that) {
case _InternalOrderRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InternalOrderRef value)?  $default,){
final _that = this;
switch (_that) {
case _InternalOrderRef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String code)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InternalOrderRef() when $default != null:
return $default(_that.id,_that.code);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String code)  $default,) {final _that = this;
switch (_that) {
case _InternalOrderRef():
return $default(_that.id,_that.code);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String code)?  $default,) {final _that = this;
switch (_that) {
case _InternalOrderRef() when $default != null:
return $default(_that.id,_that.code);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InternalOrderRef implements InternalOrderRef {
  const _InternalOrderRef({required this.id, required this.code});
  factory _InternalOrderRef.fromJson(Map<String, dynamic> json) => _$InternalOrderRefFromJson(json);

@override final  int id;
@override final  String code;

/// Create a copy of InternalOrderRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InternalOrderRefCopyWith<_InternalOrderRef> get copyWith => __$InternalOrderRefCopyWithImpl<_InternalOrderRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InternalOrderRefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InternalOrderRef&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code);

@override
String toString() {
  return 'InternalOrderRef(id: $id, code: $code)';
}


}

/// @nodoc
abstract mixin class _$InternalOrderRefCopyWith<$Res> implements $InternalOrderRefCopyWith<$Res> {
  factory _$InternalOrderRefCopyWith(_InternalOrderRef value, $Res Function(_InternalOrderRef) _then) = __$InternalOrderRefCopyWithImpl;
@override @useResult
$Res call({
 int id, String code
});




}
/// @nodoc
class __$InternalOrderRefCopyWithImpl<$Res>
    implements _$InternalOrderRefCopyWith<$Res> {
  __$InternalOrderRefCopyWithImpl(this._self, this._then);

  final _InternalOrderRef _self;
  final $Res Function(_InternalOrderRef) _then;

/// Create a copy of InternalOrderRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,}) {
  return _then(_InternalOrderRef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$InternalCategory {

 int get id; String get name;
/// Create a copy of InternalCategory
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InternalCategoryCopyWith<InternalCategory> get copyWith => _$InternalCategoryCopyWithImpl<InternalCategory>(this as InternalCategory, _$identity);

  /// Serializes this InternalCategory to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InternalCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'InternalCategory(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $InternalCategoryCopyWith<$Res>  {
  factory $InternalCategoryCopyWith(InternalCategory value, $Res Function(InternalCategory) _then) = _$InternalCategoryCopyWithImpl;
@useResult
$Res call({
 int id, String name
});




}
/// @nodoc
class _$InternalCategoryCopyWithImpl<$Res>
    implements $InternalCategoryCopyWith<$Res> {
  _$InternalCategoryCopyWithImpl(this._self, this._then);

  final InternalCategory _self;
  final $Res Function(InternalCategory) _then;

/// Create a copy of InternalCategory
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [InternalCategory].
extension InternalCategoryPatterns on InternalCategory {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InternalCategory value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InternalCategory() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InternalCategory value)  $default,){
final _that = this;
switch (_that) {
case _InternalCategory():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InternalCategory value)?  $default,){
final _that = this;
switch (_that) {
case _InternalCategory() when $default != null:
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
case _InternalCategory() when $default != null:
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
case _InternalCategory():
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
case _InternalCategory() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InternalCategory implements InternalCategory {
  const _InternalCategory({required this.id, required this.name});
  factory _InternalCategory.fromJson(Map<String, dynamic> json) => _$InternalCategoryFromJson(json);

@override final  int id;
@override final  String name;

/// Create a copy of InternalCategory
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InternalCategoryCopyWith<_InternalCategory> get copyWith => __$InternalCategoryCopyWithImpl<_InternalCategory>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InternalCategoryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InternalCategory&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'InternalCategory(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$InternalCategoryCopyWith<$Res> implements $InternalCategoryCopyWith<$Res> {
  factory _$InternalCategoryCopyWith(_InternalCategory value, $Res Function(_InternalCategory) _then) = __$InternalCategoryCopyWithImpl;
@override @useResult
$Res call({
 int id, String name
});




}
/// @nodoc
class __$InternalCategoryCopyWithImpl<$Res>
    implements _$InternalCategoryCopyWith<$Res> {
  __$InternalCategoryCopyWithImpl(this._self, this._then);

  final _InternalCategory _self;
  final $Res Function(_InternalCategory) _then;

/// Create a copy of InternalCategory
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_InternalCategory(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$InternalAttachment {

 int get id;@JsonKey(unknownEnumValue: InternalAttachmentKind.unknown) InternalAttachmentKind get kind; String? get name;@JsonKey(name: 'mime_type') String? get mimeType;@JsonKey(name: 'size_bytes') int? get sizeBytes;@JsonKey(name: 'width_px') int? get widthPx;@JsonKey(name: 'height_px') int? get heightPx;/// للصوت: كما قاسها الهاتف المرسِل، للعرض.
@JsonKey(name: 'duration_seconds') int? get durationSeconds;/// للصوت: ٤٨ رقماً من ٠ إلى ١٠٠، يحفظها الخادم فيرى المستقبِل موجةً حقيقية.
 List<int>? get waveform; String? get url;
/// Create a copy of InternalAttachment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InternalAttachmentCopyWith<InternalAttachment> get copyWith => _$InternalAttachmentCopyWithImpl<InternalAttachment>(this as InternalAttachment, _$identity);

  /// Serializes this InternalAttachment to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InternalAttachment&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.name, name) || other.name == name)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.widthPx, widthPx) || other.widthPx == widthPx)&&(identical(other.heightPx, heightPx) || other.heightPx == heightPx)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&const DeepCollectionEquality().equals(other.waveform, waveform)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,name,mimeType,sizeBytes,widthPx,heightPx,durationSeconds,const DeepCollectionEquality().hash(waveform),url);

@override
String toString() {
  return 'InternalAttachment(id: $id, kind: $kind, name: $name, mimeType: $mimeType, sizeBytes: $sizeBytes, widthPx: $widthPx, heightPx: $heightPx, durationSeconds: $durationSeconds, waveform: $waveform, url: $url)';
}


}

/// @nodoc
abstract mixin class $InternalAttachmentCopyWith<$Res>  {
  factory $InternalAttachmentCopyWith(InternalAttachment value, $Res Function(InternalAttachment) _then) = _$InternalAttachmentCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(unknownEnumValue: InternalAttachmentKind.unknown) InternalAttachmentKind kind, String? name,@JsonKey(name: 'mime_type') String? mimeType,@JsonKey(name: 'size_bytes') int? sizeBytes,@JsonKey(name: 'width_px') int? widthPx,@JsonKey(name: 'height_px') int? heightPx,@JsonKey(name: 'duration_seconds') int? durationSeconds, List<int>? waveform, String? url
});




}
/// @nodoc
class _$InternalAttachmentCopyWithImpl<$Res>
    implements $InternalAttachmentCopyWith<$Res> {
  _$InternalAttachmentCopyWithImpl(this._self, this._then);

  final InternalAttachment _self;
  final $Res Function(InternalAttachment) _then;

/// Create a copy of InternalAttachment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? name = freezed,Object? mimeType = freezed,Object? sizeBytes = freezed,Object? widthPx = freezed,Object? heightPx = freezed,Object? durationSeconds = freezed,Object? waveform = freezed,Object? url = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as InternalAttachmentKind,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,widthPx: freezed == widthPx ? _self.widthPx : widthPx // ignore: cast_nullable_to_non_nullable
as int?,heightPx: freezed == heightPx ? _self.heightPx : heightPx // ignore: cast_nullable_to_non_nullable
as int?,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,waveform: freezed == waveform ? _self.waveform : waveform // ignore: cast_nullable_to_non_nullable
as List<int>?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [InternalAttachment].
extension InternalAttachmentPatterns on InternalAttachment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InternalAttachment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InternalAttachment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InternalAttachment value)  $default,){
final _that = this;
switch (_that) {
case _InternalAttachment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InternalAttachment value)?  $default,){
final _that = this;
switch (_that) {
case _InternalAttachment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(unknownEnumValue: InternalAttachmentKind.unknown)  InternalAttachmentKind kind,  String? name, @JsonKey(name: 'mime_type')  String? mimeType, @JsonKey(name: 'size_bytes')  int? sizeBytes, @JsonKey(name: 'width_px')  int? widthPx, @JsonKey(name: 'height_px')  int? heightPx, @JsonKey(name: 'duration_seconds')  int? durationSeconds,  List<int>? waveform,  String? url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InternalAttachment() when $default != null:
return $default(_that.id,_that.kind,_that.name,_that.mimeType,_that.sizeBytes,_that.widthPx,_that.heightPx,_that.durationSeconds,_that.waveform,_that.url);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(unknownEnumValue: InternalAttachmentKind.unknown)  InternalAttachmentKind kind,  String? name, @JsonKey(name: 'mime_type')  String? mimeType, @JsonKey(name: 'size_bytes')  int? sizeBytes, @JsonKey(name: 'width_px')  int? widthPx, @JsonKey(name: 'height_px')  int? heightPx, @JsonKey(name: 'duration_seconds')  int? durationSeconds,  List<int>? waveform,  String? url)  $default,) {final _that = this;
switch (_that) {
case _InternalAttachment():
return $default(_that.id,_that.kind,_that.name,_that.mimeType,_that.sizeBytes,_that.widthPx,_that.heightPx,_that.durationSeconds,_that.waveform,_that.url);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(unknownEnumValue: InternalAttachmentKind.unknown)  InternalAttachmentKind kind,  String? name, @JsonKey(name: 'mime_type')  String? mimeType, @JsonKey(name: 'size_bytes')  int? sizeBytes, @JsonKey(name: 'width_px')  int? widthPx, @JsonKey(name: 'height_px')  int? heightPx, @JsonKey(name: 'duration_seconds')  int? durationSeconds,  List<int>? waveform,  String? url)?  $default,) {final _that = this;
switch (_that) {
case _InternalAttachment() when $default != null:
return $default(_that.id,_that.kind,_that.name,_that.mimeType,_that.sizeBytes,_that.widthPx,_that.heightPx,_that.durationSeconds,_that.waveform,_that.url);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InternalAttachment implements InternalAttachment {
  const _InternalAttachment({required this.id, @JsonKey(unknownEnumValue: InternalAttachmentKind.unknown) this.kind = InternalAttachmentKind.unknown, this.name, @JsonKey(name: 'mime_type') this.mimeType, @JsonKey(name: 'size_bytes') this.sizeBytes, @JsonKey(name: 'width_px') this.widthPx, @JsonKey(name: 'height_px') this.heightPx, @JsonKey(name: 'duration_seconds') this.durationSeconds, final  List<int>? waveform, this.url}): _waveform = waveform;
  factory _InternalAttachment.fromJson(Map<String, dynamic> json) => _$InternalAttachmentFromJson(json);

@override final  int id;
@override@JsonKey(unknownEnumValue: InternalAttachmentKind.unknown) final  InternalAttachmentKind kind;
@override final  String? name;
@override@JsonKey(name: 'mime_type') final  String? mimeType;
@override@JsonKey(name: 'size_bytes') final  int? sizeBytes;
@override@JsonKey(name: 'width_px') final  int? widthPx;
@override@JsonKey(name: 'height_px') final  int? heightPx;
/// للصوت: كما قاسها الهاتف المرسِل، للعرض.
@override@JsonKey(name: 'duration_seconds') final  int? durationSeconds;
/// للصوت: ٤٨ رقماً من ٠ إلى ١٠٠، يحفظها الخادم فيرى المستقبِل موجةً حقيقية.
 final  List<int>? _waveform;
/// للصوت: ٤٨ رقماً من ٠ إلى ١٠٠، يحفظها الخادم فيرى المستقبِل موجةً حقيقية.
@override List<int>? get waveform {
  final value = _waveform;
  if (value == null) return null;
  if (_waveform is EqualUnmodifiableListView) return _waveform;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  String? url;

/// Create a copy of InternalAttachment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InternalAttachmentCopyWith<_InternalAttachment> get copyWith => __$InternalAttachmentCopyWithImpl<_InternalAttachment>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InternalAttachmentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InternalAttachment&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.name, name) || other.name == name)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.widthPx, widthPx) || other.widthPx == widthPx)&&(identical(other.heightPx, heightPx) || other.heightPx == heightPx)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&const DeepCollectionEquality().equals(other._waveform, _waveform)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,kind,name,mimeType,sizeBytes,widthPx,heightPx,durationSeconds,const DeepCollectionEquality().hash(_waveform),url);

@override
String toString() {
  return 'InternalAttachment(id: $id, kind: $kind, name: $name, mimeType: $mimeType, sizeBytes: $sizeBytes, widthPx: $widthPx, heightPx: $heightPx, durationSeconds: $durationSeconds, waveform: $waveform, url: $url)';
}


}

/// @nodoc
abstract mixin class _$InternalAttachmentCopyWith<$Res> implements $InternalAttachmentCopyWith<$Res> {
  factory _$InternalAttachmentCopyWith(_InternalAttachment value, $Res Function(_InternalAttachment) _then) = __$InternalAttachmentCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(unknownEnumValue: InternalAttachmentKind.unknown) InternalAttachmentKind kind, String? name,@JsonKey(name: 'mime_type') String? mimeType,@JsonKey(name: 'size_bytes') int? sizeBytes,@JsonKey(name: 'width_px') int? widthPx,@JsonKey(name: 'height_px') int? heightPx,@JsonKey(name: 'duration_seconds') int? durationSeconds, List<int>? waveform, String? url
});




}
/// @nodoc
class __$InternalAttachmentCopyWithImpl<$Res>
    implements _$InternalAttachmentCopyWith<$Res> {
  __$InternalAttachmentCopyWithImpl(this._self, this._then);

  final _InternalAttachment _self;
  final $Res Function(_InternalAttachment) _then;

/// Create a copy of InternalAttachment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? name = freezed,Object? mimeType = freezed,Object? sizeBytes = freezed,Object? widthPx = freezed,Object? heightPx = freezed,Object? durationSeconds = freezed,Object? waveform = freezed,Object? url = freezed,}) {
  return _then(_InternalAttachment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as InternalAttachmentKind,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,mimeType: freezed == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String?,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,widthPx: freezed == widthPx ? _self.widthPx : widthPx // ignore: cast_nullable_to_non_nullable
as int?,heightPx: freezed == heightPx ? _self.heightPx : heightPx // ignore: cast_nullable_to_non_nullable
as int?,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,waveform: freezed == waveform ? _self._waveform : waveform // ignore: cast_nullable_to_non_nullable
as List<int>?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$InternalQuote {

 int get id;@JsonKey(name: 'author_name') String? get authorName; String get preview;@JsonKey(name: 'is_deleted') bool get isDeleted;
/// Create a copy of InternalQuote
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InternalQuoteCopyWith<InternalQuote> get copyWith => _$InternalQuoteCopyWithImpl<InternalQuote>(this as InternalQuote, _$identity);

  /// Serializes this InternalQuote to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InternalQuote&&(identical(other.id, id) || other.id == id)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.preview, preview) || other.preview == preview)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,authorName,preview,isDeleted);

@override
String toString() {
  return 'InternalQuote(id: $id, authorName: $authorName, preview: $preview, isDeleted: $isDeleted)';
}


}

/// @nodoc
abstract mixin class $InternalQuoteCopyWith<$Res>  {
  factory $InternalQuoteCopyWith(InternalQuote value, $Res Function(InternalQuote) _then) = _$InternalQuoteCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'author_name') String? authorName, String preview,@JsonKey(name: 'is_deleted') bool isDeleted
});




}
/// @nodoc
class _$InternalQuoteCopyWithImpl<$Res>
    implements $InternalQuoteCopyWith<$Res> {
  _$InternalQuoteCopyWithImpl(this._self, this._then);

  final InternalQuote _self;
  final $Res Function(InternalQuote) _then;

/// Create a copy of InternalQuote
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? authorName = freezed,Object? preview = null,Object? isDeleted = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,authorName: freezed == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String?,preview: null == preview ? _self.preview : preview // ignore: cast_nullable_to_non_nullable
as String,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [InternalQuote].
extension InternalQuotePatterns on InternalQuote {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InternalQuote value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InternalQuote() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InternalQuote value)  $default,){
final _that = this;
switch (_that) {
case _InternalQuote():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InternalQuote value)?  $default,){
final _that = this;
switch (_that) {
case _InternalQuote() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'author_name')  String? authorName,  String preview, @JsonKey(name: 'is_deleted')  bool isDeleted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InternalQuote() when $default != null:
return $default(_that.id,_that.authorName,_that.preview,_that.isDeleted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'author_name')  String? authorName,  String preview, @JsonKey(name: 'is_deleted')  bool isDeleted)  $default,) {final _that = this;
switch (_that) {
case _InternalQuote():
return $default(_that.id,_that.authorName,_that.preview,_that.isDeleted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'author_name')  String? authorName,  String preview, @JsonKey(name: 'is_deleted')  bool isDeleted)?  $default,) {final _that = this;
switch (_that) {
case _InternalQuote() when $default != null:
return $default(_that.id,_that.authorName,_that.preview,_that.isDeleted);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InternalQuote implements InternalQuote {
  const _InternalQuote({required this.id, @JsonKey(name: 'author_name') this.authorName, this.preview = '', @JsonKey(name: 'is_deleted') this.isDeleted = false});
  factory _InternalQuote.fromJson(Map<String, dynamic> json) => _$InternalQuoteFromJson(json);

@override final  int id;
@override@JsonKey(name: 'author_name') final  String? authorName;
@override@JsonKey() final  String preview;
@override@JsonKey(name: 'is_deleted') final  bool isDeleted;

/// Create a copy of InternalQuote
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InternalQuoteCopyWith<_InternalQuote> get copyWith => __$InternalQuoteCopyWithImpl<_InternalQuote>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InternalQuoteToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InternalQuote&&(identical(other.id, id) || other.id == id)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.preview, preview) || other.preview == preview)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,authorName,preview,isDeleted);

@override
String toString() {
  return 'InternalQuote(id: $id, authorName: $authorName, preview: $preview, isDeleted: $isDeleted)';
}


}

/// @nodoc
abstract mixin class _$InternalQuoteCopyWith<$Res> implements $InternalQuoteCopyWith<$Res> {
  factory _$InternalQuoteCopyWith(_InternalQuote value, $Res Function(_InternalQuote) _then) = __$InternalQuoteCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'author_name') String? authorName, String preview,@JsonKey(name: 'is_deleted') bool isDeleted
});




}
/// @nodoc
class __$InternalQuoteCopyWithImpl<$Res>
    implements _$InternalQuoteCopyWith<$Res> {
  __$InternalQuoteCopyWithImpl(this._self, this._then);

  final _InternalQuote _self;
  final $Res Function(_InternalQuote) _then;

/// Create a copy of InternalQuote
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? authorName = freezed,Object? preview = null,Object? isDeleted = null,}) {
  return _then(_InternalQuote(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,authorName: freezed == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String?,preview: null == preview ? _self.preview : preview // ignore: cast_nullable_to_non_nullable
as String,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$InternalMessage {

 int get id;@JsonKey(name: 'ticket_id') int? get ticketId; InternalPerson? get author;@JsonKey(name: 'is_mine') bool get isMine;/// «تم حذف هذه الرسالة» حين [isDeleted] — نصٌّ لا `null`، كي تُرسم فقاعةً عادية.
 String? get body;@JsonKey(name: 'is_deleted') bool get isDeleted;@JsonKey(name: 'is_edited') bool get isEdited;@JsonKey(name: 'reply_to') InternalQuote? get replyTo; List<InternalAttachment> get attachments;@JsonKey(name: 'client_token') String? get clientToken;@JsonKey(name: 'sent_at') DateTime? get sentAt;@JsonKey(name: 'can_edit') bool get canEdit;@JsonKey(name: 'can_delete') bool get canDelete;/// لماذا الزرّ مطفأ — الجملةُ نفسها التي يرفض بها الخادم.
@JsonKey(name: 'mutation_block_reason') String? get mutationBlockReason;@JsonKey(name: 'mutable_until') DateTime? get mutableUntil;
/// Create a copy of InternalMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InternalMessageCopyWith<InternalMessage> get copyWith => _$InternalMessageCopyWithImpl<InternalMessage>(this as InternalMessage, _$identity);

  /// Serializes this InternalMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InternalMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.ticketId, ticketId) || other.ticketId == ticketId)&&(identical(other.author, author) || other.author == author)&&(identical(other.isMine, isMine) || other.isMine == isMine)&&(identical(other.body, body) || other.body == body)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.isEdited, isEdited) || other.isEdited == isEdited)&&(identical(other.replyTo, replyTo) || other.replyTo == replyTo)&&const DeepCollectionEquality().equals(other.attachments, attachments)&&(identical(other.clientToken, clientToken) || other.clientToken == clientToken)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.canEdit, canEdit) || other.canEdit == canEdit)&&(identical(other.canDelete, canDelete) || other.canDelete == canDelete)&&(identical(other.mutationBlockReason, mutationBlockReason) || other.mutationBlockReason == mutationBlockReason)&&(identical(other.mutableUntil, mutableUntil) || other.mutableUntil == mutableUntil));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,ticketId,author,isMine,body,isDeleted,isEdited,replyTo,const DeepCollectionEquality().hash(attachments),clientToken,sentAt,canEdit,canDelete,mutationBlockReason,mutableUntil);

@override
String toString() {
  return 'InternalMessage(id: $id, ticketId: $ticketId, author: $author, isMine: $isMine, body: $body, isDeleted: $isDeleted, isEdited: $isEdited, replyTo: $replyTo, attachments: $attachments, clientToken: $clientToken, sentAt: $sentAt, canEdit: $canEdit, canDelete: $canDelete, mutationBlockReason: $mutationBlockReason, mutableUntil: $mutableUntil)';
}


}

/// @nodoc
abstract mixin class $InternalMessageCopyWith<$Res>  {
  factory $InternalMessageCopyWith(InternalMessage value, $Res Function(InternalMessage) _then) = _$InternalMessageCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'ticket_id') int? ticketId, InternalPerson? author,@JsonKey(name: 'is_mine') bool isMine, String? body,@JsonKey(name: 'is_deleted') bool isDeleted,@JsonKey(name: 'is_edited') bool isEdited,@JsonKey(name: 'reply_to') InternalQuote? replyTo, List<InternalAttachment> attachments,@JsonKey(name: 'client_token') String? clientToken,@JsonKey(name: 'sent_at') DateTime? sentAt,@JsonKey(name: 'can_edit') bool canEdit,@JsonKey(name: 'can_delete') bool canDelete,@JsonKey(name: 'mutation_block_reason') String? mutationBlockReason,@JsonKey(name: 'mutable_until') DateTime? mutableUntil
});


$InternalPersonCopyWith<$Res>? get author;$InternalQuoteCopyWith<$Res>? get replyTo;

}
/// @nodoc
class _$InternalMessageCopyWithImpl<$Res>
    implements $InternalMessageCopyWith<$Res> {
  _$InternalMessageCopyWithImpl(this._self, this._then);

  final InternalMessage _self;
  final $Res Function(InternalMessage) _then;

/// Create a copy of InternalMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ticketId = freezed,Object? author = freezed,Object? isMine = null,Object? body = freezed,Object? isDeleted = null,Object? isEdited = null,Object? replyTo = freezed,Object? attachments = null,Object? clientToken = freezed,Object? sentAt = freezed,Object? canEdit = null,Object? canDelete = null,Object? mutationBlockReason = freezed,Object? mutableUntil = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,ticketId: freezed == ticketId ? _self.ticketId : ticketId // ignore: cast_nullable_to_non_nullable
as int?,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as InternalPerson?,isMine: null == isMine ? _self.isMine : isMine // ignore: cast_nullable_to_non_nullable
as bool,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,isEdited: null == isEdited ? _self.isEdited : isEdited // ignore: cast_nullable_to_non_nullable
as bool,replyTo: freezed == replyTo ? _self.replyTo : replyTo // ignore: cast_nullable_to_non_nullable
as InternalQuote?,attachments: null == attachments ? _self.attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<InternalAttachment>,clientToken: freezed == clientToken ? _self.clientToken : clientToken // ignore: cast_nullable_to_non_nullable
as String?,sentAt: freezed == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,canEdit: null == canEdit ? _self.canEdit : canEdit // ignore: cast_nullable_to_non_nullable
as bool,canDelete: null == canDelete ? _self.canDelete : canDelete // ignore: cast_nullable_to_non_nullable
as bool,mutationBlockReason: freezed == mutationBlockReason ? _self.mutationBlockReason : mutationBlockReason // ignore: cast_nullable_to_non_nullable
as String?,mutableUntil: freezed == mutableUntil ? _self.mutableUntil : mutableUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of InternalMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InternalPersonCopyWith<$Res>? get author {
    if (_self.author == null) {
    return null;
  }

  return $InternalPersonCopyWith<$Res>(_self.author!, (value) {
    return _then(_self.copyWith(author: value));
  });
}/// Create a copy of InternalMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InternalQuoteCopyWith<$Res>? get replyTo {
    if (_self.replyTo == null) {
    return null;
  }

  return $InternalQuoteCopyWith<$Res>(_self.replyTo!, (value) {
    return _then(_self.copyWith(replyTo: value));
  });
}
}


/// Adds pattern-matching-related methods to [InternalMessage].
extension InternalMessagePatterns on InternalMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InternalMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InternalMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InternalMessage value)  $default,){
final _that = this;
switch (_that) {
case _InternalMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InternalMessage value)?  $default,){
final _that = this;
switch (_that) {
case _InternalMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'ticket_id')  int? ticketId,  InternalPerson? author, @JsonKey(name: 'is_mine')  bool isMine,  String? body, @JsonKey(name: 'is_deleted')  bool isDeleted, @JsonKey(name: 'is_edited')  bool isEdited, @JsonKey(name: 'reply_to')  InternalQuote? replyTo,  List<InternalAttachment> attachments, @JsonKey(name: 'client_token')  String? clientToken, @JsonKey(name: 'sent_at')  DateTime? sentAt, @JsonKey(name: 'can_edit')  bool canEdit, @JsonKey(name: 'can_delete')  bool canDelete, @JsonKey(name: 'mutation_block_reason')  String? mutationBlockReason, @JsonKey(name: 'mutable_until')  DateTime? mutableUntil)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InternalMessage() when $default != null:
return $default(_that.id,_that.ticketId,_that.author,_that.isMine,_that.body,_that.isDeleted,_that.isEdited,_that.replyTo,_that.attachments,_that.clientToken,_that.sentAt,_that.canEdit,_that.canDelete,_that.mutationBlockReason,_that.mutableUntil);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'ticket_id')  int? ticketId,  InternalPerson? author, @JsonKey(name: 'is_mine')  bool isMine,  String? body, @JsonKey(name: 'is_deleted')  bool isDeleted, @JsonKey(name: 'is_edited')  bool isEdited, @JsonKey(name: 'reply_to')  InternalQuote? replyTo,  List<InternalAttachment> attachments, @JsonKey(name: 'client_token')  String? clientToken, @JsonKey(name: 'sent_at')  DateTime? sentAt, @JsonKey(name: 'can_edit')  bool canEdit, @JsonKey(name: 'can_delete')  bool canDelete, @JsonKey(name: 'mutation_block_reason')  String? mutationBlockReason, @JsonKey(name: 'mutable_until')  DateTime? mutableUntil)  $default,) {final _that = this;
switch (_that) {
case _InternalMessage():
return $default(_that.id,_that.ticketId,_that.author,_that.isMine,_that.body,_that.isDeleted,_that.isEdited,_that.replyTo,_that.attachments,_that.clientToken,_that.sentAt,_that.canEdit,_that.canDelete,_that.mutationBlockReason,_that.mutableUntil);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'ticket_id')  int? ticketId,  InternalPerson? author, @JsonKey(name: 'is_mine')  bool isMine,  String? body, @JsonKey(name: 'is_deleted')  bool isDeleted, @JsonKey(name: 'is_edited')  bool isEdited, @JsonKey(name: 'reply_to')  InternalQuote? replyTo,  List<InternalAttachment> attachments, @JsonKey(name: 'client_token')  String? clientToken, @JsonKey(name: 'sent_at')  DateTime? sentAt, @JsonKey(name: 'can_edit')  bool canEdit, @JsonKey(name: 'can_delete')  bool canDelete, @JsonKey(name: 'mutation_block_reason')  String? mutationBlockReason, @JsonKey(name: 'mutable_until')  DateTime? mutableUntil)?  $default,) {final _that = this;
switch (_that) {
case _InternalMessage() when $default != null:
return $default(_that.id,_that.ticketId,_that.author,_that.isMine,_that.body,_that.isDeleted,_that.isEdited,_that.replyTo,_that.attachments,_that.clientToken,_that.sentAt,_that.canEdit,_that.canDelete,_that.mutationBlockReason,_that.mutableUntil);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InternalMessage extends InternalMessage {
  const _InternalMessage({required this.id, @JsonKey(name: 'ticket_id') this.ticketId, this.author, @JsonKey(name: 'is_mine') this.isMine = false, this.body, @JsonKey(name: 'is_deleted') this.isDeleted = false, @JsonKey(name: 'is_edited') this.isEdited = false, @JsonKey(name: 'reply_to') this.replyTo, final  List<InternalAttachment> attachments = const <InternalAttachment>[], @JsonKey(name: 'client_token') this.clientToken, @JsonKey(name: 'sent_at') this.sentAt, @JsonKey(name: 'can_edit') this.canEdit = false, @JsonKey(name: 'can_delete') this.canDelete = false, @JsonKey(name: 'mutation_block_reason') this.mutationBlockReason, @JsonKey(name: 'mutable_until') this.mutableUntil}): _attachments = attachments,super._();
  factory _InternalMessage.fromJson(Map<String, dynamic> json) => _$InternalMessageFromJson(json);

@override final  int id;
@override@JsonKey(name: 'ticket_id') final  int? ticketId;
@override final  InternalPerson? author;
@override@JsonKey(name: 'is_mine') final  bool isMine;
/// «تم حذف هذه الرسالة» حين [isDeleted] — نصٌّ لا `null`، كي تُرسم فقاعةً عادية.
@override final  String? body;
@override@JsonKey(name: 'is_deleted') final  bool isDeleted;
@override@JsonKey(name: 'is_edited') final  bool isEdited;
@override@JsonKey(name: 'reply_to') final  InternalQuote? replyTo;
 final  List<InternalAttachment> _attachments;
@override@JsonKey() List<InternalAttachment> get attachments {
  if (_attachments is EqualUnmodifiableListView) return _attachments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_attachments);
}

@override@JsonKey(name: 'client_token') final  String? clientToken;
@override@JsonKey(name: 'sent_at') final  DateTime? sentAt;
@override@JsonKey(name: 'can_edit') final  bool canEdit;
@override@JsonKey(name: 'can_delete') final  bool canDelete;
/// لماذا الزرّ مطفأ — الجملةُ نفسها التي يرفض بها الخادم.
@override@JsonKey(name: 'mutation_block_reason') final  String? mutationBlockReason;
@override@JsonKey(name: 'mutable_until') final  DateTime? mutableUntil;

/// Create a copy of InternalMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InternalMessageCopyWith<_InternalMessage> get copyWith => __$InternalMessageCopyWithImpl<_InternalMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InternalMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InternalMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.ticketId, ticketId) || other.ticketId == ticketId)&&(identical(other.author, author) || other.author == author)&&(identical(other.isMine, isMine) || other.isMine == isMine)&&(identical(other.body, body) || other.body == body)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.isEdited, isEdited) || other.isEdited == isEdited)&&(identical(other.replyTo, replyTo) || other.replyTo == replyTo)&&const DeepCollectionEquality().equals(other._attachments, _attachments)&&(identical(other.clientToken, clientToken) || other.clientToken == clientToken)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.canEdit, canEdit) || other.canEdit == canEdit)&&(identical(other.canDelete, canDelete) || other.canDelete == canDelete)&&(identical(other.mutationBlockReason, mutationBlockReason) || other.mutationBlockReason == mutationBlockReason)&&(identical(other.mutableUntil, mutableUntil) || other.mutableUntil == mutableUntil));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,ticketId,author,isMine,body,isDeleted,isEdited,replyTo,const DeepCollectionEquality().hash(_attachments),clientToken,sentAt,canEdit,canDelete,mutationBlockReason,mutableUntil);

@override
String toString() {
  return 'InternalMessage(id: $id, ticketId: $ticketId, author: $author, isMine: $isMine, body: $body, isDeleted: $isDeleted, isEdited: $isEdited, replyTo: $replyTo, attachments: $attachments, clientToken: $clientToken, sentAt: $sentAt, canEdit: $canEdit, canDelete: $canDelete, mutationBlockReason: $mutationBlockReason, mutableUntil: $mutableUntil)';
}


}

/// @nodoc
abstract mixin class _$InternalMessageCopyWith<$Res> implements $InternalMessageCopyWith<$Res> {
  factory _$InternalMessageCopyWith(_InternalMessage value, $Res Function(_InternalMessage) _then) = __$InternalMessageCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'ticket_id') int? ticketId, InternalPerson? author,@JsonKey(name: 'is_mine') bool isMine, String? body,@JsonKey(name: 'is_deleted') bool isDeleted,@JsonKey(name: 'is_edited') bool isEdited,@JsonKey(name: 'reply_to') InternalQuote? replyTo, List<InternalAttachment> attachments,@JsonKey(name: 'client_token') String? clientToken,@JsonKey(name: 'sent_at') DateTime? sentAt,@JsonKey(name: 'can_edit') bool canEdit,@JsonKey(name: 'can_delete') bool canDelete,@JsonKey(name: 'mutation_block_reason') String? mutationBlockReason,@JsonKey(name: 'mutable_until') DateTime? mutableUntil
});


@override $InternalPersonCopyWith<$Res>? get author;@override $InternalQuoteCopyWith<$Res>? get replyTo;

}
/// @nodoc
class __$InternalMessageCopyWithImpl<$Res>
    implements _$InternalMessageCopyWith<$Res> {
  __$InternalMessageCopyWithImpl(this._self, this._then);

  final _InternalMessage _self;
  final $Res Function(_InternalMessage) _then;

/// Create a copy of InternalMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ticketId = freezed,Object? author = freezed,Object? isMine = null,Object? body = freezed,Object? isDeleted = null,Object? isEdited = null,Object? replyTo = freezed,Object? attachments = null,Object? clientToken = freezed,Object? sentAt = freezed,Object? canEdit = null,Object? canDelete = null,Object? mutationBlockReason = freezed,Object? mutableUntil = freezed,}) {
  return _then(_InternalMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,ticketId: freezed == ticketId ? _self.ticketId : ticketId // ignore: cast_nullable_to_non_nullable
as int?,author: freezed == author ? _self.author : author // ignore: cast_nullable_to_non_nullable
as InternalPerson?,isMine: null == isMine ? _self.isMine : isMine // ignore: cast_nullable_to_non_nullable
as bool,body: freezed == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String?,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,isEdited: null == isEdited ? _self.isEdited : isEdited // ignore: cast_nullable_to_non_nullable
as bool,replyTo: freezed == replyTo ? _self.replyTo : replyTo // ignore: cast_nullable_to_non_nullable
as InternalQuote?,attachments: null == attachments ? _self._attachments : attachments // ignore: cast_nullable_to_non_nullable
as List<InternalAttachment>,clientToken: freezed == clientToken ? _self.clientToken : clientToken // ignore: cast_nullable_to_non_nullable
as String?,sentAt: freezed == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,canEdit: null == canEdit ? _self.canEdit : canEdit // ignore: cast_nullable_to_non_nullable
as bool,canDelete: null == canDelete ? _self.canDelete : canDelete // ignore: cast_nullable_to_non_nullable
as bool,mutationBlockReason: freezed == mutationBlockReason ? _self.mutationBlockReason : mutationBlockReason // ignore: cast_nullable_to_non_nullable
as String?,mutableUntil: freezed == mutableUntil ? _self.mutableUntil : mutableUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of InternalMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InternalPersonCopyWith<$Res>? get author {
    if (_self.author == null) {
    return null;
  }

  return $InternalPersonCopyWith<$Res>(_self.author!, (value) {
    return _then(_self.copyWith(author: value));
  });
}/// Create a copy of InternalMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InternalQuoteCopyWith<$Res>? get replyTo {
    if (_self.replyTo == null) {
    return null;
  }

  return $InternalQuoteCopyWith<$Res>(_self.replyTo!, (value) {
    return _then(_self.copyWith(replyTo: value));
  });
}
}


/// @nodoc
mixin _$InternalLastMessage {

 int get id;@JsonKey(name: 'author_id') int? get authorId;@JsonKey(name: 'author_name') String? get authorName; String get preview;/// `text` أو `image` أو `voice` — أيقونةٌ قبل المعاينة.
 String get kind;@JsonKey(name: 'duration_seconds') int? get durationSeconds;@JsonKey(name: 'sent_at') DateTime? get sentAt;
/// Create a copy of InternalLastMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InternalLastMessageCopyWith<InternalLastMessage> get copyWith => _$InternalLastMessageCopyWithImpl<InternalLastMessage>(this as InternalLastMessage, _$identity);

  /// Serializes this InternalLastMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InternalLastMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.preview, preview) || other.preview == preview)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,authorId,authorName,preview,kind,durationSeconds,sentAt);

@override
String toString() {
  return 'InternalLastMessage(id: $id, authorId: $authorId, authorName: $authorName, preview: $preview, kind: $kind, durationSeconds: $durationSeconds, sentAt: $sentAt)';
}


}

/// @nodoc
abstract mixin class $InternalLastMessageCopyWith<$Res>  {
  factory $InternalLastMessageCopyWith(InternalLastMessage value, $Res Function(InternalLastMessage) _then) = _$InternalLastMessageCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'author_id') int? authorId,@JsonKey(name: 'author_name') String? authorName, String preview, String kind,@JsonKey(name: 'duration_seconds') int? durationSeconds,@JsonKey(name: 'sent_at') DateTime? sentAt
});




}
/// @nodoc
class _$InternalLastMessageCopyWithImpl<$Res>
    implements $InternalLastMessageCopyWith<$Res> {
  _$InternalLastMessageCopyWithImpl(this._self, this._then);

  final InternalLastMessage _self;
  final $Res Function(InternalLastMessage) _then;

/// Create a copy of InternalLastMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? authorId = freezed,Object? authorName = freezed,Object? preview = null,Object? kind = null,Object? durationSeconds = freezed,Object? sentAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,authorId: freezed == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as int?,authorName: freezed == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String?,preview: null == preview ? _self.preview : preview // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,sentAt: freezed == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [InternalLastMessage].
extension InternalLastMessagePatterns on InternalLastMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InternalLastMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InternalLastMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InternalLastMessage value)  $default,){
final _that = this;
switch (_that) {
case _InternalLastMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InternalLastMessage value)?  $default,){
final _that = this;
switch (_that) {
case _InternalLastMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'author_id')  int? authorId, @JsonKey(name: 'author_name')  String? authorName,  String preview,  String kind, @JsonKey(name: 'duration_seconds')  int? durationSeconds, @JsonKey(name: 'sent_at')  DateTime? sentAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InternalLastMessage() when $default != null:
return $default(_that.id,_that.authorId,_that.authorName,_that.preview,_that.kind,_that.durationSeconds,_that.sentAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'author_id')  int? authorId, @JsonKey(name: 'author_name')  String? authorName,  String preview,  String kind, @JsonKey(name: 'duration_seconds')  int? durationSeconds, @JsonKey(name: 'sent_at')  DateTime? sentAt)  $default,) {final _that = this;
switch (_that) {
case _InternalLastMessage():
return $default(_that.id,_that.authorId,_that.authorName,_that.preview,_that.kind,_that.durationSeconds,_that.sentAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'author_id')  int? authorId, @JsonKey(name: 'author_name')  String? authorName,  String preview,  String kind, @JsonKey(name: 'duration_seconds')  int? durationSeconds, @JsonKey(name: 'sent_at')  DateTime? sentAt)?  $default,) {final _that = this;
switch (_that) {
case _InternalLastMessage() when $default != null:
return $default(_that.id,_that.authorId,_that.authorName,_that.preview,_that.kind,_that.durationSeconds,_that.sentAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InternalLastMessage implements InternalLastMessage {
  const _InternalLastMessage({required this.id, @JsonKey(name: 'author_id') this.authorId, @JsonKey(name: 'author_name') this.authorName, this.preview = '', this.kind = 'text', @JsonKey(name: 'duration_seconds') this.durationSeconds, @JsonKey(name: 'sent_at') this.sentAt});
  factory _InternalLastMessage.fromJson(Map<String, dynamic> json) => _$InternalLastMessageFromJson(json);

@override final  int id;
@override@JsonKey(name: 'author_id') final  int? authorId;
@override@JsonKey(name: 'author_name') final  String? authorName;
@override@JsonKey() final  String preview;
/// `text` أو `image` أو `voice` — أيقونةٌ قبل المعاينة.
@override@JsonKey() final  String kind;
@override@JsonKey(name: 'duration_seconds') final  int? durationSeconds;
@override@JsonKey(name: 'sent_at') final  DateTime? sentAt;

/// Create a copy of InternalLastMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InternalLastMessageCopyWith<_InternalLastMessage> get copyWith => __$InternalLastMessageCopyWithImpl<_InternalLastMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InternalLastMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InternalLastMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.preview, preview) || other.preview == preview)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,authorId,authorName,preview,kind,durationSeconds,sentAt);

@override
String toString() {
  return 'InternalLastMessage(id: $id, authorId: $authorId, authorName: $authorName, preview: $preview, kind: $kind, durationSeconds: $durationSeconds, sentAt: $sentAt)';
}


}

/// @nodoc
abstract mixin class _$InternalLastMessageCopyWith<$Res> implements $InternalLastMessageCopyWith<$Res> {
  factory _$InternalLastMessageCopyWith(_InternalLastMessage value, $Res Function(_InternalLastMessage) _then) = __$InternalLastMessageCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'author_id') int? authorId,@JsonKey(name: 'author_name') String? authorName, String preview, String kind,@JsonKey(name: 'duration_seconds') int? durationSeconds,@JsonKey(name: 'sent_at') DateTime? sentAt
});




}
/// @nodoc
class __$InternalLastMessageCopyWithImpl<$Res>
    implements _$InternalLastMessageCopyWith<$Res> {
  __$InternalLastMessageCopyWithImpl(this._self, this._then);

  final _InternalLastMessage _self;
  final $Res Function(_InternalLastMessage) _then;

/// Create a copy of InternalLastMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? authorId = freezed,Object? authorName = freezed,Object? preview = null,Object? kind = null,Object? durationSeconds = freezed,Object? sentAt = freezed,}) {
  return _then(_InternalLastMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,authorId: freezed == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as int?,authorName: freezed == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String?,preview: null == preview ? _self.preview : preview // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,sentAt: freezed == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$InternalReadUpTo {

 int? get opener; int? get assignee;
/// Create a copy of InternalReadUpTo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InternalReadUpToCopyWith<InternalReadUpTo> get copyWith => _$InternalReadUpToCopyWithImpl<InternalReadUpTo>(this as InternalReadUpTo, _$identity);

  /// Serializes this InternalReadUpTo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InternalReadUpTo&&(identical(other.opener, opener) || other.opener == opener)&&(identical(other.assignee, assignee) || other.assignee == assignee));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,opener,assignee);

@override
String toString() {
  return 'InternalReadUpTo(opener: $opener, assignee: $assignee)';
}


}

/// @nodoc
abstract mixin class $InternalReadUpToCopyWith<$Res>  {
  factory $InternalReadUpToCopyWith(InternalReadUpTo value, $Res Function(InternalReadUpTo) _then) = _$InternalReadUpToCopyWithImpl;
@useResult
$Res call({
 int? opener, int? assignee
});




}
/// @nodoc
class _$InternalReadUpToCopyWithImpl<$Res>
    implements $InternalReadUpToCopyWith<$Res> {
  _$InternalReadUpToCopyWithImpl(this._self, this._then);

  final InternalReadUpTo _self;
  final $Res Function(InternalReadUpTo) _then;

/// Create a copy of InternalReadUpTo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? opener = freezed,Object? assignee = freezed,}) {
  return _then(_self.copyWith(
opener: freezed == opener ? _self.opener : opener // ignore: cast_nullable_to_non_nullable
as int?,assignee: freezed == assignee ? _self.assignee : assignee // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [InternalReadUpTo].
extension InternalReadUpToPatterns on InternalReadUpTo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InternalReadUpTo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InternalReadUpTo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InternalReadUpTo value)  $default,){
final _that = this;
switch (_that) {
case _InternalReadUpTo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InternalReadUpTo value)?  $default,){
final _that = this;
switch (_that) {
case _InternalReadUpTo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? opener,  int? assignee)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InternalReadUpTo() when $default != null:
return $default(_that.opener,_that.assignee);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? opener,  int? assignee)  $default,) {final _that = this;
switch (_that) {
case _InternalReadUpTo():
return $default(_that.opener,_that.assignee);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? opener,  int? assignee)?  $default,) {final _that = this;
switch (_that) {
case _InternalReadUpTo() when $default != null:
return $default(_that.opener,_that.assignee);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InternalReadUpTo implements InternalReadUpTo {
  const _InternalReadUpTo({this.opener, this.assignee});
  factory _InternalReadUpTo.fromJson(Map<String, dynamic> json) => _$InternalReadUpToFromJson(json);

@override final  int? opener;
@override final  int? assignee;

/// Create a copy of InternalReadUpTo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InternalReadUpToCopyWith<_InternalReadUpTo> get copyWith => __$InternalReadUpToCopyWithImpl<_InternalReadUpTo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InternalReadUpToToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InternalReadUpTo&&(identical(other.opener, opener) || other.opener == opener)&&(identical(other.assignee, assignee) || other.assignee == assignee));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,opener,assignee);

@override
String toString() {
  return 'InternalReadUpTo(opener: $opener, assignee: $assignee)';
}


}

/// @nodoc
abstract mixin class _$InternalReadUpToCopyWith<$Res> implements $InternalReadUpToCopyWith<$Res> {
  factory _$InternalReadUpToCopyWith(_InternalReadUpTo value, $Res Function(_InternalReadUpTo) _then) = __$InternalReadUpToCopyWithImpl;
@override @useResult
$Res call({
 int? opener, int? assignee
});




}
/// @nodoc
class __$InternalReadUpToCopyWithImpl<$Res>
    implements _$InternalReadUpToCopyWith<$Res> {
  __$InternalReadUpToCopyWithImpl(this._self, this._then);

  final _InternalReadUpTo _self;
  final $Res Function(_InternalReadUpTo) _then;

/// Create a copy of InternalReadUpTo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? opener = freezed,Object? assignee = freezed,}) {
  return _then(_InternalReadUpTo(
opener: freezed == opener ? _self.opener : opener // ignore: cast_nullable_to_non_nullable
as int?,assignee: freezed == assignee ? _self.assignee : assignee // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$InternalTicket {

 int get id; String get code; String get title;@JsonKey(unknownEnumValue: InternalTicketStatus.unknown) InternalTicketStatus get status;@JsonKey(name: 'status_label') String get statusLabel;@JsonKey(unknownEnumValue: InternalTicketPriority.unknown) InternalTicketPriority get priority;@JsonKey(name: 'priority_label') String get priorityLabel; InternalCategory? get category; InternalPerson? get opener; InternalPerson? get assignee;/// الطرفُ الآخر عند هذا القارئ. `null` للمدير الذي ليس طرفاً — وفي البثّ.
 InternalPerson? get counterpart;@JsonKey(name: 'i_opened_it') bool get iOpenedIt;@JsonKey(name: 'is_party') bool get isParty; InternalCustomerRef? get customer; InternalOrderRef? get order;@JsonKey(name: 'unread_count') int get unreadCount;/// رسالتي مقروءةٌ (✓✓) إن كان رقمها لا يتجاوز هذا.
@JsonKey(name: 'counterpart_read_up_to') int? get counterpartReadUpTo;@JsonKey(name: 'read_up_to') InternalReadUpTo? get readUpTo;@JsonKey(name: 'awaiting_my_reply') bool get awaitingMyReply;@JsonKey(name: 'last_message') InternalLastMessage? get lastMessage;/// فارغةٌ في القائمة، كاملةٌ في المحادثة.
 List<InternalMessage> get messages;@JsonKey(name: 'can_reply') bool get canReply;@JsonKey(name: 'can_close') bool get canClose;@JsonKey(name: 'can_transfer') bool get canTransfer;@JsonKey(name: 'last_message_at') DateTime? get lastMessageAt;@JsonKey(name: 'closed_at') DateTime? get closedAt;@JsonKey(name: 'closed_by') InternalPerson? get closedBy;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of InternalTicket
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InternalTicketCopyWith<InternalTicket> get copyWith => _$InternalTicketCopyWithImpl<InternalTicket>(this as InternalTicket, _$identity);

  /// Serializes this InternalTicket to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InternalTicket&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.title, title) || other.title == title)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.priorityLabel, priorityLabel) || other.priorityLabel == priorityLabel)&&(identical(other.category, category) || other.category == category)&&(identical(other.opener, opener) || other.opener == opener)&&(identical(other.assignee, assignee) || other.assignee == assignee)&&(identical(other.counterpart, counterpart) || other.counterpart == counterpart)&&(identical(other.iOpenedIt, iOpenedIt) || other.iOpenedIt == iOpenedIt)&&(identical(other.isParty, isParty) || other.isParty == isParty)&&(identical(other.customer, customer) || other.customer == customer)&&(identical(other.order, order) || other.order == order)&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount)&&(identical(other.counterpartReadUpTo, counterpartReadUpTo) || other.counterpartReadUpTo == counterpartReadUpTo)&&(identical(other.readUpTo, readUpTo) || other.readUpTo == readUpTo)&&(identical(other.awaitingMyReply, awaitingMyReply) || other.awaitingMyReply == awaitingMyReply)&&(identical(other.lastMessage, lastMessage) || other.lastMessage == lastMessage)&&const DeepCollectionEquality().equals(other.messages, messages)&&(identical(other.canReply, canReply) || other.canReply == canReply)&&(identical(other.canClose, canClose) || other.canClose == canClose)&&(identical(other.canTransfer, canTransfer) || other.canTransfer == canTransfer)&&(identical(other.lastMessageAt, lastMessageAt) || other.lastMessageAt == lastMessageAt)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.closedBy, closedBy) || other.closedBy == closedBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,code,title,status,statusLabel,priority,priorityLabel,category,opener,assignee,counterpart,iOpenedIt,isParty,customer,order,unreadCount,counterpartReadUpTo,readUpTo,awaitingMyReply,lastMessage,const DeepCollectionEquality().hash(messages),canReply,canClose,canTransfer,lastMessageAt,closedAt,closedBy,createdAt]);

@override
String toString() {
  return 'InternalTicket(id: $id, code: $code, title: $title, status: $status, statusLabel: $statusLabel, priority: $priority, priorityLabel: $priorityLabel, category: $category, opener: $opener, assignee: $assignee, counterpart: $counterpart, iOpenedIt: $iOpenedIt, isParty: $isParty, customer: $customer, order: $order, unreadCount: $unreadCount, counterpartReadUpTo: $counterpartReadUpTo, readUpTo: $readUpTo, awaitingMyReply: $awaitingMyReply, lastMessage: $lastMessage, messages: $messages, canReply: $canReply, canClose: $canClose, canTransfer: $canTransfer, lastMessageAt: $lastMessageAt, closedAt: $closedAt, closedBy: $closedBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $InternalTicketCopyWith<$Res>  {
  factory $InternalTicketCopyWith(InternalTicket value, $Res Function(InternalTicket) _then) = _$InternalTicketCopyWithImpl;
@useResult
$Res call({
 int id, String code, String title,@JsonKey(unknownEnumValue: InternalTicketStatus.unknown) InternalTicketStatus status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(unknownEnumValue: InternalTicketPriority.unknown) InternalTicketPriority priority,@JsonKey(name: 'priority_label') String priorityLabel, InternalCategory? category, InternalPerson? opener, InternalPerson? assignee, InternalPerson? counterpart,@JsonKey(name: 'i_opened_it') bool iOpenedIt,@JsonKey(name: 'is_party') bool isParty, InternalCustomerRef? customer, InternalOrderRef? order,@JsonKey(name: 'unread_count') int unreadCount,@JsonKey(name: 'counterpart_read_up_to') int? counterpartReadUpTo,@JsonKey(name: 'read_up_to') InternalReadUpTo? readUpTo,@JsonKey(name: 'awaiting_my_reply') bool awaitingMyReply,@JsonKey(name: 'last_message') InternalLastMessage? lastMessage, List<InternalMessage> messages,@JsonKey(name: 'can_reply') bool canReply,@JsonKey(name: 'can_close') bool canClose,@JsonKey(name: 'can_transfer') bool canTransfer,@JsonKey(name: 'last_message_at') DateTime? lastMessageAt,@JsonKey(name: 'closed_at') DateTime? closedAt,@JsonKey(name: 'closed_by') InternalPerson? closedBy,@JsonKey(name: 'created_at') DateTime? createdAt
});


$InternalCategoryCopyWith<$Res>? get category;$InternalPersonCopyWith<$Res>? get opener;$InternalPersonCopyWith<$Res>? get assignee;$InternalPersonCopyWith<$Res>? get counterpart;$InternalCustomerRefCopyWith<$Res>? get customer;$InternalOrderRefCopyWith<$Res>? get order;$InternalReadUpToCopyWith<$Res>? get readUpTo;$InternalLastMessageCopyWith<$Res>? get lastMessage;$InternalPersonCopyWith<$Res>? get closedBy;

}
/// @nodoc
class _$InternalTicketCopyWithImpl<$Res>
    implements $InternalTicketCopyWith<$Res> {
  _$InternalTicketCopyWithImpl(this._self, this._then);

  final InternalTicket _self;
  final $Res Function(InternalTicket) _then;

/// Create a copy of InternalTicket
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? title = null,Object? status = null,Object? statusLabel = null,Object? priority = null,Object? priorityLabel = null,Object? category = freezed,Object? opener = freezed,Object? assignee = freezed,Object? counterpart = freezed,Object? iOpenedIt = null,Object? isParty = null,Object? customer = freezed,Object? order = freezed,Object? unreadCount = null,Object? counterpartReadUpTo = freezed,Object? readUpTo = freezed,Object? awaitingMyReply = null,Object? lastMessage = freezed,Object? messages = null,Object? canReply = null,Object? canClose = null,Object? canTransfer = null,Object? lastMessageAt = freezed,Object? closedAt = freezed,Object? closedBy = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InternalTicketStatus,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as InternalTicketPriority,priorityLabel: null == priorityLabel ? _self.priorityLabel : priorityLabel // ignore: cast_nullable_to_non_nullable
as String,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as InternalCategory?,opener: freezed == opener ? _self.opener : opener // ignore: cast_nullable_to_non_nullable
as InternalPerson?,assignee: freezed == assignee ? _self.assignee : assignee // ignore: cast_nullable_to_non_nullable
as InternalPerson?,counterpart: freezed == counterpart ? _self.counterpart : counterpart // ignore: cast_nullable_to_non_nullable
as InternalPerson?,iOpenedIt: null == iOpenedIt ? _self.iOpenedIt : iOpenedIt // ignore: cast_nullable_to_non_nullable
as bool,isParty: null == isParty ? _self.isParty : isParty // ignore: cast_nullable_to_non_nullable
as bool,customer: freezed == customer ? _self.customer : customer // ignore: cast_nullable_to_non_nullable
as InternalCustomerRef?,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as InternalOrderRef?,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,counterpartReadUpTo: freezed == counterpartReadUpTo ? _self.counterpartReadUpTo : counterpartReadUpTo // ignore: cast_nullable_to_non_nullable
as int?,readUpTo: freezed == readUpTo ? _self.readUpTo : readUpTo // ignore: cast_nullable_to_non_nullable
as InternalReadUpTo?,awaitingMyReply: null == awaitingMyReply ? _self.awaitingMyReply : awaitingMyReply // ignore: cast_nullable_to_non_nullable
as bool,lastMessage: freezed == lastMessage ? _self.lastMessage : lastMessage // ignore: cast_nullable_to_non_nullable
as InternalLastMessage?,messages: null == messages ? _self.messages : messages // ignore: cast_nullable_to_non_nullable
as List<InternalMessage>,canReply: null == canReply ? _self.canReply : canReply // ignore: cast_nullable_to_non_nullable
as bool,canClose: null == canClose ? _self.canClose : canClose // ignore: cast_nullable_to_non_nullable
as bool,canTransfer: null == canTransfer ? _self.canTransfer : canTransfer // ignore: cast_nullable_to_non_nullable
as bool,lastMessageAt: freezed == lastMessageAt ? _self.lastMessageAt : lastMessageAt // ignore: cast_nullable_to_non_nullable
as DateTime?,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,closedBy: freezed == closedBy ? _self.closedBy : closedBy // ignore: cast_nullable_to_non_nullable
as InternalPerson?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of InternalTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InternalCategoryCopyWith<$Res>? get category {
    if (_self.category == null) {
    return null;
  }

  return $InternalCategoryCopyWith<$Res>(_self.category!, (value) {
    return _then(_self.copyWith(category: value));
  });
}/// Create a copy of InternalTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InternalPersonCopyWith<$Res>? get opener {
    if (_self.opener == null) {
    return null;
  }

  return $InternalPersonCopyWith<$Res>(_self.opener!, (value) {
    return _then(_self.copyWith(opener: value));
  });
}/// Create a copy of InternalTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InternalPersonCopyWith<$Res>? get assignee {
    if (_self.assignee == null) {
    return null;
  }

  return $InternalPersonCopyWith<$Res>(_self.assignee!, (value) {
    return _then(_self.copyWith(assignee: value));
  });
}/// Create a copy of InternalTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InternalPersonCopyWith<$Res>? get counterpart {
    if (_self.counterpart == null) {
    return null;
  }

  return $InternalPersonCopyWith<$Res>(_self.counterpart!, (value) {
    return _then(_self.copyWith(counterpart: value));
  });
}/// Create a copy of InternalTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InternalCustomerRefCopyWith<$Res>? get customer {
    if (_self.customer == null) {
    return null;
  }

  return $InternalCustomerRefCopyWith<$Res>(_self.customer!, (value) {
    return _then(_self.copyWith(customer: value));
  });
}/// Create a copy of InternalTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InternalOrderRefCopyWith<$Res>? get order {
    if (_self.order == null) {
    return null;
  }

  return $InternalOrderRefCopyWith<$Res>(_self.order!, (value) {
    return _then(_self.copyWith(order: value));
  });
}/// Create a copy of InternalTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InternalReadUpToCopyWith<$Res>? get readUpTo {
    if (_self.readUpTo == null) {
    return null;
  }

  return $InternalReadUpToCopyWith<$Res>(_self.readUpTo!, (value) {
    return _then(_self.copyWith(readUpTo: value));
  });
}/// Create a copy of InternalTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InternalLastMessageCopyWith<$Res>? get lastMessage {
    if (_self.lastMessage == null) {
    return null;
  }

  return $InternalLastMessageCopyWith<$Res>(_self.lastMessage!, (value) {
    return _then(_self.copyWith(lastMessage: value));
  });
}/// Create a copy of InternalTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InternalPersonCopyWith<$Res>? get closedBy {
    if (_self.closedBy == null) {
    return null;
  }

  return $InternalPersonCopyWith<$Res>(_self.closedBy!, (value) {
    return _then(_self.copyWith(closedBy: value));
  });
}
}


/// Adds pattern-matching-related methods to [InternalTicket].
extension InternalTicketPatterns on InternalTicket {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InternalTicket value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InternalTicket() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InternalTicket value)  $default,){
final _that = this;
switch (_that) {
case _InternalTicket():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InternalTicket value)?  $default,){
final _that = this;
switch (_that) {
case _InternalTicket() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String code,  String title, @JsonKey(unknownEnumValue: InternalTicketStatus.unknown)  InternalTicketStatus status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(unknownEnumValue: InternalTicketPriority.unknown)  InternalTicketPriority priority, @JsonKey(name: 'priority_label')  String priorityLabel,  InternalCategory? category,  InternalPerson? opener,  InternalPerson? assignee,  InternalPerson? counterpart, @JsonKey(name: 'i_opened_it')  bool iOpenedIt, @JsonKey(name: 'is_party')  bool isParty,  InternalCustomerRef? customer,  InternalOrderRef? order, @JsonKey(name: 'unread_count')  int unreadCount, @JsonKey(name: 'counterpart_read_up_to')  int? counterpartReadUpTo, @JsonKey(name: 'read_up_to')  InternalReadUpTo? readUpTo, @JsonKey(name: 'awaiting_my_reply')  bool awaitingMyReply, @JsonKey(name: 'last_message')  InternalLastMessage? lastMessage,  List<InternalMessage> messages, @JsonKey(name: 'can_reply')  bool canReply, @JsonKey(name: 'can_close')  bool canClose, @JsonKey(name: 'can_transfer')  bool canTransfer, @JsonKey(name: 'last_message_at')  DateTime? lastMessageAt, @JsonKey(name: 'closed_at')  DateTime? closedAt, @JsonKey(name: 'closed_by')  InternalPerson? closedBy, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InternalTicket() when $default != null:
return $default(_that.id,_that.code,_that.title,_that.status,_that.statusLabel,_that.priority,_that.priorityLabel,_that.category,_that.opener,_that.assignee,_that.counterpart,_that.iOpenedIt,_that.isParty,_that.customer,_that.order,_that.unreadCount,_that.counterpartReadUpTo,_that.readUpTo,_that.awaitingMyReply,_that.lastMessage,_that.messages,_that.canReply,_that.canClose,_that.canTransfer,_that.lastMessageAt,_that.closedAt,_that.closedBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String code,  String title, @JsonKey(unknownEnumValue: InternalTicketStatus.unknown)  InternalTicketStatus status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(unknownEnumValue: InternalTicketPriority.unknown)  InternalTicketPriority priority, @JsonKey(name: 'priority_label')  String priorityLabel,  InternalCategory? category,  InternalPerson? opener,  InternalPerson? assignee,  InternalPerson? counterpart, @JsonKey(name: 'i_opened_it')  bool iOpenedIt, @JsonKey(name: 'is_party')  bool isParty,  InternalCustomerRef? customer,  InternalOrderRef? order, @JsonKey(name: 'unread_count')  int unreadCount, @JsonKey(name: 'counterpart_read_up_to')  int? counterpartReadUpTo, @JsonKey(name: 'read_up_to')  InternalReadUpTo? readUpTo, @JsonKey(name: 'awaiting_my_reply')  bool awaitingMyReply, @JsonKey(name: 'last_message')  InternalLastMessage? lastMessage,  List<InternalMessage> messages, @JsonKey(name: 'can_reply')  bool canReply, @JsonKey(name: 'can_close')  bool canClose, @JsonKey(name: 'can_transfer')  bool canTransfer, @JsonKey(name: 'last_message_at')  DateTime? lastMessageAt, @JsonKey(name: 'closed_at')  DateTime? closedAt, @JsonKey(name: 'closed_by')  InternalPerson? closedBy, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _InternalTicket():
return $default(_that.id,_that.code,_that.title,_that.status,_that.statusLabel,_that.priority,_that.priorityLabel,_that.category,_that.opener,_that.assignee,_that.counterpart,_that.iOpenedIt,_that.isParty,_that.customer,_that.order,_that.unreadCount,_that.counterpartReadUpTo,_that.readUpTo,_that.awaitingMyReply,_that.lastMessage,_that.messages,_that.canReply,_that.canClose,_that.canTransfer,_that.lastMessageAt,_that.closedAt,_that.closedBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String code,  String title, @JsonKey(unknownEnumValue: InternalTicketStatus.unknown)  InternalTicketStatus status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(unknownEnumValue: InternalTicketPriority.unknown)  InternalTicketPriority priority, @JsonKey(name: 'priority_label')  String priorityLabel,  InternalCategory? category,  InternalPerson? opener,  InternalPerson? assignee,  InternalPerson? counterpart, @JsonKey(name: 'i_opened_it')  bool iOpenedIt, @JsonKey(name: 'is_party')  bool isParty,  InternalCustomerRef? customer,  InternalOrderRef? order, @JsonKey(name: 'unread_count')  int unreadCount, @JsonKey(name: 'counterpart_read_up_to')  int? counterpartReadUpTo, @JsonKey(name: 'read_up_to')  InternalReadUpTo? readUpTo, @JsonKey(name: 'awaiting_my_reply')  bool awaitingMyReply, @JsonKey(name: 'last_message')  InternalLastMessage? lastMessage,  List<InternalMessage> messages, @JsonKey(name: 'can_reply')  bool canReply, @JsonKey(name: 'can_close')  bool canClose, @JsonKey(name: 'can_transfer')  bool canTransfer, @JsonKey(name: 'last_message_at')  DateTime? lastMessageAt, @JsonKey(name: 'closed_at')  DateTime? closedAt, @JsonKey(name: 'closed_by')  InternalPerson? closedBy, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _InternalTicket() when $default != null:
return $default(_that.id,_that.code,_that.title,_that.status,_that.statusLabel,_that.priority,_that.priorityLabel,_that.category,_that.opener,_that.assignee,_that.counterpart,_that.iOpenedIt,_that.isParty,_that.customer,_that.order,_that.unreadCount,_that.counterpartReadUpTo,_that.readUpTo,_that.awaitingMyReply,_that.lastMessage,_that.messages,_that.canReply,_that.canClose,_that.canTransfer,_that.lastMessageAt,_that.closedAt,_that.closedBy,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InternalTicket extends InternalTicket {
  const _InternalTicket({required this.id, required this.code, required this.title, @JsonKey(unknownEnumValue: InternalTicketStatus.unknown) this.status = InternalTicketStatus.unknown, @JsonKey(name: 'status_label') this.statusLabel = '', @JsonKey(unknownEnumValue: InternalTicketPriority.unknown) this.priority = InternalTicketPriority.medium, @JsonKey(name: 'priority_label') this.priorityLabel = '', this.category, this.opener, this.assignee, this.counterpart, @JsonKey(name: 'i_opened_it') this.iOpenedIt = false, @JsonKey(name: 'is_party') this.isParty = false, this.customer, this.order, @JsonKey(name: 'unread_count') this.unreadCount = 0, @JsonKey(name: 'counterpart_read_up_to') this.counterpartReadUpTo, @JsonKey(name: 'read_up_to') this.readUpTo, @JsonKey(name: 'awaiting_my_reply') this.awaitingMyReply = false, @JsonKey(name: 'last_message') this.lastMessage, final  List<InternalMessage> messages = const <InternalMessage>[], @JsonKey(name: 'can_reply') this.canReply = false, @JsonKey(name: 'can_close') this.canClose = false, @JsonKey(name: 'can_transfer') this.canTransfer = false, @JsonKey(name: 'last_message_at') this.lastMessageAt, @JsonKey(name: 'closed_at') this.closedAt, @JsonKey(name: 'closed_by') this.closedBy, @JsonKey(name: 'created_at') this.createdAt}): _messages = messages,super._();
  factory _InternalTicket.fromJson(Map<String, dynamic> json) => _$InternalTicketFromJson(json);

@override final  int id;
@override final  String code;
@override final  String title;
@override@JsonKey(unknownEnumValue: InternalTicketStatus.unknown) final  InternalTicketStatus status;
@override@JsonKey(name: 'status_label') final  String statusLabel;
@override@JsonKey(unknownEnumValue: InternalTicketPriority.unknown) final  InternalTicketPriority priority;
@override@JsonKey(name: 'priority_label') final  String priorityLabel;
@override final  InternalCategory? category;
@override final  InternalPerson? opener;
@override final  InternalPerson? assignee;
/// الطرفُ الآخر عند هذا القارئ. `null` للمدير الذي ليس طرفاً — وفي البثّ.
@override final  InternalPerson? counterpart;
@override@JsonKey(name: 'i_opened_it') final  bool iOpenedIt;
@override@JsonKey(name: 'is_party') final  bool isParty;
@override final  InternalCustomerRef? customer;
@override final  InternalOrderRef? order;
@override@JsonKey(name: 'unread_count') final  int unreadCount;
/// رسالتي مقروءةٌ (✓✓) إن كان رقمها لا يتجاوز هذا.
@override@JsonKey(name: 'counterpart_read_up_to') final  int? counterpartReadUpTo;
@override@JsonKey(name: 'read_up_to') final  InternalReadUpTo? readUpTo;
@override@JsonKey(name: 'awaiting_my_reply') final  bool awaitingMyReply;
@override@JsonKey(name: 'last_message') final  InternalLastMessage? lastMessage;
/// فارغةٌ في القائمة، كاملةٌ في المحادثة.
 final  List<InternalMessage> _messages;
/// فارغةٌ في القائمة، كاملةٌ في المحادثة.
@override@JsonKey() List<InternalMessage> get messages {
  if (_messages is EqualUnmodifiableListView) return _messages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_messages);
}

@override@JsonKey(name: 'can_reply') final  bool canReply;
@override@JsonKey(name: 'can_close') final  bool canClose;
@override@JsonKey(name: 'can_transfer') final  bool canTransfer;
@override@JsonKey(name: 'last_message_at') final  DateTime? lastMessageAt;
@override@JsonKey(name: 'closed_at') final  DateTime? closedAt;
@override@JsonKey(name: 'closed_by') final  InternalPerson? closedBy;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of InternalTicket
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InternalTicketCopyWith<_InternalTicket> get copyWith => __$InternalTicketCopyWithImpl<_InternalTicket>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InternalTicketToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InternalTicket&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.title, title) || other.title == title)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.priorityLabel, priorityLabel) || other.priorityLabel == priorityLabel)&&(identical(other.category, category) || other.category == category)&&(identical(other.opener, opener) || other.opener == opener)&&(identical(other.assignee, assignee) || other.assignee == assignee)&&(identical(other.counterpart, counterpart) || other.counterpart == counterpart)&&(identical(other.iOpenedIt, iOpenedIt) || other.iOpenedIt == iOpenedIt)&&(identical(other.isParty, isParty) || other.isParty == isParty)&&(identical(other.customer, customer) || other.customer == customer)&&(identical(other.order, order) || other.order == order)&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount)&&(identical(other.counterpartReadUpTo, counterpartReadUpTo) || other.counterpartReadUpTo == counterpartReadUpTo)&&(identical(other.readUpTo, readUpTo) || other.readUpTo == readUpTo)&&(identical(other.awaitingMyReply, awaitingMyReply) || other.awaitingMyReply == awaitingMyReply)&&(identical(other.lastMessage, lastMessage) || other.lastMessage == lastMessage)&&const DeepCollectionEquality().equals(other._messages, _messages)&&(identical(other.canReply, canReply) || other.canReply == canReply)&&(identical(other.canClose, canClose) || other.canClose == canClose)&&(identical(other.canTransfer, canTransfer) || other.canTransfer == canTransfer)&&(identical(other.lastMessageAt, lastMessageAt) || other.lastMessageAt == lastMessageAt)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.closedBy, closedBy) || other.closedBy == closedBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,code,title,status,statusLabel,priority,priorityLabel,category,opener,assignee,counterpart,iOpenedIt,isParty,customer,order,unreadCount,counterpartReadUpTo,readUpTo,awaitingMyReply,lastMessage,const DeepCollectionEquality().hash(_messages),canReply,canClose,canTransfer,lastMessageAt,closedAt,closedBy,createdAt]);

@override
String toString() {
  return 'InternalTicket(id: $id, code: $code, title: $title, status: $status, statusLabel: $statusLabel, priority: $priority, priorityLabel: $priorityLabel, category: $category, opener: $opener, assignee: $assignee, counterpart: $counterpart, iOpenedIt: $iOpenedIt, isParty: $isParty, customer: $customer, order: $order, unreadCount: $unreadCount, counterpartReadUpTo: $counterpartReadUpTo, readUpTo: $readUpTo, awaitingMyReply: $awaitingMyReply, lastMessage: $lastMessage, messages: $messages, canReply: $canReply, canClose: $canClose, canTransfer: $canTransfer, lastMessageAt: $lastMessageAt, closedAt: $closedAt, closedBy: $closedBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$InternalTicketCopyWith<$Res> implements $InternalTicketCopyWith<$Res> {
  factory _$InternalTicketCopyWith(_InternalTicket value, $Res Function(_InternalTicket) _then) = __$InternalTicketCopyWithImpl;
@override @useResult
$Res call({
 int id, String code, String title,@JsonKey(unknownEnumValue: InternalTicketStatus.unknown) InternalTicketStatus status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(unknownEnumValue: InternalTicketPriority.unknown) InternalTicketPriority priority,@JsonKey(name: 'priority_label') String priorityLabel, InternalCategory? category, InternalPerson? opener, InternalPerson? assignee, InternalPerson? counterpart,@JsonKey(name: 'i_opened_it') bool iOpenedIt,@JsonKey(name: 'is_party') bool isParty, InternalCustomerRef? customer, InternalOrderRef? order,@JsonKey(name: 'unread_count') int unreadCount,@JsonKey(name: 'counterpart_read_up_to') int? counterpartReadUpTo,@JsonKey(name: 'read_up_to') InternalReadUpTo? readUpTo,@JsonKey(name: 'awaiting_my_reply') bool awaitingMyReply,@JsonKey(name: 'last_message') InternalLastMessage? lastMessage, List<InternalMessage> messages,@JsonKey(name: 'can_reply') bool canReply,@JsonKey(name: 'can_close') bool canClose,@JsonKey(name: 'can_transfer') bool canTransfer,@JsonKey(name: 'last_message_at') DateTime? lastMessageAt,@JsonKey(name: 'closed_at') DateTime? closedAt,@JsonKey(name: 'closed_by') InternalPerson? closedBy,@JsonKey(name: 'created_at') DateTime? createdAt
});


@override $InternalCategoryCopyWith<$Res>? get category;@override $InternalPersonCopyWith<$Res>? get opener;@override $InternalPersonCopyWith<$Res>? get assignee;@override $InternalPersonCopyWith<$Res>? get counterpart;@override $InternalCustomerRefCopyWith<$Res>? get customer;@override $InternalOrderRefCopyWith<$Res>? get order;@override $InternalReadUpToCopyWith<$Res>? get readUpTo;@override $InternalLastMessageCopyWith<$Res>? get lastMessage;@override $InternalPersonCopyWith<$Res>? get closedBy;

}
/// @nodoc
class __$InternalTicketCopyWithImpl<$Res>
    implements _$InternalTicketCopyWith<$Res> {
  __$InternalTicketCopyWithImpl(this._self, this._then);

  final _InternalTicket _self;
  final $Res Function(_InternalTicket) _then;

/// Create a copy of InternalTicket
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? title = null,Object? status = null,Object? statusLabel = null,Object? priority = null,Object? priorityLabel = null,Object? category = freezed,Object? opener = freezed,Object? assignee = freezed,Object? counterpart = freezed,Object? iOpenedIt = null,Object? isParty = null,Object? customer = freezed,Object? order = freezed,Object? unreadCount = null,Object? counterpartReadUpTo = freezed,Object? readUpTo = freezed,Object? awaitingMyReply = null,Object? lastMessage = freezed,Object? messages = null,Object? canReply = null,Object? canClose = null,Object? canTransfer = null,Object? lastMessageAt = freezed,Object? closedAt = freezed,Object? closedBy = freezed,Object? createdAt = freezed,}) {
  return _then(_InternalTicket(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as InternalTicketStatus,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as InternalTicketPriority,priorityLabel: null == priorityLabel ? _self.priorityLabel : priorityLabel // ignore: cast_nullable_to_non_nullable
as String,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as InternalCategory?,opener: freezed == opener ? _self.opener : opener // ignore: cast_nullable_to_non_nullable
as InternalPerson?,assignee: freezed == assignee ? _self.assignee : assignee // ignore: cast_nullable_to_non_nullable
as InternalPerson?,counterpart: freezed == counterpart ? _self.counterpart : counterpart // ignore: cast_nullable_to_non_nullable
as InternalPerson?,iOpenedIt: null == iOpenedIt ? _self.iOpenedIt : iOpenedIt // ignore: cast_nullable_to_non_nullable
as bool,isParty: null == isParty ? _self.isParty : isParty // ignore: cast_nullable_to_non_nullable
as bool,customer: freezed == customer ? _self.customer : customer // ignore: cast_nullable_to_non_nullable
as InternalCustomerRef?,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as InternalOrderRef?,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,counterpartReadUpTo: freezed == counterpartReadUpTo ? _self.counterpartReadUpTo : counterpartReadUpTo // ignore: cast_nullable_to_non_nullable
as int?,readUpTo: freezed == readUpTo ? _self.readUpTo : readUpTo // ignore: cast_nullable_to_non_nullable
as InternalReadUpTo?,awaitingMyReply: null == awaitingMyReply ? _self.awaitingMyReply : awaitingMyReply // ignore: cast_nullable_to_non_nullable
as bool,lastMessage: freezed == lastMessage ? _self.lastMessage : lastMessage // ignore: cast_nullable_to_non_nullable
as InternalLastMessage?,messages: null == messages ? _self._messages : messages // ignore: cast_nullable_to_non_nullable
as List<InternalMessage>,canReply: null == canReply ? _self.canReply : canReply // ignore: cast_nullable_to_non_nullable
as bool,canClose: null == canClose ? _self.canClose : canClose // ignore: cast_nullable_to_non_nullable
as bool,canTransfer: null == canTransfer ? _self.canTransfer : canTransfer // ignore: cast_nullable_to_non_nullable
as bool,lastMessageAt: freezed == lastMessageAt ? _self.lastMessageAt : lastMessageAt // ignore: cast_nullable_to_non_nullable
as DateTime?,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,closedBy: freezed == closedBy ? _self.closedBy : closedBy // ignore: cast_nullable_to_non_nullable
as InternalPerson?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of InternalTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InternalCategoryCopyWith<$Res>? get category {
    if (_self.category == null) {
    return null;
  }

  return $InternalCategoryCopyWith<$Res>(_self.category!, (value) {
    return _then(_self.copyWith(category: value));
  });
}/// Create a copy of InternalTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InternalPersonCopyWith<$Res>? get opener {
    if (_self.opener == null) {
    return null;
  }

  return $InternalPersonCopyWith<$Res>(_self.opener!, (value) {
    return _then(_self.copyWith(opener: value));
  });
}/// Create a copy of InternalTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InternalPersonCopyWith<$Res>? get assignee {
    if (_self.assignee == null) {
    return null;
  }

  return $InternalPersonCopyWith<$Res>(_self.assignee!, (value) {
    return _then(_self.copyWith(assignee: value));
  });
}/// Create a copy of InternalTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InternalPersonCopyWith<$Res>? get counterpart {
    if (_self.counterpart == null) {
    return null;
  }

  return $InternalPersonCopyWith<$Res>(_self.counterpart!, (value) {
    return _then(_self.copyWith(counterpart: value));
  });
}/// Create a copy of InternalTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InternalCustomerRefCopyWith<$Res>? get customer {
    if (_self.customer == null) {
    return null;
  }

  return $InternalCustomerRefCopyWith<$Res>(_self.customer!, (value) {
    return _then(_self.copyWith(customer: value));
  });
}/// Create a copy of InternalTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InternalOrderRefCopyWith<$Res>? get order {
    if (_self.order == null) {
    return null;
  }

  return $InternalOrderRefCopyWith<$Res>(_self.order!, (value) {
    return _then(_self.copyWith(order: value));
  });
}/// Create a copy of InternalTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InternalReadUpToCopyWith<$Res>? get readUpTo {
    if (_self.readUpTo == null) {
    return null;
  }

  return $InternalReadUpToCopyWith<$Res>(_self.readUpTo!, (value) {
    return _then(_self.copyWith(readUpTo: value));
  });
}/// Create a copy of InternalTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InternalLastMessageCopyWith<$Res>? get lastMessage {
    if (_self.lastMessage == null) {
    return null;
  }

  return $InternalLastMessageCopyWith<$Res>(_self.lastMessage!, (value) {
    return _then(_self.copyWith(lastMessage: value));
  });
}/// Create a copy of InternalTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InternalPersonCopyWith<$Res>? get closedBy {
    if (_self.closedBy == null) {
    return null;
  }

  return $InternalPersonCopyWith<$Res>(_self.closedBy!, (value) {
    return _then(_self.copyWith(closedBy: value));
  });
}
}


/// @nodoc
mixin _$InternalTicketsHome {

 List<InternalTicket> get tickets;@JsonKey(name: 'awaiting_my_reply') int get awaitingMyReply;@JsonKey(name: 'has_more') bool get hasMore;@JsonKey(name: 'total_open') int get totalOpen;@JsonKey(name: 'unread_tickets') int get unreadTickets;
/// Create a copy of InternalTicketsHome
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InternalTicketsHomeCopyWith<InternalTicketsHome> get copyWith => _$InternalTicketsHomeCopyWithImpl<InternalTicketsHome>(this as InternalTicketsHome, _$identity);

  /// Serializes this InternalTicketsHome to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InternalTicketsHome&&const DeepCollectionEquality().equals(other.tickets, tickets)&&(identical(other.awaitingMyReply, awaitingMyReply) || other.awaitingMyReply == awaitingMyReply)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.totalOpen, totalOpen) || other.totalOpen == totalOpen)&&(identical(other.unreadTickets, unreadTickets) || other.unreadTickets == unreadTickets));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(tickets),awaitingMyReply,hasMore,totalOpen,unreadTickets);

@override
String toString() {
  return 'InternalTicketsHome(tickets: $tickets, awaitingMyReply: $awaitingMyReply, hasMore: $hasMore, totalOpen: $totalOpen, unreadTickets: $unreadTickets)';
}


}

/// @nodoc
abstract mixin class $InternalTicketsHomeCopyWith<$Res>  {
  factory $InternalTicketsHomeCopyWith(InternalTicketsHome value, $Res Function(InternalTicketsHome) _then) = _$InternalTicketsHomeCopyWithImpl;
@useResult
$Res call({
 List<InternalTicket> tickets,@JsonKey(name: 'awaiting_my_reply') int awaitingMyReply,@JsonKey(name: 'has_more') bool hasMore,@JsonKey(name: 'total_open') int totalOpen,@JsonKey(name: 'unread_tickets') int unreadTickets
});




}
/// @nodoc
class _$InternalTicketsHomeCopyWithImpl<$Res>
    implements $InternalTicketsHomeCopyWith<$Res> {
  _$InternalTicketsHomeCopyWithImpl(this._self, this._then);

  final InternalTicketsHome _self;
  final $Res Function(InternalTicketsHome) _then;

/// Create a copy of InternalTicketsHome
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tickets = null,Object? awaitingMyReply = null,Object? hasMore = null,Object? totalOpen = null,Object? unreadTickets = null,}) {
  return _then(_self.copyWith(
tickets: null == tickets ? _self.tickets : tickets // ignore: cast_nullable_to_non_nullable
as List<InternalTicket>,awaitingMyReply: null == awaitingMyReply ? _self.awaitingMyReply : awaitingMyReply // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,totalOpen: null == totalOpen ? _self.totalOpen : totalOpen // ignore: cast_nullable_to_non_nullable
as int,unreadTickets: null == unreadTickets ? _self.unreadTickets : unreadTickets // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [InternalTicketsHome].
extension InternalTicketsHomePatterns on InternalTicketsHome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InternalTicketsHome value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InternalTicketsHome() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InternalTicketsHome value)  $default,){
final _that = this;
switch (_that) {
case _InternalTicketsHome():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InternalTicketsHome value)?  $default,){
final _that = this;
switch (_that) {
case _InternalTicketsHome() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<InternalTicket> tickets, @JsonKey(name: 'awaiting_my_reply')  int awaitingMyReply, @JsonKey(name: 'has_more')  bool hasMore, @JsonKey(name: 'total_open')  int totalOpen, @JsonKey(name: 'unread_tickets')  int unreadTickets)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InternalTicketsHome() when $default != null:
return $default(_that.tickets,_that.awaitingMyReply,_that.hasMore,_that.totalOpen,_that.unreadTickets);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<InternalTicket> tickets, @JsonKey(name: 'awaiting_my_reply')  int awaitingMyReply, @JsonKey(name: 'has_more')  bool hasMore, @JsonKey(name: 'total_open')  int totalOpen, @JsonKey(name: 'unread_tickets')  int unreadTickets)  $default,) {final _that = this;
switch (_that) {
case _InternalTicketsHome():
return $default(_that.tickets,_that.awaitingMyReply,_that.hasMore,_that.totalOpen,_that.unreadTickets);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<InternalTicket> tickets, @JsonKey(name: 'awaiting_my_reply')  int awaitingMyReply, @JsonKey(name: 'has_more')  bool hasMore, @JsonKey(name: 'total_open')  int totalOpen, @JsonKey(name: 'unread_tickets')  int unreadTickets)?  $default,) {final _that = this;
switch (_that) {
case _InternalTicketsHome() when $default != null:
return $default(_that.tickets,_that.awaitingMyReply,_that.hasMore,_that.totalOpen,_that.unreadTickets);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InternalTicketsHome implements InternalTicketsHome {
  const _InternalTicketsHome({final  List<InternalTicket> tickets = const <InternalTicket>[], @JsonKey(name: 'awaiting_my_reply') this.awaitingMyReply = 0, @JsonKey(name: 'has_more') this.hasMore = false, @JsonKey(name: 'total_open') this.totalOpen = 0, @JsonKey(name: 'unread_tickets') this.unreadTickets = 0}): _tickets = tickets;
  factory _InternalTicketsHome.fromJson(Map<String, dynamic> json) => _$InternalTicketsHomeFromJson(json);

 final  List<InternalTicket> _tickets;
@override@JsonKey() List<InternalTicket> get tickets {
  if (_tickets is EqualUnmodifiableListView) return _tickets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tickets);
}

@override@JsonKey(name: 'awaiting_my_reply') final  int awaitingMyReply;
@override@JsonKey(name: 'has_more') final  bool hasMore;
@override@JsonKey(name: 'total_open') final  int totalOpen;
@override@JsonKey(name: 'unread_tickets') final  int unreadTickets;

/// Create a copy of InternalTicketsHome
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InternalTicketsHomeCopyWith<_InternalTicketsHome> get copyWith => __$InternalTicketsHomeCopyWithImpl<_InternalTicketsHome>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InternalTicketsHomeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InternalTicketsHome&&const DeepCollectionEquality().equals(other._tickets, _tickets)&&(identical(other.awaitingMyReply, awaitingMyReply) || other.awaitingMyReply == awaitingMyReply)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.totalOpen, totalOpen) || other.totalOpen == totalOpen)&&(identical(other.unreadTickets, unreadTickets) || other.unreadTickets == unreadTickets));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_tickets),awaitingMyReply,hasMore,totalOpen,unreadTickets);

@override
String toString() {
  return 'InternalTicketsHome(tickets: $tickets, awaitingMyReply: $awaitingMyReply, hasMore: $hasMore, totalOpen: $totalOpen, unreadTickets: $unreadTickets)';
}


}

/// @nodoc
abstract mixin class _$InternalTicketsHomeCopyWith<$Res> implements $InternalTicketsHomeCopyWith<$Res> {
  factory _$InternalTicketsHomeCopyWith(_InternalTicketsHome value, $Res Function(_InternalTicketsHome) _then) = __$InternalTicketsHomeCopyWithImpl;
@override @useResult
$Res call({
 List<InternalTicket> tickets,@JsonKey(name: 'awaiting_my_reply') int awaitingMyReply,@JsonKey(name: 'has_more') bool hasMore,@JsonKey(name: 'total_open') int totalOpen,@JsonKey(name: 'unread_tickets') int unreadTickets
});




}
/// @nodoc
class __$InternalTicketsHomeCopyWithImpl<$Res>
    implements _$InternalTicketsHomeCopyWith<$Res> {
  __$InternalTicketsHomeCopyWithImpl(this._self, this._then);

  final _InternalTicketsHome _self;
  final $Res Function(_InternalTicketsHome) _then;

/// Create a copy of InternalTicketsHome
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tickets = null,Object? awaitingMyReply = null,Object? hasMore = null,Object? totalOpen = null,Object? unreadTickets = null,}) {
  return _then(_InternalTicketsHome(
tickets: null == tickets ? _self._tickets : tickets // ignore: cast_nullable_to_non_nullable
as List<InternalTicket>,awaitingMyReply: null == awaitingMyReply ? _self.awaitingMyReply : awaitingMyReply // ignore: cast_nullable_to_non_nullable
as int,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,totalOpen: null == totalOpen ? _self.totalOpen : totalOpen // ignore: cast_nullable_to_non_nullable
as int,unreadTickets: null == unreadTickets ? _self.unreadTickets : unreadTickets // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$Colleague {

 int get id; String get name;@JsonKey(name: 'employee_code') String? get employeeCode; List<String> get roles;@JsonKey(name: 'open_tickets_with_me') int get openTicketsWithMe;
/// Create a copy of Colleague
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ColleagueCopyWith<Colleague> get copyWith => _$ColleagueCopyWithImpl<Colleague>(this as Colleague, _$identity);

  /// Serializes this Colleague to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Colleague&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.employeeCode, employeeCode) || other.employeeCode == employeeCode)&&const DeepCollectionEquality().equals(other.roles, roles)&&(identical(other.openTicketsWithMe, openTicketsWithMe) || other.openTicketsWithMe == openTicketsWithMe));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,employeeCode,const DeepCollectionEquality().hash(roles),openTicketsWithMe);

@override
String toString() {
  return 'Colleague(id: $id, name: $name, employeeCode: $employeeCode, roles: $roles, openTicketsWithMe: $openTicketsWithMe)';
}


}

/// @nodoc
abstract mixin class $ColleagueCopyWith<$Res>  {
  factory $ColleagueCopyWith(Colleague value, $Res Function(Colleague) _then) = _$ColleagueCopyWithImpl;
@useResult
$Res call({
 int id, String name,@JsonKey(name: 'employee_code') String? employeeCode, List<String> roles,@JsonKey(name: 'open_tickets_with_me') int openTicketsWithMe
});




}
/// @nodoc
class _$ColleagueCopyWithImpl<$Res>
    implements $ColleagueCopyWith<$Res> {
  _$ColleagueCopyWithImpl(this._self, this._then);

  final Colleague _self;
  final $Res Function(Colleague) _then;

/// Create a copy of Colleague
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? employeeCode = freezed,Object? roles = null,Object? openTicketsWithMe = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,employeeCode: freezed == employeeCode ? _self.employeeCode : employeeCode // ignore: cast_nullable_to_non_nullable
as String?,roles: null == roles ? _self.roles : roles // ignore: cast_nullable_to_non_nullable
as List<String>,openTicketsWithMe: null == openTicketsWithMe ? _self.openTicketsWithMe : openTicketsWithMe // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Colleague].
extension ColleaguePatterns on Colleague {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Colleague value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Colleague() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Colleague value)  $default,){
final _that = this;
switch (_that) {
case _Colleague():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Colleague value)?  $default,){
final _that = this;
switch (_that) {
case _Colleague() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'employee_code')  String? employeeCode,  List<String> roles, @JsonKey(name: 'open_tickets_with_me')  int openTicketsWithMe)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Colleague() when $default != null:
return $default(_that.id,_that.name,_that.employeeCode,_that.roles,_that.openTicketsWithMe);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name, @JsonKey(name: 'employee_code')  String? employeeCode,  List<String> roles, @JsonKey(name: 'open_tickets_with_me')  int openTicketsWithMe)  $default,) {final _that = this;
switch (_that) {
case _Colleague():
return $default(_that.id,_that.name,_that.employeeCode,_that.roles,_that.openTicketsWithMe);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name, @JsonKey(name: 'employee_code')  String? employeeCode,  List<String> roles, @JsonKey(name: 'open_tickets_with_me')  int openTicketsWithMe)?  $default,) {final _that = this;
switch (_that) {
case _Colleague() when $default != null:
return $default(_that.id,_that.name,_that.employeeCode,_that.roles,_that.openTicketsWithMe);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Colleague implements Colleague {
  const _Colleague({required this.id, required this.name, @JsonKey(name: 'employee_code') this.employeeCode, final  List<String> roles = const <String>[], @JsonKey(name: 'open_tickets_with_me') this.openTicketsWithMe = 0}): _roles = roles;
  factory _Colleague.fromJson(Map<String, dynamic> json) => _$ColleagueFromJson(json);

@override final  int id;
@override final  String name;
@override@JsonKey(name: 'employee_code') final  String? employeeCode;
 final  List<String> _roles;
@override@JsonKey() List<String> get roles {
  if (_roles is EqualUnmodifiableListView) return _roles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_roles);
}

@override@JsonKey(name: 'open_tickets_with_me') final  int openTicketsWithMe;

/// Create a copy of Colleague
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ColleagueCopyWith<_Colleague> get copyWith => __$ColleagueCopyWithImpl<_Colleague>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ColleagueToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Colleague&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.employeeCode, employeeCode) || other.employeeCode == employeeCode)&&const DeepCollectionEquality().equals(other._roles, _roles)&&(identical(other.openTicketsWithMe, openTicketsWithMe) || other.openTicketsWithMe == openTicketsWithMe));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,employeeCode,const DeepCollectionEquality().hash(_roles),openTicketsWithMe);

@override
String toString() {
  return 'Colleague(id: $id, name: $name, employeeCode: $employeeCode, roles: $roles, openTicketsWithMe: $openTicketsWithMe)';
}


}

/// @nodoc
abstract mixin class _$ColleagueCopyWith<$Res> implements $ColleagueCopyWith<$Res> {
  factory _$ColleagueCopyWith(_Colleague value, $Res Function(_Colleague) _then) = __$ColleagueCopyWithImpl;
@override @useResult
$Res call({
 int id, String name,@JsonKey(name: 'employee_code') String? employeeCode, List<String> roles,@JsonKey(name: 'open_tickets_with_me') int openTicketsWithMe
});




}
/// @nodoc
class __$ColleagueCopyWithImpl<$Res>
    implements _$ColleagueCopyWith<$Res> {
  __$ColleagueCopyWithImpl(this._self, this._then);

  final _Colleague _self;
  final $Res Function(_Colleague) _then;

/// Create a copy of Colleague
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? employeeCode = freezed,Object? roles = null,Object? openTicketsWithMe = null,}) {
  return _then(_Colleague(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,employeeCode: freezed == employeeCode ? _self.employeeCode : employeeCode // ignore: cast_nullable_to_non_nullable
as String?,roles: null == roles ? _self._roles : roles // ignore: cast_nullable_to_non_nullable
as List<String>,openTicketsWithMe: null == openTicketsWithMe ? _self.openTicketsWithMe : openTicketsWithMe // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$InternalTicketChange {

/// `message_posted` · `message_edited` · `message_retracted` · `read` · `closed` · `transferred`.
 String get change; InternalTicket get ticket; InternalMessage? get message;
/// Create a copy of InternalTicketChange
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InternalTicketChangeCopyWith<InternalTicketChange> get copyWith => _$InternalTicketChangeCopyWithImpl<InternalTicketChange>(this as InternalTicketChange, _$identity);

  /// Serializes this InternalTicketChange to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InternalTicketChange&&(identical(other.change, change) || other.change == change)&&(identical(other.ticket, ticket) || other.ticket == ticket)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,change,ticket,message);

@override
String toString() {
  return 'InternalTicketChange(change: $change, ticket: $ticket, message: $message)';
}


}

/// @nodoc
abstract mixin class $InternalTicketChangeCopyWith<$Res>  {
  factory $InternalTicketChangeCopyWith(InternalTicketChange value, $Res Function(InternalTicketChange) _then) = _$InternalTicketChangeCopyWithImpl;
@useResult
$Res call({
 String change, InternalTicket ticket, InternalMessage? message
});


$InternalTicketCopyWith<$Res> get ticket;$InternalMessageCopyWith<$Res>? get message;

}
/// @nodoc
class _$InternalTicketChangeCopyWithImpl<$Res>
    implements $InternalTicketChangeCopyWith<$Res> {
  _$InternalTicketChangeCopyWithImpl(this._self, this._then);

  final InternalTicketChange _self;
  final $Res Function(InternalTicketChange) _then;

/// Create a copy of InternalTicketChange
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? change = null,Object? ticket = null,Object? message = freezed,}) {
  return _then(_self.copyWith(
change: null == change ? _self.change : change // ignore: cast_nullable_to_non_nullable
as String,ticket: null == ticket ? _self.ticket : ticket // ignore: cast_nullable_to_non_nullable
as InternalTicket,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as InternalMessage?,
  ));
}
/// Create a copy of InternalTicketChange
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InternalTicketCopyWith<$Res> get ticket {
  
  return $InternalTicketCopyWith<$Res>(_self.ticket, (value) {
    return _then(_self.copyWith(ticket: value));
  });
}/// Create a copy of InternalTicketChange
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InternalMessageCopyWith<$Res>? get message {
    if (_self.message == null) {
    return null;
  }

  return $InternalMessageCopyWith<$Res>(_self.message!, (value) {
    return _then(_self.copyWith(message: value));
  });
}
}


/// Adds pattern-matching-related methods to [InternalTicketChange].
extension InternalTicketChangePatterns on InternalTicketChange {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _InternalTicketChange value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _InternalTicketChange() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _InternalTicketChange value)  $default,){
final _that = this;
switch (_that) {
case _InternalTicketChange():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _InternalTicketChange value)?  $default,){
final _that = this;
switch (_that) {
case _InternalTicketChange() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String change,  InternalTicket ticket,  InternalMessage? message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _InternalTicketChange() when $default != null:
return $default(_that.change,_that.ticket,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String change,  InternalTicket ticket,  InternalMessage? message)  $default,) {final _that = this;
switch (_that) {
case _InternalTicketChange():
return $default(_that.change,_that.ticket,_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String change,  InternalTicket ticket,  InternalMessage? message)?  $default,) {final _that = this;
switch (_that) {
case _InternalTicketChange() when $default != null:
return $default(_that.change,_that.ticket,_that.message);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _InternalTicketChange implements InternalTicketChange {
  const _InternalTicketChange({required this.change, required this.ticket, this.message});
  factory _InternalTicketChange.fromJson(Map<String, dynamic> json) => _$InternalTicketChangeFromJson(json);

/// `message_posted` · `message_edited` · `message_retracted` · `read` · `closed` · `transferred`.
@override final  String change;
@override final  InternalTicket ticket;
@override final  InternalMessage? message;

/// Create a copy of InternalTicketChange
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$InternalTicketChangeCopyWith<_InternalTicketChange> get copyWith => __$InternalTicketChangeCopyWithImpl<_InternalTicketChange>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$InternalTicketChangeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _InternalTicketChange&&(identical(other.change, change) || other.change == change)&&(identical(other.ticket, ticket) || other.ticket == ticket)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,change,ticket,message);

@override
String toString() {
  return 'InternalTicketChange(change: $change, ticket: $ticket, message: $message)';
}


}

/// @nodoc
abstract mixin class _$InternalTicketChangeCopyWith<$Res> implements $InternalTicketChangeCopyWith<$Res> {
  factory _$InternalTicketChangeCopyWith(_InternalTicketChange value, $Res Function(_InternalTicketChange) _then) = __$InternalTicketChangeCopyWithImpl;
@override @useResult
$Res call({
 String change, InternalTicket ticket, InternalMessage? message
});


@override $InternalTicketCopyWith<$Res> get ticket;@override $InternalMessageCopyWith<$Res>? get message;

}
/// @nodoc
class __$InternalTicketChangeCopyWithImpl<$Res>
    implements _$InternalTicketChangeCopyWith<$Res> {
  __$InternalTicketChangeCopyWithImpl(this._self, this._then);

  final _InternalTicketChange _self;
  final $Res Function(_InternalTicketChange) _then;

/// Create a copy of InternalTicketChange
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? change = null,Object? ticket = null,Object? message = freezed,}) {
  return _then(_InternalTicketChange(
change: null == change ? _self.change : change // ignore: cast_nullable_to_non_nullable
as String,ticket: null == ticket ? _self.ticket : ticket // ignore: cast_nullable_to_non_nullable
as InternalTicket,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as InternalMessage?,
  ));
}

/// Create a copy of InternalTicketChange
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InternalTicketCopyWith<$Res> get ticket {
  
  return $InternalTicketCopyWith<$Res>(_self.ticket, (value) {
    return _then(_self.copyWith(ticket: value));
  });
}/// Create a copy of InternalTicketChange
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InternalMessageCopyWith<$Res>? get message {
    if (_self.message == null) {
    return null;
  }

  return $InternalMessageCopyWith<$Res>(_self.message!, (value) {
    return _then(_self.copyWith(message: value));
  });
}
}

// dart format on
