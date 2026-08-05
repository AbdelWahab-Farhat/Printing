// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'roles_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RolesState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RolesState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RolesState()';
}


}

/// @nodoc
class $RolesStateCopyWith<$Res>  {
$RolesStateCopyWith(RolesState _, $Res Function(RolesState) __);
}


/// Adds pattern-matching-related methods to [RolesState].
extension RolesStatePatterns on RolesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RolesLoading value)?  loading,TResult Function( RolesLoaded value)?  loaded,TResult Function( RolesFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RolesLoading() when loading != null:
return loading(_that);case RolesLoaded() when loaded != null:
return loaded(_that);case RolesFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RolesLoading value)  loading,required TResult Function( RolesLoaded value)  loaded,required TResult Function( RolesFailure value)  failure,}){
final _that = this;
switch (_that) {
case RolesLoading():
return loading(_that);case RolesLoaded():
return loaded(_that);case RolesFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RolesLoading value)?  loading,TResult? Function( RolesLoaded value)?  loaded,TResult? Function( RolesFailure value)?  failure,}){
final _that = this;
switch (_that) {
case RolesLoading() when loading != null:
return loading(_that);case RolesLoaded() when loaded != null:
return loaded(_that);case RolesFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<Role> roles,  int? deletingId)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RolesLoading() when loading != null:
return loading();case RolesLoaded() when loaded != null:
return loaded(_that.roles,_that.deletingId);case RolesFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<Role> roles,  int? deletingId)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case RolesLoading():
return loading();case RolesLoaded():
return loaded(_that.roles,_that.deletingId);case RolesFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<Role> roles,  int? deletingId)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case RolesLoading() when loading != null:
return loading();case RolesLoaded() when loaded != null:
return loaded(_that.roles,_that.deletingId);case RolesFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class RolesLoading implements RolesState {
  const RolesLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RolesLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RolesState.loading()';
}


}




/// @nodoc


class RolesLoaded implements RolesState {
  const RolesLoaded({required final  List<Role> roles, this.deletingId}): _roles = roles;
  

 final  List<Role> _roles;
 List<Role> get roles {
  if (_roles is EqualUnmodifiableListView) return _roles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_roles);
}

/// Which row is being deleted right now, if any. Inside `loaded` rather than a case of its
/// own, because the rest of the list stays on screen and usable while it happens.
 final  int? deletingId;

/// Create a copy of RolesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RolesLoadedCopyWith<RolesLoaded> get copyWith => _$RolesLoadedCopyWithImpl<RolesLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RolesLoaded&&const DeepCollectionEquality().equals(other._roles, _roles)&&(identical(other.deletingId, deletingId) || other.deletingId == deletingId));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_roles),deletingId);

@override
String toString() {
  return 'RolesState.loaded(roles: $roles, deletingId: $deletingId)';
}


}

/// @nodoc
abstract mixin class $RolesLoadedCopyWith<$Res> implements $RolesStateCopyWith<$Res> {
  factory $RolesLoadedCopyWith(RolesLoaded value, $Res Function(RolesLoaded) _then) = _$RolesLoadedCopyWithImpl;
@useResult
$Res call({
 List<Role> roles, int? deletingId
});




}
/// @nodoc
class _$RolesLoadedCopyWithImpl<$Res>
    implements $RolesLoadedCopyWith<$Res> {
  _$RolesLoadedCopyWithImpl(this._self, this._then);

  final RolesLoaded _self;
  final $Res Function(RolesLoaded) _then;

/// Create a copy of RolesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? roles = null,Object? deletingId = freezed,}) {
  return _then(RolesLoaded(
roles: null == roles ? _self._roles : roles // ignore: cast_nullable_to_non_nullable
as List<Role>,deletingId: freezed == deletingId ? _self.deletingId : deletingId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc


class RolesFailure implements RolesState {
  const RolesFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of RolesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RolesFailureCopyWith<RolesFailure> get copyWith => _$RolesFailureCopyWithImpl<RolesFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RolesFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'RolesState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $RolesFailureCopyWith<$Res> implements $RolesStateCopyWith<$Res> {
  factory $RolesFailureCopyWith(RolesFailure value, $Res Function(RolesFailure) _then) = _$RolesFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$RolesFailureCopyWithImpl<$Res>
    implements $RolesFailureCopyWith<$Res> {
  _$RolesFailureCopyWithImpl(this._self, this._then);

  final RolesFailure _self;
  final $Res Function(RolesFailure) _then;

/// Create a copy of RolesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(RolesFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of RolesState
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
