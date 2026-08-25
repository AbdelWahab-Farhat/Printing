// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stock_item_links_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$StockItemLinksState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StockItemLinksState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StockItemLinksState()';
}


}

/// @nodoc
class $StockItemLinksStateCopyWith<$Res>  {
$StockItemLinksStateCopyWith(StockItemLinksState _, $Res Function(StockItemLinksState) __);
}


/// Adds pattern-matching-related methods to [StockItemLinksState].
extension StockItemLinksStatePatterns on StockItemLinksState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( StockItemLinksInitial value)?  initial,TResult Function( StockItemLinksLoading value)?  loading,TResult Function( StockItemLinksLoaded value)?  loaded,TResult Function( StockItemLinksFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case StockItemLinksInitial() when initial != null:
return initial(_that);case StockItemLinksLoading() when loading != null:
return loading(_that);case StockItemLinksLoaded() when loaded != null:
return loaded(_that);case StockItemLinksFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( StockItemLinksInitial value)  initial,required TResult Function( StockItemLinksLoading value)  loading,required TResult Function( StockItemLinksLoaded value)  loaded,required TResult Function( StockItemLinksFailure value)  failure,}){
final _that = this;
switch (_that) {
case StockItemLinksInitial():
return initial(_that);case StockItemLinksLoading():
return loading(_that);case StockItemLinksLoaded():
return loaded(_that);case StockItemLinksFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( StockItemLinksInitial value)?  initial,TResult? Function( StockItemLinksLoading value)?  loading,TResult? Function( StockItemLinksLoaded value)?  loaded,TResult? Function( StockItemLinksFailure value)?  failure,}){
final _that = this;
switch (_that) {
case StockItemLinksInitial() when initial != null:
return initial(_that);case StockItemLinksLoading() when loading != null:
return loading(_that);case StockItemLinksLoaded() when loaded != null:
return loaded(_that);case StockItemLinksFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( List<StockItemVariantRef> variants,  Set<int>? selected)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case StockItemLinksInitial() when initial != null:
return initial();case StockItemLinksLoading() when loading != null:
return loading();case StockItemLinksLoaded() when loaded != null:
return loaded(_that.variants,_that.selected);case StockItemLinksFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( List<StockItemVariantRef> variants,  Set<int>? selected)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case StockItemLinksInitial():
return initial();case StockItemLinksLoading():
return loading();case StockItemLinksLoaded():
return loaded(_that.variants,_that.selected);case StockItemLinksFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( List<StockItemVariantRef> variants,  Set<int>? selected)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case StockItemLinksInitial() when initial != null:
return initial();case StockItemLinksLoading() when loading != null:
return loading();case StockItemLinksLoaded() when loaded != null:
return loaded(_that.variants,_that.selected);case StockItemLinksFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class StockItemLinksInitial implements StockItemLinksState {
  const StockItemLinksInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StockItemLinksInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StockItemLinksState.initial()';
}


}




/// @nodoc


class StockItemLinksLoading implements StockItemLinksState {
  const StockItemLinksLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StockItemLinksLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'StockItemLinksState.loading()';
}


}




/// @nodoc


class StockItemLinksLoaded implements StockItemLinksState {
  const StockItemLinksLoaded(final  List<StockItemVariantRef> variants, {final  Set<int>? selected}): _variants = variants,_selected = selected;
  

 final  List<StockItemVariantRef> _variants;
 List<StockItemVariantRef> get variants {
  if (_variants is EqualUnmodifiableListView) return _variants;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_variants);
}

 final  Set<int>? _selected;
 Set<int>? get selected {
  final value = _selected;
  if (value == null) return null;
  if (_selected is EqualUnmodifiableSetView) return _selected;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(value);
}


/// Create a copy of StockItemLinksState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StockItemLinksLoadedCopyWith<StockItemLinksLoaded> get copyWith => _$StockItemLinksLoadedCopyWithImpl<StockItemLinksLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StockItemLinksLoaded&&const DeepCollectionEquality().equals(other._variants, _variants)&&const DeepCollectionEquality().equals(other._selected, _selected));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_variants),const DeepCollectionEquality().hash(_selected));

@override
String toString() {
  return 'StockItemLinksState.loaded(variants: $variants, selected: $selected)';
}


}

/// @nodoc
abstract mixin class $StockItemLinksLoadedCopyWith<$Res> implements $StockItemLinksStateCopyWith<$Res> {
  factory $StockItemLinksLoadedCopyWith(StockItemLinksLoaded value, $Res Function(StockItemLinksLoaded) _then) = _$StockItemLinksLoadedCopyWithImpl;
@useResult
$Res call({
 List<StockItemVariantRef> variants, Set<int>? selected
});




}
/// @nodoc
class _$StockItemLinksLoadedCopyWithImpl<$Res>
    implements $StockItemLinksLoadedCopyWith<$Res> {
  _$StockItemLinksLoadedCopyWithImpl(this._self, this._then);

  final StockItemLinksLoaded _self;
  final $Res Function(StockItemLinksLoaded) _then;

/// Create a copy of StockItemLinksState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? variants = null,Object? selected = freezed,}) {
  return _then(StockItemLinksLoaded(
null == variants ? _self._variants : variants // ignore: cast_nullable_to_non_nullable
as List<StockItemVariantRef>,selected: freezed == selected ? _self._selected : selected // ignore: cast_nullable_to_non_nullable
as Set<int>?,
  ));
}


}

/// @nodoc


class StockItemLinksFailure implements StockItemLinksState {
  const StockItemLinksFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of StockItemLinksState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StockItemLinksFailureCopyWith<StockItemLinksFailure> get copyWith => _$StockItemLinksFailureCopyWithImpl<StockItemLinksFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StockItemLinksFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'StockItemLinksState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $StockItemLinksFailureCopyWith<$Res> implements $StockItemLinksStateCopyWith<$Res> {
  factory $StockItemLinksFailureCopyWith(StockItemLinksFailure value, $Res Function(StockItemLinksFailure) _then) = _$StockItemLinksFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$StockItemLinksFailureCopyWithImpl<$Res>
    implements $StockItemLinksFailureCopyWith<$Res> {
  _$StockItemLinksFailureCopyWithImpl(this._self, this._then);

  final StockItemLinksFailure _self;
  final $Res Function(StockItemLinksFailure) _then;

/// Create a copy of StockItemLinksState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(StockItemLinksFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of StockItemLinksState
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
