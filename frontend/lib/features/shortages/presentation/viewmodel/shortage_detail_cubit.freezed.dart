// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shortage_detail_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ShortageDetailState {

 Shortage? get shortage;
/// Create a copy of ShortageDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShortageDetailStateCopyWith<ShortageDetailState> get copyWith => _$ShortageDetailStateCopyWithImpl<ShortageDetailState>(this as ShortageDetailState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShortageDetailState&&(identical(other.shortage, shortage) || other.shortage == shortage));
}


@override
int get hashCode => Object.hash(runtimeType,shortage);

@override
String toString() {
  return 'ShortageDetailState(shortage: $shortage)';
}


}

/// @nodoc
abstract mixin class $ShortageDetailStateCopyWith<$Res>  {
  factory $ShortageDetailStateCopyWith(ShortageDetailState value, $Res Function(ShortageDetailState) _then) = _$ShortageDetailStateCopyWithImpl;
@useResult
$Res call({
 Shortage shortage
});


$ShortageCopyWith<$Res>? get shortage;

}
/// @nodoc
class _$ShortageDetailStateCopyWithImpl<$Res>
    implements $ShortageDetailStateCopyWith<$Res> {
  _$ShortageDetailStateCopyWithImpl(this._self, this._then);

  final ShortageDetailState _self;
  final $Res Function(ShortageDetailState) _then;

/// Create a copy of ShortageDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? shortage = null,}) {
  return _then(_self.copyWith(
shortage: null == shortage ? _self.shortage! : shortage // ignore: cast_nullable_to_non_nullable
as Shortage,
  ));
}
/// Create a copy of ShortageDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShortageCopyWith<$Res>? get shortage {
    if (_self.shortage == null) {
    return null;
  }

  return $ShortageCopyWith<$Res>(_self.shortage!, (value) {
    return _then(_self.copyWith(shortage: value));
  });
}
}


/// Adds pattern-matching-related methods to [ShortageDetailState].
extension ShortageDetailStatePatterns on ShortageDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ShortageDetailLoading value)?  loading,TResult Function( ShortageDetailReady value)?  ready,TResult Function( ShortageDetailWorking value)?  working,TResult Function( ShortageDetailFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ShortageDetailLoading() when loading != null:
return loading(_that);case ShortageDetailReady() when ready != null:
return ready(_that);case ShortageDetailWorking() when working != null:
return working(_that);case ShortageDetailFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ShortageDetailLoading value)  loading,required TResult Function( ShortageDetailReady value)  ready,required TResult Function( ShortageDetailWorking value)  working,required TResult Function( ShortageDetailFailure value)  failure,}){
final _that = this;
switch (_that) {
case ShortageDetailLoading():
return loading(_that);case ShortageDetailReady():
return ready(_that);case ShortageDetailWorking():
return working(_that);case ShortageDetailFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ShortageDetailLoading value)?  loading,TResult? Function( ShortageDetailReady value)?  ready,TResult? Function( ShortageDetailWorking value)?  working,TResult? Function( ShortageDetailFailure value)?  failure,}){
final _that = this;
switch (_that) {
case ShortageDetailLoading() when loading != null:
return loading(_that);case ShortageDetailReady() when ready != null:
return ready(_that);case ShortageDetailWorking() when working != null:
return working(_that);case ShortageDetailFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Shortage? shortage)?  loading,TResult Function( Shortage shortage)?  ready,TResult Function( Shortage shortage)?  working,TResult Function( Failure failure,  Shortage? shortage)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ShortageDetailLoading() when loading != null:
return loading(_that.shortage);case ShortageDetailReady() when ready != null:
return ready(_that.shortage);case ShortageDetailWorking() when working != null:
return working(_that.shortage);case ShortageDetailFailure() when failure != null:
return failure(_that.failure,_that.shortage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Shortage? shortage)  loading,required TResult Function( Shortage shortage)  ready,required TResult Function( Shortage shortage)  working,required TResult Function( Failure failure,  Shortage? shortage)  failure,}) {final _that = this;
switch (_that) {
case ShortageDetailLoading():
return loading(_that.shortage);case ShortageDetailReady():
return ready(_that.shortage);case ShortageDetailWorking():
return working(_that.shortage);case ShortageDetailFailure():
return failure(_that.failure,_that.shortage);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Shortage? shortage)?  loading,TResult? Function( Shortage shortage)?  ready,TResult? Function( Shortage shortage)?  working,TResult? Function( Failure failure,  Shortage? shortage)?  failure,}) {final _that = this;
switch (_that) {
case ShortageDetailLoading() when loading != null:
return loading(_that.shortage);case ShortageDetailReady() when ready != null:
return ready(_that.shortage);case ShortageDetailWorking() when working != null:
return working(_that.shortage);case ShortageDetailFailure() when failure != null:
return failure(_that.failure,_that.shortage);case _:
  return null;

}
}

}

