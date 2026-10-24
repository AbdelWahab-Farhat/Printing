// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'design_ticket_thread.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DesignThreadTicket {

 int get id; String get code; String get title;@JsonKey(unknownEnumValue: DesignTicketStatus.unknown) DesignTicketStatus get status;@JsonKey(name: 'status_label') String get statusLabel;@JsonKey(name: 'is_open') bool get isOpen;@JsonKey(name: 'customer_name') String? get customerName; ChatPerson? get requester;/// مَن يعمل عليها فعلاً — مَن قبلها، أو مَن أُسندت إليه قبل القبول.
 ChatPerson? get designer;
/// Create a copy of DesignThreadTicket
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DesignThreadTicketCopyWith<DesignThreadTicket> get copyWith => _$DesignThreadTicketCopyWithImpl<DesignThreadTicket>(this as DesignThreadTicket, _$identity);

  /// Serializes this DesignThreadTicket to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesignThreadTicket&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.title, title) || other.title == title)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.isOpen, isOpen) || other.isOpen == isOpen)&&(identical(other.customerName, customerName) || other.customerName == customerName)&&(identical(other.requester, requester) || other.requester == requester)&&(identical(other.designer, designer) || other.designer == designer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,title,status,statusLabel,isOpen,customerName,requester,designer);

@override
String toString() {
  return 'DesignThreadTicket(id: $id, code: $code, title: $title, status: $status, statusLabel: $statusLabel, isOpen: $isOpen, customerName: $customerName, requester: $requester, designer: $designer)';
}


}

/// @nodoc
abstract mixin class $DesignThreadTicketCopyWith<$Res>  {
  factory $DesignThreadTicketCopyWith(DesignThreadTicket value, $Res Function(DesignThreadTicket) _then) = _$DesignThreadTicketCopyWithImpl;
@useResult
$Res call({
 int id, String code, String title,@JsonKey(unknownEnumValue: DesignTicketStatus.unknown) DesignTicketStatus status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'is_open') bool isOpen,@JsonKey(name: 'customer_name') String? customerName, ChatPerson? requester, ChatPerson? designer
});


$ChatPersonCopyWith<$Res>? get requester;$ChatPersonCopyWith<$Res>? get designer;

}
/// @nodoc
class _$DesignThreadTicketCopyWithImpl<$Res>
    implements $DesignThreadTicketCopyWith<$Res> {
  _$DesignThreadTicketCopyWithImpl(this._self, this._then);

  final DesignThreadTicket _self;
  final $Res Function(DesignThreadTicket) _then;

/// Create a copy of DesignThreadTicket
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? code = null,Object? title = null,Object? status = null,Object? statusLabel = null,Object? isOpen = null,Object? customerName = freezed,Object? requester = freezed,Object? designer = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DesignTicketStatus,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,isOpen: null == isOpen ? _self.isOpen : isOpen // ignore: cast_nullable_to_non_nullable
as bool,customerName: freezed == customerName ? _self.customerName : customerName // ignore: cast_nullable_to_non_nullable
as String?,requester: freezed == requester ? _self.requester : requester // ignore: cast_nullable_to_non_nullable
as ChatPerson?,designer: freezed == designer ? _self.designer : designer // ignore: cast_nullable_to_non_nullable
as ChatPerson?,
  ));
}
/// Create a copy of DesignThreadTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatPersonCopyWith<$Res>? get requester {
    if (_self.requester == null) {
    return null;
  }

  return $ChatPersonCopyWith<$Res>(_self.requester!, (value) {
    return _then(_self.copyWith(requester: value));
  });
}/// Create a copy of DesignThreadTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatPersonCopyWith<$Res>? get designer {
    if (_self.designer == null) {
    return null;
  }

  return $ChatPersonCopyWith<$Res>(_self.designer!, (value) {
    return _then(_self.copyWith(designer: value));
  });
}
}


