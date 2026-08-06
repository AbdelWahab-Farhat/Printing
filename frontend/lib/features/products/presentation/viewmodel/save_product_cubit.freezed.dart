// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'save_product_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SaveProductState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveProductState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SaveProductState()';
}


}

/// @nodoc
class $SaveProductStateCopyWith<$Res>  {
$SaveProductStateCopyWith(SaveProductState _, $Res Function(SaveProductState) __);
}


/// Adds pattern-matching-related methods to [SaveProductState].
extension SaveProductStatePatterns on SaveProductState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SaveProductInitial value)?  initial,TResult Function( SaveProductSubmitting value)?  submitting,TResult Function( SaveProductSuccess value)?  success,TResult Function( SaveProductFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SaveProductInitial() when initial != null:
return initial(_that);case SaveProductSubmitting() when submitting != null:
return submitting(_that);case SaveProductSuccess() when success != null:
return success(_that);case SaveProductFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SaveProductInitial value)  initial,required TResult Function( SaveProductSubmitting value)  submitting,required TResult Function( SaveProductSuccess value)  success,required TResult Function( SaveProductFailure value)  failure,}){
final _that = this;
switch (_that) {
case SaveProductInitial():
return initial(_that);case SaveProductSubmitting():
return submitting(_that);case SaveProductSuccess():
return success(_that);case SaveProductFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SaveProductInitial value)?  initial,TResult? Function( SaveProductSubmitting value)?  submitting,TResult? Function( SaveProductSuccess value)?  success,TResult? Function( SaveProductFailure value)?  failure,}){
final _that = this;
switch (_that) {
case SaveProductInitial() when initial != null:
return initial(_that);case SaveProductSubmitting() when submitting != null:
return submitting(_that);case SaveProductSuccess() when success != null:
return success(_that);case SaveProductFailure() when failure != null:
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
case SaveProductInitial() when initial != null:
return initial();case SaveProductSubmitting() when submitting != null:
return submitting();case SaveProductSuccess() when success != null:
return success(_that.product);case SaveProductFailure() when failure != null:
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
case SaveProductInitial():
return initial();case SaveProductSubmitting():
return submitting();case SaveProductSuccess():
return success(_that.product);case SaveProductFailure():
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
case SaveProductInitial() when initial != null:
return initial();case SaveProductSubmitting() when submitting != null:
return submitting();case SaveProductSuccess() when success != null:
return success(_that.product);case SaveProductFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class SaveProductInitial implements SaveProductState {
  const SaveProductInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveProductInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SaveProductState.initial()';
}


}




/// @nodoc


class SaveProductSubmitting implements SaveProductState {
  const SaveProductSubmitting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveProductSubmitting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SaveProductState.submitting()';
}


}




/// @nodoc


class SaveProductSuccess implements SaveProductState {
  const SaveProductSuccess(this.product);
  

 final  Product product;

/// Create a copy of SaveProductState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SaveProductSuccessCopyWith<SaveProductSuccess> get copyWith => _$SaveProductSuccessCopyWithImpl<SaveProductSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveProductSuccess&&(identical(other.product, product) || other.product == product));
}


@override
int get hashCode => Object.hash(runtimeType,product);

@override
String toString() {
  return 'SaveProductState.success(product: $product)';
}


}

/// @nodoc
abstract mixin class $SaveProductSuccessCopyWith<$Res> implements $SaveProductStateCopyWith<$Res> {
  factory $SaveProductSuccessCopyWith(SaveProductSuccess value, $Res Function(SaveProductSuccess) _then) = _$SaveProductSuccessCopyWithImpl;
@useResult
$Res call({
 Product product
});


$ProductCopyWith<$Res> get product;

}
/// @nodoc
class _$SaveProductSuccessCopyWithImpl<$Res>
    implements $SaveProductSuccessCopyWith<$Res> {
  _$SaveProductSuccessCopyWithImpl(this._self, this._then);

  final SaveProductSuccess _self;
  final $Res Function(SaveProductSuccess) _then;

/// Create a copy of SaveProductState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? product = null,}) {
  return _then(SaveProductSuccess(
null == product ? _self.product : product // ignore: cast_nullable_to_non_nullable
as Product,
  ));
}

/// Create a copy of SaveProductState
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


class SaveProductFailure implements SaveProductState {
  const SaveProductFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of SaveProductState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SaveProductFailureCopyWith<SaveProductFailure> get copyWith => _$SaveProductFailureCopyWithImpl<SaveProductFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveProductFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'SaveProductState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $SaveProductFailureCopyWith<$Res> implements $SaveProductStateCopyWith<$Res> {
  factory $SaveProductFailureCopyWith(SaveProductFailure value, $Res Function(SaveProductFailure) _then) = _$SaveProductFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$SaveProductFailureCopyWithImpl<$Res>
    implements $SaveProductFailureCopyWith<$Res> {
  _$SaveProductFailureCopyWithImpl(this._self, this._then);

  final SaveProductFailure _self;
  final $Res Function(SaveProductFailure) _then;

/// Create a copy of SaveProductState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(SaveProductFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of SaveProductState
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
