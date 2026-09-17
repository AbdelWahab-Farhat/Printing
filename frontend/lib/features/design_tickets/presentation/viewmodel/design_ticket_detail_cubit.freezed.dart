// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'design_ticket_detail_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DesignTicketDetailState {

 DesignTicket? get ticket;
/// Create a copy of DesignTicketDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DesignTicketDetailStateCopyWith<DesignTicketDetailState> get copyWith => _$DesignTicketDetailStateCopyWithImpl<DesignTicketDetailState>(this as DesignTicketDetailState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesignTicketDetailState&&(identical(other.ticket, ticket) || other.ticket == ticket));
}


@override
int get hashCode => Object.hash(runtimeType,ticket);

@override
String toString() {
  return 'DesignTicketDetailState(ticket: $ticket)';
}


}

/// @nodoc
abstract mixin class $DesignTicketDetailStateCopyWith<$Res>  {
  factory $DesignTicketDetailStateCopyWith(DesignTicketDetailState value, $Res Function(DesignTicketDetailState) _then) = _$DesignTicketDetailStateCopyWithImpl;
@useResult
$Res call({
 DesignTicket ticket
});


$DesignTicketCopyWith<$Res>? get ticket;

}
/// @nodoc
class _$DesignTicketDetailStateCopyWithImpl<$Res>
    implements $DesignTicketDetailStateCopyWith<$Res> {
  _$DesignTicketDetailStateCopyWithImpl(this._self, this._then);

  final DesignTicketDetailState _self;
  final $Res Function(DesignTicketDetailState) _then;

/// Create a copy of DesignTicketDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ticket = null,}) {
  return _then(_self.copyWith(
ticket: null == ticket ? _self.ticket! : ticket // ignore: cast_nullable_to_non_nullable
as DesignTicket,
  ));
}
/// Create a copy of DesignTicketDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DesignTicketCopyWith<$Res>? get ticket {
    if (_self.ticket == null) {
    return null;
  }

  return $DesignTicketCopyWith<$Res>(_self.ticket!, (value) {
    return _then(_self.copyWith(ticket: value));
  });
}
}


/// Adds pattern-matching-related methods to [DesignTicketDetailState].
extension DesignTicketDetailStatePatterns on DesignTicketDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DesignTicketDetailLoading value)?  loading,TResult Function( DesignTicketDetailReady value)?  ready,TResult Function( DesignTicketDetailWorking value)?  working,TResult Function( DesignTicketDetailFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DesignTicketDetailLoading() when loading != null:
return loading(_that);case DesignTicketDetailReady() when ready != null:
return ready(_that);case DesignTicketDetailWorking() when working != null:
return working(_that);case DesignTicketDetailFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DesignTicketDetailLoading value)  loading,required TResult Function( DesignTicketDetailReady value)  ready,required TResult Function( DesignTicketDetailWorking value)  working,required TResult Function( DesignTicketDetailFailure value)  failure,}){
final _that = this;
switch (_that) {
case DesignTicketDetailLoading():
return loading(_that);case DesignTicketDetailReady():
return ready(_that);case DesignTicketDetailWorking():
return working(_that);case DesignTicketDetailFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DesignTicketDetailLoading value)?  loading,TResult? Function( DesignTicketDetailReady value)?  ready,TResult? Function( DesignTicketDetailWorking value)?  working,TResult? Function( DesignTicketDetailFailure value)?  failure,}){
final _that = this;
switch (_that) {
case DesignTicketDetailLoading() when loading != null:
return loading(_that);case DesignTicketDetailReady() when ready != null:
return ready(_that);case DesignTicketDetailWorking() when working != null:
return working(_that);case DesignTicketDetailFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( DesignTicket? ticket)?  loading,TResult Function( DesignTicket ticket)?  ready,TResult Function( DesignTicket ticket)?  working,TResult Function( Failure failure,  DesignTicket? ticket)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DesignTicketDetailLoading() when loading != null:
return loading(_that.ticket);case DesignTicketDetailReady() when ready != null:
return ready(_that.ticket);case DesignTicketDetailWorking() when working != null:
return working(_that.ticket);case DesignTicketDetailFailure() when failure != null:
return failure(_that.failure,_that.ticket);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( DesignTicket? ticket)  loading,required TResult Function( DesignTicket ticket)  ready,required TResult Function( DesignTicket ticket)  working,required TResult Function( Failure failure,  DesignTicket? ticket)  failure,}) {final _that = this;
switch (_that) {
case DesignTicketDetailLoading():
return loading(_that.ticket);case DesignTicketDetailReady():
return ready(_that.ticket);case DesignTicketDetailWorking():
return working(_that.ticket);case DesignTicketDetailFailure():
return failure(_that.failure,_that.ticket);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( DesignTicket? ticket)?  loading,TResult? Function( DesignTicket ticket)?  ready,TResult? Function( DesignTicket ticket)?  working,TResult? Function( Failure failure,  DesignTicket? ticket)?  failure,}) {final _that = this;
switch (_that) {
case DesignTicketDetailLoading() when loading != null:
return loading(_that.ticket);case DesignTicketDetailReady() when ready != null:
return ready(_that.ticket);case DesignTicketDetailWorking() when working != null:
return working(_that.ticket);case DesignTicketDetailFailure() when failure != null:
return failure(_that.failure,_that.ticket);case _:
  return null;

}
}

}

