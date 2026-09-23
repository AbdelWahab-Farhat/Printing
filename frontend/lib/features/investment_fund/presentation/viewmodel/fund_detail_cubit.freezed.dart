// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fund_detail_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FundDetailState<T> {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FundDetailState<T>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'FundDetailState<$T>()';
}


}

/// @nodoc
class $FundDetailStateCopyWith<T,$Res>  {
$FundDetailStateCopyWith(FundDetailState<T> _, $Res Function(FundDetailState<T>) __);
}


/// Adds pattern-matching-related methods to [FundDetailState].
extension FundDetailStatePatterns<T> on FundDetailState<T> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( FundDetailLoading<T> value)?  loading,TResult Function( FundDetailLoaded<T> value)?  loaded,TResult Function( FundDetailFailure<T> value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case FundDetailLoading() when loading != null:
return loading(_that);case FundDetailLoaded() when loaded != null:
return loaded(_that);case FundDetailFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( FundDetailLoading<T> value)  loading,required TResult Function( FundDetailLoaded<T> value)  loaded,required TResult Function( FundDetailFailure<T> value)  failure,}){
final _that = this;
switch (_that) {
case FundDetailLoading():
return loading(_that);case FundDetailLoaded():
return loaded(_that);case FundDetailFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( FundDetailLoading<T> value)?  loading,TResult? Function( FundDetailLoaded<T> value)?  loaded,TResult? Function( FundDetailFailure<T> value)?  failure,}){
final _that = this;
switch (_that) {
case FundDetailLoading() when loading != null:
return loading(_that);case FundDetailLoaded() when loaded != null:
return loaded(_that);case FundDetailFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( T value)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case FundDetailLoading() when loading != null:
return loading();case FundDetailLoaded() when loaded != null:
return loaded(_that.value);case FundDetailFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( T value)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case FundDetailLoading():
return loading();case FundDetailLoaded():
return loaded(_that.value);case FundDetailFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( T value)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case FundDetailLoading() when loading != null:
return loading();case FundDetailLoaded() when loaded != null:
return loaded(_that.value);case FundDetailFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class FundDetailLoading<T> implements FundDetailState<T> {
  const FundDetailLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FundDetailLoading<T>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'FundDetailState<$T>.loading()';
}


}




/// @nodoc


class FundDetailLoaded<T> implements FundDetailState<T> {
  const FundDetailLoaded(this.value);
  

 final  T value;

/// Create a copy of FundDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FundDetailLoadedCopyWith<T, FundDetailLoaded<T>> get copyWith => _$FundDetailLoadedCopyWithImpl<T, FundDetailLoaded<T>>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FundDetailLoaded<T>&&const DeepCollectionEquality().equals(other.value, value));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(value));

@override
String toString() {
  return 'FundDetailState<$T>.loaded(value: $value)';
}


}

/// @nodoc
abstract mixin class $FundDetailLoadedCopyWith<T,$Res> implements $FundDetailStateCopyWith<T, $Res> {
  factory $FundDetailLoadedCopyWith(FundDetailLoaded<T> value, $Res Function(FundDetailLoaded<T>) _then) = _$FundDetailLoadedCopyWithImpl;
@useResult
$Res call({
 T value
});




}
/// @nodoc
class _$FundDetailLoadedCopyWithImpl<T,$Res>
    implements $FundDetailLoadedCopyWith<T, $Res> {
  _$FundDetailLoadedCopyWithImpl(this._self, this._then);

  final FundDetailLoaded<T> _self;
  final $Res Function(FundDetailLoaded<T>) _then;

/// Create a copy of FundDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = freezed,}) {
  return _then(FundDetailLoaded<T>(
freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as T,
  ));
}


}

/// @nodoc


class FundDetailFailure<T> implements FundDetailState<T> {
  const FundDetailFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of FundDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FundDetailFailureCopyWith<T, FundDetailFailure<T>> get copyWith => _$FundDetailFailureCopyWithImpl<T, FundDetailFailure<T>>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FundDetailFailure<T>&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'FundDetailState<$T>.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $FundDetailFailureCopyWith<T,$Res> implements $FundDetailStateCopyWith<T, $Res> {
  factory $FundDetailFailureCopyWith(FundDetailFailure<T> value, $Res Function(FundDetailFailure<T>) _then) = _$FundDetailFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$FundDetailFailureCopyWithImpl<T,$Res>
    implements $FundDetailFailureCopyWith<T, $Res> {
  _$FundDetailFailureCopyWithImpl(this._self, this._then);

  final FundDetailFailure<T> _self;
  final $Res Function(FundDetailFailure<T>) _then;

/// Create a copy of FundDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(FundDetailFailure<T>(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of FundDetailState
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
