// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'line_quote_cubit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LineQuoteState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LineQuoteState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LineQuoteState()';
}


}

/// @nodoc
class $LineQuoteStateCopyWith<$Res>  {
$LineQuoteStateCopyWith(LineQuoteState _, $Res Function(LineQuoteState) __);
}


/// Adds pattern-matching-related methods to [LineQuoteState].
extension LineQuoteStatePatterns on LineQuoteState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( LineQuoteIdle value)?  idle,TResult Function( LineQuoteLoading value)?  loading,TResult Function( LineQuotePriced value)?  priced,TResult Function( LineQuoteFailure value)?  failure,TResult Function( LineQuoteByHand value)?  byHand,required TResult orElse(),}){
final _that = this;
switch (_that) {
case LineQuoteIdle() when idle != null:
return idle(_that);case LineQuoteLoading() when loading != null:
return loading(_that);case LineQuotePriced() when priced != null:
return priced(_that);case LineQuoteFailure() when failure != null:
return failure(_that);case LineQuoteByHand() when byHand != null:
return byHand(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( LineQuoteIdle value)  idle,required TResult Function( LineQuoteLoading value)  loading,required TResult Function( LineQuotePriced value)  priced,required TResult Function( LineQuoteFailure value)  failure,required TResult Function( LineQuoteByHand value)  byHand,}){
final _that = this;
switch (_that) {
case LineQuoteIdle():
return idle(_that);case LineQuoteLoading():
return loading(_that);case LineQuotePriced():
return priced(_that);case LineQuoteFailure():
return failure(_that);case LineQuoteByHand():
return byHand(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( LineQuoteIdle value)?  idle,TResult? Function( LineQuoteLoading value)?  loading,TResult? Function( LineQuotePriced value)?  priced,TResult? Function( LineQuoteFailure value)?  failure,TResult? Function( LineQuoteByHand value)?  byHand,}){
final _that = this;
switch (_that) {
case LineQuoteIdle() when idle != null:
return idle(_that);case LineQuoteLoading() when loading != null:
return loading(_that);case LineQuotePriced() when priced != null:
return priced(_that);case LineQuoteFailure() when failure != null:
return failure(_that);case LineQuoteByHand() when byHand != null:
return byHand(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function()?  loading,TResult Function( PriceQuote quote)?  priced,TResult Function( Failure failure)?  failure,TResult Function()?  byHand,required TResult orElse(),}) {final _that = this;
switch (_that) {
case LineQuoteIdle() when idle != null:
return idle();case LineQuoteLoading() when loading != null:
return loading();case LineQuotePriced() when priced != null:
return priced(_that.quote);case LineQuoteFailure() when failure != null:
return failure(_that.failure);case LineQuoteByHand() when byHand != null:
return byHand();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function()  loading,required TResult Function( PriceQuote quote)  priced,required TResult Function( Failure failure)  failure,required TResult Function()  byHand,}) {final _that = this;
switch (_that) {
case LineQuoteIdle():
return idle();case LineQuoteLoading():
return loading();case LineQuotePriced():
return priced(_that.quote);case LineQuoteFailure():
return failure(_that.failure);case LineQuoteByHand():
return byHand();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function()?  loading,TResult? Function( PriceQuote quote)?  priced,TResult? Function( Failure failure)?  failure,TResult? Function()?  byHand,}) {final _that = this;
switch (_that) {
case LineQuoteIdle() when idle != null:
return idle();case LineQuoteLoading() when loading != null:
return loading();case LineQuotePriced() when priced != null:
return priced(_that.quote);case LineQuoteFailure() when failure != null:
return failure(_that.failure);case LineQuoteByHand() when byHand != null:
return byHand();case _:
  return null;

}
}

}

/// @nodoc


class LineQuoteIdle implements LineQuoteState {
  const LineQuoteIdle();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LineQuoteIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LineQuoteState.idle()';
}


}




/// @nodoc


class LineQuoteLoading implements LineQuoteState {
  const LineQuoteLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LineQuoteLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LineQuoteState.loading()';
}


}




/// @nodoc


class LineQuotePriced implements LineQuoteState {
  const LineQuotePriced(this.quote);
  

 final  PriceQuote quote;

/// Create a copy of LineQuoteState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LineQuotePricedCopyWith<LineQuotePriced> get copyWith => _$LineQuotePricedCopyWithImpl<LineQuotePriced>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LineQuotePriced&&(identical(other.quote, quote) || other.quote == quote));
}


@override
int get hashCode => Object.hash(runtimeType,quote);

@override
String toString() {
  return 'LineQuoteState.priced(quote: $quote)';
}


}

/// @nodoc
abstract mixin class $LineQuotePricedCopyWith<$Res> implements $LineQuoteStateCopyWith<$Res> {
  factory $LineQuotePricedCopyWith(LineQuotePriced value, $Res Function(LineQuotePriced) _then) = _$LineQuotePricedCopyWithImpl;
@useResult
$Res call({
 PriceQuote quote
});


$PriceQuoteCopyWith<$Res> get quote;

}
/// @nodoc
class _$LineQuotePricedCopyWithImpl<$Res>
    implements $LineQuotePricedCopyWith<$Res> {
  _$LineQuotePricedCopyWithImpl(this._self, this._then);

  final LineQuotePriced _self;
  final $Res Function(LineQuotePriced) _then;

/// Create a copy of LineQuoteState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? quote = null,}) {
  return _then(LineQuotePriced(
null == quote ? _self.quote : quote // ignore: cast_nullable_to_non_nullable
as PriceQuote,
  ));
}

/// Create a copy of LineQuoteState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PriceQuoteCopyWith<$Res> get quote {
  
  return $PriceQuoteCopyWith<$Res>(_self.quote, (value) {
    return _then(_self.copyWith(quote: value));
  });
}
}

/// @nodoc


class LineQuoteFailure implements LineQuoteState {
  const LineQuoteFailure(this.failure);
  

 final  Failure failure;

/// Create a copy of LineQuoteState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LineQuoteFailureCopyWith<LineQuoteFailure> get copyWith => _$LineQuoteFailureCopyWithImpl<LineQuoteFailure>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LineQuoteFailure&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode => Object.hash(runtimeType,failure);

@override
String toString() {
  return 'LineQuoteState.failure(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $LineQuoteFailureCopyWith<$Res> implements $LineQuoteStateCopyWith<$Res> {
  factory $LineQuoteFailureCopyWith(LineQuoteFailure value, $Res Function(LineQuoteFailure) _then) = _$LineQuoteFailureCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$LineQuoteFailureCopyWithImpl<$Res>
    implements $LineQuoteFailureCopyWith<$Res> {
  _$LineQuoteFailureCopyWithImpl(this._self, this._then);

  final LineQuoteFailure _self;
  final $Res Function(LineQuoteFailure) _then;

/// Create a copy of LineQuoteState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(LineQuoteFailure(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of LineQuoteState
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


class LineQuoteByHand implements LineQuoteState {
  const LineQuoteByHand();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LineQuoteByHand);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'LineQuoteState.byHand()';
}


}




// dart format on
