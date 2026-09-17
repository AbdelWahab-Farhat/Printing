// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bag_preview_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BagPreviewState {

 BagType get bag; ui.Image? get mockup;
/// Create a copy of BagPreviewState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BagPreviewStateCopyWith<BagPreviewState> get copyWith => _$BagPreviewStateCopyWithImpl<BagPreviewState>(this as BagPreviewState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BagPreviewState&&(identical(other.bag, bag) || other.bag == bag)&&(identical(other.mockup, mockup) || other.mockup == mockup));
}


@override
int get hashCode => Object.hash(runtimeType,bag,mockup);

@override
String toString() {
  return 'BagPreviewState(bag: $bag, mockup: $mockup)';
}


}

/// @nodoc
abstract mixin class $BagPreviewStateCopyWith<$Res>  {
  factory $BagPreviewStateCopyWith(BagPreviewState value, $Res Function(BagPreviewState) _then) = _$BagPreviewStateCopyWithImpl;
@useResult
$Res call({
 BagType bag, ui.Image? mockup
});




}
/// @nodoc
class _$BagPreviewStateCopyWithImpl<$Res>
    implements $BagPreviewStateCopyWith<$Res> {
  _$BagPreviewStateCopyWithImpl(this._self, this._then);

  final BagPreviewState _self;
  final $Res Function(BagPreviewState) _then;

/// Create a copy of BagPreviewState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bag = null,Object? mockup = freezed,}) {
  return _then(_self.copyWith(
bag: null == bag ? _self.bag : bag // ignore: cast_nullable_to_non_nullable
as BagType,mockup: freezed == mockup ? _self.mockup : mockup // ignore: cast_nullable_to_non_nullable
as ui.Image?,
  ));
}

}


/// Adds pattern-matching-related methods to [BagPreviewState].
extension BagPreviewStatePatterns on BagPreviewState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( BagPreviewEmpty value)?  empty,TResult Function( BagPreviewLoading value)?  loading,TResult Function( BagPreviewReady value)?  ready,TResult Function( BagPreviewFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case BagPreviewEmpty() when empty != null:
return empty(_that);case BagPreviewLoading() when loading != null:
return loading(_that);case BagPreviewReady() when ready != null:
return ready(_that);case BagPreviewFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( BagPreviewEmpty value)  empty,required TResult Function( BagPreviewLoading value)  loading,required TResult Function( BagPreviewReady value)  ready,required TResult Function( BagPreviewFailure value)  failure,}){
final _that = this;
switch (_that) {
case BagPreviewEmpty():
return empty(_that);case BagPreviewLoading():
return loading(_that);case BagPreviewReady():
return ready(_that);case BagPreviewFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( BagPreviewEmpty value)?  empty,TResult? Function( BagPreviewLoading value)?  loading,TResult? Function( BagPreviewReady value)?  ready,TResult? Function( BagPreviewFailure value)?  failure,}){
final _that = this;
switch (_that) {
case BagPreviewEmpty() when empty != null:
return empty(_that);case BagPreviewLoading() when loading != null:
return loading(_that);case BagPreviewReady() when ready != null:
return ready(_that);case BagPreviewFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( BagType bag,  ui.Image? mockup)?  empty,TResult Function( BagType bag,  ui.Image? mockup)?  loading,TResult Function( BagType bag,  ui.Image design,  ui.Image? mockup)?  ready,TResult Function( BagType bag,  Failure failure,  ui.Image? mockup)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case BagPreviewEmpty() when empty != null:
return empty(_that.bag,_that.mockup);case BagPreviewLoading() when loading != null:
return loading(_that.bag,_that.mockup);case BagPreviewReady() when ready != null:
return ready(_that.bag,_that.design,_that.mockup);case BagPreviewFailure() when failure != null:
return failure(_that.bag,_that.failure,_that.mockup);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( BagType bag,  ui.Image? mockup)  empty,required TResult Function( BagType bag,  ui.Image? mockup)  loading,required TResult Function( BagType bag,  ui.Image design,  ui.Image? mockup)  ready,required TResult Function( BagType bag,  Failure failure,  ui.Image? mockup)  failure,}) {final _that = this;
switch (_that) {
case BagPreviewEmpty():
return empty(_that.bag,_that.mockup);case BagPreviewLoading():
return loading(_that.bag,_that.mockup);case BagPreviewReady():
return ready(_that.bag,_that.design,_that.mockup);case BagPreviewFailure():
return failure(_that.bag,_that.failure,_that.mockup);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( BagType bag,  ui.Image? mockup)?  empty,TResult? Function( BagType bag,  ui.Image? mockup)?  loading,TResult? Function( BagType bag,  ui.Image design,  ui.Image? mockup)?  ready,TResult? Function( BagType bag,  Failure failure,  ui.Image? mockup)?  failure,}) {final _that = this;
switch (_that) {
case BagPreviewEmpty() when empty != null:
return empty(_that.bag,_that.mockup);case BagPreviewLoading() when loading != null:
return loading(_that.bag,_that.mockup);case BagPreviewReady() when ready != null:
return ready(_that.bag,_that.design,_that.mockup);case BagPreviewFailure() when failure != null:
return failure(_that.bag,_that.failure,_that.mockup);case _:
  return null;

}
}

}

