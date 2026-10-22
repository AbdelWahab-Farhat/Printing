// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'internal_tickets_home_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InternalTicketsHomeState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InternalTicketsHomeState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'InternalTicketsHomeState()';
}


}

/// @nodoc
class $InternalTicketsHomeStateCopyWith<$Res>  {
$InternalTicketsHomeStateCopyWith(InternalTicketsHomeState _, $Res Function(InternalTicketsHomeState) __);
}


/// Adds pattern-matching-related methods to [InternalTicketsHomeState].
extension InternalTicketsHomeStatePatterns on InternalTicketsHomeState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( InternalTicketsHomeLoading value)?  loading,TResult Function( InternalTicketsHomeFailure value)?  failure,TResult Function( InternalTicketsHomeLoaded value)?  loaded,required TResult orElse(),}){
final _that = this;
switch (_that) {
case InternalTicketsHomeLoading() when loading != null:
return loading(_that);case InternalTicketsHomeFailure() when failure != null:
return failure(_that);case InternalTicketsHomeLoaded() when loaded != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( InternalTicketsHomeLoading value)  loading,required TResult Function( InternalTicketsHomeFailure value)  failure,required TResult Function( InternalTicketsHomeLoaded value)  loaded,}){
final _that = this;
switch (_that) {
case InternalTicketsHomeLoading():
return loading(_that);case InternalTicketsHomeFailure():
return failure(_that);case InternalTicketsHomeLoaded():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( InternalTicketsHomeLoading value)?  loading,TResult? Function( InternalTicketsHomeFailure value)?  failure,TResult? Function( InternalTicketsHomeLoaded value)?  loaded,}){
final _that = this;
switch (_that) {
case InternalTicketsHomeLoading() when loading != null:
return loading(_that);case InternalTicketsHomeFailure() when failure != null:
return failure(_that);case InternalTicketsHomeLoaded() when loaded != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( Failure failure)?  failure,TResult Function( InternalTicketsHome home,  int? replyingTo,  Failure? lastFailure)?  loaded,required TResult orElse(),}) {final _that = this;
switch (_that) {
case InternalTicketsHomeLoading() when loading != null:
return loading();case InternalTicketsHomeFailure() when failure != null:
return failure(_that.failure);case InternalTicketsHomeLoaded() when loaded != null:
return loaded(_that.home,_that.replyingTo,_that.lastFailure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( Failure failure)  failure,required TResult Function( InternalTicketsHome home,  int? replyingTo,  Failure? lastFailure)  loaded,}) {final _that = this;
switch (_that) {
case InternalTicketsHomeLoading():
return loading();case InternalTicketsHomeFailure():
return failure(_that.failure);case InternalTicketsHomeLoaded():
return loaded(_that.home,_that.replyingTo,_that.lastFailure);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( Failure failure)?  failure,TResult? Function( InternalTicketsHome home,  int? replyingTo,  Failure? lastFailure)?  loaded,}) {final _that = this;
switch (_that) {
case InternalTicketsHomeLoading() when loading != null:
return loading();case InternalTicketsHomeFailure() when failure != null:
return failure(_that.failure);case InternalTicketsHomeLoaded() when loaded != null:
return loaded(_that.home,_that.replyingTo,_that.lastFailure);case _:
  return null;

}
}

}

/// @nodoc


class InternalTicketsHomeLoading implements InternalTicketsHomeState {
  const InternalTicketsHomeLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InternalTicketsHomeLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'InternalTicketsHomeState.loading()';
}


}




/// @nodoc


class InternalTicketsHomeFailure implements InternalTicketsHomeState {
  const InternalTicketsHomeFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of InternalTicketsHomeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InternalTicketsHomeFailureCopyWith<InternalTicketsHomeFailure> get copyWith => _$InternalTicketsHomeFailureCopyWithImpl<InternalTicketsHomeFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InternalTicketsHomeFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'InternalTicketsHomeState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $InternalTicketsHomeFailureCopyWith<$Res> implements $InternalTicketsHomeStateCopyWith<$Res> {
  factory $InternalTicketsHomeFailureCopyWith(InternalTicketsHomeFailure value, $Res Function(InternalTicketsHomeFailure) _then) = _$InternalTicketsHomeFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$InternalTicketsHomeFailureCopyWithImpl<$Res>
    implements $InternalTicketsHomeFailureCopyWith<$Res> {
  _$InternalTicketsHomeFailureCopyWithImpl(this._self, this._then);

  final InternalTicketsHomeFailure _self;
  final $Res Function(InternalTicketsHomeFailure) _then;

/// Create a copy of InternalTicketsHomeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(InternalTicketsHomeFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of InternalTicketsHomeState
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


class InternalTicketsHomeLoaded implements InternalTicketsHomeState {
  const InternalTicketsHomeLoaded({required this.home, this.replyingTo, this.lastFailure});
  

 final  InternalTicketsHome home;
/// التذكرةُ التي يُرسل إليها ردٌّ سريع الآن.
 final  int? replyingTo;
 final  Failure? lastFailure;

/// Create a copy of InternalTicketsHomeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InternalTicketsHomeLoadedCopyWith<InternalTicketsHomeLoaded> get copyWith => _$InternalTicketsHomeLoadedCopyWithImpl<InternalTicketsHomeLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InternalTicketsHomeLoaded&&(identical(other.home, home) || other.home == home)&&(identical(other.replyingTo, replyingTo) || other.replyingTo == replyingTo)&&(identical(other.lastFailure, lastFailure) || other.lastFailure == lastFailure));
}


@override
int get hashCode => Object.hash(runtimeType,home,replyingTo,lastFailure);

@override
String toString() {
  return 'InternalTicketsHomeState.loaded(home: $home, replyingTo: $replyingTo, lastFailure: $lastFailure)';
}


}

/// @nodoc
abstract mixin class $InternalTicketsHomeLoadedCopyWith<$Res> implements $InternalTicketsHomeStateCopyWith<$Res> {
  factory $InternalTicketsHomeLoadedCopyWith(InternalTicketsHomeLoaded value, $Res Function(InternalTicketsHomeLoaded) _then) = _$InternalTicketsHomeLoadedCopyWithImpl;
@useResult
$Res call({
 InternalTicketsHome home, int? replyingTo, Failure? lastFailure
});


$InternalTicketsHomeCopyWith<$Res> get home;$FailureCopyWith<$Res>? get lastFailure;

}
/// @nodoc
class _$InternalTicketsHomeLoadedCopyWithImpl<$Res>
    implements $InternalTicketsHomeLoadedCopyWith<$Res> {
  _$InternalTicketsHomeLoadedCopyWithImpl(this._self, this._then);

  final InternalTicketsHomeLoaded _self;
  final $Res Function(InternalTicketsHomeLoaded) _then;

/// Create a copy of InternalTicketsHomeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? home = null,Object? replyingTo = freezed,Object? lastFailure = freezed,}) {
  return _then(InternalTicketsHomeLoaded(
home: null == home ? _self.home : home // ignore: cast_nullable_to_non_nullable
as InternalTicketsHome,replyingTo: freezed == replyingTo ? _self.replyingTo : replyingTo // ignore: cast_nullable_to_non_nullable
as int?,lastFailure: freezed == lastFailure ? _self.lastFailure : lastFailure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of InternalTicketsHomeState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InternalTicketsHomeCopyWith<$Res> get home {
  
  return $InternalTicketsHomeCopyWith<$Res>(_self.home, (value) {
    return _then(_self.copyWith(home: value));
  });
}/// Create a copy of InternalTicketsHomeState
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

// dart format on
