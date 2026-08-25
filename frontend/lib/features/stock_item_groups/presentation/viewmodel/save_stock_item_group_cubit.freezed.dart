// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'save_stock_item_group_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SaveStockItemGroupState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveStockItemGroupState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SaveStockItemGroupState()';
}


}

/// @nodoc
class $SaveStockItemGroupStateCopyWith<$Res>  {
$SaveStockItemGroupStateCopyWith(SaveStockItemGroupState _, $Res Function(SaveStockItemGroupState) __);
}


/// Adds pattern-matching-related methods to [SaveStockItemGroupState].
extension SaveStockItemGroupStatePatterns on SaveStockItemGroupState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SaveStockItemGroupInitial value)?  initial,TResult Function( SaveStockItemGroupSubmitting value)?  submitting,TResult Function( SaveStockItemGroupSuccess value)?  success,TResult Function( SaveStockItemGroupFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SaveStockItemGroupInitial() when initial != null:
return initial(_that);case SaveStockItemGroupSubmitting() when submitting != null:
return submitting(_that);case SaveStockItemGroupSuccess() when success != null:
return success(_that);case SaveStockItemGroupFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SaveStockItemGroupInitial value)  initial,required TResult Function( SaveStockItemGroupSubmitting value)  submitting,required TResult Function( SaveStockItemGroupSuccess value)  success,required TResult Function( SaveStockItemGroupFailure value)  failure,}){
final _that = this;
switch (_that) {
case SaveStockItemGroupInitial():
return initial(_that);case SaveStockItemGroupSubmitting():
return submitting(_that);case SaveStockItemGroupSuccess():
return success(_that);case SaveStockItemGroupFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SaveStockItemGroupInitial value)?  initial,TResult? Function( SaveStockItemGroupSubmitting value)?  submitting,TResult? Function( SaveStockItemGroupSuccess value)?  success,TResult? Function( SaveStockItemGroupFailure value)?  failure,}){
final _that = this;
switch (_that) {
case SaveStockItemGroupInitial() when initial != null:
return initial(_that);case SaveStockItemGroupSubmitting() when submitting != null:
return submitting(_that);case SaveStockItemGroupSuccess() when success != null:
return success(_that);case SaveStockItemGroupFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  submitting,TResult Function( StockItemGroup group)?  success,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SaveStockItemGroupInitial() when initial != null:
return initial();case SaveStockItemGroupSubmitting() when submitting != null:
return submitting();case SaveStockItemGroupSuccess() when success != null:
return success(_that.group);case SaveStockItemGroupFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  submitting,required TResult Function( StockItemGroup group)  success,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case SaveStockItemGroupInitial():
return initial();case SaveStockItemGroupSubmitting():
return submitting();case SaveStockItemGroupSuccess():
return success(_that.group);case SaveStockItemGroupFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  submitting,TResult? Function( StockItemGroup group)?  success,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case SaveStockItemGroupInitial() when initial != null:
return initial();case SaveStockItemGroupSubmitting() when submitting != null:
return submitting();case SaveStockItemGroupSuccess() when success != null:
return success(_that.group);case SaveStockItemGroupFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class SaveStockItemGroupInitial implements SaveStockItemGroupState {
  const SaveStockItemGroupInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveStockItemGroupInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SaveStockItemGroupState.initial()';
}


}




/// @nodoc


class SaveStockItemGroupSubmitting implements SaveStockItemGroupState {
  const SaveStockItemGroupSubmitting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveStockItemGroupSubmitting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SaveStockItemGroupState.submitting()';
}


}




/// @nodoc


class SaveStockItemGroupSuccess implements SaveStockItemGroupState {
  const SaveStockItemGroupSuccess(this.group);
  

 final  StockItemGroup group;

/// Create a copy of SaveStockItemGroupState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SaveStockItemGroupSuccessCopyWith<SaveStockItemGroupSuccess> get copyWith => _$SaveStockItemGroupSuccessCopyWithImpl<SaveStockItemGroupSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveStockItemGroupSuccess&&(identical(other.group, group) || other.group == group));
}


@override
int get hashCode => Object.hash(runtimeType,group);

@override
String toString() {
  return 'SaveStockItemGroupState.success(group: $group)';
}


}

/// @nodoc
abstract mixin class $SaveStockItemGroupSuccessCopyWith<$Res> implements $SaveStockItemGroupStateCopyWith<$Res> {
  factory $SaveStockItemGroupSuccessCopyWith(SaveStockItemGroupSuccess value, $Res Function(SaveStockItemGroupSuccess) _then) = _$SaveStockItemGroupSuccessCopyWithImpl;
@useResult
$Res call({
 StockItemGroup group
});


$StockItemGroupCopyWith<$Res> get group;

}
/// @nodoc
class _$SaveStockItemGroupSuccessCopyWithImpl<$Res>
    implements $SaveStockItemGroupSuccessCopyWith<$Res> {
  _$SaveStockItemGroupSuccessCopyWithImpl(this._self, this._then);

  final SaveStockItemGroupSuccess _self;
  final $Res Function(SaveStockItemGroupSuccess) _then;

/// Create a copy of SaveStockItemGroupState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? group = null,}) {
  return _then(SaveStockItemGroupSuccess(
null == group ? _self.group : group // ignore: cast_nullable_to_non_nullable
as StockItemGroup,
  ));
}

/// Create a copy of SaveStockItemGroupState
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


class SaveStockItemGroupFailure implements SaveStockItemGroupState {
  const SaveStockItemGroupFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of SaveStockItemGroupState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SaveStockItemGroupFailureCopyWith<SaveStockItemGroupFailure> get copyWith => _$SaveStockItemGroupFailureCopyWithImpl<SaveStockItemGroupFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveStockItemGroupFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'SaveStockItemGroupState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $SaveStockItemGroupFailureCopyWith<$Res> implements $SaveStockItemGroupStateCopyWith<$Res> {
  factory $SaveStockItemGroupFailureCopyWith(SaveStockItemGroupFailure value, $Res Function(SaveStockItemGroupFailure) _then) = _$SaveStockItemGroupFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$SaveStockItemGroupFailureCopyWithImpl<$Res>
    implements $SaveStockItemGroupFailureCopyWith<$Res> {
  _$SaveStockItemGroupFailureCopyWithImpl(this._self, this._then);

  final SaveStockItemGroupFailure _self;
  final $Res Function(SaveStockItemGroupFailure) _then;

/// Create a copy of SaveStockItemGroupState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(SaveStockItemGroupFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of SaveStockItemGroupState
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
