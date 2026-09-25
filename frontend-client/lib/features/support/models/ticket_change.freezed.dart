// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ticket_change.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TicketChange {

 SupportTicket get ticket;/// ما قيل، حين يكون التغيير رسالة. فارغٌ للإغلاق وإعادة الفتح والقراءة.
 TicketMessage? get message;
/// Create a copy of TicketChange
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TicketChangeCopyWith<TicketChange> get copyWith => _$TicketChangeCopyWithImpl<TicketChange>(this as TicketChange, _$identity);

  /// Serializes this TicketChange to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TicketChange&&(identical(other.ticket, ticket) || other.ticket == ticket)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ticket,message);

@override
String toString() {
  return 'TicketChange(ticket: $ticket, message: $message)';
}


}

/// @nodoc
abstract mixin class $TicketChangeCopyWith<$Res>  {
  factory $TicketChangeCopyWith(TicketChange value, $Res Function(TicketChange) _then) = _$TicketChangeCopyWithImpl;
@useResult
$Res call({
 SupportTicket ticket, TicketMessage? message
});


$SupportTicketCopyWith<$Res> get ticket;$TicketMessageCopyWith<$Res>? get message;

}
/// @nodoc
class _$TicketChangeCopyWithImpl<$Res>
    implements $TicketChangeCopyWith<$Res> {
  _$TicketChangeCopyWithImpl(this._self, this._then);

  final TicketChange _self;
  final $Res Function(TicketChange) _then;

/// Create a copy of TicketChange
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ticket = null,Object? message = freezed,}) {
  return _then(_self.copyWith(
ticket: null == ticket ? _self.ticket : ticket // ignore: cast_nullable_to_non_nullable
as SupportTicket,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as TicketMessage?,
  ));
}
/// Create a copy of TicketChange
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SupportTicketCopyWith<$Res> get ticket {
  
  return $SupportTicketCopyWith<$Res>(_self.ticket, (value) {
    return _then(_self.copyWith(ticket: value));
  });
}/// Create a copy of TicketChange
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TicketMessageCopyWith<$Res>? get message {
    if (_self.message == null) {
    return null;
  }

  return $TicketMessageCopyWith<$Res>(_self.message!, (value) {
    return _then(_self.copyWith(message: value));
  });
}
}


/// Adds pattern-matching-related methods to [TicketChange].
extension TicketChangePatterns on TicketChange {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TicketChange value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TicketChange() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TicketChange value)  $default,){
final _that = this;
switch (_that) {
case _TicketChange():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TicketChange value)?  $default,){
final _that = this;
switch (_that) {
case _TicketChange() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SupportTicket ticket,  TicketMessage? message)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TicketChange() when $default != null:
return $default(_that.ticket,_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SupportTicket ticket,  TicketMessage? message)  $default,) {final _that = this;
switch (_that) {
case _TicketChange():
return $default(_that.ticket,_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SupportTicket ticket,  TicketMessage? message)?  $default,) {final _that = this;
switch (_that) {
case _TicketChange() when $default != null:
return $default(_that.ticket,_that.message);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TicketChange implements TicketChange {
  const _TicketChange({required this.ticket, this.message});
  factory _TicketChange.fromJson(Map<String, dynamic> json) => _$TicketChangeFromJson(json);

@override final  SupportTicket ticket;
/// ما قيل، حين يكون التغيير رسالة. فارغٌ للإغلاق وإعادة الفتح والقراءة.
@override final  TicketMessage? message;

/// Create a copy of TicketChange
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TicketChangeCopyWith<_TicketChange> get copyWith => __$TicketChangeCopyWithImpl<_TicketChange>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TicketChangeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TicketChange&&(identical(other.ticket, ticket) || other.ticket == ticket)&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ticket,message);

@override
String toString() {
  return 'TicketChange(ticket: $ticket, message: $message)';
}


}

/// @nodoc
abstract mixin class _$TicketChangeCopyWith<$Res> implements $TicketChangeCopyWith<$Res> {
  factory _$TicketChangeCopyWith(_TicketChange value, $Res Function(_TicketChange) _then) = __$TicketChangeCopyWithImpl;
@override @useResult
$Res call({
 SupportTicket ticket, TicketMessage? message
});


@override $SupportTicketCopyWith<$Res> get ticket;@override $TicketMessageCopyWith<$Res>? get message;

}
/// @nodoc
class __$TicketChangeCopyWithImpl<$Res>
    implements _$TicketChangeCopyWith<$Res> {
  __$TicketChangeCopyWithImpl(this._self, this._then);

  final _TicketChange _self;
  final $Res Function(_TicketChange) _then;

/// Create a copy of TicketChange
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ticket = null,Object? message = freezed,}) {
  return _then(_TicketChange(
ticket: null == ticket ? _self.ticket : ticket // ignore: cast_nullable_to_non_nullable
as SupportTicket,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as TicketMessage?,
  ));
}

/// Create a copy of TicketChange
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SupportTicketCopyWith<$Res> get ticket {
  
  return $SupportTicketCopyWith<$Res>(_self.ticket, (value) {
    return _then(_self.copyWith(ticket: value));
  });
}/// Create a copy of TicketChange
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TicketMessageCopyWith<$Res>? get message {
    if (_self.message == null) {
    return null;
  }

  return $TicketMessageCopyWith<$Res>(_self.message!, (value) {
    return _then(_self.copyWith(message: value));
  });
}
}

// dart format on
