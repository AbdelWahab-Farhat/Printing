// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'investor_portal_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InvestorPortalState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestorPortalState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'InvestorPortalState()';
}


}

/// @nodoc
class $InvestorPortalStateCopyWith<$Res>  {
$InvestorPortalStateCopyWith(InvestorPortalState _, $Res Function(InvestorPortalState) __);
}


/// Adds pattern-matching-related methods to [InvestorPortalState].
extension InvestorPortalStatePatterns on InvestorPortalState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( InvestorPortalInitial value)?  initial,TResult Function( InvestorPortalLoading value)?  loading,TResult Function( InvestorPortalLoaded value)?  loaded,TResult Function( InvestorPortalFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case InvestorPortalInitial() when initial != null:
return initial(_that);case InvestorPortalLoading() when loading != null:
return loading(_that);case InvestorPortalLoaded() when loaded != null:
return loaded(_that);case InvestorPortalFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( InvestorPortalInitial value)  initial,required TResult Function( InvestorPortalLoading value)  loading,required TResult Function( InvestorPortalLoaded value)  loaded,required TResult Function( InvestorPortalFailure value)  failure,}){
final _that = this;
switch (_that) {
case InvestorPortalInitial():
return initial(_that);case InvestorPortalLoading():
return loading(_that);case InvestorPortalLoaded():
return loaded(_that);case InvestorPortalFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( InvestorPortalInitial value)?  initial,TResult? Function( InvestorPortalLoading value)?  loading,TResult? Function( InvestorPortalLoaded value)?  loaded,TResult? Function( InvestorPortalFailure value)?  failure,}){
final _that = this;
switch (_that) {
case InvestorPortalInitial() when initial != null:
return initial(_that);case InvestorPortalLoading() when loading != null:
return loading(_that);case InvestorPortalLoaded() when loaded != null:
return loaded(_that);case InvestorPortalFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function()?  loading,TResult Function( InvestorPortfolio portfolio,  bool isRefreshing)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case InvestorPortalInitial() when initial != null:
return initial();case InvestorPortalLoading() when loading != null:
return loading();case InvestorPortalLoaded() when loaded != null:
return loaded(_that.portfolio,_that.isRefreshing);case InvestorPortalFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function()  loading,required TResult Function( InvestorPortfolio portfolio,  bool isRefreshing)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case InvestorPortalInitial():
return initial();case InvestorPortalLoading():
return loading();case InvestorPortalLoaded():
return loaded(_that.portfolio,_that.isRefreshing);case InvestorPortalFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function()?  loading,TResult? Function( InvestorPortfolio portfolio,  bool isRefreshing)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case InvestorPortalInitial() when initial != null:
return initial();case InvestorPortalLoading() when loading != null:
return loading();case InvestorPortalLoaded() when loaded != null:
return loaded(_that.portfolio,_that.isRefreshing);case InvestorPortalFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class InvestorPortalInitial implements InvestorPortalState {
  const InvestorPortalInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestorPortalInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'InvestorPortalState.initial()';
}


}




/// @nodoc


class InvestorPortalLoading implements InvestorPortalState {
  const InvestorPortalLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestorPortalLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'InvestorPortalState.loading()';
}


}




/// @nodoc


class InvestorPortalLoaded implements InvestorPortalState {
  const InvestorPortalLoaded({required this.portfolio, this.isRefreshing = false});
  

 final  InvestorPortfolio portfolio;
/// A refresh running over figures already on screen — part of `loaded` precisely because the
/// screen keeps rendering throughout.
@JsonKey() final  bool isRefreshing;

/// Create a copy of InvestorPortalState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvestorPortalLoadedCopyWith<InvestorPortalLoaded> get copyWith => _$InvestorPortalLoadedCopyWithImpl<InvestorPortalLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestorPortalLoaded&&(identical(other.portfolio, portfolio) || other.portfolio == portfolio)&&(identical(other.isRefreshing, isRefreshing) || other.isRefreshing == isRefreshing));
}


@override
int get hashCode => Object.hash(runtimeType,portfolio,isRefreshing);

@override
String toString() {
  return 'InvestorPortalState.loaded(portfolio: $portfolio, isRefreshing: $isRefreshing)';
}


}

/// @nodoc
abstract mixin class $InvestorPortalLoadedCopyWith<$Res> implements $InvestorPortalStateCopyWith<$Res> {
  factory $InvestorPortalLoadedCopyWith(InvestorPortalLoaded value, $Res Function(InvestorPortalLoaded) _then) = _$InvestorPortalLoadedCopyWithImpl;
@useResult
$Res call({
 InvestorPortfolio portfolio, bool isRefreshing
});


$InvestorPortfolioCopyWith<$Res> get portfolio;

}
/// @nodoc
class _$InvestorPortalLoadedCopyWithImpl<$Res>
    implements $InvestorPortalLoadedCopyWith<$Res> {
  _$InvestorPortalLoadedCopyWithImpl(this._self, this._then);

  final InvestorPortalLoaded _self;
  final $Res Function(InvestorPortalLoaded) _then;

/// Create a copy of InvestorPortalState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? portfolio = null,Object? isRefreshing = null,}) {
  return _then(InvestorPortalLoaded(
portfolio: null == portfolio ? _self.portfolio : portfolio // ignore: cast_nullable_to_non_nullable
as InvestorPortfolio,isRefreshing: null == isRefreshing ? _self.isRefreshing : isRefreshing // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of InvestorPortalState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InvestorPortfolioCopyWith<$Res> get portfolio {
  
  return $InvestorPortfolioCopyWith<$Res>(_self.portfolio, (value) {
    return _then(_self.copyWith(portfolio: value));
  });
}
}

/// @nodoc


class InvestorPortalFailure implements InvestorPortalState {
  const InvestorPortalFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of InvestorPortalState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvestorPortalFailureCopyWith<InvestorPortalFailure> get copyWith => _$InvestorPortalFailureCopyWithImpl<InvestorPortalFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestorPortalFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'InvestorPortalState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $InvestorPortalFailureCopyWith<$Res> implements $InvestorPortalStateCopyWith<$Res> {
  factory $InvestorPortalFailureCopyWith(InvestorPortalFailure value, $Res Function(InvestorPortalFailure) _then) = _$InvestorPortalFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$InvestorPortalFailureCopyWithImpl<$Res>
    implements $InvestorPortalFailureCopyWith<$Res> {
  _$InvestorPortalFailureCopyWithImpl(this._self, this._then);

  final InvestorPortalFailure _self;
  final $Res Function(InvestorPortalFailure) _then;

/// Create a copy of InvestorPortalState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(InvestorPortalFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of InvestorPortalState
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
