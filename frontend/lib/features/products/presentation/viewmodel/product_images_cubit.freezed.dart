// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_images_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProductImagesState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductImagesState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProductImagesState()';
}


}

/// @nodoc
class $ProductImagesStateCopyWith<$Res>  {
$ProductImagesStateCopyWith(ProductImagesState _, $Res Function(ProductImagesState) __);
}


/// Adds pattern-matching-related methods to [ProductImagesState].
extension ProductImagesStatePatterns on ProductImagesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ProductImagesLoading value)?  loading,TResult Function( ProductImagesLoaded value)?  loaded,TResult Function( ProductImagesFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ProductImagesLoading() when loading != null:
return loading(_that);case ProductImagesLoaded() when loaded != null:
return loaded(_that);case ProductImagesFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ProductImagesLoading value)  loading,required TResult Function( ProductImagesLoaded value)  loaded,required TResult Function( ProductImagesFailure value)  failure,}){
final _that = this;
switch (_that) {
case ProductImagesLoading():
return loading(_that);case ProductImagesLoaded():
return loaded(_that);case ProductImagesFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ProductImagesLoading value)?  loading,TResult? Function( ProductImagesLoaded value)?  loaded,TResult? Function( ProductImagesFailure value)?  failure,}){
final _that = this;
switch (_that) {
case ProductImagesLoading() when loading != null:
return loading(_that);case ProductImagesLoaded() when loaded != null:
return loaded(_that);case ProductImagesFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<ProductImage> images,  bool isUploading,  int sent,  int total,  Set<int> busy)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ProductImagesLoading() when loading != null:
return loading();case ProductImagesLoaded() when loaded != null:
return loaded(_that.images,_that.isUploading,_that.sent,_that.total,_that.busy);case ProductImagesFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<ProductImage> images,  bool isUploading,  int sent,  int total,  Set<int> busy)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case ProductImagesLoading():
return loading();case ProductImagesLoaded():
return loaded(_that.images,_that.isUploading,_that.sent,_that.total,_that.busy);case ProductImagesFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<ProductImage> images,  bool isUploading,  int sent,  int total,  Set<int> busy)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case ProductImagesLoading() when loading != null:
return loading();case ProductImagesLoaded() when loaded != null:
return loaded(_that.images,_that.isUploading,_that.sent,_that.total,_that.busy);case ProductImagesFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class ProductImagesLoading implements ProductImagesState {
  const ProductImagesLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductImagesLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProductImagesState.loading()';
}


}




/// @nodoc


class ProductImagesLoaded implements ProductImagesState {
  const ProductImagesLoaded({required final  List<ProductImage> images, this.isUploading = false, this.sent = 0, this.total = 0, final  Set<int> busy = const <int>{}}): _images = images,_busy = busy;
  

 final  List<ProductImage> _images;
 List<ProductImage> get images {
  if (_images is EqualUnmodifiableListView) return _images;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_images);
}

/// One at a time — the screen refuses to open a second picker while one is going up, so
/// this is a flag rather than a queue. The cap is five; a queue would be machinery for a
/// case the limit already prevents.
@JsonKey() final  bool isUploading;
/// Bytes sent and bytes to send, so the bar shows a fraction rather than a spinner. Both
/// zero whenever nothing is uploading.
@JsonKey() final  int sent;
@JsonKey() final  int total;
/// The photographs with a write in flight against them — a promotion or a delete.
 final  Set<int> _busy;
/// The photographs with a write in flight against them — a promotion or a delete.
@JsonKey() Set<int> get busy {
  if (_busy is EqualUnmodifiableSetView) return _busy;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_busy);
}


/// Create a copy of ProductImagesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductImagesLoadedCopyWith<ProductImagesLoaded> get copyWith => _$ProductImagesLoadedCopyWithImpl<ProductImagesLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductImagesLoaded&&const DeepCollectionEquality().equals(other._images, _images)&&(identical(other.isUploading, isUploading) || other.isUploading == isUploading)&&(identical(other.sent, sent) || other.sent == sent)&&(identical(other.total, total) || other.total == total)&&const DeepCollectionEquality().equals(other._busy, _busy));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_images),isUploading,sent,total,const DeepCollectionEquality().hash(_busy));

@override
String toString() {
  return 'ProductImagesState.loaded(images: $images, isUploading: $isUploading, sent: $sent, total: $total, busy: $busy)';
}


}

/// @nodoc
abstract mixin class $ProductImagesLoadedCopyWith<$Res> implements $ProductImagesStateCopyWith<$Res> {
  factory $ProductImagesLoadedCopyWith(ProductImagesLoaded value, $Res Function(ProductImagesLoaded) _then) = _$ProductImagesLoadedCopyWithImpl;
@useResult
$Res call({
 List<ProductImage> images, bool isUploading, int sent, int total, Set<int> busy
});




}
/// @nodoc
class _$ProductImagesLoadedCopyWithImpl<$Res>
    implements $ProductImagesLoadedCopyWith<$Res> {
  _$ProductImagesLoadedCopyWithImpl(this._self, this._then);

  final ProductImagesLoaded _self;
  final $Res Function(ProductImagesLoaded) _then;

/// Create a copy of ProductImagesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? images = null,Object? isUploading = null,Object? sent = null,Object? total = null,Object? busy = null,}) {
  return _then(ProductImagesLoaded(
images: null == images ? _self._images : images // ignore: cast_nullable_to_non_nullable
as List<ProductImage>,isUploading: null == isUploading ? _self.isUploading : isUploading // ignore: cast_nullable_to_non_nullable
as bool,sent: null == sent ? _self.sent : sent // ignore: cast_nullable_to_non_nullable
as int,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,busy: null == busy ? _self._busy : busy // ignore: cast_nullable_to_non_nullable
as Set<int>,
  ));
}


}

/// @nodoc


class ProductImagesFailure implements ProductImagesState {
  const ProductImagesFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of ProductImagesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductImagesFailureCopyWith<ProductImagesFailure> get copyWith => _$ProductImagesFailureCopyWithImpl<ProductImagesFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductImagesFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'ProductImagesState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $ProductImagesFailureCopyWith<$Res> implements $ProductImagesStateCopyWith<$Res> {
  factory $ProductImagesFailureCopyWith(ProductImagesFailure value, $Res Function(ProductImagesFailure) _then) = _$ProductImagesFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$ProductImagesFailureCopyWithImpl<$Res>
    implements $ProductImagesFailureCopyWith<$Res> {
  _$ProductImagesFailureCopyWithImpl(this._self, this._then);

  final ProductImagesFailure _self;
  final $Res Function(ProductImagesFailure) _then;

/// Create a copy of ProductImagesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(ProductImagesFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of ProductImagesState
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
