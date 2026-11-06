// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nawris_settlement_imports_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NawrisSettlementImportState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NawrisSettlementImportState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NawrisSettlementImportState()';
}


}

/// @nodoc
class $NawrisSettlementImportStateCopyWith<$Res>  {
$NawrisSettlementImportStateCopyWith(NawrisSettlementImportState _, $Res Function(NawrisSettlementImportState) __);
}


/// Adds pattern-matching-related methods to [NawrisSettlementImportState].
extension NawrisSettlementImportStatePatterns on NawrisSettlementImportState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NawrisSettlementImportLoading value)?  loading,TResult Function( NawrisSettlementImportLoaded value)?  loaded,TResult Function( NawrisSettlementImportFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NawrisSettlementImportLoading() when loading != null:
return loading(_that);case NawrisSettlementImportLoaded() when loaded != null:
return loaded(_that);case NawrisSettlementImportFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NawrisSettlementImportLoading value)  loading,required TResult Function( NawrisSettlementImportLoaded value)  loaded,required TResult Function( NawrisSettlementImportFailure value)  failure,}){
final _that = this;
switch (_that) {
case NawrisSettlementImportLoading():
return loading(_that);case NawrisSettlementImportLoaded():
return loaded(_that);case NawrisSettlementImportFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NawrisSettlementImportLoading value)?  loading,TResult? Function( NawrisSettlementImportLoaded value)?  loaded,TResult? Function( NawrisSettlementImportFailure value)?  failure,}){
final _that = this;
switch (_that) {
case NawrisSettlementImportLoading() when loading != null:
return loading(_that);case NawrisSettlementImportLoaded() when loaded != null:
return loaded(_that);case NawrisSettlementImportFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( NawrisSettlementImport batch)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NawrisSettlementImportLoading() when loading != null:
return loading();case NawrisSettlementImportLoaded() when loaded != null:
return loaded(_that.batch);case NawrisSettlementImportFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( NawrisSettlementImport batch)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case NawrisSettlementImportLoading():
return loading();case NawrisSettlementImportLoaded():
return loaded(_that.batch);case NawrisSettlementImportFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( NawrisSettlementImport batch)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case NawrisSettlementImportLoading() when loading != null:
return loading();case NawrisSettlementImportLoaded() when loaded != null:
return loaded(_that.batch);case NawrisSettlementImportFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class NawrisSettlementImportLoading implements NawrisSettlementImportState {
  const NawrisSettlementImportLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NawrisSettlementImportLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NawrisSettlementImportState.loading()';
}


}




/// @nodoc


class NawrisSettlementImportLoaded implements NawrisSettlementImportState {
  const NawrisSettlementImportLoaded(this.batch);
  

 final  NawrisSettlementImport batch;

/// Create a copy of NawrisSettlementImportState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NawrisSettlementImportLoadedCopyWith<NawrisSettlementImportLoaded> get copyWith => _$NawrisSettlementImportLoadedCopyWithImpl<NawrisSettlementImportLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NawrisSettlementImportLoaded&&(identical(other.batch, batch) || other.batch == batch));
}


@override
int get hashCode => Object.hash(runtimeType,batch);

@override
String toString() {
  return 'NawrisSettlementImportState.loaded(batch: $batch)';
}


}

/// @nodoc
abstract mixin class $NawrisSettlementImportLoadedCopyWith<$Res> implements $NawrisSettlementImportStateCopyWith<$Res> {
  factory $NawrisSettlementImportLoadedCopyWith(NawrisSettlementImportLoaded value, $Res Function(NawrisSettlementImportLoaded) _then) = _$NawrisSettlementImportLoadedCopyWithImpl;
@useResult
$Res call({
 NawrisSettlementImport batch
});


$NawrisSettlementImportCopyWith<$Res> get batch;

}
/// @nodoc
class _$NawrisSettlementImportLoadedCopyWithImpl<$Res>
    implements $NawrisSettlementImportLoadedCopyWith<$Res> {
  _$NawrisSettlementImportLoadedCopyWithImpl(this._self, this._then);

  final NawrisSettlementImportLoaded _self;
  final $Res Function(NawrisSettlementImportLoaded) _then;

/// Create a copy of NawrisSettlementImportState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? batch = null,}) {
  return _then(NawrisSettlementImportLoaded(
null == batch ? _self.batch : batch // ignore: cast_nullable_to_non_nullable
as NawrisSettlementImport,
  ));
}

/// Create a copy of NawrisSettlementImportState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NawrisSettlementImportCopyWith<$Res> get batch {
  
  return $NawrisSettlementImportCopyWith<$Res>(_self.batch, (value) {
    return _then(_self.copyWith(batch: value));
  });
}
}

/// @nodoc


class NawrisSettlementImportFailure implements NawrisSettlementImportState {
  const NawrisSettlementImportFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of NawrisSettlementImportState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NawrisSettlementImportFailureCopyWith<NawrisSettlementImportFailure> get copyWith => _$NawrisSettlementImportFailureCopyWithImpl<NawrisSettlementImportFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NawrisSettlementImportFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'NawrisSettlementImportState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $NawrisSettlementImportFailureCopyWith<$Res> implements $NawrisSettlementImportStateCopyWith<$Res> {
  factory $NawrisSettlementImportFailureCopyWith(NawrisSettlementImportFailure value, $Res Function(NawrisSettlementImportFailure) _then) = _$NawrisSettlementImportFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$NawrisSettlementImportFailureCopyWithImpl<$Res>
    implements $NawrisSettlementImportFailureCopyWith<$Res> {
  _$NawrisSettlementImportFailureCopyWithImpl(this._self, this._then);

  final NawrisSettlementImportFailure _self;
  final $Res Function(NawrisSettlementImportFailure) _then;

/// Create a copy of NawrisSettlementImportState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(NawrisSettlementImportFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of NawrisSettlementImportState
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
