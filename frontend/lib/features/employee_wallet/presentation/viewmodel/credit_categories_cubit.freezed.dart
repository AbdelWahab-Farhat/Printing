// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'credit_categories_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CreditCategoriesState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreditCategoriesState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CreditCategoriesState()';
}


}

/// @nodoc
class $CreditCategoriesStateCopyWith<$Res>  {
$CreditCategoriesStateCopyWith(CreditCategoriesState _, $Res Function(CreditCategoriesState) __);
}


/// Adds pattern-matching-related methods to [CreditCategoriesState].
extension CreditCategoriesStatePatterns on CreditCategoriesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CreditCategoriesLoading value)?  loading,TResult Function( CreditCategoriesFailed value)?  failed,TResult Function( CreditCategoriesLoaded value)?  loaded,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CreditCategoriesLoading() when loading != null:
return loading(_that);case CreditCategoriesFailed() when failed != null:
return failed(_that);case CreditCategoriesLoaded() when loaded != null:
return loaded(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CreditCategoriesLoading value)  loading,required TResult Function( CreditCategoriesFailed value)  failed,required TResult Function( CreditCategoriesLoaded value)  loaded,}){
final _that = this;
switch (_that) {
case CreditCategoriesLoading():
return loading(_that);case CreditCategoriesFailed():
return failed(_that);case CreditCategoriesLoaded():
return loaded(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CreditCategoriesLoading value)?  loading,TResult? Function( CreditCategoriesFailed value)?  failed,TResult? Function( CreditCategoriesLoaded value)?  loaded,}){
final _that = this;
switch (_that) {
case CreditCategoriesLoading() when loading != null:
return loading(_that);case CreditCategoriesFailed() when failed != null:
return failed(_that);case CreditCategoriesLoaded() when loaded != null:
return loaded(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( Failure failure)?  failed,TResult Function( List<ExpenseCategory> categories)?  loaded,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CreditCategoriesLoading() when loading != null:
return loading();case CreditCategoriesFailed() when failed != null:
return failed(_that.failure);case CreditCategoriesLoaded() when loaded != null:
return loaded(_that.categories);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( Failure failure)  failed,required TResult Function( List<ExpenseCategory> categories)  loaded,}) {final _that = this;
switch (_that) {
case CreditCategoriesLoading():
return loading();case CreditCategoriesFailed():
return failed(_that.failure);case CreditCategoriesLoaded():
return loaded(_that.categories);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( Failure failure)?  failed,TResult? Function( List<ExpenseCategory> categories)?  loaded,}) {final _that = this;
switch (_that) {
case CreditCategoriesLoading() when loading != null:
return loading();case CreditCategoriesFailed() when failed != null:
return failed(_that.failure);case CreditCategoriesLoaded() when loaded != null:
return loaded(_that.categories);case _:
  return null;

}
}

}

/// @nodoc


class CreditCategoriesLoading implements CreditCategoriesState {
  const CreditCategoriesLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreditCategoriesLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CreditCategoriesState.loading()';
}


}




/// @nodoc


class CreditCategoriesFailed implements CreditCategoriesState {
  const CreditCategoriesFailed(this.failure);
  

 final  Failure failure;

/// Create a copy of CreditCategoriesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreditCategoriesFailedCopyWith<CreditCategoriesFailed> get copyWith => _$CreditCategoriesFailedCopyWithImpl<CreditCategoriesFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreditCategoriesFailed&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'CreditCategoriesState.failed(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $CreditCategoriesFailedCopyWith<$Res> implements $CreditCategoriesStateCopyWith<$Res> {
  factory $CreditCategoriesFailedCopyWith(CreditCategoriesFailed value, $Res Function(CreditCategoriesFailed) _then) = _$CreditCategoriesFailedCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$CreditCategoriesFailedCopyWithImpl<$Res>
    implements $CreditCategoriesFailedCopyWith<$Res> {
  _$CreditCategoriesFailedCopyWithImpl(this._self, this._then);

  final CreditCategoriesFailed _self;
  final $Res Function(CreditCategoriesFailed) _then;

/// Create a copy of CreditCategoriesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(CreditCategoriesFailed(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of CreditCategoriesState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res> get failure {
  
  return $FailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

/// @nodoc


class CreditCategoriesLoaded implements CreditCategoriesState {
  const CreditCategoriesLoaded(final  List<ExpenseCategory> categories): _categories = categories;
  

 final  List<ExpenseCategory> _categories;
 List<ExpenseCategory> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}


/// Create a copy of CreditCategoriesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CreditCategoriesLoadedCopyWith<CreditCategoriesLoaded> get copyWith => _$CreditCategoriesLoadedCopyWithImpl<CreditCategoriesLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CreditCategoriesLoaded&&const DeepCollectionEquality().equals(other._categories, _categories));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_categories));

@override
String toString() {
  return 'CreditCategoriesState.loaded(categories: $categories)';
}


}

/// @nodoc
abstract mixin class $CreditCategoriesLoadedCopyWith<$Res> implements $CreditCategoriesStateCopyWith<$Res> {
  factory $CreditCategoriesLoadedCopyWith(CreditCategoriesLoaded value, $Res Function(CreditCategoriesLoaded) _then) = _$CreditCategoriesLoadedCopyWithImpl;
@useResult
$Res call({
 List<ExpenseCategory> categories
});




}
/// @nodoc
class _$CreditCategoriesLoadedCopyWithImpl<$Res>
    implements $CreditCategoriesLoadedCopyWith<$Res> {
  _$CreditCategoriesLoadedCopyWithImpl(this._self, this._then);

  final CreditCategoriesLoaded _self;
  final $Res Function(CreditCategoriesLoaded) _then;

/// Create a copy of CreditCategoriesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? categories = null,}) {
  return _then(CreditCategoriesLoaded(
null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<ExpenseCategory>,
  ));
}


}

// dart format on
