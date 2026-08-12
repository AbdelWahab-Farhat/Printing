// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stock_summary_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StockSummaryState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StockSummaryState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StockSummaryState()';
}


}

/// @nodoc
class $StockSummaryStateCopyWith<$Res>  {
$StockSummaryStateCopyWith(StockSummaryState _, $Res Function(StockSummaryState) __);
}


/// Adds pattern-matching-related methods to [StockSummaryState].
extension StockSummaryStatePatterns on StockSummaryState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( StockSummaryInitial value)?  initial,TResult Function( StockSummaryLoading value)?  loading,TResult Function( StockSummaryLoaded value)?  loaded,TResult Function( StockSummaryFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case StockSummaryInitial() when initial != null:
return initial(_that);case StockSummaryLoading() when loading != null:
return loading(_that);case StockSummaryLoaded() when loaded != null:
return loaded(_that);case StockSummaryFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( StockSummaryInitial value)  initial,required TResult Function( StockSummaryLoading value)  loading,required TResult Function( StockSummaryLoaded value)  loaded,required TResult Function( StockSummaryFailure value)  failure,}){
final _that = this;
switch (_that) {
case StockSummaryInitial():
return initial(_that);case StockSummaryLoading():
return loading(_that);case StockSummaryLoaded():
return loaded(_that);case StockSummaryFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( StockSummaryInitial value)?  initial,TResult? Function( StockSummaryLoading value)?  loading,TResult? Function( StockSummaryLoaded value)?  loaded,TResult? Function( StockSummaryFailure value)?  failure,}){
final _that = this;
switch (_that) {
case StockSummaryInitial() when initial != null:
return initial(_that);case StockSummaryLoading() when loading != null:
return loading(_that);case StockSummaryLoaded() when loaded != null:
return loaded(_that);case StockSummaryFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( WarehouseStockSummary summary)?  loaded,TResult Function()?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case StockSummaryInitial() when initial != null:
return initial();case StockSummaryLoading() when loading != null:
return loading();case StockSummaryLoaded() when loaded != null:
return loaded(_that.summary);case StockSummaryFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( WarehouseStockSummary summary)  loaded,required TResult Function()  failure,}) {final _that = this;
switch (_that) {
case StockSummaryInitial():
return initial();case StockSummaryLoading():
return loading();case StockSummaryLoaded():
return loaded(_that.summary);case StockSummaryFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( WarehouseStockSummary summary)?  loaded,TResult? Function()?  failure,}) {final _that = this;
switch (_that) {
case StockSummaryInitial() when initial != null:
return initial();case StockSummaryLoading() when loading != null:
return loading();case StockSummaryLoaded() when loaded != null:
return loaded(_that.summary);case StockSummaryFailure() when failure != null:
return failure();case _:
  return null;

}
}

}

/// @nodoc


class StockSummaryInitial implements StockSummaryState {
  const StockSummaryInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StockSummaryInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StockSummaryState.initial()';
}


}




/// @nodoc


class StockSummaryLoading implements StockSummaryState {
  const StockSummaryLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StockSummaryLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StockSummaryState.loading()';
}


}




/// @nodoc


class StockSummaryLoaded implements StockSummaryState {
  const StockSummaryLoaded(this.summary);
  

 final  WarehouseStockSummary summary;

/// Create a copy of StockSummaryState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StockSummaryLoadedCopyWith<StockSummaryLoaded> get copyWith => _$StockSummaryLoadedCopyWithImpl<StockSummaryLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StockSummaryLoaded&&(identical(other.summary, summary) || other.summary == summary));
}


@override
int get hashCode => Object.hash(runtimeType,summary);

@override
String toString() {
  return 'StockSummaryState.loaded(summary: $summary)';
}


}

/// @nodoc
abstract mixin class $StockSummaryLoadedCopyWith<$Res> implements $StockSummaryStateCopyWith<$Res> {
  factory $StockSummaryLoadedCopyWith(StockSummaryLoaded value, $Res Function(StockSummaryLoaded) _then) = _$StockSummaryLoadedCopyWithImpl;
@useResult
$Res call({
 WarehouseStockSummary summary
});


$WarehouseStockSummaryCopyWith<$Res> get summary;

}
/// @nodoc
class _$StockSummaryLoadedCopyWithImpl<$Res>
    implements $StockSummaryLoadedCopyWith<$Res> {
  _$StockSummaryLoadedCopyWithImpl(this._self, this._then);

  final StockSummaryLoaded _self;
  final $Res Function(StockSummaryLoaded) _then;

/// Create a copy of StockSummaryState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? summary = null,}) {
  return _then(StockSummaryLoaded(
null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as WarehouseStockSummary,
  ));
}

/// Create a copy of StockSummaryState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WarehouseStockSummaryCopyWith<$Res> get summary {
  
  return $WarehouseStockSummaryCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}

/// @nodoc


class StockSummaryFailure implements StockSummaryState {
  const StockSummaryFailure();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StockSummaryFailure);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StockSummaryState.failure()';
}


}




// dart format on
