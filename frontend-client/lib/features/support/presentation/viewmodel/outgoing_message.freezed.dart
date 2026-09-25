// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'outgoing_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OutgoingMessage {

 String get clientToken; String get body;/// ملفٌّ على هذا الهاتف، يُرفع مع الرسالة. يُقرأ من مساره مرّةً واحدة — انظر [PickedFile].
 PickedFile? get file; DateTime get createdAt; OutgoingStatus get status;/// من ٠ إلى ١، للملفات وحدها. النصّ يصل في طلبٍ صغير لا تقدّم فيه يُرى.
 double get progress; Failure? get failure;
/// Create a copy of OutgoingMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OutgoingMessageCopyWith<OutgoingMessage> get copyWith => _$OutgoingMessageCopyWithImpl<OutgoingMessage>(this as OutgoingMessage, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OutgoingMessage&&(identical(other.clientToken, clientToken) || other.clientToken == clientToken)&&(identical(other.body, body) || other.body == body)&&(identical(other.file, file) || other.file == file)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,clientToken,body,file,createdAt,status,progress,failure);

@override
String toString() {
  return 'OutgoingMessage(clientToken: $clientToken, body: $body, file: $file, createdAt: $createdAt, status: $status, progress: $progress, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $OutgoingMessageCopyWith<$Res>  {
  factory $OutgoingMessageCopyWith(OutgoingMessage value, $Res Function(OutgoingMessage) _then) = _$OutgoingMessageCopyWithImpl;
@useResult
$Res call({
 String clientToken, String body, PickedFile? file, DateTime createdAt, OutgoingStatus status, double progress, Failure? failure
});


$FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class _$OutgoingMessageCopyWithImpl<$Res>
    implements $OutgoingMessageCopyWith<$Res> {
  _$OutgoingMessageCopyWithImpl(this._self, this._then);

  final OutgoingMessage _self;
  final $Res Function(OutgoingMessage) _then;

/// Create a copy of OutgoingMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? clientToken = null,Object? body = null,Object? file = freezed,Object? createdAt = null,Object? status = null,Object? progress = null,Object? failure = freezed,}) {
  return _then(_self.copyWith(
clientToken: null == clientToken ? _self.clientToken : clientToken // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,file: freezed == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as PickedFile?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OutgoingStatus,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}
/// Create a copy of OutgoingMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res>? get failure {
    if (_self.failure == null) {
    return null;
  }

  return $FailureCopyWith<$Res>(_self.failure!, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}


/// Adds pattern-matching-related methods to [OutgoingMessage].
extension OutgoingMessagePatterns on OutgoingMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OutgoingMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OutgoingMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OutgoingMessage value)  $default,){
final _that = this;
switch (_that) {
case _OutgoingMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OutgoingMessage value)?  $default,){
final _that = this;
switch (_that) {
case _OutgoingMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String clientToken,  String body,  PickedFile? file,  DateTime createdAt,  OutgoingStatus status,  double progress,  Failure? failure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OutgoingMessage() when $default != null:
return $default(_that.clientToken,_that.body,_that.file,_that.createdAt,_that.status,_that.progress,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String clientToken,  String body,  PickedFile? file,  DateTime createdAt,  OutgoingStatus status,  double progress,  Failure? failure)  $default,) {final _that = this;
switch (_that) {
case _OutgoingMessage():
return $default(_that.clientToken,_that.body,_that.file,_that.createdAt,_that.status,_that.progress,_that.failure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String clientToken,  String body,  PickedFile? file,  DateTime createdAt,  OutgoingStatus status,  double progress,  Failure? failure)?  $default,) {final _that = this;
switch (_that) {
case _OutgoingMessage() when $default != null:
return $default(_that.clientToken,_that.body,_that.file,_that.createdAt,_that.status,_that.progress,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _OutgoingMessage implements OutgoingMessage {
  const _OutgoingMessage({required this.clientToken, this.body = '', this.file, required this.createdAt, this.status = OutgoingStatus.sending, this.progress = 0, this.failure});
  

@override final  String clientToken;
@override@JsonKey() final  String body;
/// ملفٌّ على هذا الهاتف، يُرفع مع الرسالة. يُقرأ من مساره مرّةً واحدة — انظر [PickedFile].
@override final  PickedFile? file;
@override final  DateTime createdAt;
@override@JsonKey() final  OutgoingStatus status;
/// من ٠ إلى ١، للملفات وحدها. النصّ يصل في طلبٍ صغير لا تقدّم فيه يُرى.
@override@JsonKey() final  double progress;
@override final  Failure? failure;

/// Create a copy of OutgoingMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OutgoingMessageCopyWith<_OutgoingMessage> get copyWith => __$OutgoingMessageCopyWithImpl<_OutgoingMessage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OutgoingMessage&&(identical(other.clientToken, clientToken) || other.clientToken == clientToken)&&(identical(other.body, body) || other.body == body)&&(identical(other.file, file) || other.file == file)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,clientToken,body,file,createdAt,status,progress,failure);

@override
String toString() {
  return 'OutgoingMessage(clientToken: $clientToken, body: $body, file: $file, createdAt: $createdAt, status: $status, progress: $progress, failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$OutgoingMessageCopyWith<$Res> implements $OutgoingMessageCopyWith<$Res> {
  factory _$OutgoingMessageCopyWith(_OutgoingMessage value, $Res Function(_OutgoingMessage) _then) = __$OutgoingMessageCopyWithImpl;
@override @useResult
$Res call({
 String clientToken, String body, PickedFile? file, DateTime createdAt, OutgoingStatus status, double progress, Failure? failure
});


@override $FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class __$OutgoingMessageCopyWithImpl<$Res>
    implements _$OutgoingMessageCopyWith<$Res> {
  __$OutgoingMessageCopyWithImpl(this._self, this._then);

  final _OutgoingMessage _self;
  final $Res Function(_OutgoingMessage) _then;

/// Create a copy of OutgoingMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? clientToken = null,Object? body = null,Object? file = freezed,Object? createdAt = null,Object? status = null,Object? progress = null,Object? failure = freezed,}) {
  return _then(_OutgoingMessage(
clientToken: null == clientToken ? _self.clientToken : clientToken // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,file: freezed == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as PickedFile?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OutgoingStatus,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of OutgoingMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res>? get failure {
    if (_self.failure == null) {
    return null;
  }

  return $FailureCopyWith<$Res>(_self.failure!, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

// dart format on