/// Adds pattern-matching-related methods to [DesignThreadTicket].
extension DesignThreadTicketPatterns on DesignThreadTicket {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DesignThreadTicket value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DesignThreadTicket() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DesignThreadTicket value)  $default,){
final _that = this;
switch (_that) {
case _DesignThreadTicket():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DesignThreadTicket value)?  $default,){
final _that = this;
switch (_that) {
case _DesignThreadTicket() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String code,  String title, @JsonKey(unknownEnumValue: DesignTicketStatus.unknown)  DesignTicketStatus status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'is_open')  bool isOpen, @JsonKey(name: 'customer_name')  String? customerName,  ChatPerson? requester,  ChatPerson? designer)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DesignThreadTicket() when $default != null:
return $default(_that.id,_that.code,_that.title,_that.status,_that.statusLabel,_that.isOpen,_that.customerName,_that.requester,_that.designer);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String code,  String title, @JsonKey(unknownEnumValue: DesignTicketStatus.unknown)  DesignTicketStatus status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'is_open')  bool isOpen, @JsonKey(name: 'customer_name')  String? customerName,  ChatPerson? requester,  ChatPerson? designer)  $default,) {final _that = this;
switch (_that) {
case _DesignThreadTicket():
return $default(_that.id,_that.code,_that.title,_that.status,_that.statusLabel,_that.isOpen,_that.customerName,_that.requester,_that.designer);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String code,  String title, @JsonKey(unknownEnumValue: DesignTicketStatus.unknown)  DesignTicketStatus status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'is_open')  bool isOpen, @JsonKey(name: 'customer_name')  String? customerName,  ChatPerson? requester,  ChatPerson? designer)?  $default,) {final _that = this;
switch (_that) {
case _DesignThreadTicket() when $default != null:
return $default(_that.id,_that.code,_that.title,_that.status,_that.statusLabel,_that.isOpen,_that.customerName,_that.requester,_that.designer);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DesignThreadTicket implements DesignThreadTicket {
  const _DesignThreadTicket({required this.id, required this.code, this.title = '', @JsonKey(unknownEnumValue: DesignTicketStatus.unknown) this.status = DesignTicketStatus.unknown, @JsonKey(name: 'status_label') this.statusLabel = '', @JsonKey(name: 'is_open') this.isOpen = true, @JsonKey(name: 'customer_name') this.customerName, this.requester, this.designer});
  factory _DesignThreadTicket.fromJson(Map<String, dynamic> json) => _$DesignThreadTicketFromJson(json);

@override final  int id;
@override final  String code;
@override@JsonKey() final  String title;
@override@JsonKey(unknownEnumValue: DesignTicketStatus.unknown) final  DesignTicketStatus status;
@override@JsonKey(name: 'status_label') final  String statusLabel;
@override@JsonKey(name: 'is_open') final  bool isOpen;
@override@JsonKey(name: 'customer_name') final  String? customerName;
@override final  ChatPerson? requester;
/// مَن يعمل عليها فعلاً — مَن قبلها، أو مَن أُسندت إليه قبل القبول.
@override final  ChatPerson? designer;

/// Create a copy of DesignThreadTicket
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DesignThreadTicketCopyWith<_DesignThreadTicket> get copyWith => __$DesignThreadTicketCopyWithImpl<_DesignThreadTicket>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DesignThreadTicketToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DesignThreadTicket&&(identical(other.id, id) || other.id == id)&&(identical(other.code, code) || other.code == code)&&(identical(other.title, title) || other.title == title)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.isOpen, isOpen) || other.isOpen == isOpen)&&(identical(other.customerName, customerName) || other.customerName == customerName)&&(identical(other.requester, requester) || other.requester == requester)&&(identical(other.designer, designer) || other.designer == designer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,code,title,status,statusLabel,isOpen,customerName,requester,designer);

@override
String toString() {
  return 'DesignThreadTicket(id: $id, code: $code, title: $title, status: $status, statusLabel: $statusLabel, isOpen: $isOpen, customerName: $customerName, requester: $requester, designer: $designer)';
}


}

/// @nodoc
abstract mixin class _$DesignThreadTicketCopyWith<$Res> implements $DesignThreadTicketCopyWith<$Res> {
  factory _$DesignThreadTicketCopyWith(_DesignThreadTicket value, $Res Function(_DesignThreadTicket) _then) = __$DesignThreadTicketCopyWithImpl;
@override @useResult
$Res call({
 int id, String code, String title,@JsonKey(unknownEnumValue: DesignTicketStatus.unknown) DesignTicketStatus status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'is_open') bool isOpen,@JsonKey(name: 'customer_name') String? customerName, ChatPerson? requester, ChatPerson? designer
});