/// @nodoc


class DesignTicketDetailLoading implements DesignTicketDetailState {
  const DesignTicketDetailLoading({this.ticket});
  

@override final  DesignTicket? ticket;

/// Create a copy of DesignTicketDetailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DesignTicketDetailLoadingCopyWith<DesignTicketDetailLoading> get copyWith => _$DesignTicketDetailLoadingCopyWithImpl<DesignTicketDetailLoading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesignTicketDetailLoading&&(identical(other.ticket, ticket) || other.ticket == ticket));
}


@override
int get hashCode => Object.hash(runtimeType,ticket);

@override
String toString() {
  return 'DesignTicketDetailState.loading(ticket: $ticket)';
}


}

/// @nodoc
abstract mixin class $DesignTicketDetailLoadingCopyWith<$Res> implements $DesignTicketDetailStateCopyWith<$Res> {
  factory $DesignTicketDetailLoadingCopyWith(DesignTicketDetailLoading value, $Res Function(DesignTicketDetailLoading) _then) = _$DesignTicketDetailLoadingCopyWithImpl;
@override @useResult
$Res call({
 DesignTicket? ticket
});


@override $DesignTicketCopyWith<$Res>? get ticket;

}
/// @nodoc
class _$DesignTicketDetailLoadingCopyWithImpl<$Res>
    implements $DesignTicketDetailLoadingCopyWith<$Res> {
  _$DesignTicketDetailLoadingCopyWithImpl(this._self, this._then);

  final DesignTicketDetailLoading _self;
  final $Res Function(DesignTicketDetailLoading) _then;

/// Create a copy of DesignTicketDetailState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ticket = freezed,}) {
  return _then(DesignTicketDetailLoading(
ticket: freezed == ticket ? _self.ticket : ticket // ignore: cast_nullable_to_non_nullable
as DesignTicket?,
  ));
}

/// Create a copy of DesignTicketDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DesignTicketCopyWith<$Res>? get ticket {
    if (_self.ticket == null) {
    return null;
  }

  return $DesignTicketCopyWith<$Res>(_self.ticket!, (value) {
    return _then(_self.copyWith(ticket: value));
  });
}
}

/// @nodoc


class DesignTicketDetailReady implements DesignTicketDetailState {
  const DesignTicketDetailReady(this.ticket);
  

@override final  DesignTicket ticket;

/// Create a copy of DesignTicketDetailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DesignTicketDetailReadyCopyWith<DesignTicketDetailReady> get copyWith => _$DesignTicketDetailReadyCopyWithImpl<DesignTicketDetailReady>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesignTicketDetailReady&&(identical(other.ticket, ticket) || other.ticket == ticket));
}


@override
int get hashCode => Object.hash(runtimeType,ticket);

@override
String toString() {
  return 'DesignTicketDetailState.ready(ticket: $ticket)';
}


}

/// @nodoc
abstract mixin class $DesignTicketDetailReadyCopyWith<$Res> implements $DesignTicketDetailStateCopyWith<$Res> {
  factory $DesignTicketDetailReadyCopyWith(DesignTicketDetailReady value, $Res Function(DesignTicketDetailReady) _then) = _$DesignTicketDetailReadyCopyWithImpl;
@override @useResult
$Res call({
 DesignTicket ticket
});


@override $DesignTicketCopyWith<$Res> get ticket;

}
/// @nodoc
class _$DesignTicketDetailReadyCopyWithImpl<$Res>
    implements $DesignTicketDetailReadyCopyWith<$Res> {
  _$DesignTicketDetailReadyCopyWithImpl(this._self, this._then);

  final DesignTicketDetailReady _self;
  final $Res Function(DesignTicketDetailReady) _then;

/// Create a copy of DesignTicketDetailState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ticket = null,}) {
  return _then(DesignTicketDetailReady(
null == ticket ? _self.ticket : ticket // ignore: cast_nullable_to_non_nullable
as DesignTicket,
  ));
}

