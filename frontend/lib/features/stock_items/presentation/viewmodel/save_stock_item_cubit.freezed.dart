// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'save_stock_item_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SaveStockItemState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveStockItemState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SaveStockItemState()';
}


}

/// @nodoc
class $SaveStockItemStateCopyWith<$Res>  {
$SaveStockItemStateCopyWith(SaveStockItemState _, $Res Function(SaveStockItemState) __);
}


/// Adds pattern-matching-related methods to [SaveStockItemState].
extension SaveStockItemStatePatterns on SaveStockItemState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SaveStockItemInitial value)?  initial,TResult Function( SaveStockItemSubmitting value)?  submitting,TResult Function( SaveStockItemSuccess value)?  success,TResult Function( SaveStockItemChangingUnit value)?  changingUnit,TResult Function( SaveStockItemUnitChanged value)?  unitChanged,TResult Function( SaveStockItemLinksRefused value)?  linksRefused,TResult Function( SaveStockItemFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SaveStockItemInitial() when initial != null:
return initial(_that);case SaveStockItemSubmitting() when submitting != null:
return submitting(_that);case SaveStockItemSuccess() when success != null:
return success(_that);case SaveStockItemChangingUnit() when changingUnit != null:
return changingUnit(_that);case SaveStockItemUnitChanged() when unitChanged != null:
return unitChanged(_that);case SaveStockItemLinksRefused() when linksRefused != null:
return linksRefused(_that);case SaveStockItemFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SaveStockItemInitial value)  initial,required TResult Function( SaveStockItemSubmitting value)  submitting,required TResult Function( SaveStockItemSuccess value)  success,required TResult Function( SaveStockItemChangingUnit value)  changingUnit,required TResult Function( SaveStockItemUnitChanged value)  unitChanged,required TResult Function( SaveStockItemLinksRefused value)  linksRefused,required TResult Function( SaveStockItemFailure value)  failure,}){
final _that = this;
switch (_that) {
case SaveStockItemInitial():
return initial(_that);case SaveStockItemSubmitting():
return submitting(_that);case SaveStockItemSuccess():
return success(_that);case SaveStockItemChangingUnit():
return changingUnit(_that);case SaveStockItemUnitChanged():
return unitChanged(_that);case SaveStockItemLinksRefused():
return linksRefused(_that);case SaveStockItemFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SaveStockItemInitial value)?  initial,TResult? Function( SaveStockItemSubmitting value)?  submitting,TResult? Function( SaveStockItemSuccess value)?  success,TResult? Function( SaveStockItemChangingUnit value)?  changingUnit,TResult? Function( SaveStockItemUnitChanged value)?  unitChanged,TResult? Function( SaveStockItemLinksRefused value)?  linksRefused,TResult? Function( SaveStockItemFailure value)?  failure,}){
final _that = this;
switch (_that) {
case SaveStockItemInitial() when initial != null:
return initial(_that);case SaveStockItemSubmitting() when submitting != null:
return submitting(_that);case SaveStockItemSuccess() when success != null:
return success(_that);case SaveStockItemChangingUnit() when changingUnit != null:
return changingUnit(_that);case SaveStockItemUnitChanged() when unitChanged != null:
return unitChanged(_that);case SaveStockItemLinksRefused() when linksRefused != null:
return linksRefused(_that);case SaveStockItemFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  submitting,TResult Function( StockItem item)?  success,TResult Function()?  changingUnit,TResult Function( StockItem item)?  unitChanged,TResult Function( StockItem item,  Failure failure)?  linksRefused,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SaveStockItemInitial() when initial != null:
return initial();case SaveStockItemSubmitting() when submitting != null:
return submitting();case SaveStockItemSuccess() when success != null:
return success(_that.item);case SaveStockItemChangingUnit() when changingUnit != null:
return changingUnit();case SaveStockItemUnitChanged() when unitChanged != null:
return unitChanged(_that.item);case SaveStockItemLinksRefused() when linksRefused != null:
return linksRefused(_that.item,_that.failure);case SaveStockItemFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  submitting,required TResult Function( StockItem item)  success,required TResult Function()  changingUnit,required TResult Function( StockItem item)  unitChanged,required TResult Function( StockItem item,  Failure failure)  linksRefused,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case SaveStockItemInitial():
return initial();case SaveStockItemSubmitting():
return submitting();case SaveStockItemSuccess():
return success(_that.item);case SaveStockItemChangingUnit():
return changingUnit();case SaveStockItemUnitChanged():
return unitChanged(_that.item);case SaveStockItemLinksRefused():
return linksRefused(_that.item,_that.failure);case SaveStockItemFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  submitting,TResult? Function( StockItem item)?  success,TResult? Function()?  changingUnit,TResult? Function( StockItem item)?  unitChanged,TResult? Function( StockItem item,  Failure failure)?  linksRefused,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case SaveStockItemInitial() when initial != null:
return initial();case SaveStockItemSubmitting() when submitting != null:
return submitting();case SaveStockItemSuccess() when success != null:
return success(_that.item);case SaveStockItemChangingUnit() when changingUnit != null:
return changingUnit();case SaveStockItemUnitChanged() when unitChanged != null:
return unitChanged(_that.item);case SaveStockItemLinksRefused() when linksRefused != null:
return linksRefused(_that.item,_that.failure);case SaveStockItemFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class SaveStockItemInitial implements SaveStockItemState {
  const SaveStockItemInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveStockItemInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SaveStockItemState.initial()';
}


}




/// @nodoc


class SaveStockItemSubmitting implements SaveStockItemState {
  const SaveStockItemSubmitting();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveStockItemSubmitting);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SaveStockItemState.submitting()';
}


}




