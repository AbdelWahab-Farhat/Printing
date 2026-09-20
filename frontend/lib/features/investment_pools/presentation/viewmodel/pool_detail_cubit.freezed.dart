// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pool_detail_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PoolDetailState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PoolDetailState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PoolDetailState()';
}


}

/// @nodoc
class $PoolDetailStateCopyWith<$Res>  {
$PoolDetailStateCopyWith(PoolDetailState _, $Res Function(PoolDetailState) __);
}


/// Adds pattern-matching-related methods to [PoolDetailState].
extension PoolDetailStatePatterns on PoolDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PoolDetailLoading value)?  loading,TResult Function( PoolDetailLoaded value)?  loaded,TResult Function( PoolDetailFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PoolDetailLoading() when loading != null:
return loading(_that);case PoolDetailLoaded() when loaded != null:
return loaded(_that);case PoolDetailFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PoolDetailLoading value)  loading,required TResult Function( PoolDetailLoaded value)  loaded,required TResult Function( PoolDetailFailure value)  failure,}){
final _that = this;
switch (_that) {
case PoolDetailLoading():
return loading(_that);case PoolDetailLoaded():
return loaded(_that);case PoolDetailFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PoolDetailLoading value)?  loading,TResult? Function( PoolDetailLoaded value)?  loaded,TResult? Function( PoolDetailFailure value)?  failure,}){
final _that = this;
switch (_that) {
case PoolDetailLoading() when loading != null:
return loading(_that);case PoolDetailLoaded() when loaded != null:
return loaded(_that);case PoolDetailFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( InvestmentPool pool,  PoolDeployableCash? cash,  List<ReturnedGoodsQuestion> openQuestions,  List<CapitalRequest> capitalRequests,  List<PoolExpense> expenses)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PoolDetailLoading() when loading != null:
return loading();case PoolDetailLoaded() when loaded != null:
return loaded(_that.pool,_that.cash,_that.openQuestions,_that.capitalRequests,_that.expenses);case PoolDetailFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( InvestmentPool pool,  PoolDeployableCash? cash,  List<ReturnedGoodsQuestion> openQuestions,  List<CapitalRequest> capitalRequests,  List<PoolExpense> expenses)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case PoolDetailLoading():
return loading();case PoolDetailLoaded():
return loaded(_that.pool,_that.cash,_that.openQuestions,_that.capitalRequests,_that.expenses);case PoolDetailFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( InvestmentPool pool,  PoolDeployableCash? cash,  List<ReturnedGoodsQuestion> openQuestions,  List<CapitalRequest> capitalRequests,  List<PoolExpense> expenses)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case PoolDetailLoading() when loading != null:
return loading();case PoolDetailLoaded() when loaded != null:
return loaded(_that.pool,_that.cash,_that.openQuestions,_that.capitalRequests,_that.expenses);case PoolDetailFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class PoolDetailLoading implements PoolDetailState {
  const PoolDetailLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PoolDetailLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PoolDetailState.loading()';
}


}




/// @nodoc


class PoolDetailLoaded implements PoolDetailState {
  const PoolDetailLoaded({required this.pool, this.cash, final  List<ReturnedGoodsQuestion> openQuestions = const <ReturnedGoodsQuestion>[], final  List<CapitalRequest> capitalRequests = const <CapitalRequest>[], final  List<PoolExpense> expenses = const <PoolExpense>[]}): _openQuestions = openQuestions,_capitalRequests = capitalRequests,_expenses = expenses;
  

 final  InvestmentPool pool;
/// Null when the figure could not be read — the screen shows the pool without it rather
/// than showing nothing.
 final  PoolDeployableCash? cash;
/// **Open ones only.** These are the work, and they are what the close is waiting for.
 final  List<ReturnedGoodsQuestion> _openQuestions;
/// **Open ones only.** These are the work, and they are what the close is waiting for.
@JsonKey() List<ReturnedGoodsQuestion> get openQuestions {
  if (_openQuestions is EqualUnmodifiableListView) return _openQuestions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_openQuestions);
}

 final  List<CapitalRequest> _capitalRequests;
@JsonKey() List<CapitalRequest> get capitalRequests {
  if (_capitalRequests is EqualUnmodifiableListView) return _capitalRequests;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_capitalRequests);
}

/// What has been charged to the pool, newest first.
 final  List<PoolExpense> _expenses;
/// What has been charged to the pool, newest first.
@JsonKey() List<PoolExpense> get expenses {
  if (_expenses is EqualUnmodifiableListView) return _expenses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_expenses);
}


