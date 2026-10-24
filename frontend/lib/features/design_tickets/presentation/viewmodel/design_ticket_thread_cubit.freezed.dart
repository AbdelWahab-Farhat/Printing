// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'design_ticket_thread_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DesignTicketThreadState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesignTicketThreadState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DesignTicketThreadState()';
}


}

/// @nodoc
class $DesignTicketThreadStateCopyWith<$Res>  {
$DesignTicketThreadStateCopyWith(DesignTicketThreadState _, $Res Function(DesignTicketThreadState) __);
}


/// Adds pattern-matching-related methods to [DesignTicketThreadState].
extension DesignTicketThreadStatePatterns on DesignTicketThreadState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DesignTicketThreadLoading value)?  loading,TResult Function( DesignTicketThreadFailure value)?  failure,TResult Function( DesignTicketThreadLoaded value)?  loaded,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DesignTicketThreadLoading() when loading != null:
return loading(_that);case DesignTicketThreadFailure() when failure != null:
return failure(_that);case DesignTicketThreadLoaded() when loaded != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DesignTicketThreadLoading value)  loading,required TResult Function( DesignTicketThreadFailure value)  failure,required TResult Function( DesignTicketThreadLoaded value)  loaded,}){
final _that = this;
switch (_that) {
case DesignTicketThreadLoading():
return loading(_that);case DesignTicketThreadFailure():
return failure(_that);case DesignTicketThreadLoaded():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DesignTicketThreadLoading value)?  loading,TResult? Function( DesignTicketThreadFailure value)?  failure,TResult? Function( DesignTicketThreadLoaded value)?  loaded,}){
final _that = this;
switch (_that) {
case DesignTicketThreadLoading() when loading != null:
return loading(_that);case DesignTicketThreadFailure() when failure != null:
return failure(_that);case DesignTicketThreadLoaded() when loaded != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( Failure failure)?  failure,TResult Function( DesignTicketThread thread,  bool isWorking,  Failure? lastFailure,  ChatMessage? replyingTo,  PendingVoice? unsentVoice)?  loaded,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DesignTicketThreadLoading() when loading != null:
return loading();case DesignTicketThreadFailure() when failure != null:
return failure(_that.failure);case DesignTicketThreadLoaded() when loaded != null:
return loaded(_that.thread,_that.isWorking,_that.lastFailure,_that.replyingTo,_that.unsentVoice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( Failure failure)  failure,required TResult Function( DesignTicketThread thread,  bool isWorking,  Failure? lastFailure,  ChatMessage? replyingTo,  PendingVoice? unsentVoice)  loaded,}) {final _that = this;
switch (_that) {
case DesignTicketThreadLoading():
return loading();case DesignTicketThreadFailure():
return failure(_that.failure);case DesignTicketThreadLoaded():
return loaded(_that.thread,_that.isWorking,_that.lastFailure,_that.replyingTo,_that.unsentVoice);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( Failure failure)?  failure,TResult? Function( DesignTicketThread thread,  bool isWorking,  Failure? lastFailure,  ChatMessage? replyingTo,  PendingVoice? unsentVoice)?  loaded,}) {final _that = this;
switch (_that) {
case DesignTicketThreadLoading() when loading != null:
return loading();case DesignTicketThreadFailure() when failure != null:
return failure(_that.failure);case DesignTicketThreadLoaded() when loaded != null:
return loaded(_that.thread,_that.isWorking,_that.lastFailure,_that.replyingTo,_that.unsentVoice);case _:
  return null;

}
}

}

/// @nodoc


class DesignTicketThreadLoading implements DesignTicketThreadState {
  const DesignTicketThreadLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesignTicketThreadLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DesignTicketThreadState.loading()';
}


}




/// @nodoc


