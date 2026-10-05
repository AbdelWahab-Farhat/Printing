// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'period_expenses_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PeriodExpensesState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodExpensesState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PeriodExpensesState()';
}


}

/// @nodoc
class $PeriodExpensesStateCopyWith<$Res>  {
$PeriodExpensesStateCopyWith(PeriodExpensesState _, $Res Function(PeriodExpensesState) __);
}


/// Adds pattern-matching-related methods to [PeriodExpensesState].
extension PeriodExpensesStatePatterns on PeriodExpensesState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PeriodExpensesLoading value)?  loading,TResult Function( PeriodExpensesLoaded value)?  loaded,TResult Function( PeriodExpensesFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PeriodExpensesLoading() when loading != null:
return loading(_that);case PeriodExpensesLoaded() when loaded != null:
return loaded(_that);case PeriodExpensesFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PeriodExpensesLoading value)  loading,required TResult Function( PeriodExpensesLoaded value)  loaded,required TResult Function( PeriodExpensesFailure value)  failure,}){
final _that = this;
switch (_that) {
case PeriodExpensesLoading():
return loading(_that);case PeriodExpensesLoaded():
return loaded(_that);case PeriodExpensesFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PeriodExpensesLoading value)?  loading,TResult? Function( PeriodExpensesLoaded value)?  loaded,TResult? Function( PeriodExpensesFailure value)?  failure,}){
final _that = this;
switch (_that) {
case PeriodExpensesLoading() when loading != null:
return loading(_that);case PeriodExpensesLoaded() when loaded != null:
return loaded(_that);case PeriodExpensesFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( PeriodExpenses held)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PeriodExpensesLoading() when loading != null:
return loading();case PeriodExpensesLoaded() when loaded != null:
return loaded(_that.held);case PeriodExpensesFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( PeriodExpenses held)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case PeriodExpensesLoading():
return loading();case PeriodExpensesLoaded():
return loaded(_that.held);case PeriodExpensesFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( PeriodExpenses held)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case PeriodExpensesLoading() when loading != null:
return loading();case PeriodExpensesLoaded() when loaded != null:
return loaded(_that.held);case PeriodExpensesFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class PeriodExpensesLoading implements PeriodExpensesState {
  const PeriodExpensesLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodExpensesLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PeriodExpensesState.loading()';
}


}




/// @nodoc


class PeriodExpensesLoaded implements PeriodExpensesState {
  const PeriodExpensesLoaded(this.held);
  

 final  PeriodExpenses held;

/// Create a copy of PeriodExpensesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeriodExpensesLoadedCopyWith<PeriodExpensesLoaded> get copyWith => _$PeriodExpensesLoadedCopyWithImpl<PeriodExpensesLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodExpensesLoaded&&(identical(other.held, held) || other.held == held));
}


@override
int get hashCode => Object.hash(runtimeType,held);

@override
String toString() {
  return 'PeriodExpensesState.loaded(held: $held)';
}


}

/// @nodoc
abstract mixin class $PeriodExpensesLoadedCopyWith<$Res> implements $PeriodExpensesStateCopyWith<$Res> {
  factory $PeriodExpensesLoadedCopyWith(PeriodExpensesLoaded value, $Res Function(PeriodExpensesLoaded) _then) = _$PeriodExpensesLoadedCopyWithImpl;
@useResult
$Res call({
 PeriodExpenses held
});


$PeriodExpensesCopyWith<$Res> get held;

}
/// @nodoc
class _$PeriodExpensesLoadedCopyWithImpl<$Res>
    implements $PeriodExpensesLoadedCopyWith<$Res> {
  _$PeriodExpensesLoadedCopyWithImpl(this._self, this._then);

  final PeriodExpensesLoaded _self;
  final $Res Function(PeriodExpensesLoaded) _then;

/// Create a copy of PeriodExpensesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? held = null,}) {
  return _then(PeriodExpensesLoaded(
null == held ? _self.held : held // ignore: cast_nullable_to_non_nullable
as PeriodExpenses,
  ));
}

/// Create a copy of PeriodExpensesState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodExpensesCopyWith<$Res> get held {
  
  return $PeriodExpensesCopyWith<$Res>(_self.held, (value) {
    return _then(_self.copyWith(held: value));
  });
}
}

/// @nodoc


class PeriodExpensesFailure implements PeriodExpensesState {
  const PeriodExpensesFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of PeriodExpensesState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeriodExpensesFailureCopyWith<PeriodExpensesFailure> get copyWith => _$PeriodExpensesFailureCopyWithImpl<PeriodExpensesFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodExpensesFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'PeriodExpensesState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $PeriodExpensesFailureCopyWith<$Res> implements $PeriodExpensesStateCopyWith<$Res> {
  factory $PeriodExpensesFailureCopyWith(PeriodExpensesFailure value, $Res Function(PeriodExpensesFailure) _then) = _$PeriodExpensesFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$PeriodExpensesFailureCopyWithImpl<$Res>
    implements $PeriodExpensesFailureCopyWith<$Res> {
  _$PeriodExpensesFailureCopyWithImpl(this._self, this._then);

  final PeriodExpensesFailure _self;
  final $Res Function(PeriodExpensesFailure) _then;

/// Create a copy of PeriodExpensesState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(PeriodExpensesFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of PeriodExpensesState
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