/// @nodoc


class SaveStockItemSuccess implements SaveStockItemState {
  const SaveStockItemSuccess(this.item);
  

 final  StockItem item;

/// Create a copy of SaveStockItemState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SaveStockItemSuccessCopyWith<SaveStockItemSuccess> get copyWith => _$SaveStockItemSuccessCopyWithImpl<SaveStockItemSuccess>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveStockItemSuccess&&(identical(other.item, item) || other.item == item));
}


@override
int get hashCode => Object.hash(runtimeType,item);

@override
String toString() {
  return 'SaveStockItemState.success(item: $item)';
}


}

/// @nodoc
abstract mixin class $SaveStockItemSuccessCopyWith<$Res> implements $SaveStockItemStateCopyWith<$Res> {
  factory $SaveStockItemSuccessCopyWith(SaveStockItemSuccess value, $Res Function(SaveStockItemSuccess) _then) = _$SaveStockItemSuccessCopyWithImpl;
@useResult
$Res call({
 StockItem item
});


$StockItemCopyWith<$Res> get item;

}
/// @nodoc
class _$SaveStockItemSuccessCopyWithImpl<$Res>
    implements $SaveStockItemSuccessCopyWith<$Res> {
  _$SaveStockItemSuccessCopyWithImpl(this._self, this._then);

  final SaveStockItemSuccess _self;
  final $Res Function(SaveStockItemSuccess) _then;

/// Create a copy of SaveStockItemState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? item = null,}) {
  return _then(SaveStockItemSuccess(
null == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as StockItem,
  ));
}

/// Create a copy of SaveStockItemState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StockItemCopyWith<$Res> get item {
  
  return $StockItemCopyWith<$Res>(_self.item, (value) {
    return _then(_self.copyWith(item: value));
  });
}
}

/// @nodoc


class SaveStockItemChangingUnit implements SaveStockItemState {
  const SaveStockItemChangingUnit();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveStockItemChangingUnit);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SaveStockItemState.changingUnit()';
}


}




/// @nodoc


class SaveStockItemUnitChanged implements SaveStockItemState {
  const SaveStockItemUnitChanged(this.item);
  

 final  StockItem item;

/// Create a copy of SaveStockItemState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SaveStockItemUnitChangedCopyWith<SaveStockItemUnitChanged> get copyWith => _$SaveStockItemUnitChangedCopyWithImpl<SaveStockItemUnitChanged>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveStockItemUnitChanged&&(identical(other.item, item) || other.item == item));
}


@override
int get hashCode => Object.hash(runtimeType,item);

@override
String toString() {
  return 'SaveStockItemState.unitChanged(item: $item)';
}


}