/// @nodoc


class ShortageDetailLoading implements ShortageDetailState {
  const ShortageDetailLoading({this.shortage});
  

@override final  Shortage? shortage;

/// Create a copy of ShortageDetailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShortageDetailLoadingCopyWith<ShortageDetailLoading> get copyWith => _$ShortageDetailLoadingCopyWithImpl<ShortageDetailLoading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShortageDetailLoading&&(identical(other.shortage, shortage) || other.shortage == shortage));
}


@override
int get hashCode => Object.hash(runtimeType,shortage);

@override
String toString() {
  return 'ShortageDetailState.loading(shortage: $shortage)';
}


}

/// @nodoc
abstract mixin class $ShortageDetailLoadingCopyWith<$Res> implements $ShortageDetailStateCopyWith<$Res> {
  factory $ShortageDetailLoadingCopyWith(ShortageDetailLoading value, $Res Function(ShortageDetailLoading) _then) = _$ShortageDetailLoadingCopyWithImpl;
@override @useResult
$Res call({
 Shortage? shortage
});


@override $ShortageCopyWith<$Res>? get shortage;

}
/// @nodoc
class _$ShortageDetailLoadingCopyWithImpl<$Res>
    implements $ShortageDetailLoadingCopyWith<$Res> {
  _$ShortageDetailLoadingCopyWithImpl(this._self, this._then);

  final ShortageDetailLoading _self;
  final $Res Function(ShortageDetailLoading) _then;

/// Create a copy of ShortageDetailState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? shortage = freezed,}) {
  return _then(ShortageDetailLoading(
shortage: freezed == shortage ? _self.shortage : shortage // ignore: cast_nullable_to_non_nullable
as Shortage?,
  ));
}

/// Create a copy of ShortageDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShortageCopyWith<$Res>? get shortage {
    if (_self.shortage == null) {
    return null;
  }

  return $ShortageCopyWith<$Res>(_self.shortage!, (value) {
    return _then(_self.copyWith(shortage: value));
  });
}
}

/// @nodoc


class ShortageDetailReady implements ShortageDetailState {
  const ShortageDetailReady(this.shortage);
  

@override final  Shortage shortage;

/// Create a copy of ShortageDetailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShortageDetailReadyCopyWith<ShortageDetailReady> get copyWith => _$ShortageDetailReadyCopyWithImpl<ShortageDetailReady>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShortageDetailReady&&(identical(other.shortage, shortage) || other.shortage == shortage));
}


@override
int get hashCode => Object.hash(runtimeType,shortage);

@override
String toString() {
  return 'ShortageDetailState.ready(shortage: $shortage)';
}


}

/// @nodoc
abstract mixin class $ShortageDetailReadyCopyWith<$Res> implements $ShortageDetailStateCopyWith<$Res> {
  factory $ShortageDetailReadyCopyWith(ShortageDetailReady value, $Res Function(ShortageDetailReady) _then) = _$ShortageDetailReadyCopyWithImpl;
@override @useResult
$Res call({
 Shortage shortage
});


@override $ShortageCopyWith<$Res> get shortage;

}
/// @nodoc
class _$ShortageDetailReadyCopyWithImpl<$Res>
    implements $ShortageDetailReadyCopyWith<$Res> {
  _$ShortageDetailReadyCopyWithImpl(this._self, this._then);

  final ShortageDetailReady _self;
  final $Res Function(ShortageDetailReady) _then;

/// Create a copy of ShortageDetailState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? shortage = null,}) {
  return _then(ShortageDetailReady(
null == shortage ? _self.shortage : shortage // ignore: cast_nullable_to_non_nullable
as Shortage,
  ));
}