class DesignTicketThreadFailure implements DesignTicketThreadState {
  const DesignTicketThreadFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of DesignTicketThreadState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DesignTicketThreadFailureCopyWith<DesignTicketThreadFailure> get copyWith => _$DesignTicketThreadFailureCopyWithImpl<DesignTicketThreadFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesignTicketThreadFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'DesignTicketThreadState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $DesignTicketThreadFailureCopyWith<$Res> implements $DesignTicketThreadStateCopyWith<$Res> {
  factory $DesignTicketThreadFailureCopyWith(DesignTicketThreadFailure value, $Res Function(DesignTicketThreadFailure) _then) = _$DesignTicketThreadFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$DesignTicketThreadFailureCopyWithImpl<$Res>
    implements $DesignTicketThreadFailureCopyWith<$Res> {
  _$DesignTicketThreadFailureCopyWithImpl(this._self, this._then);

  final DesignTicketThreadFailure _self;
  final $Res Function(DesignTicketThreadFailure) _then;

/// Create a copy of DesignTicketThreadState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(DesignTicketThreadFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of DesignTicketThreadState
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


class DesignTicketThreadLoaded implements DesignTicketThreadState {
  const DesignTicketThreadLoaded({required this.thread, this.isWorking = false, this.lastFailure, this.replyingTo, this.unsentVoice});
  

 final  DesignTicketThread thread;
/// كتابةٌ في الطريق — رسالة، تعديل، سحب.
@JsonKey() final  bool isWorking;
/// آخرُ كتابةٍ لم تأخذ، مقولةً بجانب محادثةٍ ما زالت هناك.
 final  Failure? lastFailure;
/// الرسالةُ التي يُردّ عليها — تُقتبس فوق الردّ.
 final  ChatMessage? replyingTo;
/// صوتٌ لم يصل.
 final  PendingVoice? unsentVoice;

/// Create a copy of DesignTicketThreadState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DesignTicketThreadLoadedCopyWith<DesignTicketThreadLoaded> get copyWith => _$DesignTicketThreadLoadedCopyWithImpl<DesignTicketThreadLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesignTicketThreadLoaded&&(identical(other.thread, thread) || other.thread == thread)&&(identical(other.isWorking, isWorking) || other.isWorking == isWorking)&&(identical(other.lastFailure, lastFailure) || other.lastFailure == lastFailure)&&(identical(other.replyingTo, replyingTo) || other.replyingTo == replyingTo)&&(identical(other.unsentVoice, unsentVoice) || other.unsentVoice == unsentVoice));
}


@override
int get hashCode => Object.hash(runtimeType,thread,isWorking,lastFailure,replyingTo,unsentVoice);

@override
String toString() {
  return 'DesignTicketThreadState.loaded(thread: $thread, isWorking: $isWorking, lastFailure: $lastFailure, replyingTo: $replyingTo, unsentVoice: $unsentVoice)';
}


}

/// @nodoc
abstract mixin class $DesignTicketThreadLoadedCopyWith<$Res> implements $DesignTicketThreadStateCopyWith<$Res> {
  factory $DesignTicketThreadLoadedCopyWith(DesignTicketThreadLoaded value, $Res Function(DesignTicketThreadLoaded) _then) = _$DesignTicketThreadLoadedCopyWithImpl;
@useResult
$Res call({
 DesignTicketThread thread, bool isWorking, Failure? lastFailure, ChatMessage? replyingTo, PendingVoice? unsentVoice
});


$DesignTicketThreadCopyWith<$Res> get thread;$FailureCopyWith<$Res>? get lastFailure;$ChatMessageCopyWith<$Res>? get replyingTo;$PendingVoiceCopyWith<$Res>? get unsentVoice;

}
/// @nodoc
class _$DesignTicketThreadLoadedCopyWithImpl<$Res>
    implements $DesignTicketThreadLoadedCopyWith<$Res> {
  _$DesignTicketThreadLoadedCopyWithImpl(this._self, this._then);

  final DesignTicketThreadLoaded _self;
  final $Res Function(DesignTicketThreadLoaded) _then;

/// Create a copy of DesignTicketThreadState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? thread = null,Object? isWorking = null,Object? lastFailure = freezed,Object? replyingTo = freezed,Object? unsentVoice = freezed,}) {
  return _then(DesignTicketThreadLoaded(
thread: null == thread ? _self.thread : thread // ignore: cast_nullable_to_non_nullable
as DesignTicketThread,isWorking: null == isWorking ? _self.isWorking : isWorking // ignore: cast_nullable_to_non_nullable
as bool,lastFailure: freezed == lastFailure ? _self.lastFailure : lastFailure // ignore: cast_nullable_to_non_nullable
as Failure?,replyingTo: freezed == replyingTo ? _self.replyingTo : replyingTo // ignore: cast_nullable_to_non_nullable
as ChatMessage?,unsentVoice: freezed == unsentVoice ? _self.unsentVoice : unsentVoice // ignore: cast_nullable_to_non_nullable
as PendingVoice?,
  ));
}

/// Create a copy of DesignTicketThreadState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DesignTicketThreadCopyWith<$Res> get thread {
  
  return $DesignTicketThreadCopyWith<$Res>(_self.thread, (value) {
    return _then(_self.copyWith(thread: value));
  });
}/// Create a copy of DesignTicketThreadState
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
}/// Create a copy of DesignTicketThreadState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ChatMessageCopyWith<$Res>? get replyingTo {
    if (_self.replyingTo == null) {
    return null;
  }

  return $ChatMessageCopyWith<$Res>(_self.replyingTo!, (value) {
    return _then(_self.copyWith(replyingTo: value));
  });
}/// Create a copy of DesignTicketThreadState
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
