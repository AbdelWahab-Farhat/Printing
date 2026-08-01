// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'paged_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PagedState<T> {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PagedState<T>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PagedState<$T>()';
}


}

/// @nodoc
class $PagedStateCopyWith<T,$Res>  {
$PagedStateCopyWith(PagedState<T> _, $Res Function(PagedState<T>) __);
}


/// Adds pattern-matching-related methods to [PagedState].
extension PagedStatePatterns<T> on PagedState<T> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PagedInitial<T> value)?  initial,TResult Function( PagedLoading<T> value)?  loading,TResult Function( PagedLoaded<T> value)?  loaded,TResult Function( PagedFailure<T> value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PagedInitial() when initial != null:
return initial(_that);case PagedLoading() when loading != null:
return loading(_that);case PagedLoaded() when loaded != null:
return loaded(_that);case PagedFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PagedInitial<T> value)  initial,required TResult Function( PagedLoading<T> value)  loading,required TResult Function( PagedLoaded<T> value)  loaded,required TResult Function( PagedFailure<T> value)  failure,}){
final _that = this;
switch (_that) {
case PagedInitial():
return initial(_that);case PagedLoading():
return loading(_that);case PagedLoaded():
return loaded(_that);case PagedFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PagedInitial<T> value)?  initial,TResult? Function( PagedLoading<T> value)?  loading,TResult? Function( PagedLoaded<T> value)?  loaded,TResult? Function( PagedFailure<T> value)?  failure,}){
final _that = this;
switch (_that) {
case PagedInitial() when initial != null:
return initial(_that);case PagedLoading() when loading != null:
return loading(_that);case PagedLoaded() when loaded != null:
return loaded(_that);case PagedFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( Paginated<T> page,  bool isLoadingMore,  String? search)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PagedInitial() when initial != null:
return initial();case PagedLoading() when loading != null:
return loading();case PagedLoaded() when loaded != null:
return loaded(_that.page,_that.isLoadingMore,_that.search);case PagedFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( Paginated<T> page,  bool isLoadingMore,  String? search)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case PagedInitial():
return initial();case PagedLoading():
return loading();case PagedLoaded():
return loaded(_that.page,_that.isLoadingMore,_that.search);case PagedFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( Paginated<T> page,  bool isLoadingMore,  String? search)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case PagedInitial() when initial != null:
return initial();case PagedLoading() when loading != null:
return loading();case PagedLoaded() when loaded != null:
return loaded(_that.page,_that.isLoadingMore,_that.search);case PagedFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class PagedInitial<T> implements PagedState<T> {
  const PagedInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PagedInitial<T>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PagedState<$T>.initial()';
}


}




/// @nodoc


class PagedLoading<T> implements PagedState<T> {
  const PagedLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PagedLoading<T>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PagedState<$T>.loading()';
}


}




/// @nodoc


class PagedLoaded<T> implements PagedState<T> {
  const PagedLoaded({required this.page, this.isLoadingMore = false, this.search});
  

 final  Paginated<T> page;
/// A further page is on its way. Inside `loaded` rather than a case of its own, because
/// everything already fetched stays on screen while it happens.
@JsonKey() final  bool isLoadingMore;
/// The term these results belong to. Kept so an empty result can say *what* found nothing,
/// and so a late response for an old term can be dropped instead of overwriting a newer one.
 final  String? search;

/// Create a copy of PagedState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PagedLoadedCopyWith<T, PagedLoaded<T>> get copyWith => _$PagedLoadedCopyWithImpl<T, PagedLoaded<T>>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PagedLoaded<T>&&(identical(other.page, page) || other.page == page)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&(identical(other.search, search) || other.search == search));
}


@override
int get hashCode => Object.hash(runtimeType,page,isLoadingMore,search);

@override
String toString() {
  return 'PagedState<$T>.loaded(page: $page, isLoadingMore: $isLoadingMore, search: $search)';
}


}

/// @nodoc
abstract mixin class $PagedLoadedCopyWith<T,$Res> implements $PagedStateCopyWith<T, $Res> {
  factory $PagedLoadedCopyWith(PagedLoaded<T> value, $Res Function(PagedLoaded<T>) _then) = _$PagedLoadedCopyWithImpl;
@useResult
$Res call({
 Paginated<T> page, bool isLoadingMore, String? search
});




}
/// @nodoc
class _$PagedLoadedCopyWithImpl<T,$Res>
    implements $PagedLoadedCopyWith<T, $Res> {
  _$PagedLoadedCopyWithImpl(this._self, this._then);

  final PagedLoaded<T> _self;
  final $Res Function(PagedLoaded<T>) _then;

/// Create a copy of PagedState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? page = null,Object? isLoadingMore = null,Object? search = freezed,}) {
  return _then(PagedLoaded<T>(
page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as Paginated<T>,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,search: freezed == search ? _self.search : search // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class PagedFailure<T> implements PagedState<T> {
  const PagedFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of PagedState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PagedFailureCopyWith<T, PagedFailure<T>> get copyWith => _$PagedFailureCopyWithImpl<T, PagedFailure<T>>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PagedFailure<T>&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'PagedState<$T>.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $PagedFailureCopyWith<T,$Res> implements $PagedStateCopyWith<T, $Res> {
  factory $PagedFailureCopyWith(PagedFailure<T> value, $Res Function(PagedFailure<T>) _then) = _$PagedFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$PagedFailureCopyWithImpl<T,$Res>
    implements $PagedFailureCopyWith<T, $Res> {
  _$PagedFailureCopyWithImpl(this._self, this._then);

  final PagedFailure<T> _self;
  final $Res Function(PagedFailure<T>) _then;

/// Create a copy of PagedState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(PagedFailure<T>(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of PagedState
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
