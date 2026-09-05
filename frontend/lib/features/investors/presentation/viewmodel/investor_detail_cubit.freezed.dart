// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'investor_detail_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$InvestorDetailState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestorDetailState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'InvestorDetailState()';
}


}

/// @nodoc
class $InvestorDetailStateCopyWith<$Res>  {
$InvestorDetailStateCopyWith(InvestorDetailState _, $Res Function(InvestorDetailState) __);
}


/// Adds pattern-matching-related methods to [InvestorDetailState].
extension InvestorDetailStatePatterns on InvestorDetailState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( InvestorDetailLoading value)?  loading,TResult Function( InvestorDetailLoaded value)?  loaded,TResult Function( InvestorDetailFailure value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case InvestorDetailLoading() when loading != null:
return loading(_that);case InvestorDetailLoaded() when loaded != null:
return loaded(_that);case InvestorDetailFailure() when failure != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( InvestorDetailLoading value)  loading,required TResult Function( InvestorDetailLoaded value)  loaded,required TResult Function( InvestorDetailFailure value)  failure,}){
final _that = this;
switch (_that) {
case InvestorDetailLoading():
return loading(_that);case InvestorDetailLoaded():
return loaded(_that);case InvestorDetailFailure():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( InvestorDetailLoading value)?  loading,TResult? Function( InvestorDetailLoaded value)?  loaded,TResult? Function( InvestorDetailFailure value)?  failure,}){
final _that = this;
switch (_that) {
case InvestorDetailLoading() when loading != null:
return loading(_that);case InvestorDetailLoaded() when loaded != null:
return loaded(_that);case InvestorDetailFailure() when failure != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( Investor investor)?  loaded,TResult Function( Failure failure)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case InvestorDetailLoading() when loading != null:
return loading();case InvestorDetailLoaded() when loaded != null:
return loaded(_that.investor);case InvestorDetailFailure() when failure != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( Investor investor)  loaded,required TResult Function( Failure failure)  failure,}) {final _that = this;
switch (_that) {
case InvestorDetailLoading():
return loading();case InvestorDetailLoaded():
return loaded(_that.investor);case InvestorDetailFailure():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( Investor investor)?  loaded,TResult? Function( Failure failure)?  failure,}) {final _that = this;
switch (_that) {
case InvestorDetailLoading() when loading != null:
return loading();case InvestorDetailLoaded() when loaded != null:
return loaded(_that.investor);case InvestorDetailFailure() when failure != null:
return failure(_that.failure);case _:
  return null;

}
}

}

/// @nodoc


class InvestorDetailLoading implements InvestorDetailState {
  const InvestorDetailLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestorDetailLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'InvestorDetailState.loading()';
}


}




/// @nodoc


class InvestorDetailLoaded implements InvestorDetailState {
  const InvestorDetailLoaded({required this.investor});
  

 final  Investor investor;

/// Create a copy of InvestorDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvestorDetailLoadedCopyWith<InvestorDetailLoaded> get copyWith => _$InvestorDetailLoadedCopyWithImpl<InvestorDetailLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestorDetailLoaded&&(identical(other.investor, investor) || other.investor == investor));
}


@override
int get hashCode => Object.hash(runtimeType,investor);

@override
String toString() {
  return 'InvestorDetailState.loaded(investor: $investor)';
}


}

/// @nodoc
abstract mixin class $InvestorDetailLoadedCopyWith<$Res> implements $InvestorDetailStateCopyWith<$Res> {
  factory $InvestorDetailLoadedCopyWith(InvestorDetailLoaded value, $Res Function(InvestorDetailLoaded) _then) = _$InvestorDetailLoadedCopyWithImpl;
@useResult
$Res call({
 Investor investor
});


$InvestorCopyWith<$Res> get investor;

}
/// @nodoc
class _$InvestorDetailLoadedCopyWithImpl<$Res>
    implements $InvestorDetailLoadedCopyWith<$Res> {
  _$InvestorDetailLoadedCopyWithImpl(this._self, this._then);

  final InvestorDetailLoaded _self;
  final $Res Function(InvestorDetailLoaded) _then;

/// Create a copy of InvestorDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? investor = null,}) {
  return _then(InvestorDetailLoaded(
investor: null == investor ? _self.investor : investor // ignore: cast_nullable_to_non_nullable
as Investor,
  ));
}

/// Create a copy of InvestorDetailState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$InvestorCopyWith<$Res> get investor {
  
  return $InvestorCopyWith<$Res>(_self.investor, (value) {
    return _then(_self.copyWith(investor: value));
  });
}
}

/// @nodoc


class InvestorDetailFailure implements InvestorDetailState {
  const InvestorDetailFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of InvestorDetailState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$InvestorDetailFailureCopyWith<InvestorDetailFailure> get copyWith => _$InvestorDetailFailureCopyWithImpl<InvestorDetailFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is InvestorDetailFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'InvestorDetailState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $InvestorDetailFailureCopyWith<$Res> implements $InvestorDetailStateCopyWith<$Res> {
  factory $InvestorDetailFailureCopyWith(InvestorDetailFailure value, $Res Function(InvestorDetailFailure) _then) = _$InvestorDetailFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$InvestorDetailFailureCopyWithImpl<$Res>
    implements $InvestorDetailFailureCopyWith<$Res> {
  _$InvestorDetailFailureCopyWithImpl(this._self, this._then);

  final InvestorDetailFailure _self;
  final $Res Function(InvestorDetailFailure) _then;

/// Create a copy of InvestorDetailState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(InvestorDetailFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of InvestorDetailState
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
