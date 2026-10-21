// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'internal_thread_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PendingVoice {

 String get path; int get durationSeconds; List<int> get waveform; String get clientToken; int? get replyToMessageId;
/// Create a copy of PendingVoice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingVoiceCopyWith<PendingVoice> get copyWith => _$PendingVoiceCopyWithImpl<PendingVoice>(this as PendingVoice, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingVoice&&(identical(other.path, path) || other.path == path)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&const DeepCollectionEquality().equals(other.waveform, waveform)&&(identical(other.clientToken, clientToken) || other.clientToken == clientToken)&&(identical(other.replyToMessageId, replyToMessageId) || other.replyToMessageId == replyToMessageId));
}


@override
int get hashCode => Object.hash(runtimeType,path,durationSeconds,const DeepCollectionEquality().hash(waveform),clientToken,replyToMessageId);

@override
String toString() {
  return 'PendingVoice(path: $path, durationSeconds: $durationSeconds, waveform: $waveform, clientToken: $clientToken, replyToMessageId: $replyToMessageId)';
}


}

/// @nodoc
abstract mixin class $PendingVoiceCopyWith<$Res>  {
  factory $PendingVoiceCopyWith(PendingVoice value, $Res Function(PendingVoice) _then) = _$PendingVoiceCopyWithImpl;
@useResult
$Res call({
 String path, int durationSeconds, List<int> waveform, String clientToken, int? replyToMessageId
});




}
/// @nodoc
class _$PendingVoiceCopyWithImpl<$Res>
    implements $PendingVoiceCopyWith<$Res> {
  _$PendingVoiceCopyWithImpl(this._self, this._then);

  final PendingVoice _self;
  final $Res Function(PendingVoice) _then;

/// Create a copy of PendingVoice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? path = null,Object? durationSeconds = null,Object? waveform = null,Object? clientToken = null,Object? replyToMessageId = freezed,}) {
  return _then(_self.copyWith(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,durationSeconds: null == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int,waveform: null == waveform ? _self.waveform : waveform // ignore: cast_nullable_to_non_nullable
as List<int>,clientToken: null == clientToken ? _self.clientToken : clientToken // ignore: cast_nullable_to_non_nullable
as String,replyToMessageId: freezed == replyToMessageId ? _self.replyToMessageId : replyToMessageId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [PendingVoice].
extension PendingVoicePatterns on PendingVoice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PendingVoice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PendingVoice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PendingVoice value)  $default,){
final _that = this;
switch (_that) {
case _PendingVoice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PendingVoice value)?  $default,){
final _that = this;
switch (_that) {
case _PendingVoice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String path,  int durationSeconds,  List<int> waveform,  String clientToken,  int? replyToMessageId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PendingVoice() when $default != null:
return $default(_that.path,_that.durationSeconds,_that.waveform,_that.clientToken,_that.replyToMessageId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String path,  int durationSeconds,  List<int> waveform,  String clientToken,  int? replyToMessageId)  $default,) {final _that = this;
switch (_that) {
case _PendingVoice():
return $default(_that.path,_that.durationSeconds,_that.waveform,_that.clientToken,_that.replyToMessageId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String path,  int durationSeconds,  List<int> waveform,  String clientToken,  int? replyToMessageId)?  $default,) {final _that = this;
switch (_that) {
case _PendingVoice() when $default != null:
return $default(_that.path,_that.durationSeconds,_that.waveform,_that.clientToken,_that.replyToMessageId);case _:
  return null;

}
}

}

/// @nodoc


class _PendingVoice implements PendingVoice {
  const _PendingVoice({required this.path, required this.durationSeconds, required final  List<int> waveform, required this.clientToken, this.replyToMessageId}): _waveform = waveform;
  

@override final  String path;
@override final  int durationSeconds;
 final  List<int> _waveform;
@override List<int> get waveform {
  if (_waveform is EqualUnmodifiableListView) return _waveform;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_waveform);
}

@override final  String clientToken;
@override final  int? replyToMessageId;

/// Create a copy of PendingVoice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PendingVoiceCopyWith<_PendingVoice> get copyWith => __$PendingVoiceCopyWithImpl<_PendingVoice>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PendingVoice&&(identical(other.path, path) || other.path == path)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&const DeepCollectionEquality().equals(other._waveform, _waveform)&&(identical(other.clientToken, clientToken) || other.clientToken == clientToken)&&(identical(other.replyToMessageId, replyToMessageId) || other.replyToMessageId == replyToMessageId));
}


@override
int get hashCode => Object.hash(runtimeType,path,durationSeconds,const DeepCollectionEquality().hash(_waveform),clientToken,replyToMessageId);

@override
String toString() {
  return 'PendingVoice(path: $path, durationSeconds: $durationSeconds, waveform: $waveform, clientToken: $clientToken, replyToMessageId: $replyToMessageId)';
}


}