/// @nodoc


class BagPreviewEmpty extends BagPreviewState {
  const BagPreviewEmpty({required this.bag, this.mockup}): super._();
  

@override final  BagType bag;
@override final  ui.Image? mockup;

/// Create a copy of BagPreviewState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BagPreviewEmptyCopyWith<BagPreviewEmpty> get copyWith => _$BagPreviewEmptyCopyWithImpl<BagPreviewEmpty>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BagPreviewEmpty&&(identical(other.bag, bag) || other.bag == bag)&&(identical(other.mockup, mockup) || other.mockup == mockup));
}


@override
int get hashCode => Object.hash(runtimeType,bag,mockup);

@override
String toString() {
  return 'BagPreviewState.empty(bag: $bag, mockup: $mockup)';
}


}

/// @nodoc
abstract mixin class $BagPreviewEmptyCopyWith<$Res> implements $BagPreviewStateCopyWith<$Res> {
  factory $BagPreviewEmptyCopyWith(BagPreviewEmpty value, $Res Function(BagPreviewEmpty) _then) = _$BagPreviewEmptyCopyWithImpl;
@override @useResult
$Res call({
 BagType bag, ui.Image? mockup
});




}
/// @nodoc
class _$BagPreviewEmptyCopyWithImpl<$Res>
    implements $BagPreviewEmptyCopyWith<$Res> {
  _$BagPreviewEmptyCopyWithImpl(this._self, this._then);

  final BagPreviewEmpty _self;
  final $Res Function(BagPreviewEmpty) _then;

/// Create a copy of BagPreviewState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bag = null,Object? mockup = freezed,}) {
  return _then(BagPreviewEmpty(
bag: null == bag ? _self.bag : bag // ignore: cast_nullable_to_non_nullable
as BagType,mockup: freezed == mockup ? _self.mockup : mockup // ignore: cast_nullable_to_non_nullable
as ui.Image?,
  ));
}


}

/// @nodoc


class BagPreviewLoading extends BagPreviewState {
  const BagPreviewLoading({required this.bag, this.mockup}): super._();
  

@override final  BagType bag;
@override final  ui.Image? mockup;

/// Create a copy of BagPreviewState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BagPreviewLoadingCopyWith<BagPreviewLoading> get copyWith => _$BagPreviewLoadingCopyWithImpl<BagPreviewLoading>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BagPreviewLoading&&(identical(other.bag, bag) || other.bag == bag)&&(identical(other.mockup, mockup) || other.mockup == mockup));
}


@override
int get hashCode => Object.hash(runtimeType,bag,mockup);

@override
String toString() {
  return 'BagPreviewState.loading(bag: $bag, mockup: $mockup)';
}


}

/// @nodoc
abstract mixin class $BagPreviewLoadingCopyWith<$Res> implements $BagPreviewStateCopyWith<$Res> {
  factory $BagPreviewLoadingCopyWith(BagPreviewLoading value, $Res Function(BagPreviewLoading) _then) = _$BagPreviewLoadingCopyWithImpl;
@override @useResult
$Res call({
 BagType bag, ui.Image? mockup
});




}
/// @nodoc
class _$BagPreviewLoadingCopyWithImpl<$Res>
    implements $BagPreviewLoadingCopyWith<$Res> {
  _$BagPreviewLoadingCopyWithImpl(this._self, this._then);

  final BagPreviewLoading _self;
  final $Res Function(BagPreviewLoading) _then;

/// Create a copy of BagPreviewState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bag = null,Object? mockup = freezed,}) {
  return _then(BagPreviewLoading(
bag: null == bag ? _self.bag : bag // ignore: cast_nullable_to_non_nullable
as BagType,mockup: freezed == mockup ? _self.mockup : mockup // ignore: cast_nullable_to_non_nullable
as ui.Image?,
  ));
}


}

