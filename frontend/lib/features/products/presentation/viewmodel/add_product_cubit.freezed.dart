// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'add_product_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AddProductState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AddProductState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AddProductState()';
}


}

/// @nodoc
class $AddProductStateCopyWith<$Res>  {
$AddProductStateCopyWith(AddProductState _, $Res Function(AddProductState) __);
}


/// Adds pattern-matching-related methods to [AddProductState].
extension AddProductStatePatterns on AddProductState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AddProductInitial value)?  initial,TResult Function( AddProductSubmitting value)?  submitting,TResult Function( AddProductSuccess value)?  success,TResult Function( AddProductFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AddProductInitial() when initial != null:
return initial(_that);case AddProductSubmitting() when submitting != null:
return submitting(_that);case AddProductSuccess() when success != null:
return success(_that);case AddProductFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AddProductInitial value)  initial,required TResult Function( AddProductSubmitting value)  submitting,required TResult Function( AddProductSuccess value)  success,required TResult Function( AddProductFailure value)  failure,}){
final _that = this;
switch (_that) {
case AddProductInitial():
return initial(_that);case AddProductSubmitting():
return submitting(_that);case AddProductSuccess():
return success(_that);case AddProductFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AddProductInitial value)?  initial,TResult? Function( AddProductSubmitting value)?  submitting,TResult? Function( AddProductSuccess value)?  success,TResult? Function( AddProductFailure value)?  failure,}){
final _that = this;
switch (_that) {
case AddProductInitial() when initial != null:
return initial(_that);case AddProductSubmitting() when submitting != null:
return submitting(_that);case AddProductSuccess() when success != null:
return success(_that);case AddProductFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  submitting,TResult Function( Product product)?  success,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AddProductInitial() when initial != null:
return initial();case AddProductSubmitting() when submitting != null:
return submitting();case AddProductSuccess() when success != null:
return success(_that.product);case AddProductFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  submitting,required TResult Function( Product product)  success,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case AddProductInitial():
return initial();case AddProductSubmitting():
return submitting();case AddProductSuccess():
return success(_that.product);case AddProductFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  submitting,TResult? Function( Product product)?  success,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case AddProductInitial() when initial != null:
return initial();case AddProductSubmitting() when submitting != null:
return submitting();case AddProductSuccess() when success != null:
return success(_that.product);case AddProductFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class AddProductInitial implements AddProductState {
  const AddProductInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AddProductInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AddProductState.initial()';
}


}




/// @nodoc


class AddProductSubmitting implements AddProductState {
  const AddProductSubmitting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AddProductSubmitting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'AddProductState.submitting()';
}


}




/// @nodoc


class AddProductSuccess implements AddProductState {
  const AddProductSuccess(this.product);
  

 final  Product product;

/// Create a copy of AddProductState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AddProductSuccessCopyWith<AddProductSuccess> get copyWith => _$AddProductSuccessCopyWithImpl<AddProductSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AddProductSuccess&&(identical(other.product, product) || other.product == product));
}


@override
int get hashCode => Object.hash(runtimeType,product);

@override
String toString() {
  return 'AddProductState.success(product: $product)';
}


}

/// @nodoc
abstract mixin class $AddProductSuccessCopyWith<$Res> implements $AddProductStateCopyWith<$Res> {
  factory $AddProductSuccessCopyWith(AddProductSuccess value, $Res Function(AddProductSuccess) _then) = _$AddProductSuccessCopyWithImpl;
@useResult
$Res call({
 Product product
});


$ProductCopyWith<$Res> get product;

}
/// @nodoc
class _$AddProductSuccessCopyWithImpl<$Res>
    implements $AddProductSuccessCopyWith<$Res> {
  _$AddProductSuccessCopyWithImpl(this._self, this._then);

  final AddProductSuccess _self;
  final $Res Function(AddProductSuccess) _then;

/// Create a copy of AddProductState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? product = null,}) {
  return _then(AddProductSuccess(
null == product ? _self.product : product // ignore: cast_nullable_to_non_nullable
as Product,
  ));
}

/// Create a copy of AddProductState
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


class AddProductFailure implements AddProductState {
  const AddProductFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of AddProductState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AddProductFailureCopyWith<AddProductFailure> get copyWith => _$AddProductFailureCopyWithImpl<AddProductFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AddProductFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'AddProductState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $AddProductFailureCopyWith<$Res> implements $AddProductStateCopyWith<$Res> {
  factory $AddProductFailureCopyWith(AddProductFailure value, $Res Function(AddProductFailure) _then) = _$AddProductFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$AddProductFailureCopyWithImpl<$Res>
    implements $AddProductFailureCopyWith<$Res> {
  _$AddProductFailureCopyWithImpl(this._self, this._then);

  final AddProductFailure _self;
  final $Res Function(AddProductFailure) _then;

/// Create a copy of AddProductState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(AddProductFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of AddProductState
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