/// Create a copy of DesignTicketDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DesignTicketCopyWith<$Res> get ticket {
  
  return $DesignTicketCopyWith<$Res>(_self.ticket, (value) {
    return _then(_self.copyWith(ticket: value));
  });
}
}

/// @nodoc


class DesignTicketDetailWorking implements DesignTicketDetailState {
  const DesignTicketDetailWorking(this.ticket);
  

@override final  DesignTicket ticket;

/// Create a copy of DesignTicketDetailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DesignTicketDetailWorkingCopyWith<DesignTicketDetailWorking> get copyWith => _$DesignTicketDetailWorkingCopyWithImpl<DesignTicketDetailWorking>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesignTicketDetailWorking&&(identical(other.ticket, ticket) || other.ticket == ticket));
}


@override
int get hashCode => Object.hash(runtimeType,ticket);

@override
String toString() {
  return 'DesignTicketDetailState.working(ticket: $ticket)';
}


}

/// @nodoc
abstract mixin class $DesignTicketDetailWorkingCopyWith<$Res> implements $DesignTicketDetailStateCopyWith<$Res> {
  factory $DesignTicketDetailWorkingCopyWith(DesignTicketDetailWorking value, $Res Function(DesignTicketDetailWorking) _then) = _$DesignTicketDetailWorkingCopyWithImpl;
@override @useResult
$Res call({
 DesignTicket ticket
});


@override $DesignTicketCopyWith<$Res> get ticket;

}
/// @nodoc
class _$DesignTicketDetailWorkingCopyWithImpl<$Res>
    implements $DesignTicketDetailWorkingCopyWith<$Res> {
  _$DesignTicketDetailWorkingCopyWithImpl(this._self, this._then);

  final DesignTicketDetailWorking _self;
  final $Res Function(DesignTicketDetailWorking) _then;

/// Create a copy of DesignTicketDetailState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ticket = null,}) {
  return _then(DesignTicketDetailWorking(
null == ticket ? _self.ticket : ticket // ignore: cast_nullable_to_non_nullable
as DesignTicket,
  ));
}

/// Create a copy of DesignTicketDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DesignTicketCopyWith<$Res> get ticket {
  
  return $DesignTicketCopyWith<$Res>(_self.ticket, (value) {
    return _then(_self.copyWith(ticket: value));
  });
}
}

/// @nodoc


class DesignTicketDetailFailure implements DesignTicketDetailState {
  const DesignTicketDetailFailure(this.failure, {this.ticket});
  

 final  Failure failure;
@override final  DesignTicket? ticket;

/// Create a copy of DesignTicketDetailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DesignTicketDetailFailureCopyWith<DesignTicketDetailFailure> get copyWith => _$DesignTicketDetailFailureCopyWithImpl<DesignTicketDetailFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesignTicketDetailFailure&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.ticket, ticket) || other.ticket == ticket));
}


@override
int get hashCode => Object.hash(runtimeType,failure,ticket);

@override
String toString() {
  return 'DesignTicketDetailState.failure(failure: $failure, ticket: $ticket)';
}


}

/// @nodoc
abstract mixin class $DesignTicketDetailFailureCopyWith<$Res> implements $DesignTicketDetailStateCopyWith<$Res> {
  factory $DesignTicketDetailFailureCopyWith(DesignTicketDetailFailure value, $Res Function(DesignTicketDetailFailure) _then) = _$DesignTicketDetailFailureCopyWithImpl;
@override @useResult
$Res call({
 Failure failure, DesignTicket? ticket
});


$FailureCopyWith<$Res> get failure;@override $DesignTicketCopyWith<$Res>? get ticket;

}
/// @nodoc
class _$DesignTicketDetailFailureCopyWithImpl<$Res>
    implements $DesignTicketDetailFailureCopyWith<$Res> {
  _$DesignTicketDetailFailureCopyWithImpl(this._self, this._then);

  final DesignTicketDetailFailure _self;
  final $Res Function(DesignTicketDetailFailure) _then;

/// Create a copy of DesignTicketDetailState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? failure = null,Object? ticket = freezed,}) {
  return _then(DesignTicketDetailFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,ticket: freezed == ticket ? _self.ticket : ticket // ignore: cast_nullable_to_non_nullable
as DesignTicket?,
  ));
}

/// Create a copy of DesignTicketDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res> get failure {
  
  return $FailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}/// Create a copy of DesignTicketDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DesignTicketCopyWith<$Res>? get ticket {
    if (_self.ticket == null) {
    return null;
  }

  return $DesignTicketCopyWith<$Res>(_self.ticket!, (value) {
    return _then(_self.copyWith(ticket: value));
  });
}
}

// dart format on