@override $ChatPersonCopyWith<$Res>? get requester;@override $ChatPersonCopyWith<$Res>? get designer;

}
/// @nodoc
class __$DesignThreadTicketCopyWithImpl<$Res>
    implements _$DesignThreadTicketCopyWith<$Res> {
  __$DesignThreadTicketCopyWithImpl(this._self, this._then);

  final _DesignThreadTicket _self;
  final $Res Function(_DesignThreadTicket) _then;

/// Create a copy of DesignThreadTicket
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? code = null,Object? title = null,Object? status = null,Object? statusLabel = null,Object? isOpen = null,Object? customerName = freezed,Object? requester = freezed,Object? designer = freezed,}) {
  return _then(_DesignThreadTicket(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DesignTicketStatus,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,isOpen: null == isOpen ? _self.isOpen : isOpen // ignore: cast_nullable_to_non_nullable
as bool,customerName: freezed == customerName ? _self.customerName : customerName // ignore: cast_nullable_to_non_nullable
as String?,requester: freezed == requester ? _self.requester : requester // ignore: cast_nullable_to_non_nullable
as ChatPerson?,designer: freezed == designer ? _self.designer : designer // ignore: cast_nullable_to_non_nullable
as ChatPerson?,
  ));
}

/// Create a copy of DesignThreadTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatPersonCopyWith<$Res>? get requester {
    if (_self.requester == null) {
    return null;
  }

  return $ChatPersonCopyWith<$Res>(_self.requester!, (value) {
    return _then(_self.copyWith(requester: value));
  });
}/// Create a copy of DesignThreadTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatPersonCopyWith<$Res>? get designer {
    if (_self.designer == null) {
    return null;
  }

  return $ChatPersonCopyWith<$Res>(_self.designer!, (value) {
    return _then(_self.copyWith(designer: value));
  });
}
}


/// @nodoc
mixin _$DesignThreadReadUpTo {

 int? get requester; int? get designer;
/// Create a copy of DesignThreadReadUpTo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DesignThreadReadUpToCopyWith<DesignThreadReadUpTo> get copyWith => _$DesignThreadReadUpToCopyWithImpl<DesignThreadReadUpTo>(this as DesignThreadReadUpTo, _$identity);

  /// Serializes this DesignThreadReadUpTo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesignThreadReadUpTo&&(identical(other.requester, requester) || other.requester == requester)&&(identical(other.designer, designer) || other.designer == designer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,requester,designer);

@override
String toString() {
  return 'DesignThreadReadUpTo(requester: $requester, designer: $designer)';
}


}

