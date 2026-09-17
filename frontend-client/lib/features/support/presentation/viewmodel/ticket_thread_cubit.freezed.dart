// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ticket_thread_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TicketThreadState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TicketThreadState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TicketThreadState()';
}


}

/// @nodoc
class $TicketThreadStateCopyWith<$Res>  {
$TicketThreadStateCopyWith(TicketThreadState _, $Res Function(TicketThreadState) __);
}


/// Adds pattern-matching-related methods to [TicketThreadState].
extension TicketThreadStatePatterns on TicketThreadState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TicketThreadLoading value)?  loading,TResult Function( TicketThreadLoaded value)?  loaded,TResult Function( TicketThreadFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TicketThreadLoading() when loading != null:
return loading(_that);case TicketThreadLoaded() when loaded != null:
return loaded(_that);case TicketThreadFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TicketThreadLoading value)  loading,required TResult Function( TicketThreadLoaded value)  loaded,required TResult Function( TicketThreadFailure value)  failure,}){
final _that = this;
switch (_that) {
case TicketThreadLoading():
return loading(_that);case TicketThreadLoaded():
return loaded(_that);case TicketThreadFailure():
return failure(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TicketThreadLoading value)?  loading,TResult? Function( TicketThreadLoaded value)?  loaded,TResult? Function( TicketThreadFailure value)?  failure,}){
final _that = this;
switch (_that) {
case TicketThreadLoading() when loading != null:
return loading(_that);case TicketThreadLoaded() when loaded != null:
return loaded(_that);case TicketThreadFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( SupportTicket ticket,  bool isSending,  Failure? lastFailure)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TicketThreadLoading() when loading != null:
return loading();case TicketThreadLoaded() when loaded != null:
return loaded(_that.ticket,_that.isSending,_that.lastFailure);case TicketThreadFailure() when failure != null:
return failure(_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( SupportTicket ticket,  bool isSending,  Failure? lastFailure)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case TicketThreadLoading():
return loading();case TicketThreadLoaded():
return loaded(_that.ticket,_that.isSending,_that.lastFailure);case TicketThreadFailure():
return failure(_that.failure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( SupportTicket ticket,  bool isSending,  Failure? lastFailure)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case TicketThreadLoading() when loading != null:
return loading();case TicketThreadLoaded() when loaded != null:
return loaded(_that.ticket,_that.isSending,_that.lastFailure);case TicketThreadFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class TicketThreadLoading implements TicketThreadState {
  const TicketThreadLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TicketThreadLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'TicketThreadState.loading()';
}


}




/// @nodoc


class TicketThreadLoaded implements TicketThreadState {
  const TicketThreadLoaded(this.ticket, {this.isSending = false, this.lastFailure});
  

 final  SupportTicket ticket;
/// A reply is in flight. The thread stays on screen and the field locks — a conversation
/// that vanishes behind a spinner every time somebody writes into it reads as broken.
@JsonKey() final  bool isSending;
/// The reply that failed, cleared by the next attempt. The messages already there are
/// still true.
 final  Failure? lastFailure;

/// Create a copy of TicketThreadState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TicketThreadLoadedCopyWith<TicketThreadLoaded> get copyWith => _$TicketThreadLoadedCopyWithImpl<TicketThreadLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TicketThreadLoaded&&(identical(other.ticket, ticket) || other.ticket == ticket)&&(identical(other.isSending, isSending) || other.isSending == isSending)&&(identical(other.lastFailure, lastFailure) || other.lastFailure == lastFailure));
}


@override
int get hashCode => Object.hash(runtimeType,ticket,isSending,lastFailure);

@override
String toString() {
  return 'TicketThreadState.loaded(ticket: $ticket, isSending: $isSending, lastFailure: $lastFailure)';
}


}

/// @nodoc
abstract mixin class $TicketThreadLoadedCopyWith<$Res> implements $TicketThreadStateCopyWith<$Res> {
  factory $TicketThreadLoadedCopyWith(TicketThreadLoaded value, $Res Function(TicketThreadLoaded) _then) = _$TicketThreadLoadedCopyWithImpl;
@useResult
$Res call({
 SupportTicket ticket, bool isSending, Failure? lastFailure
});


$SupportTicketCopyWith<$Res> get ticket;$FailureCopyWith<$Res>? get lastFailure;

}
/// @nodoc
class _$TicketThreadLoadedCopyWithImpl<$Res>
    implements $TicketThreadLoadedCopyWith<$Res> {
  _$TicketThreadLoadedCopyWithImpl(this._self, this._then);

  final TicketThreadLoaded _self;
  final $Res Function(TicketThreadLoaded) _then;

/// Create a copy of TicketThreadState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? ticket = null,Object? isSending = null,Object? lastFailure = freezed,}) {
  return _then(TicketThreadLoaded(
null == ticket ? _self.ticket : ticket // ignore: cast_nullable_to_non_nullable
as SupportTicket,isSending: null == isSending ? _self.isSending : isSending // ignore: cast_nullable_to_non_nullable
as bool,lastFailure: freezed == lastFailure ? _self.lastFailure : lastFailure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of TicketThreadState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SupportTicketCopyWith<$Res> get ticket {
  
  return $SupportTicketCopyWith<$Res>(_self.ticket, (value) {
    return _then(_self.copyWith(ticket: value));
  });
}/// Create a copy of TicketThreadState
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
}
}

/// @nodoc


class TicketThreadFailure implements TicketThreadState {
  const TicketThreadFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of TicketThreadState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TicketThreadFailureCopyWith<TicketThreadFailure> get copyWith => _$TicketThreadFailureCopyWithImpl<TicketThreadFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TicketThreadFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'TicketThreadState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $TicketThreadFailureCopyWith<$Res> implements $TicketThreadStateCopyWith<$Res> {
  factory $TicketThreadFailureCopyWith(TicketThreadFailure value, $Res Function(TicketThreadFailure) _then) = _$TicketThreadFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$TicketThreadFailureCopyWithImpl<$Res>
    implements $TicketThreadFailureCopyWith<$Res> {
  _$TicketThreadFailureCopyWithImpl(this._self, this._then);

  final TicketThreadFailure _self;
  final $Res Function(TicketThreadFailure) _then;

/// Create a copy of TicketThreadState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(TicketThreadFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of TicketThreadState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res> get failure {
  
  return $FailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

// dart format on
