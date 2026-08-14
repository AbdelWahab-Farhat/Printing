// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'comments_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CommentsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommentsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CommentsState()';
}


}

/// @nodoc
class $CommentsStateCopyWith<$Res>  {
$CommentsStateCopyWith(CommentsState _, $Res Function(CommentsState) __);
}


/// Adds pattern-matching-related methods to [CommentsState].
extension CommentsStatePatterns on CommentsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CommentsLoading value)?  loading,TResult Function( CommentsLoaded value)?  loaded,TResult Function( CommentsFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CommentsLoading() when loading != null:
return loading(_that);case CommentsLoaded() when loaded != null:
return loaded(_that);case CommentsFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CommentsLoading value)  loading,required TResult Function( CommentsLoaded value)  loaded,required TResult Function( CommentsFailure value)  failure,}){
final _that = this;
switch (_that) {
case CommentsLoading():
return loading(_that);case CommentsLoaded():
return loaded(_that);case CommentsFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CommentsLoading value)?  loading,TResult? Function( CommentsLoaded value)?  loaded,TResult? Function( CommentsFailure value)?  failure,}){
final _that = this;
switch (_that) {
case CommentsLoading() when loading != null:
return loading(_that);case CommentsLoaded() when loaded != null:
return loaded(_that);case CommentsFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<Comment> comments,  Set<int> busy,  bool isAdding)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CommentsLoading() when loading != null:
return loading();case CommentsLoaded() when loaded != null:
return loaded(_that.comments,_that.busy,_that.isAdding);case CommentsFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<Comment> comments,  Set<int> busy,  bool isAdding)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case CommentsLoading():
return loading();case CommentsLoaded():
return loaded(_that.comments,_that.busy,_that.isAdding);case CommentsFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<Comment> comments,  Set<int> busy,  bool isAdding)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case CommentsLoading() when loading != null:
return loading();case CommentsLoaded() when loaded != null:
return loaded(_that.comments,_that.busy,_that.isAdding);case CommentsFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class CommentsLoading implements CommentsState {
  const CommentsLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommentsLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'CommentsState.loading()';
}


}




/// @nodoc


class CommentsLoaded implements CommentsState {
  const CommentsLoaded({required final  List<Comment> comments, final  Set<int> busy = const <int>{}, this.isAdding = false}): _comments = comments,_busy = busy;
  

 final  List<Comment> _comments;
 List<Comment> get comments {
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

/// Create a copy of CommentsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommentsLoadedCopyWith<CommentsLoaded> get copyWith => _$CommentsLoadedCopyWithImpl<CommentsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommentsLoaded&&const DeepCollectionEquality().equals(other._comments, _comments)&&const DeepCollectionEquality().equals(other._busy, _busy)&&(identical(other.isAdding, isAdding) || other.isAdding == isAdding));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_comments),const DeepCollectionEquality().hash(_busy),isAdding);

@override
String toString() {
  return 'CommentsState.loaded(comments: $comments, busy: $busy, isAdding: $isAdding)';
}


}

/// @nodoc
abstract mixin class $CommentsLoadedCopyWith<$Res> implements $CommentsStateCopyWith<$Res> {
  factory $CommentsLoadedCopyWith(CommentsLoaded value, $Res Function(CommentsLoaded) _then) = _$CommentsLoadedCopyWithImpl;
@useResult
$Res call({
 List<Comment> comments, Set<int> busy, bool isAdding
});




}
/// @nodoc
class _$CommentsLoadedCopyWithImpl<$Res>
    implements $CommentsLoadedCopyWith<$Res> {
  _$CommentsLoadedCopyWithImpl(this._self, this._then);

  final CommentsLoaded _self;
  final $Res Function(CommentsLoaded) _then;

/// Create a copy of CommentsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? comments = null,Object? busy = null,Object? isAdding = null,}) {
  return _then(CommentsLoaded(
comments: null == comments ? _self._comments : comments // ignore: cast_nullable_to_non_nullable
as List<Comment>,busy: null == busy ? _self._busy : busy // ignore: cast_nullable_to_non_nullable
as Set<int>,isAdding: null == isAdding ? _self.isAdding : isAdding // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class CommentsFailure implements CommentsState {
  const CommentsFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of CommentsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommentsFailureCopyWith<CommentsFailure> get copyWith => _$CommentsFailureCopyWithImpl<CommentsFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommentsFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'CommentsState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $CommentsFailureCopyWith<$Res> implements $CommentsStateCopyWith<$Res> {
  factory $CommentsFailureCopyWith(CommentsFailure value, $Res Function(CommentsFailure) _then) = _$CommentsFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$CommentsFailureCopyWithImpl<$Res>
    implements $CommentsFailureCopyWith<$Res> {
  _$CommentsFailureCopyWithImpl(this._self, this._then);

  final CommentsFailure _self;
  final $Res Function(CommentsFailure) _then;

/// Create a copy of CommentsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(CommentsFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of CommentsState
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
