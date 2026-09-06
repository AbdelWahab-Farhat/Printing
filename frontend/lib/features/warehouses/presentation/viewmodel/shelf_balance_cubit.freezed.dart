// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shelf_balance_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ShelfBalanceState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShelfBalanceState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ShelfBalanceState()';
}


}

/// @nodoc
class $ShelfBalanceStateCopyWith<$Res>  {
$ShelfBalanceStateCopyWith(ShelfBalanceState _, $Res Function(ShelfBalanceState) __);
}


/// Adds pattern-matching-related methods to [ShelfBalanceState].
extension ShelfBalanceStatePatterns on ShelfBalanceState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ShelfBalanceInitial value)?  initial,TResult Function( ShelfBalanceLoading value)?  loading,TResult Function( ShelfBalanceLoaded value)?  loaded,TResult Function( ShelfBalanceFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ShelfBalanceInitial() when initial != null:
return initial(_that);case ShelfBalanceLoading() when loading != null:
return loading(_that);case ShelfBalanceLoaded() when loaded != null:
return loaded(_that);case ShelfBalanceFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ShelfBalanceInitial value)  initial,required TResult Function( ShelfBalanceLoading value)  loading,required TResult Function( ShelfBalanceLoaded value)  loaded,required TResult Function( ShelfBalanceFailure value)  failure,}){
final _that = this;
switch (_that) {
case ShelfBalanceInitial():
return initial(_that);case ShelfBalanceLoading():
return loading(_that);case ShelfBalanceLoaded():
return loaded(_that);case ShelfBalanceFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ShelfBalanceInitial value)?  initial,TResult? Function( ShelfBalanceLoading value)?  loading,TResult? Function( ShelfBalanceLoaded value)?  loaded,TResult? Function( ShelfBalanceFailure value)?  failure,}){
final _that = this;
switch (_that) {
case ShelfBalanceInitial() when initial != null:
return initial(_that);case ShelfBalanceLoading() when loading != null:
return loading(_that);case ShelfBalanceLoaded() when loaded != null:
return loaded(_that);case ShelfBalanceFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( WarehouseStock? stock)?  loaded,TResult Function()?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ShelfBalanceInitial() when initial != null:
return initial();case ShelfBalanceLoading() when loading != null:
return loading();case ShelfBalanceLoaded() when loaded != null:
return loaded(_that.stock);case ShelfBalanceFailure() when failure != null:
return failure();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( WarehouseStock? stock)  loaded,required TResult Function()  failure,}) {final _that = this;
switch (_that) {
case ShelfBalanceInitial():
return initial();case ShelfBalanceLoading():
return loading();case ShelfBalanceLoaded():
return loaded(_that.stock);case ShelfBalanceFailure():
return failure();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( WarehouseStock? stock)?  loaded,TResult? Function()?  failure,}) {final _that = this;
switch (_that) {
case ShelfBalanceInitial() when initial != null:
return initial();case ShelfBalanceLoading() when loading != null:
return loading();case ShelfBalanceLoaded() when loaded != null:
return loaded(_that.stock);case ShelfBalanceFailure() when failure != null:
return failure();case _:
  return null;

}
}

}

/// @nodoc


class ShelfBalanceInitial implements ShelfBalanceState {
  const ShelfBalanceInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShelfBalanceInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ShelfBalanceState.initial()';
}


}




/// @nodoc


class ShelfBalanceLoading implements ShelfBalanceState {
  const ShelfBalanceLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShelfBalanceLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ShelfBalanceState.loading()';
}


}




/// @nodoc


class ShelfBalanceLoaded implements ShelfBalanceState {
  const ShelfBalanceLoaded(this.stock);
  

 final  WarehouseStock? stock;

/// Create a copy of ShelfBalanceState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShelfBalanceLoadedCopyWith<ShelfBalanceLoaded> get copyWith => _$ShelfBalanceLoadedCopyWithImpl<ShelfBalanceLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShelfBalanceLoaded&&(identical(other.stock, stock) || other.stock == stock));
}


@override
int get hashCode => Object.hash(runtimeType,stock);

@override
String toString() {
  return 'ShelfBalanceState.loaded(stock: $stock)';
}


}

/// @nodoc
abstract mixin class $ShelfBalanceLoadedCopyWith<$Res> implements $ShelfBalanceStateCopyWith<$Res> {
  factory $ShelfBalanceLoadedCopyWith(ShelfBalanceLoaded value, $Res Function(ShelfBalanceLoaded) _then) = _$ShelfBalanceLoadedCopyWithImpl;
@useResult
$Res call({
 WarehouseStock? stock
});


$WarehouseStockCopyWith<$Res>? get stock;

}
/// @nodoc
class _$ShelfBalanceLoadedCopyWithImpl<$Res>
    implements $ShelfBalanceLoadedCopyWith<$Res> {
  _$ShelfBalanceLoadedCopyWithImpl(this._self, this._then);

  final ShelfBalanceLoaded _self;
  final $Res Function(ShelfBalanceLoaded) _then;

/// Create a copy of ShelfBalanceState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? stock = freezed,}) {
  return _then(ShelfBalanceLoaded(
freezed == stock ? _self.stock : stock // ignore: cast_nullable_to_non_nullable
as WarehouseStock?,
  ));
}

/// Create a copy of ShelfBalanceState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WarehouseStockCopyWith<$Res>? get stock {
    if (_self.stock == null) {
    return null;
  }

  return $WarehouseStockCopyWith<$Res>(_self.stock!, (value) {
    return _then(_self.copyWith(stock: value));
  });
}
}

/// @nodoc


class ShelfBalanceFailure implements ShelfBalanceState {
  const ShelfBalanceFailure();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShelfBalanceFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ShelfBalanceState.failure()';
}


}




// dart format on
