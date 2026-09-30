// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_notes_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OrderNotesState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderNotesState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OrderNotesState()';
}


}

/// @nodoc
class $OrderNotesStateCopyWith<$Res>  {
$OrderNotesStateCopyWith(OrderNotesState _, $Res Function(OrderNotesState) __);
}


/// Adds pattern-matching-related methods to [OrderNotesState].
extension OrderNotesStatePatterns on OrderNotesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( OrderNotesLoading value)?  loading,TResult Function( OrderNotesLoaded value)?  loaded,TResult Function( OrderNotesFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case OrderNotesLoading() when loading != null:
return loading(_that);case OrderNotesLoaded() when loaded != null:
return loaded(_that);case OrderNotesFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( OrderNotesLoading value)  loading,required TResult Function( OrderNotesLoaded value)  loaded,required TResult Function( OrderNotesFailure value)  failure,}){
final _that = this;
switch (_that) {
case OrderNotesLoading():
return loading(_that);case OrderNotesLoaded():
return loaded(_that);case OrderNotesFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( OrderNotesLoading value)?  loading,TResult? Function( OrderNotesLoaded value)?  loaded,TResult? Function( OrderNotesFailure value)?  failure,}){
final _that = this;
switch (_that) {
case OrderNotesLoading() when loading != null:
return loading(_that);case OrderNotesLoaded() when loaded != null:
return loaded(_that);case OrderNotesFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( List<OrderNote> notes)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case OrderNotesLoading() when loading != null:
return loading();case OrderNotesLoaded() when loaded != null:
return loaded(_that.notes);case OrderNotesFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( List<OrderNote> notes)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case OrderNotesLoading():
return loading();case OrderNotesLoaded():
return loaded(_that.notes);case OrderNotesFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( List<OrderNote> notes)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case OrderNotesLoading() when loading != null:
return loading();case OrderNotesLoaded() when loaded != null:
return loaded(_that.notes);case OrderNotesFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class OrderNotesLoading implements OrderNotesState {
  const OrderNotesLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderNotesLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'OrderNotesState.loading()';
}


}




/// @nodoc


class OrderNotesLoaded implements OrderNotesState {
  const OrderNotesLoaded(final  List<OrderNote> notes): _notes = notes;
  

 final  List<OrderNote> _notes;
 List<OrderNote> get notes {
  if (_notes is EqualUnmodifiableListView) return _notes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_notes);
}


/// Create a copy of OrderNotesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderNotesLoadedCopyWith<OrderNotesLoaded> get copyWith => _$OrderNotesLoadedCopyWithImpl<OrderNotesLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderNotesLoaded&&const DeepCollectionEquality().equals(other._notes, _notes));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_notes));

@override
String toString() {
  return 'OrderNotesState.loaded(notes: $notes)';
}


}

/// @nodoc
abstract mixin class $OrderNotesLoadedCopyWith<$Res> implements $OrderNotesStateCopyWith<$Res> {
  factory $OrderNotesLoadedCopyWith(OrderNotesLoaded value, $Res Function(OrderNotesLoaded) _then) = _$OrderNotesLoadedCopyWithImpl;
@useResult
$Res call({
 List<OrderNote> notes
});




}
/// @nodoc
class _$OrderNotesLoadedCopyWithImpl<$Res>
    implements $OrderNotesLoadedCopyWith<$Res> {
  _$OrderNotesLoadedCopyWithImpl(this._self, this._then);

  final OrderNotesLoaded _self;
  final $Res Function(OrderNotesLoaded) _then;

/// Create a copy of OrderNotesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? notes = null,}) {
  return _then(OrderNotesLoaded(
null == notes ? _self._notes : notes // ignore: cast_nullable_to_non_nullable
as List<OrderNote>,
  ));
}


}

/// @nodoc


class OrderNotesFailure implements OrderNotesState {
  const OrderNotesFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of OrderNotesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderNotesFailureCopyWith<OrderNotesFailure> get copyWith => _$OrderNotesFailureCopyWithImpl<OrderNotesFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderNotesFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'OrderNotesState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $OrderNotesFailureCopyWith<$Res> implements $OrderNotesStateCopyWith<$Res> {
  factory $OrderNotesFailureCopyWith(OrderNotesFailure value, $Res Function(OrderNotesFailure) _then) = _$OrderNotesFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$OrderNotesFailureCopyWithImpl<$Res>
    implements $OrderNotesFailureCopyWith<$Res> {
  _$OrderNotesFailureCopyWithImpl(this._self, this._then);

  final OrderNotesFailure _self;
  final $Res Function(OrderNotesFailure) _then;

/// Create a copy of OrderNotesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(OrderNotesFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of OrderNotesState
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
