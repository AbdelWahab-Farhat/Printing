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
mixin _$TicketMessage {

 int get id;@JsonKey(unknownEnumValue: MessageAuthor.unknown) MessageAuthor get from; String get body;@JsonKey(name: 'sent_at') DateTime? get sentAt;
/// Create a copy of TicketMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TicketMessageCopyWith<TicketMessage> get copyWith => _$TicketMessageCopyWithImpl<TicketMessage>(this as TicketMessage, _$identity);

  /// Serializes this TicketMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TicketMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.from, from) || other.from == from)&&(identical(other.body, body) || other.body == body)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,from,body,sentAt);

@override
String toString() {
  return 'TicketMessage(id: $id, from: $from, body: $body, sentAt: $sentAt)';
}


}

/// @nodoc
abstract mixin class $TicketMessageCopyWith<$Res>  {
  factory $TicketMessageCopyWith(TicketMessage value, $Res Function(TicketMessage) _then) = _$TicketMessageCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(unknownEnumValue: MessageAuthor.unknown) MessageAuthor from, String body,@JsonKey(name: 'sent_at') DateTime? sentAt
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? from = null,Object? body = null,Object? sentAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as MessageAuthor,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(unknownEnumValue: MessageAuthor.unknown)  MessageAuthor from,  String body, @JsonKey(name: 'sent_at')  DateTime? sentAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TicketMessage() when $default != null:
return $default(_that.id,_that.from,_that.body,_that.sentAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(unknownEnumValue: MessageAuthor.unknown)  MessageAuthor from,  String body, @JsonKey(name: 'sent_at')  DateTime? sentAt)  $default,) {final _that = this;
switch (_that) {
case _TicketMessage():
return $default(_that.id,_that.from,_that.body,_that.sentAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(unknownEnumValue: MessageAuthor.unknown)  MessageAuthor from,  String body, @JsonKey(name: 'sent_at')  DateTime? sentAt)?  $default,) {final _that = this;
switch (_that) {
case _TicketMessage() when $default != null:
return $default(_that.id,_that.from,_that.body,_that.sentAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TicketMessage implements TicketMessage {
  const _TicketMessage({required this.id, @JsonKey(unknownEnumValue: MessageAuthor.unknown) this.from = MessageAuthor.unknown, required this.body, @JsonKey(name: 'sent_at') this.sentAt});
  factory _TicketMessage.fromJson(Map<String, dynamic> json) => _$TicketMessageFromJson(json);

@override final  int id;
@override@JsonKey(unknownEnumValue: MessageAuthor.unknown) final  MessageAuthor from;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TicketMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.from, from) || other.from == from)&&(identical(other.body, body) || other.body == body)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,from,body,sentAt);

@override
String toString() {
  return 'TicketMessage(id: $id, from: $from, body: $body, sentAt: $sentAt)';
}


}

/// @nodoc
abstract mixin class _$TicketMessageCopyWith<$Res> implements $TicketMessageCopyWith<$Res> {
  factory _$TicketMessageCopyWith(_TicketMessage value, $Res Function(_TicketMessage) _then) = __$TicketMessageCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(unknownEnumValue: MessageAuthor.unknown) MessageAuthor from, String body,@JsonKey(name: 'sent_at') DateTime? sentAt
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? from = null,Object? body = null,Object? sentAt = freezed,}) {
  return _then(_TicketMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as MessageAuthor,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,sentAt: freezed == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
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
mixin _$SupportTicket {

 int get id; String get subject;@JsonKey(unknownEnumValue: TicketStatus.unknown) TicketStatus get status;/// Drawn instead of translating [status] here, so a status added to the business appears
/// correctly without an app release.
@JsonKey(name: 'status_label') String get statusLabel;@JsonKey(name: 'is_open') bool get isOpen; TicketOrderRef? get order;@JsonKey(name: 'unread_count') int get unreadCount;/// Present on the thread endpoint, empty in the list — the list draws a subject and a badge.
 List<TicketMessage> get messages;/// How long the thread is, and the last thing anybody said in it.
///
/// **Both come from the list endpoint only**, where [messages] is empty — the thread
/// endpoint sends the messages themselves and these would be a second way to say the same
/// thing. So a card that came back from the thread screen has no preview, and the card
/// keeps the one it was drawn with rather than blanking.
@JsonKey(name: 'messages_count') int? get messagesCount; String? get preview;@JsonKey(name: 'last_message_at') DateTime? get lastMessageAt;@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of SupportTicket
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportTicketCopyWith<SupportTicket> get copyWith => _$SupportTicketCopyWithImpl<SupportTicket>(this as SupportTicket, _$identity);

  /// Serializes this SupportTicket to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportTicket&&(identical(other.id, id) || other.id == id)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.isOpen, isOpen) || other.isOpen == isOpen)&&(identical(other.order, order) || other.order == order)&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount)&&const DeepCollectionEquality().equals(other.messages, messages)&&(identical(other.messagesCount, messagesCount) || other.messagesCount == messagesCount)&&(identical(other.preview, preview) || other.preview == preview)&&(identical(other.lastMessageAt, lastMessageAt) || other.lastMessageAt == lastMessageAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,subject,status,statusLabel,isOpen,order,unreadCount,const DeepCollectionEquality().hash(messages),messagesCount,preview,lastMessageAt,createdAt);

@override
String toString() {
  return 'SupportTicket(id: $id, subject: $subject, status: $status, statusLabel: $statusLabel, isOpen: $isOpen, order: $order, unreadCount: $unreadCount, messages: $messages, messagesCount: $messagesCount, preview: $preview, lastMessageAt: $lastMessageAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $SupportTicketCopyWith<$Res>  {
  factory $SupportTicketCopyWith(SupportTicket value, $Res Function(SupportTicket) _then) = _$SupportTicketCopyWithImpl;
@useResult
$Res call({
 int id, String subject,@JsonKey(unknownEnumValue: TicketStatus.unknown) TicketStatus status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'is_open') bool isOpen, TicketOrderRef? order,@JsonKey(name: 'unread_count') int unreadCount, List<TicketMessage> messages,@JsonKey(name: 'messages_count') int? messagesCount, String? preview,@JsonKey(name: 'last_message_at') DateTime? lastMessageAt,@JsonKey(name: 'created_at') DateTime? createdAt
});


$TicketOrderRefCopyWith<$Res>? get order;

}
/// @nodoc
class _$SupportTicketCopyWithImpl<$Res>
    implements $SupportTicketCopyWith<$Res> {
  _$SupportTicketCopyWithImpl(this._self, this._then);

  final SupportTicket _self;
  final $Res Function(SupportTicket) _then;

/// Create a copy of SupportTicket
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? subject = null,Object? status = null,Object? statusLabel = null,Object? isOpen = null,Object? order = freezed,Object? unreadCount = null,Object? messages = null,Object? messagesCount = freezed,Object? preview = freezed,Object? lastMessageAt = freezed,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TicketStatus,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,isOpen: null == isOpen ? _self.isOpen : isOpen // ignore: cast_nullable_to_non_nullable
as bool,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as TicketOrderRef?,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,messages: null == messages ? _self.messages : messages // ignore: cast_nullable_to_non_nullable
as List<TicketMessage>,messagesCount: freezed == messagesCount ? _self.messagesCount : messagesCount // ignore: cast_nullable_to_non_nullable
as int?,preview: freezed == preview ? _self.preview : preview // ignore: cast_nullable_to_non_nullable
as String?,lastMessageAt: freezed == lastMessageAt ? _self.lastMessageAt : lastMessageAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of SupportTicket
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String subject, @JsonKey(unknownEnumValue: TicketStatus.unknown)  TicketStatus status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'is_open')  bool isOpen,  TicketOrderRef? order, @JsonKey(name: 'unread_count')  int unreadCount,  List<TicketMessage> messages, @JsonKey(name: 'messages_count')  int? messagesCount,  String? preview, @JsonKey(name: 'last_message_at')  DateTime? lastMessageAt, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SupportTicket() when $default != null:
return $default(_that.id,_that.subject,_that.status,_that.statusLabel,_that.isOpen,_that.order,_that.unreadCount,_that.messages,_that.messagesCount,_that.preview,_that.lastMessageAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String subject, @JsonKey(unknownEnumValue: TicketStatus.unknown)  TicketStatus status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'is_open')  bool isOpen,  TicketOrderRef? order, @JsonKey(name: 'unread_count')  int unreadCount,  List<TicketMessage> messages, @JsonKey(name: 'messages_count')  int? messagesCount,  String? preview, @JsonKey(name: 'last_message_at')  DateTime? lastMessageAt, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _SupportTicket():
return $default(_that.id,_that.subject,_that.status,_that.statusLabel,_that.isOpen,_that.order,_that.unreadCount,_that.messages,_that.messagesCount,_that.preview,_that.lastMessageAt,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String subject, @JsonKey(unknownEnumValue: TicketStatus.unknown)  TicketStatus status, @JsonKey(name: 'status_label')  String statusLabel, @JsonKey(name: 'is_open')  bool isOpen,  TicketOrderRef? order, @JsonKey(name: 'unread_count')  int unreadCount,  List<TicketMessage> messages, @JsonKey(name: 'messages_count')  int? messagesCount,  String? preview, @JsonKey(name: 'last_message_at')  DateTime? lastMessageAt, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _SupportTicket() when $default != null:
return $default(_that.id,_that.subject,_that.status,_that.statusLabel,_that.isOpen,_that.order,_that.unreadCount,_that.messages,_that.messagesCount,_that.preview,_that.lastMessageAt,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SupportTicket implements SupportTicket {
  const _SupportTicket({required this.id, required this.subject, @JsonKey(unknownEnumValue: TicketStatus.unknown) this.status = TicketStatus.unknown, @JsonKey(name: 'status_label') required this.statusLabel, @JsonKey(name: 'is_open') this.isOpen = true, this.order, @JsonKey(name: 'unread_count') this.unreadCount = 0, final  List<TicketMessage> messages = const <TicketMessage>[], @JsonKey(name: 'messages_count') this.messagesCount, this.preview, @JsonKey(name: 'last_message_at') this.lastMessageAt, @JsonKey(name: 'created_at') this.createdAt}): _messages = messages;
  factory _SupportTicket.fromJson(Map<String, dynamic> json) => _$SupportTicketFromJson(json);

@override final  int id;
@override final  String subject;
@override@JsonKey(unknownEnumValue: TicketStatus.unknown) final  TicketStatus status;
/// Drawn instead of translating [status] here, so a status added to the business appears
/// correctly without an app release.
@override@JsonKey(name: 'status_label') final  String statusLabel;
@override@JsonKey(name: 'is_open') final  bool isOpen;
@override final  TicketOrderRef? order;
@override@JsonKey(name: 'unread_count') final  int unreadCount;
/// Present on the thread endpoint, empty in the list — the list draws a subject and a badge.
 final  List<TicketMessage> _messages;
/// Present on the thread endpoint, empty in the list — the list draws a subject and a badge.
@override@JsonKey() List<TicketMessage> get messages {
  if (_messages is EqualUnmodifiableListView) return _messages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_messages);
}

/// How long the thread is, and the last thing anybody said in it.
///
/// **Both come from the list endpoint only**, where [messages] is empty — the thread
/// endpoint sends the messages themselves and these would be a second way to say the same
/// thing. So a card that came back from the thread screen has no preview, and the card
/// keeps the one it was drawn with rather than blanking.
@override@JsonKey(name: 'messages_count') final  int? messagesCount;
@override final  String? preview;
@override@JsonKey(name: 'last_message_at') final  DateTime? lastMessageAt;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SupportTicket&&(identical(other.id, id) || other.id == id)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.status, status) || other.status == status)&&(identical(other.statusLabel, statusLabel) || other.statusLabel == statusLabel)&&(identical(other.isOpen, isOpen) || other.isOpen == isOpen)&&(identical(other.order, order) || other.order == order)&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount)&&const DeepCollectionEquality().equals(other._messages, _messages)&&(identical(other.messagesCount, messagesCount) || other.messagesCount == messagesCount)&&(identical(other.preview, preview) || other.preview == preview)&&(identical(other.lastMessageAt, lastMessageAt) || other.lastMessageAt == lastMessageAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,subject,status,statusLabel,isOpen,order,unreadCount,const DeepCollectionEquality().hash(_messages),messagesCount,preview,lastMessageAt,createdAt);

@override
String toString() {
  return 'SupportTicket(id: $id, subject: $subject, status: $status, statusLabel: $statusLabel, isOpen: $isOpen, order: $order, unreadCount: $unreadCount, messages: $messages, messagesCount: $messagesCount, preview: $preview, lastMessageAt: $lastMessageAt, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$SupportTicketCopyWith<$Res> implements $SupportTicketCopyWith<$Res> {
  factory _$SupportTicketCopyWith(_SupportTicket value, $Res Function(_SupportTicket) _then) = __$SupportTicketCopyWithImpl;
@override @useResult
$Res call({
 int id, String subject,@JsonKey(unknownEnumValue: TicketStatus.unknown) TicketStatus status,@JsonKey(name: 'status_label') String statusLabel,@JsonKey(name: 'is_open') bool isOpen, TicketOrderRef? order,@JsonKey(name: 'unread_count') int unreadCount, List<TicketMessage> messages,@JsonKey(name: 'messages_count') int? messagesCount, String? preview,@JsonKey(name: 'last_message_at') DateTime? lastMessageAt,@JsonKey(name: 'created_at') DateTime? createdAt
});


@override $TicketOrderRefCopyWith<$Res>? get order;

}
/// @nodoc
class __$SupportTicketCopyWithImpl<$Res>
    implements _$SupportTicketCopyWith<$Res> {
  __$SupportTicketCopyWithImpl(this._self, this._then);

  final _SupportTicket _self;
  final $Res Function(_SupportTicket) _then;

/// Create a copy of SupportTicket
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? subject = null,Object? status = null,Object? statusLabel = null,Object? isOpen = null,Object? order = freezed,Object? unreadCount = null,Object? messages = null,Object? messagesCount = freezed,Object? preview = freezed,Object? lastMessageAt = freezed,Object? createdAt = freezed,}) {
  return _then(_SupportTicket(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TicketStatus,statusLabel: null == statusLabel ? _self.statusLabel : statusLabel // ignore: cast_nullable_to_non_nullable
as String,isOpen: null == isOpen ? _self.isOpen : isOpen // ignore: cast_nullable_to_non_nullable
as bool,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as TicketOrderRef?,unreadCount: null == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int,messages: null == messages ? _self._messages : messages // ignore: cast_nullable_to_non_nullable
as List<TicketMessage>,messagesCount: freezed == messagesCount ? _self.messagesCount : messagesCount // ignore: cast_nullable_to_non_nullable
as int?,preview: freezed == preview ? _self.preview : preview // ignore: cast_nullable_to_non_nullable
as String?,lastMessageAt: freezed == lastMessageAt ? _self.lastMessageAt : lastMessageAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of SupportTicket
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
}
}

// dart format on
