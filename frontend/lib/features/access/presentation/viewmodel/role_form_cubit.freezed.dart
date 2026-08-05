// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'role_form_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RoleFormState {

/// The catalogue, in the server's own sections.
 List<PermissionGroup> get catalogue;/// What is ticked right now. Machine names, because that is what the API is given.
 Set<String> get selected; bool get isLoadingCatalogue; bool get isSubmitting;/// The role as the **server** stored it. The screen navigates on this rather than on what
/// was typed, so what appears next is what was actually saved.
 Role? get saved; Failure? get failure;
/// Create a copy of RoleFormState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RoleFormStateCopyWith<RoleFormState> get copyWith => _$RoleFormStateCopyWithImpl<RoleFormState>(this as RoleFormState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RoleFormState&&const DeepCollectionEquality().equals(other.catalogue, catalogue)&&const DeepCollectionEquality().equals(other.selected, selected)&&(identical(other.isLoadingCatalogue, isLoadingCatalogue) || other.isLoadingCatalogue == isLoadingCatalogue)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&(identical(other.saved, saved) || other.saved == saved)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(catalogue),const DeepCollectionEquality().hash(selected),isLoadingCatalogue,isSubmitting,saved,failure);

@override
String toString() {
  return 'RoleFormState(catalogue: $catalogue, selected: $selected, isLoadingCatalogue: $isLoadingCatalogue, isSubmitting: $isSubmitting, saved: $saved, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $RoleFormStateCopyWith<$Res>  {
  factory $RoleFormStateCopyWith(RoleFormState value, $Res Function(RoleFormState) _then) = _$RoleFormStateCopyWithImpl;
@useResult
$Res call({
 List<PermissionGroup> catalogue, Set<String> selected, bool isLoadingCatalogue, bool isSubmitting, Role? saved, Failure? failure
});


$RoleCopyWith<$Res>? get saved;$FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class _$RoleFormStateCopyWithImpl<$Res>
    implements $RoleFormStateCopyWith<$Res> {
  _$RoleFormStateCopyWithImpl(this._self, this._then);

  final RoleFormState _self;
  final $Res Function(RoleFormState) _then;

/// Create a copy of RoleFormState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? catalogue = null,Object? selected = null,Object? isLoadingCatalogue = null,Object? isSubmitting = null,Object? saved = freezed,Object? failure = freezed,}) {
  return _then(_self.copyWith(
catalogue: null == catalogue ? _self.catalogue : catalogue // ignore: cast_nullable_to_non_nullable
as List<PermissionGroup>,selected: null == selected ? _self.selected : selected // ignore: cast_nullable_to_non_nullable
as Set<String>,isLoadingCatalogue: null == isLoadingCatalogue ? _self.isLoadingCatalogue : isLoadingCatalogue // ignore: cast_nullable_to_non_nullable
as bool,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,saved: freezed == saved ? _self.saved : saved // ignore: cast_nullable_to_non_nullable
as Role?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}
/// Create a copy of RoleFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RoleCopyWith<$Res>? get saved {
    if (_self.saved == null) {
    return null;
  }

  return $RoleCopyWith<$Res>(_self.saved!, (value) {
    return _then(_self.copyWith(saved: value));
  });
}/// Create a copy of RoleFormState
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


/// Adds pattern-matching-related methods to [RoleFormState].
extension RoleFormStatePatterns on RoleFormState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RoleFormState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RoleFormState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RoleFormState value)  $default,){
final _that = this;
switch (_that) {
case _RoleFormState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RoleFormState value)?  $default,){
final _that = this;
switch (_that) {
case _RoleFormState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<PermissionGroup> catalogue,  Set<String> selected,  bool isLoadingCatalogue,  bool isSubmitting,  Role? saved,  Failure? failure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RoleFormState() when $default != null:
return $default(_that.catalogue,_that.selected,_that.isLoadingCatalogue,_that.isSubmitting,_that.saved,_that.failure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<PermissionGroup> catalogue,  Set<String> selected,  bool isLoadingCatalogue,  bool isSubmitting,  Role? saved,  Failure? failure)  $default,) {final _that = this;
switch (_that) {
case _RoleFormState():
return $default(_that.catalogue,_that.selected,_that.isLoadingCatalogue,_that.isSubmitting,_that.saved,_that.failure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<PermissionGroup> catalogue,  Set<String> selected,  bool isLoadingCatalogue,  bool isSubmitting,  Role? saved,  Failure? failure)?  $default,) {final _that = this;
switch (_that) {
case _RoleFormState() when $default != null:
return $default(_that.catalogue,_that.selected,_that.isLoadingCatalogue,_that.isSubmitting,_that.saved,_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class _RoleFormState extends RoleFormState {
  const _RoleFormState({final  List<PermissionGroup> catalogue = const <PermissionGroup>[], final  Set<String> selected = const <String>{}, this.isLoadingCatalogue = false, this.isSubmitting = false, this.saved, this.failure}): _catalogue = catalogue,_selected = selected,super._();
  

/// The catalogue, in the server's own sections.
 final  List<PermissionGroup> _catalogue;
/// The catalogue, in the server's own sections.
@override@JsonKey() List<PermissionGroup> get catalogue {
  if (_catalogue is EqualUnmodifiableListView) return _catalogue;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_catalogue);
}

/// What is ticked right now. Machine names, because that is what the API is given.
 final  Set<String> _selected;
/// What is ticked right now. Machine names, because that is what the API is given.
@override@JsonKey() Set<String> get selected {
  if (_selected is EqualUnmodifiableSetView) return _selected;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_selected);
}

@override@JsonKey() final  bool isLoadingCatalogue;
@override@JsonKey() final  bool isSubmitting;
/// The role as the **server** stored it. The screen navigates on this rather than on what
/// was typed, so what appears next is what was actually saved.
@override final  Role? saved;
@override final  Failure? failure;

/// Create a copy of RoleFormState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RoleFormStateCopyWith<_RoleFormState> get copyWith => __$RoleFormStateCopyWithImpl<_RoleFormState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RoleFormState&&const DeepCollectionEquality().equals(other._catalogue, _catalogue)&&const DeepCollectionEquality().equals(other._selected, _selected)&&(identical(other.isLoadingCatalogue, isLoadingCatalogue) || other.isLoadingCatalogue == isLoadingCatalogue)&&(identical(other.isSubmitting, isSubmitting) || other.isSubmitting == isSubmitting)&&(identical(other.saved, saved) || other.saved == saved)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_catalogue),const DeepCollectionEquality().hash(_selected),isLoadingCatalogue,isSubmitting,saved,failure);

@override
String toString() {
  return 'RoleFormState(catalogue: $catalogue, selected: $selected, isLoadingCatalogue: $isLoadingCatalogue, isSubmitting: $isSubmitting, saved: $saved, failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$RoleFormStateCopyWith<$Res> implements $RoleFormStateCopyWith<$Res> {
  factory _$RoleFormStateCopyWith(_RoleFormState value, $Res Function(_RoleFormState) _then) = __$RoleFormStateCopyWithImpl;
@override @useResult
$Res call({
 List<PermissionGroup> catalogue, Set<String> selected, bool isLoadingCatalogue, bool isSubmitting, Role? saved, Failure? failure
});


@override $RoleCopyWith<$Res>? get saved;@override $FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class __$RoleFormStateCopyWithImpl<$Res>
    implements _$RoleFormStateCopyWith<$Res> {
  __$RoleFormStateCopyWithImpl(this._self, this._then);

  final _RoleFormState _self;
  final $Res Function(_RoleFormState) _then;

/// Create a copy of RoleFormState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? catalogue = null,Object? selected = null,Object? isLoadingCatalogue = null,Object? isSubmitting = null,Object? saved = freezed,Object? failure = freezed,}) {
  return _then(_RoleFormState(
catalogue: null == catalogue ? _self._catalogue : catalogue // ignore: cast_nullable_to_non_nullable
as List<PermissionGroup>,selected: null == selected ? _self._selected : selected // ignore: cast_nullable_to_non_nullable
as Set<String>,isLoadingCatalogue: null == isLoadingCatalogue ? _self.isLoadingCatalogue : isLoadingCatalogue // ignore: cast_nullable_to_non_nullable
as bool,isSubmitting: null == isSubmitting ? _self.isSubmitting : isSubmitting // ignore: cast_nullable_to_non_nullable
as bool,saved: freezed == saved ? _self.saved : saved // ignore: cast_nullable_to_non_nullable
as Role?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of RoleFormState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RoleCopyWith<$Res>? get saved {
    if (_self.saved == null) {
    return null;
  }

  return $RoleCopyWith<$Res>(_self.saved!, (value) {
    return _then(_self.copyWith(saved: value));
  });
}/// Create a copy of RoleFormState
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