/// @nodoc


class BagPreviewReady extends BagPreviewState {
  const BagPreviewReady({required this.bag, required this.design, this.mockup}): super._();
  

@override final  BagType bag;
 final  ui.Image design;
@override final  ui.Image? mockup;

/// Create a copy of BagPreviewState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BagPreviewReadyCopyWith<BagPreviewReady> get copyWith => _$BagPreviewReadyCopyWithImpl<BagPreviewReady>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BagPreviewReady&&(identical(other.bag, bag) || other.bag == bag)&&(identical(other.design, design) || other.design == design)&&(identical(other.mockup, mockup) || other.mockup == mockup));
}


@override
int get hashCode => Object.hash(runtimeType,bag,design,mockup);

@override
String toString() {
  return 'BagPreviewState.ready(bag: $bag, design: $design, mockup: $mockup)';
}


}

/// @nodoc
abstract mixin class $BagPreviewReadyCopyWith<$Res> implements $BagPreviewStateCopyWith<$Res> {
  factory $BagPreviewReadyCopyWith(BagPreviewReady value, $Res Function(BagPreviewReady) _then) = _$BagPreviewReadyCopyWithImpl;
@override @useResult
$Res call({
 BagType bag, ui.Image design, ui.Image? mockup
});




}
/// @nodoc
class _$BagPreviewReadyCopyWithImpl<$Res>
    implements $BagPreviewReadyCopyWith<$Res> {
  _$BagPreviewReadyCopyWithImpl(this._self, this._then);

  final BagPreviewReady _self;
  final $Res Function(BagPreviewReady) _then;

/// Create a copy of BagPreviewState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bag = null,Object? design = null,Object? mockup = freezed,}) {
  return _then(BagPreviewReady(
bag: null == bag ? _self.bag : bag // ignore: cast_nullable_to_non_nullable
as BagType,design: null == design ? _self.design : design // ignore: cast_nullable_to_non_nullable
as ui.Image,mockup: freezed == mockup ? _self.mockup : mockup // ignore: cast_nullable_to_non_nullable
as ui.Image?,
  ));
}


}

/// @nodoc


class BagPreviewFailure extends BagPreviewState {
  const BagPreviewFailure({required this.bag, required this.failure, this.mockup}): super._();
  

@override final  BagType bag;
 final  Failure failure;
@override final  ui.Image? mockup;

/// Create a copy of BagPreviewState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BagPreviewFailureCopyWith<BagPreviewFailure> get copyWith => _$BagPreviewFailureCopyWithImpl<BagPreviewFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BagPreviewFailure&&(identical(other.bag, bag) || other.bag == bag)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.mockup, mockup) || other.mockup == mockup));
}


@override
int get hashCode => Object.hash(runtimeType,bag,failure,mockup);

@override
String toString() {
  return 'BagPreviewState.failure(bag: $bag, failure: $failure, mockup: $mockup)';
}


}

/// @nodoc
abstract mixin class $BagPreviewFailureCopyWith<$Res> implements $BagPreviewStateCopyWith<$Res> {
  factory $BagPreviewFailureCopyWith(BagPreviewFailure value, $Res Function(BagPreviewFailure) _then) = _$BagPreviewFailureCopyWithImpl;
@override @useResult
$Res call({
 BagType bag, Failure failure, ui.Image? mockup
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$BagPreviewFailureCopyWithImpl<$Res>
    implements $BagPreviewFailureCopyWith<$Res> {
  _$BagPreviewFailureCopyWithImpl(this._self, this._then);

  final BagPreviewFailure _self;
  final $Res Function(BagPreviewFailure) _then;

/// Create a copy of BagPreviewState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bag = null,Object? failure = null,Object? mockup = freezed,}) {
  return _then(BagPreviewFailure(
bag: null == bag ? _self.bag : bag // ignore: cast_nullable_to_non_nullable
as BagType,failure: null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,mockup: freezed == mockup ? _self.mockup : mockup // ignore: cast_nullable_to_non_nullable
as ui.Image?,
  ));
}

/// Create a copy of BagPreviewState
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
