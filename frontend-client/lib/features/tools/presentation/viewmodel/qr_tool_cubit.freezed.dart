// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'qr_tool_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$QrToolState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QrToolState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'QrToolState()';
}


}

/// @nodoc
class $QrToolStateCopyWith<$Res>  {
$QrToolStateCopyWith(QrToolState _, $Res Function(QrToolState) __);
}


/// Adds pattern-matching-related methods to [QrToolState].
extension QrToolStatePatterns on QrToolState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( QrBlank value)?  blank,TResult Function( QrReady value)?  ready,TResult Function( QrToolFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case QrBlank() when blank != null:
return blank(_that);case QrReady() when ready != null:
return ready(_that);case QrToolFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( QrBlank value)  blank,required TResult Function( QrReady value)  ready,required TResult Function( QrToolFailure value)  failure,}){
final _that = this;
switch (_that) {
case QrBlank():
return blank(_that);case QrReady():
return ready(_that);case QrToolFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( QrBlank value)?  blank,TResult? Function( QrReady value)?  ready,TResult? Function( QrToolFailure value)?  failure,}){
final _that = this;
switch (_that) {
case QrBlank() when blank != null:
return blank(_that);case QrReady() when ready != null:
return ready(_that);case QrToolFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  blank,TResult Function( QrCodeArt art)?  ready,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case QrBlank() when blank != null:
return blank();case QrReady() when ready != null:
return ready(_that.art);case QrToolFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  blank,required TResult Function( QrCodeArt art)  ready,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case QrBlank():
return blank();case QrReady():
return ready(_that.art);case QrToolFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  blank,TResult? Function( QrCodeArt art)?  ready,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case QrBlank() when blank != null:
return blank();case QrReady() when ready != null:
return ready(_that.art);case QrToolFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class QrBlank implements QrToolState {
  const QrBlank();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QrBlank);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'QrToolState.blank()';
}


}




/// @nodoc


class QrReady implements QrToolState {
  const QrReady({required this.art});
  

 final  QrCodeArt art;

/// Create a copy of QrToolState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QrReadyCopyWith<QrReady> get copyWith => _$QrReadyCopyWithImpl<QrReady>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QrReady&&(identical(other.art, art) || other.art == art));
}


@override
int get hashCode => Object.hash(runtimeType,art);

@override
String toString() {
  return 'QrToolState.ready(art: $art)';
}


}

/// @nodoc
abstract mixin class $QrReadyCopyWith<$Res> implements $QrToolStateCopyWith<$Res> {
  factory $QrReadyCopyWith(QrReady value, $Res Function(QrReady) _then) = _$QrReadyCopyWithImpl;
@useResult
$Res call({
 QrCodeArt art
});




}
/// @nodoc
class _$QrReadyCopyWithImpl<$Res>
    implements $QrReadyCopyWith<$Res> {
  _$QrReadyCopyWithImpl(this._self, this._then);

  final QrReady _self;
  final $Res Function(QrReady) _then;

/// Create a copy of QrToolState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? art = null,}) {
  return _then(QrReady(
art: null == art ? _self.art : art // ignore: cast_nullable_to_non_nullable
as QrCodeArt,
  ));
}


}

/// @nodoc


class QrToolFailure implements QrToolState {
  const QrToolFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of QrToolState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QrToolFailureCopyWith<QrToolFailure> get copyWith => _$QrToolFailureCopyWithImpl<QrToolFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QrToolFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'QrToolState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $QrToolFailureCopyWith<$Res> implements $QrToolStateCopyWith<$Res> {
  factory $QrToolFailureCopyWith(QrToolFailure value, $Res Function(QrToolFailure) _then) = _$QrToolFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$QrToolFailureCopyWithImpl<$Res>
    implements $QrToolFailureCopyWith<$Res> {
  _$QrToolFailureCopyWithImpl(this._self, this._then);

  final QrToolFailure _self;
  final $Res Function(QrToolFailure) _then;

/// Create a copy of QrToolState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(QrToolFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of QrToolState
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
