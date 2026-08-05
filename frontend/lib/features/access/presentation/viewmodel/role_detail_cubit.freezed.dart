// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'role_detail_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RoleDetailState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoleDetailState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RoleDetailState()';
}


}

/// @nodoc
class $RoleDetailStateCopyWith<$Res>  {
$RoleDetailStateCopyWith(RoleDetailState _, $Res Function(RoleDetailState) __);
}


/// Adds pattern-matching-related methods to [RoleDetailState].
extension RoleDetailStatePatterns on RoleDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RoleDetailLoading value)?  loading,TResult Function( RoleDetailLoaded value)?  loaded,TResult Function( RoleDetailFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RoleDetailLoading() when loading != null:
return loading(_that);case RoleDetailLoaded() when loaded != null:
return loaded(_that);case RoleDetailFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RoleDetailLoading value)  loading,required TResult Function( RoleDetailLoaded value)  loaded,required TResult Function( RoleDetailFailure value)  failure,}){
final _that = this;
switch (_that) {
case RoleDetailLoading():
return loading(_that);case RoleDetailLoaded():
return loaded(_that);case RoleDetailFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RoleDetailLoading value)?  loading,TResult? Function( RoleDetailLoaded value)?  loaded,TResult? Function( RoleDetailFailure value)?  failure,}){
final _that = this;
switch (_that) {
case RoleDetailLoading() when loading != null:
return loading(_that);case RoleDetailLoaded() when loaded != null:
return loaded(_that);case RoleDetailFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( Role role,  List<PermissionGroup> groups)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RoleDetailLoading() when loading != null:
return loading();case RoleDetailLoaded() when loaded != null:
return loaded(_that.role,_that.groups);case RoleDetailFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( Role role,  List<PermissionGroup> groups)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case RoleDetailLoading():
return loading();case RoleDetailLoaded():
return loaded(_that.role,_that.groups);case RoleDetailFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( Role role,  List<PermissionGroup> groups)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case RoleDetailLoading() when loading != null:
return loading();case RoleDetailLoaded() when loaded != null:
return loaded(_that.role,_that.groups);case RoleDetailFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class RoleDetailLoading implements RoleDetailState {
  const RoleDetailLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoleDetailLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'RoleDetailState.loading()';
}


}




/// @nodoc


class RoleDetailLoaded implements RoleDetailState {
  const RoleDetailLoaded({required this.role, required final  List<PermissionGroup> groups}): _groups = groups;
  

 final  Role role;
/// The role's own permissions, already sorted into the catalogue's sections.
///
/// Computed in the Cubit rather than in the widget, because it is a rule about data — which
/// permission belongs to which part of the business — and the screen's job is to draw the
/// answer, not work it out. Empty for a role that grants nothing, **and for the
/// administrator**, whose access comes from a gate rule rather than rows: see
/// [Role.grantsEverything], which is what the screen shows instead.
 final  List<PermissionGroup> _groups;
/// The role's own permissions, already sorted into the catalogue's sections.
///
/// Computed in the Cubit rather than in the widget, because it is a rule about data — which
/// permission belongs to which part of the business — and the screen's job is to draw the
/// answer, not work it out. Empty for a role that grants nothing, **and for the
/// administrator**, whose access comes from a gate rule rather than rows: see
/// [Role.grantsEverything], which is what the screen shows instead.
 List<PermissionGroup> get groups {
  if (_groups is EqualUnmodifiableListView) return _groups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_groups);
}


/// Create a copy of RoleDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoleDetailLoadedCopyWith<RoleDetailLoaded> get copyWith => _$RoleDetailLoadedCopyWithImpl<RoleDetailLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoleDetailLoaded&&(identical(other.role, role) || other.role == role)&&const DeepCollectionEquality().equals(other._groups, _groups));
}


@override
int get hashCode => Object.hash(runtimeType,role,const DeepCollectionEquality().hash(_groups));

@override
String toString() {
  return 'RoleDetailState.loaded(role: $role, groups: $groups)';
}


}

/// @nodoc
abstract mixin class $RoleDetailLoadedCopyWith<$Res> implements $RoleDetailStateCopyWith<$Res> {
  factory $RoleDetailLoadedCopyWith(RoleDetailLoaded value, $Res Function(RoleDetailLoaded) _then) = _$RoleDetailLoadedCopyWithImpl;
@useResult
$Res call({
 Role role, List<PermissionGroup> groups
});


$RoleCopyWith<$Res> get role;

}
/// @nodoc
class _$RoleDetailLoadedCopyWithImpl<$Res>
    implements $RoleDetailLoadedCopyWith<$Res> {
  _$RoleDetailLoadedCopyWithImpl(this._self, this._then);

  final RoleDetailLoaded _self;
  final $Res Function(RoleDetailLoaded) _then;

/// Create a copy of RoleDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? role = null,Object? groups = null,}) {
  return _then(RoleDetailLoaded(
role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as Role,groups: null == groups ? _self._groups : groups // ignore: cast_nullable_to_non_nullable
as List<PermissionGroup>,
  ));
}

/// Create a copy of RoleDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RoleCopyWith<$Res> get role {
  
  return $RoleCopyWith<$Res>(_self.role, (value) {
    return _then(_self.copyWith(role: value));
  });
}
}

/// @nodoc


class RoleDetailFailure implements RoleDetailState {
  const RoleDetailFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of RoleDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoleDetailFailureCopyWith<RoleDetailFailure> get copyWith => _$RoleDetailFailureCopyWithImpl<RoleDetailFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoleDetailFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'RoleDetailState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $RoleDetailFailureCopyWith<$Res> implements $RoleDetailStateCopyWith<$Res> {
  factory $RoleDetailFailureCopyWith(RoleDetailFailure value, $Res Function(RoleDetailFailure) _then) = _$RoleDetailFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$RoleDetailFailureCopyWithImpl<$Res>
    implements $RoleDetailFailureCopyWith<$Res> {
  _$RoleDetailFailureCopyWithImpl(this._self, this._then);

  final RoleDetailFailure _self;
  final $Res Function(RoleDetailFailure) _then;

/// Create a copy of RoleDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(RoleDetailFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of RoleDetailState
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