/// Create a copy of PoolDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PoolDetailLoadedCopyWith<PoolDetailLoaded> get copyWith => _$PoolDetailLoadedCopyWithImpl<PoolDetailLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PoolDetailLoaded&&(identical(other.pool, pool) || other.pool == pool)&&(identical(other.cash, cash) || other.cash == cash)&&const DeepCollectionEquality().equals(other._openQuestions, _openQuestions)&&const DeepCollectionEquality().equals(other._capitalRequests, _capitalRequests)&&const DeepCollectionEquality().equals(other._expenses, _expenses));
}


@override
int get hashCode => Object.hash(runtimeType,pool,cash,const DeepCollectionEquality().hash(_openQuestions),const DeepCollectionEquality().hash(_capitalRequests),const DeepCollectionEquality().hash(_expenses));

@override
String toString() {
  return 'PoolDetailState.loaded(pool: $pool, cash: $cash, openQuestions: $openQuestions, capitalRequests: $capitalRequests, expenses: $expenses)';
}


}

/// @nodoc
abstract mixin class $PoolDetailLoadedCopyWith<$Res> implements $PoolDetailStateCopyWith<$Res> {
  factory $PoolDetailLoadedCopyWith(PoolDetailLoaded value, $Res Function(PoolDetailLoaded) _then) = _$PoolDetailLoadedCopyWithImpl;
@useResult
$Res call({
 InvestmentPool pool, PoolDeployableCash? cash, List<ReturnedGoodsQuestion> openQuestions, List<CapitalRequest> capitalRequests, List<PoolExpense> expenses
});


$InvestmentPoolCopyWith<$Res> get pool;$PoolDeployableCashCopyWith<$Res>? get cash;

}
/// @nodoc
class _$PoolDetailLoadedCopyWithImpl<$Res>
    implements $PoolDetailLoadedCopyWith<$Res> {
  _$PoolDetailLoadedCopyWithImpl(this._self, this._then);

  final PoolDetailLoaded _self;
  final $Res Function(PoolDetailLoaded) _then;

/// Create a copy of PoolDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? pool = null,Object? cash = freezed,Object? openQuestions = null,Object? capitalRequests = null,Object? expenses = null,}) {
  return _then(PoolDetailLoaded(
pool: null == pool ? _self.pool : pool // ignore: cast_nullable_to_non_nullable
as InvestmentPool,cash: freezed == cash ? _self.cash : cash // ignore: cast_nullable_to_non_nullable
as PoolDeployableCash?,openQuestions: null == openQuestions ? _self._openQuestions : openQuestions // ignore: cast_nullable_to_non_nullable
as List<ReturnedGoodsQuestion>,capitalRequests: null == capitalRequests ? _self._capitalRequests : capitalRequests // ignore: cast_nullable_to_non_nullable
as List<CapitalRequest>,expenses: null == expenses ? _self._expenses : expenses // ignore: cast_nullable_to_non_nullable
as List<PoolExpense>,
  ));
}

/// Create a copy of PoolDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InvestmentPoolCopyWith<$Res> get pool {
  
  return $InvestmentPoolCopyWith<$Res>(_self.pool, (value) {
    return _then(_self.copyWith(pool: value));
  });
}/// Create a copy of PoolDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PoolDeployableCashCopyWith<$Res>? get cash {
    if (_self.cash == null) {
    return null;
  }

  return $PoolDeployableCashCopyWith<$Res>(_self.cash!, (value) {
    return _then(_self.copyWith(cash: value));
  });
}
}

/// @nodoc


class PoolDetailFailure implements PoolDetailState {
  const PoolDetailFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of PoolDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PoolDetailFailureCopyWith<PoolDetailFailure> get copyWith => _$PoolDetailFailureCopyWithImpl<PoolDetailFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PoolDetailFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'PoolDetailState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $PoolDetailFailureCopyWith<$Res> implements $PoolDetailStateCopyWith<$Res> {
  factory $PoolDetailFailureCopyWith(PoolDetailFailure value, $Res Function(PoolDetailFailure) _then) = _$PoolDetailFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$PoolDetailFailureCopyWithImpl<$Res>
    implements $PoolDetailFailureCopyWith<$Res> {
  _$PoolDetailFailureCopyWithImpl(this._self, this._then);

  final PoolDetailFailure _self;
  final $Res Function(PoolDetailFailure) _then;

/// Create a copy of PoolDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(PoolDetailFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of PoolDetailState
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