/// @nodoc
abstract mixin class $SaveStockItemUnitChangedCopyWith<$Res> implements $SaveStockItemStateCopyWith<$Res> {
  factory $SaveStockItemUnitChangedCopyWith(SaveStockItemUnitChanged value, $Res Function(SaveStockItemUnitChanged) _then) = _$SaveStockItemUnitChangedCopyWithImpl;
@useResult
$Res call({
 StockItem item
});


$StockItemCopyWith<$Res> get item;

}
/// @nodoc
class _$SaveStockItemUnitChangedCopyWithImpl<$Res>
    implements $SaveStockItemUnitChangedCopyWith<$Res> {
  _$SaveStockItemUnitChangedCopyWithImpl(this._self, this._then);

  final SaveStockItemUnitChanged _self;
  final $Res Function(SaveStockItemUnitChanged) _then;

/// Create a copy of SaveStockItemState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? item = null,}) {
  return _then(SaveStockItemUnitChanged(
null == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as StockItem,
  ));
}

/// Create a copy of SaveStockItemState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StockItemCopyWith<$Res> get item {
  
  return $StockItemCopyWith<$Res>(_self.item, (value) {
    return _then(_self.copyWith(item: value));
  });
}
}

/// @nodoc


class SaveStockItemLinksRefused implements SaveStockItemState {
  const SaveStockItemLinksRefused(this.item, this.failure);
  

 final  StockItem item;
 final  Failure failure;

/// Create a copy of SaveStockItemState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SaveStockItemLinksRefusedCopyWith<SaveStockItemLinksRefused> get copyWith => _$SaveStockItemLinksRefusedCopyWithImpl<SaveStockItemLinksRefused>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveStockItemLinksRefused&&(identical(other.item, item) || other.item == item)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,item,failure);

@override
String toString() {
  return 'SaveStockItemState.linksRefused(item: $item, failure: $failure)';
}


}

/// @nodoc
abstract mixin class $SaveStockItemLinksRefusedCopyWith<$Res> implements $SaveStockItemStateCopyWith<$Res> {
  factory $SaveStockItemLinksRefusedCopyWith(SaveStockItemLinksRefused value, $Res Function(SaveStockItemLinksRefused) _then) = _$SaveStockItemLinksRefusedCopyWithImpl;
@useResult
$Res call({
 StockItem item, Failure failure
});


$StockItemCopyWith<$Res> get item;$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$SaveStockItemLinksRefusedCopyWithImpl<$Res>
    implements $SaveStockItemLinksRefusedCopyWith<$Res> {
  _$SaveStockItemLinksRefusedCopyWithImpl(this._self, this._then);

  final SaveStockItemLinksRefused _self;
  final $Res Function(SaveStockItemLinksRefused) _then;

/// Create a copy of SaveStockItemState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? item = null,Object? failure = null,}) {
  return _then(SaveStockItemLinksRefused(
null == item ? _self.item : item // ignore: cast_nullable_to_non_nullable
as StockItem,null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of SaveStockItemState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StockItemCopyWith<$Res> get item {
  
  return $StockItemCopyWith<$Res>(_self.item, (value) {
    return _then(_self.copyWith(item: value));
  });
}/// Create a copy of SaveStockItemState
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


class SaveStockItemFailure implements SaveStockItemState {
  const SaveStockItemFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of SaveStockItemState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SaveStockItemFailureCopyWith<SaveStockItemFailure> get copyWith => _$SaveStockItemFailureCopyWithImpl<SaveStockItemFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveStockItemFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'SaveStockItemState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $SaveStockItemFailureCopyWith<$Res> implements $SaveStockItemStateCopyWith<$Res> {
  factory $SaveStockItemFailureCopyWith(SaveStockItemFailure value, $Res Function(SaveStockItemFailure) _then) = _$SaveStockItemFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$SaveStockItemFailureCopyWithImpl<$Res>
    implements $SaveStockItemFailureCopyWith<$Res> {
  _$SaveStockItemFailureCopyWithImpl(this._self, this._then);

  final SaveStockItemFailure _self;
  final $Res Function(SaveStockItemFailure) _then;

/// Create a copy of SaveStockItemState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(SaveStockItemFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of SaveStockItemState
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
