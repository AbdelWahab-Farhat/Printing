// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'customer_comments_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CustomerCommentsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerCommentsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CustomerCommentsState()';
}


}

/// @nodoc
class $CustomerCommentsStateCopyWith<$Res>  {
$CustomerCommentsStateCopyWith(CustomerCommentsState _, $Res Function(CustomerCommentsState) __);
}


/// Adds pattern-matching-related methods to [CustomerCommentsState].
extension CustomerCommentsStatePatterns on CustomerCommentsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CustomerCommentsLoading value)?  loading,TResult Function( CustomerCommentsLoaded value)?  loaded,TResult Function( CustomerCommentsFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CustomerCommentsLoading() when loading != null:
return loading(_that);case CustomerCommentsLoaded() when loaded != null:
return loaded(_that);case CustomerCommentsFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CustomerCommentsLoading value)  loading,required TResult Function( CustomerCommentsLoaded value)  loaded,required TResult Function( CustomerCommentsFailure value)  failure,}){
final _that = this;
switch (_that) {
case CustomerCommentsLoading():
return loading(_that);case CustomerCommentsLoaded():
return loaded(_that);case CustomerCommentsFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CustomerCommentsLoading value)?  loading,TResult? Function( CustomerCommentsLoaded value)?  loaded,TResult? Function( CustomerCommentsFailure value)?  failure,}){
final _that = this;
switch (_that) {
case CustomerCommentsLoading() when loading != null:
return loading(_that);case CustomerCommentsLoaded() when loaded != null:
return loaded(_that);case CustomerCommentsFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<CustomerComment> comments,  Set<int> busy,  bool isAdding)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CustomerCommentsLoading() when loading != null:
return loading();case CustomerCommentsLoaded() when loaded != null:
return loaded(_that.comments,_that.busy,_that.isAdding);case CustomerCommentsFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<CustomerComment> comments,  Set<int> busy,  bool isAdding)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case CustomerCommentsLoading():
return loading();case CustomerCommentsLoaded():
return loaded(_that.comments,_that.busy,_that.isAdding);case CustomerCommentsFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<CustomerComment> comments,  Set<int> busy,  bool isAdding)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case CustomerCommentsLoading() when loading != null:
return loading();case CustomerCommentsLoaded() when loaded != null:
return loaded(_that.comments,_that.busy,_that.isAdding);case CustomerCommentsFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class CustomerCommentsLoading implements CustomerCommentsState {
  const CustomerCommentsLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerCommentsLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CustomerCommentsState.loading()';
}


}




/// @nodoc


class CustomerCommentsLoaded implements CustomerCommentsState {
  const CustomerCommentsLoaded({required final  List<CustomerComment> comments, final  Set<int> busy = const <int>{}, this.isAdding = false}): _comments = comments,_busy = busy;
  

 final  List<CustomerComment> _comments;
 List<CustomerComment> get comments {
  if (_comments is EqualUnmodifiableListView) return _comments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_comments);
}

/// Ids of notes being rewritten or removed right now. A set rather than a single id
/// because two rows can be worked on at once and each has to show its own state.
 final  Set<int> _busy;
/// Ids of notes being rewritten or removed right now. A set rather than a single id
/// because two rows can be worked on at once and each has to show its own state.
@JsonKey() Set<int> get busy {
  if (_busy is EqualUnmodifiableSetView) return _busy;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_busy);
}

/// True while a *new* note is on its way up. Separate from [busy], which is keyed by id —
/// a note that does not exist yet has none.
@JsonKey() final  bool isAdding;

/// Create a copy of CustomerCommentsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerCommentsLoadedCopyWith<CustomerCommentsLoaded> get copyWith => _$CustomerCommentsLoadedCopyWithImpl<CustomerCommentsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerCommentsLoaded&&const DeepCollectionEquality().equals(other._comments, _comments)&&const DeepCollectionEquality().equals(other._busy, _busy)&&(identical(other.isAdding, isAdding) || other.isAdding == isAdding));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_comments),const DeepCollectionEquality().hash(_busy),isAdding);

@override
String toString() {
  return 'CustomerCommentsState.loaded(comments: $comments, busy: $busy, isAdding: $isAdding)';
}


}

/// @nodoc
abstract mixin class $CustomerCommentsLoadedCopyWith<$Res> implements $CustomerCommentsStateCopyWith<$Res> {
  factory $CustomerCommentsLoadedCopyWith(CustomerCommentsLoaded value, $Res Function(CustomerCommentsLoaded) _then) = _$CustomerCommentsLoadedCopyWithImpl;
@useResult
$Res call({
 List<CustomerComment> comments, Set<int> busy, bool isAdding
});




}
/// @nodoc
class _$CustomerCommentsLoadedCopyWithImpl<$Res>
    implements $CustomerCommentsLoadedCopyWith<$Res> {
  _$CustomerCommentsLoadedCopyWithImpl(this._self, this._then);

  final CustomerCommentsLoaded _self;
  final $Res Function(CustomerCommentsLoaded) _then;

/// Create a copy of CustomerCommentsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? comments = null,Object? busy = null,Object? isAdding = null,}) {
  return _then(CustomerCommentsLoaded(
comments: null == comments ? _self._comments : comments // ignore: cast_nullable_to_non_nullable
as List<CustomerComment>,busy: null == busy ? _self._busy : busy // ignore: cast_nullable_to_non_nullable
as Set<int>,isAdding: null == isAdding ? _self.isAdding : isAdding // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class CustomerCommentsFailure implements CustomerCommentsState {
  const CustomerCommentsFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of CustomerCommentsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CustomerCommentsFailureCopyWith<CustomerCommentsFailure> get copyWith => _$CustomerCommentsFailureCopyWithImpl<CustomerCommentsFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CustomerCommentsFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'CustomerCommentsState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $CustomerCommentsFailureCopyWith<$Res> implements $CustomerCommentsStateCopyWith<$Res> {
  factory $CustomerCommentsFailureCopyWith(CustomerCommentsFailure value, $Res Function(CustomerCommentsFailure) _then) = _$CustomerCommentsFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$CustomerCommentsFailureCopyWithImpl<$Res>
    implements $CustomerCommentsFailureCopyWith<$Res> {
  _$CustomerCommentsFailureCopyWithImpl(this._self, this._then);

  final CustomerCommentsFailure _self;
  final $Res Function(CustomerCommentsFailure) _then;

/// Create a copy of CustomerCommentsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(CustomerCommentsFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of CustomerCommentsState
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
