// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'company_settings_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CompanySettingsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompanySettingsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CompanySettingsState()';
}


}

/// @nodoc
class $CompanySettingsStateCopyWith<$Res>  {
$CompanySettingsStateCopyWith(CompanySettingsState _, $Res Function(CompanySettingsState) __);
}


/// Adds pattern-matching-related methods to [CompanySettingsState].
extension CompanySettingsStatePatterns on CompanySettingsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CompanySettingsLoading value)?  loading,TResult Function( CompanySettingsLoaded value)?  loaded,TResult Function( CompanySettingsFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CompanySettingsLoading() when loading != null:
return loading(_that);case CompanySettingsLoaded() when loaded != null:
return loaded(_that);case CompanySettingsFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CompanySettingsLoading value)  loading,required TResult Function( CompanySettingsLoaded value)  loaded,required TResult Function( CompanySettingsFailure value)  failure,}){
final _that = this;
switch (_that) {
case CompanySettingsLoading():
return loading(_that);case CompanySettingsLoaded():
return loaded(_that);case CompanySettingsFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CompanySettingsLoading value)?  loading,TResult? Function( CompanySettingsLoaded value)?  loaded,TResult? Function( CompanySettingsFailure value)?  failure,}){
final _that = this;
switch (_that) {
case CompanySettingsLoading() when loading != null:
return loading(_that);case CompanySettingsLoaded() when loaded != null:
return loaded(_that);case CompanySettingsFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( CompanySettings settings)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CompanySettingsLoading() when loading != null:
return loading();case CompanySettingsLoaded() when loaded != null:
return loaded(_that.settings);case CompanySettingsFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( CompanySettings settings)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case CompanySettingsLoading():
return loading();case CompanySettingsLoaded():
return loaded(_that.settings);case CompanySettingsFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( CompanySettings settings)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case CompanySettingsLoading() when loading != null:
return loading();case CompanySettingsLoaded() when loaded != null:
return loaded(_that.settings);case CompanySettingsFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class CompanySettingsLoading implements CompanySettingsState {
  const CompanySettingsLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompanySettingsLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CompanySettingsState.loading()';
}


}




/// @nodoc


class CompanySettingsLoaded implements CompanySettingsState {
  const CompanySettingsLoaded({required this.settings});
  

 final  CompanySettings settings;

/// Create a copy of CompanySettingsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompanySettingsLoadedCopyWith<CompanySettingsLoaded> get copyWith => _$CompanySettingsLoadedCopyWithImpl<CompanySettingsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompanySettingsLoaded&&(identical(other.settings, settings) || other.settings == settings));
}


@override
int get hashCode => Object.hash(runtimeType,settings);

@override
String toString() {
  return 'CompanySettingsState.loaded(settings: $settings)';
}


}

/// @nodoc
abstract mixin class $CompanySettingsLoadedCopyWith<$Res> implements $CompanySettingsStateCopyWith<$Res> {
  factory $CompanySettingsLoadedCopyWith(CompanySettingsLoaded value, $Res Function(CompanySettingsLoaded) _then) = _$CompanySettingsLoadedCopyWithImpl;
@useResult
$Res call({
 CompanySettings settings
});


$CompanySettingsCopyWith<$Res> get settings;

}
/// @nodoc
class _$CompanySettingsLoadedCopyWithImpl<$Res>
    implements $CompanySettingsLoadedCopyWith<$Res> {
  _$CompanySettingsLoadedCopyWithImpl(this._self, this._then);

  final CompanySettingsLoaded _self;
  final $Res Function(CompanySettingsLoaded) _then;

/// Create a copy of CompanySettingsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? settings = null,}) {
  return _then(CompanySettingsLoaded(
settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as CompanySettings,
  ));
}

/// Create a copy of CompanySettingsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CompanySettingsCopyWith<$Res> get settings {
  
  return $CompanySettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}
}

/// @nodoc


class CompanySettingsFailure implements CompanySettingsState {
  const CompanySettingsFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of CompanySettingsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompanySettingsFailureCopyWith<CompanySettingsFailure> get copyWith => _$CompanySettingsFailureCopyWithImpl<CompanySettingsFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompanySettingsFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'CompanySettingsState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $CompanySettingsFailureCopyWith<$Res> implements $CompanySettingsStateCopyWith<$Res> {
  factory $CompanySettingsFailureCopyWith(CompanySettingsFailure value, $Res Function(CompanySettingsFailure) _then) = _$CompanySettingsFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$CompanySettingsFailureCopyWithImpl<$Res>
    implements $CompanySettingsFailureCopyWith<$Res> {
  _$CompanySettingsFailureCopyWithImpl(this._self, this._then);

  final CompanySettingsFailure _self;
  final $Res Function(CompanySettingsFailure) _then;

/// Create a copy of CompanySettingsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(CompanySettingsFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of CompanySettingsState
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