/// @nodoc
abstract mixin class _$PendingVoiceCopyWith<$Res> implements $PendingVoiceCopyWith<$Res> {
  factory _$PendingVoiceCopyWith(_PendingVoice value, $Res Function(_PendingVoice) _then) = __$PendingVoiceCopyWithImpl;
@override @useResult
$Res call({
 String path, int durationSeconds, List<int> waveform, String clientToken, int? replyToMessageId
});




}
/// @nodoc
class __$PendingVoiceCopyWithImpl<$Res>
    implements _$PendingVoiceCopyWith<$Res> {
  __$PendingVoiceCopyWithImpl(this._self, this._then);

  final _PendingVoice _self;
  final $Res Function(_PendingVoice) _then;

/// Create a copy of PendingVoice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? path = null,Object? durationSeconds = null,Object? waveform = null,Object? clientToken = null,Object? replyToMessageId = freezed,}) {
  return _then(_PendingVoice(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,durationSeconds: null == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int,waveform: null == waveform ? _self._waveform : waveform // ignore: cast_nullable_to_non_nullable
as List<int>,clientToken: null == clientToken ? _self.clientToken : clientToken // ignore: cast_nullable_to_non_nullable
as String,replyToMessageId: freezed == replyToMessageId ? _self.replyToMessageId : replyToMessageId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
mixin _$InternalThreadState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InternalThreadState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'InternalThreadState()';
}


}

/// @nodoc
class $InternalThreadStateCopyWith<$Res>  {
$InternalThreadStateCopyWith(InternalThreadState _, $Res Function(InternalThreadState) __);
}


/// Adds pattern-matching-related methods to [InternalThreadState].
extension InternalThreadStatePatterns on InternalThreadState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( InternalThreadLoading value)?  loading,TResult Function( InternalThreadFailure value)?  failure,TResult Function( InternalThreadLoaded value)?  loaded,required TResult orElse(),}){
final _that = this;
switch (_that) {
case InternalThreadLoading() when loading != null:
return loading(_that);case InternalThreadFailure() when failure != null:
return failure(_that);case InternalThreadLoaded() when loaded != null:
return loaded(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( InternalThreadLoading value)  loading,required TResult Function( InternalThreadFailure value)  failure,required TResult Function( InternalThreadLoaded value)  loaded,}){
final _that = this;
switch (_that) {
case InternalThreadLoading():
return loading(_that);case InternalThreadFailure():
return failure(_that);case InternalThreadLoaded():
return loaded(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( InternalThreadLoading value)?  loading,TResult? Function( InternalThreadFailure value)?  failure,TResult? Function( InternalThreadLoaded value)?  loaded,}){
final _that = this;
switch (_that) {
case InternalThreadLoading() when loading != null:
return loading(_that);case InternalThreadFailure() when failure != null:
return failure(_that);case InternalThreadLoaded() when loaded != null:
return loaded(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( Failure failure)?  failure,TResult Function( InternalTicket ticket,  bool isWorking,  Failure? lastFailure,  InternalMessage? replyingTo,  PendingVoice? unsentVoice)?  loaded,required TResult orElse(),}) {final _that = this;
switch (_that) {
case InternalThreadLoading() when loading != null:
return loading();case InternalThreadFailure() when failure != null:
return failure(_that.failure);case InternalThreadLoaded() when loaded != null:
return loaded(_that.ticket,_that.isWorking,_that.lastFailure,_that.replyingTo,_that.unsentVoice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( Failure failure)  failure,required TResult Function( InternalTicket ticket,  bool isWorking,  Failure? lastFailure,  InternalMessage? replyingTo,  PendingVoice? unsentVoice)  loaded,}) {final _that = this;
switch (_that) {
case InternalThreadLoading():
return loading();case InternalThreadFailure():
return failure(_that.failure);case InternalThreadLoaded():
return loaded(_that.ticket,_that.isWorking,_that.lastFailure,_that.replyingTo,_that.unsentVoice);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( Failure failure)?  failure,TResult? Function( InternalTicket ticket,  bool isWorking,  Failure? lastFailure,  InternalMessage? replyingTo,  PendingVoice? unsentVoice)?  loaded,}) {final _that = this;
switch (_that) {
case InternalThreadLoading() when loading != null:
return loading();case InternalThreadFailure() when failure != null:
return failure(_that.failure);case InternalThreadLoaded() when loaded != null:
return loaded(_that.ticket,_that.isWorking,_that.lastFailure,_that.replyingTo,_that.unsentVoice);case _:
  return null;

}
}

}

/// @nodoc


class InternalThreadLoading implements InternalThreadState {
  const InternalThreadLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InternalThreadLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'InternalThreadState.loading()';
}


}




/// @nodoc


class InternalThreadFailure implements InternalThreadState {
  const InternalThreadFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of InternalThreadState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InternalThreadFailureCopyWith<InternalThreadFailure> get copyWith => _$InternalThreadFailureCopyWithImpl<InternalThreadFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InternalThreadFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'InternalThreadState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $InternalThreadFailureCopyWith<$Res> implements $InternalThreadStateCopyWith<$Res> {
  factory $InternalThreadFailureCopyWith(InternalThreadFailure value, $Res Function(InternalThreadFailure) _then) = _$InternalThreadFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$InternalThreadFailureCopyWithImpl<$Res>
    implements $InternalThreadFailureCopyWith<$Res> {
  _$InternalThreadFailureCopyWithImpl(this._self, this._then);

  final InternalThreadFailure _self;
  final $Res Function(InternalThreadFailure) _then;

/// Create a copy of InternalThreadState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(InternalThreadFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of InternalThreadState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res> get failure {
  
  return $FailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

/// @nodoc


class InternalThreadLoaded implements InternalThreadState {
  const InternalThreadLoaded({required this.ticket, this.isWorking = false, this.lastFailure, this.replyingTo, this.unsentVoice});
  

 final  InternalTicket ticket;
/// كتابةٌ في الطريق — رسالة، تعديل، سحب، إغلاق، تحويل.
@JsonKey() final  bool isWorking;
/// آخرُ كتابةٍ لم تأخذ، مقولةً بجانب محادثةٍ ما زالت هناك.
 final  Failure? lastFailure;
/// الرسالةُ التي يُردّ عليها — تُقتبس فوق الردّ.
 final  InternalMessage? replyingTo;
/// صوتٌ لم يصل.
 final  PendingVoice? unsentVoice;

/// Create a copy of InternalThreadState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InternalThreadLoadedCopyWith<InternalThreadLoaded> get copyWith => _$InternalThreadLoadedCopyWithImpl<InternalThreadLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InternalThreadLoaded&&(identical(other.ticket, ticket) || other.ticket == ticket)&&(identical(other.isWorking, isWorking) || other.isWorking == isWorking)&&(identical(other.lastFailure, lastFailure) || other.lastFailure == lastFailure)&&(identical(other.replyingTo, replyingTo) || other.replyingTo == replyingTo)&&(identical(other.unsentVoice, unsentVoice) || other.unsentVoice == unsentVoice));
}


@override
int get hashCode => Object.hash(runtimeType,ticket,isWorking,lastFailure,replyingTo,unsentVoice);

@override
String toString() {
  return 'InternalThreadState.loaded(ticket: $ticket, isWorking: $isWorking, lastFailure: $lastFailure, replyingTo: $replyingTo, unsentVoice: $unsentVoice)';
}


}

/// @nodoc
abstract mixin class $InternalThreadLoadedCopyWith<$Res> implements $InternalThreadStateCopyWith<$Res> {
  factory $InternalThreadLoadedCopyWith(InternalThreadLoaded value, $Res Function(InternalThreadLoaded) _then) = _$InternalThreadLoadedCopyWithImpl;
@useResult
$Res call({
 InternalTicket ticket, bool isWorking, Failure? lastFailure, InternalMessage? replyingTo, PendingVoice? unsentVoice
});


$InternalTicketCopyWith<$Res> get ticket;$FailureCopyWith<$Res>? get lastFailure;$InternalMessageCopyWith<$Res>? get replyingTo;$PendingVoiceCopyWith<$Res>? get unsentVoice;

}
/// @nodoc
class _$InternalThreadLoadedCopyWithImpl<$Res>
    implements $InternalThreadLoadedCopyWith<$Res> {
  _$InternalThreadLoadedCopyWithImpl(this._self, this._then);

  final InternalThreadLoaded _self;
  final $Res Function(InternalThreadLoaded) _then;

/// Create a copy of InternalThreadState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? ticket = null,Object? isWorking = null,Object? lastFailure = freezed,Object? replyingTo = freezed,Object? unsentVoice = freezed,}) {
  return _then(InternalThreadLoaded(
ticket: null == ticket ? _self.ticket : ticket // ignore: cast_nullable_to_non_nullable
as InternalTicket,isWorking: null == isWorking ? _self.isWorking : isWorking // ignore: cast_nullable_to_non_nullable
as bool,lastFailure: freezed == lastFailure ? _self.lastFailure : lastFailure // ignore: cast_nullable_to_non_nullable
as Failure?,replyingTo: freezed == replyingTo ? _self.replyingTo : replyingTo // ignore: cast_nullable_to_non_nullable
as InternalMessage?,unsentVoice: freezed == unsentVoice ? _self.unsentVoice : unsentVoice // ignore: cast_nullable_to_non_nullable
as PendingVoice?,
  ));
}

/// Create a copy of InternalThreadState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InternalTicketCopyWith<$Res> get ticket {
  
  return $InternalTicketCopyWith<$Res>(_self.ticket, (value) {
    return _then(_self.copyWith(ticket: value));
  });
}/// Create a copy of InternalThreadState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res>? get lastFailure {
    if (_self.lastFailure == null) {
    return null;
  }

  return $FailureCopyWith<$Res>(_self.lastFailure!, (value) {
    return _then(_self.copyWith(lastFailure: value));
  });
}/// Create a copy of InternalThreadState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InternalMessageCopyWith<$Res>? get replyingTo {
    if (_self.replyingTo == null) {
    return null;
  }

  return $InternalMessageCopyWith<$Res>(_self.replyingTo!, (value) {
    return _then(_self.copyWith(replyingTo: value));
  });
}/// Create a copy of InternalThreadState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PendingVoiceCopyWith<$Res>? get unsentVoice {
    if (_self.unsentVoice == null) {
    return null;
  }

  return $PendingVoiceCopyWith<$Res>(_self.unsentVoice!, (value) {
    return _then(_self.copyWith(unsentVoice: value));
  });
}
}

// dart format on
