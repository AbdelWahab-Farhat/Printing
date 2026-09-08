// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'unread_badge_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$UnreadBadgeState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnreadBadgeState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UnreadBadgeState()';
}


}

/// @nodoc
class $UnreadBadgeStateCopyWith<$Res>  {
$UnreadBadgeStateCopyWith(UnreadBadgeState _, $Res Function(UnreadBadgeState) __);
}


/// Adds pattern-matching-related methods to [UnreadBadgeState].
extension UnreadBadgeStatePatterns on UnreadBadgeState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( UnreadBadgeInitial value)?  initial,TResult Function( UnreadBadgeLoading value)?  loading,TResult Function( UnreadBadgeLoaded value)?  loaded,TResult Function( UnreadBadgeFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case UnreadBadgeInitial() when initial != null:
return initial(_that);case UnreadBadgeLoading() when loading != null:
return loading(_that);case UnreadBadgeLoaded() when loaded != null:
return loaded(_that);case UnreadBadgeFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( UnreadBadgeInitial value)  initial,required TResult Function( UnreadBadgeLoading value)  loading,required TResult Function( UnreadBadgeLoaded value)  loaded,required TResult Function( UnreadBadgeFailure value)  failure,}){
final _that = this;
switch (_that) {
case UnreadBadgeInitial():
return initial(_that);case UnreadBadgeLoading():
return loading(_that);case UnreadBadgeLoaded():
return loaded(_that);case UnreadBadgeFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( UnreadBadgeInitial value)?  initial,TResult? Function( UnreadBadgeLoading value)?  loading,TResult? Function( UnreadBadgeLoaded value)?  loaded,TResult? Function( UnreadBadgeFailure value)?  failure,}){
final _that = this;
switch (_that) {
case UnreadBadgeInitial() when initial != null:
return initial(_that);case UnreadBadgeLoading() when loading != null:
return loading(_that);case UnreadBadgeLoaded() when loaded != null:
return loaded(_that);case UnreadBadgeFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( int count)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case UnreadBadgeInitial() when initial != null:
return initial();case UnreadBadgeLoading() when loading != null:
return loading();case UnreadBadgeLoaded() when loaded != null:
return loaded(_that.count);case UnreadBadgeFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( int count)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case UnreadBadgeInitial():
return initial();case UnreadBadgeLoading():
return loading();case UnreadBadgeLoaded():
return loaded(_that.count);case UnreadBadgeFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( int count)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case UnreadBadgeInitial() when initial != null:
return initial();case UnreadBadgeLoading() when loading != null:
return loading();case UnreadBadgeLoaded() when loaded != null:
return loaded(_that.count);case UnreadBadgeFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class UnreadBadgeInitial implements UnreadBadgeState {
  const UnreadBadgeInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnreadBadgeInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UnreadBadgeState.initial()';
}


}




/// @nodoc


class UnreadBadgeLoading implements UnreadBadgeState {
  const UnreadBadgeLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnreadBadgeLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'UnreadBadgeState.loading()';
}


}




/// @nodoc


class UnreadBadgeLoaded implements UnreadBadgeState {
  const UnreadBadgeLoaded(this.count);
  

 final  int count;

/// Create a copy of UnreadBadgeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnreadBadgeLoadedCopyWith<UnreadBadgeLoaded> get copyWith => _$UnreadBadgeLoadedCopyWithImpl<UnreadBadgeLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnreadBadgeLoaded&&(identical(other.count, count) || other.count == count));
}


@override
int get hashCode => Object.hash(runtimeType,count);

@override
String toString() {
  return 'UnreadBadgeState.loaded(count: $count)';
}


}

/// @nodoc
abstract mixin class $UnreadBadgeLoadedCopyWith<$Res> implements $UnreadBadgeStateCopyWith<$Res> {
  factory $UnreadBadgeLoadedCopyWith(UnreadBadgeLoaded value, $Res Function(UnreadBadgeLoaded) _then) = _$UnreadBadgeLoadedCopyWithImpl;
@useResult
$Res call({
 int count
});




}
/// @nodoc
class _$UnreadBadgeLoadedCopyWithImpl<$Res>
    implements $UnreadBadgeLoadedCopyWith<$Res> {
  _$UnreadBadgeLoadedCopyWithImpl(this._self, this._then);

  final UnreadBadgeLoaded _self;
  final $Res Function(UnreadBadgeLoaded) _then;

/// Create a copy of UnreadBadgeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? count = null,}) {
  return _then(UnreadBadgeLoaded(
null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class UnreadBadgeFailure implements UnreadBadgeState {
  const UnreadBadgeFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of UnreadBadgeState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnreadBadgeFailureCopyWith<UnreadBadgeFailure> get copyWith => _$UnreadBadgeFailureCopyWithImpl<UnreadBadgeFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnreadBadgeFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'UnreadBadgeState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $UnreadBadgeFailureCopyWith<$Res> implements $UnreadBadgeStateCopyWith<$Res> {
  factory $UnreadBadgeFailureCopyWith(UnreadBadgeFailure value, $Res Function(UnreadBadgeFailure) _then) = _$UnreadBadgeFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$UnreadBadgeFailureCopyWithImpl<$Res>
    implements $UnreadBadgeFailureCopyWith<$Res> {
  _$UnreadBadgeFailureCopyWithImpl(this._self, this._then);

  final UnreadBadgeFailure _self;
  final $Res Function(UnreadBadgeFailure) _then;

/// Create a copy of UnreadBadgeState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(UnreadBadgeFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of UnreadBadgeState
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
