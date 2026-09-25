// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shops_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ShopsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShopsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ShopsState()';
}


}

/// @nodoc
class $ShopsStateCopyWith<$Res>  {
$ShopsStateCopyWith(ShopsState _, $Res Function(ShopsState) __);
}


/// Adds pattern-matching-related methods to [ShopsState].
extension ShopsStatePatterns on ShopsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ShopsLoading value)?  loading,TResult Function( ShopsLoaded value)?  loaded,TResult Function( ShopsFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ShopsLoading() when loading != null:
return loading(_that);case ShopsLoaded() when loaded != null:
return loaded(_that);case ShopsFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ShopsLoading value)  loading,required TResult Function( ShopsLoaded value)  loaded,required TResult Function( ShopsFailure value)  failure,}){
final _that = this;
switch (_that) {
case ShopsLoading():
return loading(_that);case ShopsLoaded():
return loaded(_that);case ShopsFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ShopsLoading value)?  loading,TResult? Function( ShopsLoaded value)?  loaded,TResult? Function( ShopsFailure value)?  failure,}){
final _that = this;
switch (_that) {
case ShopsLoading() when loading != null:
return loading(_that);case ShopsLoaded() when loaded != null:
return loaded(_that);case ShopsFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<Shop> shops,  bool isBusy,  Failure? lastFailure)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ShopsLoading() when loading != null:
return loading();case ShopsLoaded() when loaded != null:
return loaded(_that.shops,_that.isBusy,_that.lastFailure);case ShopsFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<Shop> shops,  bool isBusy,  Failure? lastFailure)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case ShopsLoading():
return loading();case ShopsLoaded():
return loaded(_that.shops,_that.isBusy,_that.lastFailure);case ShopsFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<Shop> shops,  bool isBusy,  Failure? lastFailure)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case ShopsLoading() when loading != null:
return loading();case ShopsLoaded() when loaded != null:
return loaded(_that.shops,_that.isBusy,_that.lastFailure);case ShopsFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class ShopsLoading implements ShopsState {
  const ShopsLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShopsLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ShopsState.loading()';
}


}




/// @nodoc


class ShopsLoaded implements ShopsState {
  const ShopsLoaded(final  List<Shop> shops, {this.isBusy = false, this.lastFailure}): _shops = shops;
  

 final  List<Shop> _shops;
 List<Shop> get shops {
  if (_shops is EqualUnmodifiableListView) return _shops;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_shops);
}

/// حذفٌ في الطريق: القائمة باقية، والأزرار مقفلة.
@JsonKey() final  bool isBusy;
/// آخر حذفٍ فشل، ويُمسح مع الحالة التالية.
 final  Failure? lastFailure;

/// Create a copy of ShopsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShopsLoadedCopyWith<ShopsLoaded> get copyWith => _$ShopsLoadedCopyWithImpl<ShopsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShopsLoaded&&const DeepCollectionEquality().equals(other._shops, _shops)&&(identical(other.isBusy, isBusy) || other.isBusy == isBusy)&&(identical(other.lastFailure, lastFailure) || other.lastFailure == lastFailure));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_shops),isBusy,lastFailure);

@override
String toString() {
  return 'ShopsState.loaded(shops: $shops, isBusy: $isBusy, lastFailure: $lastFailure)';
}


}

/// @nodoc
abstract mixin class $ShopsLoadedCopyWith<$Res> implements $ShopsStateCopyWith<$Res> {
  factory $ShopsLoadedCopyWith(ShopsLoaded value, $Res Function(ShopsLoaded) _then) = _$ShopsLoadedCopyWithImpl;
@useResult
$Res call({
 List<Shop> shops, bool isBusy, Failure? lastFailure
});


$FailureCopyWith<$Res>? get lastFailure;

}
/// @nodoc
class _$ShopsLoadedCopyWithImpl<$Res>
    implements $ShopsLoadedCopyWith<$Res> {
  _$ShopsLoadedCopyWithImpl(this._self, this._then);

  final ShopsLoaded _self;
  final $Res Function(ShopsLoaded) _then;

/// Create a copy of ShopsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? shops = null,Object? isBusy = null,Object? lastFailure = freezed,}) {
  return _then(ShopsLoaded(
null == shops ? _self._shops : shops // ignore: cast_nullable_to_non_nullable
as List<Shop>,isBusy: null == isBusy ? _self.isBusy : isBusy // ignore: cast_nullable_to_non_nullable
as bool,lastFailure: freezed == lastFailure ? _self.lastFailure : lastFailure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of ShopsState
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


class ShopsFailure implements ShopsState {
  const ShopsFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of ShopsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShopsFailureCopyWith<ShopsFailure> get copyWith => _$ShopsFailureCopyWithImpl<ShopsFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShopsFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'ShopsState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $ShopsFailureCopyWith<$Res> implements $ShopsStateCopyWith<$Res> {
  factory $ShopsFailureCopyWith(ShopsFailure value, $Res Function(ShopsFailure) _then) = _$ShopsFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$ShopsFailureCopyWithImpl<$Res>
    implements $ShopsFailureCopyWith<$Res> {
  _$ShopsFailureCopyWithImpl(this._self, this._then);

  final ShopsFailure _self;
  final $Res Function(ShopsFailure) _then;

/// Create a copy of ShopsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(ShopsFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of ShopsState
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