/// Create a copy of ShortageDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShortageCopyWith<$Res> get shortage {
  
  return $ShortageCopyWith<$Res>(_self.shortage, (value) {
    return _then(_self.copyWith(shortage: value));
  });
}
}

/// @nodoc


class ShortageDetailWorking implements ShortageDetailState {
  const ShortageDetailWorking(this.shortage);
  

@override final  Shortage shortage;

/// Create a copy of ShortageDetailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShortageDetailWorkingCopyWith<ShortageDetailWorking> get copyWith => _$ShortageDetailWorkingCopyWithImpl<ShortageDetailWorking>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShortageDetailWorking&&(identical(other.shortage, shortage) || other.shortage == shortage));
}


@override
int get hashCode => Object.hash(runtimeType,shortage);

@override
String toString() {
  return 'ShortageDetailState.working(shortage: $shortage)';
}


}

/// @nodoc
abstract mixin class $ShortageDetailWorkingCopyWith<$Res> implements $ShortageDetailStateCopyWith<$Res> {
  factory $ShortageDetailWorkingCopyWith(ShortageDetailWorking value, $Res Function(ShortageDetailWorking) _then) = _$ShortageDetailWorkingCopyWithImpl;
@override @useResult
$Res call({
 Shortage shortage
});


@override $ShortageCopyWith<$Res> get shortage;

}
/// @nodoc
class _$ShortageDetailWorkingCopyWithImpl<$Res>
    implements $ShortageDetailWorkingCopyWith<$Res> {
  _$ShortageDetailWorkingCopyWithImpl(this._self, this._then);

  final ShortageDetailWorking _self;
  final $Res Function(ShortageDetailWorking) _then;

/// Create a copy of ShortageDetailState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? shortage = null,}) {
  return _then(ShortageDetailWorking(
null == shortage ? _self.shortage : shortage // ignore: cast_nullable_to_non_nullable
as Shortage,
  ));
}

/// Create a copy of ShortageDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShortageCopyWith<$Res> get shortage {
  
  return $ShortageCopyWith<$Res>(_self.shortage, (value) {
    return _then(_self.copyWith(shortage: value));
  });
}
}

/// @nodoc


class ShortageDetailFailure implements ShortageDetailState {
  const ShortageDetailFailure(this.failure, {this.shortage});
  

 final  Failure failure;
@override final  Shortage? shortage;

/// Create a copy of ShortageDetailState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShortageDetailFailureCopyWith<ShortageDetailFailure> get copyWith => _$ShortageDetailFailureCopyWithImpl<ShortageDetailFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShortageDetailFailure&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.shortage, shortage) || other.shortage == shortage));
}


@override
int get hashCode => Object.hash(runtimeType,failure,shortage);

@override
String toString() {
  return 'ShortageDetailState.failure(failure: $failure, shortage: $shortage)';
}


}

/// @nodoc
abstract mixin class $ShortageDetailFailureCopyWith<$Res> implements $ShortageDetailStateCopyWith<$Res> {
  factory $ShortageDetailFailureCopyWith(ShortageDetailFailure value, $Res Function(ShortageDetailFailure) _then) = _$ShortageDetailFailureCopyWithImpl;
@override @useResult
$Res call({
 Failure failure, Shortage? shortage
});


$FailureCopyWith<$Res> get failure;@override $ShortageCopyWith<$Res>? get shortage;

}
/// @nodoc
class _$ShortageDetailFailureCopyWithImpl<$Res>
    implements $ShortageDetailFailureCopyWith<$Res> {
  _$ShortageDetailFailureCopyWithImpl(this._self, this._then);

  final ShortageDetailFailure _self;
  final $Res Function(ShortageDetailFailure) _then;

/// Create a copy of ShortageDetailState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? failure = null,Object? shortage = freezed,}) {
  return _then(ShortageDetailFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,shortage: freezed == shortage ? _self.shortage : shortage // ignore: cast_nullable_to_non_nullable
as Shortage?,
  ));
}

/// Create a copy of ShortageDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res> get failure {
  
  return $FailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}/// Create a copy of ShortageDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShortageCopyWith<$Res>? get shortage {
    if (_self.shortage == null) {
    return null;
  }

  return $ShortageCopyWith<$Res>(_self.shortage!, (value) {
    return _then(_self.copyWith(shortage: value));
  });
}
}

// dart format on
