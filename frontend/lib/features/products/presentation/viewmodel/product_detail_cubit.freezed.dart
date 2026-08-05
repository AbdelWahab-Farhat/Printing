// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_detail_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProductDetailState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductDetailState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProductDetailState()';
}


}

/// @nodoc
class $ProductDetailStateCopyWith<$Res>  {
$ProductDetailStateCopyWith(ProductDetailState _, $Res Function(ProductDetailState) __);
}


/// Adds pattern-matching-related methods to [ProductDetailState].
extension ProductDetailStatePatterns on ProductDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ProductDetailLoading value)?  loading,TResult Function( ProductDetailLoaded value)?  loaded,TResult Function( ProductDetailFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ProductDetailLoading() when loading != null:
return loading(_that);case ProductDetailLoaded() when loaded != null:
return loaded(_that);case ProductDetailFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ProductDetailLoading value)  loading,required TResult Function( ProductDetailLoaded value)  loaded,required TResult Function( ProductDetailFailure value)  failure,}){
final _that = this;
switch (_that) {
case ProductDetailLoading():
return loading(_that);case ProductDetailLoaded():
return loaded(_that);case ProductDetailFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ProductDetailLoading value)?  loading,TResult? Function( ProductDetailLoaded value)?  loaded,TResult? Function( ProductDetailFailure value)?  failure,}){
final _that = this;
switch (_that) {
case ProductDetailLoading() when loading != null:
return loading(_that);case ProductDetailLoaded() when loaded != null:
return loaded(_that);case ProductDetailFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( Product product)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ProductDetailLoading() when loading != null:
return loading();case ProductDetailLoaded() when loaded != null:
return loaded(_that.product);case ProductDetailFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( Product product)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case ProductDetailLoading():
return loading();case ProductDetailLoaded():
return loaded(_that.product);case ProductDetailFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( Product product)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case ProductDetailLoading() when loading != null:
return loading();case ProductDetailLoaded() when loaded != null:
return loaded(_that.product);case ProductDetailFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class ProductDetailLoading implements ProductDetailState {
  const ProductDetailLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductDetailLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ProductDetailState.loading()';
}


}




/// @nodoc


class ProductDetailLoaded implements ProductDetailState {
  const ProductDetailLoaded(this.product);
  

 final  Product product;

/// Create a copy of ProductDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductDetailLoadedCopyWith<ProductDetailLoaded> get copyWith => _$ProductDetailLoadedCopyWithImpl<ProductDetailLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductDetailLoaded&&(identical(other.product, product) || other.product == product));
}


@override
int get hashCode => Object.hash(runtimeType,product);

@override
String toString() {
  return 'ProductDetailState.loaded(product: $product)';
}


}

/// @nodoc
abstract mixin class $ProductDetailLoadedCopyWith<$Res> implements $ProductDetailStateCopyWith<$Res> {
  factory $ProductDetailLoadedCopyWith(ProductDetailLoaded value, $Res Function(ProductDetailLoaded) _then) = _$ProductDetailLoadedCopyWithImpl;
@useResult
$Res call({
 Product product
});


$ProductCopyWith<$Res> get product;

}
/// @nodoc
class _$ProductDetailLoadedCopyWithImpl<$Res>
    implements $ProductDetailLoadedCopyWith<$Res> {
  _$ProductDetailLoadedCopyWithImpl(this._self, this._then);

  final ProductDetailLoaded _self;
  final $Res Function(ProductDetailLoaded) _then;

/// Create a copy of ProductDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? product = null,}) {
  return _then(ProductDetailLoaded(
null == product ? _self.product : product // ignore: cast_nullable_to_non_nullable
as Product,
  ));
}

/// Create a copy of ProductDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProductCopyWith<$Res> get product {
  
  return $ProductCopyWith<$Res>(_self.product, (value) {
    return _then(_self.copyWith(product: value));
  });
}
}

/// @nodoc


class ProductDetailFailure implements ProductDetailState {
  const ProductDetailFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of ProductDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductDetailFailureCopyWith<ProductDetailFailure> get copyWith => _$ProductDetailFailureCopyWithImpl<ProductDetailFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductDetailFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'ProductDetailState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $ProductDetailFailureCopyWith<$Res> implements $ProductDetailStateCopyWith<$Res> {
  factory $ProductDetailFailureCopyWith(ProductDetailFailure value, $Res Function(ProductDetailFailure) _then) = _$ProductDetailFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$ProductDetailFailureCopyWithImpl<$Res>
    implements $ProductDetailFailureCopyWith<$Res> {
  _$ProductDetailFailureCopyWithImpl(this._self, this._then);

  final ProductDetailFailure _self;
  final $Res Function(ProductDetailFailure) _then;

/// Create a copy of ProductDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(ProductDetailFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of ProductDetailState
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
