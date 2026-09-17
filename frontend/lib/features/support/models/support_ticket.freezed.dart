// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'support_ticket.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TicketCustomer {

 int get id; String? get code; String? get name; String? get phone;
/// Create a copy of TicketCustomer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TicketCustomerCopyWith<TicketCustomer> get copyWith => _$TicketCustomerCopyWithImpl<TicketCustomer>(this as TicketCustomer, _$identity);

  /// Serializes this TicketCustomer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TicketCustomer&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name,phone);

@override
String toString() {
  return 'TicketCustomer(id: $id, code: $code, name: $name, phone: $phone)';
}


}

/// @nodoc
abstract mixin class $TicketCustomerCopyWith<$Res>  {
  factory $TicketCustomerCopyWith(TicketCustomer value, $Res Function(TicketCustomer) _then) = _$TicketCustomerCopyWithImpl;
@useResult
$Res call({
 int id, String? code, String? name, String? phone
});




}
/// @nodoc
class _$TicketCustomerCopyWithImpl<$Res>
    implements $TicketCustomerCopyWith<$Res> {
  _$TicketCustomerCopyWithImpl(this._self, this._then);

  final TicketCustomer _self;
  final $Res Function(TicketCustomer) _then;

/// Create a copy of TicketCustomer
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


/// Adds pattern-matching-related methods to [TicketCustomer].
extension TicketCustomerPatterns on TicketCustomer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TicketCustomer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TicketCustomer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TicketCustomer value)  $default,){
final _that = this;
switch (_that) {
case _TicketCustomer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TicketCustomer value)?  $default,){
final _that = this;
switch (_that) {
case _TicketCustomer() when $default != null:
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
case _TicketCustomer() when $default != null:
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
case _TicketCustomer():
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
case _TicketCustomer() when $default != null:
return $default(_that.id,_that.code,_that.name,_that.phone);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TicketCustomer implements TicketCustomer {
  const _TicketCustomer({required this.id, this.code, this.name, this.phone});
  factory _TicketCustomer.fromJson(Map<String, dynamic> json) => _$TicketCustomerFromJson(json);

@override final  int id;
@override final  String? code;
@override final  String? name;
@override final  String? phone;

/// Create a copy of TicketCustomer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TicketCustomerCopyWith<_TicketCustomer> get copyWith => __$TicketCustomerCopyWithImpl<_TicketCustomer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TicketCustomerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TicketCustomer&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.name, name) || other.name == name)&&(identical(other.phone, phone) || other.phone == phone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,name,phone);

@override
String toString() {
  return 'TicketCustomer(id: $id, code: $code, name: $name, phone: $phone)';
}


}

/// @nodoc
abstract mixin class _$TicketCustomerCopyWith<$Res> implements $TicketCustomerCopyWith<$Res> {
  factory _$TicketCustomerCopyWith(_TicketCustomer value, $Res Function(_TicketCustomer) _then) = __$TicketCustomerCopyWithImpl;
@override @useResult
$Res call({
 int id, String? code, String? name, String? phone
});




}
/// @nodoc
class __$TicketCustomerCopyWithImpl<$Res>
    implements _$TicketCustomerCopyWith<$Res> {
  __$TicketCustomerCopyWithImpl(this._self, this._then);

  final _TicketCustomer _self;
  final $Res Function(_TicketCustomer) _then;

/// Create a copy of TicketCustomer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = freezed,Object? name = freezed,Object? phone = freezed,}) {
  return _then(_TicketCustomer(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: freezed == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String?,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$TicketOrderRef {

 int get id; String get code;
/// Create a copy of TicketOrderRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TicketOrderRefCopyWith<TicketOrderRef> get copyWith => _$TicketOrderRefCopyWithImpl<TicketOrderRef>(this as TicketOrderRef, _$identity);

  /// Serializes this TicketOrderRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TicketOrderRef&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code);

@override
String toString() {
  return 'TicketOrderRef(id: $id, code: $code)';
}


}

/// @nodoc
abstract mixin class $TicketOrderRefCopyWith<$Res>  {
  factory $TicketOrderRefCopyWith(TicketOrderRef value, $Res Function(TicketOrderRef) _then) = _$TicketOrderRefCopyWithImpl;
@useResult
$Res call({
 int id, String code
});




}
/// @nodoc
class _$TicketOrderRefCopyWithImpl<$Res>
    implements $TicketOrderRefCopyWith<$Res> {
  _$TicketOrderRefCopyWithImpl(this._self, this._then);

  final TicketOrderRef _self;
  final $Res Function(TicketOrderRef) _then;

/// Create a copy of TicketOrderRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TicketOrderRef].
extension TicketOrderRefPatterns on TicketOrderRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TicketOrderRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TicketOrderRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TicketOrderRef value)  $default,){
final _that = this;
switch (_that) {
case _TicketOrderRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TicketOrderRef value)?  $default,){
final _that = this;
switch (_that) {
case _TicketOrderRef() when $default != null:
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
case _TicketOrderRef() when $default != null:
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
case _TicketOrderRef():
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
case _TicketOrderRef() when $default != null:
return $default(_that.id,_that.code);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TicketOrderRef implements TicketOrderRef {
  const _TicketOrderRef({required this.id, required this.code});
  factory _TicketOrderRef.fromJson(Map<String, dynamic> json) => _$TicketOrderRefFromJson(json);

@override final  int id;
@override final  String code;

/// Create a copy of TicketOrderRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TicketOrderRefCopyWith<_TicketOrderRef> get copyWith => __$TicketOrderRefCopyWithImpl<_TicketOrderRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TicketOrderRefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TicketOrderRef&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code);

@override
String toString() {
  return 'TicketOrderRef(id: $id, code: $code)';
}


}

/// @nodoc
abstract mixin class _$TicketOrderRefCopyWith<$Res> implements $TicketOrderRefCopyWith<$Res> {
  factory _$TicketOrderRefCopyWith(_TicketOrderRef value, $Res Function(_TicketOrderRef) _then) = __$TicketOrderRefCopyWithImpl;
@override @useResult
$Res call({
 int id, String code
});




}
/// @nodoc
class __$TicketOrderRefCopyWithImpl<$Res>
    implements _$TicketOrderRefCopyWith<$Res> {
  __$TicketOrderRefCopyWithImpl(this._self, this._then);

  final _TicketOrderRef _self;
  final $Res Function(_TicketOrderRef) _then;

/// Create a copy of TicketOrderRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,}) {
  return _then(_TicketOrderRef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$TicketAssignee {

 int get id; String? get name;
/// Create a copy of TicketAssignee
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TicketAssigneeCopyWith<TicketAssignee> get copyWith => _$TicketAssigneeCopyWithImpl<TicketAssignee>(this as TicketAssignee, _$identity);

  /// Serializes this TicketAssignee to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TicketAssignee&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'TicketAssignee(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $TicketAssigneeCopyWith<$Res>  {
  factory $TicketAssigneeCopyWith(TicketAssignee value, $Res Function(TicketAssignee) _then) = _$TicketAssigneeCopyWithImpl;
@useResult
$Res call({
 int id, String? name
});




}
/// @nodoc
class _$TicketAssigneeCopyWithImpl<$Res>
    implements $TicketAssigneeCopyWith<$Res> {
  _$TicketAssigneeCopyWithImpl(this._self, this._then);

  final TicketAssignee _self;
  final $Res Function(TicketAssignee) _then;

/// Create a copy of TicketAssignee
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TicketAssignee].
extension TicketAssigneePatterns on TicketAssignee {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TicketAssignee value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TicketAssignee() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TicketAssignee value)  $default,){
final _that = this;
switch (_that) {
case _TicketAssignee():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TicketAssignee value)?  $default,){
final _that = this;
switch (_that) {
case _TicketAssignee() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String? name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TicketAssignee() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String? name)  $default,) {final _that = this;
switch (_that) {
case _TicketAssignee():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String? name)?  $default,) {final _that = this;
switch (_that) {
case _TicketAssignee() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TicketAssignee implements TicketAssignee {
  const _TicketAssignee({required this.id, this.name});
  factory _TicketAssignee.fromJson(Map<String, dynamic> json) => _$TicketAssigneeFromJson(json);

@override final  int id;
@override final  String? name;

/// Create a copy of TicketAssignee
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TicketAssigneeCopyWith<_TicketAssignee> get copyWith => __$TicketAssigneeCopyWithImpl<_TicketAssignee>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TicketAssigneeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TicketAssignee&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'TicketAssignee(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$TicketAssigneeCopyWith<$Res> implements $TicketAssigneeCopyWith<$Res> {
  factory _$TicketAssigneeCopyWith(_TicketAssignee value, $Res Function(_TicketAssignee) _then) = __$TicketAssigneeCopyWithImpl;
@override @useResult
$Res call({
 int id, String? name
});




}
/// @nodoc
class __$TicketAssigneeCopyWithImpl<$Res>
    implements _$TicketAssigneeCopyWith<$Res> {
  __$TicketAssigneeCopyWithImpl(this._self, this._then);

  final _TicketAssignee _self;
  final $Res Function(_TicketAssignee) _then;

/// Create a copy of TicketAssignee
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,}) {
  return _then(_TicketAssignee(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$TicketMessage {

 int get id;@JsonKey(unknownEnumValue: MessageAuthor.unknown) MessageAuthor get from;/// **Named on this side, and null on the customer's.** «من ردّ عليه؟» is a question the shop
/// is entitled to ask of itself; the customer app is sent `me` or `support` and no name,
/// because a name there makes one person the target of a complaint about a decision the
/// business made.
@JsonKey(name: 'author_name') String? get authorName; String get body;@JsonKey(name: 'sent_at') DateTime? get sentAt;
/// Create a copy of TicketMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TicketMessageCopyWith<TicketMessage> get copyWith => _$TicketMessageCopyWithImpl<TicketMessage>(this as TicketMessage, _$identity);

  /// Serializes this TicketMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TicketMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.from, from) || other.from == from)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.body, body) || other.body == body)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,from,authorName,body,sentAt);

@override
String toString() {
  return 'TicketMessage(id: $id, from: $from, authorName: $authorName, body: $body, sentAt: $sentAt)';
}


}

/// @nodoc
abstract mixin class $TicketMessageCopyWith<$Res>  {
  factory $TicketMessageCopyWith(TicketMessage value, $Res Function(TicketMessage) _then) = _$TicketMessageCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(unknownEnumValue: MessageAuthor.unknown) MessageAuthor from,@JsonKey(name: 'author_name') String? authorName, String body,@JsonKey(name: 'sent_at') DateTime? sentAt
});




}
/// @nodoc
class _$TicketMessageCopyWithImpl<$Res>
    implements $TicketMessageCopyWith<$Res> {
  _$TicketMessageCopyWithImpl(this._self, this._then);

  final TicketMessage _self;
  final $Res Function(TicketMessage) _then;

/// Create a copy of TicketMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? from = null,Object? authorName = freezed,Object? body = null,Object? sentAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as MessageAuthor,authorName: freezed == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String?,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,sentAt: freezed == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [TicketMessage].
extension TicketMessagePatterns on TicketMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TicketMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TicketMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TicketMessage value)  $default,){
final _that = this;
switch (_that) {
case _TicketMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TicketMessage value)?  $default,){
final _that = this;
switch (_that) {
case _TicketMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(unknownEnumValue: MessageAuthor.unknown)  MessageAuthor from, @JsonKey(name: 'author_name')  String? authorName,  String body, @JsonKey(name: 'sent_at')  DateTime? sentAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TicketMessage() when $default != null:
return $default(_that.id,_that.from,_that.authorName,_that.body,_that.sentAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(unknownEnumValue: MessageAuthor.unknown)  MessageAuthor from, @JsonKey(name: 'author_name')  String? authorName,  String body, @JsonKey(name: 'sent_at')  DateTime? sentAt)  $default,) {final _that = this;
switch (_that) {
case _TicketMessage():
return $default(_that.id,_that.from,_that.authorName,_that.body,_that.sentAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(unknownEnumValue: MessageAuthor.unknown)  MessageAuthor from, @JsonKey(name: 'author_name')  String? authorName,  String body, @JsonKey(name: 'sent_at')  DateTime? sentAt)?  $default,) {final _that = this;
switch (_that) {
case _TicketMessage() when $default != null:
return $default(_that.id,_that.from,_that.authorName,_that.body,_that.sentAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TicketMessage implements TicketMessage {
  const _TicketMessage({required this.id, @JsonKey(unknownEnumValue: MessageAuthor.unknown) this.from = MessageAuthor.unknown, @JsonKey(name: 'author_name') this.authorName, required this.body, @JsonKey(name: 'sent_at') this.sentAt});
  factory _TicketMessage.fromJson(Map<String, dynamic> json) => _$TicketMessageFromJson(json);

@override final  int id;
@override@JsonKey(unknownEnumValue: MessageAuthor.unknown) final  MessageAuthor from;
/// **Named on this side, and null on the customer's.** «من ردّ عليه؟» is a question the shop
/// is entitled to ask of itself; the customer app is sent `me` or `support` and no name,
/// because a name there makes one person the target of a complaint about a decision the
/// business made.
@override@JsonKey(name: 'author_name') final  String? authorName;
@override final  String body;
@override@JsonKey(name: 'sent_at') final  DateTime? sentAt;

/// Create a copy of TicketMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TicketMessageCopyWith<_TicketMessage> get copyWith => __$TicketMessageCopyWithImpl<_TicketMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TicketMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TicketMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.from, from) || other.from == from)&&(identical(other.authorName, authorName) || other.authorName == authorName)&&(identical(other.body, body) || other.body == body)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,from,authorName,body,sentAt);

@override
String toString() {
  return 'TicketMessage(id: $id, from: $from, authorName: $authorName, body: $body, sentAt: $sentAt)';
}


}

/// @nodoc
abstract mixin class _$TicketMessageCopyWith<$Res> implements $TicketMessageCopyWith<$Res> {
  factory _$TicketMessageCopyWith(_TicketMessage value, $Res Function(_TicketMessage) _then) = __$TicketMessageCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(unknownEnumValue: MessageAuthor.unknown) MessageAuthor from,@JsonKey(name: 'author_name') String? authorName, String body,@JsonKey(name: 'sent_at') DateTime? sentAt
});




}
/// @nodoc
class __$TicketMessageCopyWithImpl<$Res>
    implements _$TicketMessageCopyWith<$Res> {
  __$TicketMessageCopyWithImpl(this._self, this._then);

  final _TicketMessage _self;
  final $Res Function(_TicketMessage) _then;

/// Create a copy of TicketMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? from = null,Object? authorName = freezed,Object? body = null,Object? sentAt = freezed,}) {
  return _then(_TicketMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as MessageAuthor,authorName: freezed == authorName ? _self.authorName : authorName // ignore: cast_nullable_to_non_nullable
as String?,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,sentAt: freezed == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$SupportTicket {

 int get id; String get subject;@JsonKey(unknownEnumValue: TicketStatus.unknown) TicketStatus get status;/// **Always drawn instead of translating [status] here.** The Arabic travels with the value,
/// so a status added to the business appears without an app release.
@JsonKey(name: 'status_label') String get statusLabel; TicketCustomer? get customer; TicketOrderRef? get order;@JsonKey(name: 'assigned_to') int? get assignedTo; TicketAssignee? get assignee;/// The **desk's** unread count — the customer's messages this side has not read. Derived
/// from a read cursor on every request rather than stored, so it cannot drift.
@JsonKey(name: 'unread_count') int get unreadCount;/// Empty on the list endpoint, which does not load them; full on the thread endpoint.
 List<TicketMessage> get messages;@JsonKey(name: 'last_message_at') DateTime? get lastMessageAt;@JsonKey(name: 'closed_at') DateTime? get closedAt;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of SupportTicket
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportTicketCopyWith<SupportTicket> get copyWith => _$SupportTicketCopyWithImpl<SupportTicket>(this as SupportTicket, _$identity);

  /// Serializes this SupportTicket to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportTicket&&(identical(other.id, id) || other.id == id)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.customer, customer) || other.customer == customer)&&(identical(other.order, order) || other.order == order)&&(identical(other.assignedTo, assignedTo) || other.assignedTo == assignedTo)&&(identical(other.assignee, assignee) || other.assignee == assignee)&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount)&&const DeepCollectionEquality().equals(other.messages, messages)&&(identical(other.lastMessageAt, lastMessageAt) || other.lastMessageAt == lastMessageAt)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,subject,status,statusLabel,customer,order,assignedTo,assignee,unreadCount,const DeepCollectionEquality().hash(messages),lastMessageAt,closedAt,createdAt);

@override
String toString() {
  return 'SupportTicket(id: $id, subject: $subject, status: $status, statusLabel: $statusLabel, customer: $customer, order: $order, assignedTo: $assignedTo, assignee: $assignee, unreadCount: $unreadCount, messages: $messages, lastMessageAt: $lastMessageAt, closedAt: $closedAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $SupportTicketCopyWith<$Res>  {
  factory $SupportTicketCopyWith(SupportTicket value, $Res Function(SupportTicket) _then) = _$SupportTicketCopyWithImpl;
@useResult
$Res call({
 int id, String subject,@JsonKey(unknownEnumValue: TicketStatus.unknown) TicketStatus status,@JsonKey(name: 'status_label') String statusLabel, TicketCustomer? customer, TicketOrderRef? order,@JsonKey(name: 'assigned_to') int? assignedTo, TicketAssignee? assignee,@JsonKey(name: 'unread_count') int unreadCount, List<TicketMessage> messages,@JsonKey(name: 'last_message_at') DateTime? lastMessageAt,@JsonKey(name: 'closed_at') DateTime? closedAt,@JsonKey(name: 'created_at') DateTime? createdAt
});


$TicketCustomerCopyWith<$Res>? get customer;$TicketOrderRefCopyWith<$Res>? get order;$TicketAssigneeCopyWith<$Res>? get assignee;

}
/// @nodoc
class _$SupportTicketCopyWithImpl<$Res>
    implements $SupportTicketCopyWith<$Res> {
  _$SupportTicketCopyWithImpl(this._self, this._then);

  final SupportTicket _self;
  final $Res Function(SupportTicket) _then;

/// Create a copy of SupportTicket
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? subject = null,Object? status = null,Object? statusLabel = null,Object? customer = freezed,Object? order = freezed,Object? assignedTo = freezed,Object? assignee = freezed,Object? unreadCount = null,Object? messages = null,Object? lastMessageAt = freezed,Object? closedAt = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TicketStatus,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,customer: freezed == customer ? _self.customer : customer // ignore: cast_nullable_to_non_nullable
as TicketCustomer?,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as TicketOrderRef?,assignedTo: freezed == assignedTo ? _self.assignedTo : assignedTo // ignore: cast_nullable_to_non_nullable
as int?,assignee: freezed == assignee ? _self.assignee : assignee // ignore: cast_nullable_to_non_nullable
as TicketAssignee?,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,messages: null == messages ? _self.messages : messages // ignore: cast_nullable_to_non_nullable
as List<TicketMessage>,lastMessageAt: freezed == lastMessageAt ? _self.lastMessageAt : lastMessageAt // ignore: cast_nullable_to_non_nullable
as DateTime?,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of SupportTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TicketCustomerCopyWith<$Res>? get customer {
    if (_self.customer == null) {
    return null;
  }

  return $TicketCustomerCopyWith<$Res>(_self.customer!, (value) {
    return _then(_self.copyWith(customer: value));
  });
}/// Create a copy of SupportTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TicketOrderRefCopyWith<$Res>? get order {
    if (_self.order == null) {
    return null;
  }

  return $TicketOrderRefCopyWith<$Res>(_self.order!, (value) {
    return _then(_self.copyWith(order: value));
  });
}/// Create a copy of SupportTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TicketAssigneeCopyWith<$Res>? get assignee {
    if (_self.assignee == null) {
    return null;
  }

  return $TicketAssigneeCopyWith<$Res>(_self.assignee!, (value) {
    return _then(_self.copyWith(assignee: value));
  });
}
}


/// Adds pattern-matching-related methods to [SupportTicket].
extension SupportTicketPatterns on SupportTicket {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SupportTicket value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SupportTicket() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SupportTicket value)  $default,){
final _that = this;
switch (_that) {
case _SupportTicket():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SupportTicket value)?  $default,){
final _that = this;
switch (_that) {
case _SupportTicket() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String subject, @JsonKey(unknownEnumValue: TicketStatus.unknown)  TicketStatus status, @JsonKey(name: 'status_label')  String statusLabel,  TicketCustomer? customer,  TicketOrderRef? order, @JsonKey(name: 'assigned_to')  int? assignedTo,  TicketAssignee? assignee, @JsonKey(name: 'unread_count')  int unreadCount,  List<TicketMessage> messages, @JsonKey(name: 'last_message_at')  DateTime? lastMessageAt, @JsonKey(name: 'closed_at')  DateTime? closedAt, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SupportTicket() when $default != null:
return $default(_that.id,_that.subject,_that.status,_that.statusLabel,_that.customer,_that.order,_that.assignedTo,_that.assignee,_that.unreadCount,_that.messages,_that.lastMessageAt,_that.closedAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String subject, @JsonKey(unknownEnumValue: TicketStatus.unknown)  TicketStatus status, @JsonKey(name: 'status_label')  String statusLabel,  TicketCustomer? customer,  TicketOrderRef? order, @JsonKey(name: 'assigned_to')  int? assignedTo,  TicketAssignee? assignee, @JsonKey(name: 'unread_count')  int unreadCount,  List<TicketMessage> messages, @JsonKey(name: 'last_message_at')  DateTime? lastMessageAt, @JsonKey(name: 'closed_at')  DateTime? closedAt, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _SupportTicket():
return $default(_that.id,_that.subject,_that.status,_that.statusLabel,_that.customer,_that.order,_that.assignedTo,_that.assignee,_that.unreadCount,_that.messages,_that.lastMessageAt,_that.closedAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String subject, @JsonKey(unknownEnumValue: TicketStatus.unknown)  TicketStatus status, @JsonKey(name: 'status_label')  String statusLabel,  TicketCustomer? customer,  TicketOrderRef? order, @JsonKey(name: 'assigned_to')  int? assignedTo,  TicketAssignee? assignee, @JsonKey(name: 'unread_count')  int unreadCount,  List<TicketMessage> messages, @JsonKey(name: 'last_message_at')  DateTime? lastMessageAt, @JsonKey(name: 'closed_at')  DateTime? closedAt, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _SupportTicket() when $default != null:
return $default(_that.id,_that.subject,_that.status,_that.statusLabel,_that.customer,_that.order,_that.assignedTo,_that.assignee,_that.unreadCount,_that.messages,_that.lastMessageAt,_that.closedAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SupportTicket implements SupportTicket {
  const _SupportTicket({required this.id, required this.subject, @JsonKey(unknownEnumValue: TicketStatus.unknown) this.status = TicketStatus.unknown, @JsonKey(name: 'status_label') required this.statusLabel, this.customer, this.order, @JsonKey(name: 'assigned_to') this.assignedTo, this.assignee, @JsonKey(name: 'unread_count') this.unreadCount = 0, final  List<TicketMessage> messages = const <TicketMessage>[], @JsonKey(name: 'last_message_at') this.lastMessageAt, @JsonKey(name: 'closed_at') this.closedAt, @JsonKey(name: 'created_at') this.createdAt}): _messages = messages;
  factory _SupportTicket.fromJson(Map<String, dynamic> json) => _$SupportTicketFromJson(json);

@override final  int id;
@override final  String subject;
@override@JsonKey(unknownEnumValue: TicketStatus.unknown) final  TicketStatus status;
/// **Always drawn instead of translating [status] here.** The Arabic travels with the value,
/// so a status added to the business appears without an app release.
@override@JsonKey(name: 'status_label') final  String statusLabel;
@override final  TicketCustomer? customer;
@override final  TicketOrderRef? order;
@override@JsonKey(name: 'assigned_to') final  int? assignedTo;
@override final  TicketAssignee? assignee;
/// The **desk's** unread count — the customer's messages this side has not read. Derived
/// from a read cursor on every request rather than stored, so it cannot drift.
@override@JsonKey(name: 'unread_count') final  int unreadCount;
/// Empty on the list endpoint, which does not load them; full on the thread endpoint.
 final  List<TicketMessage> _messages;
/// Empty on the list endpoint, which does not load them; full on the thread endpoint.
@override@JsonKey() List<TicketMessage> get messages {
  if (_messages is EqualUnmodifiableListView) return _messages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_messages);
}

@override@JsonKey(name: 'last_message_at') final  DateTime? lastMessageAt;
@override@JsonKey(name: 'closed_at') final  DateTime? closedAt;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of SupportTicket
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SupportTicketCopyWith<_SupportTicket> get copyWith => __$SupportTicketCopyWithImpl<_SupportTicket>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SupportTicketToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SupportTicket&&(identical(other.id, id) || other.id == id)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.customer, customer) || other.customer == customer)&&(identical(other.order, order) || other.order == order)&&(identical(other.assignedTo, assignedTo) || other.assignedTo == assignedTo)&&(identical(other.assignee, assignee) || other.assignee == assignee)&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount)&&const DeepCollectionEquality().equals(other._messages, _messages)&&(identical(other.lastMessageAt, lastMessageAt) || other.lastMessageAt == lastMessageAt)&&(identical(other.closedAt, closedAt) || other.closedAt == closedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,subject,status,statusLabel,customer,order,assignedTo,assignee,unreadCount,const DeepCollectionEquality().hash(_messages),lastMessageAt,closedAt,createdAt);

@override
String toString() {
  return 'SupportTicket(id: $id, subject: $subject, status: $status, statusLabel: $statusLabel, customer: $customer, order: $order, assignedTo: $assignedTo, assignee: $assignee, unreadCount: $unreadCount, messages: $messages, lastMessageAt: $lastMessageAt, closedAt: $closedAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$SupportTicketCopyWith<$Res> implements $SupportTicketCopyWith<$Res> {
  factory _$SupportTicketCopyWith(_SupportTicket value, $Res Function(_SupportTicket) _then) = __$SupportTicketCopyWithImpl;
@override @useResult
$Res call({
 int id, String subject,@JsonKey(unknownEnumValue: TicketStatus.unknown) TicketStatus status,@JsonKey(name: 'status_label') String statusLabel, TicketCustomer? customer, TicketOrderRef? order,@JsonKey(name: 'assigned_to') int? assignedTo, TicketAssignee? assignee,@JsonKey(name: 'unread_count') int unreadCount, List<TicketMessage> messages,@JsonKey(name: 'last_message_at') DateTime? lastMessageAt,@JsonKey(name: 'closed_at') DateTime? closedAt,@JsonKey(name: 'created_at') DateTime? createdAt
});


@override $TicketCustomerCopyWith<$Res>? get customer;@override $TicketOrderRefCopyWith<$Res>? get order;@override $TicketAssigneeCopyWith<$Res>? get assignee;

}
/// @nodoc
class __$SupportTicketCopyWithImpl<$Res>
    implements _$SupportTicketCopyWith<$Res> {
  __$SupportTicketCopyWithImpl(this._self, this._then);

  final _SupportTicket _self;
  final $Res Function(_SupportTicket) _then;

/// Create a copy of SupportTicket
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? subject = null,Object? status = null,Object? statusLabel = null,Object? customer = freezed,Object? order = freezed,Object? assignedTo = freezed,Object? assignee = freezed,Object? unreadCount = null,Object? messages = null,Object? lastMessageAt = freezed,Object? closedAt = freezed,Object? createdAt = freezed,}) {
  return _then(_SupportTicket(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TicketStatus,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,customer: freezed == customer ? _self.customer : customer // ignore: cast_nullable_to_non_nullable
as TicketCustomer?,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as TicketOrderRef?,assignedTo: freezed == assignedTo ? _self.assignedTo : assignedTo // ignore: cast_nullable_to_non_nullable
as int?,assignee: freezed == assignee ? _self.assignee : assignee // ignore: cast_nullable_to_non_nullable
as TicketAssignee?,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,messages: null == messages ? _self._messages : messages // ignore: cast_nullable_to_non_nullable
as List<TicketMessage>,lastMessageAt: freezed == lastMessageAt ? _self.lastMessageAt : lastMessageAt // ignore: cast_nullable_to_non_nullable
as DateTime?,closedAt: freezed == closedAt ? _self.closedAt : closedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of SupportTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TicketCustomerCopyWith<$Res>? get customer {
    if (_self.customer == null) {
    return null;
  }

  return $TicketCustomerCopyWith<$Res>(_self.customer!, (value) {
    return _then(_self.copyWith(customer: value));
  });
}/// Create a copy of SupportTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TicketOrderRefCopyWith<$Res>? get order {
    if (_self.order == null) {
    return null;
  }

  return $TicketOrderRefCopyWith<$Res>(_self.order!, (value) {
    return _then(_self.copyWith(order: value));
  });
}/// Create a copy of SupportTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TicketAssigneeCopyWith<$Res>? get assignee {
    if (_self.assignee == null) {
    return null;
  }

  return $TicketAssigneeCopyWith<$Res>(_self.assignee!, (value) {
    return _then(_self.copyWith(assignee: value));
  });
}
}

// dart format on
