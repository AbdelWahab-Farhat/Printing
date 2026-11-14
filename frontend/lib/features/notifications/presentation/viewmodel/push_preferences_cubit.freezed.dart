// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'push_preferences_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PushPreferencesState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PushPreferencesState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PushPreferencesState()';
}


}

/// @nodoc
class $PushPreferencesStateCopyWith<$Res>  {
$PushPreferencesStateCopyWith(PushPreferencesState _, $Res Function(PushPreferencesState) __);
}


/// Adds pattern-matching-related methods to [PushPreferencesState].
extension PushPreferencesStatePatterns on PushPreferencesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PushPreferencesLoading value)?  loading,TResult Function( PushPreferencesLoaded value)?  loaded,TResult Function( PushPreferencesFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PushPreferencesLoading() when loading != null:
return loading(_that);case PushPreferencesLoaded() when loaded != null:
return loaded(_that);case PushPreferencesFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PushPreferencesLoading value)  loading,required TResult Function( PushPreferencesLoaded value)  loaded,required TResult Function( PushPreferencesFailure value)  failure,}){
final _that = this;
switch (_that) {
case PushPreferencesLoading():
return loading(_that);case PushPreferencesLoaded():
return loaded(_that);case PushPreferencesFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PushPreferencesLoading value)?  loading,TResult? Function( PushPreferencesLoaded value)?  loaded,TResult? Function( PushPreferencesFailure value)?  failure,}){
final _that = this;
switch (_that) {
case PushPreferencesLoading() when loading != null:
return loading(_that);case PushPreferencesLoaded() when loaded != null:
return loaded(_that);case PushPreferencesFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<PushPreferenceGroup> groups,  Failure? failure)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PushPreferencesLoading() when loading != null:
return loading();case PushPreferencesLoaded() when loaded != null:
return loaded(_that.groups,_that.failure);case PushPreferencesFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<PushPreferenceGroup> groups,  Failure? failure)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case PushPreferencesLoading():
return loading();case PushPreferencesLoaded():
return loaded(_that.groups,_that.failure);case PushPreferencesFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<PushPreferenceGroup> groups,  Failure? failure)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case PushPreferencesLoading() when loading != null:
return loading();case PushPreferencesLoaded() when loaded != null:
return loaded(_that.groups,_that.failure);case PushPreferencesFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class PushPreferencesLoading implements PushPreferencesState {
  const PushPreferencesLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PushPreferencesLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PushPreferencesState.loading()';
}


}




/// @nodoc


class PushPreferencesLoaded implements PushPreferencesState {
  const PushPreferencesLoaded(final  List<PushPreferenceGroup> groups, {this.failure}): _groups = groups;
  

 final  List<PushPreferenceGroup> _groups;
 List<PushPreferenceGroup> get groups {
  if (_groups is EqualUnmodifiableListView) return _groups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_groups);
}

 final  Failure? failure;

/// Create a copy of PushPreferencesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PushPreferencesLoadedCopyWith<PushPreferencesLoaded> get copyWith => _$PushPreferencesLoadedCopyWithImpl<PushPreferencesLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PushPreferencesLoaded&&const DeepCollectionEquality().equals(other._groups, _groups)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_groups),failure);

@override
String toString() {
  return 'PushPreferencesState.loaded(groups: $groups, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $PushPreferencesLoadedCopyWith<$Res> implements $PushPreferencesStateCopyWith<$Res> {
  factory $PushPreferencesLoadedCopyWith(PushPreferencesLoaded value, $Res Function(PushPreferencesLoaded) _then) = _$PushPreferencesLoadedCopyWithImpl;
@useResult
$Res call({
 List<PushPreferenceGroup> groups, Failure? failure
});


$FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class _$PushPreferencesLoadedCopyWithImpl<$Res>
    implements $PushPreferencesLoadedCopyWith<$Res> {
  _$PushPreferencesLoadedCopyWithImpl(this._self, this._then);

  final PushPreferencesLoaded _self;
  final $Res Function(PushPreferencesLoaded) _then;

/// Create a copy of PushPreferencesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? groups = null,Object? failure = freezed,}) {
  return _then(PushPreferencesLoaded(
null == groups ? _self._groups : groups // ignore: cast_nullable_to_non_nullable
as List<PushPreferenceGroup>,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of PushPreferencesState
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

/// @nodoc


class PushPreferencesFailure implements PushPreferencesState {
  const PushPreferencesFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of PushPreferencesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PushPreferencesFailureCopyWith<PushPreferencesFailure> get copyWith => _$PushPreferencesFailureCopyWithImpl<PushPreferencesFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PushPreferencesFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'PushPreferencesState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $PushPreferencesFailureCopyWith<$Res> implements $PushPreferencesStateCopyWith<$Res> {
  factory $PushPreferencesFailureCopyWith(PushPreferencesFailure value, $Res Function(PushPreferencesFailure) _then) = _$PushPreferencesFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$PushPreferencesFailureCopyWithImpl<$Res>
    implements $PushPreferencesFailureCopyWith<$Res> {
  _$PushPreferencesFailureCopyWithImpl(this._self, this._then);

  final PushPreferencesFailure _self;
  final $Res Function(PushPreferencesFailure) _then;

/// Create a copy of PushPreferencesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(PushPreferencesFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of PushPreferencesState
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
