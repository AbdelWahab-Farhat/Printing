// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stock_item_group_items_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StockItemGroupItemsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StockItemGroupItemsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StockItemGroupItemsState()';
}


}

/// @nodoc
class $StockItemGroupItemsStateCopyWith<$Res>  {
$StockItemGroupItemsStateCopyWith(StockItemGroupItemsState _, $Res Function(StockItemGroupItemsState) __);
}


/// Adds pattern-matching-related methods to [StockItemGroupItemsState].
extension StockItemGroupItemsStatePatterns on StockItemGroupItemsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( StockItemGroupItemsInitial value)?  initial,TResult Function( StockItemGroupItemsLoading value)?  loading,TResult Function( StockItemGroupItemsLoaded value)?  loaded,TResult Function( StockItemGroupItemsFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case StockItemGroupItemsInitial() when initial != null:
return initial(_that);case StockItemGroupItemsLoading() when loading != null:
return loading(_that);case StockItemGroupItemsLoaded() when loaded != null:
return loaded(_that);case StockItemGroupItemsFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( StockItemGroupItemsInitial value)  initial,required TResult Function( StockItemGroupItemsLoading value)  loading,required TResult Function( StockItemGroupItemsLoaded value)  loaded,required TResult Function( StockItemGroupItemsFailure value)  failure,}){
final _that = this;
switch (_that) {
case StockItemGroupItemsInitial():
return initial(_that);case StockItemGroupItemsLoading():
return loading(_that);case StockItemGroupItemsLoaded():
return loaded(_that);case StockItemGroupItemsFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( StockItemGroupItemsInitial value)?  initial,TResult? Function( StockItemGroupItemsLoading value)?  loading,TResult? Function( StockItemGroupItemsLoaded value)?  loaded,TResult? Function( StockItemGroupItemsFailure value)?  failure,}){
final _that = this;
switch (_that) {
case StockItemGroupItemsInitial() when initial != null:
return initial(_that);case StockItemGroupItemsLoading() when loading != null:
return loading(_that);case StockItemGroupItemsLoaded() when loaded != null:
return loaded(_that);case StockItemGroupItemsFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( StockItemGroup group)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case StockItemGroupItemsInitial() when initial != null:
return initial();case StockItemGroupItemsLoading() when loading != null:
return loading();case StockItemGroupItemsLoaded() when loaded != null:
return loaded(_that.group);case StockItemGroupItemsFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( StockItemGroup group)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case StockItemGroupItemsInitial():
return initial();case StockItemGroupItemsLoading():
return loading();case StockItemGroupItemsLoaded():
return loaded(_that.group);case StockItemGroupItemsFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( StockItemGroup group)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case StockItemGroupItemsInitial() when initial != null:
return initial();case StockItemGroupItemsLoading() when loading != null:
return loading();case StockItemGroupItemsLoaded() when loaded != null:
return loaded(_that.group);case StockItemGroupItemsFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class StockItemGroupItemsInitial implements StockItemGroupItemsState {
  const StockItemGroupItemsInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StockItemGroupItemsInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StockItemGroupItemsState.initial()';
}


}




/// @nodoc


class StockItemGroupItemsLoading implements StockItemGroupItemsState {
  const StockItemGroupItemsLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StockItemGroupItemsLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StockItemGroupItemsState.loading()';
}


}




/// @nodoc


class StockItemGroupItemsLoaded implements StockItemGroupItemsState {
  const StockItemGroupItemsLoaded(this.group);
  

 final  StockItemGroup group;

/// Create a copy of StockItemGroupItemsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StockItemGroupItemsLoadedCopyWith<StockItemGroupItemsLoaded> get copyWith => _$StockItemGroupItemsLoadedCopyWithImpl<StockItemGroupItemsLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StockItemGroupItemsLoaded&&(identical(other.group, group) || other.group == group));
}


@override
int get hashCode => Object.hash(runtimeType,group);

@override
String toString() {
  return 'StockItemGroupItemsState.loaded(group: $group)';
}


}

/// @nodoc
abstract mixin class $StockItemGroupItemsLoadedCopyWith<$Res> implements $StockItemGroupItemsStateCopyWith<$Res> {
  factory $StockItemGroupItemsLoadedCopyWith(StockItemGroupItemsLoaded value, $Res Function(StockItemGroupItemsLoaded) _then) = _$StockItemGroupItemsLoadedCopyWithImpl;
@useResult
$Res call({
 StockItemGroup group
});


$StockItemGroupCopyWith<$Res> get group;

}
/// @nodoc
class _$StockItemGroupItemsLoadedCopyWithImpl<$Res>
    implements $StockItemGroupItemsLoadedCopyWith<$Res> {
  _$StockItemGroupItemsLoadedCopyWithImpl(this._self, this._then);

  final StockItemGroupItemsLoaded _self;
  final $Res Function(StockItemGroupItemsLoaded) _then;

/// Create a copy of StockItemGroupItemsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? group = null,}) {
  return _then(StockItemGroupItemsLoaded(
null == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as StockItemGroup,
  ));
}

/// Create a copy of StockItemGroupItemsState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StockItemGroupCopyWith<$Res> get group {
  
  return $StockItemGroupCopyWith<$Res>(_self.group, (value) {
    return _then(_self.copyWith(group: value));
  });
}
}

/// @nodoc


class StockItemGroupItemsFailure implements StockItemGroupItemsState {
  const StockItemGroupItemsFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of StockItemGroupItemsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StockItemGroupItemsFailureCopyWith<StockItemGroupItemsFailure> get copyWith => _$StockItemGroupItemsFailureCopyWithImpl<StockItemGroupItemsFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StockItemGroupItemsFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'StockItemGroupItemsState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $StockItemGroupItemsFailureCopyWith<$Res> implements $StockItemGroupItemsStateCopyWith<$Res> {
  factory $StockItemGroupItemsFailureCopyWith(StockItemGroupItemsFailure value, $Res Function(StockItemGroupItemsFailure) _then) = _$StockItemGroupItemsFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$StockItemGroupItemsFailureCopyWithImpl<$Res>
    implements $StockItemGroupItemsFailureCopyWith<$Res> {
  _$StockItemGroupItemsFailureCopyWithImpl(this._self, this._then);

  final StockItemGroupItemsFailure _self;
  final $Res Function(StockItemGroupItemsFailure) _then;

/// Create a copy of StockItemGroupItemsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(StockItemGroupItemsFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of StockItemGroupItemsState
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