/// @nodoc
abstract mixin class $DesignThreadReadUpToCopyWith<$Res>  {
  factory $DesignThreadReadUpToCopyWith(DesignThreadReadUpTo value, $Res Function(DesignThreadReadUpTo) _then) = _$DesignThreadReadUpToCopyWithImpl;
@useResult
$Res call({
 int? requester, int? designer
});




}
/// @nodoc
class _$DesignThreadReadUpToCopyWithImpl<$Res>
    implements $DesignThreadReadUpToCopyWith<$Res> {
  _$DesignThreadReadUpToCopyWithImpl(this._self, this._then);

  final DesignThreadReadUpTo _self;
  final $Res Function(DesignThreadReadUpTo) _then;

/// Create a copy of DesignThreadReadUpTo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? requester = freezed,Object? designer = freezed,}) {
  return _then(_self.copyWith(
requester: freezed == requester ? _self.requester : requester // ignore: cast_nullable_to_non_nullable
as int?,designer: freezed == designer ? _self.designer : designer // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [DesignThreadReadUpTo].
extension DesignThreadReadUpToPatterns on DesignThreadReadUpTo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DesignThreadReadUpTo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DesignThreadReadUpTo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DesignThreadReadUpTo value)  $default,){
final _that = this;
switch (_that) {
case _DesignThreadReadUpTo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DesignThreadReadUpTo value)?  $default,){
final _that = this;
switch (_that) {
case _DesignThreadReadUpTo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? requester,  int? designer)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DesignThreadReadUpTo() when $default != null:
return $default(_that.requester,_that.designer);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? requester,  int? designer)  $default,) {final _that = this;
switch (_that) {
case _DesignThreadReadUpTo():
return $default(_that.requester,_that.designer);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? requester,  int? designer)?  $default,) {final _that = this;
switch (_that) {
case _DesignThreadReadUpTo() when $default != null:
return $default(_that.requester,_that.designer);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DesignThreadReadUpTo implements DesignThreadReadUpTo {
  const _DesignThreadReadUpTo({this.requester, this.designer});
  factory _DesignThreadReadUpTo.fromJson(Map<String, dynamic> json) => _$DesignThreadReadUpToFromJson(json);

@override final  int? requester;
@override final  int? designer;

/// Create a copy of DesignThreadReadUpTo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DesignThreadReadUpToCopyWith<_DesignThreadReadUpTo> get copyWith => __$DesignThreadReadUpToCopyWithImpl<_DesignThreadReadUpTo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DesignThreadReadUpToToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DesignThreadReadUpTo&&(identical(other.requester, requester) || other.requester == requester)&&(identical(other.designer, designer) || other.designer == designer));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,requester,designer);

@override
String toString() {
  return 'DesignThreadReadUpTo(requester: $requester, designer: $designer)';
}


}

/// @nodoc
abstract mixin class _$DesignThreadReadUpToCopyWith<$Res> implements $DesignThreadReadUpToCopyWith<$Res> {
  factory _$DesignThreadReadUpToCopyWith(_DesignThreadReadUpTo value, $Res Function(_DesignThreadReadUpTo) _then) = __$DesignThreadReadUpToCopyWithImpl;
@override @useResult
$Res call({
 int? requester, int? designer
});




}
/// @nodoc
class __$DesignThreadReadUpToCopyWithImpl<$Res>
    implements _$DesignThreadReadUpToCopyWith<$Res> {
  __$DesignThreadReadUpToCopyWithImpl(this._self, this._then);

  final _DesignThreadReadUpTo _self;
  final $Res Function(_DesignThreadReadUpTo) _then;

/// Create a copy of DesignThreadReadUpTo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? requester = freezed,Object? designer = freezed,}) {
  return _then(_DesignThreadReadUpTo(
requester: freezed == requester ? _self.requester : requester // ignore: cast_nullable_to_non_nullable
as int?,designer: freezed == designer ? _self.designer : designer // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$DesignTicketThread {

 DesignThreadTicket get ticket; List<ChatMessage> get messages;/// الطالبُ أو المصمّم. مَن سواهما يقرأ ويكتب، ولا ✓✓ له ولا عليه.
@JsonKey(name: 'is_party') bool get isParty;@JsonKey(name: 'can_reply') bool get canReply;/// لماذا لا صندوق — «اعتُمد التصميم وأُغلقت المحادثة». `null` ما دامت مفتوحة.
@JsonKey(name: 'closed_note') String? get closedNote;@JsonKey(name: 'read_up_to') DesignThreadReadUpTo? get readUpTo;/// رسالتي مقروءةٌ (✓✓) إن كان رقمها لا يتجاوز هذا.
@JsonKey(name: 'counterpart_read_up_to') int? get counterpartReadUpTo;
/// Create a copy of DesignTicketThread
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DesignTicketThreadCopyWith<DesignTicketThread> get copyWith => _$DesignTicketThreadCopyWithImpl<DesignTicketThread>(this as DesignTicketThread, _$identity);

  /// Serializes this DesignTicketThread to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesignTicketThread&&(identical(other.ticket, ticket) || other.ticket == ticket)&&const DeepCollectionEquality().equals(other.messages, messages)&&(identical(other.isParty, isParty) || other.isParty == isParty)&&(identical(other.canReply, canReply) || other.canReply == canReply)&&(identical(other.closedNote, closedNote) || other.closedNote == closedNote)&&(identical(other.readUpTo, readUpTo) || other.readUpTo == readUpTo)&&(identical(other.counterpartReadUpTo, counterpartReadUpTo) || other.counterpartReadUpTo == counterpartReadUpTo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ticket,const DeepCollectionEquality().hash(messages),isParty,canReply,closedNote,readUpTo,counterpartReadUpTo);

@override
String toString() {
  return 'DesignTicketThread(ticket: $ticket, messages: $messages, isParty: $isParty, canReply: $canReply, closedNote: $closedNote, readUpTo: $readUpTo, counterpartReadUpTo: $counterpartReadUpTo)';
}


}

/// @nodoc
abstract mixin class $DesignTicketThreadCopyWith<$Res>  {
  factory $DesignTicketThreadCopyWith(DesignTicketThread value, $Res Function(DesignTicketThread) _then) = _$DesignTicketThreadCopyWithImpl;
@useResult
$Res call({
 DesignThreadTicket ticket, List<ChatMessage> messages,@JsonKey(name: 'is_party') bool isParty,@JsonKey(name: 'can_reply') bool canReply,@JsonKey(name: 'closed_note') String? closedNote,@JsonKey(name: 'read_up_to') DesignThreadReadUpTo? readUpTo,@JsonKey(name: 'counterpart_read_up_to') int? counterpartReadUpTo
});


$DesignThreadTicketCopyWith<$Res> get ticket;$DesignThreadReadUpToCopyWith<$Res>? get readUpTo;

}
/// @nodoc
class _$DesignTicketThreadCopyWithImpl<$Res>
    implements $DesignTicketThreadCopyWith<$Res> {
  _$DesignTicketThreadCopyWithImpl(this._self, this._then);

  final DesignTicketThread _self;
  final $Res Function(DesignTicketThread) _then;

/// Create a copy of DesignTicketThread
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ticket = null,Object? messages = null,Object? isParty = null,Object? canReply = null,Object? closedNote = freezed,Object? readUpTo = freezed,Object? counterpartReadUpTo = freezed,}) {
  return _then(_self.copyWith(
ticket: null == ticket ? _self.ticket : ticket // ignore: cast_nullable_to_non_nullable
as DesignThreadTicket,messages: null == messages ? _self.messages : messages // ignore: cast_nullable_to_non_nullable
as List<ChatMessage>,isParty: null == isParty ? _self.isParty : isParty // ignore: cast_nullable_to_non_nullable
as bool,canReply: null == canReply ? _self.canReply : canReply // ignore: cast_nullable_to_non_nullable
as bool,closedNote: freezed == closedNote ? _self.closedNote : closedNote // ignore: cast_nullable_to_non_nullable
as String?,readUpTo: freezed == readUpTo ? _self.readUpTo : readUpTo // ignore: cast_nullable_to_non_nullable
as DesignThreadReadUpTo?,counterpartReadUpTo: freezed == counterpartReadUpTo ? _self.counterpartReadUpTo : counterpartReadUpTo // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of DesignTicketThread
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DesignThreadTicketCopyWith<$Res> get ticket {
  
  return $DesignThreadTicketCopyWith<$Res>(_self.ticket, (value) {
    return _then(_self.copyWith(ticket: value));
  });
}/// Create a copy of DesignTicketThread
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DesignThreadReadUpToCopyWith<$Res>? get readUpTo {
    if (_self.readUpTo == null) {
    return null;
  }

  return $DesignThreadReadUpToCopyWith<$Res>(_self.readUpTo!, (value) {
    return _then(_self.copyWith(readUpTo: value));
  });
}
}


/// Adds pattern-matching-related methods to [DesignTicketThread].
extension DesignTicketThreadPatterns on DesignTicketThread {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DesignTicketThread value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DesignTicketThread() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DesignTicketThread value)  $default,){
final _that = this;
switch (_that) {
case _DesignTicketThread():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DesignTicketThread value)?  $default,){
final _that = this;
switch (_that) {
case _DesignTicketThread() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DesignThreadTicket ticket,  List<ChatMessage> messages, @JsonKey(name: 'is_party')  bool isParty, @JsonKey(name: 'can_reply')  bool canReply, @JsonKey(name: 'closed_note')  String? closedNote, @JsonKey(name: 'read_up_to')  DesignThreadReadUpTo? readUpTo, @JsonKey(name: 'counterpart_read_up_to')  int? counterpartReadUpTo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DesignTicketThread() when $default != null:
return $default(_that.ticket,_that.messages,_that.isParty,_that.canReply,_that.closedNote,_that.readUpTo,_that.counterpartReadUpTo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DesignThreadTicket ticket,  List<ChatMessage> messages, @JsonKey(name: 'is_party')  bool isParty, @JsonKey(name: 'can_reply')  bool canReply, @JsonKey(name: 'closed_note')  String? closedNote, @JsonKey(name: 'read_up_to')  DesignThreadReadUpTo? readUpTo, @JsonKey(name: 'counterpart_read_up_to')  int? counterpartReadUpTo)  $default,) {final _that = this;
switch (_that) {
case _DesignTicketThread():
return $default(_that.ticket,_that.messages,_that.isParty,_that.canReply,_that.closedNote,_that.readUpTo,_that.counterpartReadUpTo);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DesignThreadTicket ticket,  List<ChatMessage> messages, @JsonKey(name: 'is_party')  bool isParty, @JsonKey(name: 'can_reply')  bool canReply, @JsonKey(name: 'closed_note')  String? closedNote, @JsonKey(name: 'read_up_to')  DesignThreadReadUpTo? readUpTo, @JsonKey(name: 'counterpart_read_up_to')  int? counterpartReadUpTo)?  $default,) {final _that = this;
switch (_that) {
case _DesignTicketThread() when $default != null:
return $default(_that.ticket,_that.messages,_that.isParty,_that.canReply,_that.closedNote,_that.readUpTo,_that.counterpartReadUpTo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DesignTicketThread extends DesignTicketThread {
  const _DesignTicketThread({required this.ticket, final  List<ChatMessage> messages = const <ChatMessage>[], @JsonKey(name: 'is_party') this.isParty = false, @JsonKey(name: 'can_reply') this.canReply = false, @JsonKey(name: 'closed_note') this.closedNote, @JsonKey(name: 'read_up_to') this.readUpTo, @JsonKey(name: 'counterpart_read_up_to') this.counterpartReadUpTo}): _messages = messages,super._();
  factory _DesignTicketThread.fromJson(Map<String, dynamic> json) => _$DesignTicketThreadFromJson(json);

@override final  DesignThreadTicket ticket;
 final  List<ChatMessage> _messages;
@override@JsonKey() List<ChatMessage> get messages {
  if (_messages is EqualUnmodifiableListView) return _messages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_messages);
}

/// الطالبُ أو المصمّم. مَن سواهما يقرأ ويكتب، ولا ✓✓ له ولا عليه.
@override@JsonKey(name: 'is_party') final  bool isParty;
@override@JsonKey(name: 'can_reply') final  bool canReply;
/// لماذا لا صندوق — «اعتُمد التصميم وأُغلقت المحادثة». `null` ما دامت مفتوحة.
@override@JsonKey(name: 'closed_note') final  String? closedNote;
@override@JsonKey(name: 'read_up_to') final  DesignThreadReadUpTo? readUpTo;
/// رسالتي مقروءةٌ (✓✓) إن كان رقمها لا يتجاوز هذا.
@override@JsonKey(name: 'counterpart_read_up_to') final  int? counterpartReadUpTo;

/// Create a copy of DesignTicketThread
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DesignTicketThreadCopyWith<_DesignTicketThread> get copyWith => __$DesignTicketThreadCopyWithImpl<_DesignTicketThread>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DesignTicketThreadToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DesignTicketThread&&(identical(other.ticket, ticket) || other.ticket == ticket)&&const DeepCollectionEquality().equals(other._messages, _messages)&&(identical(other.isParty, isParty) || other.isParty == isParty)&&(identical(other.canReply, canReply) || other.canReply == canReply)&&(identical(other.closedNote, closedNote) || other.closedNote == closedNote)&&(identical(other.readUpTo, readUpTo) || other.readUpTo == readUpTo)&&(identical(other.counterpartReadUpTo, counterpartReadUpTo) || other.counterpartReadUpTo == counterpartReadUpTo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ticket,const DeepCollectionEquality().hash(_messages),isParty,canReply,closedNote,readUpTo,counterpartReadUpTo);

@override
String toString() {
  return 'DesignTicketThread(ticket: $ticket, messages: $messages, isParty: $isParty, canReply: $canReply, closedNote: $closedNote, readUpTo: $readUpTo, counterpartReadUpTo: $counterpartReadUpTo)';
}


}

/// @nodoc
abstract mixin class _$DesignTicketThreadCopyWith<$Res> implements $DesignTicketThreadCopyWith<$Res> {
  factory _$DesignTicketThreadCopyWith(_DesignTicketThread value, $Res Function(_DesignTicketThread) _then) = __$DesignTicketThreadCopyWithImpl;
@override @useResult
$Res call({
 DesignThreadTicket ticket, List<ChatMessage> messages,@JsonKey(name: 'is_party') bool isParty,@JsonKey(name: 'can_reply') bool canReply,@JsonKey(name: 'closed_note') String? closedNote,@JsonKey(name: 'read_up_to') DesignThreadReadUpTo? readUpTo,@JsonKey(name: 'counterpart_read_up_to') int? counterpartReadUpTo
});


@override $DesignThreadTicketCopyWith<$Res> get ticket;@override $DesignThreadReadUpToCopyWith<$Res>? get readUpTo;

}
/// @nodoc
class __$DesignTicketThreadCopyWithImpl<$Res>
    implements _$DesignTicketThreadCopyWith<$Res> {
  __$DesignTicketThreadCopyWithImpl(this._self, this._then);

  final _DesignTicketThread _self;
  final $Res Function(_DesignTicketThread) _then;

/// Create a copy of DesignTicketThread
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ticket = null,Object? messages = null,Object? isParty = null,Object? canReply = null,Object? closedNote = freezed,Object? readUpTo = freezed,Object? counterpartReadUpTo = freezed,}) {
  return _then(_DesignTicketThread(
ticket: null == ticket ? _self.ticket : ticket // ignore: cast_nullable_to_non_nullable
as DesignThreadTicket,messages: null == messages ? _self._messages : messages // ignore: cast_nullable_to_non_nullable
as List<ChatMessage>,isParty: null == isParty ? _self.isParty : isParty // ignore: cast_nullable_to_non_nullable
as bool,canReply: null == canReply ? _self.canReply : canReply // ignore: cast_nullable_to_non_nullable
as bool,closedNote: freezed == closedNote ? _self.closedNote : closedNote // ignore: cast_nullable_to_non_nullable
as String?,readUpTo: freezed == readUpTo ? _self.readUpTo : readUpTo // ignore: cast_nullable_to_non_nullable
as DesignThreadReadUpTo?,counterpartReadUpTo: freezed == counterpartReadUpTo ? _self.counterpartReadUpTo : counterpartReadUpTo // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of DesignTicketThread
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DesignThreadTicketCopyWith<$Res> get ticket {
  
  return $DesignThreadTicketCopyWith<$Res>(_self.ticket, (value) {
    return _then(_self.copyWith(ticket: value));
  });
}/// Create a copy of DesignTicketThread
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DesignThreadReadUpToCopyWith<$Res>? get readUpTo {
    if (_self.readUpTo == null) {
    return null;
  }

  return $DesignThreadReadUpToCopyWith<$Res>(_self.readUpTo!, (value) {
    return _then(_self.copyWith(readUpTo: value));
  });
}
}


/// @nodoc
mixin _$DesignTicketThreadChange {

/// `message_posted` · `message_edited` · `message_retracted` · `read`.
 String get change;/// المحادثةُ بلا رسائلها ولا قارئ — يُؤخذ منها ما لا يختلف بين القرّاء.
 DesignTicketThread get thread; ChatMessage? get message;
/// Create a copy of DesignTicketThreadChange
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DesignTicketThreadChangeCopyWith<DesignTicketThreadChange> get copyWith => _$DesignTicketThreadChangeCopyWithImpl<DesignTicketThreadChange>(this as DesignTicketThreadChange, _$identity);

  /// Serializes this DesignTicketThreadChange to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesignTicketThreadChange&&(identical(other.change, change) || other.change == change)&&(identical(other.thread, thread) || other.thread == thread)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,change,thread,message);

@override
String toString() {
  return 'DesignTicketThreadChange(change: $change, thread: $thread, message: $message)';
}


}

/// @nodoc
abstract mixin class $DesignTicketThreadChangeCopyWith<$Res>  {
  factory $DesignTicketThreadChangeCopyWith(DesignTicketThreadChange value, $Res Function(DesignTicketThreadChange) _then) = _$DesignTicketThreadChangeCopyWithImpl;
@useResult
$Res call({
 String change, DesignTicketThread thread, ChatMessage? message
});


$DesignTicketThreadCopyWith<$Res> get thread;$ChatMessageCopyWith<$Res>? get message;

}
/// @nodoc
class _$DesignTicketThreadChangeCopyWithImpl<$Res>
    implements $DesignTicketThreadChangeCopyWith<$Res> {
  _$DesignTicketThreadChangeCopyWithImpl(this._self, this._then);

  final DesignTicketThreadChange _self;
  final $Res Function(DesignTicketThreadChange) _then;

/// Create a copy of DesignTicketThreadChange
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? change = null,Object? thread = null,Object? message = freezed,}) {
  return _then(_self.copyWith(
change: null == change ? _self.change : change // ignore: cast_nullable_to_non_nullable
as String,thread: null == thread ? _self.thread : thread // ignore: cast_nullable_to_non_nullable
as DesignTicketThread,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as ChatMessage?,
  ));
}
/// Create a copy of DesignTicketThreadChange
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DesignTicketThreadCopyWith<$Res> get thread {
  
  return $DesignTicketThreadCopyWith<$Res>(_self.thread, (value) {
    return _then(_self.copyWith(thread: value));
  });
}/// Create a copy of DesignTicketThreadChange
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatMessageCopyWith<$Res>? get message {
    if (_self.message == null) {
    return null;
  }

  return $ChatMessageCopyWith<$Res>(_self.message!, (value) {
    return _then(_self.copyWith(message: value));
  });
}
}


/// Adds pattern-matching-related methods to [DesignTicketThreadChange].
extension DesignTicketThreadChangePatterns on DesignTicketThreadChange {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DesignTicketThreadChange value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DesignTicketThreadChange() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DesignTicketThreadChange value)  $default,){
final _that = this;
switch (_that) {
case _DesignTicketThreadChange():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DesignTicketThreadChange value)?  $default,){
final _that = this;
switch (_that) {
case _DesignTicketThreadChange() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String change,  DesignTicketThread thread,  ChatMessage? message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DesignTicketThreadChange() when $default != null:
return $default(_that.change,_that.thread,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String change,  DesignTicketThread thread,  ChatMessage? message)  $default,) {final _that = this;
switch (_that) {
case _DesignTicketThreadChange():
return $default(_that.change,_that.thread,_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String change,  DesignTicketThread thread,  ChatMessage? message)?  $default,) {final _that = this;
switch (_that) {
case _DesignTicketThreadChange() when $default != null:
return $default(_that.change,_that.thread,_that.message);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DesignTicketThreadChange implements DesignTicketThreadChange {
  const _DesignTicketThreadChange({required this.change, required this.thread, this.message});
  factory _DesignTicketThreadChange.fromJson(Map<String, dynamic> json) => _$DesignTicketThreadChangeFromJson(json);

/// `message_posted` · `message_edited` · `message_retracted` · `read`.
@override final  String change;
/// المحادثةُ بلا رسائلها ولا قارئ — يُؤخذ منها ما لا يختلف بين القرّاء.
@override final  DesignTicketThread thread;
@override final  ChatMessage? message;

/// Create a copy of DesignTicketThreadChange
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DesignTicketThreadChangeCopyWith<_DesignTicketThreadChange> get copyWith => __$DesignTicketThreadChangeCopyWithImpl<_DesignTicketThreadChange>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DesignTicketThreadChangeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DesignTicketThreadChange&&(identical(other.change, change) || other.change == change)&&(identical(other.thread, thread) || other.thread == thread)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,change,thread,message);

@override
String toString() {
  return 'DesignTicketThreadChange(change: $change, thread: $thread, message: $message)';
}


}

/// @nodoc
abstract mixin class _$DesignTicketThreadChangeCopyWith<$Res> implements $DesignTicketThreadChangeCopyWith<$Res> {
  factory _$DesignTicketThreadChangeCopyWith(_DesignTicketThreadChange value, $Res Function(_DesignTicketThreadChange) _then) = __$DesignTicketThreadChangeCopyWithImpl;
@override @useResult
$Res call({
 String change, DesignTicketThread thread, ChatMessage? message
});


@override $DesignTicketThreadCopyWith<$Res> get thread;@override $ChatMessageCopyWith<$Res>? get message;

}
/// @nodoc
class __$DesignTicketThreadChangeCopyWithImpl<$Res>
    implements _$DesignTicketThreadChangeCopyWith<$Res> {
  __$DesignTicketThreadChangeCopyWithImpl(this._self, this._then);

  final _DesignTicketThreadChange _self;
  final $Res Function(_DesignTicketThreadChange) _then;

/// Create a copy of DesignTicketThreadChange
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? change = null,Object? thread = null,Object? message = freezed,}) {
  return _then(_DesignTicketThreadChange(
change: null == change ? _self.change : change // ignore: cast_nullable_to_non_nullable
as String,thread: null == thread ? _self.thread : thread // ignore: cast_nullable_to_non_nullable
as DesignTicketThread,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as ChatMessage?,
  ));
}

/// Create a copy of DesignTicketThreadChange
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DesignTicketThreadCopyWith<$Res> get thread {
  
  return $DesignTicketThreadCopyWith<$Res>(_self.thread, (value) {
    return _then(_self.copyWith(thread: value));
  });
}/// Create a copy of DesignTicketThreadChange
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatMessageCopyWith<$Res>? get message {
    if (_self.message == null) {
    return null;
  }

  return $ChatMessageCopyWith<$Res>(_self.message!, (value) {
    return _then(_self.copyWith(message: value));
  });
}
}

// dart format on
