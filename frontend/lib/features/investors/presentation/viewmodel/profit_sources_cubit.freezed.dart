// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profit_sources_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProfitSourcesState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfitSourcesState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProfitSourcesState()';
}


}

/// @nodoc
class $ProfitSourcesStateCopyWith<$Res>  {
$ProfitSourcesStateCopyWith(ProfitSourcesState _, $Res Function(ProfitSourcesState) __);
}


/// Adds pattern-matching-related methods to [ProfitSourcesState].
extension ProfitSourcesStatePatterns on ProfitSourcesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ProfitSourcesLoading value)?  loading,TResult Function( ProfitSourcesLoaded value)?  loaded,TResult Function( ProfitSourcesFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ProfitSourcesLoading() when loading != null:
return loading(_that);case ProfitSourcesLoaded() when loaded != null:
return loaded(_that);case ProfitSourcesFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ProfitSourcesLoading value)  loading,required TResult Function( ProfitSourcesLoaded value)  loaded,required TResult Function( ProfitSourcesFailure value)  failure,}){
final _that = this;
switch (_that) {
case ProfitSourcesLoading():
return loading(_that);case ProfitSourcesLoaded():
return loaded(_that);case ProfitSourcesFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ProfitSourcesLoading value)?  loading,TResult? Function( ProfitSourcesLoaded value)?  loaded,TResult? Function( ProfitSourcesFailure value)?  failure,}){
final _that = this;
switch (_that) {
case ProfitSourcesLoading() when loading != null:
return loading(_that);case ProfitSourcesLoaded() when loaded != null:
return loaded(_that);case ProfitSourcesFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( ProfitSources sources)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ProfitSourcesLoading() when loading != null:
return loading();case ProfitSourcesLoaded() when loaded != null:
return loaded(_that.sources);case ProfitSourcesFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( ProfitSources sources)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case ProfitSourcesLoading():
return loading();case ProfitSourcesLoaded():
return loaded(_that.sources);case ProfitSourcesFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( ProfitSources sources)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case ProfitSourcesLoading() when loading != null:
return loading();case ProfitSourcesLoaded() when loaded != null:
return loaded(_that.sources);case ProfitSourcesFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class ProfitSourcesLoading implements ProfitSourcesState {
  const ProfitSourcesLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfitSourcesLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProfitSourcesState.loading()';
}


}




/// @nodoc


class ProfitSourcesLoaded implements ProfitSourcesState {
  const ProfitSourcesLoaded(this.sources);
  

 final  ProfitSources sources;

/// Create a copy of ProfitSourcesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfitSourcesLoadedCopyWith<ProfitSourcesLoaded> get copyWith => _$ProfitSourcesLoadedCopyWithImpl<ProfitSourcesLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfitSourcesLoaded&&(identical(other.sources, sources) || other.sources == sources));
}


@override
int get hashCode => Object.hash(runtimeType,sources);

@override
String toString() {
  return 'ProfitSourcesState.loaded(sources: $sources)';
}


}

/// @nodoc
abstract mixin class $ProfitSourcesLoadedCopyWith<$Res> implements $ProfitSourcesStateCopyWith<$Res> {
  factory $ProfitSourcesLoadedCopyWith(ProfitSourcesLoaded value, $Res Function(ProfitSourcesLoaded) _then) = _$ProfitSourcesLoadedCopyWithImpl;
@useResult
$Res call({
 ProfitSources sources
});


$ProfitSourcesCopyWith<$Res> get sources;

}
/// @nodoc
class _$ProfitSourcesLoadedCopyWithImpl<$Res>
    implements $ProfitSourcesLoadedCopyWith<$Res> {
  _$ProfitSourcesLoadedCopyWithImpl(this._self, this._then);

  final ProfitSourcesLoaded _self;
  final $Res Function(ProfitSourcesLoaded) _then;

/// Create a copy of ProfitSourcesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? sources = null,}) {
  return _then(ProfitSourcesLoaded(
null == sources ? _self.sources : sources // ignore: cast_nullable_to_non_nullable
as ProfitSources,
  ));
}

/// Create a copy of ProfitSourcesState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfitSourcesCopyWith<$Res> get sources {
  
  return $ProfitSourcesCopyWith<$Res>(_self.sources, (value) {
    return _then(_self.copyWith(sources: value));
  });
}
}

/// @nodoc


class ProfitSourcesFailure implements ProfitSourcesState {
  const ProfitSourcesFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of ProfitSourcesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfitSourcesFailureCopyWith<ProfitSourcesFailure> get copyWith => _$ProfitSourcesFailureCopyWithImpl<ProfitSourcesFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProfitSourcesFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'ProfitSourcesState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $ProfitSourcesFailureCopyWith<$Res> implements $ProfitSourcesStateCopyWith<$Res> {
  factory $ProfitSourcesFailureCopyWith(ProfitSourcesFailure value, $Res Function(ProfitSourcesFailure) _then) = _$ProfitSourcesFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$ProfitSourcesFailureCopyWithImpl<$Res>
    implements $ProfitSourcesFailureCopyWith<$Res> {
  _$ProfitSourcesFailureCopyWithImpl(this._self, this._then);

  final ProfitSourcesFailure _self;
  final $Res Function(ProfitSourcesFailure) _then;

/// Create a copy of ProfitSourcesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(ProfitSourcesFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of ProfitSourcesState
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
