// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'save_product_category_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SaveProductCategoryState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveProductCategoryState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SaveProductCategoryState()';
}


}

/// @nodoc
class $SaveProductCategoryStateCopyWith<$Res>  {
$SaveProductCategoryStateCopyWith(SaveProductCategoryState _, $Res Function(SaveProductCategoryState) __);
}


/// Adds pattern-matching-related methods to [SaveProductCategoryState].
extension SaveProductCategoryStatePatterns on SaveProductCategoryState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SaveProductCategoryInitial value)?  initial,TResult Function( SaveProductCategorySubmitting value)?  submitting,TResult Function( SaveProductCategorySuccess value)?  success,TResult Function( SaveProductCategoryFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SaveProductCategoryInitial() when initial != null:
return initial(_that);case SaveProductCategorySubmitting() when submitting != null:
return submitting(_that);case SaveProductCategorySuccess() when success != null:
return success(_that);case SaveProductCategoryFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SaveProductCategoryInitial value)  initial,required TResult Function( SaveProductCategorySubmitting value)  submitting,required TResult Function( SaveProductCategorySuccess value)  success,required TResult Function( SaveProductCategoryFailure value)  failure,}){
final _that = this;
switch (_that) {
case SaveProductCategoryInitial():
return initial(_that);case SaveProductCategorySubmitting():
return submitting(_that);case SaveProductCategorySuccess():
return success(_that);case SaveProductCategoryFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SaveProductCategoryInitial value)?  initial,TResult? Function( SaveProductCategorySubmitting value)?  submitting,TResult? Function( SaveProductCategorySuccess value)?  success,TResult? Function( SaveProductCategoryFailure value)?  failure,}){
final _that = this;
switch (_that) {
case SaveProductCategoryInitial() when initial != null:
return initial(_that);case SaveProductCategorySubmitting() when submitting != null:
return submitting(_that);case SaveProductCategorySuccess() when success != null:
return success(_that);case SaveProductCategoryFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  submitting,TResult Function( ProductCategory category)?  success,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SaveProductCategoryInitial() when initial != null:
return initial();case SaveProductCategorySubmitting() when submitting != null:
return submitting();case SaveProductCategorySuccess() when success != null:
return success(_that.category);case SaveProductCategoryFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  submitting,required TResult Function( ProductCategory category)  success,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case SaveProductCategoryInitial():
return initial();case SaveProductCategorySubmitting():
return submitting();case SaveProductCategorySuccess():
return success(_that.category);case SaveProductCategoryFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  submitting,TResult? Function( ProductCategory category)?  success,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case SaveProductCategoryInitial() when initial != null:
return initial();case SaveProductCategorySubmitting() when submitting != null:
return submitting();case SaveProductCategorySuccess() when success != null:
return success(_that.category);case SaveProductCategoryFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class SaveProductCategoryInitial implements SaveProductCategoryState {
  const SaveProductCategoryInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveProductCategoryInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SaveProductCategoryState.initial()';
}


}




/// @nodoc


class SaveProductCategorySubmitting implements SaveProductCategoryState {
  const SaveProductCategorySubmitting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveProductCategorySubmitting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SaveProductCategoryState.submitting()';
}


}




/// @nodoc


class SaveProductCategorySuccess implements SaveProductCategoryState {
  const SaveProductCategorySuccess(this.category);
  

 final  ProductCategory category;

/// Create a copy of SaveProductCategoryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SaveProductCategorySuccessCopyWith<SaveProductCategorySuccess> get copyWith => _$SaveProductCategorySuccessCopyWithImpl<SaveProductCategorySuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveProductCategorySuccess&&(identical(other.category, category) || other.category == category));
}


@override
int get hashCode => Object.hash(runtimeType,category);

@override
String toString() {
  return 'SaveProductCategoryState.success(category: $category)';
}


}

/// @nodoc
abstract mixin class $SaveProductCategorySuccessCopyWith<$Res> implements $SaveProductCategoryStateCopyWith<$Res> {
  factory $SaveProductCategorySuccessCopyWith(SaveProductCategorySuccess value, $Res Function(SaveProductCategorySuccess) _then) = _$SaveProductCategorySuccessCopyWithImpl;
@useResult
$Res call({
 ProductCategory category
});


$ProductCategoryCopyWith<$Res> get category;

}
/// @nodoc
class _$SaveProductCategorySuccessCopyWithImpl<$Res>
    implements $SaveProductCategorySuccessCopyWith<$Res> {
  _$SaveProductCategorySuccessCopyWithImpl(this._self, this._then);

  final SaveProductCategorySuccess _self;
  final $Res Function(SaveProductCategorySuccess) _then;

/// Create a copy of SaveProductCategoryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? category = null,}) {
  return _then(SaveProductCategorySuccess(
null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ProductCategory,
  ));
}

/// Create a copy of SaveProductCategoryState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProductCategoryCopyWith<$Res> get category {
  
  return $ProductCategoryCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}

/// @nodoc


class SaveProductCategoryFailure implements SaveProductCategoryState {
  const SaveProductCategoryFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of SaveProductCategoryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SaveProductCategoryFailureCopyWith<SaveProductCategoryFailure> get copyWith => _$SaveProductCategoryFailureCopyWithImpl<SaveProductCategoryFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveProductCategoryFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'SaveProductCategoryState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $SaveProductCategoryFailureCopyWith<$Res> implements $SaveProductCategoryStateCopyWith<$Res> {
  factory $SaveProductCategoryFailureCopyWith(SaveProductCategoryFailure value, $Res Function(SaveProductCategoryFailure) _then) = _$SaveProductCategoryFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$SaveProductCategoryFailureCopyWithImpl<$Res>
    implements $SaveProductCategoryFailureCopyWith<$Res> {
  _$SaveProductCategoryFailureCopyWithImpl(this._self, this._then);

  final SaveProductCategoryFailure _self;
  final $Res Function(SaveProductCategoryFailure) _then;

/// Create a copy of SaveProductCategoryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(SaveProductCategoryFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of SaveProductCategoryState
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
