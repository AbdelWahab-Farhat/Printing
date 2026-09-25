// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'designs_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DesignsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesignsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DesignsState()';
}


}

/// @nodoc
class $DesignsStateCopyWith<$Res>  {
$DesignsStateCopyWith(DesignsState _, $Res Function(DesignsState) __);
}


/// Adds pattern-matching-related methods to [DesignsState].
extension DesignsStatePatterns on DesignsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DesignsLoading value)?  loading,TResult Function( DesignsLoaded value)?  loaded,TResult Function( DesignsFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DesignsLoading() when loading != null:
return loading(_that);case DesignsLoaded() when loaded != null:
return loaded(_that);case DesignsFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DesignsLoading value)  loading,required TResult Function( DesignsLoaded value)  loaded,required TResult Function( DesignsFailure value)  failure,}){
final _that = this;
switch (_that) {
case DesignsLoading():
return loading(_that);case DesignsLoaded():
return loaded(_that);case DesignsFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DesignsLoading value)?  loading,TResult? Function( DesignsLoaded value)?  loaded,TResult? Function( DesignsFailure value)?  failure,}){
final _that = this;
switch (_that) {
case DesignsLoading() when loading != null:
return loading(_that);case DesignsLoaded() when loaded != null:
return loaded(_that);case DesignsFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<CustomerDesign> designs,  bool isBusy,  Failure? lastFailure)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DesignsLoading() when loading != null:
return loading();case DesignsLoaded() when loaded != null:
return loaded(_that.designs,_that.isBusy,_that.lastFailure);case DesignsFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<CustomerDesign> designs,  bool isBusy,  Failure? lastFailure)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case DesignsLoading():
return loading();case DesignsLoaded():
return loaded(_that.designs,_that.isBusy,_that.lastFailure);case DesignsFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<CustomerDesign> designs,  bool isBusy,  Failure? lastFailure)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case DesignsLoading() when loading != null:
return loading();case DesignsLoaded() when loaded != null:
return loaded(_that.designs,_that.isBusy,_that.lastFailure);case DesignsFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class DesignsLoading implements DesignsState {
  const DesignsLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesignsLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'DesignsState.loading()';
}


}




/// @nodoc


class DesignsLoaded implements DesignsState {
  const DesignsLoaded(final  List<CustomerDesign> designs, {this.isBusy = false, this.lastFailure}): _designs = designs;
  

 final  List<CustomerDesign> _designs;
 List<CustomerDesign> get designs {
  if (_designs is EqualUnmodifiableListView) return _designs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_designs);
}

/// A write is in flight. The grid stays, the controls lock.
@JsonKey() final  bool isBusy;
/// The last write that failed, cleared by the next state. **Not a `failure` state**: the
/// library is still perfectly readable, and a rename that failed should not take it away.
 final  Failure? lastFailure;

/// Create a copy of DesignsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DesignsLoadedCopyWith<DesignsLoaded> get copyWith => _$DesignsLoadedCopyWithImpl<DesignsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesignsLoaded&&const DeepCollectionEquality().equals(other._designs, _designs)&&(identical(other.isBusy, isBusy) || other.isBusy == isBusy)&&(identical(other.lastFailure, lastFailure) || other.lastFailure == lastFailure));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_designs),isBusy,lastFailure);

@override
String toString() {
  return 'DesignsState.loaded(designs: $designs, isBusy: $isBusy, lastFailure: $lastFailure)';
}


}

/// @nodoc
abstract mixin class $DesignsLoadedCopyWith<$Res> implements $DesignsStateCopyWith<$Res> {
  factory $DesignsLoadedCopyWith(DesignsLoaded value, $Res Function(DesignsLoaded) _then) = _$DesignsLoadedCopyWithImpl;
@useResult
$Res call({
 List<CustomerDesign> designs, bool isBusy, Failure? lastFailure
});


$FailureCopyWith<$Res>? get lastFailure;

}
/// @nodoc
class _$DesignsLoadedCopyWithImpl<$Res>
    implements $DesignsLoadedCopyWith<$Res> {
  _$DesignsLoadedCopyWithImpl(this._self, this._then);

  final DesignsLoaded _self;
  final $Res Function(DesignsLoaded) _then;

/// Create a copy of DesignsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? designs = null,Object? isBusy = null,Object? lastFailure = freezed,}) {
  return _then(DesignsLoaded(
null == designs ? _self._designs : designs // ignore: cast_nullable_to_non_nullable
as List<CustomerDesign>,isBusy: null == isBusy ? _self.isBusy : isBusy // ignore: cast_nullable_to_non_nullable
as bool,lastFailure: freezed == lastFailure ? _self.lastFailure : lastFailure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of DesignsState
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

/// @nodoc


class DesignsFailure implements DesignsState {
  const DesignsFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of DesignsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DesignsFailureCopyWith<DesignsFailure> get copyWith => _$DesignsFailureCopyWithImpl<DesignsFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DesignsFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'DesignsState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $DesignsFailureCopyWith<$Res> implements $DesignsStateCopyWith<$Res> {
  factory $DesignsFailureCopyWith(DesignsFailure value, $Res Function(DesignsFailure) _then) = _$DesignsFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$DesignsFailureCopyWithImpl<$Res>
    implements $DesignsFailureCopyWith<$Res> {
  _$DesignsFailureCopyWithImpl(this._self, this._then);

  final DesignsFailure _self;
  final $Res Function(DesignsFailure) _then;

/// Create a copy of DesignsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(DesignsFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of DesignsState
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
