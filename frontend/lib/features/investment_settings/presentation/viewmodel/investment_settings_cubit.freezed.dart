// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'investment_settings_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InvestmentSettingsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestmentSettingsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'InvestmentSettingsState()';
}


}

/// @nodoc
class $InvestmentSettingsStateCopyWith<$Res>  {
$InvestmentSettingsStateCopyWith(InvestmentSettingsState _, $Res Function(InvestmentSettingsState) __);
}


/// Adds pattern-matching-related methods to [InvestmentSettingsState].
extension InvestmentSettingsStatePatterns on InvestmentSettingsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( InvestmentSettingsLoading value)?  loading,TResult Function( InvestmentSettingsLoaded value)?  loaded,TResult Function( InvestmentSettingsFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case InvestmentSettingsLoading() when loading != null:
return loading(_that);case InvestmentSettingsLoaded() when loaded != null:
return loaded(_that);case InvestmentSettingsFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( InvestmentSettingsLoading value)  loading,required TResult Function( InvestmentSettingsLoaded value)  loaded,required TResult Function( InvestmentSettingsFailure value)  failure,}){
final _that = this;
switch (_that) {
case InvestmentSettingsLoading():
return loading(_that);case InvestmentSettingsLoaded():
return loaded(_that);case InvestmentSettingsFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( InvestmentSettingsLoading value)?  loading,TResult? Function( InvestmentSettingsLoaded value)?  loaded,TResult? Function( InvestmentSettingsFailure value)?  failure,}){
final _that = this;
switch (_that) {
case InvestmentSettingsLoading() when loading != null:
return loading(_that);case InvestmentSettingsLoaded() when loaded != null:
return loaded(_that);case InvestmentSettingsFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( InvestmentSettings settings)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case InvestmentSettingsLoading() when loading != null:
return loading();case InvestmentSettingsLoaded() when loaded != null:
return loaded(_that.settings);case InvestmentSettingsFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( InvestmentSettings settings)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case InvestmentSettingsLoading():
return loading();case InvestmentSettingsLoaded():
return loaded(_that.settings);case InvestmentSettingsFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( InvestmentSettings settings)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case InvestmentSettingsLoading() when loading != null:
return loading();case InvestmentSettingsLoaded() when loaded != null:
return loaded(_that.settings);case InvestmentSettingsFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class InvestmentSettingsLoading implements InvestmentSettingsState {
  const InvestmentSettingsLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestmentSettingsLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'InvestmentSettingsState.loading()';
}


}




/// @nodoc


class InvestmentSettingsLoaded implements InvestmentSettingsState {
  const InvestmentSettingsLoaded({required this.settings});
  

 final  InvestmentSettings settings;

/// Create a copy of InvestmentSettingsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvestmentSettingsLoadedCopyWith<InvestmentSettingsLoaded> get copyWith => _$InvestmentSettingsLoadedCopyWithImpl<InvestmentSettingsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestmentSettingsLoaded&&(identical(other.settings, settings) || other.settings == settings));
}


@override
int get hashCode => Object.hash(runtimeType,settings);

@override
String toString() {
  return 'InvestmentSettingsState.loaded(settings: $settings)';
}


}

/// @nodoc
abstract mixin class $InvestmentSettingsLoadedCopyWith<$Res> implements $InvestmentSettingsStateCopyWith<$Res> {
  factory $InvestmentSettingsLoadedCopyWith(InvestmentSettingsLoaded value, $Res Function(InvestmentSettingsLoaded) _then) = _$InvestmentSettingsLoadedCopyWithImpl;
@useResult
$Res call({
 InvestmentSettings settings
});


$InvestmentSettingsCopyWith<$Res> get settings;

}
/// @nodoc
class _$InvestmentSettingsLoadedCopyWithImpl<$Res>
    implements $InvestmentSettingsLoadedCopyWith<$Res> {
  _$InvestmentSettingsLoadedCopyWithImpl(this._self, this._then);

  final InvestmentSettingsLoaded _self;
  final $Res Function(InvestmentSettingsLoaded) _then;

/// Create a copy of InvestmentSettingsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? settings = null,}) {
  return _then(InvestmentSettingsLoaded(
settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as InvestmentSettings,
  ));
}

/// Create a copy of InvestmentSettingsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InvestmentSettingsCopyWith<$Res> get settings {
  
  return $InvestmentSettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}
}

/// @nodoc


class InvestmentSettingsFailure implements InvestmentSettingsState {
  const InvestmentSettingsFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of InvestmentSettingsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvestmentSettingsFailureCopyWith<InvestmentSettingsFailure> get copyWith => _$InvestmentSettingsFailureCopyWithImpl<InvestmentSettingsFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestmentSettingsFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'InvestmentSettingsState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $InvestmentSettingsFailureCopyWith<$Res> implements $InvestmentSettingsStateCopyWith<$Res> {
  factory $InvestmentSettingsFailureCopyWith(InvestmentSettingsFailure value, $Res Function(InvestmentSettingsFailure) _then) = _$InvestmentSettingsFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$InvestmentSettingsFailureCopyWithImpl<$Res>
    implements $InvestmentSettingsFailureCopyWith<$Res> {
  _$InvestmentSettingsFailureCopyWithImpl(this._self, this._then);

  final InvestmentSettingsFailure _self;
  final $Res Function(InvestmentSettingsFailure) _then;

/// Create a copy of InvestmentSettingsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(InvestmentSettingsFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of InvestmentSettingsState
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
